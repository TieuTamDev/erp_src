module AppointmentsHelper
  include StreamConcern

  # cập nhật appointment
  def update_appointment(appointment_data)
    if params[:appointment_id].present?
      # Cập nhật Appointment hiện có
      @appointment = Appointment.find(params[:appointment_id])
      unless @appointment.update(appointment_data)
        raise ActiveRecord::Rollback, @appointment.errors.full_messages
      end
    else
      raise ActiveRecord::Rollback, "Missing params: appointment_id"
    end
    @appointment
  end

  def result_style(result)
    result = Appointment::RESULT_STYLES[:created] if result.nil?
    Appointment::RESULT_STYLES[result.to_sym]
  end

  def create_mandocdhandle(mandoc_id:, department_id:)
    Mandocdhandle.create(
      mandoc_id: mandoc_id,
      department_id: department_id
    )
  end

  def create_mandocuhandle(mandocdhandle_id:, user_id:, sread:, status:,contents: nil)
    Mandocuhandle.create(
      mandocdhandle_id: mandocdhandle_id,
      user_id: user_id,
      sread: sread,
      status: status,
      contents: contents
    )
  end

  def update_mandocuhandle(id:, srole:, sread:,contents: nil)
    mandocuhandle = Mandocuhandle.find(id)
    mandocuhandle.update(
      srole: srole,
      sread: sread,
      contents: contents
    )
    mandocuhandle
  rescue ActiveRecord::RecordNotFound
    nil
  end

  def create_sign(signdoc_id,sign)
    sign.merge!({
      signdoc_id:signdoc_id,
      signed_by: session[:user_id],
      signer_fn: session[:user_fullname],
    })
    Sign.create(sign)
  end

  def get_pre_uhandle(appointment_id,mandocuhandle_id)
    Mandocuhandle.select("mandocuhandles.*")
                  .joins(:mandocdhandle)
                  .joins(:mandoc)
                  .where("mandocs.appointment_id =  ?",appointment_id)
                  .where("mandocuhandles.id <  ?",mandocuhandle_id)
                  .order('mandocuhandles.id DESC').first&.user_id
  end

  def get_proposal_creation_id(appointment_id,status)
    ids = Mandocuhandle.select("mandocuhandles.*")
                  .joins(:mandocdhandle)
                  .joins(:mandoc)
                  .where("mandocs.appointment_id =  ?",appointment_id)
                  .where("mandocuhandles.status = ?",status)
                  .where("mandocuhandles.sread = ?","DONE")
                  .order('mandocuhandles.id ASC').pluck("mandocuhandles.user_id")
    return ids[1] if !ids[1].nil?
    return ids[0]
  end

  def send_procecss_notify(appointment_id,send_principal = false)
    user_ids = []
    appointment = Appointment.find(appointment_id)
    # # trưởng phó đơn vị
    # user_ids << get_department_deputy_leader(appointment&.new_dept)
    # # trưởng phó TCHC
    department_id = Mandocuhandle.select("mandocdhandles.department_id").joins(:mandocdhandle)
                                .joins(:mandoc)
                                .where("mandocs.appointment_id = ? ", appointment_id )
                                .find_by("mandocuhandles.status = ? ","proposal_creation")&.department_id
    user_ids << get_department_deputy_leader(department_id)

    if send_principal
      # BGH
      department_id = Mandocuhandle.select("mandocdhandles.department_id").joins(:mandocdhandle)
                              .joins(:mandoc)
                              .where("mandocs.appointment_id = ? ", appointment_id )
                              .find_by("mandocuhandles.status = ? ","principal_approval")&.department_id

      user_ids << User.select("users.id")
                  .joins(works: {positionjob: :department})
                  .where.not(users: {status: 'INACTIVE'})
                  .where(departments: {id: department_id}).pluck(:id)
    end
    user_ids = user_ids.uniq.flatten

    mandocuhandle = Mandocuhandle.joins(:mandocdhandle).joins(:mandoc).where("mandocs.appointment_id = ? ", appointment_id ).order("mandocuhandles.id ASC").last
    user_ids = user_ids.select{|item| item != mandocuhandle&.user_id}

    user_ids.each do |user_id|
      notify = Notify.create(
        title: I18n.t("appointment.#{appointment&.stype}", default: appointment&.stype).capitalize,
        contents: "#{appointment&.title} đã tới bước #{I18n.t("appointment.status.#{mandocuhandle&.status}", default: mandocuhandle&.status)}",
        receivers: "Hệ thống ERP",
        stype: appointment&.stype
      )
      Snotice.create(
        notify_id: notify.id,
        user_id: user_id,
        isread: false,
        username: appointment_id
      )
    end
  end

  def get_department_deputy_leader(department_id)
    user_ids = []
    all_users = User.select("users.id,positionjobs.name AS position_name")
                .joins(works: {positionjob: :department})
                .where.not(users: {status: 'INACTIVE'})
                .where(departments: {id: department_id})
    keywords = ["trưởng", "giám đốc", "chủ tịch", "trưởng phòng","phó", "tổ"]

    all_users.each do |user|
      if keywords.any?{ |key| user.position_name&.downcase&.strip&.unicode_normalize(:nfc).include?(key) }
        user_ids << user.id
      end
    end
    user_ids
  end

  def button_step_data(status,stype,result = nil)
    stream_scode = stype == "BO_NHIEM" ?  "SO-DO-BO-NHIEM" : "SO-DO-MIEN-NHIEM"
    button_data = stream_connect_by_status(stream_scode,status,result)
    button_data.each{|connect| connect[:forms] = connect[:status]}
  end

  def last_step_data(stype)
    stream_scode = stype == "BO_NHIEM" ?  "SO-DO-BO-NHIEM" : "SO-DO-MIEN-NHIEM"
    stream_last_connect(stream_scode)&.status
  end

  # get user login sign
  def user_sign
    user_id = session[:user_id_login]
    signature = Signature.joins(:mediafile).select('signatures.*, mediafiles.file_name as url')
                      .where('signatures.user_id = ?', user_id)
                      .where("signatures.isdefault = ?",true)
                      .order(created_at: :desc).first
    return {} if signature.nil?
    {
      id: signature.id,
      name: signature.name,
      user_name: session[:user_fullname],
      mediafile_id: signature.mediafile_id,
      user_id: signature.user_id,
      dtcreated: signature.dtcreated,
      isdefault: signature.isdefault,
      status: signature.status,
      note: signature.note,
      created_at: signature.created_at,
      updated_at: signature.updated_at,
      url: "#{request.base_url}/mdata/hrm/#{signature.url}",
    }
  end

  # signdoc for sign step
  def get_singdoc_id(appointment_id)
    Signdoc.select("signdocs.id")
               .joins("LEFT JOIN mandocs ON mandocs.id = signdocs.mandoc_id")
               .where("mandocs.appointment_id = ?",appointment_id ).first&.id
  end

  # Chức năng: Tìm số thứ tự của bước (step) trong quy trình dựa trên trạng thái (status).
  # Người xây dựng: Lê Ngọc Huy - 01/04/2025
  # Đầu vào:
  #   - status (String): Trạng thái cần tìm (ví dụ: 'PROCESS', 'DONE').
  # Ghi chú: Trả về số thứ tự bước (Integer) nếu tìm thấy, ngược lại trả về 0.
  def find_step_by_status(status)
    step = Appointment::STEPS.find { |_, s| s[:status] == status }
    step ? step[0] : 0
  end

  def find_status_by_step(step)
    Appointment::STEPS[step][:status]
  end

  def get_signdoc_data(appointment_id)
    mandoc = Mandoc.find_by(appointment_id: appointment_id)
    apply = Apply.where("user_id = #{@appointment.user_id}").order("created_at DESC")
    schools = School.where(apply_id: apply.first.id).order("created_at DESC")
    work = User.find(@appointment.user_id).works
               .where("positionjob_id IS NOT NULL").first
    current_position_job = !work&.positionjob.nil? ? work&.positionjob&.name : ""
    current_department = !work&.positionjob&.department.nil? ? work&.positionjob&.department&.name : ""
    {
      mandoc: mandoc,
      appointment: @appointment,
      schools: schools,
      current_position_job: current_position_job,
      current_department: current_department,
      status: ""
    }
  end

  # Handle survey step
  def update_status(appointment_id)
    success = true
    position = ""
    error_detail = ""
    ActiveRecord::Base.transaction do
      begin
        oAppointment = Appointment.find(appointment_id)
        uhandle = Mandocuhandle.joins(:mandocdhandle)
                      .joins(:mandoc)
                      .where("mandocs.appointment_id = ? ", appointment_id)
                      .where("mandocuhandles.status = ?",find_status_by_step(2)).first
    
        department_id =  uhandle.mandocdhandle.department_id
        user_id = uhandle.user_id
        oNewDhandle = Mandocdhandle.create({
          mandoc_id: oAppointment.mandocs.first.id ,
          department_id: department_id,
        })
    
        next_status = button_step_data(oAppointment.status,oAppointment.stype).first[:next_status]
        Mandocuhandle.create({
          mandocdhandle_id: oNewDhandle.id,
          user_id: user_id,
          sread: "PROCESS",
          status: next_status,
        })
        oAppointment.update(status:next_status)
      rescue => e
        position = e.backtrace.to_json.html_safe.gsub("\`","")
        success = false
        error_detail = e.message.gsub("\`","")
        message = "Lỗi khi cập nhật thông tin bổ nhiệm"
        raise ActiveRecord::Rollback
      end

      if !success
        Errlog.create({
          msg: error_detail,
          msgdetails: position,
          surl: request.fullpath,
          owner: "#{session[:user_id]}/#{session[:user_fullname]}",
          dtaccess: DateTime.now,
        })
      else
        send_procecss_notify(oAppointment.id,true)
      end
      
    end

    
  end

  def get_user_info (appointment)
    user_id = appointment.user_id
    user = User.find(user_id)
    apply = Apply.where("user_id = #{user_id}").order("created_at DESC")
    schools = School.where(apply_id: apply.first.id).order("created_at DESC")
    work_history = Company.where(apply_id: apply.first.id).order("created_at DESC")
    work = Work.where(user_id: user_id).first
    archives = Archive.where("user_id = #{user_id}").order("created_at DESC")
    works_stask = Work.where("user_id = #{user_id} AND positionjob_id IS NOT NULL")

    {
      user: user,
      schools: schools,
      work_history: work_history,
      archives: archives,
      works_stask: works_stask,
    }
  end

  def get_mediafiles (appointment)
    mediafiles =  Mandocfile.joins(:mandoc, :mediafile)
                            .select("mandocfiles.id,mediafiles.id as media_id, mediafiles.file_name, mediafiles.file_size, mediafiles.file_type, mediafiles.owner")
                            .where(mandocs: { appointment_id: appointment.id })
    {
      mediafiles: mediafiles,
    }
  end

  def store_appointment_files(appointment_id, files)
    mandoc_id = Mandoc.find_by(appointment_id:appointment_id)&.id
    created_media_ids = []
    begin
      if !mandoc_id.nil?
        files.each do |file|
          mediafile_id = upload_mediafile(file)
          created_media_ids << mediafile_id # lưu cho trường hợp rollback
          Mandocfile.create({
            mediafile_id:mediafile_id,
            mandoc_id: mandoc_id,
          })
        end
      end
    rescue => e
      created_media_ids.each do |id|
        Mandocfile.find_by(mediafile_id: id).destroy
        delete_mediadile(id)
      end
      raise e
    end
  end

  def remove_appointment_files(mediafile_ids)
    mediafile_ids = mediafile_ids.split(",")
    mediafile_ids.each do |id|
      Mandocfile.find_by(mediafile_id: id).destroy
      delete_mediadile(id)
    end
  end

  def is_user_deputy(user_id,department_id)
    keyword = "Phó"
    not_keyword = "Phó Hiệu trưởng"
    position_names = Work.select("positionjobs.name")
        .joins("LEFT JOIN positionjobs ON positionjobs.id = works.positionjob_id")
        .where(user_id:user_id)
        .where("positionjobs.department_id = ?",department_id)
        .pluck(:name)
    
    has_keyword = position_names.any? { |name|
        name.downcase&.strip&.unicode_normalize(:nfc).include?(keyword.downcase)
      }
    has_not_keyword = position_names.any? { |name|
        name.downcase&.strip&.unicode_normalize(:nfc).include?(not_keyword.downcase)
      }
    has_keyword && !has_not_keyword
  end

  def get_assign_users(department_id,b_deputy,search)
    if b_deputy 
      keywords = ["Phó"]
      not_keywords = ["Phó Hiệu trưởng"]
    else
      keywords = ["Trưởng", "Trưởng", "Giám đốc", "Chủ tịch", "Trưởng phòng"]
      not_keywords = ["Phó", "Tổ"]
    end

    all_users = User.select("users.id, users.last_name, users.first_name, users.email, users.sid, users.status, positionjobs.name AS position_name")
                    .joins(works: {positionjob: :department})
                    .where.not(users: {status: 'INACTIVE'})
                    .where(departments: {id: department_id})
                    .order("CONCAT(users.last_name,' ', users.first_name) ASC")
                    .distinct

    if search.present?
      all_users = all_users.where(
        "LOWER(CONCAT(users.last_name,' ', users.first_name)) LIKE ? OR users.sid LIKE ?",
        "%#{search&.downcase}%",
        "%#{search}%"
      )
    end

    users = all_users.select do |user|
      position_name = user.position_name.downcase.strip
      has_keyword = keywords.any? { |word|
        position_name.include?(word.downcase.strip)
      }
      has_not_keyword = not_keywords.any? { |not_word|
        position_name.include?(not_word.downcase.strip)
      }

      has_keyword && !has_not_keyword
    end
    users
  end

end
