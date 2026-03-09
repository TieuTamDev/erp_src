module AttendConcern
  extend ActiveSupport::Concern
  include StreamConcern
  include AppointmentsHelper

  # Get list departments by uorg_scode
  # @author: Dat Le
  # @date: 30/06/2025
  # @input:
  # @return [ActiveRecord::Relation<Department>] List of departments
  def get_departments
    # Lấy uorg_scode từ params hoặc mặc định từ tài khoản đăng nhập
    uorg_scode = if params[:uorg_scode].present?
                   params[:uorg_scode]
                 else
                   uorgs = current_user.uorgs
                   uorgs.size > 1 ? "BMU" : (uorgs.first&.organization&.scode || "BMU")
                 end
    # Lấy danh sách departments dựa trên uorg_scode
    org_ids =
      case uorg_scode
      when "BUH"
        Organization.where(scode: "BUH").select(:id)
      when "BMU"
        Organization.where(scode: ["BMU", "BMTU"]).select(:id)
      when "BMTU"
        Organization.where(scode: ["BMU", "BMTU"]).select(:id)
      else
        Organization.none
      end

    Department.where(organization_id: org_ids)
              .where.not(name: "Quản lý ERP")
  end

  # Get list managers by user_id
  # @author: Dat Le
  # @date: 05/07/2025
  # @input: user_id
  # @return: List of managers
  def get_managers (user_id: nil)
    user_id ||= session[:user_id]
    name = Organization.where(id: User.find(user_id).uorgs.pluck(:organization_id)).pluck(:scode)
    organization_name = name || session[:organization]
    stype = params[:stype]
    leader_roles = ["trưởng","trưởng", "phó", "giám đốc", "hiệu", "chủ tịch", "chánh", "phụ trách"]

    next_user_to_handle = []
    users_have_access = []
    department_id = ""
    check_bgd = false
    if (organization_name & ["BMU", "BMTU"]).any?
      department_ids = handle_in_bmu(user_id)[:department_ids]
      users_have_access = handle_in_bmu(user_id)[:users_have_access]
    else
      department_ids = handle_in_buh(user_id)[:department_ids]
      users_have_access = handle_in_buh(user_id)[:users_have_access]
    end

    next_user_to_handle = Work.left_outer_joins({positionjob: :department}, :user)
                              .where("positionjobs.name LIKE ? OR positionjobs.name LIKE ? OR positionjobs.name LIKE ? OR positionjobs.name LIKE ? OR positionjobs.name LIKE ? OR positionjobs.name LIKE ?", "%trưởng%", "%phó%", "%giám đốc%", "%chủ tịch%", "%chánh%", "%phụ trách%")
                              .where(positionjobs: {department_id: department_ids})
                              .where.not("users.status = ? OR users.staff_status = ?", "INACTIVE", "Nghỉ việc")
                              .pluck("positionjobs.department_id", "departments.name as department_name", "works.user_id", "CONCAT(users.last_name, ' ', users.first_name) as name", "users.sid").uniq
                              .map { |department_id, department_name, user_id, name, sid| { department_id: department_id, department_name: department_name, user_id: user_id, name: name, sid: sid} }

    next_user_to_handle = next_user_to_handle + users_have_access

    next_user_to_handle = next_user_to_handle.flatten.reject(&:empty?)

    if stype == "ON-LEAVE"
      next_user_to_handle = next_user_to_handle.uniq.reject { |user| user[:user_id] == user_id }
    else
      next_user_to_handle = next_user_to_handle.uniq
    end
    return next_user_to_handle.flatten
  end

  def handle_in_buh(user_id)
    users_have_access = []
    department_ids = []
    leader_roles = ["trưởng","trưởng", "phó", "giám đốc", "hiệu", "chánh", "chủ tịch", "phụ trách"]

    # lấy danh sách positionjob_id và department_id của users
    positionjob_department_ids = get_positionjob_department_ids_of_user(user_id)[:valid].uniq
    positionjob_department_ids.each do |data|

      department = Department.find_by(id: data[1])

      position_job = Positionjob.find_by(id: data[0])

      # Kiểm tra đơn vị có lãnh đạo không?
      check_have_leader = get_users_have_access_handle(data[1])

      # Kiểm tra đơn vị nhân sự có quyền duyệt phép hay không
      is_leader = check_permission_approve_leave(user_id).present?

      # Kiểm tra nhân sự có trong danh sách này không? Nếu có trong danh sách quyền mặc định là lãnh đạo phòng
      if is_leader.present?
        if department.parents.nil? || department.parents == ""
          # Đối với đơn vị không có đơn vị cha
          case department.faculty
          when "BGD(BUH)"
            is_director = check_permission_director(user_id)
            if is_director
              # mặc định nếu là ban giám đốc thì submit luôn check client
            else
              # gửi cho giám đốc
              # users_have_access << get_users_have_access_handle(department.id, "ADM", "LEAVE-BGD")
              # kiểm tra theo vị trí
              nextStepData = stream_connect_by_status("DUYET-PHEP-BUH", "TCHC-APPROVE")
              users_have_access << get_users_have_access_handle(nextStepData.first[:next_department_id], "READ")
            end
          when "PTCHC(BUH)"
            # Nếu là phòng TC hành chỉnh thì gửi cho ban giám đốc
            nextStepData = stream_connect_by_status("DUYET-PHEP-BUH", "BOARD-APPROVE")
            department_ids << nextStepData.first[:next_department_id]
          else
            # Nếu là trưởng phòng đơn vị thì gửi cho trưởng/phó TCHC và nhân sự có quyền
            nextStepData = stream_connect_by_status("DUYET-PHEP-BUH")
            # department_ids << nextStepData.first[:next_department_id]
            users_have_access << get_users_have_access_handle(nextStepData.first[:next_department_id], "READ")
          end
        else
          # Tìm đơn vị cha
          # department_ids << department.parents.to_i
          users_have_access << get_users_have_access_handle(department.parents.to_i)
        end
      else
        if check_have_leader.present?
          # Đối với nhân sự thì gửi cho trưởng/phó đơn vị
          # department_ids << department.id
          # Lấy nhân sự có quyền
          users_have_access << get_users_have_access_handle(department.id)
        elsif !department.parents.nil? || department.parents != ""
          # Tìm đơn vị cha
          # department_ids << department.parents.to_i
          users_have_access << get_users_have_access_handle(department.parents.to_i)
        end
      end
    end
    {department_ids: department_ids, users_have_access: users_have_access}
  end

  def handle_in_bmu(user_id, leader_roles = [])
    users_have_access = []
    department_ids = []
    leader_roles = ["trưởng","trưởng", "phó", "giám đốc", "hiệu", "chánh", "chủ tịch", "phụ trách"]

    positionjob_department_ids = get_positionjob_department_ids_of_user(user_id)[:valid].uniq

    positionjob_department_ids.each do |data|
      department = Department.find_by(id: data[1])

      position_job = Positionjob.find_by(id: data[0])

      # Kiểm tra đơn vị có lãnh đạo không?
      has_leader_role = check_have_leader(department.id, leader_roles)
      #
      normalized_name = position_job.name.downcase.unicode_normalize(:nfkc)

      # Kiểm tra người tạo có phải là phó phòng?
      check_pho = normalized_name.include?("phó".unicode_normalize(:nfkc))

      # Kiểm tra người tạo có phải là trưởng phòng?
      # check_leader = leader_roles.any? { |item| normalized_name.include?(item.unicode_normalize(:nfkc)) }
      check_leader = leader_roles.any? do |item|
        normalized_item = item.downcase.unicode_normalize(:nfkc)
        normalized_name.include?(normalized_item) && !normalized_name.include?("phó trưởng") && !normalized_name.include?("phó chánh")
      end
      # check là trưởng phòng và không phải leader
      if !check_leader
        if !has_leader_role
          # Không có lãnh đạo
          if department.parents.nil? || department.parents == ""
            # nếu không có leader và không có parent
            nextStepData = stream_connect_by_status("DUYET-PHEP-BMU", "BOARD-APPROVE")
            department_ids << nextStepData.first[:next_department_id]
          else
            # bộ phận không có leader
            # Tìm đơn vị cha
            department_ids << department.parents.to_i
          end
        else
          # có lãnh đạo
          base_query = Work.joins({positionjob: :department}, :user)
                           .where(positionjobs: {department_id: position_job.department_id})
                           .where.not("users.status = ? OR users.staff_status = ?", "INACTIVE", "Nghỉ việc")

          # nếu là phó phòng
          if check_pho
            base_query = base_query.where("(positionjobs.name LIKE ? OR positionjobs.name LIKE ?) AND positionjobs.name NOT LIKE ? AND positionjobs.name NOT LIKE ?", "%trưởng%", "%chánh%", "%phó trưởng%", "%phó chánh%")   
            if !base_query.present?
              # Không có trưởng đơn vị gửi cho ban giám hiệu
              nextStepData = stream_connect_by_status("DUYET-PHEP-BMU", "BOARD-APPROVE")
              department_ids << nextStepData.first[:next_department_id]
              base_query = []
            end
          end

          # Nếu không phải là leader
          base_query = base_query.where("positionjobs.name LIKE ? OR positionjobs.name LIKE ? OR positionjobs.name LIKE ? OR positionjobs.name LIKE ?", "%trưởng%", "%phó%", "%giám đốc%", "%chánh%") if !check_leader && base_query.present?
          # Lấy thông tin users
          users_have_access << base_query.pluck("positionjobs.department_id", "departments.name as department_name", "works.user_id", "CONCAT(users.last_name, ' ', users.first_name) as name", "users.sid as sid")
                                         .map { |department_id, department_name, user_id, name, sid| { department_id: department_id, department_name: department_name, user_id: user_id, name: name, sid: sid } }
        end
      else
        # nếu không có parent
        if department.parents.nil? || department.parents == ""
          # nếu là hiệu trưởng
          check_principal = normalized_name == "hiệu trưởng".unicode_normalize(:nfkc)
          if check_principal
            nextStepData = stream_connect_by_status("NGHI-PHEP-HIEU-TRUONG", "APPROVE")
            department_ids << nextStepData.map { |item| item[:next_department_id] || item["next_department_id"] }
          else
            # Nếu là trưởng phòng thì gửi cho ban giám hiệu
            nextStepData = stream_connect_by_status("DUYET-PHEP-BMU", "BOARD-APPROVE")
            department_ids << nextStepData.first[:next_department_id]
          end
        else
          # bộ phận không có leader
          # Tìm đơn vị cha
          department_ids << department.parents.to_i
        end
      end
    end

    {department_ids: department_ids, users_have_access: users_have_access.flatten.uniq}
  end

  def check_have_leader(department_id, leader_roles)
    # lấy danh sách vị trí công việc của đơn vị
    works = Work.joins(:positionjob).where(positionjobs: {department_id: department_id})

    # Lấy tên các vị trí công việc của đơn vị
    all_position_jobs = Positionjob.where(id: works.pluck(:positionjob_id)).pluck(:name)

    # Kiểm tra đơn vị có lãnh đạo không?
    has_leader_role = all_position_jobs.any? { |name| leader_roles.any? { |item| name.downcase.unicode_normalize(:nfkc).include?(item.unicode_normalize(:nfkc)) } }
  end

  # lấy vị trí công việc cuối cùng
  def get_positionjob_department_ids_of_user(user_id)
    #1. Lấy hết vị trí công việc
    user_works = Work
                   .includes(positionjob: :department)
                   .where(user_id: user_id)

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
      {valid: valid_pairs, invalid: department_ids.compact}
    end
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
    users_have_access = users_have_access.pluck("positionjobs.department_id", "departments.name as department_name", "works.user_id", "CONCAT(users.last_name, ' ', users.first_name) as name", "users.sid as sid")
                                         .map { |department_id, department_name, user_id, name, sid| {
                                           department_id: department_id,
                                           department_name: department_name,
                                           user_id: user_id, name: name, sid: sid
                                         }}
  end

  # Update scheduleweek when leave request has been approved/canceled
  # @author: Dat Le
  # @date: 27/08/2025
  # @input: user_id, dates, status (APPROVED/CANCELED)
  # @return: nil
  def update_scheduleweek (user_id, dates = '', status = 'APPROVED')
    if dates.present? && user_id.present?
      leaves_data = parse_dates_leaves_data(dates)
      new_is_day_off = (status == 'APPROVED') ? 'ON-LEAVE' : nil

      ActiveRecord::Base.transaction do
        leaves_data.each do |item|
          day_start = item[:date].beginning_of_day
          day_end   = item[:date].end_of_day
          base = Shiftselection
                   .joins(:scheduleweek)
                   .where(scheduleweeks: { user_id: user_id })
                   .where(work_date: day_start..day_end)
          matches =
            case item[:session]
            when 'ALL'
              base
            when 'AM'
              base.where("STR_TO_DATE(shiftselections.start_time, '%H:%i') <  STR_TO_DATE('12:30','%H:%i')")
            when 'PM'
              base.where("STR_TO_DATE(shiftselections.start_time, '%H:%i') >= STR_TO_DATE('12:30','%H:%i')")
            else
              Shiftselection.none
            end

          matches.find_each do |row|
            row.update!(is_day_off: new_is_day_off)
          end

        end
      end
      :ok
    end
  rescue => e
    e.message
  end

  def get_department_name(user_id)
    work = Work
             .where(user_id: user_id)
             .where.not(positionjob_id: nil)
             .includes(positionjob: :department)
             .order(created_at: :desc, id: :desc)
             .first

    if work&.positionjob&.department
      {
        department_name: work.positionjob.department.name,
        positionjob_name: work.positionjob.name
      }
    else
      {
        department_name: nil,
        positionjob_name: nil
      }
    end
  end

  def slugify(text)
    vietnamese_map = {
      "àáạảãâầấậẩẫăằắặẳẵ" => "a",
      "èéẹẻẽêềếệểễ"       => "e",
      "ìíịỉĩ"             => "i",
      "òóọỏõôồốộổỗơờớợởỡ" => "o",
      "ùúụủũưừứựửữ"       => "u",
      "ỳýỵỷỹ"             => "y",
      "đ"                 => "d",
      "ÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴ" => "A",
      "ÈÉẸẺẼÊỀẾỆỂỄ"       => "E",
      "ÌÍỊỈĨ"             => "I",
      "ÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠ" => "O",
      "ÙÚỤỦŨƯỪỨỰỬỮ"       => "U",
      "ỲÝỴỶỸ"             => "Y",
      "Đ"                 => "D"
    }

    vietnamese_map.each do |chars, replacement|
      text = text.tr(chars, replacement)
    end

    text.downcase
        .gsub(/[^a-z0-9\s-]/, '')
        .strip
        .gsub(/\s+/, '-')
        .gsub(/-+/, '-')
        .gsub(/^-|-$/, '')
  end

  def parse_dates_leaves_data(dates)
    dates.to_s.split('$$$').map(&:strip).flat_map  do |seg|
      if seg =~ /\A(\d{2}\/\d{2}\/\d{4})-(AM|PM|ALL)\z/i
        d = (Time.zone.strptime($1, '%d/%m/%Y').to_date rescue nil)
        { date: d, session: $2.upcase } if d
      end
    end
  end

  def get_all_campus
    # campus_map = Rails.cache.fetch("campus_map:v1", expires_in: 120.minutes) do
    #   begin
    #     campuses_response = call_api(@CSVC_PATH + "api/v1/mapi_utils/get_all_campuses")
    #     campuses = campuses_response["result"].is_a?(Array) ? campuses_response["result"] : []
    #     campuses.map { |c| [c["scode"], c["name"]] }.to_h
    #   rescue
    #     {}
    #   end
    # end
    campus_map = {
      "TRUONG-DAI-HOC-Y-DUOC-BUON-MA-THUOT" => "Trường Đại học Y Dược Buôn Ma Thuột ",
      "VIEN-NGHIEN-CUU-Y-SINH-UNG-DUNG" => "Viện nghiên cứu Y Sinh Ứng Dụng",
      "BENH-VIEN-DAI-HOC-Y-DUOC-BUON-MA-THUOT" => "Bệnh viện đại học Y Dược Buôn Ma Thuột",
      "TRUONG-DAI-HOC-Y-DUOC-BUON-MA-THUOT-" => "Trường Đại học Y Dược Buôn Ma Thuột ",
      "CO-SO-LIEN-KET---BV-DA-KHOA-KHANH-HOA" => 'Cơ sở liên kết - BV Đa khoa Khánh Hòa',
      "CO-SO-LIEN-KET---BV-DA-KHOA-BINH-DINH" => 'Cơ sở liên kết - BV Đa Khoa Bình Định',
      "BENH-VIEN-DA-KHOA-VUNG-TAY-NGUYEN" => 'Bệnh viện Đa Khoa Vùng Tây Nguyên',
      "CO-SO-LIEN-KET---BV-DA-KHOA-NINH-THUAN" => 'Cơ sở liên kết - BV Đa Khoa Ninh Thuận',
      "CO-SO-LIEN-KET---BV-TAM-THAN-DAK-LAK" => 'Cơ sở liên kết - BV Tâm Thần Đắk Lắk',
      "CO-SO-LIEN-KET---BV-LAO-PHOI-DAK-LAK" => 'Cơ sở liên kết - BV Lao Phổi Đắk Lắk',
      "CO-SO-LIEN-KET---BV-YHCT-DAK-LAK" => 'Cơ sở liên kết - BV YHCT Đắk Lắk',
    }
    campus_map
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

  def check_permission_approve_leave(user_id)
    user_id = Work.joins(stask: { accesses: :resource })
                  .where(resources: { scode: "APPROVE-REQUEST" }, works: {user_id: user_id}, accesses: {permision: "ADM"})
  end

  # @author: trong.lq
  # @date: 24/01/2026
  # Lấy department_id của user
  def get_user_department_id(user_id, fallback_id = nil)
    Work
      .where(user_id: user_id)
      .where.not(positionjob_id: nil)
      .joins(positionjob: :department)
      .pluck('departments.id').first || fallback_id
  end
  
end