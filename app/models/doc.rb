class Doc < ApplicationRecord
  belongs_to :user
  belongs_to :mediafile
end
