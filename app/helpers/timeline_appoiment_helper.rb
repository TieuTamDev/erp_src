module TimelineAppoimentHelper
  # Chức năng: Tạo và hiển thị một biểu tượng (icon) trên dòng thời gian dựa trên trạng thái của bước xử lý.
  # Người xây dựng: Lê Ngọc Huy
  # Đầu vào:
  #   - status_flags (Hash): Hash chứa các cờ trạng thái (completed, current, not_processed) để xác định trạng thái hiện tại.
  def render_timeline_icon(status_flags)
    base_classes = 'timeline-icon icon-item icon-item-lg border-300'
    bg_class, text_class = icon_styles(status_flags)
    icon_class = icon_symbol(status_flags)

    content_tag(:div, class: "#{base_classes} #{bg_class} #{text_class}") do
      content_tag(:span, '', class: icon_class)
    end
  end

  # Chức năng: Trả về các lớp CSS áp dụng cho nội dung và viền của một mục trên dòng thời gian dựa trên trạng thái.
  # Người xây dựng: Lê Ngọc Huy
  # Đầu vào:
  #   - status_flags (Hash): Hash chứa các trạng thái (completed, not_processed, current) để quyết định lớp CSS.
  def timeline_classes(status_flags)
    {
      content: case
               when status_flags[:skip] then 'br-skip'
               when status_flags[:stoped] then 'br-not-processed'
               when status_flags[:completed] then 'br-completed'
               when status_flags[:not_processed] then 'br-not-processed'
               when status_flags[:current] then 'br-current'
               else ''
               end,
      border: (status_flags[:current] || status_flags[:completed] || status_flags[:not_processed] || status_flags[:skip]) ? 'border-bottom pb-2 pt-0 mb-2' : ''
    }
  end

  # Chức năng: Hiển thị thông tin người dùng (tên, chức vụ, phòng ban) liên quan đến bước xử lý trên dòng thời gian.
  # Người xây dựng: Lê Ngọc Huy
  # Đầu vào:
  #   - latest_handle (Object): Đối tượng chứa thông tin xử lý gần nhất, có thể liên kết đến user.
  #   - status_flags (Boolean): Trạng thái của bước hiện tại.
  def render_user_info(latest_handle, status_flags)
    return '' if status_flags[:future] || latest_handle.nil?

    user = latest_handle.user
    work = user&.works&.find { |w| w.positionjob_id.present? }
    positionjob = work&.positionjob
    return '' unless positionjob || user

    user_info = {
      # 'Phòng ban' => positionjob&.department&.name, # Lấy tên phòng ban
      # 'Chức vụ' => positionjob&.name, # Lấy tên vị trí công việc
      'Người xử lý' => content_tag(:strong, "#{user&.last_name} #{user&.first_name} (#{user&.sid})", class: 'ms-2')
    }
    user_info['Lý do từ chối'] = content_tag(:strong, latest_handle&.contents.to_s.gsub(/\r\n|\r|\n/, '<br>').html_safe, class: 'ms-2') if (status_flags&.dig(:current) || status_flags&.dig(:stoped)) && latest_handle&.contents.present?
    safe_join(user_info.map do |label, value|
      next unless value
      content_tag(:p, class: 'fs-10 mb-1 mt-2') do
        safe_join([label + ': ', value])
      end
    end.compact)
  end

  # Chức năng: Hiển thị thông tin khảo sát của các phòng ban liên quan đến appointment
  # Người xây dựng: Lê Ngọc Huy
  # Đầu vào: Không có tham số trực tiếp, sử dụng biến instance @appointment (Object) chứa thông tin appointment
  def render_department_surveys
    return '' unless @appointment&.appointsurveys.present?

    surveys = @appointment.appointsurveys
    safe_join([
      # content_tag(:p, class: 'fs-10 mt-2 mb-1') { "Phòng ban: #{content_tag(:strong, surveys.get_users_name&.join(', '), class: 'ms-2')}".html_safe }, # Lấy danh sách tên nhân sự
      content_tag(:p, class: 'fs-10 mb-1 mt-2') { "Đã thực hiện: #{content_tag(:strong, surveys.count_users_complete, class: 'ms-2')}".html_safe }
    ])
  end

  # Chức năng: Tạo nút hoặc nhãn trạng thái (badge) trên dòng thời gian dựa trên trạng thái của bước.
  # Người xây dựng: Lê Ngọc Huy
  # Đầu vào:
  #   - entity (Object): Đối tượng đại diện cho bước xử lý hoặc khảo sát.
  #   - status_flags (Hash): Hash chứa các cờ trạng thái (current, completed, not_processed).
  #   - step_info (Hash): Thông tin chi tiết về bước hiện tại.
  #   - type (Symbol, mặc định :status): Loại xử lý (:status hoặc :survey).
  def render_timeline_button(entity, status_flags, step_info, type: :status)
    content_tag(:div, class: (status_flags[:current] || status_flags[:completed] || status_flags[:not_processed]) ? 'mt-2 pt-1' : '') do
      case
      when status_flags[:current]
        render_current_button(entity, step_info, type)
      when status_flags[:skip]
        content_tag(:div, content_tag(:span, 'Bỏ qua', class: 'badges badges-warning'), class: 'w-100 text-end')
      when status_flags[:stoped]
        content_tag(:div, content_tag(:span, 'Hoàn tất', class: 'badges badges-success'), class: 'w-100 text-end')
      when status_flags[:completed]
        render_current_button(entity, step_info, type, 'Hoàn tất', 'badges badges-success')
      when status_flags[:not_processed] && type == :survey
        content_tag(:div, content_tag(:span, 'Chưa xử lý', class: 'badges badges-danger'), class: 'w-100 text-end')
      when (type == :status && entity&.sread == 'PENDING') || (type == :survey && !entity.nil? && entity&.dtfinished.nil?)
        content_tag(:div, content_tag(:span, 'Chờ xử lý', class: 'badges badges-warning'), class: 'w-100 text-end')
      end
    end
  end

  # Chức năng: Xác định các cờ trạng thái cho một bước cụ thể trên dòng thời gian.
  # Người xây dựng: Lê Ngọc Huy
  # Đầu vào:
  #   - step_number (Integer): Số thứ tự của bước.
  #   - step_info (Hash): Thông tin chi tiết về bước (bao gồm status).
  #   - latest_handle (Object): Đối tượng xử lý gần nhất.
  #   - appointsurvey (Object): Đối tượng khảo sát liên quan (có thể là nil).
  def status_flags_for_step(step_number, step_info, latest_handle, appointsurvey)
    step_skip = ['evaluation_preparation', 'evaluation', 'evaluation_summary', "department_approval", "proposal_creation"]
    if step_info[:status] == 'evaluation'
      appointsurvey.nil? ? basic_status_flags(step_number) : survey_status_flags(step_number, appointsurvey)
    else
      {
        skip: step_skip.include?(step_info[:status]) && (@appointment&.is_survey == "NO" || @appointment&.is_survey == nil) && latest_handle.nil? && step_number < @current_step,
        stoped: step_info[:status] == "principal_approval" && @appointment&.result == "stoped" && step_number < @current_step,
        completed: latest_handle&.sread == 'DONE' && step_number < @current_step,
        current: latest_handle&.sread == 'PROCESS' && step_number == @current_step,
        future: step_number > @current_step
      }
    end
  end

  private

  # Chức năng: Trả về cặp lớp CSS cho màu nền (bg_class) và màu chữ (text_class) của biểu tượng dựa trên trạng thái.
  # Người xây dựng: Lê Ngọc Huy
  # Đầu vào:
  #   - status_flags (Hash): Hash chứa các trạng thái (completed, current, not_processed).
  def icon_styles(status_flags)
    case
    when status_flags[:skip] then ['bg-warning', 'text-white']
    when status_flags[:stoped] then ['bg-danger', 'text-white']
    when status_flags[:completed] then ['bg-success', 'text-white']
    when status_flags[:current]   then ['bg-primary', 'text-white']
    when status_flags[:not_processed] then ['bg-danger', 'text-white']
    else ['bg-white', 'text-default']
    end
  end

  # Chức năng: Trả về lớp CSS của biểu tượng FontAwesome dựa trên trạng thái.
  # Người xây dựng: Lê Ngọc Huy
  # Đầu vào:
  #   - status_flags (Hash): Hash chứa các trạng thái (completed, current).
  def icon_symbol(status_flags)
    status_flags[:skip] ? 'fas fa-random' :
    status_flags[:stoped] ? 'fas fa-ban' :
    status_flags[:completed] ? 'fas fa-check' :
    status_flags[:not_processed] ? 'fas fa-user-clock' :
    status_flags[:current] ? 'far fa-clock' : 'fas fa-user'
  end

  # Chức năng: Hiển thị nút hành động và nhãn "Đang xử lý" cho bước hiện tại.
  # Người xây dựng: Lê Ngọc Huy
  # Đầu vào:
  #   - entity (Object): Đối tượng bước hoặc khảo sát.
  #   - step_info (Hash): Thông tin chi tiết về bước.
  #   - type (Symbol): Loại xử lý (:status hoặc :survey).
  def render_current_button(entity, step_info, type, status = 'Đang xử lý', class_color = 'badges badges-warning')
    content_tag(:div, class: 'w-100 d-flex justify-content-between align-items-center') do
      buttons = case
                when (type == :status && entity&.user_id == session[:user_id] && entity.sread != "DONE") || (type == :survey && !entity.nil? && entity&.status == "ASSIGN")
                  render(partial: 'appointments/buttons/uhandle_buttons', locals: { is_survey: @appointment.is_survey == "YES", step_info: step_info, appointment_id: @appointment&.id, mandocuhandle_id: type == :status ? entity&.id : nil })
                when (type == :status && step_info[:status] == 'created' && status == 'Hoàn tất')
                  step_info_temp = step_info.dup
                  step_info_temp[:status] = 'created_preview'
                  render(partial: 'appointments/buttons/uhandle_buttons', locals: { is_survey: @appointment.is_survey == "YES", step_info: step_info_temp, appointment_id: @appointment&.id})
                when (type == :status && step_info[:status] == 'proposal_creation' && status == 'Hoàn tất')
                  step_info_temp = step_info.dup
                  step_info_temp[:status] = 'proposal_creation_preview'
                  render(partial: 'appointments/buttons/uhandle_buttons', locals: { is_survey: @appointment.is_survey == "YES", step_info: step_info_temp, appointment_id: @appointment&.id})
                when (type == :survey && step_info[:status] == 'evaluation')
                  step_info_temp = step_info.dup
                  step_info_temp[:status] = 'evaluation_preview'
                  render(partial: 'appointments/buttons/uhandle_buttons', locals: { is_survey: @appointment.is_survey == "YES", step_info: step_info_temp, appointment_id: @appointment&.id})
                else
                  nil
                end
      safe_join([buttons, content_tag(:div, ''), content_tag(:span,  status, class: class_color)].compact)
    end
  end

  # Chức năng: Trả về các cờ trạng thái cơ bản cho một bước.
  # Người xây dựng: Lê Ngọc Huy
  # Đầu vào:
  #   - step_number (Integer): Số thứ tự của bước.
  def basic_status_flags(step_number)
    {
      skip: (@appointment&.is_survey == "NO" || @appointment&.is_survey == nil) && step_number < @current_step,
      completed: step_number < @current_step,
      current: step_number == @current_step,
      future: step_number > @current_step
    }
  end

  # Chức năng: Trả về các cờ trạng thái cho bước khảo sát.
  # Người xây dựng: Lê Ngọc Huy
  # Đầu vào:
  #   - step_number (Integer): Số thứ tự của bước.
  #   - appointsurvey (Object): Đối tượng khảo sát.
  def survey_status_flags(step_number, appointsurvey)
    {
      skip: (@appointment&.is_survey == "NO" || @appointment&.is_survey == nil) && step_number < @current_step,
      completed: appointsurvey.dtfinished.present? || step_number < @current_step,
      not_processed: appointsurvey.dtfinished.nil? && step_number < @current_step,
      current: appointsurvey.dtfinished.nil? && step_number == @current_step,
      future: step_number > @current_step
    }
  end
end
