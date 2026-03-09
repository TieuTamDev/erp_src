class ProposalCreationsController < ApplicationController
  include AppointmentsHelper
  include SigndocConcern
  before_action :set_appointment, only: [:index, :new, :create, :edit, :update, :proposal_submit, :department_approval_submit]

  def index
  end

  def new
      user_id = @appointment.user_id
      @next_department_id = params[:next_department_id]
      @user = User.find(user_id)
      @uorgs = Uorg.where(user_id: user_id)
      @mailUser =  @user.email

      @department = @appointment.department
      @position = @appointment.positionjob
      @mandoc = Mandoc.find_by(appointment_id: @appointment.id, status: 'proposal_creation')
      @form_data = {
        stream_datas: [],
        signdoc_id: get_singdoc_id(@appointment.id),
        status: 'proposal_creation'
      }
      @form_data[:stream_datas] = button_step_data('proposal_creation',@appointment.stype)

      apply = Apply.where("user_id = #{user_id}").order("created_at DESC")
      @schools = School.where(apply_id: apply.first.id).order("created_at DESC")
      @work_history = Company.where(apply_id: apply.first.id).order("created_at DESC")
      work = Work.where(user_id: user_id).first
      if !work.nil?
        depart_id =  Positionjob.where(id: work.positionjob_id).first
        if !depart_id.nil?
          @mailLeader = Department.where(id: depart_id.department_id ).first
          @listWorkleader = Mandocdhandle.select("mandocdhandles.*, max_mandocdhandles.max_id")
                          .from("mandocdhandles").where(department_id: depart_id.department_id)
                          .joins("LEFT JOIN (SELECT mandoc_id, MAX(id) as max_id FROM mandocdhandles GROUP BY mandoc_id) as max_mandocdhandles ON mandocdhandles.id = max_mandocdhandles.max_id")
                          .order("mandocdhandles.id DESC")
          @listWork = Mandocuhandle.select("mandocuhandles.*, max_mandocuhandles.max_id")
                              .from("mandocuhandles").where(user_id: user_id)
                              .joins("LEFT JOIN (SELECT mandocdhandle_id, MAX(id) as max_id FROM mandocuhandles GROUP BY mandocdhandle_id) as max_mandocuhandles ON mandocuhandles.id = max_mandocuhandles.max_id")
                              .order("mandocuhandles.id DESC")
        end
      end
      @archives = Archive.where("user_id = #{user_id}").order("created_at DESC")
      @works_stask = Work.where("user_id = #{user_id} AND positionjob_id IS NOT NULL")
  end

  def update

  end

  def assign_submit
    begin
      recipient_user_id = params[:recipient_user_id]
      next_department_id = params[:next_department_id]
      appointment_id = params[:appointment_id].to_i
      mandocuhandle_id = params[:mandocuhandle_id].to_i
      next_department_id = params[:next_department_id]
      next_status = params[:next_status]
      result = params[:result]

      mandoc_proposal_creation = Mandoc.find_by(appointment_id: appointment_id)
      mandocdhandle = Mandocdhandle.find_by(mandoc_id: mandoc_proposal_creation.id, department_id: next_department_id)
      unless mandocdhandle
        return render json: { status: 'error', message: 'Không tìm thấy phòng ban xử lý!' }, status: :not_found
      end

      # Cập nhật uhandle cho người phân công
      update_result = update_mandocuhandle(
        id: mandocuhandle_id,
        srole: result,
        sread: 'DONE'
      )

      unless update_result
        return render json: { status: 'error', message: 'Cập nhật thông tin cho người phân công thất bại!' }, status: :unprocessable_entity
      end

      # Tạo uhandle cho người được phân công
      mandocuhandle = create_mandocuhandle(
        mandocdhandle_id: mandocdhandle.id,
        user_id: recipient_user_id,
        sread: 'PROCESS',
        status: update_result.status
      )

      unless mandocuhandle
        return render json: { status: 'error', message: 'Tạo thông tin cho người được phân công thất bại!' }, status: :unprocessable_entity
      end

      render json: { status: 'success', message: 'Phân công thành công' }, status: :ok
    rescue StandardError => e
      render json: { status: 'error', message: "Đã xảy ra lỗi: #{e.message}" }, status: :internal_server_error
    end
  end

  def proposal_submit
    mandoc = Mandoc.find_or_initialize_by(
      appointment_id: @appointment.id,
      status: 'proposal_creation'
    )

    attributes = { sno: params[:sno], contents: params[:contents] }
    success =
      if mandoc.persisted?
        mandoc.update(attributes)
      else
        mandoc.update(attributes.merge(status: 'proposal_creation'))
      end

    if success
      appointment = Appointment.find(@appointment.id)
      appointment.update!(
        status: 'proposal_creation',
        appointment_date: params[:appointment_date],
      )
      render json: {
        success: true,
        message: 'Đã lưu thành công',
        data: mandoc.as_json
      }, status: :ok
    else
      render json: {
        success: false,
        message: "Lưu thất bại: #{mandoc.errors.full_messages.to_sentence}",
        errors: mandoc.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  def department_approval_submit
    begin
      @appointment = Appointment.find(params[:appointment_id])
      unless @appointment
        return render json: { status: 'error', message: 'Không tìm thấy đề xuất' }, status: :not_found
      end

      if @appointment.status == 'proposal_creation'
        # Trưởng phòng TCHC xử lý trực tiếp
        if is_access(session[:user_id], "APPOINTMENT-APPROVE-PROPOSAL", "READ")
          unless @appointment.update(status: 'department_approval')
            return render json: { status: 'error', message: 'Cập nhật trạng thái cho đề xuất thất bại!' }, status: :unprocessable_entity
          end
        end

        mandoc = Mandoc.find_by(appointment_id: @appointment.id, status: 'proposal_creation')
        unless mandoc
          return render json: { status: 'error', message: 'Không tìm thấy tờ trình với trạng thái proposal_creation!' }, status: :not_found
        end

        mandocdhandles = Mandocdhandle.where(mandoc_id: mandoc.id)
        mandocdhandle_ids = mandocdhandles.pluck(:id)

        oUmandoc = Mandocuhandle.where(mandocdhandle_id: mandocdhandle_ids, status: 'proposal_creation')
                                .order(created_at: :desc).first
        unless oUmandoc
          return render json: { status: 'error', message: 'Không tìm thấy bước hiện hiện tại!' }, status: :not_found
        end
        department_head_name = is_access(session[:user_id], "APPOINTMENT-APPROVE-PROPOSAL", "READ") ? 'Trưởng phòng TCHC' : 'Phó phòng TCHC'
        next_status = is_access(session[:user_id], "APPOINTMENT-APPROVE-PROPOSAL", "READ") ? params[:next_status] : 'proposal_creation'

        if is_access(session[:user_id], "APPOINTMENT-APPROVE-PROPOSAL", "READ") && is_access(session[:user_id], "APPOINTMENT-APPROVE-PROPOSAL", "EDIT")
          # Cập nhật uhandle hiện tại
          update_result = update_mandocuhandle(
            id: oUmandoc.id,
            srole: 'approved',
            sread: 'DONE'
          )
          unless update_result
            return render json: { status: 'error', message: 'Cập nhật bước hiện tại thất bại!' }, status: :unprocessable_entity
          end

          # Tạo uhandle cho bước tiếp theo
          create_result = create_mandocuhandle(
            mandocdhandle_id: oUmandoc.mandocdhandle_id,
            user_id: session[:user_id],
            sread: 'PROCESS',
            status: next_status
          )
          unless create_result
            return render json: { status: 'error', message: 'Tạo bước tiếp theo thất bại!' }, status: :unprocessable_entity
          end

          render json: { status: 'success', message: "Trình #{department_head_name} thành công!" }, status: :ok
        else
          # Cập nhật uhandle hiện tại
          update_result = update_mandocuhandle(
            id: oUmandoc.id,
            srole: 'assign',
            sread: 'DONE'
          )
          unless update_result
            return render json: { status: 'error', message: 'Cập nhật bước hiện tại thất bại!' }, status: :unprocessable_entity
          end

          # Tạo uhandle cho bước tiếp theo
          create_result = create_mandocuhandle(
            mandocdhandle_id: oUmandoc.mandocdhandle_id,
            user_id: params[:recipient_user_id],
            sread: 'PROCESS',
            status: next_status
          )
          unless create_result
            return render json: { status: 'error', message: 'Tạo bước tiếp theo thất bại!' }, status: :unprocessable_entity
          end

          render json: { status: 'success', message: "Trình #{department_head_name} thành công!" }, status: :ok
        end
      else
        render json: { status: 'error', message: 'Trạng thái đề xuất không hợp lệ!' }, status: :unprocessable_entity
      end
    rescue StandardError => e
      render json: { status: 'error', message: 'Đã xảy ra lỗi hệ thống, vui lòng thử lại sau!' }, status: :internal_server_error
    end
  end

  private

  def set_appointment
    @appointment = Appointment.find(params[:appointment_id])
  end
end
