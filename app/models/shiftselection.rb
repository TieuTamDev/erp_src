class Shiftselection < ApplicationRecord
  belongs_to :workshift
  belongs_to :scheduleweek
  has_one    :attend, dependent: :nullify
  has_many :shiftissue
end
