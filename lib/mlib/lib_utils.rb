require 'rest-client'
require 'json'
require 'date'
# include AppointmentsHelper
class MUtils

  # System Check Configuration
  TIMEOUT = 30
  BMU_EMAIL_DOMAIN = '@bmu.edu.vn'
  
  # Danh sách email nhận báo cáo hệ thống
  SYSTEM_REPORT_EMAILS = %w[
    htdat
    lnqthai
    ltdat
    ntpvy
    vqlam
    lnhuy
    lbtrong
    nxkhoa
    lqtrong
    tpdong
    dqhai
  ].map { |username| "#{username}#{BMU_EMAIL_DOMAIN}" }.freeze

  # Domain Expiry Manager - Quản lý expiry date và gửi thông báo
  DOMAIN_EXPIRY_DATA = {
    'erp.bmtu.edu.vn' => '2026-04-01',
    'phongkhamdalieubmt.com' => '2026-07-10',
    'nhakhoabmt.com' => '2027-03-03',
    'phauthuatthammybmt.com' => '2026-07-07',
    'bpharmed.vn' => '2026-06-04',
    'bmu.edu.vn' => '2027-03-07',
    'abri.bmtu.edu.vn' => '2026-04-01'
  }.freeze

  # Số ngày trước khi hết hạn để gửi cảnh báo
  WARNING_DAYS = 10

  ERRLOG_ENDPOINTS = {
    erp_sftraining:   'https://erp.bmtu.edu.vn/sftraining/api/v1/mapi_utils/errlogs',
    capp_sftraining:  'https://capp.bmtu.edu.vn/sftraining/api/v1/mapi_utils/errlogs',
    prerp_sftraining: 'https://prerp.bmtu.edu.vn/sftraining/api/v1/mapi_utils/errlogs',
    prerp_masset:     'https://prerp.bmtu.edu.vn/masset/api/v1/mapi_utils/errlogs',
    erp_masset:       'https://erp.bmtu.edu.vn/masset/api/v1/mapi_utils/errlogs',
    erp_get_departments: 'https://erp.bmtu.edu.vn/api/v1/mapi_utils/get_departments'
  }.freeze

  SIMPLE_URLS = [
    'https://erp.bmtu.edu.vn',
    'http://phongkhamdalieubmt.com',
    'http://nhakhoabmt.com',
    'http://phauthuatthammybmt.com',
    'http://bpharmed.vn/',
    'https://bmu.edu.vn/',
    'http://abri.bmtu.edu.vn/'
  ].freeze
  def self.get_next_stages(stageid,streamid,previous_stages)

    oStage_Road = StageRoad.where("stream_id = #{streamid} AND from_stage = #{stageid}").first

    if !oStage_Road.nil?
      if previous_stages.count == 0 && !oStage_Road.to_stage.nil?
        previous_stages.append({:id => oStage_Road.to_stage.id.to_s, :name => oStage_Road.to_stage.name, :desc => oStage_Road.to_stage.desc})
        self.get_next_stages(oStage_Road.to_stage.id,streamid,previous_stages)
      else
        flg = false
        previous_stages.each do |item|

          if !oStage_Road.to_stage.nil? && item[:id] == oStage_Road.to_stage.id.to_s
            flg = true
          end
        end

        if flg == false && !oStage_Road.to_stage.nil?

          previous_stages.append({:id => oStage_Road.to_stage.id.to_s, :name => oStage_Road.to_stage.name, :desc => oStage_Road.to_stage.desc})

          self.get_next_stages(oStage_Road.to_stage.id,streamid,previous_stages)
        end
      end
    end

  end


  def self.get_path_permision(permision)
    oPermission = Permission.where("id = #{permision}").first
    result = false
    oPermission.accessrights.each do |accessright|
      if accessright.value == true
        result = true
      end
    end
    return result
  end


  def self.is_integer(sobj)
    iobj = sobj.to_i
    if iobj.to_s == sobj.to_s
      return true
    end
    return false
  end

  def self.filter_url(surl)
    arrUrl = surl.split("/")
    result = ""
    index = 0
    arrUrl.each do |sitem|

      if is_integer(sitem) == true
        break
      end

      if index == 0
        if sitem != ""
          result = "/" + sitem
        end

      else
        result = result + "/" + sitem
      end
      index = index + 1
    end

    return result


  end

  def self.getlevel(group_id,ilevel)
    oGroup = Group.where("id = #{group_id}").first
    if oGroup.nil?
      return ilevel
    else
      parent_id = oGroup.parent
      if parent_id.nil?
        return ilevel + 1
      else
        getlevel(parent_id,ilevel + 1)
      end
    end
  end


  def self.isgroupexisting(group, groups)
    groups.each do |oGroup|
      if group.id.to_s == oGroup.id.to_s
        return true
      end
    end
    return false
  end

  # ==== System Check Methods ====  
  def self.perform_system_check
    ts     = Time.current.strftime('%d/%m/%Y %H:%M')
    lines  = []
    has_errors = false
    
    puts "===> Đang kiểm tra hệ thống, tổng số URL: #{ERRLOG_ENDPOINTS.size + SIMPLE_URLS.size}"
    
    # 1. Check websites TRƯỚC (nếu có lỗi thì dừng)
    # @author: trong.lq
    # @date: 21/01/2025
    # Cải thiện: Thêm thông tin chi tiết về lỗi
    puts "🌐 Checking websites first..."
    SIMPLE_URLS.each do |url|
      status = nil
      error_details = nil
      
      begin
        resp = RestClient::Request.execute(method: :get, url: url, timeout: TIMEOUT, open_timeout: TIMEOUT)
        if resp.code == 200
          status = 'OK'
        else
          has_errors = true
          status = "ERROR_HTTP(#{resp.code})"
          error_details = "HTTP status code: #{resp.code}"
        end
      rescue RestClient::Exceptions::Timeout => e
        has_errors = true
        status = "FAIL_HTTP - Timeout"
        error_details = "Không kết nối được (Timeout sau #{TIMEOUT}s): #{e.message}"
      rescue RestClient::Exceptions::OpenTimeout => e
        has_errors = true
        status = "FAIL_HTTP - Connection Timeout"
        error_details = "Không mở được kết nối (Timeout sau #{TIMEOUT}s): #{e.message}"
      rescue RestClient::ExceptionWithResponse => e
        has_errors = true
        status = "FAIL_HTTP - HTTP Error"
        error_details = "Lỗi HTTP (#{e.http_code}): #{e.message}"
      rescue => e
        has_errors = true
        status = "FAIL_HTTP - #{e.class.name}"
        error_details = "Lỗi: #{e.class.name} - #{e.message}"
      end
      
      line = format_line(nil, url, status, nil, error_details)
      puts line
      lines << line
    end
    
    # 2. Check API errlog
    # @author: trong.lq
    # @date: 21/01/2025
    # Cải thiện: Thêm thông tin chi tiết về môi trường khi có lỗi
    puts "🔍 Checking API errlog endpoints..."
    
    # Map tên môi trường sang mô tả tiếng Việt
    # @author: trong.lq
    # @date: 21/01/2025
    env_descriptions = {
      erp_sftraining: 'ERP - SFTraining',
      capp_sftraining: 'CAPP - SFTraining',
      prerp_sftraining: 'PreERP - SFTraining',
      prerp_masset: 'PreERP - Masset',
      erp_masset: 'ERP - Masset',
      erp_get_departments: 'ERP - Get Departments'
    }
    
    ERRLOG_ENDPOINTS.each do |name, url|
      status = nil
      error_details = nil
      
      begin
        resp = RestClient::Request.execute(method: :get, url: url, timeout: TIMEOUT, open_timeout: TIMEOUT)
        response_body = JSON.parse(resp.body) rescue {}
        
        # Kiểm tra response có field 'status' (cho errlogs) hoặc 'data' (cho get_departments)
        if response_body['status'] == 'OK'
          status = 'OK - Có phản hồi tới database(csdl)'
        elsif response_body['data'].present?
          # API get_departments trả về {data: [...]}
          status = 'OK - Có phản hồi tới database(csdl)'
        elsif response_body['status'].present?
          has_errors = true
          status = "ERROR_LOGS(#{response_body['status']})"
          error_details = "API trả về status: #{response_body['status']}"
        else
          has_errors = true
          status = "ERROR_LOGS - Invalid Response"
          error_details = "API không trả về status hoặc data hợp lệ"
        end
      rescue RestClient::Exceptions::Timeout => e
        has_errors = true
        status = "FAIL_LOGS - Timeout"
        error_details = "Không kết nối được (Timeout sau #{TIMEOUT}s): #{e.message}"
      rescue RestClient::Exceptions::OpenTimeout => e
        has_errors = true
        status = "FAIL_LOGS - Connection Timeout"
        error_details = "Không mở được kết nối (Timeout sau #{TIMEOUT}s): #{e.message}"
      rescue RestClient::ExceptionWithResponse => e
        has_errors = true
        status = "FAIL_LOGS - HTTP Error"
        error_details = "Lỗi HTTP (#{e.http_code}): #{e.message}"
      rescue JSON::ParserError => e
        has_errors = true
        status = "FAIL_LOGS - Invalid Response"
        error_details = "Không parse được JSON response: #{e.message}"
      rescue => e
        has_errors = true
        status = "FAIL_LOGS - #{e.class.name}"
        error_details = "Lỗi: #{e.class.name} - #{e.message}"
      end
      
      # Format line với thông tin chi tiết về môi trường
      env_name = env_descriptions[name] || name.to_s
      line = format_line(name, url, status, env_name, error_details)
      puts line
      lines << line
    end

    require 'date'
    
    # Nếu có lỗi website/API thì dừng lại, không check domain expiry
    if has_errors
      puts "❌ Có lỗi website/API → Dừng lại, không check domain expiry"
      lines << ""
      lines << "❌ System check stopped due to website/API errors"
    else
      puts "✅ Tất cả websites/API OK → Tiếp tục check domain expiry"
      
      # Check domain expiry dates (chỉ khi không có lỗi)
      puts "🔍 Checking domain expiry dates..."
      expiring_domains = check_expiring_domains
      
      # Thêm thông tin domain expiry vào báo cáo
      if expiring_domains.any?
        lines << ""
        lines << "📅 Domain Expiry Status:"
        expiring_domains.each do |domain_info|
          domain = domain_info[:domain]
          expiry = domain_info[:expiry_date]
          days = domain_info[:days_remaining]
          
          if days == 0
            lines << "[DOMAIN] #{domain} → EXPIRES_TODAY(#{expiry})"
          else
            lines << "[DOMAIN] #{domain} → EXPIRES_SOON(#{expiry}, #{days} days)"
          end
        end
      else
        lines << "[DOMAIN] All domains are safe (no expiry warnings)"
      end
    end

    # 5) Gửi email test để kiểm tra hệ thống gửi mail
    test_email_success = send_email_via_api(
      ['4email1erp@bmtuvietnam.com'],
      "[TEST] Gửi mail kiểm tra từ hệ thống",
      "✅ Đây là email test gửi từ hệ thống lúc #{Time.current.strftime('%d/%m/%Y %H:%M:%S')}"
    )

    if test_email_success
      lines << "[EMAIL-TEST] Gửi đến 4email1erp@bmtuvietnam.com → OK"
    else
      lines << "[EMAIL-TEST] Gửi đến 4email1erp@bmtuvietnam.com → ❌ FAIL(API Error)"
      
      # Gửi cảnh báo vì mail test thất bại
      alert_success = send_email_via_api(
        SYSTEM_REPORT_EMAILS,
        "❌ CẢNH BÁO: Lỗi gửi mail test đến 4email1erp",
        <<~BODY
          Hệ thống không gửi được mail test đến: 4email1erp@bmtuvietnam.com

          🕒 Thời gian: #{Time.current.strftime('%d/%m/%Y %H:%M:%S')}
          ❗ Lỗi: API gửi email không hoạt động

          Vui lòng kiểm tra:
          - API send_email có hoạt động không
          - Cấu hình gửi mail (SMTP, domain, SPF/DKIM)
          - Hoặc email này đang bị chặn / đưa vào spam
        BODY
      )
      
      if alert_success
        lines << "[EMAIL-ALERT] Đã gửi cảnh báo đến quản trị → OK"
      else
        lines << "[EMAIL-ALERT] Không gửi được cảnh báo đến quản trị → ❌ FAIL(API Error)"
      end
    end
    begin
      api_url = "https://erp.bmtu.edu.vn/sftraining/api/v1/mapi_utils/summary_today"
      resp = RestClient.get(api_url)
      
      # Debug: Log response để kiểm tra
      puts "API Response: #{resp.body[0..200]}..." if resp.body.length > 200
      
      # Parse JSON, nếu kết quả là String thì parse lại
      data = JSON.parse(resp.body)
      
      # Nếu data là String (double-encoded), parse lại
      if data.is_a?(String)
        data = JSON.parse(data)
      end

      # Kiểm tra data có phải Hash không
      if data.present? && data.is_a?(Hash)
        # Thông tin staff
        top_staff_name    = data.dig("top_staff", "name") || "N/A"
        top_staff_views   = data.dig("top_staff", "view_count") || 0
        top_staff_access  = data.dig("top_staff", "access_count") || 0
        staff_path        = data.dig("top_path_by_staff", "path").to_s.gsub(/^https?:\/\/[^\/]+/, '')
        staff_count       = data.dig("top_path_by_staff", "count") || 0

        # Thông tin student
        top_student_name  = data.dig("top_student", "name") || "N/A"
        top_student_views = data.dig("top_student", "view_count") || 0
        top_student_access = data.dig("top_student", "access_count") || 0
        student_path      = data.dig("top_path_by_student", "path").to_s.gsub(/^https?:\/\/[^\/]+/, '')
        student_count     = data.dig("top_path_by_student", "count") || 0

        # Thông tin đăng nhập nhiều nhất (từ hệ thống khác)
        top_login_staff_name = data.dig("top_login_staff", "name") || "N/A"
        top_login_staff_access = data.dig("top_login_staff", "access_count") || 0
        top_login_student_name = data.dig("top_login_student", "name") || "N/A"
        top_login_student_access = data.dig("top_login_student", "access_count") || 0

        lines << ""
        lines << "📊 Thống kê truy cập hôm nay:"
        lines << "- Nhân viên:"
        lines << "  + Xem trang nhiều nhất: #{top_staff_name} (#{top_staff_views} lượt xem, #{top_staff_access} lần đăng nhập)"
        lines << "  + Đăng nhập nhiều nhất: #{top_login_staff_name} (#{top_login_staff_access} lần)"
        lines << "  + Trang truy cập nhiều: \"#{staff_path}\" (#{staff_count})"
        lines << "- Sinh viên:"
        lines << "  + Xem trang nhiều nhất: #{top_student_name} (#{top_student_views} lượt xem, #{top_student_access} lần đăng nhập)"
        lines << "  + Đăng nhập nhiều nhất: #{top_login_student_name} (#{top_login_student_access} lần)"
        lines << "  + Trang truy cập nhiều: \"#{student_path}\" (#{student_count})"
      else
        lines << "[SUMMARY] ⚠️ API trả về dữ liệu không hợp lệ: #{data.class} - #{data.inspect[0..100]}"
      end
    rescue => e
      lines << "[SUMMARY] ❌ Lỗi khi gọi API summary_today: #{e.class} - #{e.message}"
    end


    # 6) Gọi API top_login_users để lấy thông tin user login nhiều nhất
    begin
      api_url = "https://erp.bmtu.edu.vn/api/v1/mapi_utils/top_login_users"
      resp = RestClient.get(api_url)
      data = JSON.parse(resp.body)

      if data.present? && data['success']
        lines << ""
        lines << "👥 Thống kê user login nhiều nhất hôm nay:"
        
        # Thông tin tổng quan
        summary = data['summary']
        lines << "- Tổng số user: #{summary['total_users']}"
        lines << "- Tổng số lần login: #{summary['total_logins']}"
        
        # Thông tin BUH
        buh_data = data['data']['buh']
        if buh_data['top_users'].any?
          lines << ""
          lines << "🏢 BUH:"
          lines << "  + Số user: #{buh_data['total_users']} (#{buh_data['total_logins']} lần login)"
          buh_data['top_users'].each do |user|
            lines << "  + Top: #{user['full_name']} (#{user['sid']}) - #{user['login_count']} lần"
            lines << "    IP: #{user['ip_addresses']}"
            lines << "    Từ: #{user['first_login']} đến #{user['last_login']}"
          end
        else
          lines << ""
          lines << "🏢 BUH: Không có user login hôm nay"
        end
        
        # Thông tin BMU
        bmu_data = data['data']['bmu']
        if bmu_data['top_users'].any?
          lines << ""
          lines << "🎓 BMU:"
          lines << "  + Số user: #{bmu_data['total_users']} (#{bmu_data['total_logins']} lần login)"
          bmu_data['top_users'].each do |user|
            lines << "  + Top: #{user['full_name']} (#{user['sid']}) - #{user['login_count']} lần"
            lines << "    IP: #{user['ip_addresses']}"
            lines << "    Từ: #{user['first_login']} đến #{user['last_login']}"
          end
        else
          lines << ""
          lines << "🎓 BMU: Không có user login hôm nay"
        end
      else
        lines << "[LOGIN-STATS] ⚠️ Không có dữ liệu login hôm nay"
      end
    rescue => e
      lines << "[LOGIN-STATS] ❌ Lỗi khi gọi API top_login_users: #{e.class} - #{e.message}"
    end
    

    # Gộp báo cáo
    header = "System Check Report (#{Time.now.in_time_zone('Asia/Ho_Chi_Minh').strftime('%d/%m/%Y %H:%M')})"
    report = ([header, '-' * header.length] + lines).join("\n")
    title = "System Check Report (#{Time.now.in_time_zone('Asia/Ho_Chi_Minh').strftime('%d/%m/%Y %H:%M')})"

    current_time = Time.now.in_time_zone('Asia/Ho_Chi_Minh')
    puts "✅ current_time: #{current_time} -> #{current_time.hour}:#{current_time.min}"
    # Gửi mail nếu có lỗi
    if report.include?("ERROR") || report.include?("FAIL")
      puts "[#{Time.now}] Có lỗi → bắt đầu gửi mail"
      send_email_via_api(
        SYSTEM_REPORT_EMAILS,
        title,
        report
      )
    elsif current_time.hour == 8 && current_time.min == 0
      puts "[#{current_time}] Không có lỗi nhưng đúng 8:00 → gửi báo cáo hàng ngày"
      send_email_via_api(
        SYSTEM_REPORT_EMAILS,
        title,
        report
      )
    elsif current_time.hour == 16 && current_time.min == 0
      puts "[#{current_time}] Không có lỗi nhưng đúng 16:00 → gửi báo cáo định kỳ"
      send_email_via_api(
        SYSTEM_REPORT_EMAILS,
        title,
        report
      )
    end
  end

  # @author: trong.lq
  # @date: 21/01/2025
  # Cải thiện: Thêm thông tin chi tiết về môi trường và lỗi
  # @author: trong.lq
  # @date: 21/01/2025
  # Format dòng hiển thị kết quả kiểm tra với thông tin chi tiết về môi trường và lỗi
  def self.format_line(name, url, status, env_name = nil, error_details = nil)
    env_display = env_name || name || '---'
    error_text = ""
    
    if status.include?("FAIL") || status.include?("ERROR")
      error_text = " - Trang truy cập đang bị lỗi"
      # Thêm thông tin chi tiết về lỗi nếu có
      if error_details.present?
        error_text += " | Chi tiết: #{error_details}"
      end
    end
    
    "[#{env_display}] #{url} → #{status}#{error_text}"
  end

  # Helper method để gửi email qua API
  def self.send_email_via_api(to_emails, subject, content, from_email = nil, cc_emails = nil, bcc_emails = nil)
    begin
      # Chuẩn bị data cho API
      email_data = {
        to: to_emails.is_a?(Array) ? to_emails : [to_emails],
        subject: subject,
        content: content
      }
      
      email_data[:from] = from_email if from_email
      email_data[:cc] = cc_emails if cc_emails && cc_emails.any?
      email_data[:bcc] = bcc_emails if bcc_emails && bcc_emails.any?
      
      # Gọi API gửi email
      api_url = "https://erp.bmtu.edu.vn/api/v1/mapi_utils/send_email"
      response = RestClient.post(api_url, email_data.to_json, {
        content_type: :json,
        accept: :json,
        timeout: TIMEOUT
      })
      
      result = JSON.parse(response.body)
      if result['success']
        puts "✅ Email sent successfully to #{result['data']['to_count']} recipients"
        return true
      else
        puts "❌ Email API error: #{result['error']}"
        return false
      end
      
    rescue => e
      puts "❌ Failed to send email via API: #{e.class} - #{e.message}"
      return false
    end
  end

  # Domain Expiry Functions
  def self.check_expiring_domains
    puts "=" * 50

    expiring_domains = []
    current_date = Date.today

    DOMAIN_EXPIRY_DATA.each do |domain, expiry_str|
      begin
        expiry_date = Date.parse(expiry_str)
        days_until_expiry = (expiry_date - current_date).to_i

        puts "📅 #{domain}: #{expiry_date} (#{days_until_expiry} days)"

        if days_until_expiry <= WARNING_DAYS && days_until_expiry >= 0
          expiring_domains << {
            domain: domain,
            expiry_date: expiry_date,
            days_remaining: days_until_expiry
          }
          puts "  ⚠️ WARNING: Expires in #{days_until_expiry} days!"
        elsif days_until_expiry < 0
          puts "  ❌ EXPIRED: #{days_until_expiry.abs} days ago!"
        else
          puts "  ✅ Safe: #{days_until_expiry} days remaining"
        end

      rescue Date::Error => e
        puts "  ❌ Invalid date format: #{expiry_str} - #{e.message}"
      end
    end

    puts "\n" + "=" * 50
    puts "📊 SUMMARY:"
    puts "=" * 50

    if expiring_domains.any?
      puts "⚠️ #{expiring_domains.size} domain(s) expiring soon:"
      expiring_domains.each do |domain_info|
        puts "  - #{domain_info[:domain]}: #{domain_info[:days_remaining]} days (#{domain_info[:expiry_date]})"
      end

      # Gửi email cảnh báo
      send_expiry_warning_email(expiring_domains)
    else
      puts "✅ No domains expiring in the next #{WARNING_DAYS} days"
    end

    return expiring_domains
  end

  def self.send_expiry_warning_email(expiring_domains)
    puts "\n📧 Sending expiry warning email..."

    begin
      # Tạo nội dung email đơn giản
      email_subject = "⚠️ Cảnh báo hết hạn domain"
      
      email_body = ""
      expiring_domains.each do |domain_info|
        domain = domain_info[:domain]
        expiry = domain_info[:expiry_date]
        days = domain_info[:days_remaining]
        
        email_body += "Tên miền #{domain} sẽ hết hạn vào #{expiry}"
        if days == 0
          email_body += " (HẾT HẠN HÔM NAY!)"
        else
          email_body += " (còn #{days} ngày)"
        end
        email_body += "\n"
      end

      # Gửi email qua API
      success = send_email_via_api(
        SYSTEM_REPORT_EMAILS,
        email_subject,
        email_body
      )

      if success
        puts "✅ Expiry warning email sent successfully via API"
      else
        puts "❌ Failed to send expiry warning email via API"
      end

    rescue => e
      puts "❌ Failed to send expiry warning email: #{e.class} - #{e.message}"
    end
  end

  def self.list_all_domains
    puts "📋 All Domain Expiry Information:"
    puts "=" * 50

    DOMAIN_EXPIRY_DATA.each do |domain, expiry_str|
      begin
        expiry_date = Date.parse(expiry_str)
        days_until_expiry = (expiry_date - Date.today).to_i
        
        status = if days_until_expiry < 0
          "❌ EXPIRED"
        elsif days_until_expiry <= WARNING_DAYS
          "⚠️ EXPIRING SOON"
        else
          "✅ SAFE"
        end
        
        puts "#{status} #{domain}: #{expiry_date} (#{days_until_expiry} days)"
        
      rescue Date::Error
        puts "❌ INVALID DATE #{domain}: #{expiry_str}"
      end
    end
  end

