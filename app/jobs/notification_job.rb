class NotificationJob < ApplicationJob
  include RemoteNotificationHelper
  def perform(token_device, title, messages, badge)
    send_notification_ios(token_device, title, messages, badge)
  rescue => e
    Rails.logger.error "NotificationJob Error: #{e.message}"
  end
end
