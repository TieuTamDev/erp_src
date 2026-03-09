class ScheduleweeksController < ApplicationController
  before_action :authorize
  include AttendConcern

  # Save scheduleweeks
  # @author: Dat Le
  # @date: 31/07/2025
  # @input: user_id, details
  # @return
  def save_scheduleweeks
    user_id     = params[:user_id].presence || session[:user_id]
    data        = params[:data]

    return render json: { success: false, message: 'Thiếu dữ liệu' },
                  status: :unprocessable_entity if data.blank?

    ActiveRecord::Base.transaction do
      data.each do |item|
        start_date = Date.parse(item[:start_date])
        end_date   = Date.parse(item[:end_date])
        week_num   = start_date.cweek
        week_year  = start_date.cwyear

        # kiểm trùng tuần PENDING/APPROVED
        if %w[PENDING APPROVED].include?(item[:current_status].to_s.upcase)
          msgs = item[:status].upcase == 'APPROVED' ?
                  "Tuần #{week_num} đã được phê duyệt trước đó. Vui lòng đăng kí tuần khác!" :
                  "Tuần #{week_num} đang được phê duyệt. Vui lòng đăng kí tuần khác!"
          render json: { success: false, message: msgs }, status: :ok
          return
        end

        # tìm hoặc tạo
        scheduleweek =
          if item[:id].present?
            Scheduleweek.find_by!(id: item[:id], user_id: user_id)
          else
            existing = Scheduleweek
                         .where(user_id: user_id, year: week_year, week_num: week_num)
                         .order(created_at: :desc)
                         .first
            if existing
              if %w[PENDING APPROVED].include?(existing.status.to_s.upcase)
                msg = existing.status.to_s.upcase == 'APPROVED' ?
                        "Tuần #{week_num} đã được phê duyệt trước đó. Vui lòng đăng kí tuần khác!" :
                        "Tuần #{week_num} đang được phê duyệt. Vui lòng đăng kí tuần khác!"
                render json: { success: false, message: msg }, status: :ok
                return
              end
              existing
            else
              Scheduleweek.new(user_id: user_id)
            end
          end

        scheduleweek.assign_attributes(
          user_id:   user_id,
          week_num:   week_num,
          year:       week_year,
          start_date: start_date,
          end_date:   end_date,
          status:     item[:status],
          time_required: item[:time_required],
          time_register: item[:time_register],
          checked_by: item[:checked_by]
        )
        scheduleweek.save!

        # reset & ghi shiftselection
        # map lại shiftselections cũ
        old_shiftselections = scheduleweek.shiftselection.includes(:shiftissue).to_a
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
          new_ss = scheduleweek.shiftselection.create!(
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
        Scheduleweek::Shiftselection.where(id: old_ids).delete_all rescue scheduleweek.shiftselection.where(id: old_ids).delete_all

        # send notify
        if (item[:status] == "PENDING")
          user_name = "#{current_user.last_name} #{current_user.first_name} (#{current_user.sid})"
          start_date = Time.zone.parse(item[:start_date]).strftime("%d/%m/%Y")
          end_date = Time.zone.parse(item[:end_date]).strftime("%d/%m/%Y")
          notify = Notify.create(
            title: "Thông báo gửi kế hoạch làm việc",
            contents: "Nhân viên <strong>#{user_name}</strong> đã gửi kế hoạch làm việc <strong>tuần #{item[:week_num]} (#{start_date} - #{end_date})</strong>.<br>",
            receivers: "Hệ thống ERP",
            senders: user_name,
            stype: "SCHEDULEWEEK",
            )
          Snotice.create(
            notify_id: notify.id,
            user_id: scheduleweek.checked_by,
            isread: false,
            username: nil
          )
        end
      end

    end

    render json: { success: true }, status: :ok
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => e
    render json: { success: false, message: e.message }, status: :unprocessable_entity
  rescue => e
    Rails.logger.error(e)
    render json: { success: false, message: "Lỗi khi lưu lịch làm việc: #{e.message}" },
           status: :internal_server_error
  end

  def workshift_code_map
    Workshift.pluck(:name, :id).map { |name, id| [slugify(name), id] }.to_h
  end

  # Get scheduleweeks
  # @author: Dat Le
  # @date: 31/07/2025
  # @input: user_id
  # @return
  def get_scheduleweeks
    user_id = params[:user_id].presence || session[:user_id]
    from_date = Date.current.beginning_of_week(:monday) - 1.day
    to_date   = from_date + 3.weeks + 1.day

    scheduleweek = Scheduleweek
            .where(user_id: user_id)
            .where(status: %w[TEMP PENDING REJECTED APPROVED])
            .where('DATE(start_date) BETWEEN ? AND ?', from_date, to_date)
            .includes(:shiftselection)
            .order(:start_date)

    render json: scheduleweek.map { |item|
      {
        id:          item.id,
        week_num:    item.week_num,
        year:        item.year,
        start_date:  item.start_date&.strftime("%Y-%m-%d"),
        end_date:    item.end_date.to_date.strftime("%Y-%m-%d"),
        status:      item.status,
        reason:      item.reason,
        checked_by:  item.checked_by,
        shift_details: item.shiftselection.map { |shiftselection|
          {
            id:           shiftselection.id,
            workshift_id: shiftselection.workshift_id,
            workshift_code: workshift_code_map.invert[shiftselection.workshift_id],
            work_date:    shiftselection.work_date&.strftime("%Y-%m-%d"),
            location:    shiftselection.location,
            start_time:   shiftselection.start_time,
            end_time:     shiftselection.end_time,
            is_day_off:   shiftselection.is_day_off
          }
        }
      }
    }
  end

end