class SurveyController < ApplicationController
  include AppointmentsHelper
    before_action :authorize
    before_action :set_appointsurvey, only: [:answer, :load_survey]

    def index
        search = params[:search] || ''
        sql = Survey.where("name LIKE ? OR code LIKE ? OR stype LIKE ? OR note LIKE ?", "%#{search}%", "%#{search}%", "%#{search}%","%#{search}%")
        @surveys = pagination_limit_offset(sql, 10)
    
    end

    def update_survey
        id = params[:survey_id_add]
        sName = params[:survey_name_add].squish
        strCode = params[:survey_code_add].squish
        strStype = params[:survey_stype_add].squish
        strNote = params[:survey_note_add].squish
        strStatus = params[:survey_status_add].squish
        msg = lib_translate("Not_Success")
        if id == ''
            survey = Survey.new
            survey.name = sName
            survey.code = strCode
            survey.stype = strStype
            survey.note = strNote
            survey.status = strStatus
            survey.save
            msg = lib_translate("Create_successfully")
        else
            survey = Survey.where(id: id).first
            if !survey.nil?
                survey.update(
                    {
                        name: sName,
                        code: strCode,
                        stype: strStype,
                        note: strNote,
                        status: strStatus,
                    }
                )    
                change_column_value = survey.previous_changes
                change_column_name = survey.previous_changes.keys
                if change_column_name  != ""
                  for changed_column in change_column_name do 
                      if changed_column != "updated_at"
                          fvalue = change_column_value[changed_column][0]
                          tvalue = change_column_value[changed_column][1]                          
                        log_history(Survey, changed_column, fvalue ,tvalue, @current_user.email)                        
                      end
                  end  
                end   
                msg = lib_translate("Update_successfully")
            end
        end
        redirect_to :back, notice: msg
    
    end

    def detail
        survey_id = params[:survey_id]
        if survey_id.blank?
          redirect_to survey_index_path, alert: lib_translate("Not_Success")
          return
        end
        @surveyName = Survey.where(id: survey_id)&.first&.name
        oAppointment = Appointment.where(survey_id: survey_id).first
        @is_use = false
        if !oAppointment.nil?
          @is_use = true
        end
        
        # Lấy dữ liệu từ database
        questions = Qsurvey.where(survey_id: survey_id).order(:iorder)
        options = Oqsurvery.where(qsurvey_id: questions.pluck(:id)).group_by(&:qsurvey_id)
      
        # Nhóm câu hỏi theo gsurvey_id
        grouped_questions = questions.group_by(&:gsurvey_id)
      
        # Build response data
        response_data = {
          survey_id: survey_id,
          groups: grouped_questions.map do |gsurvey_id, questions|
            {
              id: gsurvey_id, # Gsurvey ID để khớp với dropdown
              questions: questions.map do |q|
                {
                  id: q.id,
                  position: q.iorder.to_i,
                  content: q.content,
                  type: q.stype || 'multiple_choice',
                  options: (options[q.id] || []).map do |opt|
                    {
                      id: opt.id,
                      content: opt.optvalue # Dùng optvalue theo schema
                    }
                  end
                }
              end
            }
          end
        }
      
        respond_to do |format|
          format.html do
            @gsurveys = Gsurvey.where(status: "ACTIVE").select(:id, :name).order(:iorder) # Dùng để render dropdown
            @survey_data = response_data.to_json # Truyền JSON cho JS
          end
          format.json { render json: response_data }
        end
    end

    def update_detail
      begin
        survey_id = params[:survey_id]
        groups_data = params[:groups] || []
        deleted_question_ids = params[:deleted_question_ids] || []
        deleted_group_ids = params[:deleted_group_ids] || []
    
        # Lựa chọn mặc định cố định
        strDEFAULT_OPTIONS = [
          { content: "Không hài lòng", iorder: 1 },
          { content: "Bình thường", iorder: 2 },
          { content: "Hài lòng", iorder: 3 },
          { content: "Rất hài lòng", iorder: 4 }
        ]
    
        # Lấy tất cả câu hỏi hiện có trong database
        existing_questions = Qsurvey.where(survey_id: survey_id).index_by(&:id)
        updated_question_ids = []
    
        # Xóa các câu hỏi không còn trong khảo sát
        if deleted_question_ids.present?
          Qsurvey.where(id: deleted_question_ids, survey_id: survey_id).destroy_all
        end
    
        # Xóa các câu hỏi thuộc nhóm bị xóa
        if deleted_group_ids.present?
          Qsurvey.where(gsurvey_id: deleted_group_ids, survey_id: survey_id).destroy_all
        end
    
        # Cập nhật hoặc thêm mới các nhóm và câu hỏi từ payload
        groups_data.each do |group_data|
          gsurvey_id = group_data[:id]
    
          group_data[:questions].each do |question_data|
            question_id = question_data[:id]&.to_i
            question = nil
    
            if question_id.present? && existing_questions[question_id]
              question = existing_questions[question_id]
              question.update!(
                content: question_data[:content],
                stype: question_data[:type],
                iorder: question_data[:position].to_i,
                gsurvey_id: gsurvey_id
              )
              updated_question_ids << question_id
            else
              question = Qsurvey.create!(
                survey_id: survey_id,
                gsurvey_id: gsurvey_id,
                content: question_data[:content],
                stype: question_data[:type],
                iorder: question_data[:position].to_i
              )
              updated_question_ids << question.id
    
              # Tạo 4 tùy chọn mặc định cho câu hỏi mới
              strDEFAULT_OPTIONS.each do |opt|
                Oqsurvery.create!(
                  qsurvey_id: question.id,
                  optvalue: opt[:content],
                  iorder: opt[:iorder]
                )
              end
            end   
            
          end
        end
    
        # Lấy dữ liệu mới nhất, sắp xếp nhóm theo iorder của Gsurvey
        questions = Qsurvey.where(survey_id: survey_id).order(:iorder)
        options = Oqsurvery.where(qsurvey_id: questions.pluck(:id)).order(:iorder).group_by(&:qsurvey_id)
        grouped_questions = questions.group_by(&:gsurvey_id)
        gsurveys = Gsurvey.where(id: grouped_questions.keys).order(:iorder)
    
        survey_data = {
          survey_id: survey_id,
          groups: gsurveys.map do |gsurvey|
            qs = grouped_questions[gsurvey.id] || []
            {
              id: gsurvey.id,
              questions: qs.map do |q|
                {
                  id: q.id,
                  position: q.iorder.to_i,
                  content: q.content,
                  type: q.stype || 'multiple_choice',
                  options: (options[q.id] || []).map do |opt|
                    {
                      id: opt.id,
                      content: opt.optvalue
                    }
                  end
                }
              end
            }
          end
        }
    
        render json: { success: true, message: 'Lưu thành công!', survey_data: survey_data }
      rescue => e
        render json: { success: false, errors: [e.message] }, status: :unprocessable_entity
      end
    end

    def del
        id = params[:id]
        msg = lib_translate("Not_Success")
        survey = Survey.where("id = #{id}").first
        if !survey.nil?
            survey.destroy
            log_history(Survey, "Xóa", survey.name , "Đã xóa khỏi hệ thống", @current_user.email)
            msg = lib_translate("Delete_successfully")
        end
        redirect_to :back, notice: msg
    
    end
    

    def answer
      # Render view cho trang trả lời khảo sát
      # @appointsurvey đã được set từ before_action
    end
  
    def load_survey
      appointment = @appointsurvey.appointment
      raise "Không tìm thấy nhiệm vụ liên quan" unless appointment
      raise "Bạn không có quyền truy cập khảo sát này" unless @appointsurvey.user_id == @current_user.id && @appointsurvey.status == "ASSIGN"
      deadline_date = @appointsurvey.dtdeadline.in_time_zone('Asia/Ho_Chi_Minh').to_date
      current_date = Time.zone.today
      raise "Đã hết hạn thực hiện khảo sát" unless deadline_date + 1.day > current_date
    
      survey = appointment.survey
      raise "Không tìm thấy khảo sát" unless survey
    
      qsurveys = survey.qsurveys.order(:iorder)
      grouped_qsurveys = qsurveys.group_by(&:gsurvey_id)
    
      # Lấy tất cả Surveyrecord liên quan đến appointsurvey
      survey_records = Surveyrecord.where(appointsurvey_id: @appointsurvey.id).index_by { |r| r.qsurvey_id || r.answer }
    
      survey_data = {
        groups: grouped_qsurveys.map do |gsurvey_id, qs|
          gsurvey = Gsurvey.find(gsurvey_id)
          sample_qsurvey = qs.first
          options = sample_qsurvey.oqsurveries.order(:iorder).map do |oqsurvery|
            { id: oqsurvery.id, content: oqsurvery.optvalue }
          end
    
          # Lấy note cho nhóm nếu tồn tại (qsurvey_id nil, answer = gsurvey_id)
          group_record = survey_records[gsurvey_id.to_s]
          note = group_record && group_record.qsurvey_id.nil? ? group_record.note : nil
    
          {
            id: gsurvey.id,
            name: gsurvey.name,
            note: note, # Chỉ lấy note nếu record tồn tại và là loại ý kiến khác
            questions: qs.map do |qsurvey|
              # Lấy đáp án đã chọn từ Surveyrecord
              record = survey_records[qsurvey.id]
              selected_answer = record&.qsurvey_id.present? ? record.answer : nil
    
              {
                id: qsurvey.id,
                content: qsurvey.content,
                option_ids: qsurvey.oqsurveries.order(:iorder).pluck(:id),
                selected_answer: selected_answer # Chỉ lấy answer nếu là loại trắc nghiệm
              }
            end,
            options: options
          }
        end
      }
    
      render json: { success: true, survey_data: survey_data }
    rescue => e
      render json: { success: false, errors: e.message }, status: :unprocessable_entity
    end
  
    def submit_answer
      qsurvey_id = params[:qsurvey_id]
      answer = params[:answer]
      appointsurvey_id = params[:appointsurvey_id]
    
      # Kiểm tra dữ liệu đầu vào
      unless qsurvey_id && answer
        return render json: { success: false, errors: "Thiếu qsurvey_id hoặc answer" }, status: :bad_request
      end
    
      # Kiểm tra qsurvey có tồn tại không
      unless Qsurvey.exists?(qsurvey_id)
        return render json: { success: false, errors: "Câu hỏi không tồn tại" }, status: :not_found
      end
    
      # Kiểm tra answer (oqsurvery_id) có tồn tại không
      unless Oqsurvery.exists?(answer)
        return render json: { success: false, errors: "Lựa chọn không tồn tại" }, status: :not_found
      end
    
      # Tìm hoặc tạo mới Surveyrecord với đầy đủ giá trị
      oSurveyrecord = Surveyrecord.where(appointsurvey_id: appointsurvey_id, qsurvey_id:qsurvey_id).first
      if oSurveyrecord.nil?
        Surveyrecord.create({
          appointsurvey_id: appointsurvey_id,
          qsurvey_id: qsurvey_id,
          answer: answer,
          dtanswer: Time.now,
          status: "answered",
        })
      else
        oSurveyrecord.update({
          answer: answer,
          dtanswer: Time.now,
          status: "answered",
        })
      
      end
    
    
      render json: { success: true, message: "Đáp án đã được lưu" }
    rescue => e
      render json: { success: false, errors: e.message }, status: :unprocessable_entity
    end  

    def submit_all_answers
      appointsurvey_id = params[:appointsurvey_id]
      answers = params[:answers] || []
      notes = params[:notes] || []
      conclusion = params[:conclusion]
      conclusion_note = params[:conclusion_note] || ''

      unless appointsurvey_id && Appointsurvey.exists?(appointsurvey_id)
        return render json: { success: false, errors: "Không tìm thấy appointsurvey" }, status: :not_found
      end

      answers.each do |answer_data|
        qsurvey_id = answer_data[:qsurvey_id]
        next unless qsurvey_id && Qsurvey.exists?(qsurvey_id)

        oSurveyrecord = Surveyrecord.where(appointsurvey_id: appointsurvey_id, qsurvey_id: qsurvey_id).first
        if oSurveyrecord.nil?
          Surveyrecord.create!(
            appointsurvey_id: appointsurvey_id,
            qsurvey_id: qsurvey_id,
            answer: answer_data[:answer],
            dtanswer: answer_data[:dtanswer],
            status: "answered"
          )
        else
          oSurveyrecord.update!(
            answer: answer_data[:answer],
            dtanswer: answer_data[:dtanswer],
            status: "answered"
          )
        end
      end

      notes.each do |note_data|
        qsurvey = Qsurvey.where(gsurvey_id: note_data[:gsurvey_id]).order(:iorder).first
        next unless qsurvey

        oSurveyrecord = Surveyrecord.where(appointsurvey_id: appointsurvey_id, answer: note_data[:gsurvey_id]).first
        if oSurveyrecord.nil?
          Surveyrecord.create!(
            appointsurvey_id: appointsurvey_id,
            note: note_data[:note],
            dtanswer: Time.now,
            status: "answered",
            answer: note_data[:gsurvey_id]
          )
        else
          oSurveyrecord.update!(
            note: note_data[:note],
            dtanswer: Time.now,
            status: "answered"
          )
        end
      end

      oCurrentAppoiment = Appointsurvey.where(id: appointsurvey_id).first
      update_attributes = { status: "COMPLETED", dtfinished: Time.now, result: conclusion }
      update_attributes[:note] = conclusion_note if conclusion == "rejected"
      
      oCurrentAppoiment.update!(update_attributes)
      appointment_id = oCurrentAppoiment.appointment_id      
      oAppointsurvey = Appointsurvey.where(appointment_id: appointment_id, status: "ASSIGN").first
      if oAppointsurvey.nil?
        update_status(appointment_id)
      end
      render json: { success: true, message: "Đã lưu toàn bộ thành công" }
    rescue => e
      render json: { success: false, errors: "Có lỗi xảy ra, vui lòng kiểm tra lại" }, status: :unprocessable_entity
    end

    def assign_survey 
      @appointment = Appointment.find_by(id: params[:appointments_id])
      unless @appointment
        flash[:alert] = "Không tìm thấy nhiệm vụ với ID: #{@appointment.name}"
        redirect_to root_path and return
      end       
      @departments = Department.all.select(:id,:name)
      @users = User.where.not(status:"INACTIVE").select(:id,:sid,:first_name,:last_name)
      @assignSurveys = Survey.where(stype:"BO-NHIEM").where.not(status:"INACTIVE").select(:id,:name)        
    end
      
    def publish_survey
      ActiveRecord::Base.transaction do
        begin
            appointments_id = params[:appointments_id]
            start_date = Date.parse(params[:start_date])
            end_date = Date.parse(params[:end_date])
            survey_id = params[:survey_id]
            mandocuhandle_id = params[:mandocuhandle_id]
            strAppointmentName = Appointment.where(id: appointments_id)&.first&.title
            
            raise "Ngày bắt đầu phải trước ngày kết thúc" if start_date > end_date
      
            department_ids = params[:departments] || []
            user_ids = params[:users] || []
            oNewNotify = Notify.create({
              title: "Xuất bản khảo sát",
              contents: "Xuất bản phiếu khảo sát ý kiến: #{strAppointmentName}",
              valid_from: start_date,
              valid_to: end_date,
              senders: @current_user.email,
              stype: "SURVEY",
              dtsent: start_date
            })

            # Tìm user thuộc phòng ban 
            if department_ids.length > 0
              department_ids.each do |department_id|
                oUserDepartment = User.joins(works: [positionjob: :department]).where(departments: {id: department_id})
                oUserDepartment.each do |user|
                  oAppointsurvey = Appointsurvey.where(user_id: user.id, appointment_id:appointments_id).first
                  if oAppointsurvey.nil?
                    newAppointsurvey =  Appointsurvey.create({
                      appointment_id: appointments_id,
                      user_id: user.id,
                      dtsent: start_date,
                      status: "ASSIGN",     
                      dtdeadline: end_date,      
                    })
                    Snotice.create({
                      notify_id: oNewNotify.id,
                      user_id: user.id,
                      dtreceived: start_date,
                      username: newAppointsurvey.id
                    })          
                  end
                end
              end      
            end

            
            if user_ids.length > 0
              user_ids.each do |user_id|       
                oAppointsurveyUser = Appointsurvey.where(user_id: user_id, appointment_id:appointments_id).first
                if oAppointsurveyUser.nil?
                  newAppointsurvey =  Appointsurvey.create({
                    appointment_id: appointments_id,
                    user_id: user_id,
                    dtsent: start_date,
                    status: "ASSIGN",    
                    dtdeadline: end_date,            
                  })
                  Snotice.create({
                    notify_id: oNewNotify.id,
                    user_id: user_id,
                    dtreceived: start_date,
                    username: newAppointsurvey.id,
                    isread: false,
                  })          
                end 
              end
            end

            
            Appointment.where(id: appointments_id)&.first&.update({status: "evaluation", survey_id: survey_id}) 
            Mandocuhandle.find(mandocuhandle_id).update({sread: "DONE"})
            render json: { success: true, message: "Đã xuất bản khảo sát thành công #{department_ids} #{user_ids}"  }
          rescue => e
            render json: { success: false, errors: e.message }, status: :unprocessable_entity
        rescue => e
        raise ActiveRecord::Rollback  
        end
      end
    end

    def load_assign_survey
      survey = Survey.find_by(id: params[:survey_id])
      unless survey
        render json: { success: false, errors: "Không tìm thấy khảo sát" }, status: :not_found
        return
      end
    
      qsurveys = survey.qsurveys.order(:iorder)
      grouped_qsurveys = qsurveys.group_by(&:gsurvey_id)
    
      survey_data = {
        survey_name: survey.name,
        groups: grouped_qsurveys.map do |gsurvey_id, qs|
          gsurvey = Gsurvey.find(gsurvey_id)
          sample_qsurvey = qs.first
          options = sample_qsurvey.oqsurveries.order(:iorder).map do |oqsurvery|
            { id: oqsurvery.id, content: oqsurvery.optvalue }
          end
    
          {
            id: gsurvey.id,
            name: gsurvey.name,
            questions: qs.map do |qsurvey|
              {
                id: qsurvey.id,
                content: qsurvey.content,
                option_ids: qsurvey.oqsurveries.order(:iorder).pluck(:id)
              }
            end,
            options: options
          }
        end
      }
    
      render json: { success: true, survey_data: survey_data }
    rescue => e
      render json: { success: false, errors: e.message }, status: :unprocessable_entity
    end

    
  
    private
  
    def set_appointsurvey
      @appointsurvey = Appointsurvey.find_by(id: params[:appointsurvey_id])
      return if @appointsurvey # Tiếp tục nếu tìm thấy
  
      # Nếu không tìm thấy, xử lý theo loại request
      if request.get?
        redirect_back(fallback_location: root_path)
      else
        render json: { success: false, errors: "Không tìm thấy appointsurvey" }, status: :not_found
      end
      false # Dừng xử lý action tiếp theo
    end

  
    
end
  