module LeaveRequestHelper
  extend ActiveSupport::Concern
  include AttendConcern   # để dùng get_positionjob_department_ids_of_user, get_managers, ...

  # === Helper: build tên hiển thị cho User ===
  def lrh_user_display_name(user)
    if user.respond_to?(:last_name) && user.respond_to?(:first_name)
      "#{user.last_name} #{user.first_name}".strip
    elsif user.respond_to?(:full_name)
      user.full_name
    elsif user.respond_to?(:sid)
      "Mã NV: #{user.sid}"
    else
      "User##{user.id}"
    end
  end

  # === Check special cases ===

  # Kiểm tra Trưởng/Phó phòng TCHC (BUH)
  def lrh_check_leader_buh?(user, main_departments)
    main_departments.any? do |(_, dep_id)|
      dep = Department.find_by(id: dep_id)
      dep&.faculty == "PTCHC(BUH)" && check_permission_approve_leave(user.id).present?
    end
  end

  # Kiểm tra Phó BGD (dựa theo positionjob name)
  def lrh_check_sub_leader_bgd?(user, main_departments)
    main_departments.any? do |(pos_id, dep_id)|
      dep  = Department.find_by(id: dep_id)
      pos  = Positionjob.find_by(id: pos_id)

      dep&.faculty == "BGD(BUH)" &&
        pos&.name&.downcase&.include?("phó")
    end
  end

  # Kiểm tra thuộc Ban giám hiệu (BGD) qua quyền LEAVE-BGD
  def lrh_leave_bgd?(user)
    Work.joins(stask: { accesses: :resource })
        .where(
          resources: { scode: "LEAVE-BGD" },
          works:     { user_id: user.id },
          accesses:  { permision: "ADM" }
        )
        .exists?
  end

  # Hàm tổng quát: user có được coi là leader không?
  def lrh_is_leader?(user, main_departments)
    lrh_check_leader_buh?(user, main_departments) ||
      lrh_check_sub_leader_bgd?(user, main_departments) ||
      lrh_leave_bgd?(user)
  end

  # === Quyết định duyệt thẳng hay cần chọn người duyệt ===
  def lrh_decide_handle_user(oUser, oRegister, is_approve = false)
  main_departments = get_positionjob_department_ids_of_user(oRegister.id)[:valid] rescue []

  is_leader_buh     = lrh_check_leader_buh?(oUser, main_departments)
  is_sub_leader_bgd = lrh_check_sub_leader_bgd?(oUser, main_departments)
  is_leave_bgd      = lrh_leave_bgd?(oUser)

  approve_direct = false

  if is_leader_buh || is_sub_leader_bgd || is_leave_bgd
    approve_direct = true
  elsif is_approve == true
    # Đăng ký hộ
    if lrh_is_leader?(oUser, main_departments) && !lrh_is_leader?(oRegister, main_departments)
      approve_direct = true
    elsif lrh_check_sub_leader_bgd?(oUser, main_departments) && lrh_is_leader?(oRegister, main_departments)
      approve_direct = false
    end
  end

  if approve_direct
    {
      msg: "approve",
      result: [
        { id: oUser.id.to_s, name: lrh_user_display_name(oUser) }
      ]
    }
  else
    next_users = get_managers(user_id: oRegister.id) # từ AttendConcern
    {
      msg: "success",
      result: next_users.map { |u| { id: u[:user_id].to_s, name: u[:name] } }
    }
  end
end

end
