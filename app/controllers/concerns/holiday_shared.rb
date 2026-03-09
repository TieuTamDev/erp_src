module HolidayShared
  extend ActiveSupport::Concern

  included do
    before_action :prepare_holiday_data
  end

  private

  def prepare_holiday_data(user_id = nil)
    user = User.find_by(id: user_id)
    contract = user&.contracts&.where(status: "ACTIVE")&.order(created_at: :asc)&.first
    @holtypes = Holtype.where(status: "ACTIVE").order(:name)

    organization = Organization.find_by(scode: session[:organization])
    organization_id = organization&.id
    # Lấy positionjob_id và department_id 
    get_positionjob_department_ids = get_positionjob_department_ids_of_user(user_id)

    valid_department_ids = get_positionjob_department_ids[:valid].map { |sub| sub[1] }

    department_valid_ids = []
    valid_department_ids.each do |dpt_id|
      department_valid_ids.concat(Department.get_all_children(dpt_id))
    end

    # invalid là lấy tất cả department id của tất cả vị trí công việc
    invalid_department_ids = get_positionjob_department_ids[:invalid]
    
    # Danh sách parent deparment_ids
    department_invalid_ids = Department.get_all_related_departments(invalid_department_ids).uniq
    # department_user = fetch_leaf_departments_by_user(user_id)
    # department = department_user.first
    
    # Danh sách Nhân sự bàn giao công việc
    @users_in_department = Work.joins({positionjob: :department}, :user)
                              .where(positionjobs: { department_id: department_invalid_ids })
                              .where.not("users.status = ? OR users.staff_status = ?", "INACTIVE", "Nghỉ việc")
                              .pluck("positionjobs.department_id", "positionjobs.name", "departments.name as department_name", "works.user_id", "CONCAT(users.last_name, ' ', users.first_name) as name").uniq
                              .map { |department_id, position_name, department_name, user_id, name| { department_id: department_id, position_name: position_name, department_name: department_name, user_id: user_id, name: name } }
    
                              
    # if department.present? && department.faculty == "BGD(BUH)"
    # Danh sách nhân sự đăng ký thay
    if is_access(user_id, "ON-ADDITIONAL-LEAVE", "ADM")
      @users = Work.joins({positionjob: :department}, :user)
                                .where(positionjobs: { department_id: department_valid_ids.uniq })
                                .where.not(user_id: user_id)
                                .where.not("users.status = ? OR users.staff_status = ?", "INACTIVE", "Nghỉ việc")
                                .pluck("positionjobs.department_id", "positionjobs.name", "departments.name as department_name", "works.user_id", "CONCAT(users.last_name, ' ', users.first_name) as name").uniq
                                .map { |department_id, position_name, department_name, user_id, name| { department_id: department_id, position_name: position_name, department_name: department_name, user_id: user_id, name: name } }
    end
    # Danh sách quốc gia
    @nationalities = Nationality.where.not(name: "Việt Nam").order(:name)

    holiday = Holiday.find_by(year: Date.current.year, user_id: user_id)
    @holiday_id = holiday&.id

    holdetails = holiday ? Holdetail.where(holiday_id: holiday.id, name: ["Phép tồn", "Phép theo vị trí", "Phép thâm niên", "Phép hè"]).index_by(&:name) : {}
    # phân loại các phép theo vị trí, phép thâm niên và phép tồn
    pjob = holdetails["Phép theo vị trí"]
    seniority = holdetails["Phép thâm niên"]
    remain = holdetails["Phép tồn"]
    summer = holdetails["Phép hè"]
    # lấy giá trị của phép theo vị trí, phép thâm niên và phép tồn
    @pjob_amount       = pjob&.amount.to_f || 0
    @pjob_used         = pjob&.used.to_f || 0
    @seniority_amount  = seniority&.amount.to_f || 0
    @seniority_used    = seniority&.used.to_f || 0
    @summer_amount     = summer&.amount.to_f || 0
    @summer_used       = summer&.used.to_f || 0
    
    if remain&.dtdeadline.present? && remain.dtdeadline.to_date >= Date.current
      @remain_amount = remain.amount.to_f - remain.used.to_f
    end
    # Tính tổng số ngày phép
    @total_leave  = @pjob_amount + @seniority_amount + @summer_amount
    @total_used   = @pjob_used + @seniority_used + @summer_used
    @holiday_used = @total_leave - @total_used
    @dtdeadline   = remain&.dtdeadline

    # check TCHC department and role is leader
    leader_roles = ["trưởng","trưởng", "giám đốc", "hiệu", "chánh", "chủ tịch"]
    work = Work.where(user_id: user_id).where.not(positionjob_id: nil).first

    # setting_leave = Msetting.find_by(stype: "LEAVE", scode: "VALID-TIME-CREATE")
    # svalue_leave = JSON.parse(setting_leave.svalue)

    # find positon job
    position_job = Positionjob.find_by(id: work&.positionjob_id)
    # h.anh
    # 28/11/2025
    # Get all holidays buh
    if session[:organization].present?
      org = session[:organization].first
    else
      org = nil
    end
    if org == "BUH"
      base_url = "#{@BUH_CSVC_PATH}api/v1/mapi_utils"
      url = URI.parse("#{base_url}/get_holidays_buh?organization=#{org}")
      https = Net::HTTP.new(url.host, url.port)
      https.use_ssl = true
      request = Net::HTTP::Get.new(url)
      response = https.request(request)
      response_hash = JSON.parse(response.read_body.gsub('=>', ':'))
    else
      response_hash = nil
    end

    # find department
    department = Department.find_by(id: position_job&.department_id, status: "0")
    check_per_bgd = check_permission_director(user_id)
    # Gán gon biến
    gon.tap do |g|
      g.users_in_department    = @users_in_department.uniq
      g.users                  = @users.uniq if @users.present?
      g.holtypes               = @holtypes
      g.nationalities          = @nationalities
      g.organization           = session[:organization]
      g.holiday_used           = @holiday_used
      g.dayleave_of_pjob       = @pjob_amount
      g.remain_amount          = @remain_amount || 0
      g.dtdeadline             = @dtdeadline&.strftime("%d/%m/%Y") || Time.now.strftime("%d/%m/%Y")
      g.total_leave            = @total_leave
      g.total_used             = @total_used
      g.seniority_amount       = @seniority_amount
      g.pjob_amount            = @pjob_amount - @pjob_used  
      g.user_id                = user_id
      g.leave_bgd              = check_per_bgd
      g.dtfrom_contract        = (contract && contract.dtfrom.to_date > Date.today) ? Time.now.strftime("%Y/%m/%d") : contract ? contract.dtfrom.strftime("%Y/%m/%d") : Time.now.strftime("%Y/%m/%d")
      g.leader_roles           = leader_roles.any? { |item| position_job&.name&.downcase&.include?(item)}
      g.sub_leader_roles       = position_job&.name&.downcase&.include?("phó")
      g.leader_roles_buh       = check_permission_approve_leave(user_id).present?
      g.faculty                = department&.faculty || ""
      g.get_positionjob_department_ids = get_positionjob_department_ids
      g.all_holiday_csvc       = response_hash
    end
  end
  def fetch_leaf_departments_by_user(user_id)
    positionjob_ids = Work.where(user_id: user_id)
                          .where.not(positionjob_id: nil)
                          .pluck(:positionjob_id)

    department_ids = Positionjob.where(id: positionjob_ids).pluck(:department_id)

    departments = Department.where(id: department_ids, status: "1").where.not(parents: [nil, ""])

    if departments.present?
      parent_ids = departments.map(&:parents).compact.map(&:to_i)
      departments.reject { |dept| parent_ids.include?(dept.id) }
    else
      Department.where(id: department_ids).limit(1)
    end
  end
  # lấy vị trí công việc cuối cùng
  def get_positionjob_department_ids_of_user(user_id)
    #1. Lấy hết vị trí công việc
    valid_pairs = []
    department_ids = []
    user_works = Work
      .joins(positionjob: :department)
      .where(user_id: user_id)
      .where(departments: {status: "0"})
      # .includes(positionjob: :department)

    if user_works.present?
      #2. Lấy department id từ vị trí công việc
      work_departments = user_works.map do |w|
        [w&.positionjob_id, w&.positionjob&.department_id, w&.positionjob&.department&.faculty]
      end
      # Lấy danh sách deparment_ids
      department_ids = work_departments.map { |_, dep_id| dep_id }.uniq
      # kiểm tra xem có phải là BGĐ không?
      bgd_pairs = work_departments.select { |w| w[2] == "BGD(BUH)" }
      return { valid: bgd_pairs, invalid: department_ids.compact } if bgd_pairs.any?
      # 
      departments = Department.where(id: department_ids)
      # Lấy id của parents
      parent_ids = departments.map(&:parents).compact.uniq
      #3. So sánh các nếu mà department_id là parent của đơn vị khác thì bỏ qua
      main_departments = departments.reject { |dep| parent_ids.include?(dep.id.to_s) }
      # danh sách id department 
      main_department_ids = main_departments.map { |d| d.id }
      # so sánh work_departments để lấy positionjob_id và department_id tương ứng
      valid_pairs = work_departments.select { |pair| main_department_ids.include?(pair[1]) }
    end
    {valid: valid_pairs, invalid: department_ids.compact}
  end

  # Kiểm tra đơn vị nhân sự có quyền duyệt phép hay không 
  def get_users_have_access_handle(dpt_id = "", permission = "ADM", scode = "APPROVE-REQUEST")
    # Tìm nhân sự có quyền
    user_id = Work.joins(stask: { accesses: :resource })
                  .where(resources: { scode: scode }, accesses: {permision: permission}).pluck(:user_id)

    # Lấy thông tin nhân sự có quyền trong department
    users_have_access = Work.joins({positionjob: :department}, :user)
                            .where(user_id: user_id).where.not(positionjob_id: nil)
                            .where.not("users.status = ? OR users.staff_status = ?", "INACTIVE", "Nghỉ việc")
    users_have_access = users_have_access.where(positionjobs: {department_id: dpt_id}) if dpt_id.present?
    users_have_access = users_have_access.pluck("positionjobs.department_id", "positionjobs.name", "departments.name as department_name", "works.user_id", "CONCAT(users.last_name, ' ', users.first_name) as name")
                                        .map { |department_id, position_name, department_name, user_id, name| { 
                                          department_id: department_id, 
                                          position_name: position_name, 
                                          department_name: department_name, 
                                          user_id: user_id, name: name 
                                        }} 
  end

  def check_permission_approve_leave(user_id)
    user_id = Work.joins(stask: { accesses: :resource })
                    .where(resources: { scode: "APPROVE-REQUEST" }, works: {user_id: user_id}, accesses: {permision: "ADM"})
  end

  def check_permission_director(user_id)
    check_per_bgd = Work.joins(stask: { accesses: :resource })
                                .where(
                                  resources: { scode: "LEAVE-BGD" },
                                  works:     { user_id: user_id },
                                  accesses:  { permision: "ADM" }
                                )
                                .exists?
  end
end
