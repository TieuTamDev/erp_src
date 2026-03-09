class Holprosdetail < ApplicationRecord
  belongs_to :holpro, class_name: "Holpro", foreign_key: :holpros_id
  belongs_to :holtype, foreign_key: :sholtype, primary_key: :code, optional: true 
end
