module SendNotiAndroidHelper
  require 'fcm'
  require 'googleauth'
  require 'httparty'
  require 'json'

  def send_notification_android(tokens, title, body)
  icon_name = 'notification_icon'
  fcm_url = 'https://fcm.googleapis.com/v1/projects/bmtu-a36f0/messages:send'

  credentials_path = Rails.root.join('config', 'google_key.json')
  scope = 'https://www.googleapis.com/auth/firebase.messaging'
  credentials = Google::Auth::ServiceAccountCredentials.make_creds(
    json_key_io: File.open(credentials_path),
    scope: scope
  )
  access_token = credentials.fetch_access_token!['access_token']
  headers = {
    'Authorization' => "Bearer #{access_token}",
    'Content-Type' => 'application/json'
  }

  # 1️⃣ Thông báo hiển thị (giữ nguyên logic cũ)
  message = {
    message: {
      token: tokens,
      notification: {
        title: title,
        body: body
      },
      android: {
        priority: 'high',
        notification: {
          channel_id: 'fcm_channel',
          icon: icon_name
        }
      },
      data: {
        body: body,
        icon: icon_name
      }
    }
  }

  Rails.logger.info "FCM Payload: #{message.to_json}"
  response = HTTParty.post(fcm_url, headers: headers, body: message.to_json)
  Rails.logger.info "FCM Response: #{response.body}"

  # 2️⃣ Gửi thêm FCM data-only nếu là "kế hoạch tuần được duyệt"
  if title.include?("Thông báo duyệt kế hoạch tuần") && body.include?("được duyệt")
    data_message = {
      message: {
        token: tokens,
        android: {
          priority: 'high'
        },
        data: {
          type: "WEEK_APPROVED",
          title: title,
          body: body
        }
      }
    }

    Rails.logger.info "FCM Data-only Payload: #{data_message.to_json}"
    data_response = HTTParty.post(fcm_url, headers: headers, body: data_message.to_json)
    Rails.logger.info "FCM Data-only Response: #{data_response.body}"
  end

  response
end

end