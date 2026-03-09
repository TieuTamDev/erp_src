module RemoteNotificationHelper
  require 'apnotic'

  # Gửi thông báo không đồng bộ bằng ActiveJob
  def send_notification_ios_async(token_device, title, messages, badge)
    return { result: false, message: "Token device is missing" } if token_device.blank?
    return { result: false, message: "Title is missing" } if title.blank?
    return { result: false, message: "Message is missing" } if messages.blank?

    NotificationJob.perform_later(token_device, title, messages, badge)
    { result: true, message: "Notification job enqueued successfully" }
  end

  # Gửi thông báo đồng bộ (trường hợp cần thiết)
  def send_notification_ios(token_device, title, messages, badge)
    return { result: false, message: "Token device is missing" } if token_device.blank?
    return { result: false, message: "Title is missing" } if title.blank?
    return { result: false, message: "Message is missing" } if messages.blank?

    cert_path = Rails.root.join('public', 'assets', 'certificate_ios', 'Certificates.pem')
    url = Rails.env.production? ? 'https://api.push.apple.com' : 'https://api.sandbox.push.apple.com'
    ca_file = Rails.root.join('public', 'assets', 'certificate_ios', 'ca-certificates.crt')

    connection = Apnotic::Connection.new(cert_path: cert_path, url: url, ca_file: ca_file)
    begin
      notification = build_notification(token_device, title, messages, badge)
      response = connection.push(notification)

      handle_response(response, token_device)
    rescue => e
      { result: false, message: "Error: #{e.message}" }
    ensure
      connection.close
    end
  end

  private

  # Cấu hình thông báo cho APN
  def build_notification(token_device, title, messages, badge)
    notification = Apnotic::Notification.new(token_device)
    notification.alert = { title: title, body: messages }
    notification.sound = "bingbong.aiff"
    notification.topic = "bmtu.berp"
    notification.priority = 10 # Gấp
    notification.badge = badge.to_i
    notification.push_type = "alert"
    notification
  end

  # Xử lý phản hồi từ APN
  def handle_response(response, token_device)
    if response.ok?
      { result: true, message: "Notification sent successfully" }
    elsif response.body
      process_error_response(response.body, token_device)
    else
      { result: false, message: "Failed to send notification: Unknown error" }
    end
  end

  # Phân tích và xử lý lỗi từ phản hồi APN
  def process_error_response(body, token_device)
    error_data = JSON.parse(body.to_s) rescue {}
    reason = error_data["reason"]

    case reason
    when "BadDeviceToken", "Unregistered"
      deactivate_device(token_device)
      { result: false, message: "Failed: #{reason} - Token is invalid or no longer valid" }
    else
      { result: false, message: "Failed to send notification: #{reason || 'Unknown reason'}" }
    end
  end

  # Hủy kích hoạt thiết bị nếu mã thông báo không hợp lệ
  def deactivate_device(token_device)
    device = Mdevice.find_by(stoken: token_device)
    device&.update(status: "INACTIVE")
  end
end
