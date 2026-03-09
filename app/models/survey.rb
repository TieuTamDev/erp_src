class Survey < ApplicationRecord
  has_many :qsurveys
  has_many :appointments
end
