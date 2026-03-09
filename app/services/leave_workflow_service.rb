# app/services/leave_workflow_service.rb
class LeaveWorkflowService
  extend self
  include StreamConcern
  include HolidayShared


  # ================= BUH =================
  def handle_in_buh(user_id)
    users_have_access = []
    department_ids = []
    leader_roles = ["trưởng","trưởng", "phó", "giám đốc", "hiệu", "chánh", "chủ tịch", "phụ trách"]

    positionjob_department_ids = get_positionjob_department_ids_of_user(user_id)[:valid].uniq
    check_bgd = false

    positionjob_department_ids.each do |data|
      department   = Department.find_by(id: data[1])
      position_job = Positionjob.find_by(id: data[0])

      check_have_leader = get_users_have_access(data[1])
      is_leader = check_permission_approve_leave(user_id).present?

      if is_leader.present?
        if department.parents.nil? || department.parents == ""
          case department.faculty
          when "BGD(BUH)"
            get_department = Department.where(faculty: "PTCHC(BUH)").first
            department_ids << get_department&.id
            check_bgd = true
          when "PTCHC(BUH)"
            nextStepData = stream_connect_by_status("DUYET-PHEP-BUH", "BOARD-APPROVE")
            department_ids << nextStepData.first[:next_department_id]
          else
            nextStepData = stream_connect_by_status("DUYET-PHEP-BUH")
            users_have_access << get_users_have_access(nextStepData.first[:next_department_id], "READ")
          end
        else
          users_have_access << get_users_have_access(department.parents.to_i)
        end
      else
        if check_have_leader.present?
          users_have_access << get_users_have_access(department.id)
        elsif !department.parents.nil? || department.parents != ""
          users_have_access << get_users_have_access(department.parents.to_i)
        end
      end
    end

    { department_ids: department_ids, users_have_access: users_have_access, check_bgd: check_bgd }
  end

  # ================= BMU =================
  def handle_in_bmu(user_id)
    users_have_access = []
    department_ids = []
    leader_roles = ["trưởng","trưởng", "phó", "giám đốc", "hiệu", "chánh", "chủ tịch", "phụ trách"]

    positionjob_department_ids = get_positionjob_department_ids_of_user(user_id)[:valid].uniq

    positionjob_department_ids.each do |data|
      department   = Department.find_by(id: data[1])
      position_job = Positionjob.find_by(id: data[0])

      has_leader_role = check_have_leader(department.id, leader_roles)
      normalized_name = position_job.name.downcase.unicode_normalize(:nfkc)

      check_pho    = normalized_name.include?("phó".unicode_normalize(:nfkc))
      check_leader = leader_roles.any? do |item|
        normalized_item = item.downcase.unicode_normalize(:nfkc)
        normalized_name.include?(normalized_item) && !normalized_name.include?("phó trưởng")
      end

      if !check_leader
        if !has_leader_role
          if department.parents.nil? || department.parents == ""
            nextStepData = stream_connect_by_status("DUYET-PHEP-BMU", "BOARD-APPROVE")
            department_ids << nextStepData.first[:next_department_id]
          else
            department_ids << department.parents.to_i
          end
        else
          base_query = Work.joins({positionjob: :department}, :user)
                           .where(positionjobs: {department_id: position_job.department_id})
                           .where.not("users.status = ? OR users.staff_status = ?", "INACTIVE", "Nghỉ việc")

          if check_pho
            base_query = base_query.where("positionjobs.name LIKE ? AND positionjobs.name NOT LIKE ?", "%trưởng%", "%phó trưởng%")
            if !base_query.present?
              nextStepData = stream_connect_by_status("DUYET-PHEP-BMU", "BOARD-APPROVE")
              department_ids << nextStepData.first[:next_department_id]
              base_query = []
            end
          end

          if !check_leader && base_query.present?
            base_query = base_query.where("positionjobs.name LIKE ? OR positionjobs.name LIKE ? OR positionjobs.name LIKE ?", "%trưởng%", "%phó%", "%giám đốc%")
          end

          users_have_access << base_query.pluck("positionjobs.department_id", "departments.name as department_name", "works.user_id", "CONCAT(users.last_name, ' ', users.first_name) as name")
                                        .map { |department_id, department_name, user_id, name| { department_id: department_id, department_name: department_name, user_id: user_id, name: name } }
        end
      else
        if department.parents.nil? || department.parents == ""
          check_principal = normalized_name == "hiệu trưởng".unicode_normalize(:nfkc)
          if check_principal
            nextStepData = stream_connect_by_status("NGHI-PHEP-HIEU-TRUONG", "APPROVE")
            department_ids << nextStepData.map { |item| item[:next_department_id] || item["next_department_id"] }
          else
            nextStepData = stream_connect_by_status("DUYET-PHEP-BMU", "BOARD-APPROVE")
            department_ids << nextStepData.first[:next_department_id]
          end
        else
          department_ids << department.parents.to_i
        end
      end
    end

    { department_ids: department_ids, users_have_access: users_have_access.flatten.uniq }
  end

  # ================= Common =================
  def fetch_staff_for_workflow(user_id)
    organization_name = Organization.where(id: User.find(user_id).uorgs.pluck(:organization_id)).pluck(:scode)

    data = if (organization_name & ["BMU", "BMTU"]).any?
             handle_in_bmu(user_id)
           else
             handle_in_buh(user_id)
           end

    department_ids   = data[:department_ids]
    users_have_access = data[:users_have_access].flatten.compact

    # Lấy user_id từ users_have_access
    user_ids = users_have_access.map { |u| u[:user_id] || u[:id] }.compact

    # Nếu có department_ids thì bổ sung thêm users từ đó
    if department_ids.present?
      dept_user_ids = Work.where(positionjob_id: Positionjob.where(department_id: department_ids).pluck(:id))
                          .pluck(:user_id)
      user_ids += dept_user_ids
    end

    # Lọc trùng và chỉ lấy user đang làm việc
    user_ids = user_ids.uniq

    User.where(id: user_ids, staff_status: ["Đang làm việc", "DANG-LAM-VIEC"])
        .select("id", "CONCAT(last_name, ' ', first_name) AS name")
        .map { |w| { id: w.id.to_s, name: w.name } }
  end
end
