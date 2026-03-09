class Tfunction < ApplicationRecord
  include WorksHelper

  belongs_to :department
  has_many :stasks
  attr_accessor :duties, :tasks, :parent_name

  before_validation :strip_whitespace
  validates :name, presence: true
  validates :scode, presence: true, uniqueness: true
  validates :scode, length: { maximum: 255 }
  validates :name, length: { maximum: 255 }
  validate :validate_parent_for_dueties
  validate :custom_error_messages

  # Khoa Nguyen - 2025-05-10
  scope :sorted, -> { order(created_at: :desc) }
  scope :functions, -> { where(stype: FUNCTIONS_KEYS[:FUNCTIONS], parent: nil) }
  scope :duties_of, ->(function_id) { where(stype: FUNCTIONS_KEYS[:DUETIES], parent: function_id.to_s) }

  def full_title
    "#{scode} - #{name}"
  end

  def get_duties
    Tfunction.duties_of(self.id)
  end

  def parent_name
    @parent_name ||= parent.present? ? Tfunction.find_by(id: parent)&.name : nil
  end

  def can_delete?
    return false if stasks.exists?
    return false if Tfunction.duties_of(self.id).exists?

    true
  end

  alias_method :can_be_deleted, :can_delete?

  private

  def strip_whitespace
    self.name = name&.strip
  end
  
  def validate_parent_for_dueties
    if stype == 'DUETIES' && parent.blank?
      errors.add(:parent, "Vui lòng chọn chức năng")
    end
  end
  
  def custom_error_messages
    if errors[:name].any?
      name_details = errors.details[:name]
      errors.delete(:name)
      
      if name_details.any? { |e| e[:error] == :too_long }
        errors.add(:name, "Tên quá dài (tối đa 255 ký tự)")
      elsif name_details.any? { |e| e[:error] == :blank }
        errors.add(:name, "Vui lòng nhập tên #{stype == 'FUNCTIONS' ? 'chức năng' : 'nhiệm vụ'}")
      end
    end
    
    if errors[:scode].any?
      scode_details = errors.details[:scode]
      errors.delete(:scode)

      if scode_details.any? { |e| e[:error] == :taken }
        errors.add(:scode, "#{stype == 'FUNCTIONS' ? 'Chức năng' : 'Nhiệm vụ'} đã tồn tại trong hệ thống")
      elsif scode_details.any? { |e| e[:error] == :too_long }
        errors.add(:scode, "Mã quá dài (tối đa 255 ký tự)")
      elsif scode_details.any? { |e| e[:error] == :blank }
        errors.add(:scode, "Vui lòng nhập mã #{stype == 'FUNCTIONS' ? 'chức năng' : 'nhiệm vụ'}")
      end
    end
  end
end