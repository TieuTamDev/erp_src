class Attenddetail < ApplicationRecord
  belongs_to :attend, foreign_key: :attend_id
end
