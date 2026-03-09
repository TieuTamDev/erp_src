class EvaluationSummaryController < ApplicationController
  before_action :set_appointment, only: [:index, :detail, :export_summary_report]
  include AppointmentsHelper

  TAB_NAME = {
    summary_of_price_reviews: "summary_of_price_reviews",
    review_details: "review_details"
  }.freeze

  # Mô tả: Hiển thị thông tin tổng quan hoặc chi tiết đánh giá dựa trên tab được chọn
  # - Xác định tab hiện tại và xử lý logic tương ứng (summary_of_price_reviews hoặc review_details)
  # Lê Ngọc Huy - 03/04/2025
  def index
    @tabs = TAB_NAME
    @current_tab = params[:tab] || TAB_NAME[:summary_of_price_reviews]
    @form_data = {
      appointment_id: @appointment.id,
      status: @appointment.status,
      mandocuhandle_id: @mandocuhandle&.id,
      stream_datas: []
    }
    next_status = button_step_data(@appointment.status,@appointment.stype).first[:next_status]
    @form_data[:next_status] = next_status
    @form_data[:stream_datas] = button_step_data(next_status,@appointment.stype)

    appointsurveys = Appointsurvey.where(appointment_id: @appointment.id)
                                 .select(:id, :dtfinished)
    case @current_tab
    when TAB_NAME[:summary_of_price_reviews]
      process_summary_of_price_reviews(appointsurveys)
    when TAB_NAME[:review_details]
      process_review_details
    end
  end

  # Mô tả: Hiển thị thông tin tổng quan hoặc chi tiết theo ví trí công việc cho phiếu khảo sát ý kiến tín nhiệm
  # - Thông tin đánh giá tổng quan người đồng ý, không đồng ý, chưa thực hiện theo ví trí công việc
  # Lê Ngọc Huy - 03/04/2025
  def detail
    appointsurveys = Appointsurvey.where(appointment_id: @appointment.id)
                                  .select(:id, :dtfinished)
    process_ratio_review(appointsurveys)
  end

  # Mô tả: Chức năng xuất file báo cáo tổng hợp
  # Lê Ngọc Huy - 03/04/2025
  def export_summary_report
    file_name = "Báo cáo đánh giá tín nhiệm #{@appointment&.user&.last_name} #{@appointment&.user&.first_name}"

    oGsurveys = Gsurvey.joins(qsurveys: { surveyrecords: :appointsurvey })
                       .where(appointsurveys: { appointment_id: @appointment.id })
                       .order('gsurveys.iorder ASC, gsurveys.created_at ASC')
                       .distinct
                       .select(:id, :iorder, :created_at, :name)

    oSurveys = oGsurveys.map.with_index do |gsurvey, index|
        {
          index: to_roman(index + 1),
          gsurvey_name: gsurvey.name,
          questions_multiple: Qsurvey.get_questions_with_gsurvey(gsurvey.id, @appointment.id).map {|qsurvey|
            {
              qsurvey_name: qsurvey.content,
              answers: qsurvey.oqsurveries.order(iorder: :asc).map {|oqsurverie|
                  oSurveyrecord = Surveyrecord.joins(:appointsurvey, :qsurvey)
                                  .where(
                                    appointsurveys: {appointment_id: @appointment.id},
                                    qsurveys: {gsurvey_id: gsurvey.id, stype: "multiple_choice"},
                                    surveyrecords: {qsurvey_id: qsurvey.id}
                                  )
                  counts = oSurveyrecord.where(surveyrecords: {answer: oqsurverie.id}).count
                  total = oSurveyrecord.count
                  {
                      name: oqsurverie.optvalue,
                      rotate: calculate_percentage(counts, total)
                  }
              }
            }
          },
          answer_orthers: Surveyrecord.get_answers_orther(@appointment.id, gsurvey.id),
        }
    end

    appointsurveys = Appointsurvey.where(appointment_id: @appointment.id)
                                 .select(:id, :dtfinished)

    html_content = render_to_string(
        template: 'evaluation_summary/pdf_templates/survey_report_template',
        layout: false,
        locals: {
          file_name: file_name,
          surveys: oSurveys,
          no_mandoc: Mandoc.find_by(appointment_id: @appointment.id, status: "evaluation_preparation")&.sno,
          appointment: @appointment,
          total: appointsurveys.size,
          rotate: calculate_percentage(appointsurveys.where.not(dtfinished: nil).size, appointsurveys.size),
          count_attend: appointsurveys.where.not(dtfinished: nil).size,
          count_peer: appointsurveys.where.not(dtfinished: nil).size,
          rotate_attend: appointsurveys.where.not(dtfinished: nil).size,
          rotate_peer: appointsurveys.where.not(dtfinished: nil).size,
          approved: {
            count: appointsurveys.where(result: 'approved').where.not(dtfinished: nil).size,
            rotate_attend: calculate_percentage(appointsurveys.where(result: 'approved').where.not(dtfinished: nil).size, appointsurveys.where.not(dtfinished: nil).size),
            rotate_total: calculate_percentage(appointsurveys.where(result: 'approved').where.not(dtfinished: nil).size, appointsurveys.size)
          },
          rejected: {
            count: appointsurveys.where('dtfinished is NULL OR result = "rejected"').size,
            rotate_attend: calculate_percentage(appointsurveys.where('dtfinished is NULL OR result = "rejected"').size, appointsurveys.where.not(dtfinished: nil).size),
            rotate_total: calculate_percentage(appointsurveys.where('dtfinished is NULL OR result = "rejected"').size, appointsurveys.size)
          },
          evaluation_summary: appointsurveys.get_info_evaluation,
        }
    )

    pdf = WickedPdf.new.pdf_from_string(
        html_content,
        footer: {
          center: '[page]',
          font_size: 10,
          line: false,
        },
        margin: {
            top: 20,
            bottom: 20,
            left: 30,
            right: 20
        }
    )

    file_path = "/data/sftraining/tmp/#{file_name}.pdf"

    File.open(file_path, 'wb') do |file|
        file << pdf
    end

    send_file(file_path, type: 'application/pdf', disposition: 'inline') do
        File.delete(file_path) if File.exist?(file_path)
    end
  end

  private
  # Mô tả: Tìm và gán đối tượng Appointment dựa trên appointment_id từ params
  # - Được gọi trước action index để đảm bảo @appointment luôn có giá trị
  # Lê Ngọc Huy - 03/04/2025
  def set_appointment
    @appointment = Appointment.find(params[:appointment_id])
    @mandocuhandle = Mandocuhandle.find_by(id: params[:mandocuhandle_id], sread: "PROCESS") if params[:mandocuhandle_id].present?
  end

  # Mô tả: Xử lý dữ liệu cho tab summary_of_price_reviews
  # - Tính toán tổng số, số tham gia, và thông tin đánh giá tổng quan
  # - Gán dữ liệu cho gon để sử dụng trong JavaScript
  # Lê Ngọc Huy - 03/04/2025
  def process_summary_of_price_reviews(appointsurveys)
    total = appointsurveys.size
    attend = appointsurveys.where.not(dtfinished: nil).size
    evaluation_summary = appointsurveys.get_info_evaluation

    @resultAppointSurvey = {
      total: total,
      attend: attend,
      evaluation_summary: evaluation_summary
    }

    gon.approval_rate = build_approval_rate(evaluation_summary)
    gon.approval_rate_by_group = build_approval_rate_by_group(evaluation_summary)
  end

  # Mô tả: Xử lý dữ liệu cho trang detail
  # - Tính toán tổng số, số tham gia, và thông tin đánh giá tổng quan người đồng ý, không đồng ý, chưa thực hiện theo ví trí công việc
  # Lê Ngọc Huy - 03/04/2025
  def process_ratio_review(appointsurveys)
    @resultAppointSurvey = {
      evaluation_summary: appointsurveys.get_info_evaluation
    }
  end

  # Mô tả: Xây dựng dữ liệu tỷ lệ phê duyệt tổng quan
  # - Trả về hash chứa nhãn và dữ liệu tổng hợp (đồng ý, không đồng ý, chưa đánh giá)
  # Lê Ngọc Huy - 03/04/2025
  def build_approval_rate(evaluation_summary)
    return {} unless evaluation_summary.present?

    {
      label: ['Đồng ý', 'Không đồng ý', 'Chưa tham gia đánh giá'],
      data: [
        evaluation_summary.sum { |item| item[:approves][:total] },
        evaluation_summary.sum { |item| item[:rejects][:total] },
        evaluation_summary.sum { |item| item[:pendings][:total] }
      ]
    }
  end

  # Mô tả: Xây dựng dữ liệu tỷ lệ phê duyệt theo nhóm
  # - Trả về hash chứa nhãn và tỷ lệ phần trăm theo từng nhóm (đồng ý, không đồng ý)
  # Lê Ngọc Huy - 03/04/2025
  def build_approval_rate_by_group(evaluation_summary)
    return {} unless evaluation_summary.present?

    {
      label: evaluation_summary.map { |item| item[:positionjob_name] },
      data: {
        approve: evaluation_summary.map { |item| calculate_percentage(item[:approves][:total], item[:attend]) },
        reject: evaluation_summary.map { |item| calculate_percentage(item[:rejects][:total], item[:attend]) }
      }
    }
  end

  # Mô tả: Tính toán tỷ lệ phần trăm dựa trên giá trị và tổng
  # - Tránh lỗi chia cho 0 và trả về giá trị phần trăm đã làm tròn
  # Lê Ngọc Huy - 03/04/2025
  def calculate_percentage(value, total)
    total.to_i.zero? ? 0 : ((value.to_f / total) * 100).round
  end

  # Mô tả: Xử lý dữ liệu cho tab review_details
  # - Tạo đường dẫn chart, lấy danh sách Gsurvey và xây dựng dữ liệu biểu đồ
  # - Hỗ trợ response dạng HTML và JSON
  # Lê Ngọc Huy - 03/04/2025
  def process_review_details
    gon.path_chart = appointment_evaluation_summary_index_path(
      @appointment,
      tab: TAB_NAME[:review_details],
      format: :json
    )

    oGsurveys = Gsurvey.joins(qsurveys: { surveyrecords: :appointsurvey })
                       .where(appointsurveys: { appointment_id: @appointment.id })
                       .order('gsurveys.iorder ASC, gsurveys.created_at ASC')
                       .distinct
                       .select(:id, :iorder, :created_at, :name)

    @chartData = oGsurveys.map do |gsurvey|
      build_chart_data(gsurvey)
    end

    respond_to do |format|
      format.html
      format.json { render json: @chartData }
    end
  end

  # Mô tả: Xây dựng dữ liệu chi tiết cho biểu đồ của từng Gsurvey
  # - Trả về hash chứa câu hỏi và nhãn trả lời kèm số lượng lựa chọn câu trả lời đó
  # Lê Ngọc Huy - 03/04/2025
  def build_chart_data(gsurvey)
    questions_multiple = Qsurvey.get_questions_with_gsurvey(gsurvey.id, @appointment.id)
    {
      gsurvey_name: gsurvey.name,
      questions_multiple: questions_multiple.pluck(:content),
      answer_orthers: Surveyrecord.get_answers_orther(@appointment.id, gsurvey.id),
      answer_labels: Oqsurvery.get_answer_labels(gsurvey.id, @appointment.id).map do |oqsurvery|
        {
          id: oqsurvery.id,
          name: oqsurvery.optvalue,
          count: questions_multiple.pluck(:id).map do |qsurvery_id|
            Surveyrecord.get_count_with_qsurvery(@appointment.id, gsurvey.id, oqsurvery.id, qsurvery_id)
          end
        }
      end
    }
  end

  def to_roman(num)
    return '' if num <= 0
    roman_values = [
      [1000, 'M'], [900, 'CM'], [500, 'D'], [400, 'CD'],
      [100, 'C'], [90, 'XC'], [50, 'L'], [40, 'XL'],
      [10, 'X'], [9, 'IX'], [5, 'V'], [4, 'IV'], [1, 'I']
    ]
    result = ''
    roman_values.each do |value, symbol|
      while num >= value
        result += symbol
        num -= value
      end
    end
    result
  end
end
