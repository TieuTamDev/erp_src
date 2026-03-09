class Signature < ApplicationRecord
  belongs_to :mediafile
  belongs_to :user
end