end

public
# Send notify to user to reminder attend
def send_attendance_reminder()
  # ===================== Helpers đo memory =====================
  memory = lambda do
    if File.readable?('/proc/self/status')
      line = File.readlines('/proc/self/status').find { |l| l.start_with?('VmRSS:') }
      line ? line.split[1].to_i : 0 # tính theo KB
    else
      `ps -o rss= -p #{Process.pid}`.to_i
    end
  end

  kb_to_mb = ->(kb) { (kb.to_f / 1024.0).round(2) }

  started_at    = Time.now
  memory_before = memory.call
  saction_name  = 'send_attendance_reminder'
  spath         = 'lib/mlib/lib_utils/send_attendance_reminder'
  result_note   = 'ok'

  begin
    Time.use_zone('Asia/Ho_Chi_Minh') do
      time_now     = Time.zone.now
      target  = time_now + 15.minutes
      day_rng = target.beginning_of_day..target.end_of_day
      hhmm    = target.strftime('%H:%M')

      # Base scope: cùng ngày mục tiêu (theo TZ), APPROVED, không nghỉ
      base = Shiftselection
               .joins(:scheduleweek)
               .where(scheduleweeks: { status: 'APPROVED' })
               .where(work_date: day_rng)
               .where(is_day_off: nil)

      return unless base.exists?

      # Match theo phút chính xác cho start/end, bỏ qua NULL/''.
      start_scope = base.where.not(start_time: [nil, '']).where(start_time: hhmm)
      end_scope   = base.where.not(end_time:   [nil, '']).where(end_time:   hhmm)

      create_batch = lambda do |scope, kind|
        # kind: :start hoặc :end
        # Lấy danh sách user duy nhất từ scheduleweeks.user_id
        user_ids = scope.joins(:scheduleweek).pluck('scheduleweeks.user_id').compact.uniq
        return if user_ids.empty?

        # Lấy tên ca (Workshift) để nhúng vào contents
        ws_ids = scope.pluck(:workshift_id).compact.uniq
        shift_names =
          begin
            Workshift.where(id: ws_ids).map { |w| w.try(:name) || w.try(:sname) || w.try(:scode) || "##{w.id}" }.uniq
          rescue NameError
            ws_ids.map { |i| "##{i}" } # fallback nếu chưa có model Workshift
          end

        base_content = (kind == :start) ?
                         "Sắp đến thời gian chấm công vào làm lúc #{hhmm}" :
                         "Sắp đến thời gian chấm công tan làm lúc #{hhmm}"
        contents = shift_names.present? ? "#{base_content} (#{shift_names.join(', ')})" : base_content

        # Idempotency: không tạo trùng trong ±5 phút cùng stype+title+contents
        win_from = time_now - 5.minutes
        win_to   = time_now + 5.minutes
        dup = Notify.where(
          stype: 'ATTENDANCE_REMINDER',
          title: 'Thông báo chấm công',
          contents: contents
        ).where(dtsent: win_from..win_to).exists?
        return if dup

        notify = Notify.create!(
          title:     'Thông báo chấm công',
          contents:  contents,
          stype:     'ATTENDANCE_REMINDER',
          status:    'NEW',
          priority:  'NORMAL',
          dtsent:    Time.zone.now,
          valid_from: nil,
          valid_to:   nil,
          receivers:  nil,
          senders:   'system'
        )

        # Tạo snotice: 1 user → 1 snotice (tối ưu, tránh trùng)
        usernames = User.where(id: user_ids).pluck(:id, :username).to_h
        user_ids.each do |uid|
          Snotice.create!(
            notify_id:  notify.id,
            user_id:    uid,
            username:   usernames[uid],
            isread:     false,
            dtreceived: Time.zone.now,
            dtread:     nil,
            status:     nil
          )
        end
      end

      # Tạo notify/snotice cho hai nhóm độc lập
      create_batch.call(start_scope, :start) if start_scope.exists?
      create_batch.call(end_scope,   :end) if end_scope.exists?
    end
  rescue => e
    result_note = "error: #{e.class}: #{e.message}"
    raise
  ensure
    ended_at     = Time.now
    duration_ms  = ((ended_at - started_at)).round(9)
    memory_after = memory.call
    memory_use = memory_after - memory_before

    note_payload = {
      duration:  duration_ms,
      memory_before: "#{kb_to_mb.call(memory_before)}Mb",
      memory_after:  "#{kb_to_mb.call(memory_after)}Mb",
      memory_use:  "#{kb_to_mb.call(memory_use)}Mb",
      result_note:  result_note
    }.to_json

    Mylog.create!(
      userid:        "cronjob",
      user_name:     "cronjob",
      user_email:    "cronjob",
      spath:         spath,
      saction_name:  saction_name,
      dtstart:       Time.current - duration_ms.fdiv(1000),
      dtend:         Time.current,
      note:          note_payload
    )
  end
