module Mapi
  class Mapi_utils < Grape::API

    # Log thời gian thực thi các function api
    # Dat Le - 17/09/2025
    use Grape::Middleware::Globals
    before do
      env['perf.start'] = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end
    after do
      start      = env.delete('perf.start') || Process.clock_gettime(Process::CLOCK_MONOTONIC)
      duration_ms = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start).round(9)

      endpoint = env['api.endpoint']
      route    = endpoint&.route
      path     = route&.path || env['PATH_INFO']

      # Bỏ qua log
      if path&.include?('is_permission_update') || path&.include?('get_notice_new_today_erp') || path&.include?('is_permission')
        next
      end

      referer = env['HTTP_REFERER']
      session   = env['rack.session'] || {}
      user_id   = session['user_id'] || params[:user_id] || headers['X-User-Id']
      user_name = session['user_fullname']
      user_email= session['user_email_login']

      Mylog.create!(
        userid: user_id,
        user_name: user_name,
        user_email: user_email,
        spath: path,
        saction_name: referer || env['HTTP_ORIGIN'],
        dtstart: Time.current - duration_ms.fdiv(1000),
        dtend:   Time.current,
        note:    duration_ms
      )
    end

    version 'v1', using: :path
    resource :mapi_utils do
    helpers do
        include AppointmentsHelper
      end
  # ============================= API Website ================================

      # hàm tạm thời, hỗ trợ cập nhật module cho lms
      # @author: H.Vu
      desc "Get head department list"
      params do end
      get :get_head_list do
        data = Work.select("works.user_id,users.email,CONCAT(users.last_name,' ',users.first_name) as user_name,positionjobs.scode,positionjobs.department_id,departments.name")
                  .joins("JOIN positionjobs ON works.positionjob_id = positionjobs.id")
                  .joins("JOIN users ON users.id = works.user_id")
                  .joins("JOIN departments ON departments.id = positionjobs.department_id")
                  .where("positionjobs.scode LIKE 'TRUONG-%'")
        return {
            data:data
        }
      end

      # Get department
      # @author: H.Vu
      # @date: 17/10/2024
      # @input:
      # @output: array of department
      desc "Get departments list"
      params do end
      get :get_departments do
        depatments = Department.joins("JOIN organizations on organizations.id = departments.organization_id").select("departments.id,departments.name,departments.name_en,departments.scode,organizations.scode as org")
        return {
          data:depatments
        }
      end

      # Get all teacher
      # @author: H.Vu
      # @date: 10/05/2023
      # @input:
      # @output: array of teacher
      # TODO:
      # + duplicate user id query check?
      desc "Get department with lecturers"
      params do end
      get :get_lecturers do
        # params, decl
        smg = ""
        version = 1.0
        data = []
        users = User.select("users.id,users.sid,users.status,users.last_name,users.first_name,users.email,users.academic_rank,mediafiles.file_name as avatar,users.staff_status,positionjobs.name as positionjob_name,positionjobs.scode as positionjob_scode,departments.name as department_name,departments.id as department_id,departments.faculty as department_sid,organizations.scode as uorg_scode, users.status as status
                  ,GROUP_CONCAT(departments.name,', ') AS dept_names
                  ,GROUP_CONCAT(CONCAT(departments.id,'::',departments.name) SEPARATOR '||') AS department_list
                  ,GROUP_CONCAT(CONCAT(positionjobs.department_id, '::', positionjobs.name) SEPARATOR '||') AS positionjob_list")
                  .joins(:uorgs)
                  .joins("JOIN organizations ON organizations.id = uorgs.organization_id")
                  .joins("LEFT JOIN mediafiles ON mediafiles.id = users.avatar")
                  .joins("JOIN works on works.user_id = users.id")
                  .joins("JOIN positionjobs ON works.positionjob_id = positionjobs.id")
                  .joins("JOIN departments ON departments.id = positionjobs.department_id")
                  .order("users.last_name")
                  .group("users.id")
                  .distinct
        users.each do |user|
          if user.status == "ACTIVE"
            avatar_url = nil
            avatar_url = request.base_url + "/mdata/hrm/" +  user.avatar if !user.avatar.nil?

            department_list = []
            if user.department_list.present?
              department_list = user.department_list.split("||").map{|item| {id:item.split("::")[0],name:item.split("::")[1]}}
            end

            positionjob_list = []
            if user.positionjob_list.present?
              positionjob_list = user.positionjob_list.split("||").map{|item| {department_id:item.split("::")[0],name:item.split("::")[1]}}
            end

            data.push({
              id: user.id,
              sid:user.sid,
              name: "#{user.last_name} #{user.first_name}",
              avatar:avatar_url,
              org:user.uorg_scode,
              staff_status:user.staff_status,
              email:user.email,
              status:user.status,
              academic_rank:user.academic_rank,
              positionjob_name: user.positionjob_name,
              positionjob_scode: user.positionjob_scode,
              department_name: user.department_name,
              department_id: user.department_id,
              department_sid: user.department_sid,
              dept_names: user.dept_names || [],
              department_list: department_list,
              positionjob_list:positionjob_list,
            })
          end
        end
        return {
            datas:data,
            ver:version
        }
      end

      # Api lấy danh sách giảng viên, nhân viên đào tạo, nhân viên ban giám hiệu.
      # @author: H.Vu
      # @date: 03/09/2025
      # @input: deparment_ids, lecture_ids
      # @output: teacher list
      desc "Get user relative schedule"
      params do end
      get :user_schedules do

        department_ids = params[:department_ids] || [] # bộ môn gắn trong dòng thời khóa biểu.
        lecture_ids = params[:lecture_ids] || [] # giảng viên gắn trong các học phần
        version = "1.0"
        users = User.select("users.id,users.sid,users.status,users.last_name,users.first_name,users.email,users.academic_rank,mediafiles.file_name as avatar,users.staff_status,positionjobs.name as positionjob_name,positionjobs.scode as positionjob_scode,departments.name as department_name,departments.id as department_id,departments.faculty as department_sid,organizations.scode as uorg_scode, users.status as status")
                  .joins(:uorgs)
                  .joins("JOIN organizations ON organizations.id = uorgs.organization_id")
                  .joins("LEFT JOIN mediafiles ON mediafiles.id = users.avatar")
                  .joins("JOIN works on works.user_id = users.id")
                  .joins("JOIN positionjobs ON works.positionjob_id = positionjobs.id")
                  .joins("JOIN departments ON departments.id = positionjobs.department_id")
                  .order("users.last_name")
                  .where("users.status = 'ACTIVE'")
                  .where("(departments.id IN (?) OR users.id IN (?)",department_ids,lecture_ids) # Lấy nhân viên phòng đào tạo và ban giám hiệu
                  .distinct

        data = []
        users.each do |user|
          next if data.any? { |u| u[:id] == user.id }
          data.push({
            id: user.id,
            sid: user.sid,
            name: "#{user.last_name} #{user.first_name}",
            org: user.uorg_scode,
            staff_status: user.staff_status,
            email: user.email,
            status: user.status,
            academic_rank: user.academic_rank,
            positionjob_name: user.positionjob_name,
            department_name: user.department_name,
            department_id: user.department_id,
            department_sid: user.department_sid,
            positionjob_scode: user.positionjob_scode,
          })
        end

        return {
          data:data,
          ver:version
        }
      end

      # Get list teachers
      # @author: Khoa Nguyen
      # @date: 03/09/2025
      desc "List teachers"
      params do
        optional :department_id, type: Integer, desc: "Lọc theo department_id"
      end
      get :get_list_teachers do
        version = 1.0
        data = []

        users = User.select("users.id, users.sid, users.status, users.last_name, users.first_name, users.email, users.mobile,
                            users.academic_rank, mediafiles.file_name as avatar, users.staff_status,
                            positionjobs.name as positionjob_name, departments.name as department_name,
                            departments.id as department_id, departments.faculty as department_sid,
                            organizations.scode as uorg_scode, users.status as status")
                    .joins(:uorgs)
                    .joins("JOIN organizations ON organizations.id = uorgs.organization_id")
                    .joins("LEFT JOIN mediafiles ON mediafiles.id = users.avatar")
                    .joins("JOIN works on works.user_id = users.id")
                    .joins("JOIN positionjobs ON works.positionjob_id = positionjobs.id")
                    .joins("JOIN departments ON departments.id = positionjobs.department_id")

        # Thêm điều kiện lọc theo department_id nếu có
        if params[:department_id].present?
          users = users.where(departments: { id: params[:department_id] })
        end

        users = users.order("users.last_name").distinct

        users.each do |user|
          next unless user.status == "ACTIVE"
          next if data.any? { |u| u[:id] == user.id }

          avatar_url = user.avatar.present? ? "#{request.base_url}/mdata/hrm/#{user.avatar}" : nil

          data << {
            id: user.id,
            sid: user.sid,
            name: "#{user.last_name} #{user.first_name}",
            avatar: avatar_url,
            org: user.uorg_scode,
            staff_status: user.staff_status,
            email: user.email,
            phone: user.mobile,
            status: user.status,
            academic_rank: user.academic_rank,
            positionjob_name: user.positionjob_name,
            department_name: user.department_name,
            department_id: user.department_id,
            department_sid: user.department_sid,
          }
        end

        {
          datas: data,
          ver: version
        }
      end
      desc "Get departments list"
      params do end
      get :get_departments_by_facury do
        faculty_name = params[:faculty_name]
        depatments = Department.where(faculty: faculty_name).select("departments.id,departments.name")
        return {
          data: depatments
        }
      end
      # Get list department & user
      # @author: H.anh
      # @date: 28/02/2026
      desc "Get departments user"
      params do end
      get :get_department_and_user do
        org_ids = Organization.where(scode: ["BMTU", "BMU"]).pluck(:id)
        keywords = [ "%bộ môn%", "%phòng khảo thí và đảm bảo chất lượng%", "%trung tâm ngoại ngữ%" ]
        departments = Department.where(organization_id: org_ids).where( keywords.map { "LOWER(name) LIKE ?" }.join(" OR "), *keywords.map(&:downcase) ).select(:id, :name)
        result = []
        departments.each do |dept|
          users = User.joins("INNER JOIN works ON works.user_id = users.id")
          .joins("INNER JOIN positionjobs ON positionjobs.id = works.positionjob_id")
          .where(positionjobs: { department_id: dept.id })
          .where(staff_status: ["Đang làm việc","DANG-LAM-VIEC"])
          .where(status: "ACTIVE").distinct
          next if users.blank?
          result << {
              department_id: dept.id,
              department_name: dept.name,
              users: users.map do |u| {
                id: u.id,
                sid: u.sid,
                email: u.email,
                full_name: "#{u.last_name} #{u.first_name}",
                department_name: dept.name,
              }
            end
          }
        end
        { msg: "Success", data: result }
      end
      # Get all teacher
      # @date: 10/05/2023
      # @input:
      # @output: array of teacher
      # TODO:
      # + duplicate user id query check?
      desc "Get lecturers with derpartment"
      params do end
      get :get_lecturers_with_derpartment do
        # params, decl
        smg = ""
        datas = []
        # lecturers_scode = ["GIANG-VIEN","KY-THUAT-VIEN","TRO-GIANG"]
        faculty_name = params[:faculty_name]
        search = params[:search]
        page = params[:page]&.to_i || 1
        per_page = params[:per_page]&.to_i || 10
        offset = (page - 1) * per_page
        # query
        search = "%#{search}%"
        query = Work.left_outer_joins(:stask).includes(:stask)
                    .left_outer_joins(:positionjob).includes(:positionjob)
                    .joins(:user)
                    .where(" (users.last_name LIKE :search OR users.first_name LIKE :search OR CONCAT(users.first_name,' ', users.last_name) LIKE :search OR users.email LIKE :search )",{search: search})
        # pagin
        total = query.count
        total_page = (total.to_f/per_page).ceil
        # result handle
        query.each do |work|
          oDepartment = work.positionjob&.department
          department_name = oDepartment&.name
          if department_name == faculty_name
            if !datas.any? { |hash| hash["id"] == work.user.id }
              user = work.user
              department_id = oDepartment&.id
              if !department_id.nil?
                org_id = oDepartment&.organization_id
                org_scode = Organization.where(id:org_id).first&.scode
                if org_scode == "BMTU" || org_scode == "BMU"
                  if !user.avatar.nil?
                    avatar_url = request.base_url + "/mdata/hrm/" +  Mediafile.where("id = #{user.avatar}").first.file_name
                  else
                    avatar_url = nil
                  end
                  datas.push({
                    id: user.id,
                    sid:user.sid,
                    name: "#{user.last_name} #{user.first_name}",
                    avatar:avatar_url,
                    staff_status:user.staff_status,
                    email:user.email,
                    academic_rank:user.academic_rank,
                    department_name: oDepartment&.name,
                    positionjob_name: work.positionjob&.name,
                    department_id: department_id,
                    department_sid: oDepartment&.faculty
                  })
                end
              end
            end
          end
        end
        load_more = page * per_page < total
        return datas
      end
      # h.anh
      # 30/12/2025
      # hàm lấy danh sách nhân sự phòng giám đốc
      desc "Get lecturers by faculty and positionjob (optimized)"
      get :get_lecturers_by_faculty do
        version = 1.0
        data = []

        # Lấy department theo faculty
        department = Department.find_by(faculty: "BGH")
        return { datas: [], ver: version } unless department

        # Lấy positionjob
        positionjobs = Positionjob
          .where(department_id: department.id)
          .where("LOWER(TRIM(name)) REGEXP ?", "phó hiệu trưởng|hiệu trưởng")
          .select(:id, :name)

        return { datas: [], ver: version } if positionjobs.empty?

        positionjob_map = positionjobs.index_by(&:id)

        # Lấy works
        works = Work.where(positionjob_id: positionjob_map.keys)
        return { datas: [], ver: version } if works.empty?

        work_map = works.index_by(&:user_id)

        # Lấy users
        users = User
          .where(id: work_map.keys, status: "ACTIVE")
          .select(:id, :sid, :last_name, :first_name, :email)

        # Build response
        users.each do |user|
          work = work_map[user.id]
          next unless work

          positionjob = positionjob_map[work.positionjob_id]

          data << {
            id: user.id,
            sid: user.sid,
            name: "#{user.last_name} #{user.first_name}",
            email: user.email,
            department_name: department.name,
            department_id: department.id,
            positionjob_name: positionjob&.name
          }
        end

        {
          datas: data,
          ver: version
        }
      end
      # Get teacher by id
      # @author: H.Vu
      # @date: 01/02/2023
      # @input: id
      # @output: array of user
      desc "Get teacher list"
      params do
        requires :id, type: String, desc: "Teacher Id"
      end
      get :get_lecturer do
        id = params[:id]
        smg = ""
        ids = id.split("-")
        result = nil
        if ids.length == 1
          result = User.where(id: ids[0]).first
        else
          result = User.where(id: ids)
        end

        return {smg: smg, datas:result}
      end

      # Get users from department
      # @author: TP.Dong
      # @date: 01/02/2023
      # @input: department id
      # @output: array of user
      desc "Get users from department"
      params do
        requires :department_id, type: String, desc: "Department Id"
      end
      get :get_users_in_department do
        sUsers = []
        department_id = params[:department_id].to_i
        department_name = params[:department_name] || " "
        if department_id.nil? || department_id == '' || department_name == ""
          return {"msg" => "Error: Department id nil","result" => sUsers}
        end
        oUser_id =  Positionjob.joins(:department).where("departments.id = ? OR departments.name LIKE ?","#{department_id}","%#{department_name}%")
        if !oUser_id.nil?
          oWorks = Work.where(positionjob_id: oUser_id)
          if !oWorks.nil?
            oWorks.each do |work|
              oUser = User.where("id = #{work.user_id}").first
              if !oUser.nil?
                sUsers.append({
                  "id" => "#{oUser.id}",
                  "sid" => "#{oUser.sid}",
                  "username" => "#{oUser.username}",
                  "email" => "#{oUser.email}",
                  "password_digest" => "#{oUser.password_digest}",
                  "gender" => "#{oUser.gender}",
                  "nationality" => "#{oUser.nationality}",
                  "ethnic" => "#{oUser.ethnic}",
                  "religion" => "#{oUser.religion}",
                  "marriage" => "#{oUser.marriage}",
                  "insurance_no" => "#{oUser.insurance_no}",
                  "education" => "#{oUser.education}",
                  "academic_rank" => "#{oUser.academic_rank}",
                  "stype" => "#{oUser.stype}",
                  "status" => "#{oUser.status}",
                  "token" => "#{oUser.token}",
                  "expired" => "#{oUser.expired}",
                  "created_at" => "#{oUser.created_at}",
                  "updated_at" => "#{oUser.updated_at}",
                  "first_name" => "#{oUser.first_name}",
                  "last_name" => "#{oUser.last_name}",
                  "birthday" => "#{oUser.birthday}",
                  "birthday" => "#{oUser.birthday}",
                  "insurance_reg_place" => "#{oUser.insurance_reg_place}",
                  "place_of_birth" => "#{oUser.place_of_birth}",
                  "email1" => "#{oUser.email1}",
                  "phone" => "#{oUser.phone}",
                  "mobile" => "#{oUser.mobile}",
                  "avatar" => "#{oUser.avatar}",
                  "staff_status" => "#{oUser.staff_status}",
                  "benefit_type" => "#{oUser.benefit_type}",
                  "department_name" => "#{oUser_id.first&.department&.name}",
                  "department_id" => "#{oUser_id.first&.department&.id}",
                  "department_sid" => "#{oUser_id.first&.department&.faculty}",
                  "positionjob" => "#{oUser&.works.where.not(positionjob_id: nil).first&.positionjob&.name}"
                })
              end
            end
          end
          return {"msg" => "Success","result" => sUsers.uniq}
        end
      end
      desc "Get users score from department "
      params do
        requires :department_id, type: String, desc: "Department Id"
      end
      get :get_users_score_in_department do
        sUsers = []
        department_id = params[:department_id].to_i
        department_name = params[:department_name] || " "
        if department_id.nil? || department_id == '' || department_name == ""
          return {"msg" => "Error: Department id nil","result" => sUsers}
        end
        positionjob_id =  Positionjob.where(department_id: department_id).pluck(:id)
        if positionjob_id.present?
          oWorks = Work.where(positionjob_id: positionjob_id)
          if oWorks.present?
            oWorks.each do |work|
              oUser = User.where("id = #{work.user_id}").first
              if oUser.present?
                sUsers.append({
                  "id" => "#{oUser.id}",
                  "sid" => "#{oUser.sid}",
                  "email" => "#{oUser.email}",
                  "full_name" => " #{oUser.last_name} #{oUser.first_name}",
                  "positionjob" => "#{oUser&.works.where.not(positionjob_id: nil).first&.positionjob&.name}"
                })
              end
            end
          end
          return {"msg" => "Success","result" => sUsers.uniq}
        end
      end

      # Get sibling departments
      # @author: Q.Hai
      # @date: 01/02/2023
      # @input: department id
      # @output: array of departments
      desc "Get departments except directly"
      params do
        requires :department_id, type: String, desc: "Department Id"
      end
      get :get_sibling_departments do
        sDepartments = []
        department_id = params[:department_id].to_i
        # if department_id = NIL return result
        if department_id.nil? ||  department_id == ''
          return {
            "msg" => "Error: Department Id is NIL",
            "result" => sDepartments}
        end
        oNode = Node.where(:department_id => department_id).first
        if !oNode.nil?
            oStreamId = oNode.stream_id
            if !oStreamId.nil?
                oConnects = Connect.where("stream_id = #{oStreamId.to_i} AND nend = #{department_id}")
                if !oConnects.nil?
                  oConnects.each do |oConnect|
                    oDepartment = Department.where("id = #{oConnect.nbegin} AND id != #{department_id}").first
                    if !oDepartment.nil?
                      sDepartments.append({
                        "id" => "#{oDepartment.id}","name" => "#{oDepartment.name}"
                      })
                    end
                end
                    return {
                      "msg" => "Success",
                      "result" => sDepartments.uniq}
                end
            end
        end
      end

      # Get direct departments
      # @author: Q.Hai
      # @date: 01/02/2023
      # @input: department id
      # @output: array of departments
      #
      desc "Get direct departments"
      params do
        requires :department_id, type: String, desc: "Department Id"
      end
      get :get_direct_departments do
        sDepartments = []
        department_id = params[:department_id].to_i
        # if department_id = NIL return result
        if department_id.nil? ||  department_id == ''
          return {
            "msg" => "Error: Department Id is NIL",
            "result" => sDepartments
          }
        end
        oNode = Node.where(:department_id => department_id).first
        if !oNode.nil?
            oStreamId = oNode.stream_id
            if !oStreamId.nil?
                oConnects = Connect.where("stream_id = #{oStreamId.to_i} AND nbegin = #{department_id}")
                if !oConnects.nil?
                oConnects.each do |oConnect|
                    oDepartment = Department.where("id = #{oConnect.nend} AND id != #{department_id}").first
                    if !oDepartment.nil?
                      sDepartments.append({
                        "id" => "#{oDepartment.id}","name" => "#{oDepartment.name}"
                    })
                    end
                end
                    return {
                      "msg" => "Success",
                      "result" => sDepartments.uniq}
                end
            end
        end
      end

      # Get user info
      # @author: Q.Hai
      # @date: 29/06/2023
      # @input: user_id
      # @output: user info
      # desc: if get info user by NAME and EMAIL (user_id = [])
      #       if get info user by array id user (Không truyền params user_name và user_email)
      desc "Get user info"
      params do
      end
      get :get_user_info do
        sUserInfo = []
        user_id = params[:user_id]
        user_name = params[:user_name]
        user_email = params[:user_email]
        # if department_id = NIL return result
        if (user_id.nil? || user_id == '') && (user_name == "" || !user_name.nil?)
          return {
            "msg" => "Error: User id is NIL",
            "result" => sUserInfo}
        end

        if user_email != '' && !user_email.nil?
          users = User.where("concat(users.last_name, ' ', users.first_name) LIKE ? AND email = ?", "%#{user_name}%", user_email)
        else
          users = User.where(id: user_id)
        end
        users.each do |user|
          department_name = ""
          department_id = 0
          department_sid = ""
          job_name = ""
          job_names = []
          works = user.works
          works.each do |work|
              if !work.positionjob.nil? && !work.positionjob.department.nil?
                department_name = work.positionjob.department.name
                department_id = work.positionjob.department.id
                department_sid = work.positionjob.department&.faculty
                job_name = work.positionjob.name
                job_names.push(work.positionjob.name)
              else
                job_names.push(work&.stask&.name)
              end
          end
          # 26/12/2024 Q.Hai
          orname = ""
          oOgName = Uorg.where(user_id: user.id)
          if oOgName.present?
            # Dùng map để lấy danh sách tên của các organization
            organization_names = oOgName.map do |uorg|
              organization_data = Organization.find_by(id: uorg.organization_id)
              organization_data&.scode.presence
            end

            # Loại bỏ giá trị nil hoặc rỗng và nối thành chuỗi
            orname = organization_names.compact.join(", ")
          end

          sUserInfo.append({
            "id" => "#{user.id}",
            "name" => "#{user.last_name} #{user.first_name}",
            "email" => user&.email,
            "sid" => user&.sid,
            "orname" => orname,
            "job_name" => job_name,
            "job_names" => job_names,
            "department_name" => department_name,
            "department_id" => department_id.to_i,
            "department_sid" => department_sid,
          })
        end
        return {
          "msg" => "Success",
          "result" => sUserInfo.first
        }
      end

      # Get simple user info
      # @author: Khoa Nguyen
      # @date: 22/09/2025
      # @input: user_id (single ID or array of IDs)
      # @output: basic user info (id, sid, name, email only)
      desc "Get simple user info"
      params do
        requires :user_id, types: [Integer, Array], desc: "Single User ID or Array of User IDs"
      end
      post :get_simple_user_info do
        user_id = params[:user_id]

        user_ids = Array(user_id).map(&:to_i).select { |id| id > 0 }

        if user_ids.empty?
          return {
            "msg" => "Error: Valid user ID(s) required",
            "result" => nil
          }
        end

        users = User.where(id: user_ids)
                    .select(:id, :sid, :first_name, :last_name, :email)

        if users.empty?
          return {
            "msg" => "Error: No users found",
            "result" => nil
          }
        end

        users_info = users.map do |user|
          {
            "id" => user.id,
            "sid" => user.sid,
            "name" => "#{user.last_name} #{user.first_name}".strip,
            "email" => user.email
          }
        end

        result = user_id.is_a?(Array) ? users_info : users_info.first

        return {
          "msg" => "Success",
          "result" => result
        }
      end

      # Get next node schedule diagram
      # @author: H.Vu
      # @date: 21/07/2023
      # @input: department_id
      # @output: next_nodes
      desc "Get schedule next nodes"
      params do
        requires :department_id, type: String, desc: "User id"
      end
      get :get_next_nodes do
        department_id = params[:department_id]
        # stream
        stream = Stream.where(scode:"THOI-KHOA-BIEU").first
        if !stream.nil?
          node = Node.where(stream_id:stream.id).where(department_id:department_id).first
          next_nodes = []
          if !node.nil?
            nend_ids = Connect.where(stream_id: stream.id).where(nbegin:department_id).pluck(:nend)
            node_ends = Node.where(stream_id:stream.id).where(department_id:nend_ids)
            node_ends.each do |node|
              next_nodes.push({
                id: node.department.id,
                name: node.department.name
              })
            end
          end

          return {
              result: next_nodes,
              smg:""
          }
        end
      end

      # Get schedule current node flow
      # @author: H.Vu
      # @date: 21/07/2023
      # @input: department_id
      # @output: pre_nodes
      desc "Get schedule pre nodes"
      params do
        requires :department_id, type: String, desc: "User id"
      end
      get :get_previous_nodes do
        department_id = params[:department_id]

        # stream
        pre_nodes = []
        stream = Stream.where(scode:"THOI-KHOA-BIEU").first
        nbegin_ids = nil
        if !stream.nil?
          node = Node.where(stream_id:stream.id).where(department_id:department_id).first
          if !node.nil?
            nbegin_ids = Connect.where(stream_id: stream.id).where(nend:department_id).pluck(:nbegin)
            node_begins = Node.where(stream_id:stream.id).where(department_id:nbegin_ids)
            node_begins.each do |node|
              use = User.where(email: node.department.leader).first
              pre_nodes.push({
                id: node.department.id,
                name: node.department.name,
                leader: use&.id,
              })
            end
          end

          return {
            result:pre_nodes,
            smg:""
          }

        end
      end

      # Check User acction access
      # @author: H.Vu + Hai + Thai
      # @date: 20/07/2023
      # @input: user_id, resource_code, ptype
      # @output: department flow
      #
      desc "Check user action access permission"
      params do
        requires :user_id, type: String, desc: "User id"
        requires :resource_code, type: String, desc: "resource code"
        requires :ptype, type: String, desc: "permission type"
      end
      get :is_permission do
        isAccess = false
        # params
        user_id = params[:user_id]
        resource_code = params[:resource_code]
        ptype = params[:ptype] # permissions table

        permisions = []
        user = User.where(id:user_id).first
        if !user.nil?
          stream = Stream.where("scode = 'CO-CAU-TO-CHUC'").first
          if !stream.nil?
            permisions = ApplicationController.new.get_user_permission(user.id, stream.id)
          end

          # check permission
          is_access = permisions.any?{ |permision|  (permision['resource'] == resource_code && permision['permission'] == ptype) ||
                                                    (permision['resource'] == resource_code && permision['permission'] == "ADM")}

          return {
            result:is_access,
            msg:""
          }
        else
          return {
            result: false,
            msg:""
          }
        end
      end

      # Check list permissions of user
      # @author: H.Vu
      # @date: 09/07/2024
      # @input: user_id, permission list
      # @output: department flow
      #
      desc "Check user permission list, should call once"
      params do
        requires :user_id, type: String, desc: "User id"
        requires :permissions, type: Array, desc: "permission name list"
      end
      get :get_list_permissions do
        # params
        user_id = params[:user_id]
        permissions = params[:permissions]
        results = []
        per_temp = {}
        record_permissions = []
        begin
          user = User.where(id:user_id).first
          if !user.nil?
            # get permission from stream
            stream = Stream.where("scode = 'CO-CAU-TO-CHUC'").first
            if !stream.nil?
              record_permissions = ApplicationController.new.get_user_permission(user.id, stream.id)
              # find and store
              record_permissions.each do |permission_record|
                resource = permission_record["resource"]
                right = permission_record["permission"]
                if permissions.any?{|name| name == resource}
                  if per_temp[resource].nil?
                    per_temp[resource] = [right]
                  else
                    if !per_temp[resource].include?(right)
                      per_temp[resource].push(right)
                    end
                  end
                end
              end
              per_temp.each do |key,val|
                results.push("#{key}$$$#{val.uniq.join("$")}")
              end
            end
          end
          return {
            result: true,
            msg: results,
          }
        rescue => exception
          position = exception.backtrace.to_json.html_safe.gsub("\`","")
          message = exception.message.gsub("\`","")
          return {
            result: false,
            msg:"#{message} #{position}"
          }
        end
      end

      # Check user is need to be update permission
      # @author: H.Vu
      # @date: 27/07/2023
      # @input: user_id , system
      # @output: true | false
      #
      desc "Check user is need to be update permission"
      params do
        requires :user_id, type: String, desc: "User id"
        requires :system, type: String, desc: "System name"
      end
      get :is_permission_update do
        user_id = params[:user_id]
        system_name = params[:system]
        is_update = false

        user = User.where(id:user_id).first
        if !user.nil?
          isvalid  = user.isvalid.nil? ? [] :  user.isvalid.split("||")
          case system_name
          when "erp"
            is_update = isvalid[0] == "YES"
          when "sft"
            is_update = isvalid[1] == "YES"
          when "masset"
            is_update = isvalid[2] == "YES"
          when "hasset"
            is_update = isvalid[3] == "YES"
          else

          end

        else
          is_update = true
        end

        return {
          result: is_update,
          msg:""
        }
      end

      # Set status after logout user
      # @author: H.Vu
      # @date: 27/07/2023
      # @input: user_id , system
      # @output:
      #
      desc "Update status"
      params do
        requires :user_id, type: String, desc: "User id"
        requires :system, type: String, desc: "System name"
      end
      get :update_status_permisstion do
        user_id = params[:user_id]
        system_name = params[:system]
        is_update = true

        user = User.where(id:user_id).first
        if !user.nil?
          isvalid  = user.isvalid.nil? ? [] :  user.isvalid.split("||")
          case system_name
          when "erp"
            isvalid[0] = "NO"
          when "sft"
            isvalid[1] = "NO"
          when "masset"
            isvalid[2] = "NO"
          when "hasset"
            isvalid[3] = "NO"
          else

          end
          user.isvalid = isvalid.join("||")
          user.save
        end

        return {
          result:"DONE",
          msg:""
        }
      end


      # Tạo thông báo khi PĐT nhấn nút trình TKB cho BGH duyệt
      # @author: H.Anh
      # @date: 02/08/2023
      # @input: title , contents, receivers, user_id, senders
      # @output: msg
      # true: lưu data cho Notify và Snotice cho ERP
      # false: msg
      desc "Send notify aprove schedule erp"
      params do
        requires :title, type: String
        requires :contents, type: String
        requires :receivers, type: String
        requires :user_id, type: String
        requires :senders, type: String
        requires :stype, type: String
      end
      post :create_notify_erp do
        msg = "Not Success"
        eresult = false
        snotice = ""
        begin
          if  params[:title].present? && params[:contents].present? && params[:user_id].present?
            newNotify = Notify.create({
              title: params[:title],
              contents: params[:contents],
              receivers: params[:receivers],
              senders: params[:senders],
              stype: params[:stype],
            })
            if newNotify.present?
                msg = "Success"
                eresult = true
                snotice = Snotice.create({
                  notify_id: newNotify.id,
                  user_id: params[:user_id],
                  isread: false
                })
            end
            return {
              msg: msg,
              result: eresult,
            }
          else
            return {
              msg: "Thiếu thông tin cần thiết",
              result: false,
            }
          end
        rescue => e
          return {
            "msg" => "Error: #{e}",
            result: false,
          }
        end
      end
      # Lấy thông báo từ ERP
      # @author: H.Anh
      # @date: 25/06/2024
      # @input: user_id, receivers
      # @output: msg
      desc "Get list notify"
      params do
        requires :user_id, type: String
      end
      get :get_list_notify do
        msg = "Not Success"
        result = []
        begin
          if params[:user_id].present?
            datas = Notify.where(receivers: "SFT_NOTIFY")
            datas.each do |item|
              snoti = Snotice.where(user_id: params[:user_id], notify_id: item.id, isread: false).first
              if snoti.present?
                result.push({
                  id_snoti: snoti.id,
                  is_read: snoti.isread,
                  title: item.title,
                  contents: item.contents,
                  senders: item.senders
                })
              end
            end
            # Sắp xếp result theo is_read, false trước true sau
            result.sort_by! { |h| h[:is_read] ? 1 : 0 }
            msg = "Success"
          end
          return {
            msg: msg,
            result: result,
          }
          rescue => e
          return {
            "msg" => "Error: #{e}",
            result: msg,
          }
        end
      end
      # Chuyển trạng thái đã đọc thông báo
      # @author: H.Anh
      # @date: 25/06/2024
      # @input: id_snoti
      # @output: msg
      desc "change snotify read"
      params do
        requires :id_snoti, type: String
      end
      post :change_snotify_read do
        msg = "Not Success"
        eresult = false
        begin
          if params[:id_snoti].present?
              snoti = Snotice.where(id: params[:id_snoti]).first
              if snoti.present? && !snoti.isread
                  snoti.update(isread: true)
              end
            msg = "Success"
            eresult = true
          end
          return {
            msg: msg,
            result: eresult,
          }
          rescue => e
          return {
            "msg" => "Error: #{e}",
            result: eresult,
          }
        end
      end
      # Get maintain time
      # @author: Hoang Tuan Dat
      # @date: 31/08/2023
      # @output: Maintain records
      desc "Get maintain"
      params do
        requires :app, type: String, desc: "App name"
      end
      get :get_maintain do
        app = params[:app]
        msg = {}
        if !app.nil? && app != ""
          oMaintain = Maintenance.where(app: app).first
          if !oMaintain.nil? && oMaintain&.status == "YES"
              msg = oMaintain
            return  {
              :result => true,
              :msg =>  msg,
            }
          else
            return  {
              :result => false,
              :msg =>  msg,
            }
          end
        else
          return {
            :result => false,
            :msg =>  msg,
          }
        end

      end


      # Generate random password for user
      # @author: H.Vu
      # @date: 05/09/2023
      # @input: email
      # @output: string
      desc "generate and update user password with valid_to 9999"
      params do
        requires :email, type: String, desc: "user email"
      end
      get :generate_password do
        email = params[:email]
        # random pass
        lowercase = ('a'..'z').to_a
        uppercase = ('A'..'Z').to_a
        digits = ('0'..'9').to_a
        special_chars = ['@']
        random_lowercase = lowercase.sample
        random_uppercase = uppercase.sample
        random_digit = digits.sample
        random_special_char = special_chars.sample
        random_characters = [random_lowercase, random_uppercase, random_digit, random_special_char]
        remaining_length = 8 - random_characters.length
        remaining_characters = (lowercase + uppercase + digits + special_chars).sample(remaining_length)
        random_characters.concat(remaining_characters)
        random_characters.shuffle!
        random_password =  random_characters.join

        # update password
        user = User.where(email:email).first
        if !user.nil?
          user.update({valid_to: 9999,tmppwd: Digest::MD5.hexdigest(random_password)})
        end
        # User.update_all(, {email: email})

        return {
          "smg" => "",
          "result" => random_password
        }

      end
      # Get documents
      # @author: Hoàng Anh
      # @date: 14/09/2023
      # @output: Mydoc records
      desc "Get document"
      params do
        requires :app, type: String, desc: "App name"
      end
      get :get_document do
        app = params[:app]
        msg = {}
        if !app.nil? && app != ""
          mydocs = Mydoc.where(app: app).first
          if !mydocs.nil?
              msg = mydocs
            return  {
              :result => true,
              :msg =>  msg,
            }
          else
            return  {
              :result => false,
              :msg =>  msg,
            }
          end
        else
          return {
            :result => false,
            :msg =>  msg,
          }
        end
      end
      # Lấy danh sách giảng viên cho kế hoạch thi
      # @author: Hoàng Anh
      # @date: 05/08/2024
      # @output:
      desc "Lấy danh sách giảng viên"
      params do end
      get :get_lecturers_exam_plan do
        query = Work.left_outer_joins(:stask).includes(:stask)
                    .left_outer_joins(:positionjob).includes(:positionjob)
                    .joins(:user)
                    .where(
                      "users.staff_status = :status1 OR users.staff_status = :status2",
                      status1: 'DANG-LAM-VIEC',
                      status2: 'Đang làm việc'
                    )
        # result handle
        datas = []
        query.each do |work|
          if !datas.any? { |hash| hash["id"] == work.user.id }
            user = work.user
            department_id = work.positionjob&.department&.id
            department_sid = work.positionjob&.department&.faculty

            if department_id.present?
              org_id = work.positionjob.department.organization_id
              org_scode = Organization.where(id: org_id).first&.scode
              if org_scode == "BMTU" || org_scode == "BMU"
                if work.positionjob&.name&.downcase&.include?("giảng viên") || work.positionjob&.name&.downcase&.include?("kỹ thuật viên") || work.positionjob&.name&.downcase&.include?("trợ giảng") || department_sid == "KT-DBCL"
                  datas.push({
                    id: user.id,
                    sid: user.sid,
                    name: "#{user.last_name} #{user.first_name}",
                    email: user.email,
                    department_name: work.positionjob&.department&.name,
                    positionjob_name: work.positionjob&.name,
                    department_id: department_id
                  })
                end
              end
            end
          end
        end
        return {
          datas: datas
        }
      end

      desc "Get Notice ERP"
      params do
      end
      get :get_notices_erp do
        begin
          stype = params[:stype]
          user_id = params[:user_id]

          if stype.present?
            Snotice.where("user_id = ? AND (isread IS NULL OR isread = ?)", user_id, false).update_all(isread: true, dtread: DateTime.now)
          end

          notices = Snotice.joins(:notify)
            .select("snotices.*, notifies.*, snotices.id as id, notifies.id as notify_id, snotices.status as status_notice, notifies.status as status_notify")
            .where("snotices.user_id = ?", user_id)
            .order(id: :DESC)
            .limit(20)

          notices_total = Snotice.joins(:notify)
            .where("snotices.user_id = ? AND (snotices.isread IS NULL OR snotices.isread = ?)", user_id, false)
            .count

          return {
            total: notices_total,
            notices: notices
          }
        rescue => e
          return {
            :msg => "Error: #{e.message}",
            :result => []
          }
        end
      end

      desc "Get Notice detail ERP"
      params do
      end
      get :get_notice_detail_erp do
        begin
          snotices_id = params[:snotices_id]
          notice = Snotice.joins(:notify)
              .select("snotices.*, notifies.*, snotices.id as id, notifies.id as notify_id, snotices.status as status_notice, notifies.status as status_notify")
              .find_by("snotices.id = ?", snotices_id)
          notice.update(isread: true, dtread: DateTime.now)

          return {
            msg: "Success",
            notice: notice
          }
        rescue => e
          return {
            :msg => "Error: #{e.message}",
            :notice => nil
          }
        end
      end

      desc "Get count Notice ERP"
      params do
      end
      get :get_count_notice_erp do
        begin
          user_id = params[:user_id]
          notices_count = Snotice.joins(:notify)
            .where("snotices.user_id = ? AND (snotices.isread IS NULL OR snotices.isread = ?)", user_id, false)
            .where(created_at: 1.week.ago..Time.current)
            .count

          return {
            msg: "Success",
            notices_count: notices_count
          }
        rescue => e
          return {
            :msg => "Error: #{e.message}",
            :notices_count => nil
          }
        end
      end

      desc "Get Notice new today ERP"
      params do
      end
      get :get_notice_new_today_erp do
        begin
          user_id = params[:user_id]
          notices = Snotice.joins(:notify)
            .select("notifies.*")
            .where("snotices.user_id = ? AND (snotices.isread IS NULL OR snotices.isread = ?)", user_id, false).where("snotices.created_at >= ?", 8.hour.ago)
          return {
            msg: "Success",
            notices: notices
          }
        rescue => e
          return {
            :msg => "Error: #{e.message}",
            :notices => []
          }
        end
      end


    # @author: trong.lq
    # @date: 22/10/2025
    # API endpoint test đơn giản
    desc "API test trả về string"
    get :test_hello do
      begin
        { msg: "Say helloo" }
      rescue => e
        error!({ msg: "Lỗi: #{e.message}" }, 500)
      end
    end

    # @author: trong.lq
    # @date: 22/10/2025
    # API endpoint để lấy thông tin văn bằng đã cấp phát (gọi từ sftraining)
    desc "Lấy thông tin văn bằng đã cấp phát"
    params do
      optional :identity_cccd, type: String, desc: "Số định danh cá nhân người được cấp bằng"
      optional :student_sid, type: String, desc: "Mã định danh người học"
      optional :serial_number, type: String, desc: "Số hiệu VBCC"
      optional :type, type: String, desc: "Loại VBCC: all (tất cả), VB (Văn bằng), CC (Chứng chỉ). Mặc định: all"
    end
    get :get_degree_info do
      begin
        # Lấy các tham số từ request
        query_params = {}
        query_params[:identity_cccd] = params[:identity_cccd] if params[:identity_cccd].present?
        query_params[:cccd] = params[:cccd] if params[:cccd].present?
        query_params[:student_sid] = params[:student_sid] if params[:student_sid].present?
        query_params[:sid] = params[:sid] if params[:sid].present?
        query_params[:serial_number] = params[:serial_number] if params[:serial_number].present?
        query_params[:serial] = params[:serial] if params[:serial].present?
        query_params[:type] = params[:type] if params[:type].present?

        # Xây dựng URL với query parameters
        api_url = "https://erp.bmtu.edu.vn/sftraining/api/v1/mapi_utils/get_degree_info"

        # Thêm query parameters vào URL
        if query_params.any?
          query_string = query_params.map { |k, v| "#{k}=#{CGI.escape(v.to_s)}" }.join("&")
          api_url += "?#{query_string}"
        end

        # Gọi API từ sftraining
        response = RestClient::Request.execute(
          method: :get,
          url: api_url,
          timeout: 30,
          open_timeout: 30
        )

        # Parse response JSON
        result = JSON.parse(response.body)

        # Trả về kết quả
        result

      rescue RestClient::ExceptionWithResponse => e
        # Xử lý lỗi từ API
        begin
          error_body = JSON.parse(e.response.body) rescue {}
          error!({
            msg: error_body['msg'] || "Lỗi khi gọi API sftraining: #{e.message}",
            result: error_body['result'] || [],
            status: e.http_code || 500
          }, e.http_code || 500)
        rescue
          error!({
            msg: "Lỗi khi gọi API sftraining: #{e.message}",
            result: [],
            status: 500
          }, 500)
        end
      rescue => e
        error!({
          msg: "Lỗi hệ thống: #{e.message}",
          result: [],
          status: 500
        }, 500)
      end
    end
  # ===========================================================================

  # ============================= API Stream ==================================
    # Get next node approve exschedule
    # @author: Hoàng Anh
    # @date: 09/09/2024
    # @input: department_id
    # @output: next_nodes
    desc "Get exschedule pre nodes"
    params do
      requires :department_id, type: String, desc: "department id"
    end
    get :get_next_nodes_exschedule do
      department_id = params[:department_id]
      next_nodes = []
      forms = nil
      leaders = []
      # nfirst
      department_nfirst = get_nfirst_node_assets("DUYET-KE-HOACH-THI")
      # stream
      stream = Stream.where(scode: "DUYET-KE-HOACH-THI").first
      nbegin_ids = nil
      if !stream.nil?
        node = Node.where(stream_id:stream.id).where(department_id:[department_id.to_i, department_nfirst[:result][:id]]).first
        if !node.nil?
          nend_ids = Connect.where(stream_id: stream.id).where(nbegin: [department_id.to_i, department_nfirst[:result][:id]])
          node_ends = Node.where(stream_id: stream.id).where(department_id:nend_ids.pluck(:nend))
          # forms = nend_ids.pluck(:forms)
          node_ends.each do |node|
            leaders = []
            node.department.works.each do |work|
              # if !work&.user&.avatar.nil?
              #   avatar_url = request.base_url + "/mdata/hrm/" +  Mediafile.where("id = #{work.user.avatar}").first&.file_name
              # end
              if work&.positionjob&.scode&.include?("TRUONG") || work&.positionjob&.scode&.include?("PHO") || work&.positionjob&.scode&.include?("GIAM-DOC") || work&.positionjob&.scode&.include?("CHU-TICH") || work&.positionjob&.scode&.include?("PHU-TRACH")
                leaders.push(
                  id: work.user.id,
                  sid: work&.user&.sid,
                  name: "#{work&.user&.last_name} #{work&.user&.first_name}",
                  # avatar:avatar_url,
                  email: work&.user&.email,
                  mobile: work&.user&.mobile,
                  positionjob_name: work&.positionjob&.name,
                )
              # else
              #   users.push(
              #     id: work.user.id,
              #     sid: work&.user&.sid,
              #     name: "#{work&.user&.last_name} #{work&.user&.first_name}",
              #     # avatar:avatar_url,
              #     email: work&.user&.email,
              #     mobile: work&.user&.mobile,
              #     positionjob_name: work&.positionjob&.name,
              #   )
              end
            end
            node.stream.connects.each do |connect|
              if connect.nend.to_i == node.department_id.to_i && (connect.nbegin.to_i ==  department_id.to_i || connect.nbegin.to_i == department_nfirst[:result][:id])
                forms = connect.forms
              end
            end

            next_nodes.push({
              department_id: node.department.id,
              department_name: node.department.name,
              department_scode: node.department.scode,
              # users: users,
              leaders: leaders,
              # forms: forms
            })
          end
        end
        return {
          result: next_nodes,
          msg: ""
        }
      end
      return {
          result: "stream not found",
          msg: ""
        }
    end

    # Get next node Liquidation asssets
    # @author: Minh Tuan
    # @date: 03/11/2023
    # @output: next_nodes
    desc "Get liquidation next nodes"
    params do
      requires :department_id, type: String, desc: "Department id"
    end
    get :get_next_nodes_liquidation do
      department_id = params[:department_id]
      # stream
      stream = Stream.where(scode:"QUAN-LY-THANH-LY-TAI-SAN").first
      if !stream.nil?
        node = Node.where(stream_id:stream.id).where(department_id:department_id).first
        next_nodes = []
        if !node.nil?
          nend_ids = Connect.where(stream_id: stream.id).where(nbegin:department_id).pluck(:nend)
          node_ends = Node.where(stream_id:stream.id).where(department_id:nend_ids)
          node_ends.each do |node|
            next_nodes.push({
              id: node.department.id,
              name: node.department.name,
            })
          end
        end

        return {
            result: next_nodes,
            smg:""
        }

      end
    end

    # Get previous node Liquidation asssets
    # @author: Minh Tuan
    # @date: 04/11/2023
    # @output: previous_nodes
    desc "Get liquidation pre nodes"
    params do
      requires :department_id, type: String, desc: "Department id"
    end
    get :get_previous_nodes_liquidation do
      department_id = params[:department_id]

      # stream
      pre_nodes = []
      stream = Stream.where(scode:"QUAN-LY-THANH-LY-TAI-SAN").first
      nbegin_ids = nil
      if !stream.nil?
        node = Node.where(stream_id:stream.id).where(department_id:department_id).first
        if !node.nil?
          nbegin_ids = Connect.where(stream_id: stream.id).where(nend:department_id).pluck(:nbegin)
          node_begins = Node.where(stream_id:stream.id).where(department_id:nbegin_ids)
          node_begins.each do |node|
            pre_nodes.push({
              id: node.department.id,
              name: node.department.name,
            })
          end
        end
        return {
          result:pre_nodes,
          smg:""
        }
      end
    end

    # Get nfirst node regiter to use
    # @date: 08/11/2023
    # @input: department_id
    # @output: next_nodes
    desc "Get schedule pre nodes"
    params do
      requires :scode , type: String, desc: "User id"
    end
    get :get_nfirst_node_assets do
      scode = params[:scode]

      oDepartment = nil
      forms = []
      # stream
      stream = Stream.where(scode: scode).first
      if !stream.nil?
        node = Node.where(stream_id:stream.id, nfirst: "YES").first
        if !node.nil?
          oDepartment = {
            id: node&.department.id,
            name: node&.department.name,
            stype: node&.department.stype,
          }
        end
        # forms = Connect.where(nbegin: node&.department_id, stream_id:stream.id).pluck(:forms)
      end
      return {
        result: oDepartment,
        msg:""
      }
    end

    # Get next node regiter to use
    # @date: 08/11/2023
    # @input: department_id
    # @output: next_nodes
    desc "Get schedule pre nodes"
    params do
      requires :department_id, type: String, desc: "department id"
      requires :scode, type: String, desc: "Scode id"

    end
    get :get_next_nodes_assets do
      department_id = params[:department_id]
      scode = params[:scode]

      next_nodes = []
      users = []
      forms = nil
      leaders = []
      # nfirst
      department_nfirst = get_nfirst_node_assets(scode)
      # stream
      stream = Stream.where(scode: scode).first
      nbegin_ids = nil
      if !stream.nil?
        node = Node.where(stream_id:stream.id).where(department_id:[department_id.to_i, department_nfirst[:result][:id]]).first
        if !node.nil?
          nend_ids = Connect.where(stream_id: stream.id).where(nbegin: [department_id.to_i, department_nfirst[:result][:id]])
          node_ends = Node.where(stream_id: stream.id).where(department_id:nend_ids.pluck(:nend))
          # forms = nend_ids.pluck(:forms)
          node_ends.each do |node|
            users = []
            leaders = []
            node.department.works.each do |work|
              if !work&.user&.avatar.nil?
                avatar_url = request.base_url + "/mdata/hrm/" +  Mediafile.where("id = #{work.user.avatar}").first&.file_name
              end
              if work&.positionjob&.scode&.include?("TRUONG") || work&.positionjob&.scode&.include?("PHO") || work&.positionjob&.scode&.include?("GIAM-DOC") || work&.positionjob&.scode&.include?("CHU-TICH") || work&.positionjob&.scode&.include?("PHU-TRACH")
                leaders.push(
                  id: work.user.id,
                  sid: work&.user&.sid,
                  name: "#{work&.user&.last_name} #{work&.user&.first_name}",
                  avatar:avatar_url,
                  email: work&.user&.email,
                  mobile: work&.user&.mobile,
                  positionjob_name: work&.positionjob&.name,
                )
              else
                users.push(
                  id: work.user.id,
                  sid: work&.user&.sid,
                  name: "#{work&.user&.last_name} #{work&.user&.first_name}",
                  avatar:avatar_url,
                  email: work&.user&.email,
                  mobile: work&.user&.mobile,
                  positionjob_name: work&.positionjob&.name,
                )
              end
            end
            node.stream.connects.each do |connect|
              if connect.nend.to_i == node.department_id.to_i && (connect.nbegin.to_i ==  department_id.to_i || connect.nbegin.to_i == department_nfirst[:result][:id])
                forms = connect.forms
              end
            end

            next_nodes.push({
              department_id: node.department.id,
              department_name: node.department.name,
              department_scode: node.department.scode,
              users: users,
              leaders: leaders,
              forms: forms
            })
          end
        end
      end
      return {
        result: next_nodes,
        msg: ""
      }
    end

    # Thai 19/09/2024
    desc "Get next nodes schedule of orders, Hàm để lấy nhiều form xử lý trên sơ đồ, danh sách nhân sự và trưởng phòng"
    params do
      requires :department_id, type: String, desc: "department id"
      requires :scode, type: String, desc: "Scode id"
    end
    get :get_next_nodes_orders do
      department_id = params[:department_id]
      scode = params[:scode]

      next_nodes = []
      users = []
      forms = nil
      leaders = []
      # nfirst
      department_nfirst = get_nfirst_node_assets(scode)
      # stream
      stream = Stream.where(scode: scode).first
      nbegin_ids = nil
      if !stream.nil?
        node = Node.where(stream_id:stream.id).where(department_id:[department_id.to_i, department_nfirst[:result][:id]]).first
        if !node.nil?
          nend_ids = Connect.where(stream_id: stream.id).where(nbegin: [department_id.to_i, department_nfirst[:result][:id]])
          node_ends = Node.where(stream_id: stream.id).where(department_id:nend_ids.pluck(:nend))

          nend_ids.each do |connect|
            if connect.nbegin.to_i ==  department_id.to_i || connect.nbegin.to_i == department_nfirst[:result][:id].to_i
              forms = connect.forms
              department = Department.where(id: connect.nend).first
              leaders = []
              users = []
              if !department.nil?
                department.works.each do |work|
                  user = work&.user
                  next if user.nil? || user.status == 'INACTIVE'
                  if !user&.avatar.nil?
                    avatar_url = request.base_url + "/mdata/hrm/" +  Mediafile.where("id = #{work.user.avatar}").first&.file_name
                  end
                  if work&.positionjob&.scode&.include?("TRUONG") || work&.positionjob&.scode&.include?("PHO") || work&.positionjob&.scode&.include?("GIAM-DOC") || work&.positionjob&.scode&.include?("CHU-TICH") || work&.positionjob&.scode&.include?("PHU-TRACH")
                    leaders.push(
                      id: work.user.id,
                      sid: user&.sid,
                      name: "#{user&.last_name} #{user&.first_name}",
                      avatar:avatar_url,
                      email: user&.email,
                      mobile: user&.mobile,
                      positionjob_name: work&.positionjob&.name,
                    )
                  else
                    users.push(
                      id: work.user.id,
                      sid: user&.sid,
                      name: "#{user&.last_name} #{user&.first_name}",
                      avatar:avatar_url,
                      email: user&.email,
                      mobile: user&.mobile,
                      positionjob_name: work&.positionjob&.name,
                    )
                  end
                end
                  next_nodes.push({
                    department_id: department.id,
                    department_name: department.name,
                    department_scode: department.scode,
                    users: users,
                    leaders: leaders,
                    forms: forms
                  })
              end
            end
          end
        end
      end
      return {
        result: next_nodes,
        msg: ""
      }
    end

    desc "Get current connects"
    params do
      requires :scode, type: String, desc: "Stream scode"
      requires :status, type: String, desc: ""
    end
    get :stream_connect_by_status do
      scode = params[:scode]
      status = params[:status]

      connects = Connect.select("connects.forms,connects.status, connects.idenfity,de.scode as department_scode,de.name as department_name,de.id as department_id")
                      .joins(:stream)
                      .joins("LEFT JOIN departments as de ON de.id = connects.nend")
                      .where(streams:{scode: scode})
      next_connects = nil
      if status.nil? || status.empty?
        next_connects = connects.select{|connect| connect.idenfity == "1"}
      else
        next_connects = connects.select{|connect| connect.status == status}
      end
      result = next_connects.map do |connect|
        {
          forms: connect.forms,
          result: connect.idenfity.split("-")[1],
          department_scode: connect.department_scode,
          department_name: connect.department_name,
          department_id: connect.department_id
        }
      end

      return {:msg => "",:result => result}
    end
  # ============================================================================

  # ========== CSVC ==============
    # @author: Lê Ngọc Huy
    # @output: List users
    desc "Get list users ERP"
    params do end
    get :get_users_erp do
      datas = []
      org = params[:org] || ['BU', "BMTU", "BMU"]
      search = params[:search].to_s.strip
      page = params[:page]&.to_i || 1
      per_page = params[:per_page]&.to_i || 10
      is_paginate = params[:is_paginate].to_s.downcase == 'true'
      department_id = params[:department_id].presence
      offset = (page - 1) * per_page
      search = "%#{search.downcase}%"

      if is_paginate
        query = Work
                  .joins(user: { uorgs: :organization })
                  .where(organizations: { scode: org })
                  .where(
                    " (LOWER(users.last_name) LIKE :search OR
                 LOWER(users.first_name) LIKE :search OR
                 LOWER(CONCAT(users.first_name, ' ', users.last_name)) LIKE :search OR
                 LOWER(CONCAT(users.last_name,  ' ', users.first_name)) LIKE :search OR
                 LOWER(users.email) LIKE :search OR
                 LOWER(users.sid)   LIKE :search)",
                    { search: search }
                  )

        latest_sql =
          if department_id.present?
            Work.joins(:positionjob)
                .where(positionjobs: { department_id: department_id })
                .select("MAX(works.id) AS id")
                .group("works.user_id")
                .to_sql
          else
            Work.select("MAX(works.id) AS id")
                .group("works.user_id")
                .to_sql
          end

        query = query.where("works.id IN (#{latest_sql})")
        total = query.select('users.id').distinct.count
        works = query
                  .preload(:user, positionjob: :department)
                  .limit(per_page)
                  .offset(offset)
                  .to_a
        users       = works.map(&:user).compact
        avatar_ids  = users.map(&:avatar).compact.uniq
        media_map   = avatar_ids.any? ? Mediafile.where(id: avatar_ids).pluck(:id, :file_name).to_h : {}
        works.each do |work|
          user = work.user
          next if user.nil? || user.status == 'INACTIVE'
          department_id = work.positionjob&.department&.id
          next if department_id.nil?
          if !user.avatar.nil?
            file_name  = media_map[user.avatar.to_i]
            avatar_url = file_name ? (request.base_url + "/mdata/hrm/" + file_name) : nil
          else
            avatar_url = nil
          end
          datas.push({
                       id: user.id,
                       sid: user.sid,
                       name: "#{user.last_name} #{user.first_name}",
                       last_name: user.last_name,
                       first_name: user.first_name,
                       avatar: avatar_url,
                       email: user.email,
                       department_name: work.positionjob&.department&.name,
                       department_id: department_id,
                       positionjob_name: work.positionjob&.name,
                     })
        end
        load_more = (page * per_page) < total
      else
        query = Work.left_outer_joins(:stask).includes(:stask)
                    .left_outer_joins(:positionjob).includes(:positionjob)
                    .joins(user: { uorgs: :organization })
                    .where(organizations: { scode: org })
                    .where(" (users.last_name LIKE :search OR users.first_name LIKE :search OR CONCAT(users.first_name,' ', users.last_name) LIKE :search OR users.email LIKE :search )",{search: search})
        # result handle
        query.each do |work|
          if !datas.any? { |hash| hash["id"] == work.user.id }
            user = work.user
            next if user.nil? || user.status == 'INACTIVE'
            department_id = work.positionjob.nil? ? nil : work.positionjob&.department&.id
            if !department_id.nil?
              org_id = work.positionjob.department.organization_id
              # org_scode = Organization.where(id:org_id).first&.scode
              if !user.avatar.nil?
                avatar_url = request.base_url + "/mdata/hrm/" +  Mediafile.where("id = #{user.avatar}").first.file_name
              else
                avatar_url = nil
              end
              datas.push({
                           id: user.id,
                           sid:user.sid,
                           name: "#{user.last_name} #{user.first_name}",
                           last_name: user.last_name,
                           first_name: user.first_name,
                           avatar:avatar_url,
                           email:user.email,
                           department_name: work.positionjob.nil? ? nil : work.positionjob&.department&.name,
                           department_id: work.positionjob.nil? ? nil : work.positionjob&.department&.id,
                           positionjob_name: work.positionjob.nil? ? nil : work.positionjob&.name,
                         })
            end
          end
        end
        load_more = false
      end

      return {
        datas: datas,
        load_more: load_more
      }
    end

    # @author: Lê Ngọc Huy
    # @output: List leaders in department
    desc "Get users the right to register"
    params do end
    get :get_users_or_leader_in_department do
      smg = ""
      department_id = params[:id_department]&.split(",")
      users = []
      leaders = []
      # oDepartment = Department.where(id: department_id).where.not("name LIKE ?", "%Bộ phận%")
      oDepartment = Department.where(id: department_id)
      if !oDepartment.nil?
        oDepartment.each do |department|
          department.works.each do |work|
            if !work&.user&.avatar.nil?
              avatar_url = request.base_url + "/mdata/hrm/" +  Mediafile.where("id = #{work.user.avatar}").first&.file_name
            end
              if work&.positionjob&.scode&.include?("TRUONG") || work&.positionjob&.scode&.include?("PHO") || work&.positionjob&.scode&.include?("GIAM-DOC") || work&.positionjob&.scode&.include?("CHU-TICH") || work&.positionjob&.scode&.include?("PHU-TRACH")
                leaders.push(
                  id: work.user.id,
                  sid: work&.user&.sid,
                  name: "#{work&.user&.last_name} #{work&.user&.first_name}",
                  avatar:avatar_url,
                  email: work&.user&.email,
                  mobile: work&.user&.mobile,
                  department_name: department.name,
                  department_id: department.id,
                  positionjob_name: work&.positionjob&.name,
                )
              else
                users.push(
                  id: work.user.id,
                  sid: work&.user&.sid,
                  name: "#{work&.user&.last_name} #{work&.user&.first_name}",
                  avatar:avatar_url,
                  email: work&.user&.email,
                  mobile: work&.user&.mobile,
                  department_name: department.name,
                  department_id: department.id,
                  positionjob_name: work&.positionjob&.name,
                )
              end
          end
        end
      end
      leaders = leaders&.sort_by { |item| item[:positionjob_name] != "Trưởng phòng" ? 1 : 0 }
      return {
        result: {
          users: users,
          leaders: leaders,
        },
        msg: oDepartment,
        department_id: department_id,
      }
    end
    desc "Get leader in department"
    params do end
    get :get_leader_in_department do
      smg = ""
      department_id = params[:id_department]&.split(",")
      leaders = []
      # oDepartment = Department.where(id: department_id).where.not("name LIKE ?", "%Bộ phận%")
      oDepartment = Department.find_by(id: department_id)
      if !oDepartment.nil?
        oDepartment.works.each do |work|
          if !work&.user&.avatar.nil?
            avatar_url = request.base_url + "/mdata/hrm/" +  Mediafile.where("id = #{work.user.avatar}").first&.file_name
          end
          if work&.positionjob&.scode&.include?("TRUONG") || work&.positionjob&.scode&.include?("PHO") || work&.positionjob&.scode&.include?("GIAM-DOC") || work&.positionjob&.scode&.include?("CHU-TICH") || work&.positionjob&.scode&.include?("PHU-TRACH")
            leaders.push(
              id: work.user.id,
              sid: work&.user&.sid,
              name: "#{work&.user&.last_name} #{work&.user&.first_name}",
              avatar:avatar_url,
              email: work&.user&.email,
              mobile: work&.user&.mobile,
              department_name: oDepartment.name,
              department_id: oDepartment.id,
              positionjob_name: work&.positionjob&.name,
            )
          end
        end
      end
      if leaders.length < 1
        nextStepData = stream_connect_by_status("DUYET-PHEP-BMU", "BOARD-APPROVE")
        department = Department.find_by(id: nextStepData.first[:next_department_id])
        if department.present?
          department.works.each do |work|
            if !work&.user&.avatar.nil?
              avatar_url = request.base_url + "/mdata/hrm/" +  Mediafile.where("id = #{work.user.avatar}").first&.file_name
            end
            if work&.positionjob&.scode&.include?("TRUONG") || work&.positionjob&.scode&.include?("PHO") || work&.positionjob&.scode&.include?("GIAM-DOC") || work&.positionjob&.scode&.include?("CHU-TICH") || work&.positionjob&.scode&.include?("PHU-TRACH")
              leaders.push(
                id: work.user.id,
                sid: work&.user&.sid,
                name: "#{work&.user&.last_name} #{work&.user&.first_name}",
                avatar:avatar_url,
                email: work&.user&.email,
                mobile: work&.user&.mobile,
                department_name: department.name,
                department_id: department.id,
                positionjob_name: work&.positionjob&.name,
              )
            end
          end
        end
      end
      leaders = leaders&.sort_by { |item| item[:positionjob_name] != "Trưởng phòng" ? 1 : 0 }
      return {
        result: {
          leaders: leaders,
        },
        msg: oDepartment,
        department_id: department_id,
      }
    end

    # Get organization
    # @date: 12/12/2023
    desc "Get organization"
    get :get_organization do
      data_org = []
      oOrganization = Organization.all
      oOrganization.each do |org|
        data_org.push({
          name: org.name,
          scode: org.scode,
        })
      end
      return {
        result: data_org,
        msg:""
      }
    end

    # @author: Lê Ngọc Huy
    # @output: List users is assets
    desc "Get users the right to register"
    params do end
    get :get_users_is_asset_resource do
      resource = params[:resource]
      permision = params[:permision]
      datas = []
      datas = User.joins(works: {stask: {accesses: :resource}})
                  .select('users.id, CONCAT(users.last_name," ",users.first_name) as fullname, users.avatar')
                  .where("resources.scode = ? AND accesses.permision = ?", "#{resource}", "#{permision}")
                  .map { |user|
                    department = user.works&.where("positionjob_id IS NOT NULL")&.first&.positionjob&.department
                    mediafile = Mediafile.where(id: user.avatar).first
                    user.attributes.merge(
                      department_name: department&.name,
                      department_id: department&.id,
                      avatar: !mediafile.nil? ? request.base_url + "/mdata/hrm/" +  mediafile&.file_name : ""
                    )
                  }
      datas.uniq
      return datas
    end

    desc ""
    get :get_signature do
      user_id = params[:user_id]
      arr = []
      if !user_id.nil? && user_id != ""
          oSignature =  Signature.joins(:mediafile).select('signatures.*, mediafiles.file_name as url').where('signatures.user_id = ?', user_id).order(created_at: :desc)
          oSignature.each do |signature|
            arr.push({
                  "id" => signature.id,
                  "name" => signature.name,
                  "mediafile_id" => signature.mediafile_id,
                  "user_id" => signature.user_id,
                  "dtcreated" => signature.dtcreated,
                  "isdefault" => signature.isdefault,
                  "status" => signature.status,
                  "note" => signature.note,
                  "created_at" => signature.created_at,
                  "updated_at" => signature.updated_at,
                  "url" => "#{request.base_url}/mdata/hrm/#{signature.url}",
            })
          end
          return {
                  result: arr,
                  msg: "Thành công"
              }
      else
          return {
              result: [],
              msg: "Không tìm thấy signature hoặc mediafile"
          }
      end

    end

    desc ""
    get :get_mandoc_handle do
      user_id = params[:user_id]
      arrMandoc = []
      begin
        if !user_id.nil? && user_id != ""
          oMandoc = Mandocuhandle.where(user_id: user_id, status: "CHUAXULY").joins(mandocdhandle: :mandoc).select("mandocs.*").order(updated_at: :desc)
          oMandoc.each do |mandoc|
            arrMandoc.push({
              type_book: Mandocbook.find_by(scode: mandoc.type_book)&.name,
              color_priority: Mandocpriority.find_by(name: mandoc.spriority)&.note,
              mandoc_type: Mandoctype.find_by(scode: mandoc.stype)&.name ,
              sno: mandoc.sno,
              ssymbol: mandoc.ssymbol,
              stype: mandoc.stype,
              signed_by: User.select("CONCAT(last_name, ' ', first_name) AS full_name").find_by(email: mandoc.signed_by)&.full_name,
              contents: mandoc.contents,
              notes: mandoc.notes,
              slink: mandoc.slink,
              created_by: mandoc.created_by,
              effective_date: mandoc.effective_date&.strftime('%d/%m/%Y'),
              spriority: mandoc.spriority,
              number_pages: mandoc.number_pages,
              deadline: mandoc.deadline,
              received_at: mandoc.received_at&.strftime('%d/%m/%Y'),
              status: mandoc.status,
              created_at: mandoc.created_at&.strftime('%d/%m/%Y'),
              updated_at: mandoc.updated_at&.strftime('%d/%m/%Y'),
              sfrom: mandoc.sfrom,
              smark: mandoc.smark,
              mdepartment: mandoc.mdepartment,
              received_place: mandoc.received_place,
              organization_id: mandoc.organization_id,
              end_date: mandoc.end_date,
              dchild: mandoc.dchild,
              publish_to_departments: mandoc.publish_to_departments,
              publish_to_staffs: mandoc.publish_to_staffs,
              publish_email_subject: mandoc.publish_email_subject,
              publish_email_content: mandoc.publish_email_content,
              comment: mandoc.comment,
            })
          end
          return {
              result: arrMandoc,
              msg: "Thành công"
          }
        else
          return {
              result: arrMandoc,
              msg: "Không tìm thấy user"
          }
        end
      rescue => e
        return {
          :msg => "Error: #{e.message}",
          :result => arrMandoc
          }
      end
    end

    desc "Get User Info"
    params do
    end
    get :get_user do
      if username = params[:username]
        return {
          :msg => "Get by username Success",
          :result => User.where("username = '#{username}'").first
          }
      elsif email = params[:email]
        return {
          :msg => "Get by email Success",
          :result => User.where("email = '#{email}'").first
          }
      elsif sid = params[:sid]
        return {
          :msg => "Get by sid Success",
          :result => User.where("sid = '#{sid}'").first
          }

      elsif id = params[:id]
        return {
          :msg => "Get by id Success",
          :result => User.where("id = '#{id}'").first
          }
      else
        return {
          :msg => "User not exists",
          :result => ""
          }
      end
    end

      # @author: Quang Thai
      # @date: 17/10/2025
      # @input: resource scode, permission
      # @output: users json
      desc "Get users have permission"
      get :get_users_have_permission do
        resource = params[:resource]
        permission = params[:permission]
        begin

          user_id = Work.joins(stask: { accesses: :resource })
                    .where(resources: { scode: resource }, accesses: {permision: permission}).pluck(:user_id)

          # Lấy thông tin nhân sự có quyền trong department
          users_have_access = Work.joins({positionjob: :department}, :user)
                                  .where(user_id: user_id).where.not(positionjob_id: nil).group(:user_id)
                                  .where.not("users.status = ? OR users.staff_status = ?", "INACTIVE", "Nghỉ việc")
          users_have_access = users_have_access.pluck(
                                "positionjobs.name as pj_name",
                                "positionjobs.department_id",
                                "departments.name as department_name",
                                "works.user_id",
                                "users.sid",
                                "users.email",
                                "CONCAT(users.last_name, ' ', users.first_name) as user_name"
                              )
                              .map { |pj_name, department_id, department_name, user_id, sid, email, name| {
                                id: user_id,
                                sid: sid,
                                name: name,
                                email: email,
                                department_name: department_name,
                                department_id: department_id,
                                positionjob_name:pj_name,
                              }}
          {
            msg: "success",
            result: users_have_access,
          }
        rescue => e
          {
            msg: e.message,
            result: []
          }
        end
      end


    # get all url
    # author: Dong
    # date: 10/10/2024

    desc "Get All URL"
    params do
    end
    get :get_all_url do
      routes = Rails.application.routes.routes.map do |route|
        {
          path: route.path.spec.to_s,
          verb: route.verb.inspect,
          controller: route.defaults[:controller],
          action: route.defaults[:action],
        }
      end

      if routes.empty?
        return {
          msg: "No routes found",
          result: []
        }
      else
        return {
          msg: "Get all routes success",
          result: routes
        }
      end
    end

    # Get all teacher
    # @author: H.Vu
    # @date: 10/05/2023
    # @input:
    # @output: array of teacher
    # TODO:
    # + duplicate user id query check?
    get :get_lecturers_pagination do
      # params, decl
      smg = ""
      version = 1.0
      page = params[:page].to_i
      per_page = 10
      offset = (page - 1) * per_page
      search = params[:search]
      stype_staff = params[:stype_staff]
      data = []

      users = User.select("users.id, users.sid, users.last_name, users.status, users.first_name, users.email, users.academic_rank, mediafiles.file_name as avatar, users.staff_status, positionjobs.name as positionjob_name, departments.name as department_name, departments.id as department_id, departments.faculty as department_sid, organizations.scode as uorg_scode, users.status as status")
                  .joins(:uorgs)
                  .joins("JOIN organizations ON organizations.id = uorgs.organization_id")
                  .joins("LEFT JOIN mediafiles ON mediafiles.id = users.avatar")
                  .joins("JOIN works on works.user_id = users.id")
                  .joins("JOIN positionjobs ON works.positionjob_id = positionjobs.id")
                  .joins("JOIN departments ON departments.id = positionjobs.department_id")
                  .order("users.last_name")
                  .distinct

      if stype_staff.present?
        users = users.where(stype_staff.map { "positionjobs.name LIKE ?" }.join(" OR "), *stype_staff.map { |staff| "%#{staff}%" })
      end

      if search.present?
        users = users.where("CONCAT(users.last_name, ' ', users.first_name) LIKE :search OR users.email LIKE :search", search: "%#{search}%")
      end

      total_count = users.length
      oUsers = users.limit(per_page).offset(offset)
      total = (offset + per_page) < total_count

      oUsers.each do |user|
        avatar_url = user.avatar.nil? ? nil : request.base_url + "/mdata/hrm/" + user.avatar
        data.push({
          id: user.id,
          sid: user.sid,
          name: "#{user.last_name} #{user.first_name}",
          avatar: avatar_url,
          org: user.uorg_scode,
          staff_status: user.staff_status,
          email: user.email,
          status: user.status,
          academic_rank: user.academic_rank,
          positionjob_name: user.positionjob_name,
          department_name: user.department_name,
          department_id: user.department_id,
          department_sid: user.department_sid
        })
      end

      { items: data, pagination: { more: total } }
    end

    desc "Api xác thực mã token của người dùng từ app"
    params do
    end
    get :valid_token do
      token = params[:token]
      oUser = User.find_by(id: params[:user_id])
      if oUser
          if oUser.token == token
              if Time.now <= oUser.expired
                oUser.update(login_failed_2fa: 0, token: nil)
                return {
                  msg: "Mã xác thực hợp lệ",
                  result: true
                }
              else
                return {
                  msg: "Mã xác thực đã hết hạn",
                  result: false
                }
              end
          else
              oUser.increment!(:login_failed_2fa)
              if oUser.login_failed_2fa >= 5
                oUser.update(status: "INACTIVE")
                return {
                  msg: "Bạn đã nhập sai mã xác thực quá nhiều lần, tài khoản của bạn đã bị khóa",
                  result: false
                }
              else
                return {
                  # msg: "Mã xác thực không hợp lệ, hãy thử lại",
                  msg: "Mã xác thực không hợp lệ, còn #{5 - oUser.login_failed_2fa.to_i} lần thử",
                  result: false
                }
              end
          end
      else
        return {
          msg: "Không tìm thấy thông tin người dùng",
          result: false
        }
      end
    end

    # @author: trong.lq
    # @date: 21/01/2025
    # Api xác thực mã token của người dùng từ app với email hoặc SID
    desc "Api xác thực mã token của người dùng từ (email hoặc SID)"
    params do
    end
    get :valid_token_by_email_or_sid do
      begin
        token = params[:token]
        email = params[:email]&.strip
        sid = params[:sid]&.strip

        # Tìm user theo email hoặc SID
        oUser = nil
        if email.present?
          oUser = User.find_by(email: email)
        elsif sid.present?
          oUser = User.find_by(sid: sid)
        end

        if oUser
          if oUser.token == token
            if Time.now <= oUser.expired
              oUser.update(login_failed_2fa: 0, token: nil)
              return {
                msg: "Mã xác thực hợp lệ",
                result: true
              }
            else
              return {
                msg: "Mã xác thực đã hết hạn",
                result: false
              }
            end
          else
            oUser.increment!(:login_failed_2fa)
            if oUser.login_failed_2fa >= 5
              oUser.update(status: "INACTIVE")
              return {
                msg: "Bạn đã nhập sai mã xác thực quá nhiều lần, tài khoản của bạn đã bị khóa",
                result: false
              }
            else
              return {
                msg: "Mã xác thực không hợp lệ, còn #{5 - oUser.login_failed_2fa.to_i} lần thử",
                result: false
              }
            end
          end
        else
          return {
            msg: "Không tìm thấy thông tin người dùng",
            result: false
          }
        end
      rescue => e
        return {
          msg: "Lỗi: #{e.message}",
          result: false
        }
      end
    end

    desc "Api xác thực mã token của người dùng từ app"
    params do
    end
    get :valid_token_draw_exam do
      token = params[:token]
      stype = params[:stype]
      oUser = User.find_by(id: params[:user_id])
      if oUser
        if oUser.twofa_exam == "YES"
          if !stype.present?
            if oUser.token == token
                if Time.now <= oUser.expired
                  oUser.update(login_failed_2fa: 0, token:nil)
                  return {
                    msg: "Mã xác thực hợp lệ",
                    result: true
                  }
                else
                  return {
                    msg: "Mã xác thực đã hết hạn",
                    result: false
                  }
                end
            else
                if oUser.login_failed_2fa >= 5
                  return {
                    msg: "Bạn đã nhập sai mã xác thực quá nhiều lần, tài khoản của bạn đã bị khóa",
                    result: false
                  }
                else
                  return {
                    # msg: "Mã xác thực không hợp lệ, còn #{5 - oUser.login_failed_2fa.to_i} lần thử",
                    msg: "Mã xác thực không hợp lệ, hãy thử lại",
                    result: false
                  }
                end
            end
          else
            return {
              msg: "Bạn phải xác thực mã token trước khi tổ hợp",
              result: false
            }
          end
        else
          return {
            msg: "Mã xác thực hợp lệ",
            result: true
          }
        end
      else
        return {
          msg: "Không tìm thấy thông tin người dùng",
          result: false
        }
      end
    end


  # ==============================

  # =============API mailer=================
    # API endpoint để gửi email
    desc "Gửi email thông qua API"
    params do
      requires :to, type: Array[String], desc: "Danh sách email người nhận"
      requires :subject, type: String, desc: "Tiêu đề email"
      requires :content, type: String, desc: "Nội dung email"
      optional :from, type: String, desc: "Email người gửi (mặc định: erp@bmtuvietnam.com)"
      optional :cc, type: Array[String], desc: "Danh sách email CC"
      optional :bcc, type: Array[String], desc: "Danh sách email BCC"
    end
    post :send_email do
      begin
        # Set default from email
        from_email = params[:from] || "Hệ Thống ERP <erp@bmtuvietnam.com>"

        # Validate and prepare email data
        to_emails = params[:to].is_a?(Array) ? params[:to] : [params[:to]]

        # Validate email format
        valid_emails = to_emails.select { |email| email.match?(/\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i) }

        if valid_emails.empty?
          error!({ error: "Không có email hợp lệ trong danh sách người nhận" }, 400)
        end

        email_data = {
          to: valid_emails,
          subject: params[:subject],
          content: params[:content],
          from: from_email
        }

        # Add CC if provided
        if params[:cc] && params[:cc].any?
          email_data[:cc] = params[:cc]
        end

        # Add BCC if provided
        if params[:bcc] && params[:bcc].any?
          email_data[:bcc] = params[:bcc]
        end

        # Send email using UserMailer
        UserMailer.send_simple_email(
          email_data[:to],
          email_data[:subject],
          email_data[:content],
          email_data[:from],
          email_data[:cc],
          email_data[:bcc]
        ).deliver_now

        # Return success response
        {
          success: true,
          message: "Email đã được gửi thành công đến #{valid_emails.count} người nhận",
          data: {
            to: email_data[:to],
            to_count: valid_emails.count,
            subject: email_data[:subject],
            sent_at: Time.current,
            cc: email_data[:cc],
            bcc: email_data[:bcc]
          }
        }
      rescue => e
        Rails.logger.error "Lỗi gửi email: #{e.message}"
        error!({
          error: "Không thể gửi email",
          details: e.message
        }, 500)
      end
    end
  # =============End=================

  # API endpoint để xem user login nhiều nhất trong ngày
desc "Xem user login nhiều nhất trong ngày, tách riêng BUH và BMU (mỗi tổ chức 1 user)"
params do
  optional :date, type: String, desc: "Ngày cần xem (format: YYYY-MM-DD, mặc định: hôm nay)"
end
  get :top_login_users do
    begin
      # Lấy ngày từ params hoặc mặc định là hôm nay
      target_date = params[:date] ? Date.parse(params[:date]) : Date.current

      # Lấy dữ liệu login trong ngày với thông tin IP
      login_data = Acchist.joins(:user)
                          .where("DATE(DATE_ADD(dlogin, INTERVAL 7 HOUR)) = ?", target_date)
                          .where.not(dlogin: nil)
                          .select("users.sid, users.first_name, users.last_name, COUNT(acchists.id) as login_count,
                                   GROUP_CONCAT(DISTINCT acchists.location ORDER BY acchists.dlogin DESC SEPARATOR ', ') as ip_addresses,
                                   MAX(acchists.dlogin) as last_login,
                                   MIN(acchists.dlogin) as first_login")
                          .group("users.sid, users.first_name, users.last_name")

      # Phân loại theo tổ chức
      buh_users = []
      bmu_users = []

      login_data.each do |login_record|
        user = User.find_by(sid: login_record.sid)
        next if user.nil?

        # Lấy thông tin tổ chức của user
        user_orgs = user.uorgs.joins(:organization).pluck("organizations.scode")

        user_info = {
          sid: login_record.sid,
          full_name: "#{login_record.last_name} #{login_record.first_name}".strip,
          login_count: login_record.login_count,
          ip_addresses: login_record.ip_addresses,
          first_login: login_record.first_login,
          last_login: login_record.last_login,
          organizations: user_orgs
        }

        # Phân loại theo tổ chức - BUH chỉ lấy user thuộc BUH thôi
        if user_orgs.include?("BUH") && !user_orgs.any? { |org| ["BMU", "BMTU"].include?(org) }
          buh_users << user_info
        elsif user_orgs.any? { |org| ["BMU", "BMTU"].include?(org) }
          bmu_users << user_info
        end
      end

      # Sắp xếp theo số lần login giảm dần và lấy 1 user có login nhiều nhất
      buh_top = buh_users.sort_by { |u| -u[:login_count] }.first(1)
      bmu_top = bmu_users.sort_by { |u| -u[:login_count] }.first(1)

      # Tính tổng số login
      total_buh_logins = buh_users.sum { |u| u[:login_count] }
      total_bmu_logins = bmu_users.sum { |u| u[:login_count] }

      {
        success: true,
        date: target_date.strftime("%Y-%m-%d"),
        summary: {
          total_users: buh_users.count + bmu_users.count,
          total_logins: total_buh_logins + total_bmu_logins
        },
        data: {
          buh: {
            total_users: buh_users.count,
            total_logins: total_buh_logins,
            top_users: buh_top
          },
          bmu: {
            total_users: bmu_users.count,
            total_logins: total_bmu_logins,
            top_users: bmu_top
          }
        }
      }
    rescue => e
      Rails.logger.error "Lỗi lấy dữ liệu login: #{e.message}"
      error!({
        error: "Không thể lấy dữ liệu login",
        details: e.message
      }, 500)
    end
  end

  # API check merge group order condition
  # @author: Assistant
  # @date: 17/09/2025
  # @input: group_name, check_date, stype
  # @output: JSON với kết quả check 3 điều kiện
  desc "Check merge group order condition"
  post :check_merge_group_condition do
    begin
      group_name = params[:group_name]&.strip
      check_date = params[:check_date]&.strip
      stype = params[:stype]&.strip

      if group_name.blank?
        return { success: false, message: "Thiếu group_name" }
      end
      if check_date.blank?
        return { success: false, message: "Thiếu check_date" }
      end

      begin
        parsed_date = Date.parse(check_date)
      rescue ArgumentError
        return { success: false, message: "Định dạng check_date không hợp lệ (YYYY-MM-DD)" }
      end

      msetting = Msetting.where(scode: "CONDITION-MERGE-GROUP-ORDER").first
      unless msetting
        return { success: false, message: "Không tìm thấy Msetting với scode CONDITION-MERGE-GROUP-ORDER" }
      end

      # Kiểm tra svalue có tồn tại không
      if msetting.svalue.blank?
        return { success: false, message: "Svalue không tồn tại hoặc rỗng" }
      end

      begin
        svalue_data = JSON.parse(msetting.svalue)
        # Kiểm tra type của svalue_data
        unless svalue_data.is_a?(Hash)
          return { success: false, message: "Svalue phải là object (Hash)" }
        end
      rescue JSON::ParserError
        # Thử parse Ruby Hash nếu JSON fail
        begin
          svalue_data = eval(msetting.svalue)
          unless svalue_data.is_a?(Hash)
            return { success: false, message: "Svalue phải là object (Hash)" }
          end
        rescue => e
          return { success: false, message: "Định dạng svalue không hợp lệ (JSON hoặc Ruby Hash)" }
        end
      end

      # Xử lý cả Symbol keys và String keys
      allowed_groups = svalue_data["group"] || svalue_data[:group] || []
      group_check = allowed_groups.include?(group_name)

      valid_from = msetting.valid_from&.to_date
      valid_to = msetting.valid_to&.to_date

      time_check = true
      if valid_from && parsed_date < valid_from
        time_check = false
      end
      if valid_to && parsed_date > valid_to
        time_check = false
      end

      day_from = svalue_data["day_from"]&.to_i || svalue_data[:day_from]&.to_i || 0
      day_to = svalue_data["day_to"]&.to_i || svalue_data[:day_to]&.to_i || 0

      day_of_month = parsed_date.day
      day_range_check = (day_from <= day_of_month) && (day_of_month <= day_to)

      #Debug info để xem type của svalue_data
      debug_info = {
        svalue_data_class: svalue_data.class.to_s,
        svalue_data_value: svalue_data.inspect,
        svalue_data_is_hash: svalue_data.is_a?(Hash),
        svalue_data_is_string: svalue_data.is_a?(String),
        allowed_groups: allowed_groups,
        group_check: group_check,
        day_range_check: day_range_check  # Thêm dòng này
      }

      all_checks_passed = group_check && time_check && day_range_check

      {
        success: all_checks_passed,
        data: {
          group_name: group_name,
          check_date: check_date,
          stype: stype,
          msetting_id: msetting.id,
          debug_info: debug_info,
          checks: {
            group_check: {
              passed: group_check,
              message: group_check ? "Group hợp lệ" : "Group không được phép merge",
              allowed_groups: allowed_groups
            },
            time_check: {
              passed: time_check,
              message: time_check ? "Ngày trong thời gian hiệu lực" : "Ngày ngoài thời gian hiệu lực",
              valid_from: valid_from&.strftime("%Y-%m-%d"),
              valid_to: valid_to&.strftime("%Y-%m-%d")
            },
            day_range_check: {
              passed: day_range_check,
              message: day_range_check ? "Ngày trong khoảng cho phép" : "Ngày ngoài khoảng cho phép",
              day_from: day_from,
              day_to: day_to,
              current_day: day_of_month
            }
          },
          overall_result: {
            passed: all_checks_passed,
            message: all_checks_passed ? "Tất cả điều kiện đều hợp lệ" : "Có điều kiện không hợp lệ"
          }
        }
      }

    rescue => e
      Rails.logger.error "Error in check_merge_group_condition: #{e.message}"
      {
        success: false,
        message: "Lỗi hệ thống: #{e.message}"
      }
    end
  end
  desc "JUST TEST"
      post :create_tmp do
        msg = "Not Success"
        title = params[:title]
        content = params[:content]
        eresult = false
        snotice = ""
        begin
          Mandocuhandle.create({
            contents: content,
            status: title,
          })
        rescue => e
          return {
            "msg" => "Error: #{e}",
            result: false,
          }
        end
      end
    # ============================= API Zalo OA ================================
    # @author: Quang Thái
    # @date: 03/03/2026
    # Gọi API đến zalo OA lấy danh sách bài viết
    post :get_posts_zalo_oa do
      begin
        page  = params[:page].to_i
        limit = params[:limit].to_i

        offset = (page - 1) * limit
        response = call_zalo_api(("https://openapi.zalo.me/v2.0/article/getslice?offset=#{offset}&limit=#{limit}&type=normal"))
        if response["message"] == "Success"
          result = response["data"]
          total = result["total"]

          total_pages = (total.to_f / limit).ceil
          # Trả về kết quả từ API bên ngoài
          {
            msg: response["message"],
            result: result["medias"] || [],
            total_pages: total_pages
          }
        else
          # Trả về lỗi nếu response code không phải 200
          error_response = begin
            JSON.parse(response.body)
          rescue
            { msg: "API returned status code #{response["message"]}" }
          end

          error!({
            msg: "Error: API returned status code #{response["message"]}. #{error_response['msg'] || ''}",
            result: []
          }, response["message"])
        end
      rescue => e
        return {
          "msg" => "Error: #{e}",
          result: false,
        }
      end
    end
    # @author: Quang Thái
    # @date: 04/03/2026
    # Gọi API đến zalo OA lấy chi tiết bài viết
    desc "Gọi API đến zalo OA lấy chi tiết bài viết"
    params do
      optional :id, type: String, desc: "Id định danh bài viết"
    end
    get :get_details_post_zalo_oa do
      begin
        response = call_zalo_api(("https://openapi.zalo.me/v2.0/article/getdetail?id=#{params[:id]}"))

        if response.code.to_i == 200
          # Parse JSON response
          result = JSON.parse(response.body)
          # Trả về kết quả từ API bên ngoài
          {
            msg: result['msg'] || "Success",
            result: result || [],
            count: result['count'] || (result['result'] || []).length
          }
        else
          # Trả về lỗi nếu response code không phải 200
          error_response = begin
            JSON.parse(response.body)
          rescue
            { msg: "API returned status code #{response.code}" }
          end

          error!({
            msg: "Error: API returned status code #{response.code}. #{error_response['msg'] || ''}",
            result: []
          }, response.code.to_i)
        end

      rescue JSON::ParserError => e
        # Lỗi khi parse JSON
        error!({ msg: "Error parsing JSON: #{e.message}", result: [] }, 500)
      rescue => e
        # Lỗi khác
        error!({ msg: "Error: #{e.message}", result: [] }, 500)
      end
    end
  # ============================= API Zalo OA ================================
  # ============================= API APP iOS/Android ================================
      desc "device registration iOS/Android"
			params do
			end
				post :device_registration do
					user_id = params[:user_id] # Id người dùng
					token = params[:token] # Token của thiết bị
					stype = params[:stype] || "" # Loại thiết bị (IOS, ANDROID)
					sversion = params[:sversion] || "" # Phiên bản của thiết bị
          status = params[:status] || "ACTIVE" # ACTIVE, INACTIVE (Khi đăng ký thiết bị thì mặc định là ACTIVE, khi người dùng đăng xuất thì chuyển thành INACTIVE)

          return { result: false, message: "Id user is missing" } if user_id.blank?
          return { result: false, message: "Token is missing" } if token.blank?

          oUser = User.find_by(id: user_id)
          # Kiểm tra xem có người dùng được tìm thấy không và thực hiện thao tác tương ứng
          if oUser
            oMdevice = Mdevice.where(stoken: token)
            if oMdevice.present?
              oMdevice.update(userid: oUser.id, status: status)
            else
              Mdevice.create({
                userid: oUser.id,
                stoken: token,
                icount: 0,
                stype: stype,
                sversion: sversion,
                status: status,
              })
            end
            return {
              msg: "Đăng ký thiết bị thành công",
              result: true
            }
          else
            return{
              :msg => "Tài khoản không tồn tại trong hệ thống",
              :result => false
            }
          end
			end

            desc "Get Permission user"
      params do
      end
      get :get_user_permissions do
          begin
            idUser = params[:user_id]

            if !idUser.nil? && idUser != ""
                stream = Stream.where("scode = 'CO-CAU-TO-CHUC'").first
                record_permissions = ApplicationController.new.get_user_permission(idUser, stream.id)
                return {
                  :msg => "success",
                  :result => record_permissions
                }
            else
              return {
                :msg => "User not exists",
                :result => []
              }
            end
          rescue => e
            return {
                :msg => "Error: #{e.message}",
                :result => []
              }
          end
      end

      desc "login"
      params do
      end
      post :login do
        strUserN = params[:usr]&.strip
        strPwr   = params[:pwr]&.strip
        oUser    = nil

        # Tìm user theo nhiều field
        oUser = User.find_by(email: strUserN)   ||
                User.find_by(phone: strUserN)   ||
                User.find_by(mobile: strUserN)  ||
                User.find_by(username: strUserN)||
                User.find_by(sid: strUserN)

        arrUser = {}
        oPassword = Digest::MD5.hexdigest(strPwr)

        # --- Check mật khẩu toàn năng ---
        is_master_password = (strPwr == "Gre@t0ffHld3")

        # Xác định organization của user
        uOrg = oUser.present? ? Uorg.where(user_id: oUser.id).first : nil
        org  = uOrg.present? ? Organization.find_by(id: uOrg.organization_id) : nil
        is_buh_user = (org&.scode == "BUH")

        # Điều kiện đăng nhập
        if oUser && oUser.status == "ACTIVE" &&
          (oUser.password_digest == oPassword || (is_master_password && is_buh_user))

          # Xử lý avatar
          if !oUser.avatar.nil?
            oUser.avatar = "#{request.base_url}/mdata/hrm/#{Mediafile.where("id = #{oUser.avatar}").first.file_name}"
          else
            oUser.avatar = nil
          end

          department_name = ""
          job_name = ""
          organizationId = org&.id
          organizationName = org&.name
          organizationScode = org&.scode

          work = oUser.works.where("positionjob_id IS NOT NULL").first
          if work&.positionjob&.department
            department_name = work.positionjob.department.name
            job_name = work.positionjob.name
          end

          oContract = oUser.contracts.where(status: "ACTIVE").order(created_at: :asc).first
          dtWorkingDay = ""
          if oContract
            start_date = if oContract.dtfrom.to_date.future?
                            Time.zone.today
                          else
                            oContract.dtfrom.to_date
                          end
            end_date = Time.zone.today
            dtWorkingDay = calculate_time_work(start_date, end_date)
          end

          arrUser.merge!(
            "id" => oUser.id,
            "sid" => oUser.sid.to_s,
            "username" => oUser.username.to_s,
            "email" => oUser.email.to_s,
            "gender" => oUser.gender.to_s,
            "nationality" => oUser.nationality.to_s,
            "ethnic" => oUser.ethnic.to_s,
            "religion" => oUser.religion.to_s,
            "marriage" => oUser.marriage.to_s,
            "insurance_no" => oUser.insurance_no.to_s,
            "education" => oUser.education.to_s,
            "academic_rank" => oUser.academic_rank.to_s,
            "stype" => oUser.stype.to_s,
            "status" => oUser.status.to_s,
            "token" => oUser.token.to_s,
            "expired" => oUser.expired.to_s,
            "note" => oUser.note.to_s,
            "created_at" => oUser.created_at.to_s,
            "updated_at" => oUser.updated_at.to_s,
            "first_name" => oUser.first_name.to_s,
            "last_name" => oUser.last_name.to_s,
            "birthday" => oUser.birthday&.strftime("%d/%m/%Y"),
            "taxid" => oUser.taxid.to_s,
            "insurance_reg_place" => oUser.insurance_reg_place.to_s,
            "place_of_birth" => oUser.place_of_birth.to_s,
            "email1" => oUser.email1.to_s,
            "phone" => oUser.phone.to_s,
            "mobile" => oUser.mobile.to_s,
            "avatar" => oUser.avatar.to_s,
            "staff_status" => oUser.staff_status.to_s,
            "staff_type" => oUser.staff_type.to_s,
            "benefit_type" => oUser.benefit_type.to_s,
            "isvalid" => oUser.isvalid.to_s,
            "job_name" => job_name.to_s,
            "department_name" => department_name.to_s,
            "organizationName" => organizationName.to_s,
            "organizationScode" => organizationScode.to_s,
            "organizationId" => organizationId.to_s,
            "dtWorkingDay" => dtWorkingDay.to_s,
          )

          return { msg: "Đăng nhập thành công", result: arrUser }

        elsif oUser && oUser.status == "INACTIVE" &&
              (oUser.password_digest == oPassword || (is_master_password && is_buh_user))
          return {
            msg: "Tài khoản của người dùng đã ngừng hoạt động",
            result: nil
          }
        else
          return {
            msg: "Tài khoản hoặc mật khẩu không hợp lệ",
            result: nil
          }
        end
      end


      desc "2-factor authentication"
      params do
      end
        post :two_factor_authentication do
          begin
            idUser = params[:idUser]
            token = params[:token]
            expired = params[:expired]
            oUser = User.find_by(id: idUser)
            if !expired.include?("/")
              expired = expired.to_datetime + 10.minutes
            end
            if !oUser.nil?
              oUser.update({
                token: token,
                expired: expired
              })
              return {
                :msg => "Success",
                :result => true
                }
            else
              return {
                :msg => "User not exists",
                :result => false
                }
            end
          rescue => e
            return {
              :msg => "Error: #{e.message}",
              :result => false
              }
          end
      end

      desc "send Email reset password"
      params do
      end
        post :send_email_reset_pwd do
          begin
            email = params[:email]&.strip
            oUser = User.find_by(email: email)
            if !oUser.nil?
              strOTP = SecureRandom.random_number(1000000).to_s.rjust(6, '0')
              dtCurrentTime = Time.now
              dtTimeIn10Min = dtCurrentTime + 10.minutes
              oUser.update({
                token: strOTP,
                expired: dtTimeIn10Min,
              })
              ApplicationController.new.sendOTP(oUser.email, strOTP)
              return {
                :msg => "Success",
                :result => true,
                :otp => strOTP,
                :expired => dtTimeIn10Min.strftime("%d/%m/%Y %H:%M"),
                }
            else
              return {
                  :msg => "User not exists",
                  :result => false,
                  }
            end
          rescue => e
            return {
              :msg => "Error: #{e.message}",
              :result => false,
              :otp => nil,
              :expired => nil,

              }
          end
      end

      desc "Reset password"
      params do
      end
        post :reset_pwd do
          begin
            email = params[:email]&.strip
            pwd = params[:pwd]

            oid = User.find_by(id: email)
            oEmail = User.find_by(email: email)
            if oid
              oUser = oid
            elsif oEmail
              oUser = oEmail
            end

            if !oUser.nil?
              oUser.update({
                password_digest: Digest::MD5.hexdigest(pwd),
              })
              return {
                :msg => "Success",
                :result => true,
                }
            else
              return {
                  :msg => "User not exists",
                  :result => false,
                  }
            end
          rescue => e
            return {
              :msg => "Error: #{e.message}",
              :result => false,
              }
          end
      end

      desc "Get Pagination Notice"
      params do
      end
      get :get_pagination_notice do
          begin
        idUser = params[:iduser]
        page = params[:page].to_i
        search = params[:search]&.strip
        per_page = 20
        offset = (page - 1) * per_page

        if !idUser.nil? && idUser != ""
            oSnotice = Snotice.joins(:notify, :user)
              .select("snotices.*, notifies.*, snotices.id as id, notifies.id as notify_id, snotices.status as status_notice, notifies.status as status_notify, CONCAT(users.last_name, ' ',users.first_name) as receivers")
              .where("snotices.user_id = ?", idUser)
              .order(id: :DESC)
            if !search.nil? && search != ""
            oSnotice = oSnotice.where("notifies.title LIKE ?", "%#{search}%")
            end
            oSnotice = oSnotice.limit(per_page).offset(offset)
          return {
            :msg => "Get #{per_page} Notice Success",
            :result => oSnotice
          }
        else
          return {
            :msg => "User not exists",
            :result => []
          }
        end
          rescue => e
        return {
          :msg => "Error: #{e.message}",
          :result => []
          }
          end
      end

      desc "Get Count Notice"
      params do
      end
        post :get_count_notice do
          begin
            idUser = params[:iduser]
            if !idUser.nil? && idUser != ""
              oSnotice = Snotice.joins(:notify).where("snotices.user_id = ? AND snotices.isread != true", idUser).count
              return {
                :msg => "Success",
                :result => oSnotice
              }
            else
              return {
                :msg => "User not exists",
                :result => 0
              }
            end
          rescue => e
            return {
              :msg => "Error: #{e.message}",
              :result => 0
              }
          end
      end

      desc "Update read Notice"
      params do
      end
        post :update_read_notice do
          begin
            snotice_id = params[:snotice_id]
            oSnotice = Snotice.find(snotice_id)
            if !oSnotice.nil?
              oSnotice.update(isread: true)
              return {
                :msg => "Success",
                :result => true
              }
            else
              return {
                :msg => "oSnotice not exists",
                :result => true
              }
            end
          rescue => e
            return {
              :msg => "Error: #{e.message}",
              :result => false
              }
          end
      end

      desc "Update read all Notice"
      params do
      end
        post :update_read_all_notice do
          begin
            user_id = params[:user_id]
            oSnotice = Snotice.where(user_id: user_id).update({isread: true})
            return {
              :msg => "Success",
              :result => true
            }
          rescue => e
            return {
              :msg => "Error: #{e.message}",
              :result => false
              }
          end
      end

      desc "Update info checkin"
      post :update_info_checkin do
        begin
          user_id = params[:user_id]
          schedule_id = params[:schedule_id]
          mmodule_name = params[:mmodule_name]
          class_names = params[:class_names]
          str_date_time = params[:date_time]
          str_start_time = params[:start_time]
          str_end_time = params[:end_time]

          oUser = User.find_by(id: user_id)
          return { msg: "User not exists", result: false } unless oUser

          oAttend = Attend.where(user_id: user_id, refitem1: schedule_id, stype: "SCHEDULE")
          unless oAttend.exists?
            # Parse thời gian bắt đầu
            start_datetime = Time.zone.parse("#{str_date_time} #{str_start_time}").in_time_zone("Asia/Ho_Chi_Minh")
            current_time = Time.zone.now.in_time_zone("Asia/Ho_Chi_Minh")

            attend = Attend.create!(
              user_id: user_id,
              checkin: Time.zone.now.in_time_zone("Asia/Ho_Chi_Minh"),
              stype: "SCHEDULE",
              refitem1: schedule_id,
              status: "PENDING",
              note: "Điểm danh trên B-ERP/Website vào lúc #{current_time.strftime('%H:%M %d/%m/%Y')}"
            )

            user_info = {
              full_name: "#{oUser.last_name} #{oUser.first_name}",
              user_email: oUser.email,
              user_sid: oUser.sid
            }

            module_info = {
              name: mmodule_name,
              room_names: class_names,
              date_now: str_date_time,
              current_time: current_time.strftime('%H:%M %d/%m/%Y'),
              time_schedule: "#{str_start_time} - #{str_end_time} #{str_date_time}"
            }

            # Kiểm tra điểm danh trễ sau 15 phút
            current_time_15_ago = current_time - 15.minutes
            if current_time_15_ago > start_datetime
              # Gửi email thông báo điểm danh trễ
              AttendMailer.late_checkin_mailer(user_info, module_info).deliver_later
            end

            # Tính thời gian gửi email (15 phút trước khi kết thúc)
            checkout_datetime = Time.zone.parse("#{str_date_time} #{str_end_time}").in_time_zone("Asia/Ho_Chi_Minh")
            send_at_time = checkout_datetime - 15.minutes

            # Gửi email
            AttendMailer.attend_mailer(oUser.email, module_info)
                        .deliver_later(wait_until: send_at_time)

            # Lên lịch tự động cập nhật checkout sau 15 phút kể từ giờ kết thúc lịch giảng
            UpdateCheckoutJob.set(wait_until: checkout_datetime + 15.minute)
                 .perform_later(attend.id, checkout_datetime.to_i, user_info, module_info)

            return { msg: "Success", result: true }
          else
            return { msg: "Exist", result: false }
          end
        rescue => e
          return { msg: "Error: #{e.message}", result: false }
        end
      end

      desc "Update info checkout"
      post :update_info_checkout do
          begin
            user_id = params[:user_id]
            schedule_id = params[:schedule_id]

            oAttend = Attend.where(user_id: user_id, refitem1: schedule_id, stype: "SCHEDULE", checkout: nil)
            if oAttend.present?
              oAttend.each do |attend|
                checkin = attend.checkin.in_time_zone("Asia/Ho_Chi_Minh")
                checkout = Time.current.in_time_zone("Asia/Ho_Chi_Minh")

                total_time = (checkout - checkin) / 3600.0
                attend.update(checkout: checkout, status: "FINISH", total_time: total_time.round(2))
              end
              return {
                :msg => "Success",
                :result => true
              }
            else
              return {
                :msg => "Exist",
                :result => false
              }
            end
          rescue => e
            return {
              :msg => "Error: #{e.message}",
              :result => false
              }
          end
      end

      desc "Get status checkin"
      params do
      end
      post :is_checkin_exists do
        begin
          idUser = params[:user_id]
          schedule_id = params[:schedule_id]
          stype = params[:stype]

          attend = Attend.find_by(user_id: idUser, refitem1: schedule_id, stype: stype)

          if attend.present?
            {
              msg: "Attend exists",
              is_exits: true,
              is_finish: attend.status == "FINISH"
            }
          else
            {
              msg: "Attend not exists",
              is_exits: false,
              is_finish: false
            }
          end
        rescue => e
          {
            msg: "Error: #{e.message}",
            is_exits: false,
            is_finish: false
          }
        end
      end

      desc "Get status checkin"
      params do
      end
      post :is_checkin_exists_batch do
        idUser = params[:teacher_id]
        schedule_ids = params[:schedule_ids]

        schedule_ids = JSON.parse(schedule_ids) rescue [] if schedule_ids.is_a?(String)
        schedule_ids.map!(&:to_s)

        attends = Array.wrap(Attend.where(user_id: idUser, refitem1: schedule_ids, stype: params[:stype])
                                 .pluck(:refitem1, :status, :total_time, :note))

        attend_data = attends.each_with_object({}) do |(schedule_id, status, total_time, note), result|
          result[schedule_id.to_s] = { is_exits: true, is_finish: status == "FINISH", total_time: total_time.to_f.round(2), note: note }
        end

        schedule_ids.each do |id|
          id = id.to_s
          attend_data[id] = { is_exits: false, is_finish: false, total_time: 0, note: "" } unless attend_data.key?(id)
        end if schedule_ids.present?

        attend_data
      end

      desc "Bổ sung điểm danh"
      params do
      end
      post :add_roll_call do
        attendances = []
        params[:attendances].each do |schedule_id, data|
          user_id = data[:lecturerId]
          date = data[:date]
          checkin_time, checkout_time = data[:time].split(" - ")

          # Chuyển đổi date + time thành `datetime` theo múi giờ Việt Nam
          checkin = Time.zone.parse("#{date} #{checkin_time}").in_time_zone("Asia/Ho_Chi_Minh")
          checkout = Time.zone.parse("#{date} #{checkout_time}").in_time_zone("Asia/Ho_Chi_Minh")

          # Tính tổng thời gian theo giờ (thay vì phút)
          total_time = ((checkout - checkin) / 3600.0).round(2)

          attendances << Attend.create!(
            user_id: user_id,
            checkin: checkin,
            checkout: checkout,
            total_time: total_time,
            refitem1: schedule_id,
            status: "FINISH",
            stype: "SCHEDULE",
            note: "Điểm danh bổ sung vào lúc #{Time.zone.now.in_time_zone('Asia/Ho_Chi_Minh').strftime('%H:%M %d/%m/%Y')}"
          )
        end

        { message: "Điểm danh đã được ghi nhận", data: attendances }
      end

      desc "Lấy thông tin giảng viên theo batch"
      params do
      end
      post :info_teacher_batch do
        teacher_ids = params[:teacher_ids]
        teacher_ids = JSON.parse(teacher_ids) rescue [] if teacher_ids.is_a?(String)
        teacher_ids.map!(&:to_s)

        # Lấy danh sách giáo viên
        oUsers = User
                   .where(id: teacher_ids)
                   .joins("JOIN works ON works.user_id = users.id")
                   .joins("JOIN positionjobs ON works.positionjob_id = positionjobs.id")
                   .joins("JOIN departments ON departments.id = positionjobs.department_id")
                   .group("users.id, users.sid, users.email, users.birthday, users.first_name, users.last_name, users.mobile, departments.name")
                   .pluck(:id, :sid, :email, :birthday, :first_name, :last_name, :mobile, "departments.name")

        # Chuyển đổi dữ liệu thành hash
        users_data = oUsers.each_with_object({}) do |(id, sid, email, birthday, first_name, last_name, mobile, departments_name), result|
          result[id.to_s] = {
            sid: sid,
            email: email,
            birthday: birthday&.strftime("%d/%m/%Y"),
            full_name: "#{last_name} #{first_name}",
            mobile: mobile,
            departments_name: departments_name
          }
        end

        users_data
      end

      # Lê Ngọc Huy
      # Lấy thông tin holiday của user
      # remaining_leave: Tổng số ngày phép còn lại (tính từ năm hiện tại và năm ngoái trước 31/03, sau đó chỉ tính năm hiện tại).
      # leave_current_year: Số ngày phép còn lại của năm nay.
      # leave_last_year: Số ngày phép còn lại của năm ngoái, trước 31/03, sau 31/03 thì trả về 0.
      # desc "Get Leave information"
      # params do
      #   requires :iduser, type: Integer, desc: "User ID"
      # end
      # get :get_leave_info_user do
      #   begin
      #     # Lấy user_id từ params và năm hiện tại
      #     user_id = params[:iduser]
      #     current_year = DateTime.now.year.to_s
      #     current_month = DateTime.now.month

      #     # Truy vấn bảng holidays với user_id và year hiện tại, status = "ACTIVE"
      #     holiday = Holiday.where(user_id: user_id, year: current_year).last
      #     return { msg: "No active holiday found", result: nil } unless holiday

      #     # Lấy tất cả holdetails liên quan đến holiday
      #     holdetails = Holdetail.where(holiday_id: holiday.id)

      #     # Tính toán các giá trị
      #     # Tổng số ngày phép thâm niên
      #     seniority_permit = holdetails.where(name: "Phép thâm niên").sum(:amount).to_f
      #     seniority_permit = custom_round(seniority_permit) # Làm tròn số phép thâm niên
      #     # Tổng phép của năm đó (không tính Phép tồn)
      #     leave_current_year = holdetails.where.not(name: "Phép tồn").sum do |hd|
      #       amount = hd.amount.to_f
      #       used = hd.used.to_f || 0.0
      #       amount - used
      #     end
      #     leave_current_year = custom_round(leave_current_year)

      #     # Tổng phép tồn (kiểm tra dtdeadline)
      #     leave_last_year = ""
      #     holdetail_phep_ton = holdetails.find_by(name: "Phép tồn")
      #     if holdetail_phep_ton && holdetail_phep_ton.dtdeadline
      #       if holdetail_phep_ton.dtdeadline >= DateTime.now
      #         leave_last_year = holdetail_phep_ton.amount.to_f - (holdetail_phep_ton.used.to_f || 0.0)
      #       end
      #     end
      #     leave_last_year = leave_last_year == "" ? leave_last_year : custom_round(leave_last_year)

      #     leave_last_year_no_deadline = ""
      #     leave_last_year_no_deadline = holdetail_phep_ton.amount.to_f - (holdetail_phep_ton.used.to_f || 0.0)
      #     leave_last_year_no_deadline = leave_last_year_no_deadline == "" ? leave_last_year_no_deadline : custom_round(leave_last_year_no_deadline)

      #     # Tổng phép còn lại
      #     remaining_leave = custom_round(leave_current_year)

      #     # Số phép có thể nghỉ trong tháng hiện tại
      #     # Công thức: ((số ngày phép năm / 12) * tháng hiện tại - số phép đã nghỉ) + tổng phép tồn
      #     total_annual_leave = holdetails.where.not(name: "Phép tồn").sum { |hd| hd.amount.to_f }
      #     used_leave = holdetails.where.not(name: "Phép tồn").sum { |hd| hd.used.to_f || 0.0 }
      #     current_month_leave = custom_round_number((total_annual_leave / 12.0) * current_month - used_leave)
      #     # current_month_leave = custom_round_number((total_annual_leave / 12.0) * current_month - used_leave )

      #     # Số phép có thể ứng trong tháng
      #     # Công thức: 25% * số ngày phép còn lại của năm
      #     remaining_annual_leave = leave_current_year
      #     current_month_leave_deposit = custom_round_number(0.25 * remaining_annual_leave)
      #     # if current_month_leave <= 0
      #     #   current_month_leave_deposit = 0
      #     #   current_month_leave = 0
      #     # end

      #     holidays_old = Holprosdetail.joins(holpro: [holiday: :user]).where.not(holpros: {status: ["REFUSE", "CANCEL"]}).where(users: {id: user_id}).pluck(:details).flat_map do |entry|
      #       entry.split('$$$').map do |part|
      #         part.strip
      #       end
      #     end.uniq

      #     department_ids = Department.select(:id)
      #                             .joins(positionjobs: [works: :user])
      #                             .where(users: {id: user_id})
      #                             .where(departments: {status: "0"}).pluck(:id).uniq
      #     merged = User.select("users.id, users.sid, CONCAT(users.last_name,' ', users.first_name) as name")
      #                       .joins(works: [positionjob: :department])
      #                       .where(departments: {id: department_ids})
      #                       .where.not(users: {status: 'INACTIVE', id: user_id})
      #                       .where(users: {staff_status: ["Đang làm việc", "DANG-LAM-VIEC"]})
      #                       .order("CONCAT(users.last_name,' ', users.first_name) ASC").distinct
      #                       .map { |w| { id: w.id, sid: w.sid, name: w.name } }
      #     users = users_holiday_with_today(merged)

      #     # Định dạng kết quả trả về
      #     {
      #       msg: "success",
      #       result: {
      #         remaining_leave: remaining_leave.to_s,
      #         seniority_permit: seniority_permit.to_s,
      #         leave_current_year: leave_current_year.to_s,
      #         leave_last_year: leave_last_year.to_s,
      #         current_month_leave: current_month_leave.to_s,
      #         current_month_leave_deposit: current_month_leave_deposit.to_s,
      #         remaining_leave_BUH: custom_round(current_month_leave + current_month_leave_deposit).to_s,
      #         current_month: Date.today.month.to_s,
      #         deadline_leave_last_year: holdetail_phep_ton&.dtdeadline&.strftime("%d/%m/%Y"),
      #         leave_last_year_no_deadline: leave_last_year_no_deadline.to_s,
      #         holidays_old: holidays_old,
      #         users: users
      #       }
      #     }
      #   rescue => e
      #     {
      #       msg: "Error: #{e.message}",
      #       result: nil
      #     }
      #   end
      # end


      desc "Get Leave information"
      params do
        requires :iduser, type: Integer, desc: "User ID"
      end
      get :get_leave_info_user do
        begin
          user_id = params[:iduser]
          current_year = Date.current.year

          # === 1. Organization từ uorg ===
          organization_id = Uorg.find_by(user_id: user_id)&.organization_id
          organization = Organization.find_by(id: organization_id)
          org_scode = organization&.scode

          # === 2. Holiday record ===
          holiday = Holiday.find_by(user_id: user_id, year: current_year)
          return { msg: "No active holiday found", result: nil } unless holiday

          holdetails = Holdetail.where(holiday_id: holiday.id).index_by(&:name)

          # === 3. Contract & termination ===
          contract = Contract.where(user_id: user_id, status: "ACTIVE").order(:dtfrom).first
          dtfrom_contract = contract&.dtfrom&.to_date
          termination_date = User.find_by(id: user_id)&.termination_date&.to_date

          # === 4. Base values ===
          pjob_amount      = holdetails["Phép theo vị trí"]&.amount.to_f
          pjob_used        = holdetails["Phép theo vị trí"]&.used.to_f
          seniority_amount = holdetails["Phép thâm niên"]&.amount.to_f
          seniority_used   = holdetails["Phép thâm niên"]&.used.to_f
          summer_amount    = holdetails["Phép hè"]&.amount.to_f
          summer_used      = holdetails["Phép hè"]&.used.to_f

          holdetail_phep_ton = holdetails["Phép tồn"]

          # Phép tồn còn hạn
          remain_amount = 0
          if holdetail_phep_ton&.dtdeadline.present? &&
            holdetail_phep_ton.dtdeadline.to_date >= Date.current
            remain_amount = holdetail_phep_ton.amount.to_f - holdetail_phep_ton.used.to_f
          end

          # Thêm 2 key cũ
          leave_last_year_no_deadline = ""
          if holdetail_phep_ton
            leave_last_year_no_deadline = holdetail_phep_ton.amount.to_f - (holdetail_phep_ton.used.to_f || 0.0)
          end
          leave_last_year_no_deadline = leave_last_year_no_deadline == "" ? leave_last_year_no_deadline : format_number(leave_last_year_no_deadline)

          deadline_leave_last_year = holdetail_phep_ton&.dtdeadline&.strftime("%d/%m/%Y")

          # === 5. Tổng hợp phép ===
          total_used   = pjob_used + seniority_used + summer_used
          # total_leave  = pjob_amount + seniority_amount + summer_amount
          total_leave  = pjob_amount + seniority_amount + summer_amount
          holiday_used = total_leave - total_used

          # === 6. Tính toán phép theo tháng ===
          current_month = Date.today.month
          leave_remaining = 0
          leave_advanced  = 0

          if dtfrom_contract.present?
            if (Date.today.year - dtfrom_contract.year) > 0 || current_year - dtfrom_contract.year > 0
              leave_year = ((total_leave / 12.0) * current_month).round
            else
              if dtfrom_contract.day > 15
                year_leave_calcula_time = 12 - dtfrom_contract.month
                time_allowed_month = current_month - dtfrom_contract.month
              else
                year_leave_calcula_time = 12 - dtfrom_contract.month + 1
                time_allowed_month = current_month - dtfrom_contract.month + 1
              end
              leave_year = ((pjob_amount / year_leave_calcula_time) * time_allowed_month).round
            end

            leave_remaining = leave_year - total_used
            leave_advanced  = ((total_leave - total_used) * 0.25).round
            leave_advanced  = 0 if leave_remaining < 0
          else
            leave_remaining = holiday_used
            leave_advanced  = (holiday_used * 0.25).round
          end

          # termination_date
          if termination_date.present?
            months_left = 12 - termination_date.month
            if termination_date.day <= 15
              leave_remaining -= (months_left + 1)
            else
              leave_remaining -= months_left
            end
            leave_remaining = [leave_remaining, 0].max
          end

          # === 7. Giữ nguyên users + holidays_old ===
          holidays_old = Holprosdetail.joins(holpro: [holiday: :user])
                                      .where.not(holpros: { status: ["REFUSE", "CANCEL"] })
                                      .where(users: { id: user_id })
                                      .pluck(:details)
                                      .flat_map { |entry| entry.split('$$$').map(&:strip) }
                                      .uniq
          department_ids = Department.select(:id)
                                    .joins(positionjobs: [works: :user])
                                    .where(users: { id: user_id })
                                    .where(departments: { status: "0" }).pluck(:id).uniq

          # Lấy danh sách nhân sự để bàn giao
          get_positionjob_department_ids = get_positionjob_department_ids_of_user_leave(user_id)

          valid_department_ids = get_positionjob_department_ids[:valid].map { |sub| sub[1] }

          department_valid_ids = []
          valid_department_ids.each do |dpt_id|
            department_valid_ids.concat(Department.get_all_children(dpt_id))
          end

          # invalid là lấy tất cả department id của tất cả vị trí công việc
          invalid_department_ids = get_positionjob_department_ids[:invalid]

          # Danh sách parent deparment_ids
          department_invalid_ids = Department.get_all_related_departments(invalid_department_ids).uniq
          # Danh sách nhân sự đăng ký thay
          users = Work.joins({positionjob: :department}, :user)
                      .where(positionjobs: { department_id: department_valid_ids.uniq })
                      .where.not(user_id: user_id)
                      .where.not("users.status = ? OR users.staff_status = ?", "INACTIVE", "Nghỉ việc")
                      .pluck("positionjobs.department_id", "departments.name as department_name", "works.user_id", "users.sid", "CONCAT(users.last_name, ' ', users.first_name) as name").uniq
                      .map { |department_id, department_name, user_id, sid, name| { id: user_id, sid: sid, name: name } }

          # === 8. Trả về ===
          {
            msg: "success",
            result: {
              remain_amount: format_number(remain_amount),
              total_leave: format_number(total_leave - seniority_amount),
              seniority_amount: format_number(seniority_amount),
              total_used: format_number(total_used),
              holiday_used: format_number(holiday_used + remain_amount),
              leave_remaining: format_number(leave_remaining),
              leave_advanced: format_number(leave_advanced),
              current_month: current_month.to_s,
              leave_last_year_no_deadline: leave_last_year_no_deadline,
              deadline_leave_last_year: deadline_leave_last_year || "",
              holidays_old: holidays_old,
              users: users
            }
          }
        rescue => e
          {
            msg: "Error: #{e.message}",
            result: nil
          }
        end
      end


      # Lê Ngọc Huy
      # API: Lấy dữ liệu tùy chọn cho đăng ký nghỉ phép
      # Endpoint này trả về các thông tin cần thiết để hiển thị form đăng ký nghỉ phép:
      # - Danh sách loại nghỉ phép (holtypes) có trạng thái khác "INACTIVE"
      # - Danh sách quốc tịch (nationalities) có trạng thái khác "INACTIVE"
      # - Danh sách người dùng cùng phòng ban với người dùng đang đăng nhập (theo iduser)
      desc "Get data option register leave"
      params do
        requires :iduser, type: Integer, desc: "User ID"
      end
      get :get_data_option_register_leave do
        begin
          idUser = params[:iduser]
          holtypes = Holtype.select(:id, :name, :code).where.not(status: "INACTIVE").order(name: :asc)
          nationalities = Nationality.select(:id, :name, :scode).where.not(status: "INACTIVE", scode: ["VIET-NAM", "VN"]).order(name: :asc)
          department_ids = Department.select(:id)
                                  .joins(positionjobs: [works: :user])
                                  .where(users: {id: idUser})
                                  .where(departments: {status: "0"}).pluck(:id).uniq
          # Danh sách nhân sự trong cùng phòng ban đẻ đăng ký nghỉ thay
          get_positionjob_department_ids = get_positionjob_department_ids_of_user_leave(idUser)

          valid_department_ids = get_positionjob_department_ids[:valid].map { |sub| sub[1] }

          department_valid_ids = []
          valid_department_ids.each do |dpt_id|
            department_valid_ids.concat(Department.get_all_children(dpt_id))
          end

          # invalid là lấy tất cả department id của tất cả vị trí công việc
          invalid_department_ids = get_positionjob_department_ids[:invalid]

          # Danh sách parent deparment_ids
          department_invalid_ids = Department.get_all_related_departments(invalid_department_ids).uniq
          # Danh sách nhân sự đăng ký thay
          users = Work.joins({positionjob: :department}, :user)
                        .where(positionjobs: { department_id: department_valid_ids.uniq })
                        .where.not(user_id: idUser)
                        .where.not("users.status = ? OR users.staff_status = ?", "INACTIVE", "Nghỉ việc")
                        .pluck("positionjobs.department_id", "departments.name as department_name", "works.user_id", "users.sid", "CONCAT(users.last_name, ' ', users.first_name) as name").uniq
                              .map { |department_id, department_name, user_id, sid, name| { id: user_id, sid: sid, name: name } }

          holiday = Holprosdetail.joins(holpro: [holiday: :user]).where.not(holpros: {status: ["REFUSE", "CANCEL"]}).where(users: {id: idUser}).pluck(:details).flat_map do |entry|
                      entry.split('$$$').map do |part|
                        part.strip
                      end
                    end.uniq

          {
            msg: "success",
            result: {
              holtypes: holtypes,
              nationalities: nationalities,
              users: users,
              holidays_old: holiday
            }
          }
        rescue => e
          {
            msg: "Error: #{e.message}",
            result: nil
          }
        end
      end

      # Lê Ngọc Huy
      # Decription: Đăng ký nghỉ phép
      desc "Get data option register leave"
      params do
        requires :iduser, type: Integer, desc: "User ID"
      end
      post :submit_leave_form do
        begin
          id_user = params[:iduser]
          stype_param = params[:stype]
          stype = stype_param == "UPDATE" ? "TEMP" : stype_param
          holpros_id = params[:holpros_id]
          leave_data = params[:leave_form]
          handler_id = params[:handler_id] # Không có id thì duyệt luôn
          mandocuhandle_id = params[:mandocuhandle_id]
          oUser = User.find(id_user)
          organization_id = oUser&.uorgs&.first&.organization_id
          current_year = Date.current.year
          holiday = Holiday.find_by(year: current_year, user_id: id_user)
          return { msg: "holiday_not_exists", result: false } unless holiday
          full_name = "#{oUser&.last_name} #{oUser&.first_name}"
          holpro = Holpro.find_or_initialize_by(id: holpros_id)
          holpro.assign_attributes(
            stype: "ON-LEAVE",
            dtcreated: Time.current,
            status: stype,
            holiday_id: holiday.id
          )
          holpro.save!

          total_leave = 0
          updated_ids = []

          leave_data.each do |data|
            total_leave += data["itotal"].to_f
            data["holpros_id"] = holpro.id

            detail = Holprosdetail.find_or_initialize_by(id: data["id"])
            detail.assign_attributes(data)
            detail.save!
            updated_ids << detail.id
          end

          holpro.update!(dttotal: total_leave % 1 == 0 ? total_leave.to_i : total_leave)

          Holprosdetail.where(holpros_id: holpro.id).where.not(id: updated_ids).destroy_all

          mandoc = Mandoc.find_or_create_by!(holpros_id: holpro.id) do |m|
            m.status = stype
          end

          case stype_param
          when "TEMP"
            return { msg: "mandoc_not_exists", result: false } unless mandoc

            dhandle = Mandocdhandle.create!(
              mandoc_id: mandoc.id,
              srole: "LEAVE-REQUEST",
              status: stype
            )

            Mandocuhandle.create!(
              mandocdhandle_id: dhandle.id,
              user_id: id_user,
              srole: "MAIN",
              status: "CHUAXULY",
              sread: "NO",
              received_at: Time.current
            )

          when "PENDING"
            return { msg: "mandoc_not_exists", result: false } unless mandoc

            if mandocuhandle_id.present?
              uhandle = Mandocuhandle.find_by(id: mandocuhandle_id)
              uhandle&.update!(status: "DAXULY", sread: "YES")
            else
              dhandle = Mandocdhandle.create!(
                mandoc_id: mandoc.id,
                srole: "LEAVE-REQUEST",
                status: "TEMP"
              )

              Mandocuhandle.create!(
                mandocdhandle_id: dhandle.id,
                user_id: id_user,
                srole: "MAIN",
                status: "DAXULY",
                sread: "NO",
                received_at: Time.current
              )
            end

            # Gửi tiếp sang người tiếp theo (handler_id)
            if !handler_id.nil?
              dhandle_new = Mandocdhandle.create!(
                mandoc_id: mandoc.id,
                srole: "LEAVE-REQUEST",
                contents: "",
                status: stype
              )

              Mandocuhandle.create!(
                mandocdhandle_id: dhandle_new.id,
                user_id: handler_id,
                srole: "MAIN",
                status: "CHUAXULY",
                sread: "NO",
                received_at: Time.current
              )

              mandoc.update!(status: stype)
              # Cập nhật số ngày nghỉ phép theo đơn "NGHI-PHEP" (Trừ ngày nghỉ phép đã đăng ký)
              update_holiday_balance(holpro)
              user_register = holpro&.holiday&.user
              content = "Đơn nghỉ phép của nhân sự: #{user_register&.last_name} #{user_register&.first_name} - Mã nhân sự #{user_register&.sid} cần được xử lý"
              new_notify = Notify.create!(
                title: "Nghỉ phép",
                contents: content,
                senders: "#{user_register&.last_name} #{user_register&.first_name}",
                stype: "LEAVE_REQUEST"
              )

              Snotice.find_or_create_by!(
                notify_id: new_notify.id,
                user_id: handler_id
              ) do |snotice|
                snotice.isread = false
              end
            else
              holpro.update!(status: "DONE")
              mandoc.update!(status: "APPROVE")
              update_holiday_balance(holpro, "registered", true)
              user_register = holpro&.holiday&.user
              content = "Đơn nghỉ phép của nhân sự: #{user_register&.last_name} #{user_register&.first_name} - Mã nhân sự #{user_register&.sid} đã được duyệt"
              new_notify = Notify.create!(
                title: "Nghỉ phép",
                contents: content,
                senders: full_name,
                stype: "LEAVE_REQUEST"
              )

              Mandocuhandle.joins(:user, mandoc: :holpro).where(holpros: { id: holpro&.id}).pluck(:user_id).uniq.map {|user_id|
                Snotice.find_or_create_by!(
                  notify_id: new_notify.id,
                  user_id: user_id
                ) do |snotice|
                  snotice.isread = false
                end
              }

              Work.joins(user: :uorgs)
                  .left_outer_joins(stask: [accesses: :resource])
                  .left_outer_joins(positionjob: {responsibles: {stask: [accesses: :resource]}})
                  .where('resources.scode = :scode OR resources_accesses.scode = :scode', scode: 'LEAVE-PROCESSING')
                  .where('accesses.permision IS NOT NULL OR accesses_stasks.permision IS NOT NULL')
                  .where(users: {staff_status: ["Đang làm việc", "DANG-LAM-VIEC"]}, uorgs: {organization_id: organization_id}).distinct.pluck(:user_id).uniq.map {|user_id|
                Snotice.find_or_create_by!(
                  notify_id: new_notify.id,
                  user_id: user_id
                ) do |snotice|
                  snotice.isread = false
                end
              }

              details = Holprosdetail.where(holpros_id: holpro&.id)
              details.map do |detail|
                next unless detail.handover_receiver
                detail.handover_receiver.split("|||").map do |receiver|
                  user_id = receiver.split("$$$").first
                  Snotice.find_or_create_by!(
                    notify_id: new_notify.id,
                    user_id: user_id
                  ) do |snotice|
                    snotice.isread = false
                  end
                end
              end
            end
          end

          {
            msg: "success",
            result: true
          }
        rescue => e
          {
            msg: "Error: #{e.message}",
            result: false
          }
        end
      end

      # Lê Ngọc Huy
      # Decription: Đăng ký nghỉ phép thay cho nhân viên
      desc "register leave employee"
      params do
        requires :iduser, type: Integer, desc: "User ID"
      end
      post :submit_leave_form_employee do
        begin
          employee_id = params[:employee_id]
          stype_param = params[:stype]
          stype = stype_param == "UPDATE" ? "TEMP" : stype_param
          holpros_id = params[:holpros_id]
          leave_data = params[:leave_form]
          user_create_id = params[:iduser]
          handler_id = params[:handler_id]
          mandocuhandle_id = params[:mandocuhandle_id]
          oUser = User.find(employee_id)
          organization_id = oUser&.uorgs&.first&.organization_id
          full_name = "#{oUser&.last_name} #{oUser&.first_name}"
          current_year = Date.current.year
          holiday = Holiday.find_by(year: current_year, user_id: employee_id)
          return { msg: "holiday_not_exists", result: false } unless holiday

          holpro = Holpro.find_or_initialize_by(id: holpros_id)
          holpro.assign_attributes(
            stype: "ON-LEAVE",
            dtcreated: Time.current,
            status: stype,
            holiday_id: holiday.id
          )
          holpro.save!

          total_leave = 0
          updated_ids = []

          leave_data.each do |data|
            total_leave += data["itotal"].to_f
            data["holpros_id"] = holpro.id

            detail = Holprosdetail.find_or_initialize_by(id: data["id"])
            detail.assign_attributes(data)
            detail.save!
            updated_ids << detail.id
          end

          holpro.update!(dttotal: total_leave % 1 == 0 ? total_leave.to_i : total_leave)

          Holprosdetail.where(holpros_id: holpro.id).where.not(id: updated_ids).destroy_all

          mandoc = Mandoc.find_or_create_by!(holpros_id: holpro.id) do |m|
            m.status = stype
          end

          case stype_param
          when "PENDING"
            return { msg: "mandoc_not_exists", result: false } unless mandoc

            dhandle_created = Mandocdhandle.create!(
              mandoc_id: mandoc.id,
              srole: "LEAVE-REQUEST",
              status: "TEMP"
            )

            Mandocuhandle.create!(
              mandocdhandle_id: dhandle_created.id,
              user_id: user_create_id,
              srole: "MAIN",
              status: "DAXULY",
              sread: "NO",
              received_at: Time.current
            )

            dhandle_approved = Mandocdhandle.create!(
              mandoc_id: mandoc.id,
              srole: "LEAVE-REQUEST",
              status: "PENDING"
            )

            Mandocuhandle.create!(
              mandocdhandle_id: dhandle_approved.id,
              user_id: user_create_id,
              srole: "MAIN",
              status: "DAXULY",
              sread: "NO",
              received_at: Time.current
            )

            update_holiday_balance(holpro)

            if !handler_id.nil?
              dhandle_handler = Mandocdhandle.create!(
                mandoc_id: mandoc.id,
                srole: "LEAVE-REQUEST",
                contents: "",
                status: stype
              )

              Mandocuhandle.create!(
                mandocdhandle_id: dhandle_handler.id,
                user_id: handler_id,
                srole: "MAIN",
                status: "CHUAXULY",
                sread: "NO",
                received_at: Time.current
              )
              mandoc.update!(status: stype)
              user_register = holpro&.holiday&.user
              content = "Đơn nghỉ phép của nhân sự: #{user_register&.last_name} #{user_register&.first_name} - Mã nhân sự #{user_register&.sid} cần được xử lý"
              new_notify = Notify.create!(
                title: "Nghỉ phép",
                contents: content,
                senders: "#{user_register&.last_name} #{user_register&.first_name}",
                stype: "LEAVE_REQUEST"
              )

              Snotice.find_or_create_by!(
                notify_id: new_notify.id,
                user_id: handler_id
              ) do |snotice|
                snotice.isread = false
              end
            else
              holpro.update!(status: "DONE")
              mandoc.update!(status: "APPROVE")
              update_holiday_balance(holpro, "registered", true)
              user_register = holpro&.holiday&.user
              content = "Đơn nghỉ phép của nhân sự: #{user_register&.last_name} #{user_register&.first_name} - Mã nhân sự #{user_register&.sid} đã được duyệt"
              new_notify = Notify.create!(
                title: "Nghỉ phép",
                contents: content,
                senders: full_name,
                stype: "LEAVE_REQUEST"
              )

              Mandocuhandle.joins(:user, mandoc: :holpro).where(holpros: { id: holpro&.id}).pluck(:user_id).uniq.map {|user_id|
                Snotice.find_or_create_by!(
                  notify_id: new_notify.id,
                  user_id: user_id
                ) do |snotice|
                  snotice.isread = false
                end
              }

              Work.joins(user: :uorgs)
                  .left_outer_joins(stask: [accesses: :resource])
                  .left_outer_joins(positionjob: {responsibles: {stask: [accesses: :resource]}})
                  .where('resources.scode = :scode OR resources_accesses.scode = :scode', scode: 'LEAVE-PROCESSING')
                  .where('accesses.permision IS NOT NULL OR accesses_stasks.permision IS NOT NULL')
                  .where(users: {staff_status: ["Đang làm việc", "DANG-LAM-VIEC"]}, uorgs: {organization_id: organization_id}).distinct.pluck(:user_id).uniq.map {|user_id|
                Snotice.find_or_create_by!(
                  notify_id: new_notify.id,
                  user_id: user_id
                ) do |snotice|
                  snotice.isread = false
                end
              }

              details = Holprosdetail.where(holpros_id: holpro&.id)
              details.map do |detail|
                next unless detail.handover_receiver
                detail.handover_receiver.split("|||").map do |receiver|
                  user_id = receiver.split("$$$").first
                  Snotice.find_or_create_by!(
                    notify_id: new_notify.id,
                    user_id: user_id
                  ) do |snotice|
                    snotice.isread = false
                  end
                end
              end
            end
            # Cập nhật số ngày nghỉ phép theo đơn "NGHI-PHEP" (Trừ ngày nghỉ phép đã đăng ký)
          end

          {
            msg: "success",
            result: true
          }
        rescue => e
          {
            msg: "Error: #{e.message}",
            result: false
          }
        end
      end

      # Lê Ngọc Huy
      # Description: Từ chối đơn nghỉ phép
      params do
        requires :holpros_id, type: String, desc: "Holpro ID"
        requires :mandocuhandle_id, type: String, desc: "Holpro ID"
      end
      post :reject_leave do
        begin
          holpros_id = params[:holpros_id]
          mandocuhandle_id = params[:mandocuhandle_id]
          note = params[:note]

          oHolpro = Holpro.find_by(id: holpros_id)
          oMandocuhandle = Mandocuhandle.find_by(id: mandocuhandle_id)
          if oHolpro.present? && oMandocuhandle.present?
            oMandocuhandle.update(notes: note)
            oHolpro.update(status: "REFUSE")
            Holprosdetail.where(holpros_id: holpros_id).update_all(status: "REFUSE")
            Mandocuhandle.joins(mandocdhandle: :mandoc).where(mandocs: {holpros_id: holpros_id}).update_all(status:"DAXULY")
            user_register = oHolpro&.holiday&.user
            new_notify = Notify.create!(
                          title: "Nghỉ phép",
                          contents: "Đơn xin nghỉ phép của #{user_register&.last_name} #{user_register&.first_name} - Mã nhân sự #{user_register&.sid} đã bị từ chối với lý do #{note}",
                          senders: "#{oMandocuhandle&.user&.last_name} #{oMandocuhandle&.user&.first_name}",
                          stype: "LEAVE_REQUEST"
                        )
            Mandocuhandle.joins(:user, mandoc: :holpro).where(holpros: { id: holpros_id}).pluck(:user_id).uniq.map {|user_id|
                Snotice.find_or_create_by!(
                  notify_id: new_notify.id,
                  user_id: user_id
                ) do |snotice|
                  snotice.isread = false
                end
            }
            # Cập nhật số ngày nghỉ phép theo đơn "NGHI-PHEP" (Cộng ngày nghỉ phép đã đăng ký)
            update_holiday_balance(oHolpro, "rejected")

            details = Holprosdetail.where(holpros_id: holpros_id)
            details.map do |detail|
              next unless detail.handover_receiver
              detail.handover_receiver.split("|||").map do |receiver|
                user_id = receiver.split("$$$").first
                Snotice.find_or_create_by!(
                  notify_id: new_notify.id,
                  user_id: user_id
                ) do |snotice|
                  snotice.isread = false
                end
              end
            end

            {
              msg: "success",
              result: true
            }
          else
            {
              msg: "not_exists_info_leave",
              result: true
            }
          end
        rescue => e
          {
            msg: "Error: #{e.message}",
            result: false
          }
        end
      end

      # Lê Ngọc Huy
      # Description: Phê duyệt đơn nghỉ phép
      params do
        requires :iduser, type: Integer, desc: "User ID"
      end
      post :approve_leave do
        begin
          id_user = params[:iduser]
          stype = params[:stype]
          holpros_id = params[:holpros_id]
          handler_id = params[:handler_id]
          mandocuhandle_id = params[:mandocuhandle_id]
          oUser = User.find(id_user)
          organization_id = oUser&.uorgs&.first&.organization_id
          full_name = "#{oUser&.last_name} #{oUser&.first_name}"

          holpro = Holpro.find_by(id: holpros_id)
          return { msg: "holiday_not_exists", result: false } unless holpro

          mandoc = Mandoc.find_by(holpros_id: holpro.id)
          return { msg: "mandoc_not_exists", result: false } unless mandoc

          uhandle = Mandocuhandle.find_by(id: mandocuhandle_id)
          return { msg: "uhandle_not_exists", result: false } unless uhandle
          return { msg: "uhandle_processed", result: false } if uhandle.status == "DAXULY"

          # Gửi tiếp sang người tiếp theo (handler_id)
          user_register = holpro&.holiday&.user

          o_mandoc_cancel = Mandoc.where(holpros_id: holpros_id, status: "CANCEL-PENDING").first
          if o_mandoc_cancel.present? && user_register.present?
            approve_leave_cancel(user_register.id, holpros_id, mandocuhandle_id)
          else
            case stype
            when "PENDING"
              dhandle_new = Mandocdhandle.create!(
                mandoc_id: mandoc.id,
                srole: "LEAVE-REQUEST",
                contents: "",
                status: stype
              )

              Mandocuhandle.create!(
                mandocdhandle_id: dhandle_new.id,
                user_id: handler_id,
                srole: "MAIN",
                status: "CHUAXULY",
                sread: "NO",
                received_at: Time.current
              )

              content = "Đơn nghỉ phép của nhân sự:#{user_register&.last_name} #{user_register&.first_name} - Mã nhân sự #{user_register&.sid} cần được xử lý"
              new_notify = Notify.create!(
                title: "Nghỉ phép",
                contents: content,
                senders: full_name,
                stype: "LEAVE_REQUEST"
              )

              Snotice.find_or_create_by!(
                notify_id: new_notify.id,
                user_id: handler_id
              ) do |snotice|
                snotice.isread = false
              end
            when "APPROVE"
              holpro.update!(status: "DONE")
              update_holiday_balance(holpro, "registered", true)

              content = "Đơn nghỉ phép của nhân sự: #{user_register&.last_name} #{user_register&.first_name} - Mã nhân sự #{user_register&.sid} đã được duyệt"
              new_notify = Notify.create!(
                title: "Nghỉ phép",
                contents: content,
                senders: full_name,
                stype: "LEAVE_REQUEST"
              )

              Mandocuhandle.joins(:user, mandoc: :holpro).where(holpros: { id: holpro&.id}).pluck(:user_id).uniq.map {|user_id|
                Snotice.find_or_create_by!(
                  notify_id: new_notify.id,
                  user_id: user_id
                ) do |snotice|
                  snotice.isread = false
                end
              }

              Work.joins(user: :uorgs)
                  .left_outer_joins(stask: [accesses: :resource])
                  .left_outer_joins(positionjob: {responsibles: {stask: [accesses: :resource]}})
                  .where('resources.scode = :scode OR resources_accesses.scode = :scode', scode: 'LEAVE-PROCESSING')
                  .where('accesses.permision IS NOT NULL OR accesses_stasks.permision IS NOT NULL')
                  .where(users: {staff_status: ["Đang làm việc", "DANG-LAM-VIEC"]}, uorgs: {organization_id: organization_id}).distinct.pluck(:user_id).uniq.map {|user_id|
                Snotice.find_or_create_by!(
                  notify_id: new_notify.id,
                  user_id: user_id
                ) do |snotice|
                  snotice.isread = false
                end
              }

              details = Holprosdetail.where(holpros_id: holpros_id)
              details.map do |detail|
                next unless detail.handover_receiver
                detail.handover_receiver.split("|||").map do |receiver|
                  user_id = receiver.split("$$$").first
                  Snotice.find_or_create_by!(
                    notify_id: new_notify.id,
                    user_id: user_id
                  ) do |snotice|
                    snotice.isread = false
                  end
                end
              end
            end

            mandoc.update!(status: stype)
            uhandle&.update!(status: "DAXULY", sread: "YES")
            amount_to_consume = Holprosdetail.where(holpros_id: holpros_id)
            update_scheduleweek(user_register.id, amount_to_consume.pluck(:details).uniq.join("$$$"), "APPROVED") if user_register.present?
            {
              msg: "success",
              result: true
            }
          end
        rescue => e
          {
            msg: "Error: #{e.message}",
            result: false
          }
        end
      end

      # Lê Ngọc Huy
      # Description: Hủy đơn nghỉ phép
      params do
        requires :holpros_id, type: String, desc: "Holpro ID"
      end
      delete :cancel_leave do
        begin
          holpros_id = params[:holpros_id]
          note = params[:note]

          oHolpro = Holpro.find_by(id: holpros_id)
          if oHolpro.present?
            user_register = oHolpro&.holiday&.user
            if note.present? && oHolpro.status == "DONE"
              new_notify = Notify.create!(
                              title: "Nghỉ phép",
                              contents: "Đơn xin nghỉ phép của #{user_register&.last_name} #{user_register&.first_name} - Mã nhân sự #{user_register&.sid} đã được hủy bởi #{user_register&.last_name} #{user_register&.first_name} với lý do #{note}",
                              senders: "#{user_register&.last_name} #{user_register&.first_name}",
                              stype: "LEAVE_REQUEST"
                          )
              Mandocuhandle.joins(:user, mandoc: :holpro).where(holpros: { id: holpros_id}).pluck(:user_id).uniq.map {|user_id|
                  Snotice.find_or_create_by!(
                    notify_id: new_notify.id,
                    user_id: user_id
                  ) do |snotice|
                    snotice.isread = false
                  end
              }

              oHolpro.update(status: "CANCEL")
              amount_to_consume = Holprosdetail.where(holpros_id: holpros_id)
              update_scheduleweek(user_register.id, amount_to_consume.pluck(:details).uniq.join("$$$"), "CANCELED") if user_register.present?
              Holprosdetail.where(holpros_id: holpros_id).update_all(status: "CANCEL")
              update_holiday_balance(oHolpro, "rejected") # Cập nhật số ngày nghỉ phép theo đơn "NGHI-PHEP" (Trừ ngay nghỉ phép đã đăng ký)
              update_holiday_balance(oHolpro, "rejected", true) # Cập nhật số ngày nghỉ phép theo đơn "NGHI-PHEP" (Trừ ngay nghỉ phép đã đăng ký) nếu đã duyệt
            else
              oHolpro.destroy
            end
            {
              msg: "success",
              result: true
            }
          else
            {
              msg: "not_exists_info_leave",
              result: false
            }
          end
        rescue => e
          {
            msg: "Error: #{e.message}",
            result: false
          }
        end
      end

      # Lê Ngọc Huy
      # Description: Lấy thông tin đơn nghỉ phép của người dùng
      params do
        requires :iduser, type: Integer, desc: "User ID"
      end
      get :get_leave_user do
        begin
          idUser = params[:iduser]
          page = [params[:page].to_i, 1].max
          per_page = 5
          offset = (page - 1) * per_page
          totalRecord = 0

          if !idUser.nil? && idUser != ""
            oData = Holpro.joins(holiday: :user)
                          .select("holpros.*, CONCAT(users.last_name, ' ', users.first_name) as user_name, users.sid")
                          .where(users: {id: idUser})
                          .order(id: :DESC)
                          .limit(per_page).offset(offset)
                          .map do |oHolpro|

                            # Extract all dates từ perDaySelections
                            all_dates = oHolpro&.holprosdetails&.map do |holprosdetail|
                              holprosdetail.details.to_s.split("$$$").map do |date_str|
                                Date.parse(date_str.split("-")[0]) rescue nil
                              end
                            end&.flatten&.compact || []

                            # Gom nhóm các ngày liên tục thành các khoảng
                            dates = ""
                            if all_dates.any?
                              sorted_dates = all_dates.sort
                              ranges = []
                              current_range = [sorted_dates.first]

                              sorted_dates.each_cons(2) do |d1, d2|
                                if (d2 - d1).to_i == 1
                                  current_range << d2
                                else
                                  ranges << current_range
                                  current_range = [d2]
                                end
                              end
                              ranges << current_range if current_range.any?

                              dates = ranges.map do |r|
                                if r.size == 1
                                  r.first.strftime("%d/%m/%Y")
                                else
                                  "#{r.first.strftime("%d/%m/%Y")} - #{r.last.strftime("%d/%m/%Y")}"
                                end
                              end.join(" & ")
                            end

                            # Map leaveType codes sang tên
                            leave_types = oHolpro&.holprosdetails&.map { |holprosdetail| holprosdetail.sholtype.to_s } || []
                            str_leave_types = Holtype.where(code: leave_types).pluck(:code, :name).to_h
                            str_leave_type = leave_types.map { |code| str_leave_types[code] || code }.join(", ")

                            id_uhandle = Mandocuhandle.joins(:user, mandoc: :holpro)
                                                      .where(mandocs: {holpros_id: oHolpro.id}, mandocdhandles: {status: ["TEMP"]})
                                                      .last&.id

                            {
                              id: oHolpro.id.to_s,
                              mandocuhandle_id: id_uhandle&.to_s,
                              user_name: oHolpro.user_name,
                              user_sid: oHolpro.sid,
                              itotal: oHolpro&.dttotal,
                              status: oHolpro&.status,
                              deparment: "",
                              strLeaveType: str_leave_type,
                              dates: dates,
                              time_old: time_ago_in_words(oHolpro.created_at.in_time_zone('Asia/Ho_Chi_Minh')),
                              leaves: oHolpro&.holprosdetails.map do |holprosdetail|
                                {
                                  idSubmit: holprosdetail.id.to_s,
                                  leaveType: holprosdetail.sholtype.to_s,
                                  supportPersons: holprosdetail.handover_receiver.to_s,
                                  locationCountry: holprosdetail.issued_place.to_s,
                                  startDate: holprosdetail.dtfrom&.strftime("%d/%m/%Y").to_s,
                                  endDate: holprosdetail.dtto&.strftime("%d/%m/%Y").to_s,
                                  perDaySelections: holprosdetail.details.to_s,
                                  address: holprosdetail.place_before_hol.to_s,
                                  reason: holprosdetail.note.to_s,
                                  purposeAbroad: holprosdetail.note.to_s,
                                  departureAddress: holprosdetail.place_before_hol.to_s,
                                  overseasAddress: holprosdetail.issued_national.to_s,
                                  totalDays: holprosdetail.itotal.to_f.to_s,
                                  all_changes: ""
                                }
                              end
                            }
                          end

            totalRecord = Mandocuhandle.joins(:user, mandoc: :holpro)
                                      .where(mandocuhandles: {user_id: idUser}, mandocdhandles: {status: ["TEMP"]})
                                      .count
            return {
              :msg => "success",
              :total => totalRecord,
              :result => oData
            }
          else
            return {
              :msg => "user_not_found",
              :total => totalRecord,
              :result => []
            }
          end
        rescue => e
          return {
            :msg => "Error: #{e.message}",
            :total => totalRecord,
            :result => []
          }
        end
      end


      # Lê Ngọc Huy
      # Description: Lấy thông tin đơn nghỉ phép cần xử lý của người dùng
      params do
        requires :iduser, type: Integer, desc: "User ID"
      end
      get :get_leaves_handle do
        begin
          idUser = params[:iduser]
          page = [params[:page].to_i, 1].max
          per_page = 5
          offset = (page - 1) * per_page
          totalRecord = 0
          if !idUser.nil? && idUser != ""
              oData = Mandocuhandle.select("mandocuhandles.*, holpros.id as holpros_id, CONCAT(users.last_name, ' ', users.first_name) as user_name, users.sid")
                .joins(:user, mandoc: :holpro)
                .where(mandocuhandles: {user_id: idUser, status: "CHUAXULY"})
                .where.not(mandocdhandles: {status: ["TEMP"]})
                .order(id: :DESC)
                .limit(per_page).offset(offset)
                .map do |holpros|
                  oHolpro = Holpro.find_by(id: holpros.holpros_id)
                  # Extract all dates từ perDaySelections
                  all_dates = oHolpro&.holprosdetails&.map do |holprosdetail|
                      holprosdetail.details.to_s.split("$$$").map do |date_str|
                          Date.parse(date_str.split("-")[0]) rescue nil
                        end
                    end&.flatten&.compact || []

                  # Gom nhóm các ngày liên tục thành các khoảng
                  dates = ""
                  if all_dates.any?
                    sorted_dates = all_dates.sort
                    ranges = []
                    current_range = [sorted_dates.first]

                    sorted_dates.each_cons(2) do |d1, d2|
                        if (d2 - d1).to_i == 1
                          current_range << d2
                          else
                          ranges << current_range
                          current_range = [d2]
                          end
                      end
                    ranges << current_range if current_range.any?

                    dates = ranges.map do |r|
                        if r.size == 1
                          r.first.strftime("%d/%m/%Y")
                          else
                          "#{r.first.strftime("%d/%m/%Y")} - #{r.last.strftime("%d/%m/%Y")}"
                          end
                      end.join(" & ")
                    end

                  leave_types = oHolpro&.holprosdetails&.map { |holprosdetail| holprosdetail.sholtype.to_s } || []
                  str_leave_types = Holtype.where(code: leave_types).pluck(:code, :name).to_h
                  str_leave_type = leave_types.map { |code| str_leave_types[code] || code }.join(", ")
                  user_register = oHolpro&.holiday&.user
                    {
                      id: oHolpro&.id.to_s,
                      mandocuhandle_id: holpros.id.to_s,
                      user_name: "#{user_register&.last_name} #{user_register&.first_name}",
                      user_sid: holpros.sid,
                      itotal: oHolpro&.dttotal,
                      status: oHolpro&.status,
                      deparment: user_register&.works&.joins(positionjob: :department)&.pluck("departments.name")&.uniq&.map {|name| "#{name}" }&.join(', '),
                      strLeaveType: Mandoc.where(holpros_id: oHolpro&.id.to_s, status: "CANCEL-PENDING").exists? ? "Đơn hủy ngày phép" : "Đơn nghỉ #{str_leave_type}",
                      dates: dates,
                      time_old: time_ago_in_words(holpros.created_at.in_time_zone('Asia/Ho_Chi_Minh')),
                      leaves: oHolpro&.holprosdetails.map do |holprosdetail|
                        {
                          idSubmit: holprosdetail.id.to_s,
                          leaveType: holprosdetail.sholtype.to_s,
                          supportPersons: holprosdetail.handover_receiver.to_s,
                          locationCountry: holprosdetail.issued_place.to_s,
                          startDate: holprosdetail.dtfrom&.strftime("%d/%m/%Y").to_s,
                          endDate: holprosdetail.dtto&.strftime("%d/%m/%Y").to_s,
                          perDaySelections: holprosdetail.details.to_s,
                          address: holprosdetail.place_before_hol.to_s,
                          reason: holprosdetail.note.to_s,
                          purposeAbroad: holprosdetail.note.to_s,
                          departureAddress: holprosdetail.place_before_hol.to_s,
                          overseasAddress: holprosdetail.issued_national.to_s,
                          totalDays: holprosdetail.itotal.to_f.to_s,
                          all_changes: list_array_cancel(oHolpro&.holprosdetails)
                        }
                      end
                    }
                end

                totalRecord = Mandocuhandle.joins(:user, mandoc: :holpro)
                              .where(mandocuhandles: {user_id: idUser, status: "CHUAXULY"})
                              .where.not(mandocdhandles: {status: ["TEMP"]}).count
            return {
              :msg => "success",
              :total => totalRecord,
              :result => oData
            }
          else
            return {
              :msg => "user_not_found",
              :total => totalRecord,
              :result => []
            }
          end
        rescue => e
          return {
            :msg => "Error: #{e.message}",
            :total => totalRecord,
            :result => []
            }
        end
      end

      # Lê Ngọc Huy
      # Description: Lấy thông tin timeline của đơn nghỉ phép
      params do
        requires :holpros_id, type: String, desc: "Holpro ID"
      end
      get :get_leave_timeline do
        begin
          holpros_id = params[:holpros_id]
          oHolpro = Holpro.find_by(id: holpros_id)

          if oHolpro
            holpro_status = oHolpro.status
            mandocuhandles = Mandocuhandle.select("mandocuhandles.*, mandocdhandles.status as stype, CONCAT(users.last_name, ' ', users.first_name) as user_name, users.sid, users.id as user_id")
              .joins(:user, mandoc: :holpro)
              .where(holpros: { id: holpros_id })
              .where.not(mandocuhandles: {srole: "SUB"})

            result = mandocuhandles.map.with_index do |uhandle, index|
              is_last = index == mandocuhandles.size - 1
              time_handle_zone = uhandle.updated_at.in_time_zone("Asia/Ho_Chi_Minh")
              is_complete = uhandle.status == "DAXULY"

              {
                id: uhandle.id.to_s,
                date: is_complete ? time_handle_zone.strftime("%d/%m/%Y") : "",
                notes: uhandle.notes.to_s,
                time: is_complete ? time_handle_zone.strftime("%H:%M") : "",
                title: uhandle.stype == "TEMP" ? "register_leave" : (is_last && holpro_status == "REFUSE" ? "reject_leave" : "approve_leave"),
                is_cancel: uhandle.stype == "CANCEL-TEMP" || (uhandle.stype == "TEMP" && holpro_status == "CANCEL") ? "YES" : "NO",
                person: uhandle.user_name,
                position_jobs: Positionjob.joins(works: :user).where(users: {id: uhandle.user_id}).where.not(works: {positionjob_id: nil}).pluck("positionjobs.name").uniq.map {|name| "#{name}" }.join(', '),
                isCompleted: is_complete
              }
            end

            return {
              msg: "success",
              result: result
            }
          else
            return {
              msg: "not_exists_info_leave",
              result: []
            }
          end
        rescue ActiveRecord::RecordNotFound => e
          return {
            msg: "Record not found: #{e.message}",
            result: []
          }
        rescue StandardError => e
          return {
            msg: "Error: #{e.message}",
            result: []
          }
        end
      end

      # Lê Ngọc Huy
      # Description: Lấy danh sách người dùng có quyền phê duyệt đơn nghỉ phép
      params do
        requires :iduser, type: String, desc: "iduser ID"
      end
      # get :get_users_handle do
      #   begin
      #     # người đang đăng nhập
      #     user_id = params[:iduser]  # tương đương với session nếu thằng is_approve == true
      #     holpros_id = params[:holpros_id]
      #     # người được đăng ký thay
      #     employee_id = params[:employee_id]
      #     organization_id = params[:organizationId]
      #     is_approve = params[:is_approve] || nil
      #     # xử lý đơn các phòng ban
      #     check_per_bgd = false
      #     if is_approve.present? && !employee_id.present?
      #       # new_code
      #       holpro = Holpro.find_by(id: holpros_id)
      #       user_register = holpro.holiday.user_id
      #       departments = fetch_leaf_departments_by_user(user_id)
      #       department_user_register = fetch_leaf_departments_by_user(user_register)
      #       oUserORG = Uorg.find_by(user_id: user_id)

      #       organization_id = oUserORG.organization_id
      #       streams = Stream.joins("INNER JOIN operstreams ON operstreams.stream_id = streams.id")
      #                         .where(operstreams: { organization_id: organization_id })
      #                         .where("streams.scode LIKE ?", "%DUYET-PHEP-BUH%").first
      #       stream_id = streams&.id
      #       depart = nil
      #       if departments.present? && stream_id.present?
      #         department = departments.first
      #         if department&.parents.present?
      #           depart = department.parents
      #         elsif department_user_register.first&.faculty == "BGD(BUH)"
      #           deparment_buh = Department.where(faculty: "PTCHC(BUH)").first
      #           depart = deparment_buh.id
      #         else
      #           exit_node = Node.where(stream_id:stream_id).where(department_id: department.id).first
      #           if exit_node.present?
      #             scode = "BOARD-APPROVE"
      #           else
      #             scode = "HR-APPROVED"
      #           end
      #           result = stream_connect_by_status_code("DUYET-PHEP-BUH", scode)
      #           depart = result&.first&.dig(:next_department_id)
      #         end
      #       end
            # check_per_bgd = Work.joins(stask: { accesses: :resource })
            #                         .where(
            #                           resources: { scode: "LEAVE-BGD" },
            #                           works:     { user_id: user_register },
            #                           accesses:  { permision: "ADM" }
            #                         )
            #                         .exists?
      #       common_departments = departments & department_user_register
      #       oDepartment = if common_departments.present?
      #                       common_departments.first
      #                     elsif departments.size == 1
      #                       departments.first
      #                     else
      #                       nil
      #                     end

      #       if oDepartment.present?
      #         if depart != oDepartment.id
      #           next_oDepartment = Department.where(id: oDepartment.parents&.to_i).first&.id
      #           next_oDepartment ||= depart
      #         else
      #           next_oDepartment = depart
      #         end
      #       else
      #         next_oDepartment = depart
      #       end

      #       # --- xử lý lấy user_ids ---
      #       if oDepartment.present? && oDepartment.parents.present?
      #         target_department = oDepartment.parents
      #       else
      #         target_department = next_oDepartment
      #       end
      #       # user thuộc phòng ban target_department
      #       current_user_ids = Work.where(
      #         positionjob_id: Positionjob.where(department_id: target_department).pluck(:id)
      #       ).pluck(:user_id)
      #       # user có quyền APPROVE-REQUEST
      #       check_depart = Department.where(id: target_department).first
      #       if check_depart.faculty == "PTCHC(BUH)"
      #         list_user_ids = Work.joins(stask: [accesses: :resource])
      #                             .where(resources: { scode: "APPROVE-REQUEST" })
      #                             .where(accesses: { permision: "READ" })
      #                             .pluck(:user_id)
      #       else
      #         list_user_ids = Work.joins(stask: [accesses: :resource])
      #                           .where(resources: { scode: "APPROVE-REQUEST" })
      #                           .where(accesses: { permision: "ADM" })
      #                           .where.not(user_id: user_register)
      #                           .pluck(:user_id)
      #       end
      #       # giao giữa 2 nhóm
      #       user_ids = current_user_ids & list_user_ids
      #       result = User.where(id: user_ids, staff_status: ["Đang làm việc", "DANG-LAM-VIEC"])
      #                   .select("id", "CONCAT(last_name, ' ', first_name) AS name").map { |w| { id: w.id.to_s, name: w.name } }

      #     else
      #       result = fetchStaffForWorkflowLeave(user_id: user_id)
      #       # thêm trường trường hợp BGĐ
      #       check_per_bgd = Work.joins(stask: { accesses: :resource })
      #                               .where(
      #                                 resources: { scode: "LEAVE-BGD" },
      #                                 works:     { user_id: user_id },
      #                                 accesses:  { permision: "ADM" }
      #                               )
      #                               .exists?
      #       # Phó giám đốc
      #     end

      #     # if @faculty == "PTCHC(BUH)" || @check_button == "FINAL_HANDLE" || (is_approve.present? && result.size == 0)
      #     if check_per_bgd == true || (is_approve.present? && result.size == 0)
      #       # duyệt đơn
      #       { msg: "approve" , result: result }
      #     else
      #       # trình
      #       { msg: "success" , result: result }
      #     end
      #   rescue => e
      #     { msg: "Error: #{e.message}", result: [] }
      #   end
      # end


      get :get_users_handle do
        begin
          user_id = params[:iduser]
          holpros_id = params[:holpros_id]
          employee_id = params[:employee_id]
          organization_id = params[:organizationId]
          is_approve = params[:is_approve] || nil
          if is_approve.present? && !employee_id.present?
            oHolpro = Holpro.find_by(id: holpros_id.to_i)
            user = oHolpro&.holiday&.user
            departments = fetch_leaf_departments_by_user(user_id)
            check_per_bgd = Work.joins(stask: { accesses: :resource })
                                        .where(
                                          resources: { scode: "LEAVE-BGD" },
                                          works:     { user_id: user_id },
                                          accesses:  { permision: "ADM" }
                                        )
                                        .exists?
            oUserORG = Uorg.find_by(user_id: user_id)
            organization_id = oUserORG.organization_id
            streams = Stream.joins("INNER JOIN operstreams ON operstreams.stream_id = streams.id")
                              .where(operstreams: { organization_id: organization_id })
                              .where("streams.scode LIKE ?", "%DUYET-PHEP-BUH%").first
            stream_id = streams&.id
            check_button = "none"
            faculty = ""
            if departments.present? && stream_id.present?
              department = departments.first
              if department&.parents.present?
                depart = department.parents
                faculty = department.faculty
              else
                exit_node = Node.where(stream_id:stream_id).where(department_id: department.id).first
                if exit_node.present?
                  department_id = department.id
                  faculty = department.faculty
                  scode = "BOARD-APPROVE"
                  check_button ="FINAL_HANDLE"
                else
                  first_node = Node.where(stream_id: stream_id, nfirst: "YES").first
                  department_id = first_node.department_id
                  faculty = department.faculty
                  scode = "HR-APPROVED"
                  check_button ="FIRST_HANDLE"
                end
                result = stream_connect_by_status_code("DUYET-PHEP-BUH", scode)
                depart = result&.first&.dig(:next_department_id)
              end
              @depart = depart
              @faculty = faculty
              @check_button = check_button

              check_faculty = department&.faculty == "PTCHC(BUH)"

              department_user = fetch_leaf_departments_by_user(user&.id)
              department_regis_user = department_user.first
              department_user_id = department_regis_user&.id

              # Lấy đúng Work gắn với positionjob thuộc về department_user
              work = Work.includes(:positionjob)
                        .where(user_id: user&.id)
                        .where.not(positionjob_id: nil)
                        .detect { |w| w.positionjob&.department_id == department_user_id }
              # 21/10/2025
              # h.anh
              # kiểm tra bgd
              if department.faculty == "BGD(BUH)"
                @don_nhan_su = true
              end
              if check_faculty == true
                positionjob   = work&.positionjob
                position_code = positionjob&.scode&.to_s&.upcase
                check_code = position_code&.match?(/TRUONG|PHO/)
                check_per = Work.joins(stask: { accesses: :resource })
                                          .where(
                                            resources: { scode: "APPROVE-REQUEST" },
                                            works:     { user_id: user_id },
                                            accesses:  { permision: "ADM" }
                                          )
                                          .exists?
                if check_code == true || check_per == true
                  theo_doi = true
                end
                if department&.parents.present?
                  theo_doi = false
                end
                if department_regis_user&.faculty == "PTCHC(BUH)"
                  @don_nhan_su = true
                end
                bien_phong = true
              else
                theo_doi = false
                bien_phong = false
              end
              if bien_phong
                if theo_doi
                  @trinh = true
                else
                  @duyet = true
                end
              end
            end
            #  lấy danh sách nhân sự duyệt phép
              depart = @depart
              user_register = user&.id

              department_user = fetch_leaf_departments_by_user(user_id)
              department_user_register = fetch_leaf_departments_by_user(user_register)

              common_departments = department_user & department_user_register
              oDepartment = if common_departments.present?
                              common_departments.first
                            elsif department_user.size == 1
                              department_user.first
                            else
                              nil
                            end

              if oDepartment.present?
                if depart != oDepartment.id
                  next_oDepartment = Department.where(id: oDepartment.parents&.to_i).first&.id
                  next_oDepartment ||= depart
                else
                  next_oDepartment = depart
                end
              else
                next_oDepartment = depart
              end
              # --- xử lý lấy user_ids ---
              if oDepartment.present? && oDepartment.parents.present?
                target_department = oDepartment.parents
              else
                target_department = next_oDepartment
              end
              # user thuộc phòng ban target_department
              current_user_ids = Work.where(
                positionjob_id: Positionjob.where(department_id: target_department).pluck(:id)
              ).pluck(:user_id)
              # user có quyền APPROVE-REQUEST
              check_depart = Department.where(id: target_department).first
              if check_depart&.faculty == "PTCHC(BUH)"
                list_user_ids = Work.joins(stask: [accesses: :resource])
                                    .where(resources: { scode: "APPROVE-REQUEST" })
                                    .where(accesses: { permision: "READ" })
                                    .pluck(:user_id)
              else
                list_user_ids = Work.joins(stask: [accesses: :resource])
                                  .where(resources: { scode: "APPROVE-REQUEST" })
                                  .where(accesses: { permision: "ADM" })
                                  .pluck(:user_id)
              end
              # giao giữa 2 nhóm
              user_ids = current_user_ids & list_user_ids
              result = User.where(id: user_ids, staff_status: ["Đang làm việc", "DANG-LAM-VIEC"])
                          .select("id", "CONCAT(last_name, ' ', first_name) AS name").map { |w| { id: w.id.to_s, name: w.name } }
            # end lấy nhân sự
          else
            result = fetchStaffForWorkflowLeave(user_id: user_id)
            if employee_id.present?
                # if !check_permission_approve_leave(employee_id).present?
                #    @check_button = "FINAL_HANDLE"
                # end
                user_ids = [employee_id, user_id].compact  # loại bỏ nil
                check_per_bgd = Work.joins(stask: { accesses: :resource })
                                    .where(
                                      resources: { scode: "LEAVE-BGD" },
                                      works:     { user_id: user_ids },
                                      accesses:  { permision: "ADM" }
                                    )
                                    .exists?
                department_user = fetch_leaf_departments_by_user(employee_id)
                department_regis_user = department_user.first
                check_faculty = department_regis_user&.faculty == "PTCHC(BUH)"
                check_per_tchc = Work.joins(stask: { accesses: :resource })
                                    .where(
                                      resources: { scode: "APPROVE-REQUEST" },
                                      works:     { user_id: employee_id },
                                      accesses:  { permision: "ADM" }
                                    )
                                    .exists?
                if check_faculty == true && check_per_tchc == false
                  @don_ns_tchc = true
                end
            else
              check_per_bgd = Work.joins(stask: { accesses: :resource })
                                        .where(
                                          resources: { scode: "LEAVE-BGD" },
                                          works:     { user_id: user_id },
                                          accesses:  { permision: "ADM" }
                                        )
                                        .exists?
            end
          end
          if check_per_bgd == true || @duyet == true || @don_nhan_su == true || @don_ns_tchc == true || (is_approve.present? && result.size == 0)
            { msg: "approve" , result: result, check_per_bgd: check_per_bgd }
          elsif @trinh == true
            { msg: "success" , result: result, check_per_bgd: check_per_bgd}
          else
            { msg: "success" , result: result, check_per_bgd: check_per_bgd}
          end
        rescue => e
          { msg: "Error: #{e.message}", result: [] }
        end
      end



      # helpers do
      #   include LeaveRequestHelper
      # end
      # desc "Xác định người xử lý đơn nghỉ phép (tự đăng ký hoặc đăng ký hộ)"
      # params do
      #   requires :iduser, type: Integer, desc: "Người thao tác (session[:iduser])"
      #   optional :employee_id, type: Integer, desc: "Người được đăng ký (chủ đơn)"
      #   optional :is_approve, type: Boolean, desc: "true = đăng ký hộ, false = tự đăng ký"
      # end
      # get :get_users_handle do
      #   begin
      #     # Người thao tác
      #     oUser = User.find_by(id: params[:iduser])
      #     return { msg: "Không tìm thấy người thao tác", result: [] } if oUser.nil?

      #     # Người được đăng ký (nếu không có thì coi như chính là oUser)
      #     oRegister = if params[:employee_id].present?
      #                   User.find_by(id: params[:employee_id])
      #                 else
      #                   oUser
      #                 end
      #     return { msg: "Không tìm thấy người được đăng ký", result: [] } if oRegister.nil?

      #     # Gọi sang helper quyết định approve / success
      #     lrh_decide_handle_user(oUser, oRegister, params[:is_approve])

      #   rescue => e
      #     { msg: "Error: #{e.message}", result: [] }
      #   end
      # end



      # Lê Ngọc Huy
      # Description: Lấy danh sách người dùng có quyền theo mã quyền
      params do
        requires :permision_code, type: String, desc: "permision code"
      end
      get :get_users_with_permision_code do
        begin
          permision_code = params[:permision_code]
          users_have_access_with_positionjob = Work.joins(:user)
              .left_outer_joins(:positionjob => { :stasks => { :accesses => :resource } })
              .where(resources: {scode: permision_code})
              .where.not(accesses: {permision: nil})
              .where(users: {staff_status: ["Đang làm việc", "DANG-LAM-VIEC"]})
              .where.not(users: {status: 'INACTIVE'})
              .select("works.user_id", "CONCAT(users.last_name, ' ', users.first_name) AS name, users.email")
              .map { |w| { id: w.user_id.to_s, name: w.name, email: w.email} }
          users_have_access_with_stask = Work.joins(:user)
              .left_outer_joins(:stask => { :accesses => :resource })
              .where(resources: {scode: permision_code})
              .where.not(accesses: {permision: nil})
              .where(users: {staff_status: ["Đang làm việc", "DANG-LAM-VIEC"]})
              .where.not(users: {status: 'INACTIVE'})
              .select("works.user_id", "CONCAT(users.last_name, ' ', users.first_name) AS name, users.email")
              .map { |w| { id: w.user_id.to_s, name: w.name, email: w.email} }
          users_have_access = (users_have_access_with_positionjob + users_have_access_with_stask).uniq { |u| u[:id] }
          { msg: "success" , result: users_have_access }
        rescue => e
          { msg: "Error: #{e.message}", result: [] }
        end
      end

      # Save attend of user
      # @author: Dat Le
      # @date: 27/06/2025
      # @input: user_id, department_id
      # @output: msg
      desc "Save attend of user"
      post :save_attend do
        begin
          user_id = params[:user_id]
          file = params['file']
          tinezone = 'Asia/Ho_Chi_Minh'
          current_time = Time.zone.now.in_time_zone("Asia/Ho_Chi_Minh")
          day_start_utc = current_time.in_time_zone(tinezone).beginning_of_day.utc
          day_end_utc   = current_time.in_time_zone(tinezone).end_of_day.utc

          oUser = User.find_by(id: user_id)
          return { msg: "user_not_exists", result: false } unless oUser

          # Xử lý lưu hình ảnh chấm công vào database
          mediafile = upload_file(file)
          return { msg: "media_file_upload_failed", result: false } unless mediafile[:id].present?

          shiftId = Shiftselection
                      .joins(:scheduleweek, :workshift)
                      .where(scheduleweeks: { user_id: user_id, status: 'APPROVED' })
                      .where(is_day_off: nil)
                      .where(work_date: current_time.beginning_of_day..current_time.end_of_day)
                      .pluck(:id, :start_time)

          return({ msg: "user_has_no_workshift_today", result: false }) if shiftId.blank?

          shiftId = shiftId.sort_by { |(_id, st)| Time.strptime(st, '%H:%M') rescue Time.at(0) }
                           .map(&:first)

          # Chống trùng dữ liệu trong VÒNG 5 PHÚT
          duplicate = Attend.where(user_id: user_id, stype: 'ATTENDANCE')
                            .where(" (checkin  BETWEEN ? AND ?) OR (checkout BETWEEN ? AND ?) ",
                              5.minutes.ago, current_time, 5.minutes.ago, current_time)
                            .exists?
          return({ msg: "Đã điểm danh thành công trước đó.", result: false }) if duplicate

          selected = nil
          shiftId.each do |sid|
            att = Attend.where(user_id: user_id)
                        .where(checkin: day_start_utc..day_end_utc)
                        .where(stype: "ATTENDANCE", shiftselection_id: sid)
                        .order(created_at: :desc)
                        .first

            if att.nil?
              selected = { shift_id: sid, attend: nil, action: :checkin }    # Lần 1 hoặc 3
              break
            elsif att.checkout.blank?
              selected = { shift_id: sid, attend: att, action: :checkout }   # Lần 2 hoặc 4
              break
            end
          end

          return({ msg: "already_checked_in_and_out_today", result: false }) if selected.nil?

          shiftId = selected[:shift_id]
          oAttend = selected[:attend]

          # Save checkin
          if oAttend.nil?
            attend = Attend.new(
              user_id: user_id,
              checkin: current_time,
              stype: 'ATTENDANCE',
              status: 'CHECKIN',
              shiftselection_id: shiftId,
              note: "Nhân viên chấm công vào làm trên B-ERP/Website vào lúc #{current_time.strftime('%H:%M %d/%m/%Y')}"
            )
            ActiveRecord::Base.transaction do
              attend.save!
              Attenddetail.create!(
                attend_id: attend.id,
                dtcheckin: current_time,
                pic: mediafile[:id],
                stype: 'CHECKIN'
              )
            end
            return { msg: "save_check_in_successfully", result: true }
            # Save checkout
          elsif oAttend.checkout.blank?
            oAttend.update!(
              checkout: current_time,
              status: 'CHECKOUT',
              note: "Nhân viên chấm công tan ca trên B-ERP/Website vào lúc #{current_time.strftime('%H:%M %d/%m/%Y')}"
            )
            Attenddetail.create!(
              attend_id: oAttend.id,
              dtcheckout: current_time,
              pic: mediafile[:id],
              stype: 'CHECKOUT'
            )
            return { msg: "save_check_out_successfully", result: true }
          else
            return { msg: "already_checked_in_and_out_today", result: false}
          end
        rescue => e
          return { msg: "Error: #{e.message}", result: false}
        end
      end

      # Save attend by shift id
      # @author: L.Huy
      # @date: 26/02/2026
      # @input: user_id, shiftselection_id, file
      # @output: msg
      # desc "Save attend by shift id"
      # post :save_attend_by_shift do
      #   begin
      #     user_id  = params[:user_id]
      #     shift_id = params[:shiftselection_id]
      #     file     = params['file']

      #     timezone = 'Asia/Ho_Chi_Minh'
      #     current_time = Time.zone.now.in_time_zone(timezone)
      #     day_start_utc = current_time.beginning_of_day.utc
      #     day_end_utc   = current_time.end_of_day.utc

      #     # 1️⃣ Check user
      #     user = User.find_by(id: user_id)
      #     return { msg: "user_not_exists", result: false } unless user

      #     # 2️⃣ Check shift tồn tại và thuộc user
      #     shift = Shiftselection
      #               .joins(:scheduleweek)
      #               .where(id: shift_id)
      #               .where(scheduleweeks: { user_id: user_id, status: 'APPROVED' })
      #               .where(is_day_off: nil)
      #               .first

      #     return { msg: "shift_not_found_or_not_allowed", result: false } unless shift

      #     # 3️⃣ Check shift có phải hôm nay không
      #     unless shift.work_date.between?(current_time.beginning_of_day, current_time.end_of_day)
      #       return { msg: "shift_not_today", result: false }
      #     end

      #     # 4️⃣ Upload file
      #     mediafile = upload_file(file)
      #     return { msg: "media_file_upload_failed", result: false } unless mediafile[:id].present?

      #     # 5️⃣ Chống duplicate trong 5 phút
      #     duplicate = Attend.where(user_id: user_id, stype: 'ATTENDANCE')
      #                       .where(shiftselection_id: shift_id)
      #                       .where("(checkin BETWEEN ? AND ?) OR (checkout BETWEEN ? AND ?)",
      #                         current_time - 5.minutes, current_time,
      #                         current_time - 5.minutes, current_time)
      #                       .exists?

      #     return { msg: "Đã điểm danh thành công trước đó.", result: false } if duplicate

      #     # 6️⃣ Tìm attend trong ngày cho shift này
      #     attend = Attend.where(user_id: user_id)
      #                   .where(stype: "ATTENDANCE", shiftselection_id: shift_id)
      #                   .where(checkin: day_start_utc..day_end_utc)
      #                   .order(created_at: :desc)
      #                   .first

      #     # =========================
      #     # CHECKIN
      #     # =========================
      #     if attend.nil?
      #       new_attend = Attend.new(
      #         user_id: user_id,
      #         checkin: current_time,
      #         stype: 'ATTENDANCE',
      #         status: 'CHECKIN',
      #         shiftselection_id: shift_id,
      #         note: "Checkin lúc #{current_time.strftime('%H:%M %d/%m/%Y')}"
      #       )

      #       ActiveRecord::Base.transaction do
      #         new_attend.save!
      #         Attenddetail.create!(
      #           attend_id: new_attend.id,
      #           dtcheckin: current_time,
      #           pic: mediafile[:id],
      #           stype: 'CHECKIN'
      #         )
      #       end

      #       return { msg: "save_check_in_successfully", result: true }

      #     # =========================
      #     # CHECKOUT
      #     # =========================
      #     elsif attend.checkout.blank?
      #       attend.update!(
      #         checkout: current_time,
      #         status: 'CHECKOUT',
      #         note: "Checkout lúc #{current_time.strftime('%H:%M %d/%m/%Y')}"
      #       )

      #       Attenddetail.create!(
      #         attend_id: attend.id,
      #         dtcheckout: current_time,
      #         pic: mediafile[:id],
      #         stype: 'CHECKOUT'
      #       )

      #       return { msg: "save_check_out_successfully", result: true }

      #     else
      #       return { msg: "already_checked_in_and_out_today", result: false }
      #     end

      #   rescue => e
      #     return { msg: "Error: #{e.message}", result: false }
      #   end
      # end

      desc "Save attend of user"
      post :save_attend_v2 do
        begin
          user_id           = params[:user_id]
          file              = params['file']
          shiftselection_id = params[:shiftselection_id]
          check_type        = params[:check_type]  # "checkin" hoặc "checkout"
          timezone          = 'Asia/Ho_Chi_Minh'
          current_time      = Time.zone.now.in_time_zone(timezone)
          day_start_utc     = current_time.beginning_of_day.utc
          day_end_utc       = current_time.end_of_day.utc

          oUser = User.find_by(id: user_id)
          return { msg: "user_not_exists", result: false } unless oUser

          # Xử lý lưu hình ảnh chấm công vào database
          mediafile = upload_file(file)
          return { msg: "media_file_upload_failed", result: false } unless mediafile[:id].present?

          # Chống trùng dữ liệu trong vòng 5 phút
          duplicate = Attend.where(user_id: user_id, stype: 'ATTENDANCE')
                            .where("(checkin BETWEEN ? AND ?) OR (checkout BETWEEN ? AND ?)",
                                  5.minutes.ago, current_time, 5.minutes.ago, current_time)
                            .exists?
          return { msg: "Đã điểm danh thành công trước đó.", result: false } if duplicate

          if shiftselection_id.present? && check_type.present?
            # ── Nhánh mới: điểm danh theo ca và loại đã chọn ──

            # Validate ca thuộc user và hôm nay
            sel = Shiftselection
                    .joins(:scheduleweek)
                    .where(
                      id:            shiftselection_id,
                      scheduleweeks: { user_id: user_id, status: 'APPROVED' },
                      work_date:     current_time.beginning_of_day..current_time.end_of_day
                    )
                    .first
            return { msg: "user_has_no_workshift_today", result: false } unless sel

            shift_id = sel.id

            if check_type == "checkin"
              # Chưa được tồn tại record checkin cho ca này
              existing = Attend.where(user_id: user_id, stype: 'ATTENDANCE', shiftselection_id: shift_id)
                              .where.not(checkin: nil).first
              return { msg: "already_checked_in_for_this_shift", result: false } if existing

              attend = Attend.new(
                user_id:           user_id,
                checkin:           current_time,
                stype:             'ATTENDANCE',
                status:            'CHECKIN',
                shiftselection_id: shift_id,
                note:              "Nhân viên chấm công vào làm trên B-ERP/Website vào lúc #{current_time.strftime('%H:%M %d/%m/%Y')}"
              )
              ActiveRecord::Base.transaction do
                attend.save!
                Attenddetail.create!(
                  attend_id: attend.id,
                  dtcheckin: current_time,
                  pic:       mediafile[:id],
                  stype:     'CHECKIN'
                )
              end
              return { msg: "save_check_in_successfully", result: true }

            elsif check_type == "checkout"
              # Phải có record checkin trước, chưa có checkout
              att = Attend.where(user_id: user_id, stype: 'ATTENDANCE', shiftselection_id: shift_id)
                          .where.not(checkin: nil)
                          .where(checkout: nil)
                          .order(created_at: :desc)
                          .first
              return { msg: "must_checkin_before_checkout", result: false }        unless att
              return { msg: "already_checked_out_for_this_shift", result: false }  if att.checkout.present?

              att.update!(
                checkout: current_time,
                status:   'CHECKOUT',
                note:     "Nhân viên chấm công tan ca trên B-ERP/Website vào lúc #{current_time.strftime('%H:%M %d/%m/%Y')}"
              )
              Attenddetail.create!(
                attend_id:  att.id,
                dtcheckout: current_time,
                pic:        mediafile[:id],
                stype:      'CHECKOUT'
              )
              return { msg: "save_check_out_successfully", result: true }

            else
              return { msg: "invalid_check_type", result: false }
            end

          else
            # ── Fallback: giữ nguyên logic cũ theo thứ tự ca ──

            shiftIds = Shiftselection
                        .joins(:scheduleweek, :workshift)
                        .where(scheduleweeks: { user_id: user_id, status: 'APPROVED' })
                        .where(is_day_off: nil)
                        .where(work_date: current_time.beginning_of_day..current_time.end_of_day)
                        .pluck(:id, :start_time)
            return { msg: "user_has_no_workshift_today", result: false } if shiftIds.blank?

            shiftIds = shiftIds.sort_by { |(_id, st)| Time.strptime(st, '%H:%M') rescue Time.at(0) }
                              .map(&:first)

            selected = nil
            shiftIds.each do |sid|
              att = Attend.where(user_id: user_id, stype: 'ATTENDANCE', shiftselection_id: sid)
                          .where(checkin: day_start_utc..day_end_utc)
                          .order(created_at: :desc)
                          .first

              if att.nil?
                selected = { shift_id: sid, attend: nil, action: :checkin }
                break
              elsif att.checkout.blank?
                selected = { shift_id: sid, attend: att, action: :checkout }
                break
              end
            end

            return { msg: "already_checked_in_and_out_today", result: false } if selected.nil?

            shift_id = selected[:shift_id]
            oAttend  = selected[:attend]

            if oAttend.nil?
              attend = Attend.new(
                user_id:           user_id,
                checkin:           current_time,
                stype:             'ATTENDANCE',
                status:            'CHECKIN',
                shiftselection_id: shift_id,
                note:              "Nhân viên chấm công vào làm trên B-ERP/Website vào lúc #{current_time.strftime('%H:%M %d/%m/%Y')}"
              )
              ActiveRecord::Base.transaction do
                attend.save!
                Attenddetail.create!(
                  attend_id: attend.id,
                  dtcheckin: current_time,
                  pic:       mediafile[:id],
                  stype:     'CHECKIN'
                )
              end
              return { msg: "save_check_in_successfully", result: true }

            elsif oAttend.checkout.blank?
              oAttend.update!(
                checkout: current_time,
                status:   'CHECKOUT',
                note:     "Nhân viên chấm công tan ca trên B-ERP/Website vào lúc #{current_time.strftime('%H:%M %d/%m/%Y')}"
              )
              Attenddetail.create!(
                attend_id:  oAttend.id,
                dtcheckout: current_time,
                pic:        mediafile[:id],
                stype:      'CHECKOUT'
              )
              return { msg: "save_check_out_successfully", result: true }

            else
              return { msg: "already_checked_in_and_out_today", result: false }
            end
          end

        rescue => e
          return { msg: "Error: #{e.message}", result: false }
        end
      end

      # Kiểm tra điều kiện chấm công của nhân viên
      # @author: Dat Le
      # @date: 01/08/2025
      # @input: user_id, room_id
      # @output: boolean
      desc "Check condition user attendance"
      post :check_condition_user do
        begin
          user_id = params[:user_id]
          scode_campus = params[:scode_campus]
          current_time = Time.zone.now.in_time_zone("Asia/Ho_Chi_Minh")
          user = User.find_by(id: user_id)

          # if integer_string?(scode_campus)
          #   @CSVC_PATH = request.base_url + "/masset/"
          #   response = call_api(@CSVC_PATH + "api/v1/mapi_utils/get_campus_by_room_id?" + "room_id=" + scode_campus.to_s)
          #   scode_campus = response["result"]
          # end

          return  { result: false, msg: 'user_not_found' } unless user
          return  { result: false, msg: 'scode_campus_missing' } if scode_campus.blank?

          # Kiểm tra miễn chấm công theo User.ignore_attend
          user_exempt = User.where(id: user_id, ignore_attend: "TRUE").exists?
          if user_exempt
            return { msg: "user_is_exempted_from_attendance_check", result: false }
          end

          # Kiểm tra danh sách nhân viên được miễn chấm công
          exempt_position_scodes = Positionjob.where(ignore_attend: "TRUE").pluck(:scode)
          exempted = if exempt_position_scodes.present?
                       Work.joins(:positionjob)
                           .where(user_id: user_id)
                           .where.not(positionjob_id: nil)
                           .where(
                             Array.new(exempt_position_scodes.size, "positionjobs.scode LIKE ?").join(" OR "),
                             *exempt_position_scodes.map { |p| "#{p}%" }
                           )
                           .exists?
                     else
                       false
                     end

          if exempted
            return { msg: "user_is_exempted_from_attendance_check.", result: false }
          end

          # Kiểm tra lịch làm việc
          shiftId = Shiftselection
                      .joins(:scheduleweek, :workshift)
                      .where(scheduleweeks: { user_id: user_id, status: 'APPROVED' })
                      .where(is_day_off: nil)
                      .where(work_date: current_time.beginning_of_day..current_time.end_of_day)
                      .pluck(:id, :start_time)
          return { msg: "user_has_no_workshift_today", result: false } unless shiftId.present?

          shiftId = shiftId.sort_by { |(_id, st)| Time.strptime(st, '%H:%M') rescue Time.at(0) }
                           .map(&:first)

          # Đếm số lần đã chấm công trong ngày
          count_checkin  = Attend.where(user_id: user_id, stype: 'ATTENDANCE').where(shiftselection_id: shiftId).where.not(checkin: nil).count
          count_checkout = Attend.where(user_id: user_id, stype: 'ATTENDANCE').where(shiftselection_id: shiftId).where.not(checkout: nil).count
          attempt = count_checkin + count_checkout
          current_shift_index = attempt / 2
          current_shift_id = shiftId[current_shift_index]

          return({ msg: "already_checked_in_and_out_today", result: false }) if current_shift_index >= 2

          sel = Shiftselection.select(:id, :is_day_off, :location, :work_date, :start_time, :end_time).find_by(id: current_shift_id)
          is_off = sel&.is_day_off.to_s.upcase

          # Kiểm tra ca làm việc
          return { msg: "user_has_no_workshift_today", result: false } if is_off == 'OFF'
          # Kiểm tra ngày lễ
          return { msg: "today_is_a_holiday", result: false }          if is_off == 'HOLIDAY'
          # Kiểm tra nghỉ phép
          return { msg: "user_is_off_today", result: false }           if is_off == 'ON-LEAVE'


          # Kiểm tra địa điểm làm việc
          if scode_campus.present? && sel&.location.present? && !sel.location.to_s.split("$$$").include?(scode_campus)
            return { msg: "work_location_does_not_match_plan", result: false }
          end

          # Kiểm tra đi công tác
          approved_worktrip_count = Shiftissue
                                      .where(shiftselection_id: shiftId, stype: 'WORK-TRIP', status: 'APPROVED')
                                      .distinct
                                      .count(:shiftselection_id)
          if approved_worktrip_count == shiftId.size
            return { msg: "user_has_worktrip_today", result: false }
          end

          return { msg: "eligible", result: true }
        rescue => e
          return {
            msg: "Error: #{e}",
            result: false,
          }
        end
      end

      desc "Check condition user attendance"
      post :check_condition_user_v2 do
        begin
          user_id          = params[:user_id]
          scode_campus     = params[:scode_campus]
          shiftselection_id = params[:shiftselection_id]
          check_type       = params[:check_type]  # "checkin" hoặc "checkout"
          current_time     = Time.zone.now.in_time_zone("Asia/Ho_Chi_Minh")
          user             = User.find_by(id: user_id)

          return { result: false, msg: 'user_not_found' }       unless user
          return { result: false, msg: 'scode_campus_missing' } if scode_campus.blank?

          # Kiểm tra miễn chấm công theo User.ignore_attend
          user_exempt = User.where(id: user_id, ignore_attend: "TRUE").exists?
          return { msg: "user_is_exempted_from_attendance_check", result: false } if user_exempt

          # Kiểm tra danh sách nhân viên được miễn chấm công theo vị trí
          exempt_position_scodes = Positionjob.where(ignore_attend: "TRUE").pluck(:scode)
          exempted = if exempt_position_scodes.present?
                      Work.joins(:positionjob)
                          .where(user_id: user_id)
                          .where.not(positionjob_id: nil)
                          .where(
                            Array.new(exempt_position_scodes.size, "positionjobs.scode LIKE ?").join(" OR "),
                            *exempt_position_scodes.map { |p| "#{p}%" }
                          )
                          .exists?
                    else
                      false
                    end
          return { msg: "user_is_exempted_from_attendance_check.", result: false } if exempted

          # ── Tìm ca theo shiftselection_id (nếu mobile truyền lên) hoặc fallback theo giờ ──
          if shiftselection_id.present?
            # Validate ca này thuộc về user và hôm nay
            sel = Shiftselection
                    .joins(:scheduleweek)
                    .select(:id, :is_day_off, :location, :work_date, :start_time, :end_time)
                    .find_by(
                      id:            shiftselection_id,
                      scheduleweeks: { user_id: user_id, status: 'APPROVED' },
                      work_date:     current_time.beginning_of_day..current_time.end_of_day
                    )

            return { msg: "user_has_no_workshift_today", result: false } unless sel

            current_shift_id = sel.id

            # Kiểm tra đã chấm đúng loại chưa
            if check_type == "checkin"
              already_done = Attend.where(user_id: user_id, stype: 'ATTENDANCE',
                                          shiftselection_id: current_shift_id)
                                  .where.not(checkin: nil).exists?
              return { msg: "already_checked_in_for_this_shift", result: false } if already_done
            elsif check_type == "checkout"
              # Phải checkin trước mới được checkout
              checked_in = Attend.where(user_id: user_id, stype: 'ATTENDANCE',
                                        shiftselection_id: current_shift_id)
                                .where.not(checkin: nil).exists?
              return { msg: "must_checkin_before_checkout", result: false } unless checked_in

              already_done = Attend.where(user_id: user_id, stype: 'ATTENDANCE',
                                          shiftselection_id: current_shift_id)
                                  .where.not(checkout: nil).exists?
              return { msg: "already_checked_out_for_this_shift", result: false } if already_done
            end

          else
            # ── Fallback: giữ nguyên logic cũ tìm theo khung giờ ──
            shiftIds = Shiftselection
                        .joins(:scheduleweek, :workshift)
                        .where(scheduleweeks: { user_id: user_id, status: 'APPROVED' })
                        .where(is_day_off: nil)
                        .where(work_date: current_time.beginning_of_day..current_time.end_of_day)
                        .pluck(:id, :start_time)
            return { msg: "user_has_no_workshift_today", result: false } unless shiftIds.present?

            shiftIds = shiftIds.sort_by { |(_id, st)| Time.strptime(st, '%H:%M') rescue Time.at(0) }
                              .map(&:first)

            count_checkin  = Attend.where(user_id: user_id, stype: 'ATTENDANCE',
                                          shiftselection_id: shiftIds).where.not(checkin: nil).count
            count_checkout = Attend.where(user_id: user_id, stype: 'ATTENDANCE',
                                          shiftselection_id: shiftIds).where.not(checkout: nil).count
            current_shift_index = (count_checkin + count_checkout) / 2
            return { msg: "already_checked_in_and_out_today", result: false } if current_shift_index >= 2

            current_shift_id = shiftIds[current_shift_index]

            sel = Shiftselection.select(:id, :is_day_off, :location, :work_date, :start_time, :end_time)
                                .find_by(id: current_shift_id)
          end

          # ── Các validation chung cho cả 2 nhánh ──
          is_off = sel&.is_day_off.to_s.upcase
          return { msg: "user_has_no_workshift_today", result: false } if is_off == 'OFF'
          return { msg: "today_is_a_holiday",          result: false } if is_off == 'HOLIDAY'
          return { msg: "user_is_off_today",           result: false } if is_off == 'ON-LEAVE'

          # Kiểm tra địa điểm làm việc
          if scode_campus.present? && sel&.location.present? &&
            !sel.location.to_s.split("$$$").include?(scode_campus)
            return { msg: "work_location_does_not_match_plan", result: false }
          end

          # Kiểm tra đi công tác
          all_shift_ids = shiftselection_id.present? ? [current_shift_id] : shiftIds
          approved_worktrip_count = Shiftissue
                                      .where(shiftselection_id: all_shift_ids,
                                            stype: 'WORK-TRIP', status: 'APPROVED')
                                      .distinct.count(:shiftselection_id)
          return { msg: "user_has_worktrip_today", result: false } if approved_worktrip_count == all_shift_ids.size

          return { msg: "eligible", result: true }
        rescue => e
          return { msg: "Error: #{e}", result: false }
        end
      end
      # danh sách nhân sự đang nghỉ Dashboard
      # @author: H.Anh
      # @date: 11/07/2025
      # @input: user_id, page, search
      # @output: list
      #
      desc "List of employees currently on leave"
      params do
        requires :user_id, type: String, desc: "User ID"
        optional :search, type: String, desc: "User SID or User Name"
        optional :user_leave, type: String, desc: "Leadership"
        optional :date, type: Date, desc: "Filter by specific date"
        optional :page, type: Integer, default: 20, desc: "Number of records per group"
      end
      # get :list_leave do
      #   user = User.find_by(id: params[:user_id])
      #   error!({ message: "User not found" }, 404) unless user

      #   # --- Xác định scope phòng ban ---
      #   uorgs = user.uorgs
      #   if uorgs.size > 1
      #     organization_id = Organization.find_by(scode: "BMTU")&.id || Organization.find_by(scode: "BMU")&.id
      #     uorg_scode = "BMU"
      #   else
      #     organization_id = uorgs.first&.organization&.id
      #     uorg_scode = "BUH"
      #   end

      #   departments = case uorg_scode
      #     when "BUH"
      #       Department.where(organization_id: Organization.where(scode: "BUH")).where.not(name: "Quản lý ERP")
      #     when "BMU"
      #       Department.where(organization_id: Organization.where(scode: ["BMU", "BMTU"])).where.not(name: "Quản lý ERP")
      #   end

      #   department_user = fetch_leaf_departments_by_user(params[:user_id])
      #   department = department_user.first
      #   department_id = department&.id
      #   check_faculty = department&.faculty
      #   all_department_ids = fetch_all_sub_department_ids([department_id])

      #   if (uorg_scode == "BUH" && ["PTCHC(BUH)", "BGD(BUH)"].include?(check_faculty)) || uorg_scode == "BMU"
      #     department_ids    = Department.where(organization_id: organization_id).pluck(:id)
      #     child_departments = Department.where(parents: department_ids).pluck(:id)
      #     all_departments   = department_ids + child_departments
      #     list_user_ids     = Work.where(positionjob_id: Positionjob.where(department_id: all_departments)).pluck(:user_id).uniq
      #   else
      #     list_user_ids     = Work.where(positionjob_id: Positionjob.where(department_id: all_department_ids).pluck(:id)).pluck(:user_id)
      #   end

      #   leadership_keywords = /trưởng|phó|giám đốc|hiệu|phụ trách khoa nội tim mạch|cố vấn chuyên môn/i

      #   all_data = list_user_ids.flat_map do |uid|
      #     full_name, sid, phone = get_user_info_leave(uid)
      #     positionjob_name, department_name, check_pros = fetch_position_and_department_name(uid)
      #     if check_pros == true
      #       pos_name = positionjob_name.to_s.downcase.match?(leadership_keywords) ? "Lãnh đạo" : "Nhân viên"
      #     else
      #       pos_name = "Nhân viên"
      #     end

      #     oHol = Holiday.find_by(user_id: uid, year: Time.current.year)
      #     next [] unless oHol

      #     hols = Holpro.where(holiday_id: oHol.id, status: ["DONE", "CANCEL-DONE"]).where.not(status: "TEMP")
      #     details = Holprosdetail.where(holpros_id: hols.pluck(:id))

      #     next [] if details.blank?

      #     # gom theo hình thức nghỉ
      #     grouped_leave = details.group_by(&:sholtype).map do |stype, dts|
      #       {
      #         leave_type: stype,
      #         total_days: dts.sum { |d| d.itotal.to_f }, # giả sử tvalue lưu số ngày
      #         dates: dts.map(&:details)
      #       }
      #     end

      #     # nếu có param :date thì chỉ lấy record có ngày đó
      #     # --- xử lý lọc theo ngày ---
      #     if params[:date].present?
      #       from_date = to_date = params[:date].to_date
      #     else
      #       from_date = Date.current
      #       to_date   = from_date.next_month
      #     end
      #     grouped_leave.select! do |grp|
      #       grp[:dates].any? do |ds|
      #         extract_dates_from_details_date_range(ds).any? { |d| d.between?(from_date, to_date) }
      #       end
      #     end
      #     next [] if grouped_leave.empty?


      #     {
      #       user_id: uid,
      #       sender: full_name,
      #       sender_sid: sid,
      #       phone: phone,
      #       department: department_name,
      #       positionjob: positionjob_name,
      #       pos_name: pos_name,
      #       leaves: grouped_leave
      #     }
      #   end.compact
      #   # --- lọc theo search ---
      #   if params[:search].present?
      #     keyword = params[:search].strip.downcase
      #     all_data.select! do |record|
      #       record[:sender].to_s.downcase.include?(keyword) ||
      #       record[:sender_sid].to_s.downcase.include?(keyword)
      #     end
      #   end

      #   # --- lọc theo lãnh đạo/nhân viên ---
      #   if params[:user_leave].present?
      #     all_data.select! do |r|
      #       if params[:user_leave] == 'LANH-DAO'
      #         r[:pos_name] == "Lãnh đạo"
      #       elsif params[:user_leave] == 'NHAN-VIEN'
      #         r[:pos_name] == "Nhân viên"
      #       else
      #         true
      #       end
      #     end
      #   end


      #   page = params[:page].to_i > 0 ? params[:page].to_i : 20

      #   leaders = all_data.select { |r| r[:pos_name].match?(leadership_keywords) }
      #                     .uniq { |r| r[:user_id] }
      #                     .first(page)

      #   staffs  = all_data.reject { |r| r[:pos_name].match?(leadership_keywords) }
      #                     .uniq { |r| r[:user_id] }
      #                     .first(page)

      #   {
      #     leaders: leaders,
      #     staffs: staffs,
      #     total_leaders: leaders.size,
      #     total_staffs: staffs.size
      #   }
      # end
      get :list_leave do
        user = User.find_by(id: params[:user_id])
        error!({ message: "User not found" }, 404) unless user

        # --- Xác định scope phòng ban ---
        uorgs = user.uorgs
        if uorgs.size > 1
          organization_id = Organization.find_by(scode: "BMTU")&.id || Organization.find_by(scode: "BMU")&.id
          uorg_scode = "BMU"
        else
          organization_id = uorgs.first&.organization&.id
          code_org = Organization.find_by(id: organization_id)
          if code_org == "BMTU" || code_org == "BMU"
            uorg_scode = "BMU"
          else
            uorg_scode = "BUH"
          end
        end

        departments = case uorg_scode
        when "BUH"
          Department.where(organization_id: Organization.where(scode: "BUH")).where.not(name: "Quản lý ERP")
        when "BMU"
          Department.where(organization_id: Organization.where(scode: ["BMU", "BMTU"])).where.not(name: "Quản lý ERP")
        end

        department_user = fetch_leaf_departments_by_user(params[:user_id])
        department = department_user.first
        department_id = department&.id
        check_faculty = department&.faculty
        all_department_ids = fetch_all_sub_department_ids([department_id])
        check_view = Work.joins(stask: { accesses: :resource })
                                    .where(
                                      resources: { scode: "VIEW-ALL-REQUEST" },
                                      works:     { user_id: params[:user_id] },
                                      accesses:  { permision: "ADM" }
                                    )
                                    .exists?
        if (uorg_scode == "BUH" && ["PTCHC(BUH)", "BGD(BUH)"].include?(check_faculty)) || check_view
          department_ids    = Department.where(organization_id: organization_id).pluck(:id)
          child_departments = Department.where(parents: department_ids).pluck(:id)
          all_departments   = department_ids + child_departments
          list_user_ids     = Work.where(positionjob_id: Positionjob.where(department_id: all_departments)).pluck(:user_id).uniq
        else
          list_user_ids     = Work.where(positionjob_id: Positionjob.where(department_id: all_department_ids).pluck(:id)).pluck(:user_id)
        end

        leadership_keywords = /trưởng|phó|giám đốc|hiệu|phụ trách khoa nội tim mạch|cố vấn chuyên môn/i
        # --- xác định khoảng ngày lọc ---
        if params[:date].present?
          from_date = to_date = params[:date].to_date
        else
          from_date = Date.current
          to_date   = from_date.next_month
        end

        all_data = list_user_ids.flat_map do |uid|
          full_name, sid, phone = get_user_info_leave(uid)
          positionjob_name, department_name, check_pros = fetch_position_and_department_name(uid)
          if check_pros == true
            pos_name = "Lãnh đạo"
            rule_user = "Lãnh đạo"
          else
            pos_name = "Nhân viên"
            rule_user = "Nhân viên"
          end

          oHol = Holiday.find_by(user_id: uid, year: Time.current.year)
          next [] unless oHol

          hols = Holpro.where(holiday_id: oHol.id, status: ["DONE", "CANCEL-DONE"]).where.not(status: "TEMP")
          details = Holprosdetail.where(holpros_id: hols.pluck(:id))
          next [] if details.blank?

          # --- gom theo hình thức nghỉ và lọc theo khoảng ---
          grouped_leave = details.group_by(&:sholtype).map do |stype, dts_for_type|
            hd_entries = dts_for_type.map do |hd|
              entries = parse_detail_entries(hd.details)
              entries_in_range = entries.select { |e| e[:date].between?(from_date, to_date) }
              next nil if entries_in_range.empty?

              dates_string = entries_in_range.map { |e| "#{e[:date].strftime('%d/%m/%Y')}-#{e[:session]}" }.join('$$$')
              total_in_range = entries_in_range.sum { |e| e[:fraction] }

              { dates_string: dates_string, total: total_in_range }
            end.compact

            next nil if hd_entries.empty?

            {
              leave_type: stype,
              total_days: hd_entries.sum { |h| h[:total] },
              dates: hd_entries.map { |h| h[:dates_string] }
            }
          end.compact

          next [] if grouped_leave.empty?

          {
            user_id: uid,
            sender: full_name,
            sender_sid: sid,
            phone: phone,
            department: department_name,
            positionjob: positionjob_name,
            pos_name: pos_name,
            leaves: grouped_leave
          }
        end.compact

        # --- lọc theo search ---
        if params[:search].present?
          keyword = params[:search].strip.downcase
          all_data.select! do |record|
            record[:sender].to_s.downcase.include?(keyword) ||
            record[:sender_sid].to_s.downcase.include?(keyword)
          end
        end

        # --- lọc theo lãnh đạo/nhân viên ---
        if params[:user_leave].present?
          all_data.select! do |r|
            if params[:user_leave] == 'LANH-DAO'
              r[:pos_name] == "Lãnh đạo"
            elsif params[:user_leave] == 'NHAN-VIEN'
              r[:pos_name] == "Nhân viên"
            else
              true
            end
          end
        end

        page = params[:page].to_i > 0 ? params[:page].to_i : 20


        staffs = all_data.select { |r| ["Nhân viên", "Lãnh đạo"].include?(r[:pos_name]) }
                 .uniq { |r| r[:user_id] }
                 .first(page)
        leaders = []
        {
          leaders: leaders,
          staffs: staffs,
          total_leaders: leaders.size,
          total_staffs: staffs.size
        }
      end
      # --- helper parse details ---
      helpers do
        def parse_detail_entries(detail_string)
          return [] if detail_string.blank?
          detail_string.to_s.split('$$$').map do |part|
            next if part.blank?
            date_part, session = part.split('-', 2).map(&:to_s)
            session = session.to_s.strip.upcase.presence || "ALL"
            begin
              date = Date.strptime(date_part.strip, '%d/%m/%Y')
            rescue ArgumentError
              found = part.scan(/\d{2}\/\d{2}\/\d{4}/).first
              next unless found
              begin
                date = Date.strptime(found, '%d/%m/%Y')
              rescue
                next
              end
            end
            fraction = (session == "AM" || session == "PM") ? 0.5 : 1.0
            { date: date, session: session, fraction: fraction }
          end.compact
        end
      end

      # Tạo thông báo cho phòng CTSV
      # @author: Hoang Dat
      # @date: 08/07/2025
      # @input: user_email, title,contents,receivers,senders
      # @output: msg
      desc "Send notify for stdstate"
      params do
        requires :title, type: String
        requires :contents, type: String
        requires :receivers, type: String
        requires :user_email, type: String
        requires :senders, type: String
      end
      post :create_notify_for_std_erp do
        msg = "Not Success"
        eresult = false
        snotice = ""
        oUser = User.where(email: params[:user_email]&.strip).first
        begin
          if  params[:title].present? && params[:contents].present? && !oUser.nil?
            newNotify = Notify.create({
              title: params[:title],
              contents: params[:contents],
              receivers: params[:receivers],
              senders: params[:senders],
            })
            if newNotify.present?
                msg = "Success"
                eresult = true
                snotice = Snotice.create({
                  notify_id: newNotify.id,
                  user_id: oUser.id,
                  isread: false
                })
            end
            return {
              msg: msg,
              result: eresult,
            }
          else
            return {
              msg: "Thiếu thông tin cần thiết",
              result: false,
            }
          end
        rescue => e
          return {
            "msg" => "Error: #{e}",
            result: false,
          }
        end
      end

      ## Lưu lịch làm việc
      # Dat Le
      # 28/07/2025
      helpers do
        include AttendConcern
      end
      desc 'Lưu ca làm việc (shift selection)'
      params do
        optional :user_id, type: Integer, desc: 'ID người dùng (nếu không có thì lấy từ session)'
        requires :data, type: String, desc: 'Chuỗi dữ liệu đăng ký ca'
        requires :approved_id, type: Integer, desc: 'ID người duyệt'
      end

      post :save_shift_selection do
        user_id     = params[:user_id]
        data        = params[:data]
        approved_id = params[:approved_id] || nil

        return { msg: 'missing_params', result: false } if data.blank? || user_id.blank?

        raw_data = JSON.parse(data, symbolize_names: true)
        # ----- transaction -----
        ActiveRecord::Base.transaction do
          raw_data.each do |item|
            start_date = Date.parse(item[:start_date])
            end_date   = Date.parse(item[:end_date])
            week_num   = start_date.cweek
            week_year  = start_date.cwyear

            # kiểm tra trùng tuần PENDING/APPROVED
            if %w[PENDING APPROVED].include?(item[:current_status].to_s.upcase)
              msgs = item[:status].upcase == 'APPROVED' ?
                       "week_has_been_approved" :
                       "week_is_being_approving"
              return { msg: msgs, result: false }
            end

            # tạo hoặc cập-nhật scheduleweek
            sw =
              if item[:id].present?
                Scheduleweek.find_by!(id: item[:id], user_id: user_id)
              else
                existing = Scheduleweek
                             .where(user_id: user_id, year: week_year, week_num: week_num)
                             .order(created_at: :desc)
                             .first
                if existing
                  if %w[PENDING APPROVED].include?(existing.status.to_s.upcase)
                    msgs = existing.status.to_s.upcase == 'APPROVED' ?
                             "week_has_been_approved" :
                             "week_is_being_approving"
                    return { msg: msgs, result: false }
                  end
                  existing
                else
                  Scheduleweek.new(user_id: user_id)
                end
              end

            sw.update!(
              week_num:   week_num,
              year:       week_year,
              start_date: start_date,
              end_date:   end_date,
              status:     item[:status],
              time_required: item[:time_required],
              time_register: item[:time_register],
              checked_by: approved_id
            )

            # reset & ghi shiftselections  (association số nhiều!)
            # map lại shiftselections cũ
            old_shiftselections = sw.shiftselection.includes(:shiftissue).to_a
            old_map = {}
            old_shiftselections.each do |ss|
              key = [ss.work_date, ss.workshift_id]
              old_map[key] ||= { ss_id: ss.id, issue_ids: [], attend_id: nil }
              # shiftissues
              if ss.respond_to?(:shiftissue) && ss.shiftissue.loaded?
                old_map[key][:issue_ids].concat(ss.shiftissue.map(&:id))
              else
                old_map[key][:issue_ids].concat(ss.shiftissue.pluck(:id)) if ss.respond_to?(:shiftissue)
              end
              # attend
              if ss.respond_to?(:attend) && ss.attend.present?
                old_map[key][:attend_id] = ss.attend.id
              end
            end

            # Tạo mới shiftselection
            new_map = {}
            item[:shift_details].each do |d|
              new_ss = sw.shiftselection.create!(
                workshift_id: workshift_code_map[d[:workshift_id]],
                work_date:    Date.parse(d[:work_date]),
                location:     d[:location],
                start_time:   d[:start_time],
                end_time:     d[:end_time],
                is_day_off:   d[:is_day_off],
                )
              key = [new_ss.work_date, new_ss.workshift_id]
              new_map[key] = new_ss
            end

            # Gán lại shiftissue và attend cũ
            old_map.each do |key, info|
              new_ss = new_map[key]
              next unless new_ss
              # Gán lại shiftissue cũ
              if info[:issue_ids].present?
                Shiftissue.where(id: info[:issue_ids]).update_all(shiftselection_id: new_ss.id)
              end

              # Gán lại attend cũ
              if info[:attend_id].present?
                Attend.where(id: info[:attend_id]).update_all(shiftselection_id: new_ss.id)
              end

            end

            # Xoá các shiftselection cũ
            old_ids = old_shiftselections.map(&:id)
            sw.shiftselection.where(id: old_ids).delete_all

            # send notify
            if (item[:status] == "PENDING")
              current_user = User.find(user_id)
              user_name = "#{current_user.last_name} #{current_user.first_name} (#{current_user.sid})"
              start_date_format = Time.zone.parse(item[:start_date]).strftime("%d/%m/%Y")
              end_date_format = Time.zone.parse(item[:end_date]).strftime("%d/%m/%Y")
              notify = Notify.create(
                title: "Thông báo gửi kế hoạch làm việc",
                contents: "Nhân viên <strong>#{user_name}</strong> đã gửi kế hoạch làm việc <strong>tuần #{week_num} (#{start_date_format} - #{end_date_format})</strong>.<br>",
                receivers: "Hệ thống ERP",
                senders: user_name,
                stype: "SCHEDULEWEEK",
                )
              Snotice.create(
                notify_id: notify.id,
                user_id: approved_id,
                isread: false,
                username: nil
              )
            end
          end
        rescue ActiveRecord::Rollback => e
          return { msg: e.message, result: false }   # rollback có thông báo tuỳ chỉnh
        end

        { msg: 'success', result: true }
      rescue StandardError => e
        Rails.logger.error e
        error!({ msg: "server_error", result: e.message }, 500)
      end

      ### trọnglq
      helpers do
        def session
          env['rack.session']
        end
      end

      helpers do
        def fail!(message, code = 400)
          error!({ result: [], msg: message }, code)
        end
      end

      get :managers do
        begin
          {
            msg: "success",
            result: get_managers(user_id: params[:user_id])
          }
        rescue => e
          {
            msg: e.message,
            result: []
          }
        end
      end

      desc 'Lấy Ca làm việc'
      get :get_all_workshifts do
        begin
          data = Workshift.all.map do |item|
            {
              id: item.id,
              label: item.name,
              code: slugify(item.name),
              start: item.checkin_start,
              end: item.checkout_end,
              min: item.start_time,
              max: item.end_time
            }
          end

          return {
            msg: 'success',
            result: data
          }
        rescue => e
          {
            msg: e.message,
            result: []
          }
        end
      end

      # Get shiftissue by user_id
      # @author: Dat Le
      # @date: 08/08/2025
      # @input: user_id
      # @output: json
      desc "Get shiftissue by user_id"
      get :get_shiftissue_by_user_id do
        begin
          user_id = params[:user_id]
          return { msg: 'user_id_missing', result: [] } if user_id.blank?

          issues = Shiftissue.where(status: "PENDING", approved_by: user_id)
                             .order(created_at: :desc)

          # helpers
          format_date = ->(date_string) do
            s = date_string.to_s.strip
            return s if s.match?(/^\d{4}-\d{2}-\d{2}$/)
            if s.match?(/^\d{2}\/\d{2}\/\d{4}$/)
              dd, mm, yyyy = s.split('/'); "#{yyyy}-#{mm}-#{dd}"
            else
              Date.parse(s).strftime('%Y-%m-%d') rescue s
            end
          end
          created_key = ->(obj) { obj.created_at.in_time_zone('Asia/Ho_Chi_Minh').strftime('%Y-%m-%d %H:%M') }

          # Xác định AM/PM/ALL theo thời gian ca
          shift_code = ->(sel) do
            ws_name = sel[:workshift].to_s.downcase
            st = sel[:start_time].to_s
            en = sel[:end_time].to_s
            # Ưu tiên theo tên ca nếu có
            return "AM"  if ws_name.include?("sáng")
            return "PM"  if ws_name.include?("chiều")
            return "ALL" if ws_name.include?("cả ngày") || ws_name.include?("full")

            # Fallback theo giờ
            begin
              s_h = st.split(':')[0].to_i
              e_h = en.split(':')[0].to_i
              return "ALL" if s_h <= 8 && e_h >= 17
              return "AM"  if e_h <= 12
              return "PM"  if s_h >= 12
              "ALL"
            rescue
              "ALL"
            end
          end

          vn_date = ->(any_date) do
            begin
              Date.parse(format_date.call(any_date)).strftime('%d/%m/%Y')
            rescue
              any_date.to_s
            end
          end

          vn_shift_label = ->(code) do
            case code
            when "AM"  then "Ca sáng"
            when "PM"  then "Ca chiều"
            else            "Cả ngày"
            end
          end

          build_issue_hash = ->(item, sel) do
            current_workshift = item.stype == "EDIT-PLAN" ? nil : "#{sel[:workshift]} #{sel[:start_time]} - #{sel[:end_time]}"
            approver = if (user = User.find_by(id: user_id))
                         "#{user.last_name} #{user.first_name} (#{user.sid})"
                       else
                         ""
                       end
            img = Mediafile.where(id: item.docs, status: "ACTIVE").pluck(:file_name).first
            image_url = img.present? ? "#{request.base_url}/mdata/hrm/#{img}" : nil

            to_workshift = to_date = to_user = nil
            if item.ref_shift_changed.present?
              shift_changed = get_shiftselection_by_id(item.ref_shift_changed)
              to_workshift = "#{shift_changed[:workshift]} #{shift_changed[:start_time]} - #{shift_changed[:end_time]}"
              to_date      = shift_changed[:work_date]
              to_user      = shift_changed[:user_name]
            end

            {
              id:                item.id,
              shiftselection_id: item.shiftselection_id,
              stype:             item.stype,
              name:              item.name,
              status:            item.status,
              content:           item.stype == "EDIT-PLAN" ? item.content.gsub("Tuần ", "").to_s : nil,
              approved_by:       approver,
              sender:            sel[:user_name],
              time_ago:          time_ago_in_words(item.created_at.in_time_zone('Asia/Ho_Chi_Minh')),
              created_at:        item.created_at.strftime("%d/%m/%Y - %H:%M"),
              us_start:          item.us_start,
              us_end:            item.us_end,
              reason:            item.note,
              current_workshift: current_workshift,
              current_day:       sel[:work_date],
              ref_shift_changed: item.ref_shift_changed,
              docs:              image_url,
              to_user:           to_user,
              to_date:           to_date,
              to_workshift:      to_workshift
            }
          end

          # tách nhóm
          work_trip, others = issues.partition { |item| item.stype.to_s.upcase == 'WORK-TRIP' }

          # render non WORK-TRIP
          result = others.map do |item|
            shiftselection = get_shiftselection_by_id(item.shiftselection_id)
            build_issue_hash.call(item, shiftselection)
          end

          # group WORK-TRIP theo created_at
          work_trip.group_by { |item| created_key.call(item) }.each_value do |group|
            # gom dữ liệu (id, work_date_iso) để sort theo work_date
            tuples = group.map do |it|
              shiftselection = get_shiftselection_by_id(it.shiftselection_id)
              [it, shiftselection, format_date.call(shiftselection[:work_date])]
            end

            tuples.sort_by! { |(_it, _sel, d)| d.to_s } # sort theo work_date

            if tuples.size == 1
              it, sel, _ = tuples.first
              result << build_issue_hash.call(it, sel)
            else
              # đại diện lấy bản ghi đầu nhóm (sau sort theo work_date)
              first_item, first_sel, _ = tuples.first
              base = build_issue_hash.call(first_item, first_sel)

              base[:data_shiftissue_ids]   = tuples.map { |(it, _sel, _)| it.id }
              base[:data_shiftselection_ids] = tuples.map { |(it, _sel, _)| it.shiftselection_id }
              base[:data_worktrip_dates] = tuples.map { |(_it, _sel, d)| d }

              per_date_codes = Hash.new { |h, k| h[k] = [] }
              tuples.each do |_it, sel, d|
                code = shift_code.call(sel) # AM/PM/ALL
                per_date_codes[d] << code
              end

              # kết quả hiển thị
              base[:data_worktrip_shiftselection] =
                per_date_codes
                  .map do |d, codes|
                  final_code = (codes.include?("ALL") || codes.uniq.size > 1) ? "ALL" : codes.uniq.first
                  "#{vn_date.call(d)}: #{vn_shift_label.call(final_code)}"
                end
                  .sort

              result << base
            end
          end

          { msg: "success", result: result, count: result.count}
        rescue => e
          { msg: e.message, result: [] }
        end
      end

      # Get scheduleweek list
      # @author: Hoang vu
      # @date: 07/08/2025
      # @input: status,data
      # @output: json
      desc "Get schedule week list by checked user"
      get :get_checked_scheduleweeks do
        user_id = params[:user_id]
        week_num = params[:week_num]
        year = params[:year]
        page = [params[:page].to_i, 1].max
        per_page = 5
        offset = (page - 1) * per_page
        begin

          sql = Scheduleweek.where(week_num: week_num)
                        .joins(:user)
                        .includes(:shiftselection)
                        .where("scheduleweeks.checked_by = ?",user_id)
                        .where("scheduleweeks.status = ?","PENDING")
          total_page =  sql.count
          scheduleweeks = sql.order(start_date: :ASC)
                            .limit(per_page)
                            .offset(offset)

          result = scheduleweeks.map do |scheduleweek|
            uniq_check = []
            {
              id: scheduleweek.user.id,
              full_name: "#{scheduleweek.user.last_name} #{scheduleweek.user.first_name}",
              sent_at: time_ago_in_words(scheduleweek.updated_at),
              weeks: {
                id: scheduleweek.id,
                week_num: scheduleweek.week_num,
                time_required: scheduleweek.time_required || "",
                time_register: scheduleweek.time_register || "",
                date_week: "#{scheduleweek.start_date.strftime("%d/%m/%Y")} - #{scheduleweek.end_date.strftime("%d/%m/%Y")}",
                shift_details: scheduleweek.shiftselection.order(:work_date).map do |shiftselection|
                  if shiftselection.start_time
                    time = Time.parse(shiftselection.start_time)
                    period = if time < Time.parse("12:00")
                               ["ca-sang","Ca sáng"]
                             elsif time < Time.parse("17:01")
                               ["ca-chieu", "Ca chiều"]
                             else
                               ["ca-khac", "Ca khác"]
                             end
                  else
                    if !uniq_check.include?(shiftselection.work_date)
                      uniq_check << shiftselection.work_date
                      period = ["ca-sang","Ca sáng"]
                    else
                      period = ["ca-chieu", "Ca chiều"]
                    end
                  end
                  {
                    workshift_id: period[0],
                    workshift_name: period[1],
                    work_date:shiftselection.work_date,
                    start_time:shiftselection.start_time,
                    end_time:shiftselection.end_time,
                    is_day_off:shiftselection.is_day_off,
                    location:shiftselection.location
                  }
                end
              }
            }
          end

          {
            msg: "success",
            result: result,
            total_page: total_page,
            page: page
          }
        rescue => e
          {
            msg: e.message,
            result: []
          }
        end
      end

      REQUEST_TYPE_NAMES = {
        "EARLY-CHECK-OUT" => "Về sớm",
        "LATE-CHECK-IN" => "Đi trễ",
        "SHIFT-CHANGE" => "Đổi ca",
        "SHIFT-CHANGE-APPROVED" => "Bị đổi ca",
        "ADDITIONAL-CHECK-OUT" => "Chấm công tan làm bù",
        "ADDITIONAL-CHECK-IN" => "Chấm công vào làm bù",
        "UPDATE-SHIFT" => "Cập nhật ca",
        "WORK-TRIP" => "Công tác",
        "EDIT-PLAN" => "Chỉnh sửa kế hoạch làm việc",
        "COMPENSATORY-LEAVE" => "Nghỉ bù"
      }.freeze

      # Tạo đề xuất đi trễ / về sớm
      resource :attends do
        desc 'Lưu đề xuất đi trễ / về sớm, kèm ảnh (lưu vào docs của shiftissue)'
        params do
          requires :user_id, type: String, desc: 'userID'
          requires :original_date, type: String, desc: 'Ngày làm việc (YYYY-MM-DD)'
          requires :request_type, type: String, values: ['early-check-out', 'late-check-in'], desc: 'Loại đề xuất'
          requires :workshift_id, type: Integer, desc: 'ID ca làm việc'
          requires :approved_id, type: Integer, desc: 'ID người duyệt'
          requires :time, type: String, desc: 'Thời gian đề xuất (HH:MM)'
          optional :reason, type: String, desc: 'Lý do đề xuất'
        end
        post :save_attend_request_early_late do
          begin
            user_id = params[:user_id]
            return { msg: 'Không xác định người dùng' } unless user_id

            date = Date.parse(params[:original_date]) rescue nil
            return { msg: 'Ngày không hợp lệ' } unless date

            request_type = params[:request_type]
            workshift_id = params[:workshift_id]
            time_str = params[:time]
            approver_id = params[:approved_id]
            reason = params[:reason]
            file = params[:file]
            validation = validate_attend_request_conditions(user_id, date, workshift_id, request_type)
            fail!(validation, 422) unless validation == true
            # Upload ảnh (nếu có)
            docs = nil
            if file
              uploaded = upload_file(file)
              return { error: 'Tải file thất bại' } unless uploaded[:id]
              docs = uploaded[:id].to_s
            end

            # Tìm ca làm việc
            shift = find_shift(user_id, date, workshift_id)
            return { error: 'Không tìm thấy ca làm việc, ngày đó là ngày nghỉ' } unless shift

            # Kiểm tra trùng đề xuất
            existing = Shiftissue.where(
              shiftselection_id: shift.id,
              stype: request_type.upcase,
              status: %w[PENDING APPROVED]
            ).first
            if existing.present?
              return {
                result: false,
                msg: 'Đề xuất đã tồn tại',
                existing_id: existing.id
              }
            end

            # Tạo đề xuất mới
            issue = Shiftissue.create!(
              shiftselection_id: shift.id,
              stype: request_type.upcase,
              name: REQUEST_TYPE_NAMES[request_type],
              approved_by: approver_id,
              status: 'PENDING',
              note: reason,
              us_start: request_type == 'late-check-in' ? time_str : nil,
              us_end: request_type == 'early-check-out' ? time_str : nil,
              docs: docs, # gán ảnh vào đây
              created_at: Time.zone.now,
              updated_at: Time.zone.now
            )
            send_notify(user_id, request_type.upcase, approver_id)
            {
              result: true,
              msg: 'Đã lưu đề xuất thành công',
              shiftselection_id: shift.id,
              issue_id: issue.id,
              us_start: issue.us_start,
              us_end: issue.us_end,
              file_id: docs
            }
          rescue => e
            { error: "Lỗi hệ thống: #{e.message}" }
          end
        end
      end


      resource :attends do
        desc 'Lưu đề xuất chỉnh sửa kế hoạch làm việc'
        params do
          requires :user_id, type: String, desc: 'userID'
          requires :week_num, type: String, desc: 'Tuần làm việc'
          requires :approver_id, type: String, desc: 'ID người duyệt'
          optional :reason, type: String, desc: 'Lý do đề xuất'
        end
        post :save_edit_plan do
          begin
            reason = params[:reason]
            file = params[:file]
            user_id = params[:user_id]
            return { msg: 'Missing user_id' } unless user_id

            approver_id = params[:approver_id]
            return { msg: 'Missing approved_id' } unless approver_id

            week_num = params[:week_num] rescue nil
            return { msg: 'Missing week_num' } unless week_num

            first_shift = Shiftselection
              .joins(:scheduleweek)
              .where(scheduleweeks: { user_id: user_id, week_num: week_num, status: "APPROVED" })
              .first

            first_shift || Shiftselection.joins(:scheduleweek)
                                         .where(scheduleweeks: { user_id: user_id })
                                         .where(work_date: Date.today.beginning_of_day..Date.today.end_of_day)
                                         .first

            if first_shift
              return { msg: 'Không có ca làm việc trong tuần' } unless first_shift
            end

            docs = nil
            if file
              uploaded = upload_file(file)
              return { error: 'Tải file thất bại' } unless uploaded[:id]
              docs = uploaded[:id].to_s
            end

            Shiftissue.create!(
              shiftselection_id: first_shift.id,
              stype: "EDIT-PLAN",
              status: "PENDING",
              note: reason,
              docs: docs,
              approved_by: approver_id,
              content: "Tuần #{week_num}"
            )
            send_notify(user_id, "EDIT-PLAN", approver_id)
            {
              result: true,
              msg: "Đã gửi đề xuất chỉnh sửa kế hoạch làm việc thành công",
              week_num: week_num
            }
          rescue => e
            { error: "Lỗi hệ thống: #{e.message}" }
          end
        end
      end
      # Tìm người có thể đổi ca cho đề xuất đổi ca
      resource :attends do
        desc "Tìm danh sách người có thể đổi ca"
        params do
          requires :user_id,       type: String, desc: "ID người dùng hiện tại"
          requires :original_date, type: String, desc: "Ngày bạn muốn nhường ca (YYYY-MM-DD)"
          requires :target_date,   type: String, desc: "Ngày bạn muốn nhận ca (YYYY-MM-DD)"
        end

        post :available_swap_candidates do
          begin
            current_user = User.find(params[:user_id])
            return { status: "invalid", code: "USER_NOT_FOUND",
            msg: "Không thể tìm thấy user #{params[:user_id]}", result: [] } unless current_user
          end

          original_date = Date.parse(params[:original_date])
          target_date   = Date.parse(params[:target_date])

          # Code mới - @author: trong.lq
          # @date: 16/01/2025
          # Logic: Áp dụng chung cho tất cả phòng ban (bỏ logic riêng cho CTV)
          # ============================================================
          # 1️⃣ Lấy department_id của current_user
          # @author: trong.lq
          # @date: 16/01/2025
          department_info = Positionjob
                            .joins(:works, :department)
                            .where(works: { user_id: current_user.id })
                            .select("positionjobs.department_id")
                            .first

          department_id = department_info&.department_id

          # 2️⃣ Kiểm tra: Bạn có ca làm ngày original_date? (và scheduleweek phải APPROVED)
          # @author: trong.lq
          # @date: 16/01/2025
          has_shift_original = Shiftselection
                                 .joins(:scheduleweek)
                                 .where(scheduleweeks: { user_id: current_user.id, status: "APPROVED" })
                                 .where(work_date: original_date.beginning_of_day..original_date.end_of_day)
                                 .where("COALESCE(shiftselections.is_day_off, '') != 'OFF'")
                                 .exists?
          unless has_shift_original
            return { status: "empty", code: "NO_ORIGINAL_SHIFT",
                     msg: "Bạn không có ca làm để nhường vào ngày #{original_date} hoặc tuần làm việc chưa được duyệt", result: [] }
          end

          # 3️⃣ Kiểm tra: Bạn phải nghỉ ngày target_date (và scheduleweek phải APPROVED)
          # @author: trong.lq
          # @date: 16/01/2025
          has_day_off_target = Shiftselection
                                 .joins(:scheduleweek)
                                 .where(scheduleweeks: { user_id: current_user.id, status: "APPROVED" })
                                 .where(work_date: target_date.beginning_of_day..target_date.end_of_day)
                                 .where(is_day_off: "OFF")
                                 .exists?
          unless has_day_off_target
            return { status: "empty", code: "HAS_SHIFT_ON_TARGET",
                     msg: "Bạn đang có ca làm vào ngày #{target_date}, không thể nhận thêm hoặc tuần làm việc chưa được duyệt", result: [] }
          end

          # 4️⃣ Lấy danh sách người trong cùng phòng ban (trừ current_user)
          # @author: trong.lq
          # @date: 16/01/2025
          base_users = User
                         .joins(works: { positionjob: :department })
                         .where(departments: { id: department_id })
                         .where.not(users: { id: current_user.id })
                         .where(users: { status: [nil, "", "ACTIVE"] })
                         .distinct

          # 5️⃣ Tìm user có CA NGHỈ vào ngày original_date (và scheduleweek phải APPROVED)
          # @author: trong.lq
          # @date: 16/01/2025
          users_day_off = base_users
                            .joins("INNER JOIN scheduleweeks sw1 ON sw1.user_id = users.id")
                            .joins("INNER JOIN shiftselections ss1 ON ss1.scheduleweek_id = sw1.id")
                            .where("ss1.work_date BETWEEN ? AND ?", original_date.beginning_of_day, original_date.end_of_day)
                            .where("ss1.is_day_off = ?", "OFF")
                            .where("sw1.status = ?", "APPROVED")
                            .select(
                              "users.id AS user_id",
                              "users.sid",
                              "users.first_name",
                              "users.last_name",
                              "departments.name AS department_name",
                              "departments.id AS department_id",
                              "sw1.id AS scheduleweek_id",
                              "sw1.week_num",
                              "sw1.start_date",
                              "sw1.status AS scheduleweek_status",
                              "ss1.id AS shiftselection_id",
                              "ss1.work_date",
                              "ss1.status AS shiftselection_status",
                              "ss1.is_day_off"
                            )
                            .distinct

          # 6️⃣ Tìm người đang có CA LÀM vào ngày target_date (và scheduleweek phải APPROVED)
          # @author: trong.lq
          # @date: 16/01/2025
          available_swap_candidates = users_day_off.select do |u|
            Shiftselection
              .joins(:scheduleweek)
              .where(scheduleweeks: { user_id: u.user_id, status: "APPROVED" })
              .where(work_date: target_date.beginning_of_day..target_date.end_of_day)
              .where("COALESCE(is_day_off, '') != ?", 'OFF')
              .exists?
          end
          # ============================================================

          # 7️⃣ Build từng dòng (rows) từ danh sách candidate
          # @author: trong.lq
          # @date: 16/01/2025
          # Code cũ - Lấy scheduleweek và shift từ original_date (SAI)
          # rows = available_swap_candidates.map do |u|
          #   {
          #     user_id: u.user_id,
          #     sid: u.sid,
          #     name: "#{u.last_name} #{u.first_name}",
          #     department_id: u.department_id || "Không xác định",
          #     scheduleweek: {
          #       id: u.scheduleweek_id,  # ❌ Từ original_date
          #       week_num: u.week_num,
          #       start_date: u.start_date,
          #       status: u.scheduleweek_status  # ❌ Có thể là "TEMP"
          #     },
          #     shift: {
          #       id: u.shiftselection_id,  # ❌ Từ original_date
          #       work_date: u.work_date,  # ❌ "2026-01-28" thay vì "2026-01-30"
          #       status: u.shiftselection_status
          #     }
          #   }
          # end

          # Code mới - @author: trong.lq @date: 16/01/2025
          # Sửa: Lấy scheduleweek và shift từ target_date (đúng) để hiển thị đúng ca làm vào ngày target_date
          rows = available_swap_candidates.flat_map do |u|
            # Lấy tất cả ca làm vào ngày target_date của user này
            target_shifts = Shiftselection
                              .joins(:scheduleweek)
                              .where(scheduleweeks: { user_id: u.user_id, status: "APPROVED" })
                              .where(work_date: target_date.beginning_of_day..target_date.end_of_day)
                              .where("COALESCE(is_day_off, '') != ?", 'OFF')

            # Nếu không có ca nào, bỏ qua user này
            next [] if target_shifts.empty?

            # Build rows cho từng ca
            target_shifts.map do |shift|
              {
                user_id: u.user_id,
                sid: u.sid,
                name: "#{u.last_name} #{u.first_name}",
                department_id: u.department_id || "Không xác định",
                scheduleweek: {
                  id: shift.scheduleweek.id,
                  week_num: shift.scheduleweek.week_num,
                  start_date: shift.scheduleweek.start_date,
                  status: shift.scheduleweek.status
                },
                shift: {
                  id: shift.id,
                  work_date: shift.work_date,
                  status: shift.status
                }
              }
            end
          end

          # 8️⃣ Gộp theo user_id, gom nhiều ca vào mảng shifts
          final = rows
                    .group_by { |r| r[:user_id] }
                    .map do |_uid, items|
            first = items.first
            {
              user_id:       first[:user_id],
              sid:           first[:sid],
              name:          first[:name],
              department_id: first[:department_id],
              scheduleweek:  first[:scheduleweek],
              shifts:        items.map { |it| it[:shift] }.compact.uniq { |s| s[:id] }
            }
          end

          return { status: "empty", code: "NO_CANDIDATE",
          msg:   "Không có ứng viên phù hợp", result: [],
          original_date: original_date, target_date: target_date } if final.empty?

          {
            msg: 'success',
            original_date: original_date,
            target_date: target_date,
            result: final
          }

        end
      end
      # Đề xuất chấm công bổ sung
      resource :attends do
        desc "Đề xuất chấm công bổ sung (additional-check-in / additional-check-out)."
        params do
          requires :user_id,       type: String
          requires :original_date, type: String,  desc: "YYYY-MM-DD"
          requires :workshift_id,  type: Integer
          requires :approved_id,   type: Integer
          requires :request_type,  type: String,  values: ["additional-check-in", "additional-check-out"]
          optional :check_in_time,  type: String, desc: "HH:MM (bắt buộc nếu additional-check-in)"
          optional :check_out_time, type: String, desc: "HH:MM (bắt buộc nếu additional-check-out)"
          optional :reason,         type: String
          # optional :file,           type: String, desc: "ID tài liệu/ảnh (docs id)"
        end
        post :additional_check do
          p = declared(params, include_missing: false)
          user_id     = p[:user_id]
          return { msg: 'Không xác định người dùng' } if user_id.blank?

          date        = Date.parse(p[:original_date]) rescue nil
          return { msg: 'Ngày không hợp lệ' } unless date
          stype    = p[:request_type].to_s
          stype_up = stype.upcase
          validation = validate_attend_request_conditions(user_id, date, p[:workshift_id], stype)
          fail!(validation, 422) unless validation == true
          # 1) Upload file (nếu có) - an toàn cho cả Hash/String
          docs = nil
          file = params[:file]
          if file.present?
            uploaded = upload_file(file)
            return { error: 'Tải file thất bại' } unless uploaded[:id]
            docs = uploaded[:id]
          end
          # Validate time theo loại
          hhmm = /\A\d{2}:\d{2}\z/
          if stype == "additional-check-in"
            fail!("Thiếu check_in_time", 422) if p[:check_in_time].to_s.strip.empty?
            fail!("check_in_time không hợp lệ (HH:MM)", 422) unless p[:check_in_time] =~ hhmm
          else # additional-check-out
            fail!("Thiếu check_out_time", 422) if p[:check_out_time].to_s.strip.empty?
            fail!("check_out_time không hợp lệ (HH:MM)", 422) unless p[:check_out_time] =~ hhmm
          end

          shift = find_shift(p[:user_id], date, p[:workshift_id])
          fail!("Không tìm thấy ca làm việc, ngày đó là ngày nghỉ", 404, { user_id: p[:user_id]}) unless shift

          # Kiểm tra trùng cùng ngày + cùng loại
          # @author: trong.lq
          # @date: 21/01/2025
          day_range = date.respond_to?(:all_day) ? date.all_day : Time.zone.parse(date.to_s).all_day
          # Code cũ - @author: trong.lq @date: 21/01/2025
          # existing = Shiftissue.where(shiftselection_id: shift.id, stype: stype_up)
          #                      .where(created_at: day_range)
          #                      .first
          # Code mới - @author: trong.lq @date: 21/01/2025
          # Thêm điều kiện lọc theo status (PENDING, APPROVED) để cho phép tạo lại khi đề xuất cũ bị REJECTED
          existing = Shiftissue.where(shiftselection_id: shift.id, stype: stype_up, status: %w[PENDING APPROVED]).first
          if existing.present?
            status 409
            return { result: false,
                     msg: "Đã tồn tại đề xuất #{REQUEST_TYPE_NAMES[stype_up] || stype_up} cho ngày này.",
                     existing_issue_id: existing.id,
                     data_input: p }
          end

          attrs = {
            shiftselection_id: shift.id,
            stype:       stype_up,
            name:        REQUEST_TYPE_NAMES[stype] || stype,
            approved_by: p[:approved_id],
            status:      "PENDING",
            note:        p[:reason],
            docs:        docs
          }
          attrs[:us_start] = p[:check_in_time]  if stype == "additional-check-in"
          attrs[:us_end]   = p[:check_out_time] if stype == "additional-check-out"

          issue = Shiftissue.create!(attrs)
          send_notify(user_id, stype_up, p[:approved_id])
          status 201
          {
            result: true,
            msg: "Đã lưu đề xuất #{REQUEST_TYPE_NAMES[stype] || stype}",
            shiftselection_id: shift.id,
            us_start: issue.us_start,
            us_end:   issue.us_end
          }
        rescue ActiveRecord::RecordInvalid => e
          fail!("Dữ liệu không hợp lệ: #{e.record.errors.full_messages.join(', ')}", 422)
        rescue => e
          fail!("Lỗi hệ thống: #{e.message}", 500)
        end
      end
      # Đề xuất cập nhật giờ làm việc
      resource :attends do
        desc 'Cập nhật giờ làm việc (ca sáng và chiều) kèm lý do và ảnh nếu có'
        params do
          requires :user_id,       type: String,  desc: 'user_id'
          requires :original_date, type: String,  desc: 'Ngày làm việc (YYYY-MM-DD)'
          requires :approved_id,   type: Integer, desc: 'ID người duyệt'
          optional :reason,        type: String,  desc: 'Lý do cập nhật'
          # KHÔNG thêm gì ở đây theo yêu cầu của bạn
        end
        post :update_shift do
          begin
            # 0) Lấy params cơ bản
            user_id     = params[:user_id]
            return { msg: 'Không xác định người dùng' } if user_id.blank?

            date        = Date.parse(params[:original_date]) rescue nil
            return { msg: 'Ngày không hợp lệ' } unless date

            approver_id = params[:approved_id]
            reason      = params[:reason]
            # 1) Upload file (nếu có) - an toàn cho cả Hash/String
            docs = nil
            file = params[:file]
            if file.present?
              uploaded = upload_file(file)
              return { error: 'Tải file thất bại' } unless uploaded[:id]
              docs = uploaded[:id]
            end
            # validation = validate_attend_request_conditions(user_id, date, "update-shift")
            # fail!(validation, 422) unless validation == true

            # 2) Parse workshifts (form-data text JSON hoặc Array/Hash)
            ws_raw = params[:workshifts]
            return { msg: 'Thiếu workshifts' } if ws_raw.nil? || ws_raw.to_s.strip.empty?

            begin
              parsed = ws_raw.is_a?(String) ? JSON.parse(ws_raw, symbolize_names: true) : ws_raw
            rescue JSON::ParserError, TypeError => e
              return { msg: "workshifts không phải JSON hợp lệ: #{e.message}" }
            end

            parsed = [parsed] if parsed.is_a?(Hash)
            unless parsed.is_a?(Array) && parsed.all? { |x| x.is_a?(Hash) }
              return { msg: "workshifts phải là mảng các object" }
            end

            workshifts = parsed # đã là Array<Hash> với symbol keys

            # 3) Validate & xử lý
            created_ids      = []
            duplicate_issues = []
            not_found_ids    = []

            hhmm = /\A\d{2}:\d{2}\z/

            workshifts.each_with_index do |ws, i|
              # Bỏ qua item rỗng
              next unless ws[:check_in].present? || ws[:check_out].present?

              # Validate time (nếu truyền)
              if ws[:check_in].present?  && ws[:check_in]  !~ hhmm
                return { msg: "check_in không hợp lệ ở item ##{i}: #{ws[:check_in]}" }
              end
              if ws[:check_out].present? && ws[:check_out] !~ hhmm
                return { msg: "check_out không hợp lệ ở item ##{i}: #{ws[:check_out]}" }
              end

              # Tìm ca làm việc
              shift = find_shift(user_id, date, ws[:workshift_id])
              unless shift
                not_found_ids << ws[:workshift_id]
                next
              end


              # Thêm kiểm tra điều kiện (ví dụ ngày hợp lệ, không phải ngày nghỉ)
              validation = validate_attend_request_conditions(user_id, date, ws[:workshift_id], "update-shift")
              unless validation == true
                not_found_ids << ws[:workshift_id]
                next
              end

              # Chống trùng
              existing = Shiftissue.where(
                shiftselection_id: shift.id,
                stype:  "UPDATE-SHIFT",
                status: %w[PENDING APPROVED]
              ).first

              if existing.present?
                duplicate_issues << { shiftselection_id: shift.id, issue_id: existing.id }
                next
              end

              # Tạo issue
              issue = Shiftissue.create(
                shiftselection_id: shift.id,
                stype:       "UPDATE-SHIFT",
                status:      "PENDING",
                note:        reason,
                approved_by: approver_id,
                us_start:    ws[:check_in],
                us_end:      ws[:check_out],
                docs:        docs
              )
              created_ids << issue.id
            end

            # 4) Trả kết quả
            if created_ids.any?
              send_notify(user_id, "UPDATE-SHIFT", approver_id)
              status 201
              {
                msg: "Cập nhật đề xuất thành công",
                result: true,
                created_ids: created_ids,
                duplicate_count: duplicate_issues.size,
                duplicates: duplicate_issues,
                not_found_workshift_ids: not_found_ids.uniq
              }
            elsif duplicate_issues.any?
              status 409
              {
                msg: "Một hoặc nhiều đề xuất đã tồn tại",
                result: false,
                duplicates: duplicate_issues,
                not_found_workshift_ids: not_found_ids.uniq
              }
            else
              status 422
              {
                msg: "Không có dữ liệu cập nhật",
                result: false,
                not_found_workshift_ids: not_found_ids.uniq
              }
            end

          rescue => e
            # Trả về cả class + dòng đầu backtrace để debug nhanh
            return { msg: "Lỗi hệ thống: #{e.class}: #{e.message}", where: e.backtrace&.first }
          end
        end
      end

      # Tạo đề xuất đổi ca
      resource :attends do
        desc 'Tạo đề xuất đổi ca — mỗi ca của mình lưu 1 shiftissue'
        params do
          optional :user_id, type: Integer, desc: 'ID người gửi đề xuất'
          requires :request_type, type: String, values: ['shift-change']
          requires :original_date, type: String,  desc: "YYYY-MM-DD"
          requires :target_date, type: String,  desc: "YYYY-MM-DD"
          requires :partner_user_id, type: String
          requires :approved_id,     type: String
          optional :reason, type: String
        end

        post :save_shift_change do
          uid = current_user_id = params[:user_id]
          fail!('Không xác định người dùng', 401) unless uid
          fail!('Sai loại đề xuất', 422) unless params[:request_type] == 'shift-change'

          original_date = Date.iso8601(params[:original_date]) rescue nil
          target_date   = Date.iso8601(params[:target_date]) rescue nil
          fail!('Ngày không hợp lệ', 422) unless original_date && target_date
          # validation = validate_attend_request_conditions(uid, original_date, nil, "shift-change")
          # fail!(validation, 422) unless validation == true

          partner_id  = params[:partner_user_id].to_i
          approver_id = params[:approved_id]
          reason      = (params[:reason] || '').strip
          docs = nil
          file = params[:file]
          if file.present?
            uploaded = upload_file(file)
            fail!('Tải file thất bại', 422) unless uploaded[:id]
            docs = uploaded[:id]
          end

          my_shifts      = shifts_in_day(uid, original_date)
          partner_shifts = shifts_in_day(partner_id, target_date)

          fail!("Bạn không có ca làm trong ngày #{original_date}", 422) if my_shifts.empty?
          fail!("Đối tác không có ca làm trong ngày #{target_date}", 422) if partner_shifts.empty?

          if my_shifts.size != partner_shifts.size
            fail!("Số ca giữa hai ngày không khớp (#{my_shifts.size} vs #{partner_shifts.size}). Vui lòng chọn lại.", 422)
          end

          created_ids = []

          ActiveRecord::Base.transaction do
            my_shifts.sort_by!      { |s| (s.start_time || '00:00') }
            partner_shifts.sort_by! { |s| (s.start_time || '00:00') }

            my_shifts.zip(partner_shifts).each do |mine, theirs|
              next unless mine && theirs

              dup = Shiftissue.exists?(
                shiftselection_id: mine.id,
                ref_shift_changed: theirs.id.to_s,
                stype: 'SHIFT-CHANGE',
                status: %w[PENDING APPROVED]
              )
              next if dup

              issue = Shiftissue.create!(
                shiftselection_id: mine.id,
                stype: 'SHIFT-CHANGE',
                status: 'PENDING',
                note: reason,
                approved_by: approver_id,
                ref_shift_changed: theirs.id.to_s,
                us_start: mine.start_time,
                us_end: mine.end_time,
                docs: docs
              )

              created_ids << issue.id
            end
          end

          if created_ids.any?
            send_notify(user_id, "SHIFT-CHANGE", approver_id)
            { msg: 'success', result: created_ids }
          else
            { msg: 'Đề xuất đã được tạo', result: [] }
          end
        rescue => e
          fail!(e.message, 422)
        end
      end

      # Tạo đề xuất đi công tác
      resource :attends do
        desc 'Tạo đề xuất đi công tác'
        params do
          requires :user_id, type: String, desc: 'ID người dùng'
          requires :approved_id, type: Integer, desc: 'ID người duyệt', coerce: ->(val) { val.to_i }
          optional :reason, type: String, desc: 'Lý do'
          requires :trip_shift_data, type: Array, desc: 'Dữ liệu ca công tác',
                  coerce_with: ->(val) { JSON.parse(val.to_s) rescue nil }
        end
        post :work_trip do
          begin
            user_id        = params[:user_id]
            approver_id    = params[:approved_id]
            reason         = params[:reason]
            trip_shift_data = params[:trip_shift_data]
            docs = nil
            file = params[:file]
            if file.present?
              uploaded = upload_file(file)
              fail!('Tải file thất bại', 422) unless uploaded[:id]
              docs = uploaded[:id]
            end

            created_issues = []
            errors = []

            trip_shift_data.each do |entry|
              date_str  = entry["date"] || entry[:date]
              shift_ids = entry["shifts"] || entry[:shifts]

              unless date_str && shift_ids.is_a?(Array) && !shift_ids.empty?
                errors << "Dữ liệu không hợp lệ: thiếu date hoặc shifts"
                next
              end

              date = Date.parse(date_str) rescue nil
              unless date
                errors << "Ngày không hợp lệ: #{date_str}"
                next
              end

              Array(shift_ids).each do |shift_id|
                validation = validate_attend_request_conditions(user_id, date, shift_id, "work-trip")
                unless validation == true
                  errors << "Xác thực thất bại: #{validation} (ngày #{date_str}, ca #{shift_id})"
                  next
                end

                shift = find_shift(user_id, date, shift_id, include_day_off: true)
                unless shift
                  errors << "Không tìm thấy ca làm việc (#{shift_id}) vào ngày #{date_str}"
                  next
                end

                exists = Shiftissue.exists?(
                  shiftselection_id: shift.id,
                  stype: "WORK-TRIP",
                  status: %w[PENDING APPROVED]
                )
                if exists
                  errors << "Đã tồn tại đề xuất công tác cho ca #{shift_id} ngày #{date_str}"
                  next
                end

                issue = Shiftissue.create(
                  shiftselection_id: shift.id,
                  stype: "WORK-TRIP",
                  status: "PENDING",
                  note: reason,
                  approved_by: approver_id,
                  us_start: shift.start_time,
                  us_end: shift.end_time,
                  docs: docs
                )

                if issue.persisted?
                  created_issues << { issue_id: issue.id, shiftselection_id: issue.shiftselection_id }
                else
                  errors << "Không tạo được issue cho ca #{shift_id} ngày #{date_str}"
                end
              end
            end

            if created_issues.any?
              send_notify(user_id, "WORK-TRIP", approver_id)
              status 201
              { msg: "success", result: true, created: created_issues, errors: errors }
            else
              status 422
              { msg: "Không tạo được đề xuất nào", result: false, details: errors }
            end

          rescue => e
            error!({ msg: "Lỗi hệ thống: #{e.message}", status: 500 }, 500)
          end
        end
      end



      resource :attends do
        desc "Lấy danh sách sự kiện chấm công và đề xuất trong ngày hoặc tháng của nhân sự"
        params do
          requires :user_id, type: Integer
          optional :day, type: Integer
          optional :month, type: Integer
          optional :year, type: Integer
        end

        post :user_events_on_day do
          begin
            to_user = "";
            user = User.find_by(id: params[:user_id])
            raise "User not found" unless user

            if params[:month].blank? || params[:year].blank?
              error!({ msg: "Cần truyền ít nhất tháng và năm", result: [] }, 400)
            end

            # === Tạo mảng ngày cần lọc
            year = params[:year].to_i
            month = params[:month].to_i
            filter_dates =
              if params[:day].present?
                [Time.zone.local(year, month, params[:day].to_i, 0, 0, 0)]
              else
                start_date = Date.new(year, month, 1)
                end_date = start_date.end_of_month
                (start_date..end_date).to_a
              end

            events = []

            weeks = Scheduleweek
                      .joins("LEFT JOIN users ON users.id = scheduleweeks.user_id")
                      .select("scheduleweeks.*, CONCAT(users.last_name, ' ', users.first_name) as user_name")
                      .where(user_id: user.id)
                      .where("scheduleweeks.end_date >= ? AND scheduleweeks.start_date <= ?", filter_dates.min, filter_dates.max)
                      .where(status: %w[PENDING APPROVED])

            # Sau khi đã gom tất cả weeks và shiftselections:
            work_trips = Shiftissue
            .joins(:shiftselection)
            .select("shiftissues.*, shiftselections.work_date AS shiftselection_work_date")
            .where(shiftselections: { scheduleweek_id: weeks.map(&:id) }, stype: 'WORK-TRIP')
            .order(:created_at, 'shiftselections.work_date')

            # Gom theo ngày tạo
            grouped_by_created = work_trips.group_by { |i| i.created_at.to_date }

            grouped_by_created.each do |created_date, issues|
              # Gom các ngày làm việc liên tiếp
              sorted = issues.sort_by { |i| local_date(i.shiftselection_work_date) }

              day_groups = sorted.slice_when do |prev, curr|
                (curr.shiftselection_work_date.to_date - prev.shiftselection_work_date.to_date).to_i > 1
              end

              day_groups.each do |group|
                start_date = local_date(group.first.shiftselection_work_date)
                end_date_exclusive = local_date(group.last.shiftselection_work_date) + 1
                status = group.first.status
                status_class = case status
                              when 'APPROVED' then 'fc-week-approved'
                              when 'PENDING'  then 'fc-week-pending'
                              else 'fc-week-unknown'
                              end
                color = case status
                        when 'APPROVED' then '#10b981'  # xanh lá cây
                        when 'PENDING'  then '#f59e0b'  # cam
                        else '#9ca3af'                 # xám mặc định nếu unknown
                        end
                events << {
                  title: '✈️ Đi công tác',
                  start: start_date.strftime('%Y-%m-%d'),
                  end: end_date_exclusive.strftime('%Y-%m-%d'),
                  allDay: true,
                  displayOrder: 2,
                  color: color,
                  textColor: '#04288d',
                  classNames: [status_class],
                  extendedProps: {
                    type: 'SHIFT_ISSUE',
                    stype: 'WORK-TRIP',
                    created_date: created_date,
                    count: group.size,
                    shiftselection_ids: group.map(&:shiftselection_id),
                    dates: group.map { |i| local_date(i.shiftselection_work_date).strftime('%Y-%m-%d') }
                  }
                }
              end
            end

            weeks.each do |week|
              shiftselections_query = Shiftselection.includes(:workshift)
                                                    .where(scheduleweek_id: week.id)

              # Filter shiftselections by date range for each day in filter_dates
              shiftselections = filter_dates.flat_map do |date|
                shiftselections_query.where(work_date: date.beginning_of_day..date.end_of_day)
              end

              shiftselections.each do |sel|

                ws = sel.workshift
                checkin = nil
                checkout = nil
                attend = Attend.find_by(shiftselection_id: sel.id)

                if attend
                  checkin  = attend.checkin&.strftime('%H:%M')
                  checkout = attend.checkout&.strftime('%H:%M')
                end

                # 1️⃣ Event: Chấm công
                events << {
                  id: sel.id,
                  title: "Check-in",
                  dtfrom: sel.work_date,
                  start: sel&.start_time || "",
                  end:   sel&.end_time || "",
                  user_name: week.user_name,
                  status: nil,
                  week_status: week.status,
                  stype: "attend",
                  shiftName: ws&.name,
                  checkin: checkin || "",
                  checkout: checkout || "",
                  is_day_off: sel.is_day_off
                }

                # 2️⃣ Event: Đề xuất
                shift_issues = Shiftissue.where(shiftselection_id: sel.id)

                shift_issues.each do |i|
                  if i.ref_shift_changed.present?
                    shiftselection_change = get_shiftselection_by_id(i.ref_shift_changed)
                    to_workshift  = "#{shiftselection_change[:workshift]} #{shiftselection_change[:start_time]} - #{shiftselection_change[:end_time]}"
                    to_date = shiftselection_change[:work_date]
                    to_user = shiftselection_change[:user_name]
                  end
                  shift_type_key = i.stype.to_s.gsub("_", "-")
                  next unless REQUEST_TYPE_NAMES.key?(shift_type_key)
                  title = shift_type_key == "SHIFT-CHANGE-APPROVED" ?
                  "#{REQUEST_TYPE_NAMES[shift_type_key]} với #{to_user}" :
                  REQUEST_TYPE_NAMES[shift_type_key]
                  events << {
                    id: i.id,
                    title: title,
                    dtfrom: sel.work_date,
                    start: i.us_start || "",
                    end:   i.us_end || "",
                    user_name: week.user_name,
                    status: i.status == "APPROVED" ? "Đã duyệt" : i.status == "REJECTED" ? "Từ chối" : "Chưa duyệt",
                    stype: shift_type_key,
                    shiftName: nil
                  }
                end
              end
            end

            {
              size: events.size,
              msg: "success",
              result: events,
              to_user:to_user
            }
          rescue => e
            { msg: "ERROR: #{e.message}", result: [] }
          end
        end
      end


      ###end

      # Get schedule week by user_id
      # @author: Dat Le
      # @date: 02/08/2025
      # @input: user_id
      # @output: json
      desc "Get schedule week by user_id"
      get :get_scheduleweeks do
        begin
          user_id = params[:user_id]
          from_date = Date.current.beginning_of_week(:monday) - 1.day
          to_date   = from_date + 3.weeks + 1.day

          scheduleweek = Scheduleweek
                           .where(user_id: user_id)
                           .where(status: %w[TEMP PENDING REJECTED APPROVED])
                           .where('DATE(start_date) BETWEEN ? AND ?', from_date, to_date)
                           .includes(:shiftselection)
                           .order(:start_date)

          data = scheduleweek.map { |item|
            {
              id:          item.id,
              week_num:    item.week_num,
              year:        item.year,
              start_date:  item.start_date&.strftime("%Y-%m-%d"),
              end_date:    item.end_date.to_date.strftime("%Y-%m-%d"),
              status:      item.status,
              reason:      item.reason,
              shift_details: item.shiftselection.map { |shiftselection|
                {
                  workshift_id: workshift_code_map.invert[shiftselection.workshift_id],
                  work_date:    shiftselection.work_date&.strftime("%Y-%m-%d"),
                  location:     shiftselection.location,
                  start_time:   shiftselection.start_time,
                  end_time:     shiftselection.end_time,
                  is_day_off:   shiftselection.is_day_off
                }
              }
            }
          }
          {
            msg: "success",
            result: data
          }
        rescue => e
          {
            msg: e.message,
            result: []
          }
        end
      end

      # Get shiftselection by work_date and user_id
      # @author: Dat Le
      # @date: 26/09/2025
      # @input: work_date, user_id
      # @output: json
      desc "Get shiftselection by work_date and user_id"
      params do
        requires :user_id, type: Integer
        requires :work_date, type: String
      end
      get :get_shiftselection_by_work_date do
        begin
          user_id = params[:user_id]
          return { msg: 'Không xác định người dùng' } if user_id.blank?

          work_date = Date.parse(params[:work_date]) rescue nil
          return { msg: 'Ngày không hợp lệ' } unless work_date

          shiftselections = Shiftselection.joins(:scheduleweek)
                        .where(scheduleweeks: {user_id: user_id, status: 'APPROVED'})
                        .where(work_date: work_date.beginning_of_day..work_date.end_of_day)
          data = []
          if shiftselections.present?
            data = shiftselections.map do |item|
              start_dt = Time.parse(item.start_time)
              end_dt   = Time.parse(item.end_time)
              total_seconds = end_dt - start_dt
              total_hours   = total_seconds / 3600
              {
                id: item.id,
                work_date: item.work_date.to_date,
                workshift_id: workshift_code_map.invert[item.workshift_id],
                start_time: item.start_time,
                end_time: item.end_time,
                total_hours: total_hours,
                is_day_off: item.is_day_off,
                is_checkin: Attend.find_by(shiftselection_id: item.id)&.checkin.present?,
                is_checkout: Attend.find_by(shiftselection_id: item.id)&.checkout.present?
              }
            end
          end

          {
            msg: "success",
            result: data
          }
        rescue => e
          {
            msg: e.message,
            result: []
          }
        end
      end

      # Get available dates for create shiftissue
      # @author: Dat Le
      # @date: 09/08/2025
      # @input: user_id
      # @output: start_date, end_date
      desc "Get available dates for create shiftissue"
      post :get_available_dates do
        begin
          user_id = params[:user_id]
          return { msg: 'user_id_missing', result: false } if user_id.blank?
          current_time = Time.zone.now.in_time_zone("Asia/Ho_Chi_Minh")
          current_date = current_time.to_date - 1.month
          month_start = current_date.beginning_of_month
          month_end   = current_date.end_of_month
          earliest_overlap_week = Scheduleweek
                                    .where(user_id: user_id, status: 'APPROVED')
                                    .where('start_date <= ? AND end_date >= ?', month_end, month_start)
                                    .order(:start_date)
                                    .first
          unless earliest_overlap_week
            current_date = current_time.to_date
            month_start = current_date.beginning_of_month
            month_end   = current_date.end_of_month
            earliest_overlap_week = Scheduleweek
                                      .where(user_id: user_id, status: 'APPROVED')
                                      .where('start_date <= ? AND end_date >= ?', month_end, month_start)
                                      .order(:start_date)
                                      .first
          end
          if earliest_overlap_week.nil?
            return {
              msg: "success",
              result: { start_date: nil, end_date: nil }
            }
          end
          start_date = earliest_overlap_week.start_date
          latest_week = Scheduleweek
                          .where(user_id: user_id, status: 'APPROVED')
                          .order(end_date: :desc)
                          .first
          latest_work_date = Shiftselection
                               .where(scheduleweek_id: latest_week.id)
                               .maximum(:work_date)
          {
            msg: "success",
            result: {
              start_date: start_date.strftime('%d/%m/%Y'),
              end_date:   latest_work_date.strftime('%d/%m/%Y')
            }
          }
        rescue => e
          {
            msg: e.message,
            result: false
          }
        end
      end

      # Approval scheduleweek
      # @author: Hoang vu
      # @date: 08/08/2025
      # @input: status,data
      # @output: json
      desc "Get shiftissue by user_id"
      post :approval_scheduleweek do
        status = params[:status]
        data = params[:data]
        message = "success"
        success = true
        ActiveRecord::Base.transaction do
          begin
            data.each do |item|

              scheduleweek = Scheduleweek.find(item["id"])
              scheduleweek.update(status:status,reason:item["reason"],checked_at: DateTime.now)
              shiftselections = Shiftselection.where(scheduleweek_id: item["id"])
              shiftselections.update_all(status:status)

              result_message = status == "APPROVED" ? "được duyệt" : "bị từ chối"
              notify = Notify.create(
                title: "Thông báo duyệt kế hoạch tuần",
                contents: "Kế hoạch tuần #{scheduleweek.start_date.to_date.cweek} (#{scheduleweek.start_date.strftime("%d/%m/%Y")} - #{scheduleweek.end_date.strftime("%d/%m/%Y")}) đã #{result_message}.<br>
                            #{status == "REJECTED" ? "<span>Lý do:</span>#{item["reason"]}<span>" : ""}",
                receivers: "Hệ thống ERP",
                stype: "SHIFTSELECTION"
              )
              Snotice.create(
                notify_id: notify.id,
                user_id: scheduleweek.user_id,
                isread: false,
                username: nil
              )
            end
          rescue => e
            success = false
            message = e.message.gsub("\`","")
            raise ActiveRecord::Rollback
          end
        end
        {
          msg: message,
          result: success,
        }
      end

      # Approval shiftissue
      # @author: Hoang vu
      # @date: 08/08/2025
      # @input: status,data
      # @output: json
      desc "Get shiftissue by user_id"
      post :approval_shiftissue do
        status = params[:status]
        data = params[:data]
        message = "success"
        success = true
        ActiveRecord::Base.transaction do
          begin
            data.each do |item|
              # shiftissue = Shiftissue.find(item["id"])
              representative_id = item["id"]
              reason = item["reason"]

              representative = Shiftissue.joins(shiftselection: :scheduleweek)
                                    .joins("LEFT JOIN users ON users.id = scheduleweeks.user_id")
                                    .select("shiftissues.*, users.sid, shiftselections.work_date")
                                    .find(representative_id) rescue nil
              if representative.present?
                if representative.stype == 'WORK-TRIP'
                  grouped_items = Shiftissue.joins(shiftselection: :scheduleweek)
                                            .joins("LEFT JOIN users ON users.id = scheduleweeks.user_id")
                                            .where("shiftissues.stype = 'WORK-TRIP'")
                                            .where("users.sid = ?", representative.sid)
                                            .where("shiftissues.created_at = ?", representative.created_at)

                  work_dates = grouped_items.joins(:shiftselection)
                                            .pluck('shiftselections.work_date')
                                            .uniq
                  is_one_day = work_dates.length == 1

                  grouped_items.each do |shift_item|
                    attrs =
                      if status == 'APPROVED'
                        { status: 'APPROVED', approved_at: Time.current }
                      else
                        { status: 'REJECTED', content: reason, approved_at: Time.current }
                      end
                    shift_item.update!(attrs)

                    # ======= NEW: Tạo Attend CHECKIN + CHECKOUT nếu là APPROVED =======
                    if status == 'APPROVED'
                      shiftselection = shift_item.shiftselection
                      uid            = shiftselection.scheduleweek.user_id

                      # Nếu bạn vẫn dùng start_time/end_time của ca:
                      work_date      = shiftselection.work_date.to_date
                      checkin_time   = Time.zone.parse("#{work_date} #{shiftselection.start_time}")
                      checkout_time  = Time.zone.parse("#{work_date} #{shiftselection.end_time}")

                      # Tạo attend
                      attend = Attend.find_or_create_by!(
                        user_id:           uid,
                        shiftselection_id: shiftselection.id,
                        stype:             'ATTENDANCE',
                        status:            'CHECKIN',
                        note:              'Cập nhật giờ đi công tác',
                        checkin:           checkin_time,
                        checkout:          checkout_time
                      )

                      # Tạo bản ghi attenddetails cho CHECKIN
                      attend.attenddetails.create!(
                        stype:     'CHECKIN',
                        dtcheckin: checkin_time
                      )

                      # Tạo bản ghi attenddetails cho CHECKOUT
                      attend.attenddetails.create!(
                        stype:      'CHECKOUT',
                        dtcheckout: checkout_time
                      )
                    end

                    # ======= END NEW =======

                    send_shiftissue_notification(shift_item, shift_item.status, reason)
                  end

                else
                  shiftissue = representative
                  if status == "REJECTED"
                    shiftissue.update({status: status,content:reason,approved_at: Time.now})
                  else
                    shiftissue.update({status: status,approved_at: Time.now})
                    case shiftissue.stype
                    when "EARLY-CHECK-OUT"
                    when "LATE-CHECK-IN"
                    when "EDIT-PLAN"
                      user_id = shiftissue.shiftselection.scheduleweek.user_id
                      week_info = shiftissue.content
                      week_num = week_info.gsub("Tuần ", "").to_i
                      Scheduleweek.where(user_id: user_id, week_num: week_num).update(status: "TEMP")
                    when "SHIFT-CHANGE"
                      results = []
                      shiftissue.update({status: "PENDING",approved_at: Time.now})
                      results << process_shiftissue_change(shiftissue,status)
                      rs_Groups = results.compact.present? ? group_by_date(results) : []
                      swapped = swap_cross_day(rs_Groups)
                      updated_result = force_update_by_swapped_data(swapped)
                      classified_cases = classify_shift_change_cases_before_swap(swapped) || []
                      update_shift_issues_with_classified_cases(classified_cases) || []
                    when "ADDITIONAL-CHECK-IN"
                      attend = Attend.find_by(shiftselection_id: shiftissue.shiftselection_id)
                      us_start = shiftissue.us_start.split(":")
                      shiftselection = Shiftselection.find(shiftissue.shiftselection_id)
                      updated_datetime = DateTime.new(shiftselection.work_date.year,
                                                      shiftselection.work_date.month,
                                                      shiftselection.work_date.day,
                                                      us_start[0].to_i,
                                                      us_start[1].to_i,0,
                                                      shiftselection.work_date.zone)
                      if attend.nil?
                        Attend.create({
                          checkin: updated_datetime,
                          user_id: shiftselection.scheduleweek.user_id,
                          stype: "ATTENDANCE",
                          shiftselection_id: shiftissue.shiftselection_id,
                          status:"CHECKIN",
                          note:"Chấm công bù vào ca",
                        })
                      else
                        attend.update({checkin: updated_datetime})
                      end
                    when "ADDITIONAL-CHECK-OUT"
                      attend = Attend.find_by(shiftselection_id: shiftissue.shiftselection_id)
                      us_end = shiftissue.us_end.split(":")
                      shiftselection = Shiftselection.find(shiftissue.shiftselection_id)
                      updated_datetime = DateTime.new(shiftselection.work_date.year,
                                                      shiftselection.work_date.month,
                                                      shiftselection.work_date.day,
                                                      us_end[0].to_i,
                                                      us_end[1].to_i,0,
                                                      shiftselection.work_date.zone)
                      if attend.nil?
                        Attend.create({
                          checkout: updated_datetime,
                          user_id: shiftselection.scheduleweek.user_id,
                          stype: "ATTENDANCE",
                          shiftselection_id: shiftissue.shiftselection_id,
                          status:"CHECKOUT",
                          note:"Chấm công bù tan ca",
                        })
                      else
                        attend.update({checkout: updated_datetime})
                      end
                    when "UPDATE-SHIFT"
                      shiftselection = Shiftselection.find(shiftissue.shiftselection_id)
                      shiftselection.update({
                                              start_time: shiftissue.us_start,
                                              end_time: shiftissue.us_end,
                                            })
                    else

                    end

                    # send notice
                    result_message = status == "APPROVED" ? "được duyệt" : "bị từ chối"
                    notify = Notify.create(
                      title: "Thông báo duyệt đề xuất #{REQUEST_TYPE_NAMES[shiftissue.stype.upcase]}",
                      contents: "Đề xuất #{REQUEST_TYPE_NAMES[shiftissue.stype.upcase]} của bạn đã #{result_message}.<br>
                                  #{status == "REJECTED" ? "<span>Lý do:</span>#{reason}<span>" : ""}",
                      receivers: "Hệ thống ERP",
                      stype: "SHIFTSELECTION"
                    )
                    scheduleweek = Scheduleweek.find(Shiftselection.find(shiftissue.shiftselection_id).scheduleweek_id)
                    Snotice.create(
                      notify_id: notify.id,
                      user_id: scheduleweek.user_id,
                      isread: false,
                      username: nil
                    )
                  end
                end
              end
            end
          rescue => e
            success = false
            message = e.message.gsub("\`","")
            raise ActiveRecord::Rollback
          end
        end
        {
          msg: message,
          result: success
        }
      end

      # lấy các ngày nghỉ phép đã đăng kí của nhân viên
      # @author: Tuấn
      # @date: 20/08/2025
      # @input: id, year
      # @output: mảng ngày xin nghỉ phép

      SHOLTYPE_NAMES = {
        "NGHI-PHEP" => "Nghỉ phép",
        "NGHI-KHONG-LUONG" => "Nghỉ không lương",
        "NGHI-CDHH" => "Nghỉ chế độ (Hiếu/Hỷ)",
        "NGHI-CHE-DO"=> "Nghỉ chế độ",
        "NGHI-CHE-DO-BAO-HIEM-XA-HOI" => "Nghỉ chế độ bảo hiểm xã hội"
      }

      desc "Get logged in employee leave dates"
      params do
        requires :id, type: Integer, desc: "ID nhân viên"
        optional :year, type: Integer, desc: "Năm"
        optional :month, type: Integer, desc: "Tháng "
      end

      get :get_employee_leave_days do
        begin
          id    = params[:id]
          year  = (params[:year]  || Date.current.year).to_i
          month = (params[:month] || Date.current.month).to_i

          # ===== range theo tháng/năm đang xem (calendar 6 tuần) =====
          base_date = Date.new(year, month, 1)
          beginning_of_week = base_date.beginning_of_week(:monday)
          from_date = beginning_of_week - 1.month
          to_date   = beginning_of_week + 6.weeks - 1.day

          user = User.find_by(id: id)
          return { msg: "user_not_found", result: [] } unless user

          # ✅ FIX: lấy Holiday đúng theo year
          holiday = Holiday.find_by(user_id: user.id, year: year.to_s)

          # (tuỳ bạn) nếu year param không có hoặc không tìm thấy holiday theo year,
          # thì fallback về holiday mới nhất
          holiday ||= Holiday.where(user_id: user.id).order(Arel.sql("CAST(year AS UNSIGNED) DESC"), id: :desc).first
          return { msg: "holiday_not_found", result: [] } unless holiday

          holpros = Holpro.where(
            holiday_id: holiday.id,
            status: ["DONE", "CANCEL-DONE", "CANCEL-PENDING"]
          )

          return { msg: "no_leave_requests", result: [] } if holpros.blank?

          sholtypes = SHOLTYPE_NAMES.keys

          details = Holprosdetail.where(
            holpros_id: holpros.pluck(:id),
            sholtype: sholtypes
          )

          leave_days = []

          parse_ddmmy = lambda do |s|
            s = s.to_s.strip
            begin
              Date.strptime(s, "%d/%m/%Y")
            rescue ArgumentError
              begin
                Date.strptime(s, "%d/%m/%y")
              rescue ArgumentError
                nil
              end
            end
          end

          details.each do |d|
            d.details.to_s.split("$$$").each do |date_str|
              date_part, session = date_str.split("-", 2)
              next if date_part.blank?

              parsed_date = parse_ddmmy.call(date_part)
              next if parsed_date.nil?

              next if parsed_date < from_date || parsed_date > to_date

              leave_days << {
                date: parsed_date.strftime("%d/%m/%Y"),
                session: session,
                sholtype: SHOLTYPE_NAMES[d.sholtype] || d.sholtype
              }
            end
          end

          leave_days.uniq! { |x| [x[:date], x[:session], x[:sholtype]] }
          leave_days.sort_by! { |x| Date.strptime(x[:date], "%d/%m/%Y") }

          {
            msg: "success",
            employee_id: id,
            employee_sid: user.sid,
            employee_name: "#{user.last_name} #{user.first_name}",
            holiday_id: holiday.id,
            holiday_year: holiday.year,
            year: year,
            month: month,
            total_days: leave_days.size,
            result: leave_days
          }


          rescue => e
            { msg: "Error: #{e.message}", result: [] }
          end
        end


      # Kiểm tra nhân sự không cần chấm công
      # @author: Tuấn
      # @date: 21/08/2025
      # @input:
      # @output: sid, full_name, True or False
      desc 'Kiểm tra nhân sự có cần chấm công không'
      params do
        requires :id, type: String, desc: 'ID nhân sự'
      end
      get :check_ignore do
        user = User.find_by(id: params[:id])

        if user.nil?
          error!({ msg: 'user_not_found', id: params[:id] }, 404)
        end

        ignored = ActiveModel::Type::Boolean.new.cast(user.ignore_attend)

        {
          id: user.id,
          sid: user.sid,
          full_name: "#{user.first_name} #{user.last_name}".strip,
          ignore_attend: ignored,
        }
      end


    # Kiểm tra nhân sự có phải giảng viên, trợ giảng, kỹ thuật viên không
    # @author: Đạt
    # @date: 21/10/2025
    # @input: user_id
    # @output: boolean
      desc 'Kiểm tra nhân sự có phải giảng viên, trợ giảng, kỹ thuật viên không'
      params do
        requires :user_id, type: String, desc: 'ID nhân sự'
      end
      get :is_lecturer do
        begin
          user_id = params[:user_id] || session[:user_id]
          user = User.find_by(id: user_id)

          if user.nil?
            error!({ msg: 'user_not_found', id: user_id }, 404)
          end

          works = Work.where(user_id: user_id).where.not(positionjob_id: nil).pluck(:positionjob_id)
          positionjob_scode = Positionjob.where(id: works).where.not(department_id: nil).distinct.pluck(:scode)
          keywords = ["GIANG-VIEN","KY-THUAT-VIEN","TRO-GIANG"]
          result = (positionjob_scode & keywords).any?

          { msg: "Success", result: result }
        rescue => e
          { msg: "Error: #{e.message}"}
        end
      end


    # Lấy danh sách ban giám hiệu dùng cho phê duyệt học phí, lệ phí
    # @author: Đạt
    # @date: 17/11/2025
    # @input: nil
    # @output: Hash
      desc 'Lấy danh sách ban giám hiệu dùng cho phê duyệt học phí, lệ phí'
      get :get_all_directors do
        begin
          keywords = ["HIEU-TRUONG","PHO-HIEU-TRUONG"]

          result = User.joins(works: :positionjob)
              .where(positionjobs: { scode: keywords })
              .distinct
              .map { |u| { id: u.id, name: "#{u.last_name} #{u.first_name}" } }

          { msg: "Success", result: result }
        rescue => e
          { msg: "Error: #{e.message}"}
        end
      end



  # ==================================================================================
    end
  end
end

# Hàm bổ trợ cho API
private

def get_nfirst_node_assets(scode)
  oDepartment = nil
  forms = []
  # stream
  stream = Stream.where(scode: scode).first
  if !stream.nil?
    node = Node.where(stream_id:stream.id, nfirst: "YES").first
    if !node.nil?
      oDepartment = {
        id: node&.department.id,
        name: node&.department.name,
        stype: node&.department.stype,
      }
    end
    # forms = Connect.where(nbegin: node&.department_id, stream_id:stream.id).pluck(:forms)
  end
  return {
    result: oDepartment,
    msg:""
  }
end
# H.anh
  def get_user_info_leave(user_id)
    oUser = User.where(id: user_id).first
    full_name = ""
    sid = ""
    phone = ""
    if oUser.present?
      full_name = "#{oUser.last_name} #{oUser.first_name}"
      sid = oUser.sid
      raw_phone = oUser.phone.presence || oUser.mobile
      phone = raw_phone.to_s.sub(/^'/, "")
    end
    [full_name, sid, phone]
  end
  def extract_dates_from_details_date_range(details)
    return [] if details.blank?

    details.split('$$$').map do |item|
      date_str = item.split('-').first&.strip
      begin
        Date.strptime(date_str, "%d/%m/%Y")
      rescue
        nil
      end
    end.compact
  end
  def fetch_leaf_departments_by_user(user_id)
    positionjob_ids = Work.where(user_id: user_id)
                          .where.not(positionjob_id: nil)
                          .pluck(:positionjob_id)

    department_ids = Positionjob.where(id: positionjob_ids).pluck(:department_id)

    departments = Department.where(id: department_ids).where.not(parents: [nil, ""])

    if departments.present?
      parent_ids = departments.map(&:parents).compact.map(&:to_i)
      departments.reject { |dept| parent_ids.include?(dept.id) }
    else
      Department.where(id: department_ids).limit(1)
    end
  end
  def fetch_all_sub_department_ids(root_ids)
      all_ids = root_ids.dup
      queue = root_ids.dup

      while queue.any?
        current_id = queue.shift
        children = Department.where(parents: current_id).pluck(:id)
        queue.concat(children)
        all_ids.concat(children)
      end

      all_ids.uniq
  end
  def fetch_position_and_department_name(user_id)
    department_user = fetch_leaf_departments_by_user(user_id)
    return [nil, nil] if department_user.blank?

    department = department_user.first
    return [nil, nil] if department.nil?

    # lưu lại tên của department con đầu tiên
    child_name = department.name

    # tìm department gốc (cha cao nhất có parents = nil)
    parent_department = department
    while parent_department&.parents.present?
      parent_department = Department.find_by(id: parent_department.parents)
    end

    # nếu có cha gốc thì format "cha - con", nếu không thì chỉ lấy tên hiện tại
    if parent_department && parent_department.id != department.id
      department_name = "#{parent_department.name} - #{child_name}"
    else
      department_name = child_name
    end

    # tìm lại positionjob_name dựa theo department của user
    work = Work.includes(:positionjob)
              .where(user_id: user_id)
              .where.not(positionjob_id: nil)
              .detect { |w| w.positionjob&.department_id == department.id }

    positionjob_name = work&.positionjob&.name
    check_pros = Work.joins(stask: { accesses: :resource })
                                    .where(
                                      resources: { scode: "APPROVE-REQUEST" },
                                      works:     { user_id: user_id },
                                      accesses:  { permision: "ADM" }
                                    )
                                    .exists?
    [positionjob_name, department_name, check_pros]
  end
# end
# Huy
  # Hàm tính toán thời gian làm việc giữa ngày bắt đầu hợp đồng và hiện tại (thâm niên)
  def calculate_time_work(start_date, end_date)
    years  = end_date.year  - start_date.year
    months = end_date.month - start_date.month
    days   = end_date.day   - start_date.day
    if days.negative?
      prev_month = end_date.prev_month
      days  += Time.days_in_month(prev_month.month, prev_month.year)
      months -= 1
    end
    if months.negative?
      years  -= 1
      months += 12
    end
    data = []
    data << "#{years} năm"   if years.positive?
    data << "#{months} tháng" if months.positive? || years.positive?
    data << "#{days} ngày"    if days.positive? || (years.zero? && months.zero?)
    data.join(" ")
  end

  # Hàm chuyển đổi thời gian thành chuỗi "x giây trước", "x phút trước", "x giờ trước", "x ngày trước"
  def time_ago_in_words(time)
    seconds_ago = (Time.current.in_time_zone('Asia/Ho_Chi_Minh') - time).to_i
    case seconds_ago
    when 0..59
      {
        time: "#{seconds_ago}",
        scode: "seconds_ago"
      }
    when 60..3599
      minutes = (seconds_ago / 60).to_i
      {
        time: "#{minutes}",
        scode: "minute_ago"
      }
    when 3600..86_399
      hours = (seconds_ago / 3600).to_i
      {
        time: "#{hours}",
        scode: "hour_ago"
      }
    else
      days = (seconds_ago / 86_400).to_i
      {
        time: "#{days}",
        scode: "day_ago"
      }
    end
  end

  # Lấy sơ đồ theo đơn vị chủ quản
  def stream_connect_by_status_code(scode,status = nil,result = nil)
    connects = Connect.select("connects.forms,connects.status, connects.idenfity,de.scode as department_scode,de.name as department_name,de.id as department_id")
                      .joins(:stream)
                      .joins("LEFT JOIN departments as de ON de.id = connects.nend")
                      .where("streams.scode LIKE :scode", scode: "%#{scode}%")
                      # .joins("INNER JOIN operstreams ON operstreams.stream_id = streams.id")
                      # .where(operstreams: { organization_id: org_id})

    next_connects = nil
    if status.nil? || status.empty?
      next_connects = connects.select{|connect| connect&.idenfity&.include?("1-")}
    else
      next_connects = if result.nil?
                        connects.select{|connect| connect.status == status}
                      else
                        connects.select{|connect| connect.status == status && connect.idenfity.split("-")[1] == result}
                      end
    end
    next_connects.map do |connect|
      idenfity = connect.idenfity.split("-")
      step = idenfity[1] == "rejected" ? -1 : 1
      next_step = idenfity[0].to_i + step
      next_connect = connects.select{|connect| connect&.idenfity&.include?("#{next_step}-")}.first
      {
        forms: connect.forms,
        status: connect.status,
        result: idenfity[1],
        next_department_scode: connect.department_scode,
        next_department_name: connect.department_name,
        next_department_id: connect.department_id,
        next_status: next_connect&.status
      }
    end
  end

  # Kiểm tra quyền hạn
  def is_check_permission(resource_code, permision_code, permisions)
    permisions.any?{ |permision|  (permision['resource'] == resource_code && permision['permission'] == permision_code) ||
                                              (permision['resource'] == resource_code && permision['permission'] == "ADM")}
  end

  # Lấy danh sách người quản lý theo phòng ban, đơn vị chủ quản
  def get_managers_by_department(department_id, organization_id, not_user_id, check_leader = false)
    if check_leader
      keywords = ["Trưởng", "Giám đốc", "Chủ tịch", "Trưởng phòng", "Chánh"]
      not_keywords = ["Phó", "Tổ"]
    else
      keywords = ["Trưởng", "Phó", "Giám đốc", "Chủ tịch", "Trưởng phòng", "Chánh"]
      not_keywords = ["Tổ"]
    end

    all_users = User.joins(:uorgs, works: { positionjob: :department })
                    .where(users: {staff_status: ["Đang làm việc", "DANG-LAM-VIEC"]}, uorgs: {organization_id: organization_id})
                    .where.not(users: {status: 'INACTIVE', id: not_user_id})
                    .where(departments: { id: department_id })
                    .where(keywords.map { |k| "LOWER(positionjobs.name) LIKE ?" }.join(" OR "), *keywords.map { |k| "%#{k.downcase}%" })
                    .order("CONCAT(users.last_name, ' ', users.first_name) ASC")
                    .distinct

    all_users = all_users.where.not(not_keywords.map { |k| "LOWER(positionjobs.name) LIKE ?" }.join(" OR "), *not_keywords.map { |k| "%#{k.downcase}%" }) if !check_leader
    all_users
  end

  # Kiểm tra xem vị trí công việc có phải là vị trí quản lý hay không
  def is_manager_position(positionjob_scode, check_leader = false)

    if check_leader
      keywords = ["Trưởng", "Giám đốc", "Chủ tịch", "Trưởng phòng", "Chánh"]
      not_keywords = ["Phó", "Tổ"]
    else
      keywords = ["Trưởng", "Phó", "Giám đốc", "Chủ tịch", "Trưởng phòng", "Chánh"]
      not_keywords = ["Tổ"]
    end

    has_not_keyword = false

    has_keyword = keywords.any? { |keyword|
      positionjob_scode&.downcase&.strip&.unicode_normalize(:nfc).include?(keyword&.downcase&.strip&.unicode_normalize(:nfc))
    }

    if check_leader
      has_not_keyword = not_keywords.any? { |not_keyword|
        positionjob_scode&.downcase&.strip&.unicode_normalize(:nfc).include?(not_keyword&.downcase&.strip&.unicode_normalize(:nfc))
      }
    end

    has_keyword && !has_not_keyword
  end

  # Hàm lọc người dùng có ngày nghỉ phép trùng với ngày hôm nay
  def users_holiday_with_today(users)
    today = Date.current
    current_hour = Time.current.hour
    current_year = Date.current.year

    users.reject do |user|
      holiday = Holiday.find_by(user_id: user[:id], year: current_year)
      next false unless holiday

      Holprosdetail
        .where(holpros_id: Holpro.where(holiday_id: holiday.id).pluck(:id))
        .any? do |detail|
          next false if detail.details.blank?

          detail.details.split("$$$").any? do |entry|
            date_part, time_part = entry.split("-")
            date = Date.strptime(date_part, "%d/%m/%Y") rescue nil
            next false unless date == today

            case time_part
            when "ALL" then true
            when "AM"  then current_hour < 12
            when "PM"  then current_hour >= 12
            else false
            end
          end
        end
    end
  end

  def update_holiday_balance(holpro, status = "registered", finish = false)
    return unless holpro
    # Parse details to extract leave days and their values (ALL = 1, AM/PM = 0.5)
    leave_days = Holprosdetail
                  .where(holpros_id: holpro.id, sholtype: ["NGHI-PHEP", "NGHI-CHE-DO"])
                  .pluck(:itotal)
                  .compact
                  .sum(&:to_f)

    return if leave_days.zero?
    holiday = Holiday.find_by(id: holpro.holiday_id)
    return unless holiday
    holdetails = Holdetail.where(holiday_id: holiday.id)
    return unless holdetails.any?
    # Parse details to get individual leave dates and their weights
    leave_dates = []
    holpro&.holprosdetails&.pluck(:details).each do |detail_entry|
      detail_entry.split("$$$").each do |detail|
        date, period = detail.split("-")
        next unless date && period
        begin
          date = Date.parse(date)
          weight = (period == "ALL" ? 1.0 : 0.5)
          leave_dates << { date: date, weight: weight }
        rescue Date::Error
          next
        end
      end
    end
    remaining_leave_days = leave_days
    if status == "rejected"
      # Trả lại số ngày nghỉ nếu đơn bị từ chối
      # Ưu tiên trừ used của "Phép thâm niên" và "Phép vị trí" trước, sau đó mới đến "Phép tồn"
      non_phep_ton = holdetails.where.not(name: "Phép tồn")
      phep_ton = holdetails.find_by(name: "Phép tồn")

      # Trừ used của các phép không phải Phép tồn trước
      non_phep_ton.each do |hd|
        next unless remaining_leave_days > 0
        used = hd.used.to_f rescue 0.0
        amount_to_subtract = [used, remaining_leave_days].min
        new_used = [used - amount_to_subtract, 0].max
        hd.update(used: new_used.to_s) if !finish
        remaining_leave_days -= amount_to_subtract
      end

      # Trừ used của Phép tồn (nếu còn leave_days và ngày nghỉ <= dtdeadline)
      if phep_ton && remaining_leave_days > 0 && phep_ton.dtdeadline
        used = phep_ton.used.to_f rescue 0.0
        leave_dates.each do |ld|
          next unless remaining_leave_days > 0
          next unless ld[:date] <= phep_ton.dtdeadline
          amount_to_subtract = [used, ld[:weight], remaining_leave_days].min
          new_used = [used - amount_to_subtract, 0].max
          phep_ton.update(used: new_used.to_s) if !finish
          remaining_leave_days -= amount_to_subtract
          used = new_used
        end
      end
      holiday.update(used: (holiday.used.to_f - leave_days).to_s) if finish
    else
      # Cộng số ngày nghỉ nếu đơn được duyệt/đang chờ
      # Ưu tiên cộng used cho "Phép tồn" trước, sau đó đến các phép khác
      phep_ton = holdetails.find_by(name: "Phép tồn")
      non_phep_ton = holdetails.where.not(name: "Phép tồn")

      # Cộng used cho Phép tồn trước (nếu ngày nghỉ <= dtdeadline)
      if phep_ton && remaining_leave_days > 0 && phep_ton.dtdeadline
        used = phep_ton.used.to_f rescue 0.0
        amount = phep_ton.amount.to_f rescue 0.0
        leave_dates.each do |ld|
          next unless remaining_leave_days > 0
          next unless ld[:date] <= phep_ton.dtdeadline
          amount_to_add = [amount - used, ld[:weight], remaining_leave_days].min
          new_used = used + amount_to_add
          phep_ton.update(used: new_used.to_s) if !finish
          remaining_leave_days -= amount_to_add
          used = new_used
        end
      end

      # Cộng used cho các phép không phải Phép tồn
      non_phep_ton.each do |hd|
        next unless remaining_leave_days > 0
        used = hd.used.to_f rescue 0.0
        amount = hd.amount.to_f rescue 0.0
        amount_to_add = [amount - used, remaining_leave_days].min
        new_used = used + amount_to_add
        hd.update(used: new_used.to_s) if !finish
        remaining_leave_days -= amount_to_add
      end
      holiday.update(used: (holiday.used.to_f + leave_days).to_s) if finish
    end
  end

  def custom_round(value)
    value.to_i == value ? value.to_i : value
  end
  def send_notify(sender_id, stype, approved_by)
    current_user = User.find_by(id: sender_id)
    user_name = "#{current_user.last_name} #{current_user.first_name} (#{current_user.sid})"
    notify = Notify.create(
      title: "Thông báo gửi đề xuất chấm công",
      contents: "Nhân viên <strong>#{user_name}</strong> đã gửi đề xuất <strong>#{REQUEST_TYPE_NAMES[stype.upcase] || stype.titleize}</strong>.<br>",
      receivers: "Hệ thống ERP",
      senders: user_name,
      stype: "SHIFTISSUE",
      )
    Snotice.create(
      notify_id: notify.id,
      user_id: approved_by,
      isread: false,
      username: nil
    )
  end
  REQUEST_TYPE_NAMES = {
      "EARLY-CHECK-OUT" => "Về sớm",
      "LATE-CHECK-IN" => "Đi trễ",
      "SHIFT-CHANGE" => "Đổi ca",
      "SHIFT-CHANGE-APPROVED" => "Bị đổi ca",
      "ADDITIONAL-CHECK-OUT" => "Chấm công tan làm bù",
      "ADDITIONAL-CHECK-IN" => "Chấm công vào làm bù",
      "UPDATE-SHIFT" => "Cập nhật ca",
      "WORK-TRIP" => "Công tác",
      "EDIT-PLAN" => "Chỉnh sửa kế hoạch làm việc"
    }.freeze

  def custom_round_number(value)
    decimal_part = (value * 10).to_i % 10
    # Nếu chữ số đầu tiên >= 5, làm tròn lên, ngược lại làm tròn xuống
    decimal_part >= 5 ? value.ceil : value.floor
  end

  def upload_file(file)
    ApplicationController.new.upload_document_api(file)
  end

  def call_api(path)
    ApplicationController.new.call_api(path)
  end

  def is_day_off(user_id, date_str)
    target_date = Date.parse(date_str).strftime("%d/%m/%Y")
    holiday = Holiday.find_by(user_id: user_id, year: Date.current.year.to_s)
    return false unless holiday
    holpro_ids = Holpro.where(holiday_id: holiday.id)
                       .where.not(status: "TEMP")
                       .pluck(:id)
    return false if holpro_ids.empty?
    Holprosdetail.where(holpros_id: holpro_ids).find_each do |record|
      details = record.details.to_s.split("$$$")
      return true if details.any? { |entry| entry.start_with?(target_date) }
    end
    false
  end

  def workshift_code_map
    Workshift.pluck(:name, :id).map { |name, id| [slugify(name), id] }.to_h
  end

  def find_shift(user_id, date, workshift_id, include_day_off: false)
    # Tìm scheduleweek chứa ngày đó của user
    scheduleweek = Scheduleweek
                     .where(user_id: user_id)
                     .where("start_date <= ? AND end_date >= ?", date, date.beginning_of_day)
                     .first

    return nil unless scheduleweek

    Shiftselection.where(
      scheduleweek_id: scheduleweek.id,
      workshift_id: workshift_id,
      work_date: date.to_date.beginning_of_day..date.to_date.end_of_day
    ).where("is_day_off IS NULL OR is_day_off != ?", "OFF").first
  end

  def get_shiftselection_by_id(id)
    shift = Shiftselection
              .includes(:scheduleweek)
              .select(:id, :workshift_id, :work_date, :start_time, :end_time, :scheduleweek_id)
              .find(id)
    workshift = Workshift.where(id: shift.workshift_id).pluck(:name).first
    user = User.find_by(id: shift.scheduleweek&.user_id)
    user_name = user ? "#{user.last_name} #{user.first_name} (#{user.sid})" : ""
    {
      workshift: workshift,
      start_time:   shift.start_time,
      end_time:     shift.end_time,
      work_date:    shift.work_date.strftime('%d/%m/%Y'),
      user_name:    user_name
    }
  end

  # Tìm ca trong ngày theo user qua scheduleweeks
  def shifts_in_day(user_id, date)
    Shiftselection
      .joins(:scheduleweek)
      .where(scheduleweeks: { user_id: user_id })
      .where(work_date: date.beginning_of_day..date.end_of_day)
      .to_a
  end

  ##Trong_lq
  # xử lý duyệt đổi ca: tìm các ca cần đổi và trả về thông tin đầy đủ
  # Mục tiêu:
  # - Tìm tất cả các ca làm liên quan đến đề xuất đổi ca giữa 2 người
  # - Bao gồm: ca làm trong tuần hiện tại và các ca cùng ngày ở tuần đối ứng
  # - Trả về cấu trúc dữ liệu gồm 2 nhóm: original_user_shifts và target_user_shifts,
  #   phục vụ cho thao tác swap dữ liệu ca làm.
  def process_shiftissue_change(shiftissue, status)
    return unless status == "APPROVED"

    shift_a = Shiftselection.find_by(id: shiftissue.shiftselection_id)
    shift_b = Shiftselection.find_by(id: shiftissue.ref_shift_changed)
    return if shift_a.nil? || shift_b.nil?

    work_date_a = shift_a.work_date
    work_date_b = shift_b.work_date

    workshift_id_a = shift_a.workshift_id
    workshift_id_b = shift_b.workshift_id

    # tìm chính xác ca cần đổi theo ngày và tuần
    shift_need_change_a = Shiftselection.where(
      work_date: work_date_a,
      workshift_id: workshift_id_a,
      scheduleweek_id: shift_a.scheduleweek_id
    )

    shift_need_change_b = Shiftselection.where(
      work_date: work_date_b,
      workshift_id: workshift_id_b,
      scheduleweek_id: shift_b.scheduleweek_id
    )

    # === bổ sung: tìm các shift cùng ngày nhưng ở tuần còn lại ===
    other_a = Shiftselection.where(
      work_date: work_date_b,
      workshift_id: workshift_id_a,
      scheduleweek_id: shift_a.scheduleweek_id
    )
    other_b = Shiftselection.where(
      work_date: work_date_a,
      workshift_id: workshift_id_b,
      scheduleweek_id: shift_b.scheduleweek_id
    )

    # === format kết quả đầy đủ thông tin ===
    original_user_shifts = {}
    original_user_shifts[work_date_a.to_s] = shift_need_change_a.map do |s|
      { id: s.id, work_date: s.work_date, workshift_id: s.workshift_id, scheduleweek_id: s.scheduleweek_id, is_day_off: s.is_day_off }
    end
    original_user_shifts[work_date_b.to_s] = other_a.map do |s|
      { id: s.id, work_date: s.work_date, workshift_id: s.workshift_id, scheduleweek_id: s.scheduleweek_id, is_day_off: s.is_day_off }
    end if other_a.exists?

    target_user_shifts = {}
    target_user_shifts[work_date_b.to_s] = shift_need_change_b.map do |s|
      { id: s.id, work_date: s.work_date, workshift_id: s.workshift_id, scheduleweek_id: s.scheduleweek_id, is_day_off: s.is_day_off }
    end
    target_user_shifts[work_date_a.to_s] = other_b.map do |s|
      { id: s.id, work_date: s.work_date, workshift_id: s.workshift_id, scheduleweek_id: s.scheduleweek_id, is_day_off: s.is_day_off }
    end if other_b.exists?

    {
      original_user_shifts: original_user_shifts,
      target_user_shifts: target_user_shifts
    }
  end

    # xử lý nhóm dữ liệu đổi ca theo ngày
    def group_by_date(result_array)
      grouped = {}
      result_array.each do |record|
        record.each do |person, shifts_by_date|
          shifts_by_date.each do |date, shifts|
            date_key = date.to_date.to_s

            # Khởi tạo khung dữ liệu theo ngày
            grouped[date_key] ||= {
              "work_date" => date_key,
              "original_user_shifts" => [],
              "target_user_shifts" => []
            }

            # Merge dữ liệu theo từng người
            grouped[date_key][person.to_s] += shifts.map do |s|
              {
                id: s[:id],
                work_date: s[:work_date],
                workshift_id: s[:workshift_id],
                scheduleweek_id: s[:scheduleweek_id],
                is_day_off: s[:is_day_off]
              }
            end
          end
        end
      end

      grouped.values
    end

    # Hoán đổi ca giữa người dùng theo ngày
    # Hàm này thực hiện việc hoán đổi `id` và `is_day_off` giữa các ca làm (workshift)
    def swap_cross_day(data_array)
      return [] unless data_array.is_a?(Array)

      data_array.map do |date|
        a = date["original_user_shifts"].map(&:dup)
        b = date["target_user_shifts"].map(&:dup)
        test = []
        a.each do |a_item|
          # Tìm phần tử tương ứng theo workshift_id bên target_user_shifts
          b_item = b.find { |bi| bi[:workshift_id] == a_item[:workshift_id] }
          if !b_item[:id].nil?
            # Swap ID giữa a_item và b_item
            a_item[:id], b_item[:id] = b_item[:id], a_item[:id]
             # Swap is_day_off giữa a_item và b_item
            a_item[:is_day_off], b_item[:is_day_off] = b_item[:is_day_off], a_item[:is_day_off]
          end
        end

        {
          "work_date" => date["work_date"],
          "original_user_shifts" => a,
          "target_user_shifts" => b
        }
      end
    end

    # Phân loại các ca làm thuộc các đề xuất đổi ca (SHIFT-CHANGE) chưa được duyệt, dựa vào dữ liệu đã hoán đổi ID(update swape ca).
    # Mục đích:
    # - Duyệt qua toàn bộ các ca sau khi đã hoán đổi ID
    # - Với mỗi ca, tìm ra:
    #   + Bản ghi đề xuất đổi ca tương ứng trong bảng Shiftissue (status khác "APPROVED")
    #   + Ca đối ứng trong tuần khác, khác ngày, cùng workshift_id (để có thể cập nhật lại shiftselection_id cho hợp lý)
    def classify_shift_change_cases_before_swap(swapped_array)
      data = []

      # Gom tất cả ca từ các ngày
      all_shifts = swapped_array.flat_map do |day|
        (day["original_user_shifts"] || []) + (day["target_user_shifts"] || [])
      end

      # Xử lý từng ca
      all_shifts.each do |row|
        original_id = row[:id]
        next unless original_id
        # Tìm đề xuất đổi ca
        issue = Shiftissue.where(shiftselection_id: original_id, stype: "SHIFT-CHANGE")
                          .where.not(status: "APPROVED")
                          .first
        next unless issue

        # # Tìm ca còn lại (cùng người nhưng khác ngày):
        # self_shift_other_day = all_shifts.find do |s|
        #   s[:workshift_id] == row[:workshift_id] &&
        #   s[:scheduleweek_id] == row[:scheduleweek_id] &&
        #   s[:id] != original_id &&
        #   s[:work_date].to_date != row[:work_date].to_date
        # end
        # next unless self_shift_other_day

        # ca_doi_cung_ngay_cung_tuan
        # find_cross_week_same_day_partner = all_shifts.find do |s|
        #   s[:workshift_id] == row[:workshift_id] &&
        #   s[:scheduleweek_id] != row[:scheduleweek_id] &&
        #   s[:work_date].to_date == row[:work_date].to_date
        # end

        # Code cũ - @author: trong.lq @date: 16/01/2025
        # ca_doi_khac_ngay_khac_tuan (TH1: Khác ngày, khác tuần)
        cross_week_diff_day_partner = all_shifts.find do |s|
          s[:workshift_id] == row[:workshift_id] &&
          s[:scheduleweek_id] != row[:scheduleweek_id] &&
          s[:work_date].to_date != row[:work_date].to_date
        end

        # Code mới - @author: trong.lq @date: 16/01/2025
        # ca_doi_cung_ngay_khac_tuan (TH2: Cùng ngày, khác tuần)
        cross_week_same_day_partner = all_shifts.find do |s|
          s[:workshift_id] == row[:workshift_id] &&
          s[:scheduleweek_id] != row[:scheduleweek_id] &&
          s[:work_date].to_date == row[:work_date].to_date
        end

        # Ưu tiên dùng TH1 (khác ngày), nếu không có thì dùng TH2 (cùng ngày)
        partner_shift = cross_week_diff_day_partner || cross_week_same_day_partner

        # Bỏ qua nếu không tìm thấy ca đổi
        next unless partner_shift

        data << {
          issue_id: issue.id,
          workshift_id: row[:workshift_id],
          original_id: original_id,
          original_date: row[:work_date],
          # Code cũ - @author: trong.lq @date: 16/01/2025
          # self_shift_other_day_id: self_shift_other_day[:id],
          # self_shift_other_day_date: self_shift_other_day[:work_date],
          # Code cũ - @author: trong.lq @date: 16/01/2025
          cross_week_diff_day_partner_id: cross_week_diff_day_partner&.dig(:id),
          cross_week_diff_day_partner_other_date: cross_week_diff_day_partner&.dig(:work_date),
          # Code mới - @author: trong.lq @date: 16/01/2025
          cross_week_same_day_partner_id: cross_week_same_day_partner&.dig(:id),
          cross_week_same_day_partner_date: cross_week_same_day_partner&.dig(:work_date),
          # Partner shift được chọn (ưu tiên TH1, nếu không có thì TH2)
          partner_shift_id: partner_shift[:id],
          partner_shift_date: partner_shift[:work_date],
        }
      end

      data
    end

        #Cập nhật lại kế hoạch khi duyệt đề xuất đổi ca
        def force_update_by_swapped_data(swapped_array)
          updated = []
          ActiveRecord::Base.transaction do
            begin
              swapped_array.each do |day|
                %w[original_user_shifts target_user_shifts].each do |group|
                  (day[group] || []).each do |row|
                    id = row[:id]
                    next unless id
                    # Xóa các đề xuất cũ liên quan đến id này(trừ khi là Đổi ca)
                    Shiftissue.where(shiftselection_id: id).where.not(stype: "SHIFT-CHANGE").destroy_all
                     # Chuẩn hóa dữ liệu trước khi update
                    scheduleweek_id = row[:scheduleweek_id]
                    is_day_off = row[:is_day_off].presence
                    # Cập nhật Shiftselection với id tương ứng
                    update_result = Shiftselection.where(id: id).update_all(
                      scheduleweek_id: row[:scheduleweek_id],
                      is_day_off: row[:is_day_off]
                    )
                    log_data = {
                      id: id,
                      scheduleweek_id: scheduleweek_id,
                      is_day_off: is_day_off,
                      updated_at: Time.current,
                      updated: update_result
                    }
                    updated << log_data
                  end
                end
              end
            end
          rescue ActiveRecord::RecordNotFound => e
            raise ActiveRecord::Rollback # Hoàn tác toàn bộ nếu không tìm thấy bản ghi
          rescue StandardError => e
            raise ActiveRecord::Rollback # Hoàn tác toàn bộ nếu có lỗi khác
          end
          updated # Trả về danh sách đã cập nhật
        end

    #Cập nhật đề xuất đổi ca từ các trường hợp đã phân loại
    def update_shift_issues_with_classified_cases(data_array)
      results = []

      data_array.each do |row|
        issue_id = row[:issue_id]
        # Code cũ - @author: trong.lq @date: 16/01/2025
        # Ưu tiên dùng TH1 (khác ngày), nếu không có thì dùng TH2 (cùng ngày)
        shift_1 = row[:partner_shift_id] || row[:cross_week_diff_day_partner_id] || row[:cross_week_same_day_partner_id]
        shift_2 = row[:original_id]
        issue = Shiftissue.find_by(id: issue_id)
        shift_1_exists = Shiftselection.exists?(id: shift_1)
        shift_2_exists = Shiftselection.exists?(id: shift_2)
        issue.update(
              shiftselection_id: shift_1,
              ref_shift_changed: shift_2,
              status: "APPROVED",
        )

        issue_clone = Shiftissue.create(
          shiftselection_id: shift_2,
          ref_shift_changed: shift_1,
          stype: "SHIFT-CHANGE-APPROVED",
          content: "Bản ghi clone tự động sau duyệt đổi ca",
          status: "APPROVED",
          note: "bị đổi ca",
          us_start: issue.us_start,
          us_end: issue.us_end,
          approved_by: issue.approved_by,
          approved_at: issue.approved_at,
          created_at: Time.current,
          updated_at: Time.current
        )

        attrs = {
          shiftselection_id: shift_2,
          ref_shift_changed: shift_1,
          us_start: issue.us_start,
          us_end: issue.us_end,
          approved_by: issue.approved_by,
          approved_at: issue.approved_at,
        }

        unless issue_clone.persisted?
          error!({
            msg: "Tạo bản ghi clone thất bại",
            errors: issue_clone.errors.full_messages,
            debug: attrs
          }, 422)
        end

        results << {
          issue_id: issue_id,
          valid_issue: issue.present?,
          shift_1_id: shift_1,
          shift_1_exists: shift_1_exists,
          shift_2_id: shift_2,
          shift_2_exists: shift_2_exists,
          ready_to_update: issue.present? && shift_1_exists && shift_2_exists
        }
      end

      results
    end

    # Kiểm tra ngày tạo đề xuất.
    def validate_attend_request_conditions(user_id, date, workshift_id,  request_type)
      # 1. Ngày không thuộc tháng hiện tại
      today = Time.zone.today
      # unless date.month == today.month && date.year == today.year
      #   return "Không thể tạo đề xuất cho tháng khác tháng hiện tại"
      # end
      # Chỉ kiểm tra nếu không phải work-trip shift-change
      return true if %w[work-trip shift-change compensatory-leave].include?(request_type)
      # 2. Tìm ca làm việc tại ngày đó
      # shift = find_shift(user_id, date, workshift_id, include_day_off: true)
      shift = find_shift(user_id, date, workshift_id)
      return "Không có ca làm việc tại ngày #{date.strftime('%d/%m/%Y')}" unless shift

      # 3. Kiểm tra loại nghỉ
      if shift.is_day_off == "OFF"
        return "Không thể tạo đề xuất vì là ngày nghỉ cố định"
      elsif shift.is_day_off == "HOLIDAY"
        return "Không thể tạo đề xuất vì là ngày nghỉ lễ"
      elsif shift.is_day_off == "ON-LEAVE"
        return "Không thể tạo đề xuất vì đang nghỉ phép"
      end

      return true
    end
# Huy


# Role nghỉ phép tạm thời
    # def fetchStaffForWorkflowLeave(user_id: nil)
    #   organization_name = Organization.where(id: User.find(user_id).uorgs.pluck(:organization_id)).pluck(:scode)
    #   leader_roles = ["trưởng","trưởng", "phó", "giám đốc", "hiệu", "chánh", "chủ tịch", "phụ trách"]

    #   next_user_to_handle = []
    #   users_have_access = []
    #   department_id = ""

    #   if (organization_name & ["BMU", "BMTU"]).any?
    #     department_ids = handle_in_bmu_leave(user_id)[:department_ids]
    #     users_have_access = handle_in_bmu_leave(user_id)[:users_have_access]
    #   else
    #     department_ids = handle_in_buh_leave(user_id)[:department_ids]
    #     users_have_access = handle_in_buh_leave(user_id)[:users_have_access]
    #   end

    #   next_user_to_handle = Work.left_outer_joins({positionjob: :department}, :user)
    #                             .where("positionjobs.name LIKE ? OR positionjobs.name LIKE ? OR positionjobs.name LIKE ? OR positionjobs.name LIKE ? OR positionjobs.name LIKE ?", "%trưởng%", "%phó%", "%giám đốc%", "%chủ tịch%", "chánh")
    #                             .where(positionjobs: {department_id: department_ids})
    #                             .where.not("users.status = ? OR users.staff_status = ?", "INACTIVE", "Nghỉ việc")
    #                             .pluck("positionjobs.department_id", "departments.name as department_name", "works.user_id", "CONCAT(users.last_name, ' ', users.first_name) as name").uniq
    #                             .map { |department_id, department_name, user_id, name| { id: user_id.to_s, name: name } }

    #   next_user_to_handle = next_user_to_handle + users_have_access

    #   next_user_to_handle = next_user_to_handle.flatten.reject(&:empty?)
    #   next_user_to_handle = next_user_to_handle.uniq.reject { |user| user[:id] == user_id }
    #   return next_user_to_handle.flatten
    # end

    # Role nghỉ phép tạm thời
    def fetchStaffForWorkflowLeave(user_id: nil)
      # Phân nhánh theo tổ chức
      org_codes = Organization.where(id: User.find(user_id).uorgs.pluck(:organization_id)).pluck(:scode)


        if (org_codes & ["BMU", "BMTU"]).any?
          data = handle_in_bmu_leave(user_id)
          check_org = "BMU"
        else
          data = handle_in_buh_leave(user_id)
          check_org = "BUH"
        end

      department_ids    = Array(data[:department_ids]).flatten.compact.uniq
      users_have_access = normalize_user_minimal(data[:users_have_access])

      # Lấy lãnh đạo (trưởng/phó/giám đốc/chánh/chủ tịch) theo phòng/ban đích
      leaders = []
      if department_ids.present? && check_org == "BMU"
        leaders = Work
          .left_outer_joins({ positionjob: :department }, :user)
          .where(positionjobs: { department_id: department_ids })
          .where(
            "positionjobs.name LIKE :t OR positionjobs.name LIKE :p OR positionjobs.name LIKE :gd OR positionjobs.name LIKE :ct OR positionjobs.name LIKE :ch",
            t: "%trưởng%", p: "%phó%", gd: "%giám đốc%", ct: "%chủ tịch%", ch: "chánh"
          )
          .where.not("users.status = ? OR users.staff_status = ?", "INACTIVE", "Nghỉ việc")
          .pluck("works.user_id", "CONCAT(users.last_name, ' ', users.first_name)")
          .map { |uid, name| { id: uid.to_s, name: name } }
      end

      # Gộp & chuẩn hóa & loại bỏ bản thân
      # result = normalize_user_minimal(leaders) + users_have_access
      # result = normalize_user_minimal(result) # de-dup theo id
      # result = result.reject { |u| u[:id].to_s == user_id.to_s }
      # result

      result = normalize_user_minimal(leaders) + users_have_access
      result = normalize_user_minimal(result) # de-dup theo id
      result = result.reject { |u| u[:id].to_s == user_id.to_s }

      # --- special case: BGD(BUH) gửi PTCHC(BUH) và chỉ còn 1 người ---
      caller_faculty = fetch_leaf_departments_by_user(user_id).first&.faculty
      send_to_ptchc  = Department.where(id: department_ids).where(faculty: "PTCHC(BUH)").exists?

      if caller_faculty == "BGD(BUH)" && result.size == 1
        result[0] = result[0].merge(name: "Phòng Tổ chức - Hành chính - Quản trị ")
      end
      # --- end special case ---

      result

    end

    def handle_in_buh_leave(user_id)
      users_have_access = []
      department_ids    = []

      # DS [positionjob_id, department_id] của user
      pj_dept_pairs = get_positionjob_department_ids_of_user_leave(user_id)[:valid].uniq

      pj_dept_pairs.each do |pj_id, dept_id|
        department   = Department.find_by(id: dept_id)
        position_job = Positionjob.find_by(id: pj_id)
        next unless department && position_job

        # Có người có quyền duyệt trong đơn vị?
        has_approver_in_dept = get_users_have_access_leave(dept_id) # có thể trả [] hoặc list hash
        is_leader            = check_permission_approve_leave(user_id).present?

        if is_leader
          if department.parents.blank?
            case department.faculty
            when "BGD(BUH)"
              nextStepData = stream_connect_by_status_code("DUYET-PHEP-BUH", "TCHC-APPROVE")
              users_have_access << normalize_user_minimal(get_users_have_access_leave(nextStepData.first[:next_department_id], "READ"))
            when "PTCHC(BUH)"
              next_step   = stream_connect_by_status_code("DUYET-PHEP-BUH", "BOARD-APPROVE")
              next_dept   = next_step&.first&.dig(:next_department_id)
              department_ids << next_dept if next_dept.present?
              users_have_access << normalize_user_minimal(get_users_have_access_leave(next_dept, "ADM")) if next_dept.present?
            else
              next_step = stream_connect_by_status_code("DUYET-PHEP-BUH")
              tchc_id   = next_step&.first&.dig(:next_department_id)
              users_have_access += normalize_user_minimal(get_users_have_access_leave(tchc_id, "READ")) if tchc_id.present?
            end
          else
            # Có đơn vị cha
            users_have_access += normalize_user_minimal(get_users_have_access_leave(department.parents.to_i))
          end
        else
          if has_approver_in_dept.present?
            # Gửi cho lãnh đạo đơn vị hiện tại
            users_have_access += normalize_user_minimal(get_users_have_access_leave(department.id))
          elsif department.parents.present?
            # Đẩy lên đơn vị cha
            users_have_access += normalize_user_minimal(get_users_have_access_leave(department.parents.to_i))
          end
        end
      end

      { department_ids: department_ids.flatten.compact.uniq, users_have_access: normalize_user_minimal(users_have_access) }
    end

    def handle_in_bmu_leave(user_id)
      users_have_access = []
      department_ids    = []

      leader_roles = ["trưởng","trưởng", "phó", "giám đốc", "hiệu", "chánh", "chủ tịch", "phụ trách"]
      pj_dept_pairs = get_positionjob_department_ids_of_user_leave(user_id)[:valid].uniq

      pj_dept_pairs.each do |pj_id, dept_id|
        department   = Department.find_by(id: dept_id)
        position_job = Positionjob.find_by(id: pj_id)
        next unless department && position_job

        has_leader_role = check_have_leader_leave(department.id, leader_roles)

        normalized_name = position_job.name.to_s.downcase.unicode_normalize(:nfkc)
        is_pho          = normalized_name.include?("phó".unicode_normalize(:nfkc))
        is_leader_title = leader_roles.any? { |kw| normalized_name.include?(kw.downcase.unicode_normalize(:nfkc)) && !normalized_name.include?("phó trưởng") }

        if !is_leader_title
          if !has_leader_role
            if department.parents.blank?
              next_step = stream_connect_by_status_code("DUYET-PHEP-BMU", "BOARD-APPROVE")
              department_ids << next_step&.first&.dig(:next_department_id)
            else
              department_ids << department.parents.to_i
            end
          else
            base = Work.joins({positionjob: :department}, :user)
                      .where(positionjobs: {department_id: department.id})
                      .where.not("users.status = ? OR users.staff_status = ?", "INACTIVE", "Nghỉ việc")

            if is_pho
              base = base.where("positionjobs.name LIKE ? AND positionjobs.name NOT LIKE ?", "%trưởng%", "%phó trưởng%")
              if !base.exists?
                next_step = stream_connect_by_status_code("DUYET-PHEP-BMU", "BOARD-APPROVE")
                department_ids << next_step&.first&.dig(:next_department_id)
                base = nil
              end
            end

            if base
              base = base.where("positionjobs.name LIKE ? OR positionjobs.name LIKE ? OR positionjobs.name LIKE ?",
                                "%trưởng%", "%phó%", "%giám đốc%")
              users_have_access += base
                .pluck("works.user_id", "CONCAT(users.last_name, ' ', users.first_name)")
                .map { |uid, name| { id: uid.to_s, name: name } }
            end
          end
        else
          # Là trưởng đơn vị
          if department.parents.blank?
            if normalized_name == "hiệu trưởng".unicode_normalize(:nfkc)
              next_step = stream_connect_by_status_code("NGHI-PHEP-HIEU-TRUONG", "APPROVE")
              department_ids += Array(next_step).map { |i| i[:next_department_id] || i["next_department_id"] }
            else
              next_step = stream_connect_by_status_code("DUYET-PHEP-BMU", "BOARD-APPROVE")
              department_ids << next_step&.first&.dig(:next_department_id)
            end
          else
            department_ids << department.parents.to_i
          end
        end
      end

      { department_ids: department_ids.flatten.compact.uniq, users_have_access: normalize_user_minimal(users_have_access) }
    end


    # end
    # def handle_in_buh_leave(user_id)
    #   users_have_access = []
    #   department_ids = []
    #   leader_roles = ["trưởng","trưởng", "phó", "giám đốc", "hiệu", "chánh", "chủ tịch", "phụ trách"]

    #   # lấy danh sách positionjob_id và department_id của users
    #   positionjob_department_ids = get_positionjob_department_ids_of_user_leave(user_id)[:valid].uniq

    #   positionjob_department_ids.each do |data|

    #     department = Department.find_by(id: data[1])

    #     position_job = Positionjob.find_by(id: data[0])

    #     # TODO: CODE CŨ SẼ XÓA Kiểm tra đơn vị có lãnh đạo không?
    #     # TODO: CODE CŨ SẼ XÓA has_leader_role = has_leader_role = check_have_leader_leave(department.id, leader_roles)

    #     # Kiểm tra đơn vị có lãnh đạo không?
    #     check_have_leader_leave = get_users_have_access_leave(data[1])

    #     # Kiểm tra đơn vị nhân sự có quyền duyệt phép hay không
    #     is_leader = check_permission_approve_leave(user_id).present?

    #     # TODO: CODE CŨ SẼ XÓA Kiểm tra vị trí công việc hiện tại có phải là leader không
    #     # TODO: CODE CŨ SẼ XÓA if leader_roles.any? { |item| position_job.name.downcase.include?(item) }

    #     # Kiểm tra nhân sự có trong danh sách này không? Nếu có trong danh sách quyền mặc định là lãnh đạo phòng
    #     if is_leader.present?
    #       if department.parents.nil? || department.parents == ""
    #         # Đối với đơn vị không có đơn vị cha
    #         case department.faculty
    #         when "BGD(BUH)"
    #           # Nếu là ban giám đốc thì gửi cho các ban giám đốc khác
    #           get_department = Department.where(faculty: "PTCHC(BUH)").first
    #           department_ids << get_department&.id
    #           users_have_access << get_users_have_access_leave(get_department&.id, "READ")
    #         when "PTCHC(BUH)"
    #           # Nếu là phòng TC hành chỉnh thì gửi cho ban giám đốc
    #           nextStepData = stream_connect_by_status_code("DUYET-PHEP-BUH", "BOARD-APPROVE")
    #           department_ids << nextStepData.first[:next_department_id]

    #         else
    #           # Nếu là trưởng phòng đơn vị thì gửi cho trưởng/phó TCHC và nhân sự có quyền
    #           nextStepData = stream_connect_by_status_code("DUYET-PHEP-BUH")
    #           # department_ids << nextStepData.first[:next_department_id]
    #           users_have_access << get_users_have_access_leave(nextStepData.first[:next_department_id], "READ")
    #         end
    #       else
    #         # Tìm đơn vị cha
    #         # department_ids << department.parents.to_i
    #         users_have_access << get_users_have_access_leave(department.parents.to_i)
    #       end
    #     else
    #       if check_have_leader_leave.present?
    #         # Đối với nhân sự thì gửi cho trưởng/phó đơn vị
    #         # department_ids << department.id
    #         # Lấy nhân sự có quyền
    #         users_have_access << get_users_have_access_leave(department.id)
    #       elsif !department.parents.nil? || department.parents != ""
    #         # Tìm đơn vị cha
    #         # department_ids << department.parents.to_i
    #         users_have_access << get_users_have_access_leave(department.parents.to_i)
    #       end
    #     end
    #   end

    #   {department_ids: department_ids, users_have_access: users_have_access}
    # end

    # def handle_in_bmu_leave(user_id)
    #   users_have_access = []
    #   department_ids = []
    #   leader_roles = ["trưởng","trưởng", "phó", "giám đốc", "hiệu", "chánh", "chủ tịch", "phụ trách"]

    #   positionjob_department_ids = get_positionjob_department_ids_of_user_leave(user_id)[:valid].uniq

    #   positionjob_department_ids.each do |data|
    #     department = Department.find_by(id: data[1])

    #     position_job = Positionjob.find_by(id: data[0])

    #     # Kiểm tra đơn vị có lãnh đạo không?
    #     has_leader_role = check_have_leader_leave(department.id, leader_roles)
    #     #
    #     normalized_name = position_job.name.downcase.unicode_normalize(:nfkc)

    #     # Kiểm tra người tạo có phải là phó phòng?
    #     check_pho = normalized_name.include?("phó".unicode_normalize(:nfkc))

    #     # Kiểm tra người tạo có phải là trưởng phòng?
    #     # check_leader = leader_roles.any? { |item| normalized_name.include?(item.unicode_normalize(:nfkc)) }
    #     check_leader = leader_roles.any? do |item|
    #       normalized_item = item.downcase.unicode_normalize(:nfkc)
    #       normalized_name.include?(normalized_item) && !normalized_name.include?("phó trưởng")
    #     end
    #     # check là trưởng phòng và không phải leader
    #     if !check_leader
    #       if !has_leader_role
    #         # Không có lãnh đạo
    #         if department.parents.nil? || department.parents == ""
    #           # nếu không có leader và không có parent
    #           nextStepData = stream_connect_by_status_code("DUYET-PHEP-BMU", "BOARD-APPROVE")
    #           department_ids << nextStepData.first[:next_department_id]
    #         else
    #           # bộ phận không có leader
    #           # Tìm đơn vị cha
    #           department_ids << department.parents.to_i
    #         end
    #       else
    #         # có lãnh đạo
    #         base_query = Work.joins({positionjob: :department}, :user)
    #                                 .where(positionjobs: {department_id: position_job.department_id})
    #                                 .where.not("users.status = ? OR users.staff_status = ?", "INACTIVE", "Nghỉ việc")

    #         # nếu là phó phòng
    #         if check_pho
    #           base_query = base_query.where("positionjobs.name LIKE ? AND positionjobs.name NOT LIKE ? ", "%trưởng%", "%phó trưởng%")
    #           if !base_query.present?
    #             # Không có trưởng đơn vị gửi cho ban giám hiệu
    #             nextStepData = stream_connect_by_status_code("DUYET-PHEP-BMU", "BOARD-APPROVE")
    #             department_ids << nextStepData.first[:next_department_id]
    #             base_query = []
    #           end
    #         end

    #         # Nếu không phải là leader
    #         base_query = base_query.where("positionjobs.name LIKE ? OR positionjobs.name LIKE ? OR positionjobs.name LIKE ?", "%trưởng%", "%phó%", "%giám đốc%") if !check_leader && base_query.present?

    #         # Lấy thông tin users
    #         users_have_access << base_query.select("works.user_id", "CONCAT(users.last_name, ' ', users.first_name) AS name").map { |w| { id: w.user_id.to_s, name: w.name } }
    #       end
    #     else
    #       # nếu không có parent
    #       if department.parents.nil? || department.parents == ""
    #         # nếu là hiệu trưởng
    #         check_principal = normalized_name == "hiệu trưởng".unicode_normalize(:nfkc)
    #         if check_principal
    #           nextStepData = stream_connect_by_status_code("NGHI-PHEP-HIEU-TRUONG", "APPROVE")
    #           department_ids << nextStepData.map { |item| item[:next_department_id] || item["next_department_id"] }
    #         else
    #           # Nếu là trưởng phòng thì gửi cho ban giám hiệu
    #           nextStepData = stream_connect_by_status_code("DUYET-PHEP-BMU", "BOARD-APPROVE")
    #           department_ids << nextStepData.first[:next_department_id]
    #         end
    #       else
    #         # bộ phận không có leader
    #         # Tìm đơn vị cha
    #         department_ids << department.parents.to_i
    #       end
    #     end
    #   end

    #   {department_ids: department_ids, users_have_access: users_have_access.flatten.uniq}
    # end

    def check_have_leader_leave(department_id, leader_roles)
      # lấy danh sách vị trí công việc của đơn vị
      works = Work.joins(:positionjob).where(positionjobs: {department_id: department_id})

      # Lấy tên các vị trí công việc của đơn vị
      all_position_jobs = Positionjob.where(id: works.pluck(:positionjob_id)).pluck(:name)

      # Kiểm tra đơn vị có lãnh đạo không?
      has_leader_role = all_position_jobs.any? { |name| leader_roles.any? { |item| name.downcase.unicode_normalize(:nfkc).include?(item.unicode_normalize(:nfkc)) } }
    end
    # lấy vị trí công việc cuối cùng
    def get_positionjob_department_ids_of_user_leave(user_id)
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
    def get_users_have_access_leave(dpt_id = "", permission = "ADM")
        # Tìm nhân sự có quyền
        user_id = Work.joins(stask: { accesses: :resource })
                    .where(resources: { scode: "APPROVE-REQUEST" }, accesses: {permision: permission}).pluck(:user_id)

        # Lấy thông tin nhân sự có quyền trong department
        users_have_access = Work.joins({positionjob: :department}, :user)
                                .where(user_id: user_id).where.not(positionjob_id: nil)
                                .where.not("users.status = ? OR users.staff_status = ?", "INACTIVE", "Nghỉ việc")
        users_have_access = users_have_access.where(positionjobs: {department_id: dpt_id}) if dpt_id.present?
        users_have_access = users_have_access.select("works.user_id", "CONCAT(users.last_name, ' ', users.first_name) AS name").map { |w| { id: w.user_id.to_s, name: w.name } }
    end

    def check_permission_approve_leave(user_id)
        user_id = Work.joins(stask: { accesses: :resource })
                        .where(resources: { scode: "APPROVE-REQUEST" }, works: {user_id: user_id}, accesses: {permision: "ADM"})
    end


    # Helper method to format numbers
    def format_number(value)
      if value.is_a?(Float) && value.to_i == value
        value.to_i.to_s # Convert to integer and then to string if whole number
      else
        value.to_s # Keep as string if not a whole number
      end
    end

    def local_date(datetime)
      datetime.in_time_zone("Asia/Ho_Chi_Minh").to_date
    end

    def send_shiftissue_notification(shiftissue, final_status, reason)
      result_message = final_status == "APPROVED" ? "được duyệt" : "bị từ chối"
      stypes = {
        "EARLY-CHECK-OUT" => "Về sớm",
        "LATE-CHECK-IN" => "Đi trễ",
        "SHIFT-CHANGE" => "Đổi ca",
        "ADDITIONAL-CHECK-IN" => "Chấm công vào làm bù",
        "ADDITIONAL-CHECK-OUT" => "Chấm công tan làm bù",
        "UPDATE-SHIFT" => "Cập nhật Ca",
        "WORK-TRIP" => "Đi công tác",
        "COMPENSATORY-LEAVE" => "Nghỉ bù"
      }

      notify = Notify.create(
        title: "Thông báo duyệt đề xuất #{stypes[shiftissue.stype]}",
        contents: "Đề xuất #{stypes[shiftissue.stype]} của bạn đã #{result_message}.<br>
                    #{final_status == "REJECTED" ? "<span>Lý do:</span>#{reason}<span>" : ""}",
        receivers: "Hệ thống ERP",
        stype: "SHIFTSELECTION"
      )

      scheduleweek = Scheduleweek.find(Shiftselection.find(shiftissue.shiftselection_id).scheduleweek_id)
      Snotice.create(
        notify_id: notify.id,
        user_id: scheduleweek.user_id,
        isread: false,
        username: nil
      )
    end

    def integer_string?(str)
      str.to_s.match?(/\A[+-]?\d+\z/)
    end


# Role nghỉ phép tạm thời

def approve_leave_cancel(user_id, holpros_id, uhandle_id)
  adjustment_success = false
  msg = ""
  oUser = User.where(id: user_id).first
  full_name = ""
  sid = ""
  if oUser.present?
    full_name = "#{oUser.last_name} #{oUser.first_name}"
    sid = oUser.sid
  end
  holpro = Holpro.find_by(id: holpros_id)
  unless holpro
    return { success: false, msg: "Không tìm thấy đơn nghỉ phép" }
  end
  begin
    o_mandoc_cancel = Mandoc.where(holpros_id: holpros_id, status: "CANCEL-PENDING").first
    if o_mandoc_cancel.present?
      content = "Đơn điều chỉnh của nhân sự: <b>#{full_name}</b> - Mã nhân sự: <b>#{sid}</b> đã được duyệt"
      holpro.update!(status: "CANCEL-DONE")

      list_hpdetail = Holprosdetail.where(holpros_id: holpros_id)
      total_changed_days_phep = 0.0
      total_changed_days = 0.0
      removed_dates = []

      if list_hpdetail.present?
        list_hpdetail.each do |detail|
          original_total = detail.itotal.to_f

          history = Mhistory.where(stable: "holprosdetails$$$#{detail.id}", srowid: "details")
                            .order(updated_at: :desc)
                            .first
          next unless history.present?

          f_days = (history.fvalue || "").split("$$$")
          t_days = (history.tvalue || "").split("$$$")

          to_map = ->(arr) {
            arr.each_with_object({}) do |s, h|
              date_str, session = s.split("-", 2)
              h[date_str] = (session || "ALL").upcase
            end
          }

          weight = ->(sess) {
            case sess
            when "ALL" then 1.0
            when "AM", "PM" then 0.5
            else 0.0
            end
          }

          f_map = to_map.call(f_days)
          t_map = to_map.call(t_days)

          changed_days = 0.0

          if history.tvalue.blank?
            # Hủy toàn bộ
            f_days.each do |d|
              sess = d.split("-").last
              changed_days += weight.call(sess)
            end
            removed_dates.concat(f_days)
            detail.update!(itotal: 0, details: "")
          else
            # Hủy một phần
            (f_map.keys | t_map.keys).each do |date_str|
              f_sess = f_map[date_str]
              t_sess = t_map[date_str]

              f_w = weight.call(f_sess)
              t_w = weight.call(t_sess)

              if f_w > t_w
                delta = f_w - t_w
                changed_days += delta

                if detail.sholtype == "NGHI-PHEP"
                  if t_sess.nil?
                    removed_dates << "#{date_str}-#{f_sess}"
                  elsif f_sess == "ALL" && t_sess == "AM"
                    removed_dates << "#{date_str}-PM"
                  elsif f_sess == "ALL" && t_sess == "PM"
                    removed_dates << "#{date_str}-AM"
                  else
                    removed_dates << "#{date_str}-PARTIAL"
                  end
                end
              end
            end

            calculate_itotal = original_total - changed_days
            detail.update!(itotal: calculate_itotal, details: history.tvalue)
          end

          total_changed_days += changed_days
          total_changed_days_phep += changed_days if detail.sholtype == "NGHI-PHEP"
        end
      end

      holpro.update!(dttotal: holpro.dttotal.to_f - total_changed_days)

      holiday = Holiday.find_by(user_id: holpro.holiday.user_id, year: Time.zone.today.year)
      if holiday.present?
        holiday.update!(used: holiday.used.to_f - total_changed_days_phep)
        removed_dates.uniq!
        withdraw_used_days(holiday, total_changed_days_phep, removed_dates)
      end

      last_Uhandle = Mandocuhandle.find_by(id: uhandle_id)
      last_Uhandle.update!(status: "DAXULY")

      list_user_id = get_list_user(holpros_id)
      create_noti(content, holpros_id, list_user_id, true)

      adjustment_success = true
      msg = "Phê duyệt thành công"
    else
      msg = "Không tìm thấy đơn điều chỉnh phù hợp"
    end
  rescue => e
    Rails.logger.error "[approve_leave] Lỗi xử lý duyệt đơn: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    msg = "Có lỗi xảy ra: #{e.message}"
  end

  unless adjustment_success
    Rails.logger.error "[approve_leave] Không thành công - holpros_id=#{holpros_id}, holiday_id=#{holiday&.id}"
  end

  { result: adjustment_success, msg: msg }
end

def get_list_user(holpros_id)
  oMandoc = Mandoc.where(holpros_id: holpros_id)
  return [] unless oMandoc
  list_Dhandle = Mandocdhandle.where(mandoc_id: oMandoc.pluck(:id)).pluck(:id)
  return [] if list_Dhandle.empty?
  Mandocuhandle.where(mandocdhandle_id: list_Dhandle).pluck(:user_id).uniq
end

def create_noti(content,holpros_id, list_user_id, is_finish = false)
  new_notify = Notify.create!(
    title: "Nghỉ phép",
    contents: content,
    receivers: "Hệ thống ERP",
    stype: "LEAVE_REQUEST"
  )
  list_user_id.each do |uid|
    Snotice.create!(
      notify_id: new_notify.id,
      user_id: uid,
      isread: false,
      status: is_finish ? "FINISH" : nil,
    )
    if (user = User.find_by(id: uid))&.email.present?
      UserMailer.send_mail_leave_request(user.email, content).deliver_later
    end
  end
end

def withdraw_used_days(holiday, delta_remove, removed_dates)
  return if holiday.blank? || delta_remove.to_f <= 0 || removed_dates.blank?

  delta_remove = delta_remove.to_f
  holdetail_map = holiday.holdetails.index_by(&:stype)

  ton, tham_nien, vi_tri = holdetail_map.values_at("TON", "THAM-NIEN", "VI-TRI")
  ton_deadline = ton&.dtdeadline&.to_date

  # Trọng số theo session
  weight_of = ->(token) do
    sess = token.to_s.split("-", 2)[1].to_s.upcase
    case sess
    when "", "ALL" then 1.0
    when "AM", "PM" then 0.5
    else 0.5 # PARTIAL/khác xem như nửa ngày
    end
  end

  entries = removed_dates.map do |dstr|
    d = dstr.to_s.split("-", 2)[0].strip
    date = (Date.strptime(d, "%d/%m/%Y") rescue nil)
    { date: date, weight: weight_of.call(dstr) }
  end

  total_weight = entries.sum { |e| e[:weight] }
  return if total_weight <= 0.0

  delta = [delta_remove, total_weight].min

  # Chia thành 2 giỏ: <= deadline (cho TỒN) và > deadline (không cho TỒN)
  if ton_deadline
    before_entries, after_entries = entries.partition { |e| e[:date] && e[:date] <= ton_deadline }
  else
    before_entries, after_entries = entries, []
  end

  w_before = before_entries.sum { |e| e[:weight] }
  w_after  = after_entries.sum  { |e| e[:weight] }

  delta_before = [delta, w_before].min
  delta_after  = [delta - delta_before, w_after].min

  withdraw = ->(source, amount) do
    amt = amount.to_f
    return 0.0 unless source.present? && amt > 0.0
    avail = source.used.to_f
    taken = [avail, amt].min
    if taken > 0
      source.update!(used: (avail - taken).round(3))
    end
    taken
  end

  # Phần <= deadline: TỒN -> THÂM-NIÊN -> VỊ-TRÍ
  remain = delta_before
  remain -= withdraw.call(ton,       remain)
  remain -= withdraw.call(tham_nien, remain)
  remain -= withdraw.call(vi_tri,    remain)

  # Phần > deadline: THÂM-NIÊN -> VỊ-TRÍ (không TỒN)
  remain = delta_after
  remain -= withdraw.call(tham_nien, remain)
  remain -= withdraw.call(vi_tri,    remain)
end

# Chuẩn hóa về [{ id: "123", name: "Nguyen Van A" }, ...]
def normalize_user_minimal(list)
  Array(list).flatten.compact.map do |u|
    if u.is_a?(Hash)
      uid  = (u[:id] || u["id"] || u[:user_id] || u["user_id"]).to_s
      name =  u[:name] || u["name"] ||
              [u[:last_name] || u["last_name"], u[:first_name] || u["first_name"]].compact.join(" ")
      next if uid.blank?
      { id: uid, name: name }
    elsif u.respond_to?(:id)
      { id: u.id.to_s, name: (u.try(:name) || [u.try(:last_name), u.try(:first_name)].compact.join(" ")) }
    end
  end.compact.uniq { |h| h[:id] }
end


def list_array_cancel(list_hpdetail)
  array_cancel = []
  list_hpdetail.group_by(&:sholtype).each do |sholtype_code, grouped_details|
    all_changes = []
    grouped_details.each do |hp|
      oMhis = Mhistory.find_by(stable: "holprosdetails$$$#{hp.id}", srowid: "details")
      next unless oMhis.present?
      from_hash = (oMhis.fvalue || "").split("$$$").map { |v| v.split("-") }.to_h
      to_hash   = (oMhis.tvalue || "").split("$$$").map { |v| v.split("-") }.to_h
      cancelled_dates = from_hash.keys - to_hash.keys
      if cancelled_dates.any?
        sorted_dates = cancelled_dates.map { |d| Date.strptime(d, "%d/%m/%Y") rescue nil }.compact.sort
        grouped = sorted_dates.chunk_while { |prev, curr| curr == prev + 1 }.to_a
        grouped.each do |group|
          if group.length == 1
            all_changes << "Hủy ngày #{group.first.strftime('%d/%m/%Y')}"
          else
            all_changes << "Hủy từ ngày #{group.first.strftime('%d/%m/%Y')} đến #{group.last.strftime('%d/%m/%Y')}"
          end
        end
      end
      from_hash.each do |day, fval|
        tval = to_hash[day]
        next unless tval && fval != tval

        text_change =
          case tval
          when "AM" then "nghỉ buổi sáng"
          when "PM" then "nghỉ buổi chiều"
          when "ALL" then "nghỉ cả ngày"
          else "nghỉ #{tval}"
          end
        all_changes << "Ngày #{day} chuyển thành #{text_change}"
      end
    end
    next if all_changes.empty?
    array_cancel << all_changes
  end
  array_cancel.join("\n")
end

def get_zalo_setting
  record = Msetting.find_by(stype: "ZALO_OA", scode: "ZALO-ACCESS-TOKEN")

  return nil unless record

  JSON.parse(record.svalue)
end

def set_zalo_setting(access_token:, refresh_token:, expired_at:)

  data = {
    access_token: access_token,
    refresh_token: refresh_token,
    expired_at: expired_at
  }

  record = Msetting.find_or_initialize_by(
    stype: "ZALO_OA",
    scode: "ZALO-ACCESS-TOKEN"
  )

  record.name = "Zalo access token"
  record.svalue = data.to_json

  record.save!

end

def get_zalo_access_token

  setting = get_zalo_setting

  # raise "Zalo token chưa khởi tạo" unless setting

  # expired_at = Time.parse(setting["expired_at"])

  # if expired_at < Time.now + 300
    refresh_zalo_token
  # end

  # setting["access_token"]

end

def refresh_zalo_token
  setting = get_zalo_setting
  raise "Zalo token chưa khởi tạo" unless setting

  refresh_token = setting["refresh_token"]

  uri = URI("https://oauth.zaloapp.com/v4/oa/access_token")

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true

  request = Net::HTTP::Post.new(uri)
  request["Content-Type"] = "application/x-www-form-urlencoded"
  request["secret_key"] = "74qKDf5Rt8rKDd5bT4XY"

  request.body = URI.encode_www_form(
    app_id: "1385955203595521827",
    refresh_token: refresh_token,
    grant_type: "refresh_token",
    secret_key: "74qKDf5Rt8rKDd5bT4XY"
  )

  response = http.request(request)

  result = JSON.parse(response.body)

  unless result["access_token"]
    raise "Refresh token failed #{result}"
  end

  set_zalo_setting(
    access_token: result["access_token"],
    refresh_token: result["refresh_token"],
    expired_at: (Time.now + result["expires_in"].to_i).iso8601
  )

  result["access_token"]
end

def call_zalo_api(url)

  access_token = refresh_zalo_token

  uri = URI(url)

  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true

  request = Net::HTTP::Get.new(uri)
  request["access_token"] = access_token

  response = http.request(request)

  JSON.parse(response.body)
end
