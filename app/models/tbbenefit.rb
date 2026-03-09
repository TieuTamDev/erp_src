class Tbbenefit < ApplicationRecord
  has_many :sbenefit, :dependent => :delete_all 
 
end