end

# Send notify to user to reminder create schedule week
# Dat Le
def send_create_schedule_week_reminder()
  Time.use_zone('Asia/Ho_Chi_Minh') do
    user_ids = Scheduleweek.distinct.pluck(:user_id)
    return unless user_ids.present?

    Time.zone = 'Asia/Ho_Chi_Minh'

    current_week = Time.zone.now.strftime('%V').to_i
    iso_year = Time.zone.now.strftime('%G').to_i
    next_week = current_week + 1
    start_date = Date.commercial(iso_year, next_week, 1).in_time_zone('Asia/Ho_Chi_Minh').strftime("%d/%m/%Y")
    end_date   = Date.commercial(iso_year, next_week, 7).in_time_zone('Asia/Ho_Chi_Minh').strftime("%d/%m/%Y")

    contents = "Vui lòng tạo kế hoạch làm việc cho <strong>tuần #{next_week} (#{start_date} - #{end_date})</strong> để đảm bảo tiến độ và sắp xếp công việc hiệu quả.<br>"
    notify = Notify.create!(
      title:     'Thông báo tạo kế hoạch làm việc',
      contents:  contents,
      stype:     'CREATE_SCHEDULEWEEK_REMINDER',
      status:    'NEW',
      priority:  'NORMAL',
      dtsent:    Time.zone.now,
      valid_from: nil,
      valid_to:   nil,
      receivers:  nil,
      senders:   'Hệ thống ERP'
    )
    usernames = User.where(id: user_ids).pluck(:id, :username).to_h
    user_ids.each do |uid|
      Snotice.create!(
        notify_id:  notify.id,
        user_id:    uid,
        username:   usernames[uid],
        isread:     false,
        dtreceived: Time.zone.now,
        dtread:     nil,
        status:     nil
      )
    end
  end
