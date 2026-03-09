class Notify < ApplicationRecord
  include RemoteNotificationHelper 
  include SendNotiAndroidHelper 
  has_many :snotices, dependent: :destroy
  after_update :send_notifications_update, if: :data_changed?

  def send_notifications_update 
    sent_user_ids = []
    oSnotices = self.snotices
    oSnotices.each do |snotice|
      next if sent_user_ids.include?(snotice.user_id) # Bỏ qua nếu thông báo đã được gửi cho người dùng này
      count_notice = Snotice.where("snotices.user_id = ? AND snotices.isread != true", snotice.user_id).count || 0
      Mdevice.where(userid: snotice.user_id).where.not(status: "INACTIVE").each do |device|
        send_notification_ios_async(device.stoken, "(Gửi lại) #{self.title}", clean_html_content(self.contents), count_notice)
        send_notification_android(device.stoken ,self.title ,clean_html_content(self.contents))
      end
      sent_user_ids << snotice.user_id
    end
  end

  def clean_html_content(html_content)
    text_content = ActionView::Base.full_sanitizer.sanitize(html_content)
    text_content.gsub(/\s+/, ' ').strip
  end

  private
  # Kiểm tra xem title hoặc contents có bị thay đổi không
  def data_changed?
    changes.key?('title') || changes.key?('contents')
  end
end
