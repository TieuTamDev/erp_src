class Snotice < ApplicationRecord
  include RemoteNotificationHelper
  include SendNotiAndroidHelper
  belongs_to :notify
  belongs_to :user

  belongs_to :appointsurvey,
  ->(snotice) { where(id: snotice.username) },
  class_name: 'Appointsurvey',
  foreign_key: :username,
  primary_key: :id

  after_create :enqueue_notification_job

  def enqueue_notification_job
    if Rails.env.development?
      SendNotificationJob.perform_now(self.id)
    else
      SendNotificationJob.perform_later(self.id)
    end
  end


  private
  scope :count_filtered_snotices, ->(search, user_id, type, is_handle) {
    query = joins(:notify).where(user_id: user_id)
    query = query.where(notifies: {stype: type == 'NOTIFICATION' ? [nil, "MANDOC"] : type}) if type.present?
    query = query.where("snotices.status != ? OR snotices.status IS NULL", "FINISH").where("(snotices.isread IS NULL OR snotices.isread = ?)", false).where(notifies: {stype: ["BO_NHIEM", "MIEN_NHIEM", "SURVEY"]}) if is_handle.present?
    query = query.where("notifies.title LIKE :search OR notifies.contents LIKE :search OR notifies.senders LIKE :search", search: "%#{search}%") if search.present?
    query.uniq.count
  }

  def self.filtered_snotices(search, user_id, page, per_page, stype, type, is_handle)
    query = joins(:notify).where(user_id: user_id)
    query = query.where(notifies: {stype: type == 'NOTIFICATION' ? [nil, "MANDOC"] : type}) if type.present?
    query = query.where("snotices.status != ? OR snotices.status IS NULL", "FINISH").where("(snotices.isread IS NULL OR snotices.isread = ?)", false).where(notifies: {stype: ["BO_NHIEM", "MIEN_NHIEM", "SURVEY"]}) if is_handle.present?
    query = query.where("notifies.title LIKE :search OR notifies.contents LIKE :search OR notifies.senders LIKE :search", search: "%#{search}%") if search.present?
    query = query.uniq.order(id: :DESC).offset((page - 1) * per_page).limit(per_page)

    query.map do |snotice|
      deadline_color = ""
      deadline_str = ""
      if snotice.notify&.stype == "SURVEY"
        deadline_date = snotice.appointsurvey&.dtdeadline
        deadline_str = deadline_date&.strftime("%d/%m/%Y") || ""
        if deadline_date.present?
          days_left = (deadline_date.to_date - Date.today).to_i
          deadline_color = days_left <= 2 ? "text-danger" : ""
        end
      end
      {
        id: snotice.id,
        title: snotice.notify&.title.to_s,
        stype: I18n.t(stype[snotice.notify.stype], default: "").capitalize,
        contents: snotice.notify&.contents.to_s,
        time_ago: time_ago_in_words(snotice.created_at.in_time_zone('Asia/Ho_Chi_Minh')),
        isread: snotice.isread ? "Đã đọc" : "Chưa đọc",
        dtdeadline: snotice.notify&.stype == "SURVEY" ? deadline_str : "",
        deadline_color: deadline_color,
        isread_color: snotice.isread ? "text-success" : "text-danger",
      }
    end
  end

  private
  def self.time_ago_in_words(time)
    seconds_ago = (Time.current.in_time_zone('Asia/Ho_Chi_Minh') - time).to_i
    case seconds_ago
    when 0..59
      "#{seconds_ago} giây trước"
    when 60..3599
      minutes = (seconds_ago / 60).to_i
      "#{minutes} phút trước"
    when 3600..86_399
      hours = (seconds_ago / 3600).to_i
      "#{hours} tiếng trước"
    else
      days = (seconds_ago / 86_400).to_i
      "#{days} ngày trước"
    end
  end

end
