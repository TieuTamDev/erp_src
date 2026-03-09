class Positionjob < ApplicationRecord
  belongs_to :department
  has_many :responsibles, class_name: "Responsible"
  has_many :stasks, through: :responsibles
  has_many :responsibles, :dependent => :delete_all
  has_many :works, :dependent => :delete_all

  has_many :clones, class_name: "Positionjob", foreign_key: :is_root
  belongs_to :root, class_name: "Positionjob", optional: true

  before_validation :strip_whitespace
  validates :name, presence: true
  validates :name, length: { maximum: 255 }
  validate :custom_error_messages

  after_update :sync_to_clones, if: :is_root_nil_and_syncable?


  def can_delete?
    return false if Positionjob.where(is_root: self.id).exists?
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
        errors.add(:name, "Vui lòng nhập tên cấp độ quyền hạn")
      end
    end
  end

  def is_root_nil_and_syncable?
    is_root.nil?
  end
  
  def ignore_attend?
    ignore_attend == "true"
  end

  def sync_to_clones
    clone_attributes = self.slice(:name, :iorder, :note)
    base_scode = self.scode
    clones.find_each do |clone|
      clone.update(
        clone_attributes.merge(scode: "#{base_scode}-CLONE")
      )
    end
  end
end
