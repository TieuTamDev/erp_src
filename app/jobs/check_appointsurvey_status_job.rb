class CheckAppointsurveyStatusJob < ApplicationJob
    queue_as :default
    include AppointmentsHelper
  
    def perform
        # Lấy tất cả các Appointment có trạng thái evaluation
        appointments = Appointment.where(status: "evaluation")
        
        appointments.each do |oAppointment|
            appointsurvey = Appointsurvey.find_by(appointment_id: oAppointment.id)
            next unless appointsurvey

            # Chuyển trust_collection_period thành Date và so sánh với ngày hiện tại
            trust_collection_date = oAppointment.trust_collection_period.in_time_zone('Asia/Ho_Chi_Minh').to_date
            next unless Date.today >= trust_collection_date
            
            update_status(oAppointment.id)
            send_procecss_notify(oAppointment.id)

            # Nếu trạng thái vẫn là ASSIGN, cập nhật thành EXPIRED
            if appointsurvey.status == "ASSIGN"
                appointsurvey.update!(
                    status: "EXPIRED",
                    note: "Hệ thống tự động cập nhật trạng thái thành EXPIRED vào #{Time.zone.now.in_time_zone('Asia/Ho_Chi_Minh').strftime('%H:%M %d/%m/%Y')} do đã hết hạn"
                )
                
                Rails.logger.info("Updated Appointsurvey #{oAppointment.id} to EXPIRED on #{Date.today}")
            else
                Rails.logger.info("Appointsurvey #{oAppointment.id} status is #{appointsurvey.status}, no update needed")
            end          
        end
    end
end