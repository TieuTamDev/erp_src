require 'googleauth'
require 'httparty'
require 'json'

class FcmService
  FCM_URL = 'https://fcm.googleapis.com/v1/projects/bmtu-a36f0/messages:send'

  def self.send_notification(tokens:, title:, body:)
    # Path to your service account JSON file
    credentials_path = Rails.root.join('config', 'google_key.json')
    # Initialize the credentials from the service account file using make_creds
    scope = 'https://www.googleapis.com/auth/firebase.messaging'
    credentials = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open(credentials_path),
      scope: scope,
    )
    # Fetch the OAuth 2.0 access token
    access_token = credentials.fetch_access_token!['access_token']
    Rails.logger.info("access_token: #{access_token}")

    # Set up headers including the OAuth token
    headers = {
      'Authorization' => "Bearer #{access_token}",
      'Content-Type' => 'application/json'
    }

    Rails.logger.info("tokens: #{tokens}")
    log = []
    response = nil

    tokens.each do |token|
      # Create the notification body, ensuring body is a stringified JSON for data payload
      message = {
        message: {
          token: token,
          notification: {
            title: title,
            body: body
          },
          data: {
            body: {
              message: {
                notification: {
                  body: body
                }
              }
            }.to_json # Stringify the JSON for the 'body' field in data
          }
        }
      }.to_json

      # Send the notification request
      response = HTTParty.post(FCM_URL, headers: headers, body: message)
      log.push(response.body)    
    end  

    Rails.logger.info("FCM Response: #{log}")
    response
  end
end

