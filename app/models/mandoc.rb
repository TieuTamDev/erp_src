class Mandoc < ApplicationRecord 
    has_many :mandocuhandles, through: :mandocdhandles
    has_many :mandocfile, dependent: :destroy
    has_many :mandocdhandles, dependent: :destroy
    belongs_to :appointment
    belongs_to :holpro, class_name: 'Holpro', foreign_key: :holpros_id, optional: true
end 