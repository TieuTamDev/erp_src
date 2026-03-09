class Organization < ApplicationRecord
    has_many :uorgs
    has_many :users, through: :uorgs
end
