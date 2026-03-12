class ShiftissuesController < ApplicationController
  before_action :authorize


  def update_shiftissue
    status = params[:status]
    raw_data = params[:data]
    data = JSON.parse(raw_data) rescue []
    
    success = false
    results = []
    begin
      ActiveRecord::Base.transaction do
        data.each do |issue|
          representative_id = issue["id"]
          reason = issue["reason"]
          
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
                shiftissue.update({status: status, content: reason, approved_at: Time.now})
              else
                shiftissue.update({status: status, approved_at: Time.now})
                case shiftissue.stype
                when "EARLY-CHECK-OUT"
                  process_shiftissue_early(shiftissue, status)
                when "LATE-CHECK-IN"
                  process_shiftissue_late(shiftissue, status)
                when "SHIFT-CHANGE"
                  shiftissue.update({status: "PENDING", approved_at: Time.now})
                  results << process_shiftissue_change(shiftissue, status)
                when "ADDITIONAL-CHECK-IN"
                  process_shiftissue_additional_in(shiftissue, status)
                when "ADDITIONAL-CHECK-OUT"
                  process_shiftissue_additional_out(shiftissue, status)
                when "UPDATE-SHIFT"
                  process_shiftissue_update(shiftissue, status)
                when "EDIT-PLAN"
                  # @author: trong.lq
                  # @date: 23/10/2025
                  # Xử lý duyệt đề xuất chỉnh sửa kế hoạch làm việc
                  process_shiftissue_edit_plan(shiftissue, status)
                when "COMPENSATORY-LEAVE"
                  process_shiftissue_compensatory_leave(shiftissue, status)
                end
              end
              
              send_shiftissue_notification(shiftissue, status, reason)
            end
          end
          success = true
        end
      end
    rescue => e
      position = e.backtrace.to_json.html_safe.gsub("`", "")
      message = e.message.gsub("`", "")
    end

    rs_Groups = results.compact.present? ? group_by_date(results) : []
    swapped = swap_cross_day(rs_Groups)
    updated_result = force_update_by_swapped_data(swapped)
    classified_cases = classify_shift_change_cases_before_swap(swapped) || []
    data = update_shift_issues_with_classified_cases(classified_cases) || []
    
    respond_to do |format|
      format.html
      format.js { render js: "onApproval(#{success}); console.log(#{classified_cases.to_json.html_safe},#{data.to_json.html_safe})" }
    end
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
      "EDIT-PLAN" => "Chỉnh sửa kế hoạch làm việc",
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

  # xử lý duyệt về sớm: không thay đổi gì
  def process_shiftissue_early(shiftissue,status)
    
  end
  
  # xử lý duyệt đi làm muộn: không thay đổi gì
  def process_shiftissue_late(shiftissue,status)
    
  end

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

  # xử lý duyệt chấm công bù giờ vào : us_start => attends.check_in
  def process_shiftissue_additional_in(shiftissue,status)
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
  end
  
  # xử lý duyệt chấm công bù giờ ra: us_end => attends.check_out
  def process_shiftissue_additional_out(shiftissue,status)
    attend = Attend.find_by(shiftselection_id: shiftissue.shiftselection_id)
    shiftselection = Shiftselection.find(shiftissue.shiftselection_id)
    us_end = shiftissue.us_end.split(":")
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
  end

  # xử lý duyệt cập nhật ca: us_start => shiftselections.start_time || us_end => shiftselections.end_time
  def process_shiftissue_update(shiftissue,status)
    shiftselection = Shiftselection.find(shiftissue.shiftselection_id) rescue nil
    if shiftselection.present?
      shiftselection.update({
        start_time: shiftissue.us_start,
        end_time: shiftissue.us_end,
      })
    end
  end

  # xử lý duyệt nghỉ bù: cập nhật is_day_off = COMPENSATORY-LEAVE
  def process_shiftissue_compensatory_leave(shiftissue, status)
    return unless status == "APPROVED"

    original_shift = Shiftselection.find_by(id: shiftissue.shiftselection_id)
    return unless original_shift
    original_shift.update(is_day_off: "COMPENSATORY-LEAVE")
    
    # Lấy thông tin ngày nghỉ bù và ca nghỉ bù đã lưu
    leave_date = Date.parse(shiftissue.us_start)
    leave_shift_id = shiftissue.us_end.to_s
    
    # Lấy user từ shift gốc (ngày lễ đi làm)
    user_id = original_shift.scheduleweek.user_id

    l_target_shift = Shiftselection.joins(:scheduleweek)
                                   .where(scheduleweeks: {user_id: user_id, status: 'APPROVE'})
                                   .where(work_date: leave_date.all_day)
    
    unless leave_shift_id == "-1"
      l_target_shift = l_target_shift.where(workshift_id: leave_shift_id)
    end

    if l_target_shift.exists?
      l_target_shift.update_all(
        is_day_off: "COMPENSATORY-LEAVE",
        day_off_reason: "Nghỉ bù cho ngày #{original_shift.work_date.strftime('%d/%m/%Y')}"
      )
    end
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

      # Code cũ - @author: trong.lq @date: 15/01/2025
      # ca_doi_khac_ngay_khac_tuan (TH1: Khác ngày, khác tuần)
      cross_week_diff_day_partner = all_shifts.find do |s|
        s[:workshift_id] == row[:workshift_id] &&
        s[:scheduleweek_id] != row[:scheduleweek_id] &&
        s[:work_date].to_date != row[:work_date].to_date
      end

      # Code mới - @author: trong.lq @date: 15/01/2025
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
        # Code cũ - @author: trong.lq @date: 15/01/2025
        # self_shift_other_day_id: self_shift_other_day[:id],
        # self_shift_other_day_date: self_shift_other_day[:work_date],
        # Code cũ - @author: trong.lq @date: 15/01/2025
        cross_week_diff_day_partner_id: cross_week_diff_day_partner&.dig(:id),
        cross_week_diff_day_partner_other_date: cross_week_diff_day_partner&.dig(:work_date),
        # Code mới - @author: trong.lq @date: 15/01/2025
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
      # Code cũ - @author: trong.lq @date: 15/01/2025
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
      Shiftissue.create(
        shiftselection_id: shift_2,
        ref_shift_changed: shift_1,
        stype: "SHIFT-CHANGE-APPROVED",
        content: "Bản ghi duyệt bị đổi ca",
        status: "APPROVED",
        note: "bị đổi ca",
        us_start: issue.us_start,
        us_end: issue.us_end,
        approved_by: issue.approved_by,
        approved_at: issue.approved_at,
        created_at: Time.current,
        updated_at: Time.current
      )
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

  # Xử lý duyệt đề xuất chỉnh sửa kế hoạch làm việc
  # @author: trong.lq
  # @date: 23/10/2025
  # @input: shiftissue, status
  # @return: void
  def process_shiftissue_edit_plan(shiftissue, status)
    return unless status == "APPROVED"
    
    # Lấy thông tin tuần cần chỉnh sửa từ content
    week_info = shiftissue.content # "Tuần 43"
    
    # Lấy thông tin user từ shiftselection
    shiftselection = shiftissue.shiftselection
    scheduleweek = shiftselection.scheduleweek
    user_id = scheduleweek.user_id
    
    # Lấy week_num từ week_info (VD: "Tuần 43" -> 43)
    week_num = week_info.gsub("Tuần ", "").to_i
    
    # Cập nhật trạng thái Scheduleweek thành "TEMP" (NHÁP)
    # @author: trong.lq
    # @date: 23/10/2025
    # Chuyển kế hoạch tuần về trạng thái NHÁP để user có thể chỉnh sửa
    Scheduleweek.where(user_id: user_id, week_num: week_num).update(status: "TEMP")
  end
end