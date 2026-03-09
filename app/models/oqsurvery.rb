class Oqsurvery < ApplicationRecord
  belongs_to :qsurvey

  # Lấy danh sách các đáp án theo nhóm
  def self.get_answer_labels(gsurvey_id, appointment_id)
    select('oqsurveries.iorder as id, oqsurveries.optvalue')
    .joins(qsurvey: {survey: :appointments})
    .where(qsurveys: { gsurvey_id: gsurvey_id, stype: "multiple_choice" }, appointments: { id: appointment_id })
    .group(:iorder, :optvalue)
  end
end
