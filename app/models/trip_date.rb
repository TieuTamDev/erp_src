class TripDate < ApplicationRecord
  belongs_to :work_trip
  has_and_belongs_to_many :shiftselections

  validates :date, presence: true
  validates :shift_ids, presence: true
  validate :date_not_in_past, on: :create
  validate :shift_ids_valid

  scope :by_date, ->(date) { where(date: date) }
  scope :in_date_range, ->(start_date, end_date) { where(date: start_date..end_date) }

  def shift_ids
    super || []
  end

  def shift_ids=(ids)
    super(Array(ids).map(&:to_i).reject(&:zero?))
  end

  def shift_names
    return [] if shift_ids.empty?
    
    Workshift.where(id: shift_ids).pluck(:name)
  end

  def formatted_date
    date.strftime('%d/%m/%Y')
  end

  def day_of_week
    I18n.t('date.day_names')[date.wday]
  end

  def is_weekend?
    date.saturday? || date.sunday?
  end

  def is_holiday?
    # This would need to be implemented based on your holiday system
    false
  end

  def can_be_edited?
    work_trip.can_be_edited? && date >= Date.current
  end

  def total_hours
    return 0 if shift_ids.empty?
    
    Workshift.where(id: shift_ids).sum do |shift|
      start_time = Time.parse(shift.start_time)
      end_time = Time.parse(shift.end_time)
      ((end_time - start_time) / 1.hour).round(2)
    end
  end

  def formatted_shift_times
    return 'Không có ca' if shift_ids.empty?
    
    Workshift.where(id: shift_ids).map do |shift|
      "#{shift.start_time} - #{shift.end_time}"
    end.join(', ')
  end

  private

  def date_not_in_past
    return unless date
    
    if date < Date.current
      errors.add(:date, 'không thể là ngày trong quá khứ')
    end
  end

  def shift_ids_valid
    return if shift_ids.empty?
    
    valid_shift_ids = Workshift.where(id: shift_ids).pluck(:id)
    invalid_ids = shift_ids - valid_shift_ids
    
    if invalid_ids.any?
      errors.add(:shift_ids, "chứa ID ca không hợp lệ: #{invalid_ids.join(', ')}")
    end
  end
end
