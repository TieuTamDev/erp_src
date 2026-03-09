class Mydoc < ApplicationRecord
    has_many :mydochis, dependent: :destroy
end
