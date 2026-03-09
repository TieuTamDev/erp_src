module AppointmentStatusController
    extend ActiveSupport::Concern
    include StreamConcern
    included do
        before_action :set_appointment, only: [:approve, :reject, :set_probation, :next_step, :previous_step, :go_to_step]
    end
  
    def approve
        update_status(@appointment.approve!, 'Đã phê duyệt thành công.', 'Không thể phê duyệt.')
    end
  
    def reject
        update_status(@appointment.reject!, 'Đã từ chối thành công.', 'Không thể từ chối.')
    end
  
    def set_probation
        months = params[:months].to_i
        update_status(@appointment.set_probation_period!(months), "Đã thiết lập thời gian thử thách #{months} tháng.", 'Không thể thiết lập thời gian thử thách.')
    end
  
    def next_step
        update_status(@appointment.next_step!, 'Đã chuyển sang bước tiếp theo.', 'Không thể chuyển sang bước tiếp theo.')
    end
  
    def previous_step
        update_status(@appointment.previous_step!, 'Đã quay lại bước trước.', 'Không thể quay lại bước trước.')
    end
  
    def go_to_step
        step_number = params[:step_number].to_i
        update_status(@appointment.go_to_step!(step_number), "Đã chuyển đến bước #{step_number}.", "Không thể chuyển đến bước #{step_number}.")
    end
  
    private
  
    def set_appointment
        @appointment = Appointment.find(params[:id])
    end
  
    def update_status(success, success_message, error_message)
        if success
            respond_to do |format|
                format.html { redirect_to @appointment, notice: success_message }
                format.json { render json: { status: 'success', message: success_message, appointment: @appointment } }
            end
        else
            respond_to do |format|
                format.html { redirect_to @appointment, alert: error_message }
                format.json { render json: { status: 'error', message: error_message }, status: :unprocessable_entity }
            end
        end
    end
end  