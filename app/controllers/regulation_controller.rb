class RegulationController < ApplicationController
    include StreamConcern
    include AttendConcern
    def index
      # if !is_access session[:user_id],"TEAM-DEV-DEBUG","READ"
        # @status_code = 404
        # render template: 'errlogs/standard_error', status: :internal_server_error, layout: false
      # end
    end

    def handle_sql
      result = {}
      begin
          fun = params[:function]
          time_execute = 0
          start_time = Time.now
          data = eval(fun)
          end_time = Time.now
          time_execute = end_time - start_time
          result = {
              status:true,
              time_execute: time_execute,
              query: data
          }
      rescue => exception
          position = exception.backtrace.to_json.html_safe.gsub("\`","")
          message = exception.message.gsub("\`","")
          result = {
              status:false,
              time_execute: time_execute,
              query: "#{message} #{position.to_json.html_safe.gsub('`', '')}"
          }
      end
      respond_to do |format|
        format.js { render js: "update(#{result.to_json.html_safe})"}
      end
    end


    def fetchStaffForWorkflow(user_id: nil)
      user_id ||= session[:user_id]
      name = Organization.where(id: User.find(user_id).uorgs.pluck(:organization_id)).pluck(:scode)
      organization_name = name || session[:organization]
      stype = params[:stype]
      leader_roles = ["trưởng","trưởng", "phó", "giám đốc", "hiệu", "chánh", "chủ tịch", "phụ trách"]

      next_user_to_handle = []
      users_have_access = []
      department_id = ""

      if (organization_name & ["BMU", "BMTU"]).any?
        department_ids = handle_in_bmu(user_id)[:department_ids]
        users_have_access = handle_in_bmu(user_id)[:users_have_access]
      else
        department_ids = handle_in_buh(user_id)[:department_ids]
        users_have_access = handle_in_buh(user_id)[:users_have_access]
      end

      next_user_to_handle = Work.left_outer_joins({positionjob: :department}, :user)
                                .where("positionjobs.name LIKE ? OR positionjobs.name LIKE ? OR positionjobs.name LIKE ? OR positionjobs.name LIKE ? OR positionjobs.name LIKE ?", "%trưởng%", "%phó%", "%giám đốc%", "%chủ tịch%", "chánh")
                                .where(positionjobs: {department_id: department_ids})
                                .where.not("users.status = ? OR users.staff_status = ?", "INACTIVE", "Nghỉ việc")
                                .pluck("positionjobs.department_id", "departments.name as department_name", "works.user_id", "CONCAT(users.last_name, ' ', users.first_name) as name").uniq
                                .map { |department_id, department_name, user_id, name| { id: user_id, name: name } }

      next_user_to_handle = next_user_to_handle + users_have_access

      next_user_to_handle = next_user_to_handle.flatten.reject(&:empty?)
      if stype == "ON-LEAVE"
        next_user_to_handle = next_user_to_handle.uniq.reject { |user| user[:id] == user_id }
      else
        next_user_to_handle = next_user_to_handle.uniq
      end
      return next_user_to_handle.flatten
    end

    # end
    def handle_in_buh(user_id)
      users_have_access = []
      department_ids = []
      leader_roles = ["trưởng","trưởng", "phó", "giám đốc", "hiệu", "chánh", "chủ tịch", "phụ trách"]

      # lấy danh sách positionjob_id và department_id của users
      positionjob_department_ids = get_positionjob_department_ids_of_user(user_id)[:valid].uniq

      positionjob_department_ids.each do |data|

        department = Department.find_by(id: data[1])

        position_job = Positionjob.find_by(id: data[0])

        # TODO: CODE CŨ SẼ XÓA Kiểm tra đơn vị có lãnh đạo không?
        # TODO: CODE CŨ SẼ XÓA has_leader_role = has_leader_role = check_have_leader(department.id, leader_roles)

        # Kiểm tra đơn vị có lãnh đạo không?
        check_have_leader = get_users_have_access(data[1])

        # Kiểm tra đơn vị nhân sự có quyền duyệt phép hay không
        is_leader = check_permission_approve_leave(user_id).present?

        # TODO: CODE CŨ SẼ XÓA Kiểm tra vị trí công việc hiện tại có phải là leader không
        # TODO: CODE CŨ SẼ XÓA if leader_roles.any? { |item| position_job.name.downcase.include?(item) }

        # Kiểm tra nhân sự có trong danh sách này không? Nếu có trong danh sách quyền mặc định là lãnh đạo phòng
        if is_leader.present?
          if department.parents.nil? || department.parents == ""
            # Đối với đơn vị không có đơn vị cha
            case department.faculty

            when "BGD(BUH)"
              # Nếu là ban giám đốc thì gửi cho các ban giám đốc khác
              department_ids << department.id

            when "PTCHC(BUH)"
              # Nếu là phòng TC hành chỉnh thì gửi cho ban giám đốc
              nextStepData = stream_connect_by_status("DUYET-PHEP-BUH", "BOARD-APPROVE")
              department_ids << nextStepData.first[:next_department_id]

            else
              # Nếu là trưởng phòng đơn vị thì gửi cho trưởng/phó TCHC và nhân sự có quyền
              nextStepData = stream_connect_by_status("DUYET-PHEP-BUH")
              # department_ids << nextStepData.first[:next_department_id]
              users_have_access << get_users_have_access(nextStepData.first[:next_department_id], "READ")
            end
          else
            # Tìm đơn vị cha
            # department_ids << department.parents.to_i
            users_have_access << get_users_have_access(department.parents.to_i)
          end
        else
          if check_have_leader.present?
            # Đối với nhân sự thì gửi cho trưởng/phó đơn vị
            # department_ids << department.id
            # Lấy nhân sự có quyền
            users_have_access << get_users_have_access(department.id)
          elsif !department.parents.nil? || department.parents != ""
            # Tìm đơn vị cha
            # department_ids << department.parents.to_i
            users_have_access << get_users_have_access(department.parents.to_i)
          end
        end
      end

      {department_ids: department_ids, users_have_access: users_have_access}
    end
    def handle_in_bmu(user_id)
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
          normalized_name.include?(normalized_item) && !normalized_name.include?("phó trưởng")
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
              base_query = base_query.where("positionjobs.name LIKE ? AND positionjobs.name NOT LIKE ? ", "%trưởng%", "%phó trưởng%")
              if !base_query.present?
                # Không có trưởng đơn vị gửi cho ban giám hiệu
                nextStepData = stream_connect_by_status("DUYET-PHEP-BMU", "BOARD-APPROVE")
                department_ids << nextStepData.first[:next_department_id]
                base_query = []
              end
            end

            # Nếu không phải là leader
            base_query = base_query.where("positionjobs.name LIKE ? OR positionjobs.name LIKE ? OR positionjobs.name LIKE ?", "%trưởng%", "%phó%", "%giám đốc%") if !check_leader && base_query.present?

            # Lấy thông tin users
            users_have_access << base_query.pluck("positionjobs.department_id", "departments.name as department_name", "works.user_id", "CONCAT(users.last_name, ' ', users.first_name) as name")
                                          .map { |department_id, department_name, user_id, name| { department_id: department_id, department_name: department_name, user_id: user_id, name: name } }
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
            [w&.positionjob_id, w&.positionjob&.department_id]
        end
        # Lấy danh sách deparment_ids
        department_ids = work_departments.map { |_, dep_id| dep_id }.uniq
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
        {valid: valid_pairs, invalid: department_ids.compact, parent_ids: parent_ids}
        end
    end

    # Kiểm tra đơn vị nhân sự có quyền duyệt phép hay không
    def get_users_have_access(dpt_id = "", permission = "ADM")
        # Tìm nhân sự có quyền
        user_id = Work.joins(stask: { accesses: :resource })
                    .where(resources: { scode: "APPROVE-REQUEST" }, accesses: {permision: permission}).pluck(:user_id)

        # Lấy thông tin nhân sự có quyền trong department
        users_have_access = Work.joins({positionjob: :department}, :user)
                                .where(user_id: user_id).where.not(positionjob_id: nil)
                                .where.not("users.status = ? OR users.staff_status = ?", "INACTIVE", "Nghỉ việc")
        users_have_access = users_have_access.where(positionjobs: {department_id: dpt_id}) if dpt_id.present?
        users_have_access = users_have_access.pluck("positionjobs.department_id", "departments.name as department_name", "works.user_id", "CONCAT(users.last_name, ' ', users.first_name) as name")
                                            .map { |department_id, department_name, user_id, name| {
                                            department_id: department_id,
                                            department_name: department_name,
                                            user_id: user_id, name: name
                                            }}
    end

    def check_permission_approve_leave(user_id)
        user_id = Work.joins(stask: { accesses: :resource })
                        .where(resources: { scode: "APPROVE-REQUEST" }, works: {user_id: user_id}, accesses: {permision: "ADM"})
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
          [w&.positionjob_id, w&.positionjob&.department_id]
        end
        # Lấy danh sách deparment_ids
        department_ids = work_departments.map { |_, dep_id| dep_id }.uniq
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
        {valid: valid_pairs, invalid: department_ids.compact, parent_ids: parent_ids}
      end
    end
end
