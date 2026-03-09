class Revdoc < ApplicationRecord
  belongs_to :review
  belongs_to :mediafile
end