end

# Send notify to leave request
def alert_holpros_approval_pending
  datas = []
  oHolpros = Holpro.where.not(status: ["TEMP", "DONE", "CANCEL-DONE"])

  oHolpros.each do |holpro|
    # Người tạo đơn (người gửi)
    holiday = Holiday.find_by(id: holpro.holiday_id)
    creator = User.find_by(id: holiday&.user_id)
    creator_name = [creator&.last_name, creator&.first_name].compact.join(" ")

    # Thông tin chi tiết đơn nghỉ phép
    details = Holprosdetail.where(holpros_id: holpro.id).map do |detail|
      {
        sholtype: get_name_holtype(detail.sholtype)&.name || "",
        details: format_leave_details(detail.details),
        place: detail&.issued_place == "IN-COUNTRY" ? "Trong nước" : "Nước ngoài",
        address: detail.place_before_hol,
        handover_receiver: format_handover_receivers(detail.handover_receiver),
        notes: detail.note
      }
    end

    # Người duyệt đơn
    mandoc = Mandoc.find_by(holpros_id: holpro.id)
    next unless mandoc

    mandocdhandle = Mandocdhandle.where(mandoc_id: mandoc.id).last
    next unless mandocdhandle

    mandocuhandles = Mandocuhandle.where(mandocdhandle_id: mandocdhandle.id, status: "CHUAXULY")
    if mandocuhandles.present?
      mandocuhandles.each do |uh|
        approver = User.find_by(id: uh.user_id)
        approver_name = [approver&.last_name, approver&.first_name].compact.join(" ")

        # Gom nhóm theo approver_id
        existing = datas.find { |d| d[:user_signed][:id] == approver&.id }

        if existing
          # Đã có user_signed → push thêm record mới
          existing[:records] << {
            holpro_id: holpro.id,
            total: holpro&.dttotal,
            status: find_status(holpro&.status)&.dig(:name) || "",
            date_uhandle: uh&.created_at&.strftime('%d/%m/%Y %H:%M'),
            user_sender: {
              id: creator&.id,
              sid: creator&.sid,
              name: creator_name,
              email: creator&.email,
              name_positionjob: get_work(creator&.id)&.name_positionjob || "",
              name_department: get_work(creator&.id)&.name_department || "",
              uorg_code: get_uorg_codes(creator&.id)
            },
            details: details
          }
        else
          # Chưa có → tạo mới nhóm
          datas << {
            user_signed: {
              id: approver&.id,
              name: approver_name,
              email: approver&.email,
              name_positionjob: get_work(approver&.id)&.name_positionjob || "",
              name_department: get_work(approver&.id)&.name_department || "",
              uorg_code: get_uorg_codes(approver&.id)
            },
            records: [
              {
                holpro_id: holpro.id,
                total: holpro&.dttotal,
                status: find_status(holpro&.status)&.dig(:name) || "",
                date_uhandle: uh&.created_at&.strftime('%d/%m/%Y %H:%M'),
                user_sender: {
                  id: creator&.id,
                  sid: creator&.sid,
                  name: creator_name,
                  email: creator&.email,
                  name_positionjob: get_work(creator&.id)&.name_positionjob || "",
                  name_department: get_work(creator&.id)&.name_department || "",
                  uorg_code: get_uorg_codes(creator&.id)
                },
                details: details
              }
            ]
          }
        end
      end
    end
  end


  if datas.length > 0
    HolidayMailer.alert_holpros_approval_pending(datas).deliver_now
  end

