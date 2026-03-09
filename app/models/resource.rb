class Resource < ApplicationRecord
    has_many :accesses, dependent: :destroy
end
