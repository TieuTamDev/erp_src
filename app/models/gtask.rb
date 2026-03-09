class Gtask < ApplicationRecord
  has_many :stasks
  has_many :works

  before_validation :strip_whitespace
  validates :name, presence: true
  validates :name, length: { maximum: 255 }
  validate :custom_error_messages

  def can_delete?
    return false if stasks.exists?
    return false if works.exists?

    true
  end

  alias_method :can_be_deleted, :can_delete?

  private

  def strip_whitespace
    self.name = name&.strip
  end

  def custom_error_messages
    if errors[:name].any?
      name_details = errors.details[:name]
      errors.delete(:name)
      
      if name_details.any? { |e| e[:error] == :too_long }
        errors.add(:name, "Tên quá dài (tối đa 255 ký tự)")
      elsif name_details.any? { |e| e[:error] == :blank }
        errors.add(:name, "Vui lòng nhập tên nhóm công việc")
      end
    end
  end
end
