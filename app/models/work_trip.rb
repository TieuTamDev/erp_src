class WorkTrip < ApplicationRecord
  belongs_to :user
  belongs_to :approved_by_user, class_name: 'User', foreign_key: 'approved_by', optional: true
  
  has_many :trip_dates, dependent: :destroy
  has_many :shiftselections, through: :trip_dates
  has_many :shiftissues, through: :shiftselections

  accepts_nested_attributes_for :trip_dates, allow_destroy: true

  validates :destination, presence: true, length: { maximum: 255 }
  validates :purpose, presence: true, length: { maximum: 1000 }
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :transportation, presence: true
  validates :approved_by, presence: true
  validates :status, inclusion: { in: %w[PENDING APPROVED REJECTED] }
  
  validate :end_date_after_start_date
  validate :dates_not_in_past, on: :create
  validate :has_trip_dates

  scope :pending, -> { where(status: 'PENDING') }
  scope :approved, -> { where(status: 'APPROVED') }
  scope :rejected, -> { where(status: 'REJECTED') }
  scope :for_user, ->(user_id) { where(user_id: user_id) }
  scope :for_approver, ->(approver_id) { where(approved_by: approver_id) }
  scope :in_date_range, ->(start_date, end_date) { where(created_at: start_date..end_date) }

  def duration_days
    return 0 unless start_date && end_date
    (end_date - start_date).to_i + 1
  end

  def can_be_edited?
    status == 'PENDING'
  end

  def can_be_cancelled?
    status == 'PENDING'
  end

  def can_be_approved?
    status == 'PENDING' && approved_by.present?
  end

  def can_be_rejected?
    status == 'PENDING' && approved_by.present?
  end

  def status_text
    case status
    when 'PENDING'
      'Chờ duyệt'
    when 'APPROVED'
      'Đã duyệt'
    when 'REJECTED'
      'Bị từ chối'
    else
      'Không xác định'
    end
  end

  def status_class
    case status
    when 'PENDING'
      'warning'
    when 'APPROVED'
      'success'
    when 'REJECTED'
      'danger'
    else
      'secondary'
    end
  end

  def total_estimated_cost
    estimated_cost || 0
  end

  def formatted_cost
    return 'Chưa có' if estimated_cost.blank?
    ActionController::Base.helpers.number_to_currency(estimated_cost, unit: 'VND', precision: 0)
  end

  def transportation_text
    case transportation
    when 'plane'
      'Máy bay'
    when 'train'
      'Tàu hỏa'
    when 'bus'
      'Xe khách'
    when 'car'
      'Ô tô'
    when 'motorbike'
      'Xe máy'
    else
      transportation&.humanize || 'Không xác định'
    end
  end

  def accommodation_text
    case accommodation
    when 'hotel'
      'Khách sạn'
    when 'guesthouse'
      'Nhà nghỉ'
    when 'homestay'
      'Homestay'
    when 'company_accommodation'
      'Chỗ ở công ty'
    when 'none'
      'Không cần'
    else
      accommodation&.humanize || 'Không xác định'
    end
  end

  def self.statistics(start_date = 1.month.ago, end_date = Date.current)
    trips = in_date_range(start_date, end_date)
    
    {
      total: trips.count,
      pending: trips.pending.count,
      approved: trips.approved.count,
      rejected: trips.rejected.count,
      total_cost: trips.approved.sum(:estimated_cost) || 0,
      average_duration: trips.approved.average(:duration_days) || 0
    }
  end

  def self.by_destination(destination)
    where('destination ILIKE ?', "%#{destination}%")
  end

  def self.by_status(status)
    where(status: status)
  end

  def self.by_user(user_id)
    where(user_id: user_id)
  end

  def self.by_approver(approver_id)
    where(approved_by: approver_id)
  end

  def self.by_date_range(start_date, end_date)
    where(start_date: start_date..end_date)
  end

  def self.export_to_csv(trips)
    CSV.generate(headers: true) do |csv|
      csv << [
        'Mã nhân viên', 'Tên nhân viên', 'Điểm đến', 'Mục đích', 
        'Ngày bắt đầu', 'Ngày kết thúc', 'Số ngày', 'Phương tiện',
        'Chỗ ở', 'Chi phí dự kiến', 'Trạng thái', 'Ngày tạo'
      ]
      
      trips.includes(:user).each do |trip|
        csv << [
          trip.user.sid,
          trip.user.full_name,
          trip.destination,
          trip.purpose,
          trip.start_date.strftime('%d/%m/%Y'),
          trip.end_date.strftime('%d/%m/%Y'),
          trip.duration_days,
          trip.transportation_text,
          trip.accommodation_text,
          trip.formatted_cost,
          trip.status_text,
          trip.created_at.strftime('%d/%m/%Y %H:%M')
        ]
      end
    end
  end

  private

  def end_date_after_start_date
    return unless start_date && end_date
    
    if end_date < start_date
      errors.add(:end_date, 'phải sau ngày bắt đầu')
    end
  end

  def dates_not_in_past
    return unless start_date
    
    if start_date < Date.current
      errors.add(:start_date, 'không thể là ngày trong quá khứ')
    end
  end

  def has_trip_dates
    if trip_dates.empty?
      errors.add(:trip_dates, 'phải có ít nhất một ngày đi công tác')
    end
  end

  def duration_days
    return 0 unless start_date && end_date
    (end_date - start_date).to_i + 1
  end
end
