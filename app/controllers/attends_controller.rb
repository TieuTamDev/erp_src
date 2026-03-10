class AttendsController < ApplicationController

  before_action :authorize
  include AttendConcern

  # Attends
  # @author: Dat Le
  # @date: 30/06/2025
  # @input:
  # @return [ActiveRecord::Relation<Attend>]
  def index
    gon.user_id = session[:user_id]
    if current_user.nil?
      redirect_to login_path, alert: "Vui lòng đăng nhập để tiếp tục."
      return
    end
    @current_year = DateTime.now.year
    uorgs = current_user.uorgs
    @id = current_user.id
    @uorg_scode = uorgs.size > 1 ? "BMU" : (uorgs.first&.organization&.scode || "BMU")

    # kiểm tra có phải trợ giảng, giảng viên, kỹ thuật viên hay không
    works = Work.where(user_id: @id).where.not(positionjob_id: nil).pluck(:positionjob_id)
    positionjob_scode = Positionjob.where(id: works).where.not(department_id: nil).distinct.pluck(:scode)
    keywords = ["GIANG-VIEN","KY-THUAT-VIEN","TRO-GIANG"]
    result = positionjob_scode.any? do |scode|
      keywords.any? { |kw| scode.to_s.include?(kw) }
    end
    gon.is_lecturer = result

  end

  # Process attends
  # @author: Dat Le
  # @date: 30/06/2025
  # @input:
  # @return [ActiveRecord::Relation<Attend>]
  def process_attend
    if current_user.nil?
      redirect_to login_path, alert: "Vui lòng đăng nhập để tiếp tục."
      return
    end

    user_id = session[:user_id]
    search = params[:search]
    status_filter = params[:status_type].to_s.upcase
    date_range = params[:date].to_s.split(" - ")
    from_date = date_range[0].present? ? Date.strptime(date_range[0], "%d/%m/%Y").beginning_of_day : Date.current.beginning_of_day
    to_date   = date_range[1].present? ? Date.strptime(date_range[1], "%d/%m/%Y").end_of_day : Date.current.end_of_day
    from_month = date_range[0].present? ? Date.strptime(date_range[0], "%d/%m/%Y").beginning_of_month : Date.current.beginning_of_month
    to_month   = date_range[1].present? ? Date.strptime(date_range[1], "%d/%m/%Y").end_of_month : Date.current.end_of_month

    # TODO: Xử lý hiển thị danh sách user theo Trưởng/phó phòng đang đăng nhập theo module cơ cấu tổ chức mới
    # Lấy danh sách user theo trưởng/phó phòng đang đăng nhập
    department_id = session[:department_id]
    list_user = Work.joins(:positionjob).where(positionjobs: { department_id: department_id}).pluck(:user_id)
    # TODO: End xử lý hiển thị danh sách user theo Trưởng/phó phòng đang đăng nhập theo module cơ cấu tổ chức mới

    # Phân trang
    per_page = [(params[:per_page] || 25).to_i, 1].max
    page     = [(params[:page] || 1).to_i, 1].max
    offset   = (page - 1) * per_page

    # Base query
    attenddetails = Attenddetail.joins(:attend)
                                .where.not(stype: ['CHECKIN', 'CHECKOUT'])
                                .where(approved_by: user_id)
                                .where(attends: { stype: 'ATTENDANCE', user_id: list_user })
                                .includes(attend: :user)
                                .order('attends.checkin ASC')

    # Lọc theo trạng thái
    if status_filter.present?
      attenddetails = attenddetails.where("DATE(checkin) BETWEEN ? AND ?", from_date.to_date, to_date.to_date)
                                   .where(status: status_filter)
    else
      attenddetails = attenddetails.where("DATE(attends.checkin) BETWEEN ? AND ?", from_month.to_date, to_month.to_date)
    end

    # Lọc theo mã hoặc tên nhân viên
    if search.present?
      keyword = "%#{search.strip.downcase}%"
      attenddetails = attenddetails.joins(attend: :user).where(
        "LOWER(users.sid) LIKE :kw OR LOWER(CONCAT(users.last_name, ' ', users.first_name)) LIKE :kw",
        kw: keyword
      )
    end

    @results_total = attenddetails.count
    attenddetails = attenddetails.includes(attend: :user).limit(per_page).offset(offset)
    @total_pages = (@results_total.to_f / per_page).ceil
    @page = page
    @per_page = per_page
    @departments = get_departments

    # Xử lý dữ liệu trên view
    @results = attenddetails.map do |item|
      user = item.attend.user
      positionjob = get_department_name(user.id)
      department_name = positionjob[:department_name]
      {
        id: item.id,
        user_id: user.sid,
        user_name: "#{user.last_name} #{user.first_name}",
        department: department_name,
        checkin: item.stype == 'ADDITIONAL-CHECK-IN' ? item.dtcheckin&.strftime("%H:%M") : '-',
        checkout: item.stype == 'ADDITIONAL-CHECK-OUT' ? item.dtcheckout&.strftime("%H:%M") : '-',
        date: item.attend.checkin&.strftime("%d/%m/%Y"),
        created_at: item.created_at&.strftime("%d/%m/%Y"),
        reason: item.reason,
        status: item.status,
        stype: map_stype_label(item.stype),
        docs: item.docs,
      }
    end

  end

  def get_process_attend
    week_num = params[:week_num].to_i rescue DateTime.now.cweek
    year = params[:year].to_i rescue DateTime.now.year
    request_type = params[:request_type].to_s.strip
    search = params[:search].to_s.strip  
    page = params[:page].to_i > 0 ? params[:page].to_i : 1  
    per_page = params[:per_page].to_i > 0 ? params[:per_page].to_i : 10  
    start_date = Date.commercial(year, week_num, 1)
    end_date = Date.commercial(year, week_num, 7)

    base_query = Shiftissue.select("shiftissues.*,
                                    mediafiles.file_name,
                                    shiftselections.work_date,
                                    shiftselections.start_time,
                                    shiftselections.end_time,
                                    CONCAT(users.last_name, ' ', users.first_name) as user_name,
                                    users.sid,
                                    change_shift.start_time as c_start_time,
                                    change_shift.end_time as c_end_time,
                                    CONCAT(change_users.last_name, ' ', change_users.first_name) as change_user_name")
                            .joins(shiftselection: :scheduleweek)
                            .joins("LEFT JOIN shiftselections as change_shift ON change_shift.id = shiftissues.ref_shift_changed")
                            .joins("LEFT JOIN scheduleweeks as cscheduleweek ON change_shift.scheduleweek_id = cscheduleweek.id")
                            .joins("LEFT JOIN users as change_users ON cscheduleweek.user_id = change_users.id")
                            .joins("LEFT JOIN users ON users.id = scheduleweeks.user_id")
                            .joins("LEFT JOIN mediafiles ON mediafiles.id = shiftissues.docs")
                            .where("shiftselections.work_date >= ? AND shiftselections.work_date <= ?", start_date.beginning_of_day, end_date.end_of_day)
                            .where("shiftissues.approved_by IS NOT NULL")
                            .where("shiftissues.approved_by = ?", session[:user_id])

    if search.present?
      keyword = "%#{search.downcase}%"
      base_query = base_query.where(
        "LOWER(users.sid) LIKE ? OR LOWER(CONCAT(users.last_name, ' ', users.first_name)) LIKE ?",
        keyword, keyword
      )
    end

    if request_type.present?
      stype_value = map_request_type(request_type)
      if stype_value
        base_query = base_query.where("shiftissues.stype = ?", stype_value)
      end
    end

    all_results = base_query.order('shiftissues.created_at DESC, shiftissues.id DESC')

    work_trip_requests = all_results.select { |item| item.stype == "WORK-TRIP" }
    other_requests = all_results.reject { |item| item.stype == "WORK-TRIP" }

    grouped_work_trips = work_trip_requests.group_by { |item| [item.sid, item.created_at] }

    final_results = []

    grouped_work_trips.each do |(sid, created_date), attends|
      representative = attends.min_by(&:work_date)
      
      representative.define_singleton_method(:grouped_work_trips) { attends }
      representative.define_singleton_method(:sort_key) { representative.created_at }
      
      # Thêm thông tin về số ngày công tác
      work_dates = attends.map(&:work_date).uniq
      representative.define_singleton_method(:work_days_count) { work_dates.length }
      representative.define_singleton_method(:is_one_day_trip) { work_dates.length == 1 }
      
      final_results << representative
    end

    other_requests.each do |item|
      item.define_singleton_method(:sort_key) { item.created_at }
      final_results << item
    end

    final_results.sort_by! { |item| -item.sort_key.to_i }

    total_count = final_results.size
    total_pages = (total_count.to_f / per_page).ceil
    offset = (page - 1) * per_page
    
    @shiftissue_pagin = final_results.slice(offset, per_page) || []
    
    session[:page] = page
    session[:total_pages] = total_pages
    session[:per_page] = per_page
    session[:total_records] = total_count
  end

  def map_request_type(request_type)
    case request_type
    when 'early-check-out'
      'EARLY-CHECK-OUT'
    when 'late-check-in' 
      'LATE-CHECK-IN'
    when 'shift-change'
      'SHIFT-CHANGE'
    when 'work-trip'
      'WORK-TRIP'
    when 'additional-check-in'
      'ADDITIONAL-CHECK-IN'
    when 'additional-check-out'
      'ADDITIONAL-CHECK-OUT'
    when 'update-shift'
      'UPDATE-SHIFT'
    when 'edit-plan'
      'EDIT-PLAN'
    when 'compensatory-leave' #THÊM mapping cho đề xuất nghỉ bù - @author:an.cdb @date: 09/03/2026
      'COMPENSATORY-LEAVE'
    else
      nil
    end
  end


  # Management attends
  # @author: Dat Le
  # @date: 30/06/2025
  # @input:
  # @return [ActiveRecord::Relation<Attend>]
  def management
    if current_user.nil?
      redirect_to login_path, alert: "Vui lòng đăng nhập để tiếp tục."
      return
    end

    # Filter params
    search = params[:search]
    department_id = params[:department_id]
    type_filter = params[:attendance_type]
    date_range = params[:date].to_s.split(" - ")
    from_date = date_range[0].present? ? Time.zone.strptime(date_range[0], '%d/%m/%Y').beginning_of_day :  Time.zone.today.beginning_of_day
    to_date   = date_range[1].present? ? Time.zone.strptime(date_range[1], '%d/%m/%Y').end_of_day : Time.zone.today.end_of_day

    campus_map = get_all_campus

    # Phân trang
    per_page = [(params[:per_page] || 25).to_i, 1].max
    page     = [(params[:page] || 1).to_i, 1].max
    offset   = (page - 1) * per_page

    # Base query
    shift_selections = Shiftselection
                         .where(work_date: from_date..to_date)
                         .joins(:scheduleweek)
                         .where(scheduleweeks: { status: 'APPROVED' })
                         .includes(:attend, :shiftissue, scheduleweek: :user)
                         .order('shiftselections.work_date ASC, scheduleweeks.user_id ASC')

    # Lọc theo loại chấm công
    if type_filter.present?
      case type_filter
      when 'no-check-in-out'
        shift_selections = shift_selections
                             .where(is_day_off: nil)
                             .where(attends: { id: nil })
      when 'late-check-in'
        shift_selections = shift_selections
                             .joins(:attend)
                             .where(is_day_off: nil)
                             .where('attends.checkin IS NOT NULL')
                             .where(<<~SQL, 0)
                                     attends.checkin >
                                     TIMESTAMP(shiftselections.work_date, shiftselections.start_time) + INTERVAL 16 MINUTE
                                   SQL
      when 'early-checkout-out'
        shift_selections = shift_selections
                             .joins(:attend)
                             .where(is_day_off: nil)
                             .where('attends.checkout IS NOT NULL')
                             .where(<<~SQL, 0)
                                     attends.checkout <
                                     TIMESTAMP(shiftselections.work_date, shiftselections.end_time) - INTERVAL 16 MINUTE
                                   SQL
      when 'work-trip'
        shift_selections = shift_selections
                             .joins(:shiftissue)
                             .where(shiftissues: { stype: 'WORK-TRIP', status: 'APPROVED' })
      end
    end

    # Lọc theo mã hoặc tên nhân viên
    if search.present?
      kw = "%#{search.strip.downcase}%"
      shift_selections = shift_selections
                           .joins(scheduleweek: :user)
                           .where('LOWER(users.sid)          LIKE :kw OR
                                 LOWER(CONCAT(users.last_name," ",users.first_name)) LIKE :kw', kw: kw)
    end

    # Lọc theo phòng ban
    if department_id.present?
      user_ids = Work.joins(:positionjob)
                     .where(positionjobs: { department_id: department_id })
                     .pluck(:user_id)
      shift_selections = shift_selections.joins(:scheduleweek)
                                         .where(scheduleweeks: { user_id: user_ids })
    end

    # Hiển thị danh sách nhân viên theo Trưởng/phó phòng đang đăng nhập
    permission_edit = is_access(session['user_id'], 'ATTEND-MANAGEMENT', 'EDIT')
    permission_add  = is_access(session['user_id'], 'ATTEND-MANAGEMENT', 'ADD')
    permission_adm  = is_access(session['user_id'], 'ATTEND-MANAGEMENT', 'ADM')
    if permission_edit && !permission_add && !permission_adm
      user_id = session[:user_id]
      works = Work.where(user_id: user_id).where.not(positionjob_id: nil).pluck(:positionjob_id)
      department_ids = Positionjob.where(id: works)
                                  .where.not(department_id: nil)
                                  .distinct
                                  .pluck(:department_id)
      if department_ids.present?
        list_user = Work.joins(:positionjob)
                        .where(positionjobs: { department_id: department_ids })
                        .distinct
                        .pluck(:user_id)
        shift_selections = shift_selections.joins(:scheduleweek)
                                           .where(scheduleweeks: { user_id: list_user })
      end
    end

    grouped_rows = shift_selections.group_by { |s| [s.scheduleweek.user_id, s.work_date] }
    @results_total = grouped_rows.size
    paged_rows     = grouped_rows.values.slice(offset, per_page) || []
    @total_pages = (@results_total.to_f / per_page).ceil
    @page = page
    @per_page = per_page
    @departments = get_departments

    # @author: trong.lq
    # @date: 24/01/2026
    # Tính department_id cho user có quyền EDIT từ helper get_user_department_id
    permission_edit = is_access(session['user_id'], 'ATTEND-MANAGEMENT', 'EDIT')
    permission_add  = is_access(session['user_id'], 'ATTEND-MANAGEMENT', 'ADD')
    permission_adm  = is_access(session['user_id'], 'ATTEND-MANAGEMENT', 'ADM')
    
    if permission_edit && !permission_add && !permission_adm
      @user_department_id_for_export = get_user_department_id(session[:user_id], session[:department_id])
    else
      @user_department_id_for_export = nil
    end

    # Xử lý dữ liệu trên view
    @results = paged_rows.map do |rows|
      user       = rows.first.scheduleweek.user
      next if user.nil?
      date_key   = rows.first.work_date.strftime("%d/%m/%Y")

      shift_plan = {}
      shift_att  = {}

      rows.each do |sel|
        ws_id = sel.workshift_id
        has_work_trip = sel.shiftissue.any? { |si| si.stype == 'WORK-TRIP' && si.status == 'APPROVED' }
        is_day_off = has_work_trip ? 'WORK-TRIP' : sel.is_day_off
        shift_plan[ws_id] = {
          shiftselection_id: sel.id,
          is_day_off: is_day_off,
          location: campus_map[sel.location],
          start_time: sel.start_time,
          end_time:   sel.end_time
        }

        shift_att[ws_id] = {
          attend_id:  sel.attend&.id,
          checkin:  sel.attend&.checkin&.strftime("%H:%M"),
          checkout: sel.attend&.checkout&.strftime("%H:%M")
        }
      end
      positionjob = get_department_name(user.id)
      {
        id:          rows.map(&:id).join('|'),
        user_id:     user.sid,
        user_name:   "#{user.last_name} #{user.first_name}",
        department:  positionjob[:department_name],
        work_date:   date_key,
        shiftselection: shift_plan,
        attend:         shift_att
      }
    end
    gon.erp_path_users_erp = @ERP_PATH + "/api/v1/mapi_utils/get_users_erp"
  end

  # Get attend details by id
  # @author: Dat Le
  # @date: 02/07/2025
  # @input: attend_id
  # @return [ActiveRecord::Relation<AttendDetails>] Details attend
  def get_attend_details
    attend_id = params[:attend_id]

    oAttend = Attend.includes(:user).find(attend_id)

    unless oAttend
      return render json: { status: false, message: "Không tìm thấy chấm công" }, status: :not_found
    end

    user = oAttend.user
    positionjob = get_department_name(user.id)
    department = positionjob[:department_name]
    user_image = Mediafile.where(id: user.avatar, status: "ACTIVE").pluck(:file_name).first

    details = Attenddetail.where(attend_id: attend_id).map do |item|
      image = Mediafile.where(id: item.pic, status: "ACTIVE").pluck(:file_name).first
      user_approve = User.find_by(id: item.approved_by)
      full_name_with_sid = user_approve ? "#{user_approve.last_name} #{user_approve.first_name} (#{user_approve.sid})" : ""
      {
        id: item.id,
        attend_id: item.attend_id,
        dtcheckin: item.dtcheckin,
        dtcheckout: item.dtcheckout,
        status: item.status,
        reason: item.reason,
        owner: item.owner,
        pic: image.present? ? "#{request.base_url}/mdata/hrm/#{image}" : nil,
        approved_at: item.approved_at,
        approved_by: full_name_with_sid,
        stype: item.stype
      }
    end

    has_pending_additional_checkin = Attenddetail.exists?(
      attend_id: oAttend.id,
      stype: "ADDITIONAL-CHECK-IN",
      status: "PENDING"
    )

    has_pending_additional_checkout = Attenddetail.exists?(
      attend_id: oAttend.id,
      stype: "ADDITIONAL-CHECK-OUT",
      status: "PENDING"
    )

    render json: {
      id: attend_id,
      user_id: user.sid,
      user_name: "#{user.last_name} #{user.first_name}",
      phone: user.phone,
      checkin: has_pending_additional_checkin ? "-" : (oAttend.checkin&.strftime("%H:%M") || "-"),
      checkout: has_pending_additional_checkout ? "-" : (oAttend.checkout&.strftime("%H:%M") || "-"),
      user_image: user_image.present? ? "#{request.base_url}/mdata/hrm/#{user_image}" : nil,
      department: department,
      details: details
    }, status: :ok

  end

  REQUEST_TYPE_NAMES = {
    "EARLY-CHECK-OUT"         => "Về sớm",
    "LATE-CHECK-IN"           => "Đi trễ",
    "SHIFT-CHANGE"            => "Đổi ca",
    "SHIFT-CHANGE-APPROVED"   => "Bị đổi ca",
    "UPDATE-SHIFT"            => "Cập nhật ca",
    "WORK-TRIP"               => "Đi công tác",
    "ADDITIONAL-CHECK-IN"     => "Chấm công vào làm bù",
    "ADDITIONAL-CHECK-OUT"    => "Chấm công tan làm bù",
    "ADDITIONAL-CHECK-IN-OUT" => "Chấm công bù vào/ra",
    "EDIT-PLAN"               => "Chỉnh sửa kế hoạch làm việc",
    "COMPENSATORY-LEAVE"      => "Nghỉ bù" #Thêm mapping cho đề xuất nghỉ bù - @author:an.cdb @date: 09/03/2026
  }.freeze

  # Tạo Shiftissue cho ca sáng hoặc ca chiều
  # @author: Trong Le
  # @date: 25/09/2025
  # @input: workshift_id, shift_type, user_id, date, reason, approver_id, common_data, created_issues
  # @return: void (thêm vào created_issues array)
  def create_shift_issue(workshift_id, shift_type, user_id, date, reason, approver_id, common_data, created_issues)
    validation = validate_attend_request_conditions(user_id, date, workshift_id, "update-shift")
    # Không return render ở đây để tránh multiple render
    return unless validation == true
    
    shift = find_shift(user_id, date, workshift_id)
    
    if shift && !issue_exists?(shift.id, workshift_id)
      check_in_param = (shift_type == "morning") ? :morning_check_in : :afternoon_check_in
      check_out_param = (shift_type == "morning") ? :morning_check_out : :afternoon_check_out
      
      created_issues << Shiftissue.create(
        shiftselection_id: shift.id,
        stype: "UPDATE-SHIFT",
        status: "PENDING",
        note: reason,
        approved_by: approver_id,
        us_start: params[check_in_param],
        us_end: params[check_out_param],
        docs: common_data[:file]
      )
    end
  end

  # Save attend request by
  # @author: Trong Le
  # @date: 01/08/2025
  # @input: user_id, date, request_type, time, reason, approved_id, image
  # @return
  def find_shift(user_id, date, workshift_id, include_day_off: false)
    scheduleweek = Scheduleweek
    .where(user_id: user_id)
    .where("start_date <= ? AND end_date >= ?", date, date.beginning_of_day)
    .first
  
    return nil unless scheduleweek
  
    query = Shiftselection.where(
      scheduleweek_id: scheduleweek.id,
      workshift_id: workshift_id,
      work_date: date.to_date.beginning_of_day..date.to_date.end_of_day
    )
  
    # Chỉ lọc loại bỏ ngày nghỉ nếu không phải công tác
    query = query.where("is_day_off IS NULL OR is_day_off != ?", "OFF") unless include_day_off
  
    query.first
  end

  def find_end_time_shift()
    # Tìm scheduleweek chứa ngày đó của user
    workshift = Workshift
                  .where(id: workshift_id)
                  .first
    return workshift&.name
  end

  def save_attend_request
    user_id = session[:user_id]
    return render json: { success: false, error: "Không xác định được người dùng" }, status: :ok unless user_id

    date = Date.parse(params[:original_date]) rescue nil

    # Upload file nếu có
    file_id = nil
    if params[:image].present?
      result = upload_document(params[:image])
      if result.is_a?(Hash)
        file_id = result[:id] || result['id'] || result[:value] || result['value']
      elsif result.is_a?(String)
        file_id = result
      end
    end
    request_type = params[:request_type]
    trip_shift_data = JSON.parse(params[:trip_shift_data]) rescue []
    workshift_id = params[:workshift_id].to_i if params[:workshift_id].present?

    # Nếu là công tác thì kiểm tra từng ngày trong mảng
    if request_type == "work-trip"
      trip_shift_data.each do |entry|
        date_str = entry["date"] || entry[:date]
        date = Date.parse(date_str) rescue nil
        next unless date
    
        validation = validate_attend_request_conditions(user_id, date, workshift_id, request_type)
        return render json: { success: false, error: validation }, status: :ok unless validation == true
      end
    # Code cũ - @author: trong.lq @date: 22/10/2025
    # elsif request_type != "update-shift"
    #   date = Date.parse(params[:original_date]) rescue nil
    #   validation = validate_attend_request_conditions(user_id, date, workshift_id, request_type)
    #   return render json: { success: false, error: validation }, status: :ok unless validation == true
    # end
    
    # Code mới - @author: trong.lq @date: 22/10/2025
    # Thêm edit-plan vào danh sách không cần validation date/workshift
    elsif request_type != "update-shift" && request_type != "edit-plan"
      date = Date.parse(params[:original_date]) rescue nil
      validation = validate_attend_request_conditions(user_id, date, workshift_id, request_type)
      return render json: { success: false, error: validation }, status: :ok unless validation == true
    end
    
    common_data = {
      date: date,
      reason: params[:reason],
      time: params[:time],
      file: file_id,
      approver_id: params[:approved_id],
      workshift_id: workshift_id,
      check_in_time: params[:check_in_time],
      check_out_time: params[:check_out_time],
      trip_shift_data: trip_shift_data,
      type: request_type
    }

    case request_type
    when "early-check-out", "late-check-in"
      handle_early_or_late_check(user_id, common_data)
    when "shift-change"
      handle_shift_change(user_id, common_data)
    when "additional-check-out", "additional-check-in"
      handle_additional_check(user_id, common_data)
    when "update-shift"
      handle_update_shift(user_id, common_data)
    when "work-trip"
      handle_work_trip(user_id, common_data)
    when "edit-plan"
      handle_edit_plan(user_id, common_data)
    when "compensatory-leave" #Thêm case cho đề xuất nghỉ bù - @author:an.cdb @date: 09/03/2026
      handle_compensatory_leave(user_id, common_data)
    else
      render json: { success: false, error: "Loại đề xuất không hợp lệ" }, status: :ok
    end
  end

  def handle_early_or_late_check(user_id, data)
    shift = find_shift(user_id, data[:date], data[:workshift_id])
    return render json: { success: false, error: "Không tìm thấy ca làm việc, ngày đó là ngày nghỉ.", user_id: user_id, data_input: data }, status: :ok unless shift

    if data[:time].blank?
      return render json: { success: false, error: "Thiếu thời gian đề xuất.", data_input: data }, status: :ok
    end

    # Kiểm tra trùng
    existing = Shiftissue.where(
      shiftselection_id: shift.id,
      stype: data[:type].upcase,
      status: %w[PENDING APPROVED]
    ).first

    if existing
      return render json: {
        success: false,
        error: "Đề xuất này đã tồn tại",
        data_input: data,
        existing_id: existing.id
      }, status: :ok
    end

    issue_attrs = {
      shiftselection_id: shift.id,
      stype: data[:type].upcase,
      name: REQUEST_TYPE_NAMES[data[:type]],
      approved_by: data[:approver_id],
      status: "PENDING",
      note: data[:reason],
      created_at: Time.current,
      updated_at: Time.current,
      docs: data[:file]
    }
    issue_attrs[:us_end]   = data[:time] if data[:type] == "early-check-out"
    issue_attrs[:us_start] = data[:time] if data[:type] == "late-check-in"

    begin
      issue = Shiftissue.create!(issue_attrs)
      send_notify(data[:type].upcase, data[:approver_id])
      render json: {
        success: true,
        message: "Đã lưu đề xuất thành công",
        redirect_url: attends_path,
        request_type: data[:type],
        data_input: data,
        shiftselection_id: shift.id,
        us_start: issue.us_start,
        us_end: issue.us_end
      }, status: :ok
    rescue => e
      render json: { success: false, error: "Lỗi khi lưu đề xuất: #{e.message}", data_input: data }, status: :ok
    end
  end

  def handle_additional_check(user_id, data)
    date = data[:date].is_a?(Date) ? data[:date] : (Date.parse(data[:date].to_s) rescue nil)
    return render json: { success: false, error: "Ngày không hợp lệ", data_input: data }, status: :ok unless date

    workshift_id = data[:workshift_id].to_i
    shift = find_shift(user_id, date, workshift_id)
    return render json: { success: false, error: "Không tìm thấy ca làm việc, ngày đó là ngày nghỉ", data_input: data }, status: :ok unless shift

    stype = data[:type].upcase # "additional-check-in" | "additional-check-out"
    human_name = REQUEST_TYPE_NAMES[stype.upcase] || stype.titleize

    day_range = date.in_time_zone.all_day
    existing = Shiftissue.where(shiftselection_id: shift.id, stype: stype_up, status: %w[PENDING APPROVED]).first
    if existing_issue
      return render json: {
        success: false,
        error: "Đã tồn tại đề xuất #{human_name} cho ngày này.",
        existing_issue_id: existing_issue.id,
        data_input: data
      }, status: :ok
    end

    us_start = (stype == "ADDITIONAL-CHECK-IN"  ? data[:check_in_time]  : nil)
    us_end   = (stype == "ADDITIONAL-CHECK-OUT" ? data[:check_out_time] : nil)

    issue_attrs = {
      shiftselection_id: shift.id,
      stype: stype,
      name: human_name,
      approved_by: data[:approver_id],
      status: "PENDING",
      note: data[:reason],
      us_start: us_start,
      us_end: us_end,
      docs: data[:file]
    }

    begin
      issue = Shiftissue.create!(issue_attrs)
      send_notify(data[:type].upcase, data[:approver_id])
      render json: {
        success: true,
        message: "Đã lưu đề xuất #{human_name}",
        data_input: data,
        shiftselection_id: shift.id,
        us_start: issue.us_start,
        us_end: issue.us_end,
        redirect_url: attends_path 
      }, status: :ok
    rescue => e
      render json: { success: false, error: "Lỗi khi lưu đề xuất: #{e.message}", data_input: data }, status: :ok
    end
  end

  # Helper
  def issue_exists?(shiftselection_id, workshift_id = nil)
    query = Shiftissue.joins(:shiftselection).where(
      shiftselections: { id: shiftselection_id },
      stype: "UPDATE-SHIFT",
      status: ["PENDING", "APPROVED"]
    )
    
    # Nếu có workshift_id, kiểm tra thêm để phân biệt ca sáng/ca chiều
    if workshift_id.present?
      query = query.where(shiftselections: { workshift_id: workshift_id })
    end
    
    query.exists?
  end

  def send_notify(stype, approved_by)
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

  # Method xử lý đăng ký nghỉ bù
  # @author: an.cdb
  # @date: 09/03/2026
  # @input: user_id, data
  # @return: JSON response
  def handle_compensatory_leave(user_id, data)
    #Lấy ngày có ca làm việc dư (ngày gốc để được nghỉ bù) từ data[:date]
    attend_date = Date.parse(data[:date].to_s) rescue nil
    return render json: { success: false, error: "Ngày không hợp lệ", data_input: data }, status: :ok unless attend_date

    #Lấy ngày đăng ký nghỉ bù
    leave_date = Date.parse(params[:leave_date].to_s) rescue nil
    return render json: { success: false, error: "Ngày đăng ký nghỉ bù không hợp lệ", data_input: data}, status: :ok unless leave_date

    leave_shift_id = params[:leave_workshift_id]
    return render json: { success: false, error: "Vui lòng chọn ca nghỉ bù" }, status: :ok if leave_shift_id.blank?

    if leave_date < attend_date
      return render json: { success: false, error: "Ngày đăng ký nghỉ bù phải sau ngày có ca làm việc dư" }, status: :ok
    end

    if leave_date > attend_date + 30.days
      return render json: {
        success:false, 
        error: "Ngày đăng ký nghỉ bù không được vượt quá 30 ngày kể từ thời điểm có ca làm việc vượt giờ",
        data_input: data
      }, status: :ok
    end

    # Tìm shiftselection tương ứng
    shift = find_shift(user_id, attend_date, data[:workshift_id], include_day_off: true)
    return render json: { success: false, error: "Không tìm thấy ca làm việc vào ngày #{attend_date.strftime('%d/%m/%Y')}" }, status: :ok unless shift

    # Kiểm tra trùng đề xuất
    existing = Shiftissue.where(
      shiftselection_id: shift.id,
      stype: 'COMPENSATORY-LEAVE',
      status: %w[PENDING APPROVED]
    ).exists?

    if existing
      return render json: { success: false, error: "Đã tồn tại đơn đăng ký nghỉ bù cho ca làm việc này" }, status: :ok
    end

    leave_shift_name = Workshift.find_by(id: leave_shift_id)&.name || "N/A"

    # Tạo Shiftissue
    begin
      issue = Shiftissue.create!(
        shiftselection_id: shift.id,
        stype: 'COMPENSATORY-LEAVE',
        status: 'PENDING',
        approved_by: data[:approver_id],
        note: data[:reason],
        docs: data[:file], # Đã được xử lý upload tự động từ hàm cha
        content: "Nghỉ bù cho ngày: #{attend_date.strftime('%d/%m/%Y')} | Nghỉ ngày: #{leave_date.strftime('%d/%m/%Y')} | Ca: #{leave_shift_name}"
      )

      # Gọi hàm notify chuẩn của hệ thống (chỉ 2 tham số)
      send_notify('COMPENSATORY-LEAVE', data[:approver_id])

      render json: {
        success: true,
        message: "Đã gửi đơn đăng ký nghỉ bù thành công",
        redirect_url: attends_path,
        request_type: 'compensatory-leave',
        shiftissue_id: issue.id
      }, status: :ok
    rescue => e
      render json: { success: false, error: "Lỗi khi lưu đề xuất: #{e.message}" }, status: :ok
    end
    
  end

  def handle_update_shift(user_id, common_data)
    date        = common_data[:date]
    approver_id = common_data[:approver_id]
    reason      = common_data[:reason]

    created_issues = []
    morning_id = params[:morning_workshift_id]
    afternoon_id = params[:afternoon_workshift_id]
    # Tạo Shiftissue cho ca sáng và ca chiều
    validation_errors = []
    
    # Chỉ tạo cho ca sáng nếu có morning_workshift_id
    if morning_id.present?
      validation = validate_attend_request_conditions(user_id, date, morning_id, "update-shift")
      if validation == true
        create_shift_issue(morning_id, "morning", user_id, date, reason, approver_id, common_data, created_issues)
      else
        validation_errors << "Ca sáng: #{validation}"
      end
    end
    
    # Chỉ tạo cho ca chiều nếu có afternoon_workshift_id
    if afternoon_id.present?
      validation = validate_attend_request_conditions(user_id, date, afternoon_id, "update-shift")
      if validation == true
        create_shift_issue(afternoon_id, "afternoon", user_id, date, reason, approver_id, common_data, created_issues)
      else
        validation_errors << "Ca chiều: #{validation}"
      end
    end



    if created_issues.any?
      send_notify("UPDATE-SHIFT", approver_id)
      render json: {
        success: true,
        message: "Đã tạo cập nhật giờ làm việc",
        created: created_issues.map(&:id),
        validation_errors: validation_errors,
        redirect_url: attends_path 
      }, status: :ok
    else
      render json: {
        success: false,
        error: "Đã tồn tại đề xuất cập nhật cho ca này hoặc không có dữ liệu mới.",
        validation_errors: validation_errors
      }, status: :ok
    end
  end

  def handle_shift_change(user_id, data)
    partner_id = params[:swap_with_user_id].to_i
    begin
      original_date = params[:original_date].is_a?(Date) ? params[:original_date] : Date.parse(params[:original_date].to_s)
      target_date   = params[:target_date].is_a?(Date)   ? params[:target_date]   : Date.parse(params[:target_date].to_s)
    rescue ArgumentError, TypeError
      return render json: { success: false, error: "Ngày không hợp lệ", result: [] }, status: :ok
    end

    my_shifts      = shifts_in_day(user_id, original_date)
    partner_shifts = shifts_in_day(partner_id, target_date)

    return render json: { success: false, error: "Bạn không có ca làm trong ngày #{original_date}", result: [] }, status: :ok if my_shifts.empty?
    return render json: { success: false, error: "Đối tác không có ca làm trong ngày #{target_date}", result: [] }, status: :ok if partner_shifts.empty?

    if my_shifts.size != partner_shifts.size
      return render json: { success: false, error: "Số ca giữa hai ngày không khớp (#{my_shifts.size} vs #{partner_shifts.size}). Vui lòng chọn lại.", result: [] }, status: :ok
    end

    created_ids = []
    missing_workshift_errors = []
    is_same_day = original_date == target_date

    ActiveRecord::Base.transaction do
      if is_same_day
        # Code mới - @author: trong.lq @date: 15/01/2025
        # Trường hợp CÙNG NGÀY: Ghép ca theo workshift_id để đảm bảo đúng ca làm việc
        my_shifts.each do |mine|
          next unless mine
          
          # Tìm ca của đối tác có cùng workshift_id
          theirs = partner_shifts.find { |s| s.workshift_id == mine.workshift_id }
          
          if theirs.nil?
            missing_workshift_errors << "Không tìm thấy ca workshift_id=#{mine.workshift_id} của đối tác trong ngày #{target_date}"
            next
          end

          # Kiểm tra trùng đề xuất
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
            note: data[:reason],
            approved_by: data[:approver_id],
            ref_shift_changed: theirs.id.to_s,
            us_start: mine.start_time,
            us_end: mine.end_time,
            docs: data[:file]
          )
          created_ids << issue.id
        end
      else
        # Code cũ - @author: trong.lq @date: 15/01/2025
        # Trường hợp KHÁC NGÀY: Giữ nguyên logic cũ (sort theo start_time và zip)
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
            note: data[:reason],
            approved_by: data[:approver_id],
            ref_shift_changed: theirs.id.to_s,
            us_start: mine.start_time,
            us_end: mine.end_time,
            docs: data[:file]
          )
          created_ids << issue.id
        end
      end
    end

    if missing_workshift_errors.any?
      render json: { 
        success: false, 
        error: "Không thể ghép ca: #{missing_workshift_errors.join('; ')}", 
        result: [] 
      }, status: :ok
    elsif created_ids.any?
      send_notify("SHIFT-CHANGE", data[:approver_id])
      render json: { success: true, message: "Đã gửi đề xuất đổi ca", result: created_ids, redirect_url: attends_path }, status: :ok
    else
      render json: { success: false, error: "Đề xuất đã được tạo", result: [] }, status: :ok
    end
  rescue ActiveRecord::RecordInvalid => e
    render json: { success: false, error: "Dữ liệu không hợp lệ: #{e.record.errors.full_messages.join(', ')}", result: [] }, status: :ok
  rescue => e
    render json: { success: false, error: "Lỗi hệ thống: #{e.message}", result: [] }, status: :ok
  end

  def handle_work_trip(user_id, data)
    approver_id = data[:approver_id]
    reason = data[:reason]
    created_issues = []
    errors = []
  
    Array(data[:trip_shift_data]).each do |entry|
      date = entry["date"] || entry[:date]
      shift_ids = entry["shifts"] || entry[:shifts]
  
      begin
        date = date.is_a?(Date) ? date : Date.parse(date.to_s)
      rescue ArgumentError
        errors << "Ngày không hợp lệ: #{date}"
        next
      end
  
      Array(shift_ids).each do |shift_id|
        shift = find_shift(user_id, date, shift_id, include_day_off: true)
        unless shift
          errors << "Không tìm thấy ca làm việc với ID #{shift_id} vào ngày #{date}"
          next
        end
  
        # Kiểm tra trùng đề xuất
        exists = Shiftissue.exists?(
          shiftselection_id: shift.id,
          stype: "WORK-TRIP",
          status: %w[PENDING APPROVED]
        )
        if exists
          errors << "Đã tồn tại đề xuất công tác cho ca #{shift_id} vào ngày #{date}"
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
          docs: data[:file]
        )
        created_issues << {
          issue_id: issue.id,
          shiftselection_id: issue.shiftselection_id
        } if issue.persisted?
      end
    end
  
    if created_issues.any?
      send_notify("WORK-TRIP", approver_id)
      render json: {
        success: true,
        message: "Đã gửi đề xuất công tác",
        created: created_issues,
        errors: errors,
        redirect_url: attends_path
      }, status: :ok
    else
      render json: {
        success: false,
        error: "Không tạo được đề xuất nào.",
        details: errors,
        data_input: data
      }, status: :ok
    end
  end

  # Xử lý đề xuất chỉnh sửa kế hoạch làm việc
  # @author: trong.lq
  # @date: 22/10/2025
  # @input: user_id, common_data
  # @return: JSON response
  def handle_edit_plan(user_id, data)
    week_num = params[:plan_week_num]
    approver_id = data[:approver_id]
    reason = data[:reason]

    # Validate required fields
    if week_num.blank?
      return render json: { success: false, error: "Vui lòng chọn tuần chỉnh sửa" }, status: :ok
    end

    if approver_id.blank?
      return render json: { success: false, error: "Vui lòng chọn trưởng/phó phòng phê duyệt" }, status: :ok
    end

    if reason.blank?
      return render json: { success: false, error: "Vui lòng nhập lý do" }, status: :ok
    end

    begin
      # Tìm shiftselection có sẵn cho tuần này
      # @author: trong.lq
      # @date: 22/10/2025
      target_shiftselection = find_shiftselection_for_edit_plan(user_id, week_num)
      
      unless target_shiftselection
        return render json: { success: false, error: "Không tìm thấy lịch làm việc cho tuần #{week_num}" }, status: :ok
      end
      
      # Tạo Shiftissue cho đề xuất chỉnh sửa kế hoạch làm việc
      issue = Shiftissue.create!(
        shiftselection_id: target_shiftselection.id,
        stype: "EDIT-PLAN",
        status: "PENDING",
        note: reason,
        approved_by: approver_id,
        docs: data[:file],
        # Lưu thông tin tuần vào note hoặc tạo field mới nếu cần
        content: "Tuần #{week_num}"
      )

      # Gửi thông báo
      send_notify("EDIT-PLAN", approver_id)

      render json: {
        success: true,
        message: "Đã gửi đề xuất chỉnh sửa kế hoạch làm việc thành công",
        redirect_url: attends_path,
        request_type: "edit-plan",
        data_input: data,
        week_num: week_num
      }, status: :ok

    rescue => e
      render json: { 
        success: false, 
        error: "Lỗi khi lưu đề xuất: #{e.message}", 
        data_input: data 
      }, status: :ok
    end
  end


  # Get data request attend to display on modal
  # @author: Dat Le
  # @date: 04/07/2025
  # @input: user_id, date
  # @return: JSON data
  def get_data_request_attend
    user_id = session[:user_id]
    all_managers = get_managers
    render json: { all_managers: all_managers}, status: :ok
  end

  # Get data date
  # @author: trong Le
  # @date: 28/07/2025
  def get_data_date_attend
    user_id = session[:user_id]
    date = params[:date]

    return render json: { error: 'Invalid date' }, status: 400 unless user_id.present? && date.present?

    work_date = Date.parse(date) rescue nil
    start_time = work_date.beginning_of_day
    end_time   = work_date.end_of_day
    return render json: { error: 'Invalid date format' }, status: 400 if work_date.nil?

    # Lấy danh sách ca trong ngày
    shiftselections = Shiftselection
                        .includes(:workshift)
                        .where(user_id: user_id, work_date:  start_time..end_time)
                        .where(status: %w[PENDING APPROVED])

    # Dữ liệu chấm công
    shift_ids = shiftselections.map(&:id)
    attends = Attend
                .includes(:attenddetails)
                .where(user_id: user_id, shiftselection_id: shift_ids)
                .index_by(&:shiftselection_id)

    shifts = shiftselections.map do |sel|
      workshift = sel.workshift
      attend = attends[sel.id]

      {
        id: sel.id,
        shift_name: workshift&.name || "",
        shift_type: workshift&.start_time.to_s < "12:00" ? "MORNING" : "AFTERNOON",
        work_time: "#{workshift&.start_time || ''} - #{workshift&.end_time || ''}",
        checkin: attend&.checkin ? attend.checkin.strftime("%H:%M") : "",
        checkout: attend&.checkout ? attend.checkout.strftime("%H:%M") : "",
        status: sel.status,
        is_day_off: sel.is_day_off,
        reason: sel.day_off_reason || ""
      }
    end

    render json: {
      shifts: shifts
    }, status: :ok
  end



  # Get list allow type request attend
  # @author: Dat Le
  # @date: 05/07/2025
  # @input: user_id, date
  # @return: List allow type request attend
  def get_allowed_requests(user_id, date)
    return [] unless date.present?
    date = Date.parse(date) rescue nil
    return [] unless date

    start_time = date.beginning_of_day
    end_time = date.end_of_day

    attend = Attend.where(
      user_id: user_id,
      stype: "ATTENDANCE"
    ).where(
      "checkin BETWEEN ? AND ?", start_time, end_time
    ).first

    has_checkin = attend&.checkin.present?
    has_checkout = attend&.checkout.present?

    # Lấy các yêu cầu đã gửi trong ngày
    attend_id = attend&.id
    sent_requests = if attend_id
                      Attenddetail.where(attend_id: attend_id)
                                  .where("DATE(dtcheckin) = ? OR DATE(dtcheckout) = ?", date, date)
                                  .pluck(:stype)
                    else
                      []
                    end

    allowed = []

    unless sent_requests.include?("LATE-CHECK-IN")
      allowed << "LATE-CHECK-IN" if has_checkin
    end

    unless sent_requests.include?("EARLY-CHECKOUT-OUT")
      allowed << "EARLY-CHECKOUT-OUT" if has_checkout
    end

    unless sent_requests.include?("ADDITIONAL-CHECK-IN")
      allowed << "ADDITIONAL-CHECK-IN" unless has_checkin
    end

    unless sent_requests.include?("ADDITIONAL-CHECK-OUT")
      allowed << "ADDITIONAL-CHECK-OUT" unless has_checkout
    end

    unless sent_requests.include?("OUT-DURING-WORKING")
      allowed << "OUT-DURING-WORKING" if has_checkin
    end

    return allowed
  end

  # Fetch data attend by range date on calendar
  # @author: Trong Le
  # @date: 31/07/2025
  # @input: start, end
  # @return: JSON data attends
  def fetch_all_attends_in_month
    user_id = session[:user_id]
    return render json: [] unless user_id

    begin
      start_date = Date.parse(params[:start])
      end_date   = Date.parse(params[:end])
    rescue
      return render json: { error: 'Invalid date range' }, status: :bad_request
    end

    begin
      campus_map = get_all_campus

      events = []

      # Code cũ - 17/09/2025: Không có error handling cho database queries
      # weeks = Scheduleweek
      #           .select("scheduleweeks.*, CONCAT(users.last_name, ' ', users.first_name) as user_name, users.sid")
      #           .joins("LEFT JOIN users ON users.id = scheduleweeks.user_id")
      #           .where("scheduleweeks.user_id = ?", user_id)
      #           .where("scheduleweeks.start_date <= ? AND scheduleweeks.end_date >= ?", end_date, start_date)
      #           .where(status: %w[PENDING APPROVED])

      # Code cũ - 17/09/2025: Không preload associations
      # weeks = Scheduleweek
      #           .select("scheduleweeks.*, CONCAT(users.last_name, ' ', users.first_name) as user_name, users.sid")
      #           .joins("LEFT JOIN users ON users.id = scheduleweeks.user_id")
      #           .where("scheduleweeks.user_id = ?", user_id)
      #           .where("scheduleweeks.start_date <= ? AND scheduleweeks.end_date >= ?", end_date, start_date)
      #           .where(status: %w[PENDING APPROVED])

      # Code mới - 17/09/2025: Preload associations để tránh N+1 queries
      weeks = Scheduleweek
                .select("scheduleweeks.*, CONCAT(users.last_name, ' ', users.first_name) as user_name, users.sid")
                .joins("LEFT JOIN users ON users.id = scheduleweeks.user_id")
                .includes(:shiftselection => [:workshift, :attend, :shiftissue])
                .where("scheduleweeks.user_id = ?", user_id)
                .where("scheduleweeks.start_date <= ? AND scheduleweeks.end_date >= ?", end_date, start_date)
                .where(status: %w[PENDING APPROVED])
    rescue => e
      logger.error "Error in fetch_all_attends_in_month: #{e.message}"
      return render json: { error: 'Internal server error' }, status: :internal_server_error
    end
    # Sau khi đã gom tất cả weeks và shiftselections:
    begin
      # Code cũ - 17/09/2025: Không có error handling cho work_trips query
      # work_trips = Shiftissue
      #   .joins(:shiftselection)
      #   .select("shiftissues.*, shiftselections.work_date AS shiftselection_work_date")
      #   .where(shiftselections: { scheduleweek_id: weeks.map(&:id) }, stype: 'WORK-TRIP')
      #   .order(:created_at, 'shiftselections.work_date')

      # Code cũ - 17/09/2025: Không preload associations cho work_trips
      # work_trips = Shiftissue
      #   .joins(:shiftselection)
      #   .select("shiftissues.*, shiftselections.work_date AS shiftselection_work_date")
      #   .where(shiftselections: { scheduleweek_id: weeks.map(&:id) }, stype: 'WORK-TRIP')
      #   .order(:created_at, 'shiftselections.work_date')

      # Code mới - 17/09/2025: Preload associations cho work_trips
      work_trips = Shiftissue
        .joins(:shiftselection)
        .includes(:shiftselection)
        .where(shiftselections: { scheduleweek_id: weeks.map(&:id) }, stype: 'WORK-TRIP')
        .order(:created_at, 'shiftselections.work_date')
    rescue => e
      logger.error "Error fetching work_trips: #{e.message}"
      work_trips = []
    end

    # Gom theo ngày tạo
    grouped_by_created = work_trips.group_by { |i| i.created_at }

    grouped_by_created.each do |created_date, issues|
      # Gom các ngày làm việc liên tiếp
      sorted = issues.sort_by { |i| local_date(i.shiftselection.work_date) }

      day_groups = sorted.slice_when do |prev, curr|
        (curr.shiftselection.work_date.to_date - prev.shiftselection.work_date.to_date).to_i > 1
      end

      day_groups.each do |group|
        begin
          # Code cũ - 17/09/2025: N+1 queries không có error handling
          # approved_by_user = User.find_by(id: group.first.approved_by)
          # approved_by_name = approved_by_user ? "#{approved_by_user.last_name} #{approved_by_user.first_name} (#{approved_by_user.sid})" : nil
          # media_file = Mediafile.where(id: group.first.docs, status: "ACTIVE").pluck(:file_name).first
          # image_doc = media_file.present? ? "#{request.base_url}/mdata/hrm/#{media_file}" : nil

          # Code cũ - 17/09/2025: N+1 queries
          # approved_by_user = User.find_by(id: group.first.approved_by)
          # approved_by_name = approved_by_user ? "#{approved_by_user.last_name} #{approved_by_user.first_name} (#{approved_by_user.sid})" : nil
          # media_file = Mediafile.where(id: group.first.docs, status: "ACTIVE").pluck(:file_name).first
          # image_doc = media_file.present? ? "#{request.base_url}/mdata/hrm/#{media_file}" : nil

          # Code cũ - 17/09/2025: N+1 queries nhưng cần thiết vì không có associations
          # approved_by_user = group.first.approved_by_user
          # approved_by_name = approved_by_user ? "#{approved_by_user.last_name} #{approved_by_user.first_name} (#{approved_by_user.sid})" : nil
          # media_file = group.first.mediafile&.file_name
          # image_doc = media_file.present? ? "#{request.base_url}/mdata/hrm/#{media_file}" : nil

          # Code cũ - 17/09/2025: N+1 queries
          # approved_by_user = User.find_by(id: group.first.approved_by)
          # approved_by_name = approved_by_user ? "#{approved_by_user.last_name} #{approved_by_user.first_name} (#{approved_by_user.sid})" : nil
          # media_file = Mediafile.where(id: group.first.docs, status: "ACTIVE").pluck(:file_name).first
          # image_doc = media_file.present? ? "#{request.base_url}/mdata/hrm/#{media_file}" : nil

          # Code cũ - 17/09/2025: Associations không tồn tại
          # approved_by_user = group.first.approved_by_user
          # media_file = group.first.mediafile&.file_name

          # Code mới - 17/09/2025: N+1 queries với error handling (vì associations không tồn tại)
          approved_by_user = User.find_by(id: group.first.approved_by)
          approved_by_name = approved_by_user ? "#{approved_by_user.last_name} #{approved_by_user.first_name} (#{approved_by_user.sid})" : nil
      
          media_file = Mediafile.where(id: group.first.docs, status: "ACTIVE").pluck(:file_name).first
          image_doc = media_file.present? ? "#{request.base_url}/mdata/hrm/#{media_file}" : nil
        rescue => e
          logger.error "Error processing work-trip group: #{e.message}"
          approved_by_name = nil
          image_doc = nil
        end
        start_date = local_date(group.first.shiftselection.work_date)
        end_date_exclusive = local_date(group.last.shiftselection.work_date) + 1
        status = group.first.status
        status_class = case status
                       when 'APPROVED' then 'fc-week-approved'
                       when 'PENDING'  then 'fc-week-pending'
                       when 'REJECTED' then 'fc-week-rejected'
                       else 'fc-week-unknown'
                       end
        color = case status
                when 'APPROVED' then '#10b981'  # xanh lá cây
                when 'PENDING'  then '#f59e0b'  # cam
                when 'REJECTED' then '#ec172c'  # đỏ
                else '#9ca3af'                 # xám mặc định nếu unknown
                end
        current_date_str = if start_date == (end_date_exclusive - 1)
          start_date.strftime('%Y-%m-%d')
        else
          "#{start_date.strftime('%d-%m-%Y')} đến #{(end_date_exclusive - 1).strftime('%d-%m-%Y')}"
        end
        # Code cũ - @author: trong.lq @date: 30/10/2025
        # events << {
        #   title: '✈️ Đi công tác',
        #   start: start_date.strftime('%Y-%m-%d'),
        #   end: end_date_exclusive.strftime('%Y-%m-%d'),
        #   allDay: true,
        #   displayOrder: 2,
        #   color: color,
        #   textColor: '#04288d',
        #   classNames: [status_class],
        #   extendedProps: {
        #     type: 'SHIFT_ISSUE',
        #     stype: 'WORK-TRIP',
        #     status: status,
        #     currentDate: current_date_str,
        #     note: group.first.note,
        #     approved_by: approved_by_name,
        #     docs: image_doc,
        #     current_workshift: "Đi công tác",
        #     created_date: created_date,
        #     count: group.size,
        #     shiftselection_ids: group.map(&:shiftselection_id),
        #     dates: group.map { |i| local_date(i.shiftselection.work_date).strftime('%Y-%m-%d') }
        #   }
        # }

        # Code mới - @author: trong.lq @date: 30/10/2025
        # Bổ sung grouped_work_trips (chi tiết ca theo từng ngày) và current_workshift tóm tắt
        grouped_work_trips = group.map do |item|
          ss = item.shiftselection
          work_date = local_date(ss.work_date).strftime('%Y-%m-%d') rescue nil
          st = ss.start_time
          en = ss.end_time
          # Suy ra tên ca dựa theo giờ bắt đầu (sáng/chiều) nếu không có name
          shift_name = begin
            if st.to_s < '12:00'
              'Sáng'
            else
              'Chiều'
            end
          rescue
            'Ca'
          end
          { work_date: work_date, shift_name: shift_name, start_time: st, end_time: en }
        end

        # Tính current_workshift tóm tắt: "Cả ngày" / "Sáng" / "Chiều" / "Nhiều ca"
        summary = begin
          # Gom theo ngày => set có sáng/chiều
          by_date = {}
          grouped_work_trips.each do |it|
            d = it[:work_date]
            by_date[d] ||= { morning: false, afternoon: false }
            if it[:shift_name] == 'Sáng'
              by_date[d][:morning] = true
            else
              by_date[d][:afternoon] = true
            end
          end

          days = by_date.values
          if days.all? { |h| h[:morning] && h[:afternoon] }
            'Cả ngày'
          elsif days.all? { |h| h[:morning] && !h[:afternoon] }
            'Sáng'
          elsif days.all? { |h| !h[:morning] && h[:afternoon] }
            'Chiều'
          else
            'Nhiều ca'
          end
        rescue
          'Đi công tác'
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
            status: status,
            currentDate: current_date_str,
            note: group.first.note,
            approved_by: approved_by_name,
            docs: image_doc,
            # Code cũ: current_workshift: "Đi công tác",
            current_workshift: summary,
            created_date: created_date,
            count: group.size,
            shiftselection_ids: group.map(&:shiftselection_id),
            dates: group.map { |i| local_date(i.shiftselection.work_date).strftime('%Y-%m-%d') },
            grouped_work_trips: grouped_work_trips
          }
        }
      end
    end



    weeks.each do |week|
      # ✅ Thêm long event “Chờ duyệt” cho tuần đang PENDING
      if week.status == 'PENDING'
        wk_start = week.start_date.to_date
        wk_end_exclusive = week.end_date.to_date + 1.day # end exclusive
        events << {
          title: '⏳Chờ duyệt',
          start: wk_start.strftime('%Y-%m-%d'),
          end:   wk_end_exclusive.strftime('%Y-%m-%d'),
          week: week.status,
          allDay: true,
          display: 'block',
          displayOrder: 0,               # ưu tiên hiển thị
          color: '#f59e0b',              # cam (nền)
          textColor: '#fff',             # chữ trắng
          classNames: ['fc-week-pending']# để bạn CSS riêng nếu muốn
        }
      end

      
      # Code cũ - 17/09/2025: Không preload associations
      # shiftselections = Shiftselection
      #                     .includes(:workshift)
      #                     .where(scheduleweek_id: week.id)

      # Code cũ - 17/09/2025: Sai association name
      # shiftselections = week.shiftselections

      # Code mới - 17/09/2025: Sử dụng association name đúng
      shiftselections = week.shiftselection

      shiftselections.each do |sel|
        workshift = sel.workshift
        next unless workshift

        shift_type = (workshift.start_time && workshift.start_time < "12:00") ? "MORNING" : "AFTERNOON"

        # Code cũ - 17/09/2025: N+1 queries
        # attend = Attend.find_by(shiftselection_id: sel.id)
        # checkin  = attend&.checkin&.strftime("%H:%M") || ''
        # checkout = attend&.checkout&.strftime("%H:%M") || ''
        # has_work_trip = Shiftissue.where(stype: "WORK-TRIP", status: "APPROVED", shiftselection_id: sel.id).exists?

        # Code mới - 17/09/2025: Sử dụng preloaded data
        attend = sel.attend
        checkin  = attend&.checkin&.strftime("%H:%M") || ''
        checkout = attend&.checkout&.strftime("%H:%M") || ''
        has_work_trip = sel.shiftissue.any? { |si| si.stype == "WORK-TRIP" && si.status == "APPROVED" }

        # === Ca làm chính ===
        events << {
          title: '',
          user_id: user_id,
          user_name: week.user_name,
          sid: week.sid,
          week_num: week.week_num,
          work_date: sel.work_date.strftime('%Y-%m-%d'),
          start: sel.work_date.strftime('%Y-%m-%d'),
          end: sel.work_date.strftime('%Y-%m-%d'),
          allDay: true,
          displayOrder: 1,
          status: week.status,
          classNames: [sel.status == "APPROVED" ? "fc-shift-approved" : sel.status === "REJECTED" ? "fc-shift-rejected" : "fc-shift-pending"],
          extendedProps: {
            type: "DAY_STATUS",
            shiftselection_id: sel.id,
            shift_name: workshift.name,
            shift_type: shift_type,
            schedule_week_id: week.id,
            default_shift_start_time: workshift.start_time || '',
            default_shift_end_time: workshift.end_time || '',
            registered_shift_start_time: sel.start_time || "00:00",
            registered_shift_end_time: sel.end_time || "00:00",
            checkin: checkin,
            checkout: checkout,
            location:campus_map[sel.location] || '',
            approved_by: week.checked_by,
            reason: sel.day_off_reason,
            is_day_off: has_work_trip ? "WORK-TRIP" : sel.is_day_off
          }
        }

        # === Đề xuất lịch làm việc (Shiftissue) ===
        # Code cũ - 17/09/2025: N+1 query
        # Shiftissue.where(shiftselection_id: sel.id).each do |i|

        # Code mới - 17/09/2025: Sử dụng preloaded data
        sel.shiftissue.each do |i|
          begin
            # Code cũ - 17/09/2025: N+1 queries không có error handling
            # stype_key = i.stype.to_s.tr('_', '-')
            # type_name = REQUEST_TYPE_NAMES[stype_key] || i.stype.titleize
            # time_info = []
            # time_info << i.us_start if i.us_start.present?
            # time_info << i.us_end if i.us_end.present?
            # time_display = time_info.any? ? " (#{time_info.join(' - ')})" : ""
            # user = User.find_by(id: i.approved_by)
            # approved_by_name = user ? "#{user.last_name} #{user.first_name} (#{user.sid})" : ""
            # media_file = Mediafile.where(id: i.docs, status: "ACTIVE").pluck(:file_name).first
            # image_doc = media_file.present? ? "#{request.base_url}/mdata/hrm/#{media_file}" : nil
            # current_shiftissue  = Shiftselection.find_by(id: i.shiftselection_id)
            # workshift = Workshift.where(id: current_shiftissue.workshift_id).pluck(:name).first
            # current_workshift = "#{workshift} #{current_shiftissue.start_time} - #{current_shiftissue.end_time}"

            # Code cũ - 17/09/2025: N+1 queries
            # user = User.find_by(id: i.approved_by)
            # approved_by_name = user ? "#{user.last_name} #{user.first_name} (#{user.sid})" : ""
            # media_file = Mediafile.where(id: i.docs, status: "ACTIVE").pluck(:file_name).first
            # image_doc = media_file.present? ? "#{request.base_url}/mdata/hrm/#{media_file}" : nil
            # current_shiftissue  = Shiftselection.find_by(id: i.shiftselection_id)
            # workshift = Workshift.where(id: current_shiftissue.workshift_id).pluck(:name).first
            # current_workshift = "#{workshift} #{current_shiftissue.start_time} - #{current_shiftissue.end_time}"

            # Code cũ - 17/09/2025: Associations không tồn tại
            # user = i.approved_by_user
            # media_file = i.mediafile&.file_name

            # Code cũ - 17/09/2025: N+1 queries
            # user = User.find_by(id: i.approved_by)
            # approved_by_name = user ? "#{user.last_name} #{user.first_name} (#{user.sid})" : ""
            # media_file = Mediafile.where(id: i.docs, status: "ACTIVE").pluck(:file_name).first
            # image_doc = media_file.present? ? "#{request.base_url}/mdata/hrm/#{media_file}" : nil

            # Code cũ - 17/09/2025: Associations không tồn tại
            # user = i.approved_by_user
            # media_file = i.mediafile&.file_name

            # Code mới - 17/09/2025: N+1 queries với error handling (vì associations không tồn tại)
            stype_key = i.stype.to_s.tr('_', '-')
            type_name = REQUEST_TYPE_NAMES[stype_key] || i.stype.titleize

            time_info = []
            time_info << i.us_start if i.us_start.present?
            time_info << i.us_end if i.us_end.present?
            time_display = time_info.any? ? " (#{time_info.join(' - ')})" : ""
            user = User.find_by(id: i.approved_by)
            approved_by_name = user ? "#{user.last_name} #{user.first_name} (#{user.sid})" : ""
            media_file = Mediafile.where(id: i.docs, status: "ACTIVE").pluck(:file_name).first
            image_doc = media_file.present? ? "#{request.base_url}/mdata/hrm/#{media_file}" : nil
            current_shiftissue = i.shiftselection
            workshift = current_shiftissue.workshift
            current_workshift = "#{workshift.name} #{current_shiftissue.start_time} - #{current_shiftissue.end_time}"
          rescue => e
            logger.error "Error processing shiftissue: #{e.message}"
            next # Skip this shiftissue if there's an error
          end
          if i.ref_shift_changed.present?
            shiftselection_change = get_shiftselection_by_id(i.ref_shift_changed)
            to_workshift  = "#{shiftselection_change[:workshift]} #{shiftselection_change[:start_time]} - #{shiftselection_change[:end_time]}"
            to_date = shiftselection_change[:work_date]
            to_user = shiftselection_change[:user_name]
          end

          next if i.stype == "WORK-TRIP"
          events << {
            title: "📅 #{type_name}#{time_display}",
            start: sel.work_date.strftime('%Y-%m-%d'),
            end: sel.work_date.strftime('%Y-%m-%d'),
            allDay: true,
            displayOrder: 3,
            classNames: [i.status == "APPROVED" ? "fc-shift-approved" : i.status === "REJECTED" ? "fc-shift-rejected" : "fc-shift-pending"],
            extendedProps: {
              type: "SHIFT_ISSUE",
              shiftselection_id: sel.id,
              current_workshift: current_workshift,
              stype: i.stype,
              note: i.note,
              content: i.content,
              approved_by: approved_by_name,
              status: i.status,
              us_start: i.us_start,
              us_end: i.us_end,
              docs: image_doc,
              to_user:   to_user || nil,
              to_date:   to_date || nil,
              to_workshift:  to_workshift || nil
            }
          }
        end
      end
    end

    events.sort_by! { |e| e[:start].is_a?(String) ? Time.zone.parse(e[:start]) : e[:start] }

    render json: events
  end

  def get_image_evidence
    detail_id = params[:detail_id]
    detail = Attenddetail.find_by(id: detail_id)
    return render json: { error: 'Detail not found' }, status: 404 unless detail
    image = Mediafile.where(id: detail.pic, status: "ACTIVE").pluck(:file_name).first
    render json: { docs: image.present? ? "#{request.base_url}/mdata/hrm/#{image}" : nil }, status: :ok
  end

  def approve_request
    detail_id = params[:detail_id]
    detail = Attenddetail.find_by(id: detail_id)
    return render json: { error: 'AttendDetail not found' }, status: :not_found unless detail

    ActiveRecord::Base.transaction do
      detail.update!(
        status: "APPROVED",
        approved_at: Time.current
      )

      if detail.stype == "ADDITIONAL-CHECK-IN"
        detail.attend.update!(checkin: detail.dtcheckin)
      elsif detail.stype == "ADDITIONAL-CHECK-OUT"
        detail.attend.update!(checkout: detail.dtcheckout)
      end
    end

    render json: { message: "Phê duyệt thành công" }, status: :ok
  rescue => e
    Rails.logger.error e.full_message
    render json: { error: "Đã có lỗi xảy ra khi xử lý" }, status: :internal_server_error
  end

  def reject_request
    detail_id = params[:detail_id]
    detail = Attenddetail.find_by(id: detail_id)
    return render json: { error: 'AttendDetail not found' }, status: :not_found unless detail

    ActiveRecord::Base.transaction do
      detail.update!(
        status: "REJECTED",
        approved_at: Time.current
      )
    end
    render json: { message: "Từ chối thành công" }, status: :ok
  rescue => e
    Rails.logger.error e.full_message
    render json: { error: "Đã có lỗi xảy ra khi xử lý" }, status: :internal_server_error
  end

  def map_stype_label(stype)
    {
      "LATE-CHECK-IN" => "Xin phép đi trễ",
      "EARLY-CHECKOUT-OUT" => "Xin phép về sớm",
      "ADDITIONAL-CHECK-IN" => "Chấm công vào làm bù",
      "ADDITIONAL-CHECK-OUT" => "Chấm công tan làm bù",
      "OUT-DURING-WORKING" => "Ra ngoài trong giờ làm"
    }[stype] || stype.titleize
  end

  def map_badge_class(status)
    {
      "PENDING" => "badges-pending",
      "APPROVED" => "badges-approved",
      "REJECTED" => "badges-rejected",
    }[status.to_s.upcase] || "badge-default"
  end

  def map_status_label(status)
    case status
    when "APPROVED"
      "Đã phê duyệt"
    when "REJECTED"
      "Từ chối"
    when "PENDING"
      "Chờ phê duyệt"
    else
      status
    end
  end

  def get_shiftselection_by_id(id)
    # Code cũ - 17/09/2025: Không có error handling cho RecordNotFound
    # shift = Shiftselection.find(id)
    
    # Code mới - 17/09/2025: Thêm error handling cho RecordNotFound
    begin
      shift = Shiftselection
                .includes(:scheduleweek)
                .select(:id, :workshift_id, :work_date, :start_time, :end_time, :scheduleweek_id)
                .find(id)
    rescue ActiveRecord::RecordNotFound => e
      logger.error "Shiftselection with id=#{id} not found: #{e.message}"
      return {
        workshift: "Không tìm thấy",
        start_time: "",
        end_time: "",
        work_date: "",
        user_name: ""
      }
    end

    worksfhit = Workshift.where(id: shift.workshift_id).pluck(:name).first
    user = User.find_by(id: shift.scheduleweek&.user_id)
    user_name = user ? "#{user.last_name} #{user.first_name} (#{user.sid})" : ""
    {
      workshift:    worksfhit,
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

  def local_date(datetime)
    datetime.in_time_zone("Asia/Ho_Chi_Minh").to_date
  end

  # Helper method để lấy campus map
  # def get_campus_map
  #   @campus_map ||= begin
  #     campuses_response = call_api(@CSVC_PATH + "api/v1/mapi_utils/get_all_campuses")
  #     campuses = campuses_response["result"].is_a?(Array) ? campuses_response["result"] : []
  #     campuses.map { |c| [c["scode"], c["name"]] }.to_h
  #   rescue => e
  #     logger.error "Failed to fetch campuses: #{e.message}"
  #     {}
  #   end
  # end

  def validate_attend_request_conditions(user_id, date, workshift_id,  request_type)
    # 1. Ngày không thuộc tháng hiện tại
    today = Time.zone.today
   # Chỉ cho phép tạo đề xuất cho tháng hiện tại hoặc tháng tiếp theo
    max_allowed_month = today.next_month.beginning_of_month

    # if date < today.beginning_of_month || date > max_allowed_month.end_of_month
    #   return "Chỉ được tạo đề xuất cho tháng hiện tại hoặc tháng kế tiếp"
    # end
    # Chỉ kiểm tra nếu không phải work-trip
    return true if %w[work-trip shift-change].include?(request_type)
    # 2. Tìm ca làm việc tại ngày đó
    shift = find_shift(user_id, date, workshift_id, include_day_off: true)
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

  # Tìm shiftselection của ngày hiện tại cho đề xuất chỉnh sửa kế hoạch
  # @author: trong.lq
  # @date: 22/10/2025
  # @input: user_id, week_num
  # @return: Shiftselection object
  def find_shiftselection_for_edit_plan(user_id, week_num)
    # Tìm shiftselection của ngày hiện tại
    # @author: trong.lq
    # @date: 22/10/2025
    # Tìm ca làm việc của ngày hiện tại - cách gọn nhất
    # @author: trong.lq
    # @date: 23/10/2025
    first_shift = Shiftselection
                    .joins(:scheduleweek)
                    .where(scheduleweeks: { user_id: user_id, week_num: week_num, status: "APPROVED" })
                    .first

    first_shift || Shiftselection.joins(:scheduleweek)
                                 .where(scheduleweeks: { user_id: user_id })
                                 .where(work_date: Date.today.beginning_of_day..Date.today.end_of_day)
                                 .first
  end

end
