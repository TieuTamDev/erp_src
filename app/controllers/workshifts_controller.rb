class WorkshiftsController < ApplicationController
  before_action :authorize
  include AttendConcern

  # Dat Le 16/7/2025
  def index
    if current_user.nil?
      redirect_to login_path, alert: "Vui lòng đăng nhập để tiếp tục."
      return
    end
    search = params[:search] || ''
    sql = Workshift.where("name LIKE ?", "%#{search}%").order(created_at: :asc)
    @workshifts = pagination_limit_offset(sql, 10)
  end

  def update
    id = params[:workshift_id]
    pName = params[:workshift_name]
    pStart_time = params[:workshift_start_time]
    pEnd_time = params[:workshift_end_time]
    pCheckin_start = params[:workshift_checkin_start]
    pCheckin_end = params[:workshift_checkin_end]
    pCheckout_start = params[:workshift_checkout_start]
    pCheckout_end = params[:workshift_checkout_end]
    msg = lib_translate("Not_Success")

    if id == ""
      workshift = Workshift.new
      workshift.id = id
      workshift.name = pName
      workshift.start_time = pStart_time
      workshift.end_time = pEnd_time
      workshift.checkin_start = pCheckin_start
      workshift.checkin_end = pCheckin_end
      workshift.checkout_start = pCheckout_start
      workshift.checkout_end = pCheckout_end
      workshift.save
      msg = lib_translate("Create_successfully")
    else
      oWorkshift = Workshift.where("id = #{id}").first
      msg = lib_translate("Not_Success")
      if !oWorkshift.nil?
        oWorkshift.update({
                            name: pName,
                            start_time: pStart_time,
                            end_time: pEnd_time,
                            checkin_start: pCheckin_start,
                            checkin_end: pCheckin_end,
                            checkout_start: pCheckout_start,
                            checkout_end: pCheckout_end,
                          })

        change_column_value = oWorkshift.previous_changes
        change_column_name = oWorkshift.previous_changes.keys
        if change_column_name != ""
          for changed_column in change_column_name do
            if changed_column != "updated_at"
              fvalue = change_column_value[changed_column][0]
              tvalue = change_column_value[changed_column][1]
              log_history(Workshift, changed_column, fvalue, tvalue, @current_user.email)
            end
          end
        end
        msg = lib_translate("Update_successfully")
      end
    end
    redirect_to workshifts_index_path(lang: session[:lang], page: session[:page], per_page: session[:per_page], search: session[:search]), notice: msg
  end

  def destroy
    workshift_id = params[:id]
    workshift = Workshift.where("id = #{workshift_id}").first
    msg = lib_translate("Not_Success")
    if !workshift.nil?
      workshift.destroy
      log_history(Workshift, "Xóa", workshift.name, "Đã xóa khỏi hệ thống", @current_user.email)
      msg = lib_translate("Delete_successfully")
    end
    redirect_to workshifts_index_path(lang: session[:lang], page: session[:page], per_page: session[:per_page], search: session[:search]), notice: msg
  end

  # Get all workshift
  # @author: Dat Le
  # @date: 16/07/2025
  # @input: nil
  # @return [ActiveRecord::Relation<Workshift>]
  def get_all_workshifts
    workshifts = Workshift.all.map do |item|
      {
        id: item.id,
        label: item.name,
        code: slugify(item.name),
        start: item.checkin_start,
        end: item.checkout_end,
        min: item.start_time,
        max: item.end_time,
      }
    end

    render json: workshifts
  end

  # Get list of all approving managers
  # @author: Dat Le
  # @date: 16/07/20255
  # @input: user_id
  # @return: JSON data
  def get_all_managers
    user_id = session[:user_id]
    return render json: { error: 'Invalid user' }, status: 400 unless user_id.present?
    all_managers = get_managers
    render json: all_managers
  end

  # Configure user into the room
  # @author: Dat Le
  # @date: 28/07/20255
  # @input: nil
  # @return: nil
  def room_configuration
    if current_user.nil?
      redirect_to login_path, alert: "Vui lòng đăng nhập để tiếp tục."
      return
    end

    rooms_response = call_api(@CSVC_PATH + "api/v1/mapi_utils/get_all_rooms")
    rooms_data = rooms_response["data"].is_a?(Array) ? rooms_response["data"] : []

    # Phân trang
    per_page = [(params[:per_page] || 25).to_i, 1].max
    page     = [(params[:page] || 1).to_i, 1].max
    offset   = (page - 1) * per_page

    @results_total = rooms_data.size
    @total_pages = (@results_total.to_f / per_page).ceil
    @page = page
    @per_page = per_page
    page_rooms = rooms_data.slice(offset, per_page) || []

    @rooms = page_rooms.map do |item|
      {
        id: item["id"],
        location: item["location"],
        name: item["name"],
        building: item["building"]
      }
    end
  end

  # Get all users with room
  # @author: Dat Le
  # @date: 29/07/20255
  # @input: nil
  # @return: json
  def get_all_users
    users = User.where(status: "ACTIVE").select(:id, :first_name, :last_name, :sid, :sroom, :status).map do |u|
      { id: u.id, text: "#{u.last_name} #{u.first_name} (#{u.sid})", sroom: u.sroom }
    end
    by_room = users.group_by { |u| u[:sroom] }.transform_values { |arr| arr.map{|u|u[:id]} }
    render json: { users: users, by_room: by_room }
  end

  # Update user into the room
  # @author: Dat Le
  # @date: 29/07/20255
  # @input: room_id, user_ids
  # @return: json
  def update_sroom_users
    room_id = params[:id]
    ids  = Array(params[:user_ids]).map(&:to_i)
    User.where(sroom: room_id).where.not(id: ids).update_all(sroom: nil)
    User.where(id: ids).update_all(sroom: room_id)
    render json: { success: true }, status: :ok
  end

  # Get Shiftselections details by id
  # @author: Dat Le
  # @date: 02/07/2025
  # @input: attend_id
  # @return [ActiveRecord::Relation<Shiftselections>] Selections
  def get_shiftselection_detail
    ids = params[:ids].to_s.split('|').map(&:presence).compact.map(&:to_i).uniq
    return render json: { status: false, message: "Không tìm thấy chấm công" }, status: :not_found if ids.empty?

    shifts = Shiftselection
               .includes({ attend: :attenddetails }, :workshift, :shiftissue, scheduleweek: :user)
               .where(id: ids)

    if shifts.blank?
      return render json: { status: false, message: "Không tìm thấy lịch làm việc" }, status: :not_found
    end

    user = shifts.first.scheduleweek&.user
    unless user
      return render json: { status: false, message: "Không tìm thấy nhân viên" }, status: :not_found
    end

    campus_map = get_all_campus

    # ====== Build local caches ======
    all_issues = shifts.flat_map(&:shiftissue)

    # Ảnh (CHECKIN/CHECKOUT + issue.docs)
    pic_ids = shifts.flat_map do |s|
      ad = s.attend&.attenddetails || []
      [
        ad.find { |d| d.stype == "CHECKIN" }&.pic,
        ad.find { |d| d.stype == "CHECKOUT" }&.pic
      ]
    end.compact
    doc_ids = all_issues.map(&:docs).compact
    media_ids = (pic_ids + doc_ids).uniq
    media_map = Mediafile
                  .where(id: media_ids, status: "ACTIVE")
                  .pluck(:id, :file_name)
                  .map { |id, fname| [id.to_s, fname] }
                  .to_h

    # ref shifts (đổi ca)
    ref_ids = all_issues.map { |i| i.ref_shift_changed }.compact.uniq.map(&:to_i)
    shift_refs = Shiftselection.includes(:scheduleweek).where(id: ref_ids).index_by(&:id)

    # Workshift map (cho current & ref)
    workshift_ids = (shifts.map(&:workshift_id) + shift_refs.values.map(&:workshift_id)).compact.uniq
    workshift_map = Workshift.where(id: workshift_ids).pluck(:id, :name).to_h

    # Users (approved_by + user của ref)
    user_ids = all_issues.map(&:approved_by).compact +
               shift_refs.values.map { |sr| sr.scheduleweek&.user_id }.compact
    user_map =
      if user_ids.present?
        User.where(id: user_ids.uniq)
            .pluck(:id, :last_name, :first_name, :sid)
            .map { |id, ln, fn, sid| [id, "#{ln} #{fn} (#{sid})"] }
            .to_h
      else
        {}
      end

    base_url = request.base_url

    # Avatar người dùng
    mediafile_id = Doc.where(user_id: user.id).limit(1).pluck(:mediafile_id).first
    avatar_name  = mediafile_id && media_map[mediafile_id] ||
                   Mediafile.where(id: mediafile_id, status: "ACTIVE").limit(1).pluck(:file_name).first
    avatar = avatar_name.present? ? "#{base_url}/mdata/hrm/#{avatar_name}" : "#{base_url}#{view_context.image_path('no_avatar.jpg')}"

    positionjob = get_department_name(user.id)
    department_name  = positionjob[:department_name]
    positionjob_name = positionjob[:positionjob_name]

    # ====== Render ======
    render json: {
      id:   user.id,
      user_id:   user.sid,
      user_name: "#{user.last_name} #{user.first_name}",
      department_name: department_name,
      position_job: positionjob_name,
      user_image: avatar,
      shifts: shifts.map { |s|
        serialize_shiftselection(
          s,
          campus_map: campus_map,
          media_map: media_map,
          workshift_map: workshift_map,
          base_url: base_url
        )
      },
      issues: all_issues.uniq { |i| i.id }.map { |i|
        serialize_shiftissue(
          i,
          media_map: media_map,
          workshift_map: workshift_map,
          user_map: user_map,
          shift_refs: shift_refs,
          base_url: base_url
        )
      }
    }, status: :ok
  end

  # Update attend for user
  # @author: Dat Le
  # @date: 07/08/2025
  # @input: attend_id, field, val
  # @return [ActiveRecord::Relation<AttendDetails>]
  def update_attend
    attend_id = params[:attend_id]
    user_id = params[:user_id]
    shiftselection_id = params[:shiftselection_id]
    io        = params[:field]
    value     = params[:value]
    work_date     = params[:work_date]

    return render json: { success: false, msg: 'missing_params' },
                  status: :unprocessable_entity if io.blank? || value.blank? || work_date.blank? || shiftselection_id.blank?
    attend = nil
    new_datetime = Time.zone.strptime("#{work_date} #{value}", "%d/%m/%Y %H:%M")
    ActiveRecord::Base.transaction do
      if attend_id.blank? || attend_id.to_s.downcase == 'null'
        # Tạo mới attend
        attend = Attend.create!(
          stype: 'ATTENDANCE',
          user_id: user_id,
          checkin: (io == 'in' ? new_datetime : nil),
          checkout: (io == 'out' ? new_datetime : nil),
          status: io == 'in' ? "CHECKIN" : "CHECKOUT",
          note: "Trưởng phòng cập nhật giờ chấm công",
          shiftselection_id: shiftselection_id
        )

        # Thêm attenddetails tương ứng
        if io == 'in'
          attend.attenddetails.create!(stype: 'CHECKIN', dtcheckin: attend.checkin)
        else
          attend.attenddetails.create!(stype: 'CHECKOUT', dtcheckout: attend.checkout)
        end

        log_history(Attend, "#{io == 'in' ? 'Checkin' : 'Checkout'}-#{attend.id}",
                    nil, value, @current_user.email)
      else
        # Update attend đã có
        attend = Attend.find_by(id: attend_id)
        return render json: { success: false, msg: 'attend_not_found' },
                      status: :not_found unless attend

        if io == 'in'
          old_value = attend.checkin&.strftime("%H:%M")
          attend.update!(checkin: new_datetime, status: "CHECKIN")
          detail = attend.attenddetails.find_by(stype: 'CHECKIN')
          if detail
            detail.update!(dtcheckin: new_datetime)
          else
            attend.attenddetails.create!(stype: 'CHECKIN', dtcheckin: new_datetime)
          end
          log_history(Attend, "Checkin-#{attend_id}", old_value, value, @current_user.email)
        else
          old_value = attend.checkout&.strftime("%H:%M")
          attend.update!(checkout: new_datetime, status: "CHECKOUT")
          detail = attend.attenddetails.find_by(stype: 'CHECKOUT')
          if detail
            detail.update!(dtcheckout: new_datetime)
          else
            attend.attenddetails.create!(stype: 'CHECKOUT', dtcheckout: new_datetime)
          end
          log_history(Attend, "Checkout-#{attend_id}", old_value, value, @current_user.email)
        end
      end
    end

    render json: { success: true, attend_id: attend.id }, status: :ok

  rescue ActiveRecord::RecordInvalid => e
    render json: { success: false, msg: e.message }, status: :unprocessable_entity
  rescue => e
    Rails.logger.error(e)
    render json: { success: false, msg: 'update_failed' }, status: :internal_server_error
  end

  def serialize_shiftselection(s, campus_map:, media_map: nil, workshift_map: nil, base_url: nil)
    attend = s.attend
    attenddetails = attend&.attenddetails || []

    checkin_img_id  = attenddetails.find { |d| d.stype == "CHECKIN" }&.pic
    checkout_img_id = attenddetails.find { |d| d.stype == "CHECKOUT" }&.pic

    has_work_trip = Array(s.shiftissue).any? do |si|
      si.stype.to_s.upcase == 'WORK-TRIP' && si.status.to_s.upcase.start_with?('APPROVED')
    end
    is_day_off = has_work_trip ? 'WORK-TRIP' : s.is_day_off

    {
      id:       attend&.id,
      shiftselection_id: s.id,
      label:    s.workshift&.name || workshift_map&.dig(s.workshift_id),
      code:     slugify((s.workshift&.name || workshift_map&.dig(s.workshift_id)).to_s),
      start:    s.start_time,
      end:      s.end_time,
      is_day_off: is_day_off,
      # location: campus_map[s.location] || nil,
      location: s.location.to_s.split('$$$').map { |code| campus_map[code.strip] }.compact.join('/ ') || nil,
      checkin:  attend&.checkin&.strftime('%H:%M'),
      checkout: attend&.checkout&.strftime('%H:%M'),
      checkin_img: image_url_cached(checkin_img_id, media_map, base_url),
      checkout_img: image_url_cached(checkout_img_id, media_map, base_url)
    }
  end

  def serialize_shiftissue(i, media_map: nil, workshift_map: nil, user_map: nil, shift_refs: nil, base_url: nil)
    current_shiftselection  = i.shiftselection
    current_workshift_name  = current_shiftselection&.workshift&.name || workshift_map&.dig(current_shiftselection&.workshift_id)
    current_workshift = "#{current_workshift_name} #{current_shiftselection&.start_time} - #{current_shiftselection&.end_time}"

    payload = {
      id:          i.id,
      shiftselection_id: i.shiftselection_id,
      stype:       i.stype,
      status:      i.status,
      approved_by: get_username_by_id(i.approved_by, user_map: user_map),
      us_start:    i.us_start,
      us_end:      i.us_end,
      reason:      i.note,
      current_workshift: current_workshift,
      ref_shift_changed: i.ref_shift_changed,
      pic:         image_url_cached(i.docs, media_map, base_url)
    }

    case i.stype
    when 'LATE-CHECK-IN', 'ADDITIONAL-CHECK-IN'
      payload[:time] = i.us_start
    when 'EARLY-CHECK-OUT', 'ADDITIONAL-CHECK-OUT'
      payload[:time] = i.us_end
    when 'SHIFT-CHANGE'
      shiftselection_change = get_shiftselection_by_id(i.ref_shift_changed, shift_refs: shift_refs, workshift_map: workshift_map, user_map: user_map)
      if shiftselection_change
        to_workshift  = "#{shiftselection_change[:workshift]} #{shiftselection_change[:start_time]} - #{shiftselection_change[:end_time]}"
        to_date = shiftselection_change[:work_date]
        to_user = shiftselection_change[:user_name]

        payload.merge!(
          to_user:   to_user,
          to_date:   to_date,
          to_workshift:  to_workshift
        )
      end
    when 'UPDATE-SHIFT'
      payload.merge!(
        time_changed: "#{i.us_start} - #{i.us_end}"
      )
    end

    payload
  end

  def get_image_by_id(id, media_map: nil, base_url: nil)
    return nil if id.blank?
    if media_map && base_url
      fname = media_map[id]
      return fname.present? ? "#{base_url}/mdata/hrm/#{fname}" : nil
    end
    image = Mediafile.where(id: id, status: "ACTIVE").pluck(:file_name).first
    image.present? ? "#{request.base_url}/mdata/hrm/#{image}" : nil
  end

  def get_username_by_id(user_id, user_map: nil)
    return "" if user_id.blank?
    if user_map
      val = user_map[user_id] ||
            user_map[user_id.to_i] ||
            user_map[user_id.to_s.to_i]
      return val if val
    end
    user = User.find_by(id: user_id)
    user ? "#{user.last_name} #{user.first_name} (#{user.sid})" : ""
  end

  def get_workshift_name_by_id(id, workshift_map: nil)
    return nil if id.blank?
    if workshift_map
      return workshift_map[id]
    end
    Workshift.where(id: id).pluck(:name).first
  end

  def get_shiftselection_by_id(id, shift_refs: nil, workshift_map: nil, user_map: nil)
    return nil if id.blank?
    if shift_refs
      shift = shift_refs[id.to_i]
    else
      shift = Shiftselection
                .includes(:scheduleweek)
                .select(:id, :workshift_id, :start_time, :end_time, :scheduleweek_id)
                .find_by(id: id)
    end
    return nil unless shift

    {
      workshift: get_workshift_name_by_id(shift.workshift_id, workshift_map: workshift_map),
      start_time:   shift.start_time,
      end_time:     shift.end_time,
      work_date:    shift.scheduleweek&.start_date&.strftime('%d/%m/%Y'),
      user_name:    get_username_by_id(shift.scheduleweek&.user_id, user_map: user_map)
    }
  end

  def image_url_cached(id, media_map, base_url)
    return nil if id.blank?
    if media_map && base_url
      fname = media_map[id]
      return fname.present? ? "#{base_url}/mdata/hrm/#{fname}" : nil
    end
    get_image_by_id(id)
  end

  def export_excel
    if current_user.nil?
      redirect_to login_path, alert: "Vui lòng đăng nhập để tiếp tục."
      return
    end

    from_date = Date.new(params[:year].to_i, params[:month].to_i, 1)
    to_date   = from_date.end_of_month
    department_id = params[:department_id]
    user_id = params[:user_id]
    export_type = params[:export_type]

    case export_type
    when "list"
      export_attend_by_list(from_date, to_date, department_id)
    when "summary"
      export_attend_by_summary(from_date, to_date, department_id)
    when "attends"
      export_full_attends(from_date, to_date, department_id, user_id, params[:year].to_i, params[:month].to_i)
    when "detail_attends"
      export_detail_full_attends(from_date, to_date, department_id, user_id, params[:year].to_i, params[:month].to_i)
    end

  end

  def export_attend_by_list(from_date, to_date, department_id)
    data_rows = []
    # Lấy danh sách chấm công vào làm trễ
    late_attend = Attend.includes({ shiftselection: :shiftissue }, :user, :attenddetails)
                        .joins(:user)
                        .where(stype: 'ATTENDANCE')
                        .where("DATE(attends.checkin) BETWEEN ? AND ?", from_date, to_date)
                        .where.not(checkin: nil)
                        .order(checkin: :asc)
    # Nếu có department_id
    if department_id.present?
      user_ids = Work.joins(:positionjob)
                     .where(positionjobs: { department_id: department_id })
                     .pluck(:user_id)
      late_attend = late_attend.where(user_id: user_ids)
    end
    late_attend.each do |item|
      start_str = item.shiftselection&.start_time
      next if start_str.blank?
      late_time = Time.zone.parse("#{item.checkin.to_date} #{start_str}")
      if item.checkin.present? && (item.checkin.change(sec: 0) - late_time.change(sec: 0)) > 15.minutes
        total_minutes = (((item.checkin.change(sec: 0) - late_time.change(sec: 0)) - 15.minutes) / 60).ceil
        late_detail = item.shiftselection.shiftissue.find { |d| d.stype == "LATE-CHECK-IN" }
        request = late_detail ? "<#{late_detail.id}>, #{map_status_label(late_detail.status)}" : ""
        positionjob = get_department_name(item.user.id)
        department_name = positionjob[:department_name]
        positionjob_name = positionjob[:positionjob_name]
        data_rows << {
          user_sid: item.user.sid,
          user_name: "#{item.user.last_name} #{item.user.first_name}",
          department_name: department_name,
          positionjob_name: positionjob_name,
          date: item.checkin,
          workshift: get_workshift_name_by_id(item.shiftselection&.workshift_id),
          type: "Đi trễ",
          total_minutes: total_minutes,
          request: request
        }
      end
    end

    # Lấy danh sách chấm công tan làm sớm
    early_attend = Attend.includes({ shiftselection: :shiftissue }, :user, :attenddetails)
                         .joins(:user)
                         .where(stype: 'ATTENDANCE')
                         .where("DATE(attends.checkout) BETWEEN ? AND ?", from_date, to_date)
                         .where.not(checkout: nil)
                         .order(checkout: :asc)
    # Nếu có department_id
    if department_id.present?
      user_ids = Work.joins(:positionjob)
                     .where(positionjobs: { department_id: department_id })
                     .pluck(:user_id)
      early_attend = early_attend.where(user_id: user_ids)
    end
    early_attend.each do |item|
      end_str = item.shiftselection&.end_time
      next if end_str.blank?
      early_time = Time.zone.parse("#{item.checkout.to_date} #{end_str}")
      if item.checkout.present? && (early_time.change(sec: 0) - item.checkout.change(sec: 0)) > 15.minutes
        total_minutes = (((early_time.change(sec: 0) - item.checkout.change(sec: 0)) - 15.minutes) / 60).ceil
        early_detail = item.shiftselection.shiftissue.find { |d| d.stype == "EARLY-CHECK-OUT" }
        request = early_detail ? "<#{early_detail.id}>, #{map_status_label(early_detail.status)}" : ""
        positionjob = get_department_name(item.user.id)
        department_name = positionjob[:department_name]
        positionjob_name = positionjob[:positionjob_name]
        data_rows << {
          user_sid: item.user.sid,
          user_name: "#{item.user.last_name} #{item.user.first_name}",
          department_name: department_name,
          positionjob_name: positionjob_name,
          early_time: early_time,
          date: item.checkout,
          workshift: get_workshift_name_by_id(item.shiftselection&.workshift_id),
          type: "Về sớm",
          total_minutes: total_minutes,
          request: request
        }
      end
    end
    data_rows = data_rows.sort_by { |row| [row[:user_name], row[:date]] }

    package = Axlsx::Package.new
    workbook = package.workbook

    styles = workbook.styles

    # Styles
    bold_center_13 = styles.add_style(
      b: true, sz: 13, font_name: 'Times',
      alignment: { horizontal: :center, vertical: :center }
    )
    normal_center_13 = styles.add_style(
      b: false, sz: 13, font_name: 'Times',
      alignment: { horizontal: :center, vertical: :center }
    )
    bold_center_15 = styles.add_style(
      b: true, sz: 15, font_name: 'Times',
      alignment: { horizontal: :center, vertical: :center }
    )
    center_header = styles.add_style(
      b: true, sz: 13, font_name: 'Times',
      bg_color: "D9D9D9", fg_color: "000000",
      alignment: { horizontal: :center, vertical: :center },
      border: { style: :thin, color: "000000" }
    )
    cell_left = styles.add_style(
      sz: 13, font_name: 'Times',
      alignment: { horizontal: :left, vertical: :center },
      border: { style: :thin, color: "000000" }
    )
    cell_center = styles.add_style(
      sz: 13, font_name: 'Times',
      alignment: { horizontal: :center, vertical: :center },
      border: { style: :thin, color: "000000" }
    )

    workbook.add_worksheet(name: "Danh sách đi trễ về sớm") do |sheet|
      # Merge titles
      sheet.merge_cells("B2:D2")
      sheet.merge_cells("B3:D3")
      sheet.merge_cells("A5:I5")
      sheet.merge_cells("A6:I6")

      # Title block
      sheet.add_row []
      sheet.add_row ["", "BỘ GIÁO DỤC VÀ ĐÀO TẠO"], style: bold_center_13
      sheet.add_row ["", "TRƯỜNG ĐẠI HỌC Y DƯỢC BUÔN MA THUỘT"], style: bold_center_13
      sheet.add_row []
      sheet.add_row ["DANH SÁCH ĐI TRỄ, VỀ SỚM"], style: bold_center_15
      sheet.add_row ["Từ #{from_date.strftime('%d/%m/%Y')} đến #{to_date.strftime('%d/%m/%Y')}"], style: normal_center_13
      sheet.add_row []

      # Header
      sheet.add_row [
                      "STT", "Mã nhân viên", "Tên nhân viên", "Vị trí công việc", "Đơn vị công tác",
                      "Ngày", "Ca làm việc", "Đi trễ/Về sớm", "Số phút", "Đề xuất"
                    ], style: center_header

      # Data rows
      data_rows.each_with_index do |row, idx|
        sheet.add_row [
                        idx + 1,
                        row[:user_sid],
                        row[:user_name],
                        row[:positionjob_name],
                        row[:department_name],
                        row[:date].strftime("%d/%m/%Y"),
                        row[:workshift],
                        row[:type],
                        row[:total_minutes],
                        row[:request]
                      ], style: [
          cell_center,
          cell_left,
          cell_left,
          cell_left,
          cell_left,
          cell_center,
          cell_center,
          cell_center,
          cell_center,
          cell_center
        ]
      end

      # Set column widths (optional)
      sheet.column_widths 6, 15, 22, 25, 30, 15, 15, 17, 10, 20
    end

    # Export file
    send_data package.to_stream.read,
              filename: "Danh sách đi trễ về sớm #{from_date.strftime('%d_%m_%Y')} - #{to_date.strftime('%d_%m_%Y')}.xlsx",
              type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
              disposition: 'attachment'


  end

  def export_attend_by_summary(from_date, to_date, department_id)
    # Lấy danh sách chấm công vào làm trễ
    late_summary = {}
    late_attend = Attend.includes({ shiftselection: :shiftissue }, :user, :attenddetails)
                        .joins(:user)
                        .where(stype: 'ATTENDANCE')
                        .where("DATE(attends.checkin) BETWEEN ? AND ?", from_date, to_date)
                        .where.not(checkin: nil)
                        .order(checkin: :asc)
    # Nếu có department_id
    if department_id.present?
      user_ids = Work.joins(:positionjob)
                     .where(positionjobs: { department_id: department_id })
                     .pluck(:user_id)
      late_attend = late_attend.where(user_id: user_ids)
    end
    late_attend.each do |item|
      start_str = item.shiftselection&.start_time
      next if start_str.blank?
      late_time = Time.zone.parse("#{item.checkin.to_date} #{start_str}")
      if item.checkin.present? && (item.checkin.change(sec: 0) - late_time.change(sec: 0)) > 15.minutes
        total_minutes = (((item.checkin.change(sec: 0) - late_time.change(sec: 0)) - 15.minutes) / 60).ceil
        user = item.user
        positionjob = get_department_name(item.user.id)
        department_name = positionjob[:department_name]
        positionjob_name = positionjob[:positionjob_name]
        late_summary[user.id] ||= {
          user_sid: user.sid,
          user_name: "#{user.last_name} #{user.first_name}",
          department_name: department_name,
          positionjob_name: positionjob_name,
          late_count: 0,
          late_minutes: 0,
          request_ids: []
        }

        late_summary[user.id][:late_count] += 1
        late_summary[user.id][:late_minutes] += total_minutes
        late_detail = item.shiftselection.shiftissue.find { |d| d.stype == "LATE-CHECK-IN" }
        late_summary[user.id][:request_ids] << "<#{late_detail.id}>" if late_detail
      end
    end
    late_summary.each_value do |summary|
      summary[:late_request] = summary[:request_ids].join(', ')
      summary.delete(:request_ids)
    end

    # Lấy danh sách chấm công tan làm sớm
    early_summary = {}
    early_attend = Attend.includes({ shiftselection: :shiftissue }, :user, :attenddetails)
                         .joins(:user)
                         .where(stype: 'ATTENDANCE')
                         .where("DATE(attends.checkout) BETWEEN ? AND ?", from_date, to_date)
                         .where.not(checkout: nil)
                         .order(checkout: :asc)
    # Nếu có department_id
    if department_id.present?
      user_ids = Work.joins(:positionjob)
                     .where(positionjobs: { department_id: department_id })
                     .pluck(:user_id)
      early_attend = early_attend.where(user_id: user_ids)
    end
    early_attend.each do |item|
      end_str = item.shiftselection&.end_time
      next if end_str.blank?
      early_time = Time.zone.parse("#{item.checkout.to_date} #{end_str}")
      if item.checkout.present? && (early_time.change(sec: 0) - item.checkout.change(sec: 0)) > 15.minutes
        total_minutes = (((early_time.change(sec: 0) - item.checkout.change(sec: 0)) - 15.minutes) / 60).ceil
        user = item.user
        positionjob = get_department_name(item.user.id)
        department_name = positionjob[:department_name]
        positionjob_name = positionjob[:positionjob_name]
        early_summary[user.id] ||= {
          user_sid: user.sid,
          user_name: "#{user.last_name} #{user.first_name}",
          department_name: department_name,
          positionjob_name: positionjob_name,
          early_count: 0,
          early_minutes: 0,
          request_ids: []
        }

        early_summary[user.id][:early_count] += 1
        early_summary[user.id][:early_minutes] += total_minutes
        early_detail = item.shiftselection.shiftissue.find { |d| d.stype == "EARLY-CHECK-OUT" }
        early_summary[user.id][:request_ids] << "<#{early_detail.id}>" if early_detail
      end
    end
    early_summary.each_value do |summary|
      summary[:early_request] = summary[:request_ids].join(', ')
      summary.delete(:request_ids)
    end

    data_rows = merge_data(late_summary, early_summary)
    data_rows = data_rows.sort_by { |row| [row[:department_name].to_s, row[:user_name].to_s] }

    package = Axlsx::Package.new
    workbook = package.workbook

    styles = workbook.styles

    # Styles
    bold_center_13 = styles.add_style(
      b: true, sz: 13, font_name: 'Times',
      alignment: { horizontal: :center, vertical: :center }
    )
    normal_center_13 = styles.add_style(
      b: false, sz: 13, font_name: 'Times',
      alignment: { horizontal: :center, vertical: :center }
    )
    bold_center_15 = styles.add_style(
      b: true, sz: 15, font_name: 'Times',
      alignment: { horizontal: :center, vertical: :center }
    )
    center_header = styles.add_style(
      b: true, sz: 13, font_name: 'Times',
      bg_color: "D9D9D9", fg_color: "000000",
      alignment: { horizontal: :center, vertical: :center },
      border: { style: :thin, color: "000000" }
    )
    cell_left = styles.add_style(
      sz: 13, font_name: 'Times',
      alignment: { horizontal: :left, vertical: :center },
      border: { style: :thin, color: "000000" }
    )
    cell_center = styles.add_style(
      sz: 13, font_name: 'Times',
      alignment: { horizontal: :center, vertical: :center },
      border: { style: :thin, color: "000000" }
    )

    workbook.add_worksheet(name: "Danh sách đi trễ về sớm") do |sheet|
      # Merge titles
      sheet.merge_cells("B2:D2")
      sheet.merge_cells("B3:D3")
      sheet.merge_cells("A5:K5")
      sheet.merge_cells("A6:K6")
      # Title block
      sheet.add_row []
      sheet.add_row ["", "BỘ GIÁO DỤC VÀ ĐÀO TẠO"], style: bold_center_13
      sheet.add_row ["", "TRƯỜNG ĐẠI HỌC Y DƯỢC BUÔN MA THUỘT"], style: bold_center_13
      sheet.add_row []
      sheet.add_row ["TỔNG HỢP ĐI TRỄ, VỀ SỚM THEO NHÂN VIÊN"], style: bold_center_15
      sheet.add_row ["Từ #{from_date.strftime('%d/%m/%Y')} đến #{to_date.strftime('%d/%m/%Y')}"], style: normal_center_13
      sheet.add_row []

      # Header
      sheet.add_row [
                      "STT", "Mã nhân viên", "Tên nhân viên", "Vị trí công việc", "Đơn vị công tác",
                      "Đi trễ", nil, nil, "Về sớm", nil, nil
                    ], style: center_header
      sheet.add_row [
                      nil, nil, nil, nil, nil,
                      "Số lần", "Số phút", "Đề xuất",
                      "Số lần", "Số phút", "Đề xuất"
                    ], style: center_header
      sheet.merge_cells("A8:A9")
      sheet.merge_cells("B8:B9")
      sheet.merge_cells("C8:C9")
      sheet.merge_cells("D8:D9")
      sheet.merge_cells("E8:E9")
      sheet.merge_cells("F8:H8")
      sheet.merge_cells("I8:K8")

      # Data rows
      data_rows.each_with_index do |row, idx|
        sheet.add_row [
                        idx + 1,
                        row[:user_sid],
                        row[:user_name],
                        row[:positionjob_name],
                        row[:department_name],
                        row[:late_count],
                        row[:late_minutes],
                        row[:late_request],
                        row[:early_count],
                        row[:early_minutes],
                        row[:early_request]
                      ], style: [
          cell_center,
          cell_left,
          cell_left,
          cell_left,
          cell_left,
          cell_center,
          cell_center,
          cell_center,
          cell_center,
          cell_center,
          cell_center
        ]
      end

      # Set column widths (optional)
      sheet.column_widths 6, 15, 22, 25, 30, 10, 10, 20, 10, 10, 20
    end

    # Export file
    send_data package.to_stream.read,
              filename: "Tổng hợp đi trễ về sớm theo nhân viên #{from_date.strftime('%d_%m_%Y')} - #{to_date.strftime('%d_%m_%Y')}.xlsx",
              type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
              disposition: 'attachment'


  end

  def export_full_attends(from_date, to_date, department_id, user_id, year, month)
    # Lấy danh sách nhân viên của trường
    org = ['BU', "BMTU", "BMU"]
    require_position_scodes = Positionjob
                               .where("ignore_attend IS NULL OR ignore_attend != ?", "TRUE")
                               .pluck(:scode)
    users = User
              .joins(uorgs: :organization)
              .joins("LEFT JOIN works ON works.user_id = users.id")
              .joins("LEFT JOIN positionjobs ON positionjobs.id = works.positionjob_id")
              .joins("LEFT JOIN departments ON departments.id = positionjobs.department_id")
              .where(organizations: { scode: org })
              .where(status: "ACTIVE")
              .where("users.ignore_attend IS NULL OR users.ignore_attend != ?", "TRUE")
              .where(positionjobs: { scode: require_position_scodes })
              .distinct
              .select(
                "users.id AS user_id, users.sid, users.first_name, users.last_name,
             MIN(departments.name) AS department_name, MIN(positionjobs.name) AS positionjob_name"
              )
              .group(
                "users.id, users.sid, users.first_name, users.last_name"
              )

    # Nếu có department_id
    if department_id.present?
      user_ids = Work.joins(:positionjob)
                     .where(positionjobs: { department_id: department_id })
                     .pluck(:user_id)
      users = users.where(id: user_ids)
    end

    # Nếu có user_id
    if user_id.present?
      users = users.where(id: user_id)
    end

    data_rows = []

    users.each do |item|
      data_rows << {
        user_id: item.user_id,
        user_sid: item.sid,
        user_name: "#{item.last_name} #{item.first_name}",
        department_name: item.department_name,
        positionjob_name: item.positionjob_name
      }
    end

    package = Axlsx::Package.new
    workbook = package.workbook

    styles = workbook.styles

    # Styles
    bold_center_13 = styles.add_style(
      b: true, sz: 13, font_name: 'Times',
      alignment: { horizontal: :center, vertical: :center }
    )
    normal_center_13 = styles.add_style(
      b: false, sz: 13, font_name: 'Times',
      alignment: { horizontal: :center, vertical: :center }
    )
    bold_center_15 = styles.add_style(
      b: true, sz: 15, font_name: 'Times',
      alignment: { horizontal: :center, vertical: :center }
    )
    center_header = styles.add_style(
      b: true, sz: 13, font_name: 'Times',
      bg_color: "D9D9D9", fg_color: "000000",
      alignment: { horizontal: :center, vertical: :center },
      border: { style: :thin, color: "000000" }
    )
    cell_left = styles.add_style(
      sz: 13, font_name: 'Times',
      alignment: { horizontal: :left, vertical: :center },
      border: { style: :thin, color: "000000" }
    )
    cell_center = styles.add_style(
      sz: 13, font_name: 'Times',
      alignment: { horizontal: :center, vertical: :center },
      border: { style: :thin, color: "000000" }
    )
    cell_center_red = styles.add_style(
      sz: 13, font_name: 'Times',
      alignment: { horizontal: :center, vertical: :center },
      border: { style: :thin, color: "000000" },
      fg_color: "FF0000"
    )

    workbook.add_worksheet(name: "Bảng chấm công tháng #{from_date.strftime('%m')}") do |sheet|
      # Merge titles
      sheet.merge_cells("B2:D2")
      sheet.merge_cells("B3:D3")
      sheet.merge_cells("A5:K5")
      sheet.merge_cells("A6:K6")
      # Title block
      sheet.add_row []
      sheet.add_row ["", "BỘ GIÁO DỤC VÀ ĐÀO TẠO"], style: bold_center_13
      sheet.add_row ["", "TRƯỜNG ĐẠI HỌC Y DƯỢC BUÔN MA THUỘT"], style: bold_center_13
      sheet.add_row []
      sheet.add_row ["BẢNG CHẤM CÔNG THÁNG #{from_date.strftime('%m')}"], style: bold_center_15
      sheet.add_row ["Từ #{from_date.strftime('%d/%m/%Y')} đến #{to_date.strftime('%d/%m/%Y')}"], style: normal_center_13
      sheet.add_row []

      # ==== Hàng 1: ngày ====
      header_top = ["STT", "Mã nhân viên", "Tên nhân viên", "Vị trí công việc", "Đơn vị công tác"]
      (from_date..to_date).each do |date|
        header_top += [date.strftime("%d/%m/%Y"), "", "", ""]
      end
      header_top += [
        "Số công chuẩn",
        "Ngày công hưởng lương", "", "", "", "", "", "",
        "Ngày công không hưởng lương", "", "", "",
        "Tổng công hưởng lương",
        "Tổng giờ làm đăng ký",
        "Tổng giờ làm thực tế",
        "Đi muộn về sớm", ""
      ]
      sheet.add_row header_top, style: center_header

      # ==== Hàng 2: Kế hoạch / Chấm công ====
      header_mid = ["", "", "", "", ""]
      (from_date..to_date).each do |_|
        header_mid += ["Kế hoạch", "", "Chấm công", ""]
      end
      header_mid += [
        "", # Số công chuẩn
        "Ngày công thực tế",
        "Nghỉ phép",
        "Nghỉ bù",
        "Làm từ xa",
        "Nghỉ chế độ",
        "Đi công tác, đào tạo",
        "Nghỉ Lễ, Tết",
        "Học việc",
        "Nghỉ không lương",
        "Nghỉ hưởng BHXH",
        "Nghỉ thai sản",
        "", # Tổng công hưởng lương
        "", # Tổng giờ làm đăng ký
        "", # Tổng giờ làm thực tế
        "Số lần",
        "Số phút"
      ]
      sheet.add_row header_mid, style: center_header

      # ==== Hàng 3: Ca Sáng / Ca Chiều ====
      header_bottom = ["", "", "", "", ""]
      (from_date..to_date).each do |_|
        header_bottom += ["Sáng", "Chiều", "Sáng", "Chiều"]
      end
      header_bottom += Array.new(17, "")
      sheet.add_row header_bottom, style: center_header

      # ==== Gộp ô (merge cells) ====
      row_top    = sheet.rows.size - 2
      row_mid    = sheet.rows.size - 1
      row_bottom = sheet.rows.size
      (0..4).each do |i|
        ref = "#{col_name(i)}#{row_top}:#{col_name(i)}#{row_bottom}"
        sheet.merge_cells(ref)
      end

      # Gộp từng ngày
      offset = 5 # cột đầu của ngày
      (from_date..to_date).each_with_index do |_, idx|
        base = offset + idx * 4
        # Gộp ngày
        sheet.merge_cells("#{col_name(base)}#{row_top}:#{col_name(base+3)}#{row_top}")
        # Gộp cột Kế hoạch
        sheet.merge_cells("#{col_name(base)}#{row_mid}:#{col_name(base+1)}#{row_mid}")
        # Gộp cột Chấm công
        sheet.merge_cells("#{col_name(base+2)}#{row_mid}:#{col_name(base+3)}#{row_mid}")
      end

      # Cố định A..E khi scroll ngang
      sheet.sheet_view.pane do |p|
        p.state = :frozen
        p.x_split = 5
        p.y_split = 0
        p.top_left_cell = "#{col_name(5)}#{row_bottom+1}"
      end

      # ----- GỘP PHẦN TỔNG HỢP CUỐI BẢNG -----
      day_count = (to_date - from_date).to_i + 1
      summary_start_col = offset + day_count * 4

      # "Số công chuẩn" (merge dọc 3 hàng)
      sheet.merge_cells("#{col_name(summary_start_col)}#{row_top}:#{col_name(summary_start_col)}#{row_bottom}")

      # Nhóm "Ngày công hưởng lương" (7 cột)
      paid_group_start = summary_start_col + 1
      paid_group_end   = paid_group_start + 6
      sheet.merge_cells("#{col_name(paid_group_start)}#{row_top}:#{col_name(paid_group_end)}#{row_top}")
      (paid_group_start..paid_group_end).each do |paid_group_col|
        sheet.merge_cells("#{col_name(paid_group_col)}#{row_bottom - 1}:#{col_name(paid_group_col)}#{row_bottom}")
      end

      # Nhóm "Ngày công không hưởng lương" (3 cột)
      unpaid_group_start = paid_group_end + 1
      unpaid_group_end   = unpaid_group_start + 3
      sheet.merge_cells("#{col_name(unpaid_group_start)}#{row_top}:#{col_name(unpaid_group_end)}#{row_top}")
      (unpaid_group_start..unpaid_group_end).each do |unpaid_group_col|
        sheet.merge_cells("#{col_name(unpaid_group_col)}#{row_bottom - 1}:#{col_name(unpaid_group_col)}#{row_bottom}")
      end

      # Các cột đơn: Tổng công hưởng lương, Tổng giờ làm đăng ký, Tổng giờ làm thực tế (merge dọc)
      total_paid_col         = unpaid_group_end + 1
      total_hours_reg_col    = total_paid_col + 1
      total_hours_actual_col = total_hours_reg_col + 1

      [total_paid_col, total_hours_reg_col, total_hours_actual_col].each do |col|
        sheet.merge_cells("#{col_name(col)}#{row_top}:#{col_name(col)}#{row_bottom}")
      end

      # Nhóm "Đi muộn về sớm" (2 cột)
      late_early_group_start = total_hours_actual_col + 1
      late_early_group_end   = late_early_group_start + 1
      sheet.merge_cells("#{col_name(late_early_group_start)}#{row_top}:#{col_name(late_early_group_end)}#{row_top}")
      sheet.merge_cells("#{col_name(late_early_group_start)}#{row_bottom - 1}:#{col_name(late_early_group_start)}#{row_bottom}")
      sheet.merge_cells("#{col_name(late_early_group_end)}#{row_bottom - 1}:#{col_name(late_early_group_end)}#{row_bottom}")
      # ----------------------------------------

      # Set column widths (optional)
      total_day_cols = (to_date - from_date).to_i + 1
      total_cols     = 5 + total_day_cols * 4 + 17
      widths = [6, 15, 22, 25, 30] + Array.new(total_cols - 5, 20)
      sheet.column_widths(*widths)

      # Data rows
      data_rows.each_with_index do |row, idx|
        values = [
          idx + 1,
          row[:user_sid],
          row[:user_name],
          row[:positionjob_name],
          row[:department_name]
        ]
        styles = [cell_center, cell_left, cell_left, cell_left, cell_left]

        user_id = row[:user_id]
        next unless user_id

        shifts = Shiftselection
                   .joins(:workshift)
                   .joins(scheduleweek: :user)
                   .left_joins(:attend)
                   .where(work_date: from_date.beginning_of_day..to_date.end_of_day)
                   .where(scheduleweeks: { user_id: user_id, status: 'APPROVED' })
                   .select(
                     'shiftselections.id',
                     'shiftselections.work_date',
                     'shiftselections.start_time',
                     'shiftselections.end_time',
                     'shiftselections.is_day_off',
                     'workshifts.name AS ws_name',
                     'attends.checkin AS att_checkin',
                     'attends.checkout AS att_checkout',
                     'scheduleweeks.id AS scheduleweek_id'
                   )

        # Gom theo ngày
        by_date = Hash.new { |h,k| h[k] = { am: nil, pm: nil } }
        shifts.each do |s|
          wsname = s.ws_name.to_s.downcase
          session =
            if wsname.include?("sáng")
              :am
            elsif wsname.include?("chiều")
              :pm
            else
              (s.start_time.to_s < "12:30" ? :am : :pm)
            end
          by_date[s.work_date.to_date][session] = s
        end

        # format giờ
        def fmt_time(t)
          return "" if t.blank?
          t = t.to_time if t.respond_to?(:to_time)
          t.strftime("%H:%M") rescue ""
        end

        actual_work_units = 0.0
        total_registered_sec = 0
        total_actual_sec     = 0
        (from_date..to_date).each do |d|
          am = by_date[d][:am]
          pm = by_date[d][:pm]

          # KẾ HOẠCH SÁNG
          if am.nil?
            values << ""
          else
            if am.is_day_off.present?
              code = { "OFF"=>"Nghỉ","ON-LEAVE"=>"Nghỉ phép","HOLIDAY"=>"Nghỉ lễ","TEACHING-SCHEDULE"=>"Lịch giảng dạy" }[am.is_day_off] || ""
              values << code
            else
              values << "#{fmt_time(am.start_time)} - #{fmt_time(am.end_time)}"
            end
          end
          styles << cell_center

          # KẾ HOẠCH CHIỀU
          if pm.nil?
            values << ""
          else
            if pm.is_day_off.present?
              code = { "OFF"=>"Nghỉ","ON-LEAVE"=>"Nghỉ phép","HOLIDAY"=>"Nghỉ lễ","TEACHING-SCHEDULE"=>"Lịch giảng dạy" }[pm.is_day_off] || ""
              values << code
            else
              values << "#{fmt_time(pm.start_time)} - #{fmt_time(pm.end_time)}"
            end
          end
          styles << cell_center

          # CHẤM CÔNG SÁNG
          if am.nil? || am.is_day_off.present?
            values << "-"
            styles << cell_center
          else
            checkin  = am.att_checkin.present? ? am.att_checkin&.in_time_zone("Asia/Ho_Chi_Minh") : nil
            checkout = am.att_checkout.present? ? am.att_checkout&.in_time_zone("Asia/Ho_Chi_Minh") : nil
            plan_in  = am.start_time.present? ? am.start_time.to_time : nil
            plan_out = am.end_time.present? ? am.end_time.to_time : nil
            text = (checkin || checkout) ? "#{fmt_time(checkin)} - #{fmt_time(checkout)}" : "-"
            late   = checkin && plan_in  && (checkin  > (plan_in  + 15.minutes))
            early  = checkout && plan_out && (checkout < (plan_out - 15.minutes))
            values << text
            styles << (late || early ? cell_center : cell_center)

            # Giờ làm đăng ký / Giờ làm thực tế (ca sáng)
            if plan_in && plan_out
              total_registered_sec += (plan_out - plan_in)
            end
            if checkin && checkout
              total_actual_sec += (checkout - checkin)
              actual_work_units += 0.5
            end
          end

          # CHẤM CÔNG CHIỀU
          if pm.nil? || pm.is_day_off.present?
            values << "-"
            styles << cell_center
          else
            checkin  = pm.att_checkin.present? ? pm.att_checkin&.in_time_zone("Asia/Ho_Chi_Minh") : nil
            checkout = pm.att_checkout.present? ? pm.att_checkout&.in_time_zone("Asia/Ho_Chi_Minh") : nil
            plan_in  = pm.start_time.present? ? pm.start_time.to_time : nil
            plan_out = pm.end_time.present? ? pm.end_time.to_time : nil
            text = (checkin || checkout) ? "#{fmt_time(checkin)} - #{fmt_time(checkout)}" : "-"
            late   = checkin && plan_in  && (checkin  > (plan_in  + 15.minutes))
            early  = checkout && plan_out && (checkout < (plan_out - 15.minutes))
            values << text
            styles << (late || early ? cell_center : cell_center)

            # Giờ làm đăng ký / Giờ làm thực tế (ca chiều)
            if plan_in && plan_out
              total_registered_sec += (plan_out - plan_in)
            end
            if checkin && checkout
              total_actual_sec += (checkout - checkin)
              actual_work_units += 0.5
            end
          end
        end

        # Tổng giờ đăng kí và tổng giờ thực tế
        total_registered_hours = (total_registered_sec / 3600.0).round(2)
        total_actual_hours     = (total_actual_sec / 3600.0).round(2)

        # Tính số lần & số phút đi muộn / về sớm
        late_early_count   = 0
        late_early_minutes = 0

        # Đi muộn (checkin trễ so với start_time > 15 phút)
        late_attend = Attend.includes(shiftselection: :shiftissue)
                            .where(user_id: user_id, stype: "ATTENDANCE")
                            .where("DATE(attends.checkin) BETWEEN ? AND ?", from_date, to_date)
                            .where.not(checkin: nil)
                            .order(checkin: :asc)

        late_attend.each do |item|
          start_str = item.shiftselection&.start_time
          next if start_str.blank?

          late_approved = item.shiftselection&.shiftissue&.any? do |iss|
            iss.stype == "LATE-CHECK-IN" && iss.status == "APPROVED"
          end
          next if late_approved

          late_time = Time.zone.parse("#{item.checkin.to_date} #{start_str}")
          if item.checkin.present? && (item.checkin.change(sec: 0) - late_time.change(sec: 0)) > 15.minutes
            total_minutes = (((item.checkin.change(sec: 0) - late_time.change(sec: 0)) - 15.minutes) / 60.0).ceil
            late_early_count   += 1
            late_early_minutes += total_minutes
          end
        end

        # Về sớm (checkout sớm hơn end_time > 15 phút)
        early_attend = Attend.includes(shiftselection: :shiftissue)
                             .where(user_id: user_id, stype: "ATTENDANCE")
                             .where("DATE(attends.checkout) BETWEEN ? AND ?", from_date, to_date)
                             .where.not(checkout: nil)
                             .order(checkout: :asc)

        early_attend.each do |item|
          end_str = item.shiftselection&.end_time
          next if end_str.blank?

          early_approved = item.shiftselection&.shiftissue&.any? do |iss|
            iss.stype == "EARLY-CHECK-OUT" && iss.status == "APPROVED"
          end
          next if early_approved

          early_time = Time.zone.parse("#{item.checkout.to_date} #{end_str}")
          if item.checkout.present? && (early_time.change(sec: 0) - item.checkout.change(sec: 0)) > 15.minutes
            total_minutes = (((early_time.change(sec: 0) - item.checkout.change(sec: 0)) - 15.minutes) / 60.0).ceil
            late_early_count   += 1
            late_early_minutes += total_minutes
          end
        end

        # Đếm số ca đi công tác/đào tạo (WORK-TRIP, APPROVED)
        shift_ids = shifts.map(&:id)
        work_trip_count =
          if shift_ids.empty?
            0.0
          else
            Shiftissue.where(
              shiftselection_id: shift_ids,
              stype: "WORK-TRIP",
              status: "APPROVED"
            ).count * 0.5
          end

        data = parse_holiday_details_date(user_id, year, month)
        so_cong_chuan             = count_days_excluding_sundays(year, month)
        ngay_cong_thuc_te         = actual_work_units.to_f - work_trip_count.to_f
        nghi_phep                 = data[:nghi_phep]
        nghi_bu                   = data[:nghi_bu]
        lam_tu_xa                 = ""
        nghi_che_do               = data[:nghi_che_do]
        di_cong_tac_dao_tao       = work_trip_count
        nghi_le_tet               = data[:nghi_le_tet]
        hoc_viec                  = data[:hoc_viec]
        nghi_khong_luong          = data[:khong_luong]
        nghi_huong_bhxh           = data[:che_do_bhxh]
        nghi_thai_san             = data[:thai_san]
        tong_cong_huong_luong     = actual_work_units.to_f + data[:nghi_phep].to_f + data[:nghi_bu].to_f + data[:nghi_che_do].to_f + data[:nghi_le_tet].to_f
        tong_gio_lam_dang_ky      = total_registered_hours
        tong_gio_lam_thuc_te      = total_actual_hours
        di_muon_ve_som_so_lan     = late_early_count
        di_muon_ve_som_so_phut    = late_early_minutes

        summary_cells = [
          so_cong_chuan,
          ngay_cong_thuc_te,
          nghi_phep,
          nghi_bu,
          lam_tu_xa,
          nghi_che_do,
          di_cong_tac_dao_tao,
          nghi_le_tet,
          hoc_viec,
          nghi_khong_luong,
          nghi_huong_bhxh,
          nghi_thai_san,
          tong_cong_huong_luong,
          tong_gio_lam_dang_ky,
          tong_gio_lam_thuc_te,
          di_muon_ve_som_so_lan,
          di_muon_ve_som_so_phut
        ]

        values += summary_cells
        styles += Array.new(17, cell_center)
        # -------------------------------------------------------------

        sheet.add_row values, style: styles
      end

    end

    # Export file
    send_data package.to_stream.read,
              filename: "Bảng chấm công tháng #{from_date.strftime('%m')}.xlsx",
              type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
              disposition: 'attachment'


  end

  def export_detail_full_attends(from_date, to_date, department_id, user_id, year, month)
    # Lấy danh sách nhân viên của trường
    org = ['BU', "BMTU", "BMU"]
    require_position_scodes = Positionjob
                              .where("ignore_attend IS NULL OR ignore_attend != ?", "TRUE")
                              .pluck(:scode)
    users = User
              .joins(uorgs: :organization)
              .joins("LEFT JOIN works ON works.user_id = users.id")
              .joins("LEFT JOIN positionjobs ON positionjobs.id = works.positionjob_id")
              .joins("LEFT JOIN departments ON departments.id = positionjobs.department_id")
              .where(organizations: { scode: org })
              .where(status: "ACTIVE")
              .where("users.ignore_attend IS NULL OR users.ignore_attend != ?", "TRUE")
              .where(positionjobs: { scode: require_position_scodes })
              .distinct
              .select(
                "users.id AS user_id, users.sid, users.first_name, users.last_name,
            MIN(departments.name) AS department_name, MIN(positionjobs.name) AS positionjob_name"
              )
              .group(
                "users.id, users.sid, users.first_name, users.last_name"
              )

    if department_id.present?
      user_ids = Work.joins(:positionjob)
                    .where(positionjobs: { department_id: department_id })
                    .pluck(:user_id)
      users = users.where(id: user_ids)
    end

    if user_id.present?
      users = users.where(id: user_id)
    end

    # Thu thập dữ liệu nhân viên
    data_rows = []
    users.each do |item|
      oContract = User.find(item.user_id)&.contracts.where(status: "ACTIVE").order(created_at: :asc).first
      data_rows << {
        user_id: item.user_id,
        user_sid: item.sid,
        user_name: "#{item.last_name} #{item.first_name}",
        department_name: item.department_name,
        positionjob_name: item.positionjob_name,
        contract_start_date: (oContract && oContract.dtfrom.to_date > Date.today) ? Time.now.strftime("%Y/%m/%d") : oContract ? oContract.dtfrom.strftime("%Y/%m/%d") : Time.now.strftime("%Y/%m/%d"),
      }
    end

    package  = Axlsx::Package.new
    workbook = package.workbook
    styles   = workbook.styles

    # ── Styles ──────────────────────────────────────────────────────────────────
    bold_center_13 = styles.add_style(
      b: true, sz: 13, font_name: 'Times',
      alignment: { horizontal: :center, vertical: :center }
    )
    normal_center_13 = styles.add_style(
      b: false, sz: 13, font_name: 'Times',
      alignment: { horizontal: :center, vertical: :center }
    )
    bold_center_15 = styles.add_style(
      b: true, sz: 15, font_name: 'Times',
      alignment: { horizontal: :center, vertical: :center }
    )
    center_header = styles.add_style(
      b: true, sz: 11, font_name: 'Times',
      bg_color: "D9D9D9", fg_color: "000000",
      alignment: { horizontal: :center, vertical: :center, wrap_text: true },
      border: { style: :thin, color: "000000" }
    )
    bold_left = styles.add_style(
      b: true, sz: 11, font_name: 'Times', fg_color: "000000",
      alignment: { horizontal: :left, vertical: :center }
    )
    cell_left = styles.add_style(
      sz: 11, font_name: 'Times',
      alignment: { horizontal: :left, vertical: :center },
      border: { style: :thin, color: "000000" }
    )
    cell_center = styles.add_style(
      sz: 11, font_name: 'Times',
      alignment: { horizontal: :center, vertical: :center },
      border: { style: :thin, color: "000000" }
    )
    cell_center_bold = styles.add_style(
      b: true, sz: 11, font_name: 'Times',
      alignment: { horizontal: :center, vertical: :center },
      border: { style: :thin, color: "000000" }
    )

    # ── Helper: chuyển index cột (0-based) → tên cột Excel (A, B, ..., AA, AB…) ──
    def col_name(idx)
      name = ""
      idx += 1
      while idx > 0
        idx -= 1
        name = (65 + idx % 26).chr + name
        idx /= 26
      end
      name
    end

    workbook.add_worksheet(name: "Bảng chấm công tổng hợp") do |sheet|

      # ── Tiêu đề ──────────────────────────────────────────────────────────────
      # Xác định tổng số cột: 6 (thông tin) + số ngày + 17 (tổng hợp)
      day_count   = (to_date - from_date).to_i + 1
      total_cols  = 6 + day_count + 17
      last_col    = col_name(total_cols - 1)

      sheet.merge_cells("B2:D2")
      sheet.merge_cells("B3:D3")
      sheet.add_row []                                                      # Row 1 (trống)
      sheet.add_row ["", "BỘ GIÁO DỤC VÀ ĐÀO TẠO"], style: bold_center_13
      sheet.add_row ["", "TRƯỜNG ĐẠI HỌC Y DƯỢC BUÔN MA THUỘT"], style: bold_center_13
      sheet.add_row []                                                       # Row 4

      # Row 5 – tiêu đề lớn (merge toàn bộ chiều ngang)
      sheet.add_row ["BẢNG CHẤM CÔNG TỔNG HỢP"], style: bold_center_15
      sheet.merge_cells("A5:#{last_col}5")

      # Row 6 – khoảng thời gian (merge toàn bộ)
      sheet.add_row ["Từ #{from_date.strftime('%d/%m/%Y')} đến #{to_date.strftime('%d/%m/%Y')}"],
                    style: normal_center_13
      sheet.merge_cells("A6:#{last_col}6")

      sheet.add_row []                                                      # Row 7

      # ── Header Row 8 (hàng 1 của bảng) ──────────────────────────────────────
      # Cột 0-5: thông tin cơ bản  |  cột 6..(6+day-1): ngày  |  cột (6+day)..: tổng hợp
      summary_start = 6 + day_count            # 0-based index cột đầu tiên của phần tổng hợp

      header_top = ["STT", "Mã nhân viên", "Họ và tên", "Đơn vị", "Vị trí công việc", "Ngày vào làm",
                    "Chi tiết chấm công"]       # "Chi tiết chấm công" sẽ được merge ngang qua tất cả cột ngày
      header_top += Array.new(day_count - 1, nil)
      header_top += [
        "Số công chuẩn",
        "Ngày công hưởng lương", nil, nil, nil, nil, nil, nil,
        "Ngày công không hưởng lương", nil, nil, nil,
        "Tổng công hưởng lương",
        "Tổng giờ làm đăng ký",
        "Tổng giờ làm thực tế",
        "Đi muộn về sớm", nil
      ]
      sheet.add_row header_top, style: center_header   # Row 8

      # ── Header Row 9 (hàng 2 của bảng) – ngày trong tháng ───────────────────
      header_mid = [nil, nil, nil, nil, nil, nil]
      (from_date..to_date).each { |d| header_mid << d.day.to_s }
      header_mid += [
        nil,              # Số công chuẩn (merge dọc với row8)
        "Ngày công thực tế",
        "Nghỉ phép",
        "Nghỉ bù",
        "Làm từ xa",
        "Nghỉ chế độ",
        "Đi công tác, đào tạo",
        "Nghỉ Lễ, Tết",
        "Học việc",
        "Nghỉ không lương",
        "Nghỉ hưởng BHXH",
        "Nghỉ thai sản",
        nil,              # Tổng công hưởng lương (merge dọc)
        nil,              # Tổng giờ làm đăng ký (merge dọc)
        nil,              # Tổng giờ làm thực tế (merge dọc)
        "Số lần",
        "Số phút"
      ]
      sheet.add_row header_mid, style: center_header   # Row 9

      # ── Header Row 10 (hàng 3 của bảng) – thứ trong tuần ────────────────────
      weekday_vn = %w[CN T2 T3 T4 T5 T6 T7]
      header_bot = [nil, nil, nil, nil, nil, nil]
      (from_date..to_date).each { |d| header_bot << weekday_vn[d.wday] }
      header_bot += Array.new(17, nil)
      sheet.add_row header_bot, style: center_header   # Row 10

      # ── Tính vị trí hàng header (1-based) ────────────────────────────────────
      row_top    = 8   # Row 8
      row_mid    = 9   # Row 9
      row_bottom = 10  # Row 10

      # ── Merge ô thông tin cơ bản (cột A..F) theo chiều dọc (3 hàng) ─────────
      %w[A B C D E F].each do |c|
        sheet.merge_cells("#{c}#{row_top}:#{c}#{row_bottom}")
      end

      # ── Merge "Chi tiết chấm công" ngang qua tất cả cột ngày ─────────────────
      day_first_col = col_name(6)                      # G
      day_last_col  = col_name(6 + day_count - 1)      # ví dụ: AK nếu 31 ngày
      sheet.merge_cells("#{day_first_col}#{row_top}:#{day_last_col}#{row_top}")

      # ── Merge phần tổng hợp cuối bảng ────────────────────────────────────────
      sc_col             = col_name(summary_start)      # Số công chuẩn
      paid_start_col     = col_name(summary_start + 1)  # Ngày công hưởng lương
      paid_end_col       = col_name(summary_start + 7)
      unpaid_start_col   = col_name(summary_start + 8)
      unpaid_end_col     = col_name(summary_start + 11)
      total_paid_col     = col_name(summary_start + 12)
      total_reg_col      = col_name(summary_start + 13)
      total_act_col      = col_name(summary_start + 14)
      late_start_col     = col_name(summary_start + 15)
      late_end_col       = col_name(summary_start + 16)

      # Số công chuẩn – merge dọc 3 hàng
      sheet.merge_cells("#{sc_col}#{row_top}:#{sc_col}#{row_bottom}")
      # "Ngày công hưởng lương" – merge ngang row8, từng sub-col merge dọc row9-10
      sheet.merge_cells("#{paid_start_col}#{row_top}:#{paid_end_col}#{row_top}")
      (1..7).each do |i|
        c = col_name(summary_start + i)
        sheet.merge_cells("#{c}#{row_mid}:#{c}#{row_bottom}")
      end
      # "Ngày công không hưởng lương" – merge ngang row8, từng sub-col merge dọc row9-10
      sheet.merge_cells("#{unpaid_start_col}#{row_top}:#{unpaid_end_col}#{row_top}")
      (8..11).each do |i|
        c = col_name(summary_start + i)
        sheet.merge_cells("#{c}#{row_mid}:#{c}#{row_bottom}")
      end
      # Tổng công hưởng lương / Tổng giờ đăng ký / Tổng giờ thực tế – merge dọc 3 hàng
      [total_paid_col, total_reg_col, total_act_col].each do |c|
        sheet.merge_cells("#{c}#{row_top}:#{c}#{row_bottom}")
      end
      # "Đi muộn về sớm" – merge ngang row8, sub-col merge dọc row9-10
      sheet.merge_cells("#{late_start_col}#{row_top}:#{late_end_col}#{row_top}")
      sheet.merge_cells("#{late_start_col}#{row_mid}:#{late_start_col}#{row_bottom}")
      sheet.merge_cells("#{late_end_col}#{row_mid}:#{late_end_col}#{row_bottom}")

      # ── Cố định cột A..E khi scroll ngang ────────────────────────────────────
      sheet.sheet_view.pane do |p|
        p.state         = :frozen
        p.x_split       = 5
        p.y_split       = 0
        p.top_left_cell = "#{col_name(5)}#{row_bottom + 1}"
      end

      # ── Dữ liệu từng nhân viên ────────────────────────────────────────────────
      data_rows.each_with_index do |row, idx|
        excel_row = row_bottom + 1 + idx  # hàng Excel 1-based

        values = [
          idx + 1,
          row[:user_sid],
          row[:user_name],
          row[:department_name],
          row[:positionjob_name],
          row[:contract_start_date],
        ]
        row_styles = [cell_center, cell_left, cell_left, cell_left, cell_left, cell_left]

        uid = row[:user_id]
        unless uid
          values += Array.new(day_count + 17, nil)
          row_styles += Array.new(day_count + 17, cell_center)
          sheet.add_row values, style: row_styles
          next
        end

        # Lấy shift của nhân viên trong kỳ
        shifts = Shiftselection
                  .joins(:workshift)
                  .joins(scheduleweek: :user)
                  .left_joins(:attend)
                  .where(work_date: from_date.beginning_of_day..to_date.end_of_day)
                  .where(scheduleweeks: { user_id: uid, status: 'APPROVED' })
                  .select(
                    'shiftselections.id',
                    'shiftselections.work_date',
                    'shiftselections.start_time',
                    'shiftselections.end_time',
                    'shiftselections.is_day_off',
                    'workshifts.name AS ws_name',
                    'attends.checkin AS att_checkin',
                    'attends.checkout AS att_checkout',
                    'scheduleweeks.id AS scheduleweek_id'
                  )

        # Gom shift theo ngày → { date => { am: shift, pm: shift } }
        by_date = Hash.new { |h, k| h[k] = { am: nil, pm: nil } }
        shifts.each do |s|
          wsname  = s.ws_name.to_s.downcase
          session = if wsname.include?("sáng")   then :am
                    elsif wsname.include?("chiều") then :pm
                    else s.start_time.to_s < "12:30" ? :am : :pm
                    end
          by_date[s.work_date.to_date][session] = s
        end

        def fmt_time(t)
          return "" if t.blank?
          t = t.to_time if t.respond_to?(:to_time)
          t.strftime("%H:%M") rescue ""
        end

        # ── Lấy leave_days từ parse_holiday_details_date để có ký hiệu chính xác ──
        # leave_days là mảng 31 phần tử (index 0 = ngày 1), mỗi phần tử là:
        #   "-"  → ngoài tháng
        #   "X"  → ngày làm (mặc định, chưa có nghỉ phép)
        #   "P", "NB", "L", "CD", "KL", "BH", "TS", "HV"... → ký hiệu nghỉ
        #   "X/P", "P/X", "NB/X"... → nửa ngày
        # Ưu tiên: nếu ngày có ký hiệu từ holpro → dùng ký hiệu đó
        #           nếu không → dùng session_code từ shiftselection (X hoặc nil)
        holiday_data = parse_holiday_details_date(uid, year, month)
        leave_days   = holiday_data[:leave_days]   # mảng 31 phần tử

        # Ánh xạ is_day_off sang ký hiệu (fallback khi không có holpro)
        is_day_off_code = {
          "OFF"               => nil,
          "ON-LEAVE"          => "P",
          "HOLIDAY"           => "L",
          "TEACHING-SCHEDULE" => "H",
          "WORK-TRIP"         => "CT",
        }

        actual_work_units    = 0.0
        total_registered_sec = 0
        total_actual_sec     = 0

        (from_date..to_date).each do |d|
          am = by_date[d][:am]
          pm = by_date[d][:pm]

          # Không có lịch cả ngày → để trống
          if am.nil? && pm.nil?
            values << nil
            row_styles << cell_center
            next
          end

          am_off = am&.is_day_off == "OFF"
          pm_off = pm&.is_day_off == "OFF"

          # Cả hai ca đều là ngày nghỉ cuối tuần (OFF) → để trống
          if (am.nil? || am_off) && (pm.nil? || pm_off)
            values << nil
            row_styles << cell_center
            next
          end

          # ── Ưu tiên ký hiệu từ holpro (leave_days) ──────────────────────────
          # leave_days[d.day - 1] đã được parse_holiday_details_date tính sẵn
          # với đầy đủ ký hiệu P, NB, CD, L, KL, BH, TS, HV, X/P, P/X...
          holpro_code = leave_days[d.day - 1]

          # Nếu holpro có ký hiệu nghỉ thực sự (không phải "X" thuần hay "-") → dùng luôn
          has_holiday_code = holpro_code.present? &&
                            holpro_code != "X" &&
                            holpro_code != "-" &&
                            !holpro_code.nil?

          daily_code =
            if has_holiday_code
              # Holpro đã tính đủ: P, NB, L, CD, KL, BH, TS, HV, X/P, P/X...
              holpro_code
            else
              # Không có holpro → dùng is_day_off hoặc chấm công thực tế
              am_code =
                if am_off then nil
                elsif am&.is_day_off.present? then is_day_off_code[am.is_day_off]
                else (am&.att_checkin.present? || am&.att_checkout.present?) ? "X" : nil
                end

              pm_code =
                if pm_off then nil
                elsif pm&.is_day_off.present? then is_day_off_code[pm.is_day_off]
                else (pm&.att_checkin.present? || pm&.att_checkout.present?) ? "X" : nil
                end

              if am.nil? || am_off
                pm_code
              elsif pm.nil? || pm_off
                am_code
              elsif am_code == pm_code
                am_code
              else
                [am_code, pm_code].compact.join("/").presence
              end
            end

          values << (daily_code.presence || "")
          row_styles << cell_center

          # Tích lũy actual_work_units, giờ đăng ký, giờ thực tế (giữ nguyên logic cũ)
          [am, pm].each do |s|
            next if s.nil? || s.is_day_off.present?
            plan_in  = s.start_time.present? ? s.start_time.to_time : nil
            plan_out = s.end_time.present? ? s.end_time.to_time : nil
            checkin  = s.att_checkin.present?  ? s.att_checkin.in_time_zone("Asia/Ho_Chi_Minh")  : nil
            checkout = s.att_checkout.present? ? s.att_checkout.in_time_zone("Asia/Ho_Chi_Minh") : nil
            total_registered_sec += (plan_out - plan_in) if plan_in && plan_out
            if checkin && checkout
              total_actual_sec  += (checkout - checkin)
              actual_work_units += 0.5
            end
          end
        end

        # ── Tính đi muộn / về sớm (giữ nguyên logic cũ) ──────────────────────
        late_early_count   = 0
        late_early_minutes = 0

        late_attend = Attend.includes(shiftselection: :shiftissue)
                            .where(user_id: uid, stype: "ATTENDANCE")
                            .where("DATE(attends.checkin) BETWEEN ? AND ?", from_date, to_date)
                            .where.not(checkin: nil)
                            .order(checkin: :asc)
        late_attend.each do |item|
          start_str = item.shiftselection&.start_time
          next if start_str.blank?
          next if item.shiftselection&.shiftissue&.any? { |iss| iss.stype == "LATE-CHECK-IN" && iss.status == "APPROVED" }
          late_time = Time.zone.parse("#{item.checkin.to_date} #{start_str}")
          if item.checkin.present? && (item.checkin.change(sec: 0) - late_time.change(sec: 0)) > 15.minutes
            mins = (((item.checkin.change(sec: 0) - late_time.change(sec: 0)) - 15.minutes) / 60.0).ceil
            late_early_count   += 1
            late_early_minutes += mins
          end
        end

        early_attend = Attend.includes(shiftselection: :shiftissue)
                            .where(user_id: uid, stype: "ATTENDANCE")
                            .where("DATE(attends.checkout) BETWEEN ? AND ?", from_date, to_date)
                            .where.not(checkout: nil)
                            .order(checkout: :asc)
        early_attend.each do |item|
          end_str = item.shiftselection&.end_time
          next if end_str.blank?
          next if item.shiftselection&.shiftissue&.any? { |iss| iss.stype == "EARLY-CHECK-OUT" && iss.status == "APPROVED" }
          early_time = Time.zone.parse("#{item.checkout.to_date} #{end_str}")
          if item.checkout.present? && (early_time.change(sec: 0) - item.checkout.change(sec: 0)) > 15.minutes
            mins = (((early_time.change(sec: 0) - item.checkout.change(sec: 0)) - 15.minutes) / 60.0).ceil
            late_early_count   += 1
            late_early_minutes += mins
          end
        end

        # ── Tính công tác / đào tạo (giữ nguyên logic cũ) ────────────────────
        shift_ids       = shifts.map(&:id)
        work_trip_count = shift_ids.empty? ? 0.0 :
          Shiftissue.where(shiftselection_id: shift_ids, stype: "WORK-TRIP", status: "APPROVED").count * 0.5

        # ── Tổng hợp các cột cuối (dùng lại holiday_data đã lấy ở trên) ────────
        data                      = holiday_data
        so_cong_chuan             = count_days_excluding_sundays(year, month)

        ngay_cong_thuc_te         = actual_work_units.to_f - work_trip_count.to_f
        nghi_phep                 = data[:nghi_phep]
        nghi_bu                   = data[:nghi_bu]
        lam_tu_xa                 = ""
        nghi_che_do               = data[:nghi_che_do]
        di_cong_tac_dao_tao       = work_trip_count
        nghi_le_tet               = data[:nghi_le_tet]
        hoc_viec                  = data[:hoc_viec]
        nghi_khong_luong          = data[:khong_luong]
        nghi_huong_bhxh           = data[:che_do_bhxh]
        nghi_thai_san             = data[:thai_san]
        tong_cong_huong_luong     = actual_work_units.to_f + data[:nghi_phep].to_f + data[:nghi_bu].to_f + data[:nghi_che_do].to_f + data[:nghi_le_tet].to_f
        tong_gio_lam_dang_ky      = (total_registered_sec / 3600.0).round(2)
        tong_gio_lam_thuc_te      = (total_actual_sec / 3600.0).round(2)
        di_muon_ve_som_so_lan     = late_early_count
        di_muon_ve_som_so_phut    = late_early_minutes

        summary_values = [
          so_cong_chuan,
          ngay_cong_thuc_te,
          nghi_phep,
          nghi_bu,
          lam_tu_xa,
          nghi_che_do,
          di_cong_tac_dao_tao,
          nghi_le_tet,
          hoc_viec,
          nghi_khong_luong,
          nghi_huong_bhxh,
          nghi_thai_san,
          tong_cong_huong_luong,
          tong_gio_lam_dang_ky,
          tong_gio_lam_thuc_te,
          di_muon_ve_som_so_lan,
          di_muon_ve_som_so_phut,
        ]

        values     += summary_values
        row_styles += Array.new(17, cell_center)

        sheet.add_row values, style: row_styles
      end

      # ── Ghi chú cuối bảng ────────────────────────────────────────────────────
      sheet.add_row []
      sheet.add_row ["", "", "Ngày công đi làm",                                        "", "", "X"]
      sheet.add_row ["", "", "Nghỉ phép",                                               "", "", "P"]
      sheet.add_row ["", "", "Nghỉ bù",                                                 "", "", "NB"]
      sheet.add_row ["", "", "Làm từ xa",                                               "", "", "TX"]
      sheet.add_row ["", "", "Nghỉ chế độ hưởng lương (tang chế, cưới)",               "", "", "CD"]
      sheet.add_row ["", "", "Đi công tác, đào tạo, đi học",                           "", "", "CT"]
      sheet.add_row ["", "", "Nghỉ Lễ, Tết",                                           "", "", "L"]
      sheet.add_row ["", "", "Nghỉ không lương",                                       "", "", "KL"]
      sheet.add_row ["", "", "Nghỉ hưởng BHXH (bản thân ốm, con ốm)",                 "", "", "BH"]
      sheet.add_row ["", "", "Nghỉ thai sản",                                          "", "", "TS"]
      sheet.add_row ["", "", "Đối với những ngày đi làm, nghỉ không trọn ngày kí hiệu nửa ngày: X/P, NB/X, CD/X, P/KL, TX/P, P/X..."]
      sheet.add_row ["", "", "Đối với giảng viên, tính đủ ngày làm việc khi:"], style: bold_left
      sheet.add_row ["", "", "- Chấm công đủ 8 tiếng"]
      sheet.add_row ["", "", "- Chấm công 1 ca 4 tiếng và 1 ca có lịch giảng"]
      sheet.add_row ["", "", "- 2 ca có lịch giảng"]
      sheet.add_row ["", "", "Đối với nhân viên:"], style: bold_left
      sheet.add_row ["", "", "- Đi trễ, về sớm, chấm công bù được duyệt => tính trọn ca làm việc"]
      sheet.add_row ["", "", "- Đi trễ, về sớm quá 2 tiếng; chấm công bù không được duyệt => không tính ca làm việc đó"]

      # ── Độ rộng cột ──────────────────────────────────────────────────────────
      widths = [6, 15, 25, 25, 25, 12]
      widths += Array.new(day_count, 5)          # cột ngày – hẹp vì chỉ là 1-2 ký tự
      widths += [8, 10, 8, 6, 6, 8, 10, 6, 6, 8, 8, 8, 10, 12, 12, 8, 8]
      sheet.column_widths(*widths)
    end

    send_data package.to_stream.read,
              filename: "Bảng chấm công tổng hợp #{from_date.strftime('%d_%m_%Y')} - #{to_date.strftime('%d_%m_%Y')}.xlsx",
              type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
              disposition: 'attachment'
  end

  def merge_data(late_summary, early_summary)
    merged = {}

    # Gộp từ late_summary
    late_summary.values.each do |row|
      merged[row[:user_sid]] ||= row.slice(:user_sid, :user_name, :department_name, :positionjob_name)
      merged[row[:user_sid]].merge!(
        late_count: row[:late_count],
        late_minutes: row[:late_minutes],
        late_request: row[:late_request]
      )
    end

    # Gộp từ early_summary
    early_summary.values.each do |row|
      merged[row[:user_sid]] ||= row.slice(:user_sid, :user_name, :department_name, :positionjob_name)
      merged[row[:user_sid]].merge!(
        early_count: row[:early_count],
        early_minutes: row[:early_minutes],
        early_request: row[:early_request]
      )
    end

    # Convert thành mảng theo thứ tự cột
    final_data = merged.values.map do |row|
      {
        user_sid: row[:user_sid],
        user_name: row[:user_name],
        positionjob_name: row[:positionjob_name],
        department_name: row[:department_name],
        late_count: row[:late_count] || 0,
        late_minutes: row[:late_minutes] || 0,
        late_request: row[:late_request] || "",
        early_count: row[:early_count] || 0,
        early_minutes: row[:early_minutes] || 0,
        early_request: row[:early_request] || ""
      }
    end

  end

  # Hàm lấy chi tiết nghỉ làm bảng chấm công
  def parse_holiday_details_date(user_id, year, month)
    count_date = days_in_month(year, month)
    leave_days = Array.new(31, nil)

    # Gán giá trị mặc định
    (1..count_date).each do |day|
      date = Date.new(year.to_i, month.to_i, day)
      leave_days[day - 1] = date.sunday? ? "-" : "X"
    end
    (count_date...31).each { |i| leave_days[i] = "-" } if count_date < 31

    oHoliday = Holiday.where(user_id: user_id, year: year).first
    return {
      leave_days: leave_days,
      nc_tong: "-",
      nghi_phep: "-",
      nghi_bu: "-",
      di_hoc: "-",
      nghi_che_do: "-",
      nghi_le_tet: "-",
      hoc_viec: "-",
      khong_luong: "-",
      che_do_bhxh: "-",
      thai_san: "-"
    } unless oHoliday

    holpros = Holpro.joins(:holprosdetails, :holiday)
                    .where(holidays: { id: oHoliday.id })
                    .where("holpros.status IN (?)", ["DONE", "CANCEL-DONE"])
                    .select('holprosdetails.details', 'holprosdetails.sholtype','holpros.status')

    nc_chuan = count_days_excluding_sundays(year.to_i, month.to_i)

    leave_counts = {
      'NGHI-PHEP' => 0.0,
      'NGHI-BU' => 0.0,
      'DI-HOC' => 0.0,
      'NGHI-CDHH' => 0.0,
      'NGHI-LE' => 0.0,
      'HOC-VIEC' => 0.0,
      'NGHI-KHONG-LUONG' => 0.0,
      'NGHI-CHE-DO-BAO-HIEM-XA-HOI' => 0.0,
      'THAI-SAN' => 0.0
    }
    nc_tong_types = ['NGHI-KHONG-LUONG', 'NGHI-CHE-DO-BAO-HIEM-XA-HOI', 'HOC-VIEC', 'THAI-SAN']

    # Gom dữ liệu nghỉ theo ngày
    holpros.each do |holpro|
      next unless holpro.details.present? && holpro.sholtype.present?

      holpro.details.split('$$$').each do |entry|
        date_str, period = entry.split('-')
        next unless date_str && period

        begin
          date = Date.strptime(date_str, '%d/%m/%Y')
          next unless date.year == year && date.month == month

          day_index = date.day - 1
          next unless day_index >= 0 && day_index < count_date

          # Lưu nhiều bản ghi cho cùng 1 ngày
          leave_days[day_index] = [] if leave_days[day_index].is_a?(String) || leave_days[day_index].nil?
          leave_days[day_index] << { type: holpro.sholtype, period: period }

          # Tính số ngày nghỉ
          days = period == 'ALL' ? 1.0 : 0.5
          leave_counts[holpro.sholtype] += days if leave_counts.key?(holpro.sholtype)

        rescue ArgumentError => e
          Rails.logger.error "Invalid date format in details: #{date_str}, error: #{e.message}"
          next
        end
      end
    end

    # Chuyển đổi dữ liệu gom được thành ký hiệu hiển thị
    leave_days.map!.with_index do |val, _idx|
      if val.is_a?(Array)
        # Sắp xếp theo period để xác định sáng trước chiều
        sorted = val.sort_by do |v|
          case v[:period]
          when 'AM'  then 1
          when 'PM'  then 2
          when 'ALL' then 0
          else 9
          end
        end

        labels = sorted.map do |entry|
          type   = entry[:type]
          period = entry[:period]

          case type
          when 'NGHI-PHEP'
            if period == 'ALL' then 'P'
            elsif period == 'AM' then 'P/X'
            else 'X/P' end
          when 'NGHI-BU'
            if period == 'ALL' then 'NB'
            elsif period == 'AM' then 'NB/X'
            else 'X/NB' end
          when 'DI-HOC'
            if period == 'ALL' then 'DH'
            elsif period == 'AM' then 'DH/X'
            else 'X/DH' end
          when 'NGHI-CDHH'
            period == 'ALL' ? 'CD' : 'CD/KL'
          when 'NGHI-LE'
            if period == 'ALL' then 'LT'
            elsif period == 'AM' then 'LT/X'
            else 'X/LT' end
          when 'HOC-VIEC'
            if period == 'ALL' then 'HV'
            elsif period == 'AM' then 'HV/X'
            else 'X/HV' end
          when 'NGHI-KHONG-LUONG'
            if period == 'ALL' then 'KL'
            elsif period == 'AM' then 'KL/X'
            else 'X/KL' end
          when 'NGHI-CHE-DO-BAO-HIEM-XA-HOI'
            if period == 'ALL' then 'BH'
            elsif period == 'AM' then 'BH/X'
            else 'X/BH' end
          when 'THAI-SAN'
            if period == 'ALL' then 'TS'
            elsif period == 'AM' then 'TS/X'
            else 'X/TS' end
          else
            'X'
          end
        end

        # Áp dụng quy tắc gộp đặc biệt (trừ khi có tiền tố X/, giữ nguyên thứ tự)
        if labels.size == 2 && labels.none? { |lbl| lbl.start_with?('X/') }
          a, b = labels
          return_case = case [a.gsub(/^X\//, ''), b.gsub(/^X\//, '')]
                        when ['P', 'KL'] then a.include?('P') ? 'P/KL' : 'KL/P'
                        when ['KL', 'P'] then a.include?('KL') ? 'KL/P' : 'P/KL'
                        when ['P', 'BH'] then a.include?('P') ? 'P/BH' : 'BH/P'
                        when ['BH', 'P'] then a.include?('BH') ? 'BH/P' : 'P/BH'
                        when ['KL', 'BH'] then a.include?('KL') ? 'KL/BH' : 'BH/KL'
                        when ['BH', 'KL'] then a.include?('BH') ? 'BH/KL' : 'KL/BH'
                        else
                          "#{a}, #{b}"
                        end
          return_case
        else
          labels.join(', ')
        end
      else
        val
      end
    end

    leave_count = nc_tong_types.sum { |type| leave_counts[type] }
    nc_tong = nc_chuan - leave_count

    {
      leave_days: leave_days,
      nc_tong: nc_tong,
      nghi_phep: leave_counts['NGHI-PHEP'],
      nghi_bu: leave_counts['NGHI-BU'],
      di_hoc: leave_counts['DI-HOC'],
      nghi_che_do: leave_counts['NGHI-CDHH'],
      nghi_le_tet: leave_counts['NGHI-LE'],
      hoc_viec: leave_counts['HOC-VIEC'],
      khong_luong: leave_counts['NGHI-KHONG-LUONG'],
      che_do_bhxh: leave_counts['NGHI-CHE-DO-BAO-HIEM-XA-HOI'],
      thai_san: leave_counts['THAI-SAN']
    }
  end

  # Hàm lấy số ngày công chuẩn đã trừ chủ nhật
  def count_days_excluding_sundays(year, month)
    # Kiểm tra đầu vào hợp lệ
    return 0 unless (1..12).include?(month.to_i) && year.to_i.positive?

    begin
      # Tính tổng số ngày trong tháng
      total_days = Date.new(year, month, -1).day

      # Đếm số ngày Chủ Nhật
      sundays = 0
      (1..total_days).each do |day|
        date = Date.new(year, month, day)
        sundays += 1 if date.wday == 0 # wday == 0 là Chủ Nhật
      end

      # Trả về số ngày trừ đi Chủ Nhật
      total_days - sundays
    rescue ArgumentError => e
      Rails.logger.error "Invalid date: #{e.message}"
      0
    end
  end

  # Hàm trả về số ngày trong tháng của năm
  def days_in_month(year, month)
    # Kiểm tra đầu vào hợp lệ
    return 0 unless (1..12).include?(month.to_i) && year.to_i.positive?

    # Tính số ngày tối đa của tháng trong năm
    Date.new(year.to_i, month.to_i, -1).day
  end

  def col_name(idx)
    s = ""
    n = idx + 1
    while n > 0
      n, r = (n - 1).divmod(26)
      s.prepend((65 + r).chr)
    end
    s
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

end
