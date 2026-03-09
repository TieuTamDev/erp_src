class Holiday < ApplicationRecord
  belongs_to :user, optional: true
  has_many :holdocs
  has_many :holdocs, dependent: :destroy
  has_many :mediafiles, through: :holdocs
  has_many :holpros
  has_many :holdetails
  # Hải 10/10/2025
  has_many :holdetails, dependent: :destroy
  has_many :holdocs, dependent: :destroy
  has_many :holpros, dependent: :destroy
  # scope :pagination_30_day_count, -> { where(status: "ACTIVE", created_at: (DateTime.now - 30.day)..DateTime.now).count }
  # scope :pagination_30_day_total, -> (per_page, holidayOffset) { where(status: "ACTIVE", created_at: (DateTime.now - 30.day)..DateTime.now).order(created_at: :desc).limit(per_page).offset(holidayOffset) }
end
