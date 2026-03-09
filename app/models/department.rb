class Department < ApplicationRecord
  # has_many :works, :dependent => :delete_all
  has_many :works, through: :positionjobs
  # has_many :responsibles, :dependent => :destroy
  has_many :positionjobs, :dependent => :destroy
  has_many :nodes, :dependent => :destroy
  has_many :ddocs, :dependent => :destroy
  has_many :node
  # has_many :positionjobs
  has_many :ddocs, class_name: "Ddoc"
  has_many :mediafiles, through: :ddocs

  # 08/05/2025
  belongs_to :organization

  belongs_to :leader_user, class_name: 'User', foreign_key: 'leader', optional: true
  belongs_to :deputy_user, class_name: 'User', foreign_key: 'deputy', optional: true
  
  # Khoa Nguyen - 2025-06-30
  def is_subdepartment?
    parents.present?
  end

  # Validations chỉ áp dụng cho subdepartment
  validates :name, presence: { message: "Tên nhóm tiếng Việt không được để trống" }, if: :is_subdepartment?
  validates :name, length: { maximum: 255, message: "Tên nhóm tiếng Việt không được vượt quá 255 ký tự" }, if: :is_subdepartment?
  # validates :leader, presence: { message: "Trưởng nhóm không được để trống" }, if: :is_subdepartment?
  # validates :deputy, presence: { message: "Phó nhóm không được để trống" }, if: :is_subdepartment?
  validates :name_en, presence: { message: "Tên nhóm tiếng Anh không được để trống" }, if: :is_subdepartment?
  validates :name_en, length: { maximum: 255, message: "Tên nhóm tiếng Anh không được vượt quá 255 ký tự" }, if: :is_subdepartment?
  validates :amount, presence: { message: "Số lượng không được để trống" }, if: :is_subdepartment?
  validate :validate_subdepartment_rules, if: :is_subdepartment?

  def leader_name
    User.find_by(email: leader)&.new_full_name || 'Chưa có trưởng nhóm'
  end

  def deputy_name
    return 'Chưa có phó nhóm' if deputy.blank?
    
    # Kiểm tra nếu deputy là số (ID cũ)
    if deputy.is_a?(Integer) || deputy.to_s.match?(/^\d+$/)
      user = User.find_by(id: deputy)
      return user&.new_full_name || 'Chưa có phó nhóm'
    end
    
    # Kiểm tra nếu deputy là JSON string
    begin
      emails = JSON.parse(deputy)

      if emails.size == 1
        User.find_by(email: emails.first)&.new_full_name || 'Chưa có phó nhóm'
      else
        names = emails.map do |email|
          User.find_by(email: email)&.new_full_name
        end.compact
        
        names.empty? ? 'Chưa có phó nhóm' : names.join(', ')
      end
    rescue JSON::ParserError
      User.find_by(email: deputy)&.new_full_name || 'Chưa có phó nhóm'
    end
  end

  def parents_name
    Department.find_by(id: parents)&.name || 'Chưa có đơn vị cha'
  end
  private

  def validate_subdepartment_rules
    return unless is_subdepartment?
    
    # Kiểm tra leader và deputy khác nhau
    # if leader.present? && deputy.present? && leader == deputy
    #   errors.add(:deputy, "Phó nhóm không thể trùng với trưởng nhóm")
    # end

    if amount.present?
      if amount.match?(/^\d+$/)
        if amount.to_i <= 0
          errors.add(:amount, "Số lượng phải lớn hơn 0")
        elsif amount.to_i > 999
          errors.add(:amount, "Số lượng không được vượt quá 999")
        end
      else
        errors.add(:amount, "Số lượng phải là số nguyên")
      end
    end
  end
  def self.get_all_related_departments(department_ids)
    # Khởi tạo một mảng kết quả mới
    all_related_departments = []

    # Lặp qua từng department_id trong mảng department_ids
    department_ids.each do |department_id|

      # Lấy tất cả các parent_ids và child_ids cho department_id
      parent_ids = get_all_parents(department_id)

      child_ids = get_all_children(department_id)

      department_ids = parent_ids.concat(child_ids)

      # Gộp cả parent_ids và child_ids và thêm vào mảng kết quả
      all_related_departments.concat(department_ids.uniq)
    end

    # Trả về mảng kết quả chứa các department_ids (cha và con)
    all_related_departments
  end

  # Phương thức đệ quy để lấy tất cả department_id của nhóm cha
  def self.get_all_parents(department_id)
    department = Department.find_by(id: department_id)
    # kiểm tra status active hay inactive
    parent_ids = [department.status == "0" ? department_id : nil ]

    # Nếu có parent (group cha), thêm vào danh sách và tiếp tục đệ quy
    if department&.parents.present?
      # tìm parent
      dpt_parent = Department.find_by(id: department.parents)
      # kiểm tra status parent
      parent_ids << department.parents.to_i if dpt_parent.present? && dpt_parent.status == "0"
      #
      parent_ids.concat(get_all_parents(department.parents.to_i)) 
    end

    parent_ids.uniq
  end

  # Phương thức đệ quy để lấy tất cả department_id của nhóm con
  def self.get_all_children(department_id)
    # Lấy tất cả nhóm con có parent_id là department_id
    child_departments = Department.where(parents: department_id)
    child_ids = [department_id]

    # Thêm các nhóm con hiện tại vào danh sách
    child_departments.each do |child|
      child_ids << child.id if child.status == "0"
      # Tiếp tục lấy nhóm con của nhóm con
      child_ids.concat(get_all_children(child.id))
    end

    child_ids.uniq
  end
end
