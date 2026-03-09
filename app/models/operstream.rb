class Operstream < ApplicationRecord
  belongs_to :organization
  belongs_to :stream
  belongs_to :function

  
end
