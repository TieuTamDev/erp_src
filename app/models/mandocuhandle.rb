class Mandocuhandle < ApplicationRecord
  belongs_to :mandocdhandle
  has_one :mandoc, through: :mandocdhandle
  belongs_to :user

  after_create :send_notification
  # after_create :send_notification, unless: :skip_notification?

  private

  def send_notification
    SendMandocuhandleNotificationJob.perform_now(self.id)
  end

  def skip_notification?
    status == 'created'
  end

  def self.fetch_user_handles(holpros_id)
    Mandocuhandle.joins(:user, mandoc: :holpro)
      .where(holpros: {id: holpros_id}, mandocdhandles: {status: ["TEMP"]})
      .order(id: :DESC)
      .pluck("CONCAT(users.last_name, ' ', users.first_name)")
      .uniq.map {|name| "#{name}" }.join(', ')
  end
end
