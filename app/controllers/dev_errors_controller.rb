class DevErrorsController < ApplicationController
  include DeverrorsHelper
  def index
    @code = params[:code]
    @tab = params[:tab] || "error"
    secret_key = "erp" # TODO: change secret key
    if !is_access_dev_log("ERP-DEV","READ") && ( @code.nil? || @code !=  secret_key)
      @code = 404
      render template: 'errlogs/standard_error', status: :internal_server_error, layout: false
      return
    else
      @per_page = params[:per_page]&.to_i || 30
      @page = params[:page]&.to_i || 1
      @page = 1 if @page < 1
      @offset = (@page - 1) * @per_page
      @max_pages = params[:max_page]&.to_i || 10
      @tab = 'error' if @tab == ''

      if @tab == 'error'
        data = Errlog.order(dtaccess: :desc, id: :desc)
        total_records = data.count
        @total_pages  = (total_records.to_f / @per_page.to_f).ceil
        @logs         = data.limit(@per_page).offset(@offset)
        render layout: false
        return
      end
      user_email   = params[:user_email].to_s.strip
      spath        = params[:spath].to_s.strip
      saction_name = params[:saction_name].to_s.strip
      min_note      = params[:min_note].to_s.strip
      @dtstart_from_iso, @dtstart_date_display, @dtstart_time_display, @dtstart_date_iso =
        normalize_dtstart_from(params[:dtstart_date], params[:dtstart_time], params[:dtstart_from])

      data = Mylog
               .select(:id, :user_name, :user_email, :spath, :saction_name, :dtstart, :dtend, :note)
               .order(dtstart: :desc, id: :desc)

      if user_email.present?
        esc = ActiveRecord::Base.send(:sanitize_sql_like, user_email.to_s.downcase)
        kw  = "%#{esc}%"
        data = data.where("LOWER(user_email) LIKE ?", kw)
      end

      if spath.present?
        esc = ActiveRecord::Base.send(:sanitize_sql_like, spath.to_s.downcase)
        data = data.where("LOWER(spath) LIKE ?", "%#{esc}%")
      end

      if saction_name.present?
        esc = ActiveRecord::Base.send(:sanitize_sql_like, saction_name.to_s.downcase)
        data = data.where("LOWER(saction_name) LIKE ?", "%#{esc}%")
      end

      if @dtstart_from_iso.present?
        if @dtstart_from_iso.include?('T')
          from_time = Time.zone.parse(@dtstart_from_iso) rescue nil
          if from_time
            to_time = from_time + 60.seconds
            data = data.where(dtstart: from_time...to_time)
          end
        else
          # chỉ có ngày
          d = Date.strptime(@dtstart_from_iso, '%Y-%m-%d') rescue nil
          if d
            data = data.where(dtstart: d.beginning_of_day..d.end_of_day)
          end
        end
      end

      if min_note.present?
        f = Float(min_note) rescue nil
        if f && f >= 1.0 && f <= 100.0
          data = data.where("note >= ?", f)
        end
      end

      total_records = data.unscope(:select).reorder(nil).count
      @total_pages  = (total_records.to_f / @per_page.to_f).ceil
      @logs         = data.limit(@per_page).offset(@offset)
      render layout: false
    end
  end

  private

  def parse_ddmmyyyy(str)
    return nil if str.blank?
    Date.strptime(str.strip, '%d/%m/%Y') rescue nil
  end

  def normalize_dtstart_from(date_str, time_str, fallback_raw)
    date_str = date_str.to_s.strip
    time_str = time_str.to_s.strip

    # 1) Có dtstart_date dạng YYYY-MM-DD (type=date)
    if date_str.present? && date_str =~ /\A\d{4}-\d{2}-\d{2}\z/
      d = Date.strptime(date_str, '%Y-%m-%d') rescue nil
      if d
        if time_str.present? && time_str =~ /\A\d{1,2}:\d{2}\z/
          hhmm = time_str.rjust(5, '0')
          return ["#{d.strftime('%Y-%m-%d')}T#{hhmm}", d.strftime('%d/%m/%Y'), hhmm, d.strftime('%Y-%m-%d')]
        else
          return [d.strftime('%Y-%m-%d'), d.strftime('%d/%m/%Y'), "", d.strftime('%Y-%m-%d')]
        end
      end
    end

    # 2) Tương thích tham số cũ dtstart_from
    raw = fallback_raw.to_s.strip
    return [nil, "", "", ""] if raw.blank?

    # yyyy-mm-ddThh:mm
    if raw =~ /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}\z/
      t = Time.zone.parse(raw) rescue nil
      return [raw, t&.strftime('%d/%m/%Y') || "", t&.strftime('%H:%M') || "", t&.strftime('%Y-%m-%d') || ""]
    end

    # yyyy-mm-dd
    if raw =~ /\A\d{4}-\d{2}-\d{2}\z/
      d = Date.strptime(raw, '%Y-%m-%d') rescue nil
      return [raw, d&.strftime('%d/%m/%Y') || "", "", d&.strftime('%Y-%m-%d') || ""]
    end

    # dd/mm/yyyy [hh:mm]
    if raw =~ /\A\d{2}\/\d{2}\/\d{4}(?:\s+\d{1,2}:\d{2})?\z/
      date_part, time_part = raw.split(/\s+/, 2)
      d = parse_ddmmyyyy(date_part)
      if d
        if time_part.present?
          hhmm = time_part.rjust(5, '0')
          return ["#{d.strftime('%Y-%m-%d')}T#{hhmm}", d.strftime('%d/%m/%Y'), hhmm, d.strftime('%Y-%m-%d')]
        else
          return [d.strftime('%Y-%m-%d'), d.strftime('%d/%m/%Y'), "", d.strftime('%Y-%m-%d')]
        end
      end
    end

    t = Time.zone.parse(raw) rescue nil
    if t
      if raw.include?(':')
        return [t.strftime('%Y-%m-%dT%H:%M'), t.strftime('%d/%m/%Y'), t.strftime('%H:%M'), t.strftime('%Y-%m-%d')]
      else
        d = t.to_date
        return [d.strftime('%Y-%m-%d'), d.strftime('%d/%m/%Y'), "", d.strftime('%Y-%m-%d')]
      end
    end

    [nil, "", "", ""]
  end

end