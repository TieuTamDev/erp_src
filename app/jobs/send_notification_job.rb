class SendNotificationJob < ApplicationJob
    queue_as :default

    def perform(snotice_id)
      snotice = Snotice.find_by(id: snotice_id)
      return unless snotice

      o_notify = snotice.notify
      return unless o_notify

      text_content = ActionView::Base.full_sanitizer.sanitize(o_notify.contents)
      text_content.gsub(/\s+/, ' ').strip

      count_notice = Snotice.where("snotices.user_id = ? AND snotices.isread != true", snotice.user_id).count || 0
      Mdevice.where(userid: snotice.user_id).where.not(status: "INACTIVE").each do |device|
        snotice.send_notification_ios_async(device.stoken, o_notify.title, text_content, count_notice)
        snotice.send_notification_android(device.stoken, o_notify.title, text_content)
      end
    end

end
