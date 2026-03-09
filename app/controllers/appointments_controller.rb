class AppointmentsController < ApplicationController
    include AppointmentStatusController
    include AppointmentsHelper
    include SigndocConcern
    before_action :set_appointment, only: [:show, :edit, :update, :destroy,:load_signdoc]
    skip_before_action :verify_authenticity_token, only: :load_signdoc

    TAB_NAME = {
        task_list: "task_list",
        processing_task: "processing_task"
    }.freeze

    def index
      # Params
      page = params[:page].to_i
      per_page = params[:per_page].to_i
      search = params.dig(:search, :value).to_s.strip
      # Khai báo biến
      oData = []

      @tabs = TAB_NAME
      @current_tab = params[:tab] || TAB_NAME[:task_list]
      gon.appointments_path = appointments_path(
          tab: @current_tab,
          format: :json,
      )
      @appointment = Appointment.new
      @counts = {
          TAB_NAME[:task_list] => Appointment.count_filtered_appointments(search, session[:user_id]),
          TAB_NAME[:processing_task] => Appointment.count_filtered_appointments(search, session[:user_id], true)
      }
      case @current_tab
      when TAB_NAME[:task_list]
        oData = Appointment.filtered_appointments(search, session[:user_id], page, per_page)
        @totalCount = @counts[TAB_NAME[:task_list]]
      when TAB_NAME[:processing_task]
        oData = Appointment.filtered_appointments(search, session[:user_id], page, per_page, true)
        @totalCount = @counts[TAB_NAME[:processing_task]]
      end

      respond_to do |format|
        format.html
        format.json { render json: {
          draw: params[:draw],
          recordsTotal: @totalCount,
          recordsFiltered: @totalCount,
          data: oData
        }}
      end
    end

    def new
        @appointment = Appointment.new
        respond_to do |format|
            format.js
        end
    end

    # Chức năng: Hiển thị thông tin chi tiết của một cuộc hẹn (appointment), bao gồm các xử lý liên quan (mandocuhandles),
    # bước hiện tại, và thông tin khảo sát (appointsurvey). Hỗ trợ trả về cả định dạng HTML và JavaScript.
    # Người xây dựng: Lê Ngọc Huy
    # Đầu vào: Không có tham số trực tiếp, hàm sử dụng các biến instance:
    #   - @appointment (Object): Đối tượng cuộc hẹn hiện tại, được giả định đã được khởi tạo trước (thường trong controller).
    #   - session[:user_id] (Integer): ID của người dùng hiện tại, lấy từ session.
    def show
      @mandocuhandles = Mandocuhandle.joins(mandocdhandle: { mandoc: :appointment })
                                  .where(mandocs: { appointment_id: @appointment.id })
                                  .includes(mandocdhandle: { mandoc: :appointment })
                                  .order(created_at: :desc)

      @latest_handles = @mandocuhandles.group_by(&:status).transform_values { |handles| handles.max_by(&:created_at) }

      @current_step = determine_current_step

      @appointsurvey = Appointsurvey.find_by(user_id: session[:user_id], appointment_id: @appointment.id)

      # Lấy danh sách các bước trong quy trình xử lý của bổ nhiệm, miễn nhiệm, ....
      case @appointment.stype
      when "MIEN_NHIEM"
        @steps = AppointmentStatusManagement::STEPS.reject { |k, _| [2,3,4,5,6].include?(k) }
      else
        @steps = AppointmentStatusManagement::STEPS
      end

      respond_to do |format|
        format.html
        format.js
      end

    end

    def create
      if params[:appointment_id].present?
        update_existing_appointment
      else
        create_new_appointment
      end
    end

    def pending_approvals
        @appointments = Appointment.where(result: Appointment::RESULTS[:pending])

        respond_to do |format|
            format.html
            format.json { render json: @appointments }
        end
    end

    # Action cập nhật chung cho thao tác submit của tất cả bước trong quy trình
    def update
      current_step = find_step_by_status(params[:status])
      success = true
      message = "Xử lý thành công"
      position = ""
      error_detail = ""
      ActiveRecord::Base.transaction do
        begin
          #1 Cập nhật/Tạo mới appointment
          unless @appointment.update(appointment_params)
            success = false
            message = "Lỗi khi cập nhật thông tin bổ nhiệm"
            raise ActiveRecord::Rollback
          end

          case current_step
          when 1
          when 2
            @appointment.update({
              trust_collection_period: params[:trust_collection_period],
            })
            store_appointment_files(@appointment.id,params[:files] || [])
            remove_appointment_files(params[:remove_media_ids])

            assign_user_id = params[:assign_user_id]
            if assign_user_id.present?
              uhandle = update_mandocuhandle(id: params[:mandocuhandle_id], srole: params[:result], sread:"DONE",contents: params[:mandocuhandle_contents])
              dhandle = uhandle.mandocdhandle
              if dhandle.department_id != params[:next_department_scode]
                dhandle = create_mandocdhandle(mandoc_id: dhandle.mandoc_id, department_id: params[:next_department_id])
              end
              create_mandocuhandle(mandocdhandle_id: dhandle.id, user_id: assign_user_id, sread: "PROCESS", status: params[:next_status],contents: params[:mandocuhandle_contents])
              @appointment.update(status: params[:next_status])
            end

          when 3
            # Cập nhật uhandle hiện tại
            uhandle = update_mandocuhandle(id: params[:mandocuhandle_id], srole: params[:result], sread: "DONE",contents: params[:mandocuhandle_contents])
            # Tạo mới uhandle bước tiếp theo
            dhandle = uhandle.mandocdhandle
            if dhandle.department_id != params[:next_department_scode]
              dhandle = create_mandocdhandle(mandoc_id: dhandle.mandoc_id, department_id: params[:next_department_id])
            end
            assign_user_id = params[:assign_user_id]
            if params[:result] == "rejected"
              assign_user_id = get_pre_uhandle(params[:appointment_id],params[:mandocuhandle_id])
            end
            create_mandocuhandle(mandocdhandle_id: dhandle.id, user_id: assign_user_id, sread: "PROCESS", status: params[:next_status],contents: params[:mandocuhandle_contents])
            @appointment.update(status: params[:next_status])
            send_principal =  params[:result] == "approved"
            send_procecss_notify(@appointment.id,send_principal)
          when 4 # BGH
            #3 Cập nhật uhandle hiện tại
            uhandle = update_mandocuhandle(id: params[:mandocuhandle_id], srole: params[:result], sread: "DONE",contents: params[:mandocuhandle_contents])
            #4 Tạo mới uhandle bước tiếp theo
            if params[:result] == "approved"
              if @appointment.is_survey == "YES"
                dhandle = uhandle.mandocdhandle
                if dhandle.department_id != params[:next_department_scode]
                  dhandle = create_mandocdhandle(mandoc_id: dhandle.mandoc_id, department_id: params[:next_department_id])
                end
                # giao cho người lập tờ trình tạo khảo sát
                assign_user_id = get_proposal_creation_id(params[:appointment_id],find_status_by_step(2))
                create_mandocuhandle(mandocdhandle_id: dhandle.id, user_id: assign_user_id, sread: "PROCESS", status: params[:next_status],contents: params[:mandocuhandle_contents])
                @appointment.update(status: params[:next_status])
              else
                dhandle = uhandle.mandocdhandle
                if dhandle.department_id != params[:next_department_scode]
                  dhandle = create_mandocdhandle(mandoc_id: dhandle.mandoc_id, department_id: params[:next_department_id])
                end
                # giao cho người lập tờ trình tạo khảo sát
                assign_user_id = get_proposal_creation_id(params[:appointment_id],find_status_by_step(2))
                create_mandocuhandle(mandocdhandle_id: dhandle.id, user_id: assign_user_id, sread: "PROCESS", status: "proposal_creation")
                @appointment.update(status: "proposal_creation")
              end
            elsif params[:result] == "stoped"
              # stop quy trình
              last_status = last_step_data(@appointment.stype)
              next_uhandle = create_mandocuhandle(mandocdhandle_id: uhandle.mandocdhandle_id, user_id: uhandle.user_id, sread: "DONE", status: last_status)
              update_mandocuhandle(id: next_uhandle.id, srole: params[:result], sread: "DONE",contents: params[:mandocuhandle_contents])
              @appointment.update(status: last_status, result: params[:result],is_survey: "NO")
            end

          when 8 # trưởng phòng duyệt tờ trình
            #2 tạo chữ ký
            if params[:result] == "approved"
              create_sign(params[:signdoc_id],sign_params)
            end
            #3 Cập nhật uhandle hiện tại
            uhandle = update_mandocuhandle(id: params[:mandocuhandle_id], srole: params[:result], sread: "DONE",contents: params[:mandocuhandle_contents])
            #4 Tạo mới uhandle bước tiếp theo
            dhandle = uhandle.mandocdhandle
            if dhandle.department_id != params[:next_department_scode]
              dhandle = create_mandocdhandle(mandoc_id: dhandle.mandoc_id, department_id: params[:next_department_id])
            end
            assign_user_id = params[:assign_user_id]
            if params[:result] == "rejected"
              assign_user_id = get_pre_uhandle(params[:appointment_id],params[:mandocuhandle_id])
            end
            create_mandocuhandle(mandocdhandle_id: dhandle.id, user_id: assign_user_id, sread: "PROCESS", status: params[:next_status],contents: params[:mandocuhandle_contents])
            @appointment.update(status: params[:next_status])
            send_principal =  params[:result] == "approved"
            send_procecss_notify(@appointment.id,send_principal)
          when 9 # duyệt bổ nhiệm.

            uhandle = update_mandocuhandle(id: params[:mandocuhandle_id], srole: params[:result], sread: "DONE",contents: params[:mandocuhandle_contents])

            if params[:result] == "finished"
              last_status = last_step_data(@appointment.stype)
              next_uhandle = create_mandocuhandle(mandocdhandle_id: uhandle.mandocdhandle_id, user_id: uhandle.user_id, sread: "DONE", status: last_status)
              update_mandocuhandle(id: next_uhandle.id, srole: "finished", sread: "DONE")
              @appointment.update(status: last_status, result: "finished")

              create_sign(params[:signdoc_id],sign_params)
              # finish quy trình
              if @appointment.stype == "BO_NHIEM"
                assign_positionjob()
              else
                dismiss_positionjob()
              end
              
            elsif params[:result] == "stoped"
              # stop quy trình
              last_status = last_step_data(@appointment.stype)
              next_uhandle = create_mandocuhandle(mandocdhandle_id: uhandle.mandocdhandle_id, user_id: uhandle.user_id, sread: "DONE", status: last_status)
              update_mandocuhandle(id: next_uhandle.id, srole: params[:result], sread: "DONE",contents: params[:mandocuhandle_contents])
              @appointment.update(status: last_status, result: params[:result],is_survey: "NO")
            end
            send_procecss_notify(@appointment.id,true)
          end

        rescue => e
          position = e.backtrace.to_json.html_safe.gsub("\`","")
          success = false
          error_detail = e.message.gsub("\`","")
          message = "Lỗi khi cập nhật thông tin bổ nhiệm"
          raise ActiveRecord::Rollback
        end

      end

      if !success
        Errlog.create({
          msg: error_detail,
          msgdetails: position,
          surl: request.fullpath,
          owner: "#{session[:user_id]}/#{session[:user_fullname]}",
          dtaccess: DateTime.now,
        })
        respond_to do |format|
          format.html {redirect_to appointment_path(id:@appointment.id), alert: message}
          format.js { render js: "onSubmitError();console.log(`#{error_detail.to_json.html_safe}`)" }
        end
      else
        respond_to do |format|
          format.html {redirect_to appointment_path(id:@appointment.id), alert: message}
          format.js { render js: "onSubmitSuccess();"}
        end
      end

    end

    def assign_positionjob()
      user_id = @appointment.user_id
      positionjob_id = @appointment.new_position
      department_id = @appointment.new_dept
      Work.joins(:positionjob)
          .where.not(positionjob_id: nil)
          .where("positionjobs.department_id = ?",department_id)
          .find_by(user_id: user_id)
          .update(positionjob_id: positionjob_id)

      # check positionjob is leader
      keywords = ["trưởng", "giám đốc", "chủ tịch", "trưởng phòng"]
      not_keywords = ["phó", "tổ"]
      positionjob_name = Positionjob.find_by(id:positionjob_id)&.name&.downcase&.strip&.unicode_normalize(:nfc)  || ""
      b_keywords = keywords.any?{ |key| positionjob_name.include?(key) }
      b_not_keywords = not_keywords.any?{ |key| positionjob_name.include?(key) }
      if b_keywords && !b_not_keywords
        Department.find_by(id:department_id).update(leader: @appointment.user.email)
      end

    end

    def dismiss_positionjob()
      user_id = @appointment.user_id
      positionjob_id = @appointment.new_position
      department_id = @appointment.new_dept
      work = Work.find_by(positionjob_id: positionjob_id,user_id: user_id)
      if !work.nil?
        work.destroy
        # check positionjob is leader
        keywords = ["trưởng", "giám đốc", "chủ tịch", "trưởng phòng"]
        not_keywords = ["phó", "tổ"]
        positionjob_name = Positionjob.find_by(id:positionjob_id)&.name&.downcase&.strip&.unicode_normalize(:nfc)  || ""
        b_keywords = keywords.any?{ |key| positionjob_name.include?(key) }
        b_not_keywords = not_keywords.any?{ |key| positionjob_name.include?(key) }
        if b_keywords && !b_not_keywords
          Department.find_by(id:department_id).update(leader: nil)
        end
      else

      end

    end

    def by_step
        step_number = params[:step].to_i
        step_info = Appointment::STEPS[step_number]

        if step_info
            @appointments = Appointment.where(status: step_info[:status])
            respond_to do |format|
                format.html
                format.json { render json: @appointments }
            end
        else
            respond_to do |format|
                format.html { redirect_to appointments_path, alert: 'Bước không hợp lệ.' }
                format.json { render json: { status: 'error', message: 'Bước không hợp lệ.' }, status: :unprocessable_entity }
            end
        end
    end

    # Chức năng: Chuẩn bị và trả về dữ liệu để render form dựa trên trạng thái (status) của cuộc hẹn.
    # author: Lê Ngọc Huy - 01/04/2025
    # Input: Không có tham số, hàm sử dụng params:
    #   - params[:status] (String): Trạng thái hiện tại của bước (từ request).
    #   - params[:appointment_id] (Integer): ID của appointment (từ request).
    #   - params[:mandocuhandle_id] (Integer): ID của xử lý liên quan (từ request).
    # Ouput: @form_data - hash
    def render_form
      @status = params[:status]
      @form = params[:form]
      @appointment = params[:appointment_id].present? ? Appointment.find(params[:appointment_id]) : nil
      @stype = @appointment.present? ? @appointment.stype : params[:stype]

      stream_datas = button_step_data(@status,@stype)
      @next_department_id = stream_datas&.first&.dig(:next_department_id)
      next_department_scode = stream_datas&.first&.dig(:next_department_scode)

      @form_data = {
        appointment_id: params[:appointment_id],
        status:@status,
        mandocuhandle_id: params[:mandocuhandle_id],
        next_department_id: @next_department_id,
        next_department_scode: next_department_scode,
        stream_datas: stream_datas,
      }.merge(build_form_data(@status, params[:appointment_id]) || {})
        .merge(build_extra_data(@status, params[:appointment_id]) || {})
      gon.form_data = @form_data

    end

    # Chức năng: Xây dựng dữ liệu bổ sung cho form dựa trên trạng thái và bước hiện tại của cuộc hẹn.
    # Người xây dựng: Lê Ngọc Huy - 02/04/2025
    # Đầu vào:
    #   - status (String): Trạng thái hiện tại của bước (ví dụ: 'PROCESS', 'DONE').
    #   - appointment_id (Integer): ID của appointment
    # Ghi chú: Trả về hash chứa dữ liệu tùy thuộc vào bước (step) được tìm thấy.
    def build_form_data(status, appointment_id)
      step = find_step_by_status(status)
        case (step)
        when 1 # Đề xuất yêu cầu bổ nhiệm
          user_handle_id =
            if appointment_id.present?
              Mandocuhandle.joins(mandocdhandle: { mandoc: :appointment }).where(mandocs: { appointment_id: appointment_id }).where(status: 'unit_leader_review').first&.user_id
            else
              nil
            end
          {
            levels: get_levels,
            appointment: @appointment,
            user_handle_id: user_handle_id,
          }
        when 2, 3, 4 # Xử lý đề xuất (cập nhật thông tin cá nhân bổ nhiệm)
          appointment = Appointment.joins("LEFT JOIN mandocpriorities ON appointments.priority = mandocpriorities.scode")
                          .select("appointments.*, mandocpriorities.note AS color_priority, mandocpriorities.name AS priority_name")
                          .find_by(appointments: { id: appointment_id })

          user_info = get_user_info(@appointment) || {}
          mediafiles = get_mediafiles(@appointment) || {}
          assign_users = {}
          if step == 2
            # nếu là nhân viên thì lấy danh sách phó, nếu là phó thì lấy danh sách trưởng.
            is_user_deputy = is_user_deputy(session[:user_id],session[:department_id])
            assign_users = get_assign_users(@next_department_id,!is_user_deputy,"")
          end

          {appointment: appointment}.merge(user_info)
                                    .merge(mediafiles)
                                    .merge({assign_users: assign_users, is_user_deputy: is_user_deputy})
        when 5
          {

          }
        when 6 # nhân sự trong quy trình thực hiện tín nhiệm.
          { 
            appointsurvey_id: Appointsurvey.find_by(user_id: session[:user_id], appointment_id: appointment_id)&.id,
          }
        when 7 #Lập tờ trình bổ nhiệm.
          signdoc_id = get_singdoc_id(appointment_id)
          {
            levels: get_levels,
            signdoc_id: signdoc_id,
          }
        when 8 # Tưởng Phòng Phê duyệt tờ trình
          signdoc_id = get_singdoc_id(appointment_id)
          {
            appointment: Appointment.find(appointment_id),
            user_sign: user_sign,
            bSigned: check_sign_exist(signdoc_id),
            signdoc_id: signdoc_id,
          }
        when 9 # Ban giám hiệu duyệt tờ trình
          signdoc_id = get_singdoc_id(appointment_id)
          {
            appointment: Appointment.find(appointment_id),
            user_sign: user_sign,
            bSigned: check_sign_exist(signdoc_id),
            signdoc_id: signdoc_id,
          }
        else
          result = params[:result]
          appointment =  Appointment.find(appointment_id)
          case result
            when "assign"
            {
              stream_datas: button_step_data("999999999",appointment.stype),
            }
          end
        end
    end


    def build_extra_data(status, appointment_id)
      case (status)
      when "created_preview" # Preview Đề xuất yêu cầu bổ nhiệm
        appointment = Appointment.joins("LEFT JOIN mandocpriorities ON appointments.priority = mandocpriorities.scode")
                                  .select("appointments.*, mandocpriorities.note AS color_priority, mandocpriorities.name AS priority_name")
                                  .find_by(appointments: { id: appointment_id })
        {
          appointment: appointment,
        }
      when "proposal_creation_preview" # Preview tờ trinh
        signdoc_id = get_singdoc_id(appointment_id)
        {
          signdoc_id: signdoc_id,
          status: "proposal_creation",
        }
      end
    end

    # Chức năng: Lấy danh sách các mức độ ưu tiên (Mandocpriority) để sử dụng trong form.
    # Người xây dựng: Lê Ngọc Huy - 02/04/2025
    # Đầu vào: Không có tham số trực tiếp.
    # Ghi chú: Trả về tất cả bản ghi từ bảng Mandocpriority.
    def get_levels
        Mandocpriority.all
    end

    def get_priorities
      search = params[:search]&.strip
      priorities = Mandocpriority.all

      if search.present?
        priorities = priorities.where('LOWER(name) LIKE ?', "%#{search&.downcase}%")
      end

      render json: { items: priorities }
    end

    # Chức năng: Lấy danh sách các phòng ban (departments) liên quan đến người dùng hiện tại, hỗ trợ tìm kiếm và phân trang.
    # Người xây dựng: Lê Ngọc Huy - 02/04/2025
    # Đầu vào:
    #   - params[:page] (String/Integer): Số trang hiện tại (mặc định là 1).
    #   - params[:search] (String): Từ khóa tìm kiếm (tùy chọn).
    #   - session[:user_id] (Integer): ID của người dùng hiện tại (từ session).
    # Ghi chú: Trả về JSON chứa danh sách phòng ban và thông tin phân trang.
    def get_departments
      search = params[:search]&.strip

      departments =
        if is_access(session[:user_id], "APPOINTMENT", "READ")
          Department.select(:id, :name, :scode)
                    .where(status: "0")
                    .order("name ASC")
        else
          Department.select(:id, :name, :scode)
                    .joins(positionjobs: [works: :user])
                    .where(users: {id: session[:user_id]})
                    .where(departments: {status: "0"})
                    .order("name ASC")
        end

      if search.present?
        departments = departments.where('LOWER(name) LIKE ?', "%#{search&.downcase}%")
      end

      render json: { items: departments}
    end

    # Chức năng: Lấy danh sách nhân sự quản lý (có chức danh như Trưởng, Phó, Giám đốc, Chủ tịch) theo đơn vị, hỗ trợ tìm kiếm và phân trang.
    # Người xây dựng: Lê Ngọc Huy - 02/04/2025
    # Đầu vào:
    #   - params[:page] (String/Integer): Số trang hiện tại (mặc định là 1).
    #   - params[:search] (String): Từ khóa tìm kiếm (tùy chọn).
    #   - params[:department_id] (Integer): ID của phòng ban cần lọc.
    # Ghi chú: Trả về JSON chứa danh sách người dùng và thông tin phân trang.
    def get_managers
      search = params[:search]&.strip
      department_id = params[:department_id]
      department_head = params[:department_head].to_s
      users = get_assign_users(department_id,department_head == "true",search)
      render json: { items: users }
    end


    # Chức năng: Lấy danh sách tất cả nhân sự theo đơn vị, hỗ trợ tìm kiếm và phân trang.
    # Người xây dựng: Lê Ngọc Huy - 02/04/2025
    # Đầu vào:
    #   - params[:page] (String/Integer): Số trang hiện tại (mặc định là 1).
    #   - params[:search] (String): Từ khóa tìm kiếm (tùy chọn).
    #   - params[:department_id] (Integer): ID của phòng ban cần lọc.
    # Ghi chú: Trả về JSON chứa danh sách người dùng và thông tin phân trang.
    def get_users
      search = params[:search]&.strip
      department_id = params[:department_id]
      staff_type = params[:staff_type]

      users = User.select(:id, :last_name, :first_name, :email, :sid)
                  .select("positionjobs.name as pos_name")
                  .joins(works: [positionjob: :department])
                  .where(departments: {id: department_id})
                  .where.not(users: {status: 'INACTIVE'})
                  .order("CONCAT(users.last_name,' ', users.first_name) ASC")

      if search.present?
        users = users.where("LOWER(CONCAT(users.last_name,' ', users.first_name)) LIKE ? OR users.sid LIKE ?",
          "%#{search&.downcase}%",
          "%#{search}%")
      end
      results = []
      if staff_type == "1"
        keywords = ["trưởng", "giám đốc", "chủ tịch", "trưởng phòng","phó", "tổ"]
        users.each do |user|
          if !keywords.any?{ |key| user.pos_name&.downcase&.strip&.unicode_normalize(:nfc).include?(key) }
            results << user
          end
        end
      else
        results = users
      end
      
      render json: { items: results.map(&:attributes).uniq { |h| h["id"] } }
    end

    # Chức năng: Lấy danh sách vị trí công việc (positionjobs) theo đơn vị, hỗ trợ tìm kiếm và phân trang.
    # Người xây dựng: Lê Ngọc Huy - 02/04/2025
    # Đầu vào:
    #   - params[:page] (String/Integer): Số trang hiện tại (mặc định là 1).
    #   - params[:search] (String): Từ khóa tìm kiếm (tùy chọn).
    #   - params[:department_id] (Integer): ID của phòng ban cần lọc.
    # Ghi chú: Trả về JSON chứa danh sách vị trí công việc và thông tin phân trang.
    def get_positions
      search = params[:search]&.strip
      department_id = params[:department_id]

      positionjobs = Positionjob.select(:id, :name, :scode)
                                .joins(:department)
                                .where(departments: {id: department_id})
                                .where.not(positionjobs: {status: "INACTIVE"})
                                .order("name DESC")
      if search.present?
        positionjobs = positionjobs.where("LOWER(positionjobs.name) LIKE ?", "%#{search&.downcase}%")
      end
      # filter leader only
      keywords = ["trưởng", "giám đốc", "chủ tịch", "trưởng phòng","phó", "tổ"]
      positionjobs = positionjobs.select { |positionjob|  keywords.any?{ |key| positionjob.name&.downcase&.strip&.unicode_normalize(:nfc).include?(key) }}
      render json: { items: positionjobs }
    end

    def get_user_positions
      department_id = params[:department_id]
      user_id = params[:user_id]

      positionjobs = Positionjob.select("DISTINCT positionjobs.id, positionjobs.name,positionjobs.scode")
                  .joins("LEFT JOIN works ON positionjobs.id = works.positionjob_id")
                  .where(department_id: department_id)
                  .where("works.user_id = ? ",user_id)

      render json: { items: positionjobs }
    end

    # Tải cái biểu mẫu dạng PDF kèm chữ kí cho các bước phê duyệt có chức năng ký (sử dụng trong lib signdoc js)
    def load_signdoc
      signdoc_id = params[:signdoc_id]
      appointment_id = params[:id]
      status = params[:status]
      begin
        signdoc =  Signdoc.find(signdoc_id)
        template = signdoc.tmp_file
        exist_signs = Sign.where(signdoc_id: signdoc.id)
        data = get_signdoc_data(appointment_id)
        pdf = generate_pdf_file(template,exist_signs,signdoc_id,data)
        send_data pdf,  type: 'application/pdf',
                        disposition: 'attachment',
                        filename:"pdf_#{Time.now.strftime("%d%m%Y")}.pdf"
      rescue => exception
        position = exception.backtrace
        message = exception.message
        respond_to do |format|
          format.js   { render json: { error: exception.message,position: position }, status: 404 }
          format.html   { render json: { error: exception.message,position: position }, status: 404 }
        end
      end
    end

    private
    def set_appointment
      @appointment = Appointment.find_by(id: params[:id])
      if @appointment.nil?
        redirect_back fallback_location: root_path, alert: "Không tìm thấy bổ nhiệm này."
      end
    end

    def appointment_params
      params.permit(:title, :user_id, :stype, :priority, :new_dept, :new_position, :dtstart, :status,:is_survey, :note, :expected_appointment_date, :appointment_date, :probation_period, :trust_collection_period)
    end

    def sign_params
      params.permit(:nopage, :px, :py, :sheight, :signature_path, :signatureid, :swidth)
    end

    # Chức năng: Xác định bước hiện tại trong quy trình của cuộc hẹn dựa trên trạng thái xử lý (mandocuhandle).
    # Người xây dựng: Lê Ngọc Huy - 10/04/2025
    # Đầu vào: Không có tham số trực tiếp, hàm sử dụng biến instance:
    #   - @latest_handles (Hash): Hash chứa các xử lý mới nhất, được nhóm theo trạng thái (từ controller).
    # Ghi chú:
    #   - Nếu có xử lý đang thực hiện (PROCESS), trả về bước tương ứng.
    #   - Nếu không, tìm bước cuối cùng hoàn tất (DONE) và trả về bước tiếp theo, mặc định là 1 nếu không có bước nào hoàn tất.
    def determine_current_step
        current_handle = @latest_handles.values.find { |h| h&.sread == 'PROCESS' }
        return AppointmentStatusManagement::STEPS.find { |k, v| v[:status] == current_handle.status }&.first if current_handle

        last_done_step = AppointmentStatusManagement::STEPS.max_by { |k, v| @latest_handles[v[:status]]&.sread == 'DONE' ? k : -1 }
        last_done_step&.first&.positive? ? last_done_step.first + 1 : 1
    end

    def is_uhandle_valid?(mandocuhandle_id)
      mandocuhandle = Mandocuhandle.find_by(id:mandocuhandle_id)
      return mandocuhandle&.user_id == session[:user_id]
    end


    def create_new_appointment
      begin
        user_id = params[:user_id]
        priority = params[:priority]
        new_dept = params[:new_dept]
        new_position = params[:new_position]
        result = params[:result]
        note = params[:note]
        next_dept_id = params[:next_department_id].to_i
        user_handle_id = params[:user_handle_id]
        current_dept_id = session[:department_id]
        current_user_id = session[:user_id]
        expected_appointment_date = params[:expected_appointment_date]

        stype = params[:stype]
        status = nil

        if stype == "BO_NHIEM"
          status = find_status_by_step(2)
          title = "Bổ nhiệm #{params[:appointee_name]} vào vị trí #{params[:position_name]} tại phòng #{params[:department_name]}"
        else
          status = find_status_by_step(7)
          title = "Miễn nhiệm #{params[:appointee_name]} khỏi vị trí #{params[:position_name]} tại phòng #{params[:department_name]}"
        end
        ActiveRecord::Base.transaction do
          
          # 1. Tạo appointment
          @appointment = Appointment.create!(
            title: title,
            user_id: user_id,
            stype: stype,
            priority: priority,
            new_dept: new_dept,
            new_position: new_position,
            dtstart: Time.current,
            result: result,
            status: status,
            note: note,
            expected_appointment_date: expected_appointment_date
          )

          # 2. Tạo mandocs.
          # TODO: store org
          organization_id = Department.find(new_dept).organization_id
          mandoc_proposal = Mandoc.create!(appointment_id: @appointment.id, status: find_status_by_step(7),organization_id: organization_id)
          template_name = stype == "BO_NHIEM" ? "proposal_creation" : "proposal_creation_dismiss"
          Signdoc.create!(mandoc_id: mandoc_proposal.id, tmp_file: "#{template_name}.html.erb")

          # 3. Tạo mandocdhandle cho người tạo
          current_dhandle = create_mandocdhandle(mandoc_id: mandoc_proposal.id, department_id: current_dept_id)

          # 4. Tạo mandocuhandle cho người tạo
          create_mandocuhandle(
            mandocdhandle_id: current_dhandle.id,
            user_id: current_user_id,
            sread: "DONE",
            status: params[:status]
          )

          # 5. Tạo mandocdhandle cho phòng ban tiếp theo (nếu khác)
          next_dhandle = current_dhandle
          next_dhandle = create_mandocdhandle(mandoc_id: mandoc_proposal.id, department_id: next_dept_id) if current_dhandle.department_id.to_i != next_dept_id

          # 6. Tạo mandocuhandle cho người xử lý tiếp theo
          create_mandocuhandle(
            mandocdhandle_id: next_dhandle.id,
            user_id: user_handle_id,
            sread: "PROCESS",
            status: params[:next_status]
          )

          # 7. Render kết quả thành công
          @result = {
            success: true,
            message: "Đã tạo đề xuất thành công",
            redirect_url: appointments_path
          }
        end

        render json: @result, status: :created
      rescue StandardError => e
        render json: {
          success: false,
          message: "Không thể tạo đề xuất",
          errors: e.message
        }, status: :unprocessable_entity
      end
    end
end
