class Surveyrecord < ApplicationRecord
  belongs_to :qsurvey
  belongs_to :appointsurvey 
  
  # Đếm số lượng lựa chọn theo câu hỏi
  def self.get_count_with_qsurvery(appointment_id, gsurvey_id, iorder, qsurvery_id)
    joins(:appointsurvey, :qsurvey)
    .joins("INNER JOIN oqsurveries ON oqsurveries.id = surveyrecords.answer")
    .where(
      appointsurveys: {appointment_id: appointment_id}, 
      qsurveys: {gsurvey_id: gsurvey_id, stype: "multiple_choice"}, 
      oqsurveries: {iorder: iorder}, 
      surveyrecords: {qsurvey_id: qsurvery_id}
    )
    .count
  end

  # Lấy danh sách câu trả lời khác
  def self.get_answers_orther(appointment_id, gsurvey_id)
    joins(:appointsurvey)
    .where(
      appointsurveys: {appointment_id: appointment_id}, 
      surveyrecords: {qsurvey_id: nil, answer: gsurvey_id}
    )
    .select(:id, :note)
  end
end
