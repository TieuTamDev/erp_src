class Scheduleweek < ApplicationRecord
  belongs_to :user
  has_many :shiftselection, dependent: :destroy
end