end

def find_status(value)
  case value.to_s
  when "DONE", "Đã duyệt", "đã duyệt", "ĐÃ DUYỆT"
    {scode: "DONE", name: "Đã duyệt", named: "đã duyệt", nameu: "ĐÃ DUYỆT"}
  when "PENDING", "Chờ duyệt", "chờ duyệt", "CHỜ DUYỆT"
    {scode: "PENDING", name: "Chờ duyệt", named: "chờ duyệt", nameu: "CHỜ DUYỆT"}
  when "TEMP", "Lưu nháp", "lưu nháp", "LƯU NHÁP"
    {scode: "TEMP", name: "Lưu nháp", named: "lưu nháp", nameu: "LƯU NHÁP"}
  when "PROCESSING", "Đang xử lý đơn", "đang xử lý đơn", "ĐANG XỬ LÝ ĐƠN"
    {scode: "PROCESSING", name: "Đang xử lý đơn", named: "đang xử lý đơn", nameu: "ĐANG XỬ LÝ ĐƠN"}
  when "CANCEL", "Đơn bị hủy", "đơn bị hủy", "ĐƠN BỊ HỦY"
    {scode: "CANCEL", name: "Đơn bị hủy", named: "đơn bị hủy", nameu: "ĐƠN BỊ HỦY"}
  when "CANCEL-DONE", "Đã duyệt(điều chỉnh)", "đã duyệt(điều chỉnh)", "ĐÃ DUYỆT (ĐIỀU CHỈNH)"
    {scode: "CANCEL-DONE", name: "Đã duyệt(điều chỉnh)", named: "đã duyệt(điều chỉnh)", nameu: "ĐÃ DUYỆT (ĐIỀU CHỈNH)"}
  when "REFUSE", "Đơn từ chối", "đơn từ chối", "ĐƠN TỪ CHỐI"
    {scode: "REFUSE", name: "Đơn từ chối", named: "đơn từ chối", nameu: "ĐƠN TỪ CHỐI"}
  else
    nil
  end
