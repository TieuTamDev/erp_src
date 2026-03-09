module AttendsHelper
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
        total_hours_overall = 0.0
        sw_hours_map = Hash.new(0.0)

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
            begin
              st = row.start_time.to_s.strip
              et = row.end_time.to_s.strip
              to_minutes = ->(hhmm) {
                hh, mm = hhmm.split(':').map(&:to_i)
                (hh * 60) + (mm || 0)
              }
              minutes = (st.present? && et.present?) ? (to_minutes.call(et) - to_minutes.call(st)) : 0
              hours   = (minutes > 0) ? (minutes / 60.0) : 0.0
              total_hours_overall += hours
              sw_hours_map[row.scheduleweek_id] += hours if row.scheduleweek_id
            rescue => e
              e.message
            end
          end
        end
        sw_hours_map.each do |sw_id, h|
          sw = Scheduleweek.lock.find_by(id: sw_id)
          next unless sw
          delta = (status == 'APPROVED') ? -h : h
          sw.time_required = ((sw.time_required || 0).to_f + delta).round(1)
          sw.time_register = ((sw.time_register || 0).to_f + delta).round(1)
          sw.save!
        end
      end
      :ok
    end
  rescue => e
    e.message
  end

  def parse_dates_leaves_data(dates)
    dates.to_s.split('$$$').map(&:strip).flat_map  do |seg|
      if seg =~ /\A(\d{2}\/\d{2}\/\d{4})-(AM|PM|ALL)\z/i
        d = (Time.zone.strptime($1, '%d/%m/%Y').to_date rescue nil)
        { date: d, session: $2.upcase } if d
      end
    end
  end

end