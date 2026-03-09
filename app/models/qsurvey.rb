class Qsurvey < ApplicationRecord
  belongs_to :survey
  belongs_to :gsurvey
  has_many :oqsurveries, dependent: :destroy
  has_many :surveyrecords
  
  # Lấy danh sách câu hỏi theo nhóm gsurvey
  def self.get_questions_with_gsurvey(gsurvey_id, appointment_id)
    joins(survey: :appointments)
    .where(qsurveys: {gsurvey_id: gsurvey_id, stype: "multiple_choice"}, appointments: {id: appointment_id})
    .distinct
  end
end