end

def get_uorg_codes(user_id)
  return [] if user_id.blank?

  Organization.where(
    id: Uorg.where(user_id: user_id).select(:organization_id)
  ).pluck(:scode).compact
end

def get_name_holtype(scode)
  return nil unless Holtype.where(code: scode).first # Trả về nil không tồn tại
  name_holtype = Holtype.where(code: scode).select(:name).first
end

def format_handover_receivers(raw)
  return "" if raw.blank?

  # Tách từng người
  people = raw.split("|||").map do |entry|
    parts = entry.split("$$$")
    parts[1].to_s.strip # Lấy tên
  end.compact

  return "" if people.empty?

  # Thêm dấu phẩy cho người đầu tiên nếu nhiều hơn 1 người
  if people.length > 1
    people[0..-2].map { |p| "#{p}," }.push(people.last).join("\n")
  else
    people.first.to_s
  end
end

def format_leave_details(details)
  session_mapping = {
    "ALL" => "Cả ngày",
    "AM"  => "Buổi sáng",
    "PM"  => "Buổi chiều"
  }

  items = details.to_s.split('$$$').map do |item|
    date_part, session = item.split('-')
    next unless date_part

    label = session_mapping[session&.upcase.to_s.strip] || 'Không xác định'
    "#{date_part.strip} (#{label})"
  end.compact

  items.join("\n") # xuống dòng giữa các dòng
end

def get_work(user_id)
  return nil unless User.where(id: user_id).first # Trả về nil không tồn tại
  record = User.with_basic_work
               .active_cohuu
               .select(
                 'positionjobs.name AS name_positionjob',
                 'departments.name AS name_department',
                 ).where("users.id = ?", user_id).first
end
# H.anh
# Hàm chạy kiểm tra thâm niên
def seniority_update(managing_org_code)
  organization = Organization.find_by(scode: managing_org_code)
  return unless organization

  active_user_ids = User.joins(:uorgs)
                        .where(uorgs: { organization_id: organization.id })
                        .where(status: "ACTIVE")
                        .distinct
                        .pluck(:id)
  return if active_user_ids.empty?

  today = Date.current

  milestone_contracts = Contract
    .where(user_id: active_user_ids)
    .where("dtfrom <= ?", today.end_of_day)
    .joins("INNER JOIN contracttypes c ON c.name = contracts.name")
    .where("c.is_seniority = ?", "YES")

  return if milestone_contracts.empty?

  contracts_by_user = milestone_contracts.group_by(&:user_id)

  contracts_by_user.each do |user_id, contracts|
    contract = contracts.min_by(&:dtfrom)
    dt = contract.dtfrom.to_date

    years = ((today - dt).to_i / 365).floor
    x = milestone_x(years)
    next unless x

    hol = Holiday.find_by(user_id: user_id, year: today.year)
    next unless hol

    hdetail = Holdetail.find_by(holiday_id: hol.id, stype: "THAM-NIEN")
    next unless hdetail

    current_amount = hdetail.amount.to_i
    next if current_amount >= x

    y = x - current_amount

    hdetail.update!(amount: x)
    hol.update!(total: hol.total.to_i + y)
  end
