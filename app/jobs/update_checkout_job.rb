class UpdateCheckoutJob < ApplicationJob
  queue_as :default

  def perform(attend_id, checkout_timestamp, user, mmodule)
    attend = Attend.find_by(id: attend_id)
    return if attend.nil? || attend.checkout.present? 
    checkout_time = Time.zone.at(checkout_timestamp).in_time_zone("Asia/Ho_Chi_Minh")
    total_time = (checkout_time - attend.checkin) / 3600.0 
    current_time = Time.zone.now.in_time_zone('Asia/Ho_Chi_Minh').strftime('%H:%M %d/%m/%Y')
    attend.update!(
      checkout: checkout_time,
      total_time: total_time.round(2), # Tính phút
      status: "FINISH",
      note: "#{attend.note}, Hệ thống tự kết thúc điểm danh lúc #{current_time} do không có hành động kết thúc từ giảng viên"
    )

    AttendMailer.not_checkout_mailer(user, mmodule, current_time).deliver_later
  end
end


