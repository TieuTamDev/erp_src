class Work < ApplicationRecord
  belongs_to :user
  belongs_to :positionjob
  belongs_to :stask
  has_many :stasks
end