end
# h.anh
# hàm cảnh báo đơn chưa duyệt
def holiday_user(managing_org_code)
  tomorrow = Date.current + 1.day
  tomorrow_str = tomorrow.strftime("%d/%m/%Y")

  organization = Organization.find_by(scode: managing_org_code)
  return if organization.nil?

  user_ids_tomorrow = Holprosdetail
    .joins(holpro: :holiday)
    .where("holprosdetails.details LIKE ?", "%#{tomorrow_str}%")
    .pluck("holidays.user_id")
    .uniq

  buh_user_ids = User
    .joins(:uorgs)
    .where(id: user_ids_tomorrow)
    .where(uorgs: { organization_id: organization.id })
    .pluck(:id)

  holpros_ids = Holprosdetail
    .joins(holpro: :holiday)
    .where("holprosdetails.details LIKE ?", "%#{tomorrow_str}%")
    .where(holidays: { user_id: buh_user_ids })
    .pluck(:holpros_id)
    .uniq

  list_mandoc = Mandoc.where(holpros_id: holpros_ids)
  list_dhandle = Mandocdhandle.where(mandoc_id: list_mandoc).pluck(:id).uniq

  records = Mandocuhandle
    .joins(mandocdhandle: { mandoc: { holpro: :holiday } })
    .where(
      mandocdhandle_id: list_dhandle,
      status: "CHUAXULY",
      srole: "MAIN"
    )
    .select(
      "mandocuhandles.user_id AS approver_id,
       holidays.user_id AS holiday_user_id"
    )

  grouped = records.group_by(&:approver_id)

  grouped.each do |approver_id, recs|
    holiday_user_ids = recs.map(&:holiday_user_id).uniq

    details = Holprosdetail
      .joins(holpro: :holiday)
      .where(holidays: { user_id: holiday_user_ids })
      .where("holprosdetails.details LIKE ?", "%#{tomorrow_str}%")

    message_lines = details.map do |d|
      user = d.holpro.holiday.user

      "Nhân sự: <b>#{user.first_name} #{user.last_name}</b> " \
      "- Mã nhân sự: <b>#{user.sid}</b><br>" \
      "Loại nghỉ: #{holtype_label(d.sholtype)}<br>" \
      "Thời gian nghỉ: #{parse_leave_details(d.details)}<br>"
    end

    contents = message_lines.join

    # ============================
    # TẠO NOTIFY
    # ============================
    notify = create_notify(
      "Cảnh báo đơn xin nghỉ chưa được duyệt",
      contents
    )

    # ============================
    # TẠO SNOTICE
    # ============================
    receiver_ids = [approver_id] + holiday_user_ids
    create_snotices(notify.id, receiver_ids)

    # ============================
    # GỬI MAIL (như hiện tại)
    # ============================
    approver_email = User.find_by(id: approver_id).try(:email)
    if approver_email.present?
      HolidayMailer.notifi_holpro(
        approver_email,
        contents
      ).deliver_now
    end

    holiday_user_ids.each do |uid|
      user_email = User.find_by(id: uid).try(:email)
      next if user_email.blank?

      HolidayMailer.notifi_holpro(
        user_email,
        "Đơn xin nghỉ của bạn chưa được duyệt"
      ).deliver_now
    end
  end

end
def create_notify(title, contents)
  Notify.create!(
    title: title,
    contents: contents,
    stype: "LEAVE_REQUEST",
    receivers: "Hệ thống ERP",
    dtsent: Time.current
  )
end
def create_snotices(notify_id, user_ids)
  user_ids.uniq.each do |uid|
    Snotice.create!(
      notify_id: notify_id,
      user_id: uid,
      isread: false,
      status: "FINISH",
      dtreceived: Time.current
    )
  end
end
def parse_leave_details(details)
  return "" if details.nil? || details.strip == ""

  raw_dates = details.split("$$$").map do |d|
    d.split("-").first
  end

  dates = raw_dates.map do |d|
    Date.strptime(d, "%d/%m/%Y")
  end.sort

  ranges = []
  start_date = dates.first
  prev_date  = dates.first

  dates[1..-1].to_a.each do |current|
    if current == prev_date + 1
      prev_date = current
    else
      ranges << [start_date, prev_date]
      start_date = current
      prev_date  = current
    end
  end

  ranges << [start_date, prev_date]

  ranges.map do |from, to|
    if from == to
      from.strftime("%d/%m/%Y")
    else
      "#{from.strftime("%d/%m/%Y")} – #{to.strftime("%d/%m/%Y")}"
    end
  end.join(", ")
end

def holtype_label(sholtype)
  label_map = {
    "NGHI-PHEP" => "Nghỉ phép",
    "NGHI-KHONG-LUONG" => "Nghỉ không lương",
    "NGHI-CHE-DO-BAO-HIEM-XA-HOI" => "Nghỉ BHXH",
    "NGHI-CDHH" => "Nghỉ chế độ (Hiếu/Hỷ)"
  }

  label_map[sholtype] || sholtype.to_s.tr("-", " ").capitalize
end

# hàm tạo phép năm mới
def nam_hien_tai
  Date.current.year
end

def nam_cu
  nam_hien_tai - 1
end


# ==============================
# ENTRY POINT
# ==============================
def run_buil_holiday(managing_org_code)
  bat_dau = Time.current
  logs = []

  managing_organization = Organization.find_by(scode: managing_org_code)
  raise "Managing Organization not found" unless managing_organization

  users = User.joins(:uorgs)
              .where(uorgs: { organization_id: managing_organization.id })
              .where(status: "ACTIVE")
              .distinct

  users.find_each do |user|
    holiday_2025 = Holiday.find_by(user_id: user.id, year: nam_cu)
    next unless holiday_2025
    next if Holiday.exists?(user_id: user.id, year: nam_hien_tai)

    department = fetch_leaf_departments_by_user(user.id)&.first
    next unless department

    ket_qua = tinh_toan(user, department.id, managing_org_code)
    next unless ket_qua

    create_holiday(user.id, ket_qua[:holdetails])

    logs << {
      user_id: user.id
    }
  end
  tong_time = Time.current - bat_dau
  puts "The total processing time of the run_buil_holiday function is: #{tong_time.round(2)}s"
  {
    bat_dau: bat_dau,
    ket_thuc: Time.current,
    tong_user: logs.size,
    tong_time: tong_time
  }
end
# ==============================
# CORE LOGIC
# ==============================
def tinh_toan(user, department_id, managing_org_code)
  holiday_2025 = Holiday.find_by(user_id: user.id, year: nam_cu)
  return nil unless holiday_2025

  # ============================
  # PHÉP NĂM 2025 (KHÔNG TÍNH TON)
  # ============================
  so_phep_nam_2025 =
    Holdetail.where(holiday_id: holiday_2025.id)
            .where.not(stype: "TON")
            .sum(:amount)
            .to_f

  phep_da_dung = phep_da_dung_thuc_te(holiday_2025)
  chenhlech = so_phep_nam_2025 - phep_da_dung

  # ============================
  # PHÉP ĐĂNG KÝ SỚM 2026
  # ============================
  phep_som = phep_som_2026_tu_nam_cu(holiday_2025)

  # ============================
  # PHÉP ÂM 2025
  # ============================
  phep_am = chenhlech < 0 ? chenhlech.abs : 0

  # ============================
  # PHÉP GỐC
  # ============================
  phep_ton_goc = chenhlech > 0 ? chenhlech : 0
  if managing_org_code == "BUH"
    phep_vi_tri_goc =
      Positionjob.where(
        id: Work.where(user_id: user.id)
                .where.not(positionjob_id: nil)
                .pluck(:positionjob_id),
        department_id: department_id
      ).first&.holno.to_f || 0
  else
    phep_vi_tri_goc = 12
  end

  # ============================
  # TÍNH USED CHUẨN
  # ============================
  used_ton = [phep_som, phep_ton_goc].min
  vuot_ton = [phep_som - phep_ton_goc, 0].max

  used_vi_tri = phep_am + vuot_ton
  phep_tham_nien_goc = tinh_tham_nien_user(user.id, managing_org_code)
  # ============================
  # BUILD HOLDDETAIL
  # ============================
  {
    holdetails: [
      {
        name: "Phép tồn",
        stype: "TON",
        amount: phep_ton_goc,
        used: used_ton,
        dtdeadline: Date.new(nam_hien_tai, 3, 31)
      },
      {
        name: "Phép thâm niên",
        stype: "THAM-NIEN",
        amount: phep_tham_nien_goc,
      },
      {
        name: "Phép theo vị trí",
        stype: "VI-TRI",
        amount: phep_vi_tri_goc,
        used: used_vi_tri,
      }
    ]
  }
end
def tinh_tham_nien_user(user_id, managing_org_code)
  milestones = [5, 10, 15, 20, 25, 30]
  today = Date.current
  organization = Organization.find_by(scode: managing_org_code)
  return 0 unless organization

  return 0 unless User.joins(:uorgs)
                      .where(id: user_id, status: "ACTIVE")
                      .where(uorgs: { organization_id: organization.id })
                      .exists?
  contract = Contract.joins("INNER JOIN contracttypes c ON c.name = contracts.name")
                     .where(user_id: user_id)
                     .where("c.is_seniority = ?", "YES")
                     .order(:dtfrom)
                     .first
  return 0 unless contract&.dtfrom
  years = ((today - contract.dtfrom.to_date).to_i / 365.25).floor
  milestone_x(years)
end
def milestone_x(years)
  milestones = [5, 10, 15, 20, 25, 30]
  return 0 if years < 5

  milestones.each_with_index do |m, i|
    next_m = milestones[i + 1]
    return i + 1 if next_m.nil? && years >= m
    return i + 1 if years >= m && years < next_m
  end
  0
end
# ==============================
# HELPERS
# ==============================
def tach_ngay_nghi(details)
  details.to_s.split("$$$").map do |item|
    d, buoi = item.split("-").map(&:strip)
    date = Date.strptime(d, "%d/%m/%Y")
    so_ngay = buoi.nil? || buoi.upcase == "ALL" ? 1.0 : 0.5
    [date, so_ngay]
  rescue
    nil
  end.compact
end
def phep_chua_duyet(holiday)
  holpro_ids = Holpro.where(holiday_id: holiday.id)
                      .where.not(status: %w[DONE CANCEL-DONE REFUSE CANCEL TEMP])
                      .pluck(:id)
  Holprosdetail.where(
    holpros_id: holpro_ids,
    sholtype: %w[NGHI-PHEP NGHI-CHE-DO]
  ).flat_map { |d| tach_ngay_nghi(d.details) }
    .sum { |_, w| w }
end

def phep_da_dung_thuc_te(holiday)
  tong_used = Holdetail.where(holiday_id: holiday.id)
                        .where.not(stype: "TON")
                        .sum(:used)
                        .to_f

  ket_qua = tong_used - phep_chua_duyet(holiday)
  ket_qua.negative? ? 0 : ket_qua
end

def phep_som_2026_tu_nam_cu(holiday_2025)
  holpro_ids = Holpro.where(
    holiday_id: holiday_2025.id,
    status: %w[DONE CANCEL-DONE]
  ).pluck(:id)

  Holprosdetail.where(
    holpros_id: holpro_ids,
    sholtype: %w[NGHI-PHEP NGHI-CHE-DO]
  ).flat_map { |d| tach_ngay_nghi(d.details) }
    .select { |date, _| date.year == nam_hien_tai }
    .sum { |_, w| w }
end
def fetch_leaf_departments_by_user(user_id)
  positionjob_ids = Work.where(user_id: user_id)
                        .where.not(positionjob_id: nil)
                        .pluck(:positionjob_id)

  department_ids = Positionjob.where(id: positionjob_ids).pluck(:department_id)
  departments = Department.where(id: department_ids, status: "0")
                            .where.not(parents: [nil, ""])

  if departments.present?
    parent_ids = departments.map(&:parents).compact.map(&:to_i)
    departments.reject { |d| parent_ids.include?(d.id) }
  else
    Department.where(id: department_ids, status: "0").limit(1)
  end
end
# ==============================
# CREATE DB
# ==============================
def create_holiday(user_id, holdetails)
  return if Holiday.exists?(user_id: user_id, year: nam_hien_tai)

  Holiday.transaction do
    # ============================
    # CREATE HOLIDAY (used = 0 tạm)
    # ============================
    holiday = Holiday.create!(
      user_id: user_id,
      year: nam_hien_tai,
      total: holdetails.sum { |h| h[:amount] },
      used: 0
    )

    total_used = 0.0

    # ============================
    # CREATE HOLDDETAIL
    # ============================
    holdetails.each do |h|
      used_value = h[:used].to_f
      total_used += used_value

      Holdetail.create!(
        holiday_id: holiday.id,
        name: h[:name],
        stype: h[:stype],
        amount: h[:amount],
        used: used_value,
        dtdeadline: h[:dtdeadline]
      )
    end

    # ============================
    # UPDATE HOLIDAY.USED
    # ============================
    holiday.update!(used: total_used)
  end
end

# end phép

# Author: H.Vũ (19/01/2025)
# @desc: Clean bảng Mylog định kỳ 3 ngày 1 lần.
def clean_system_log
  Mylog.delete_all
end