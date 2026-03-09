class Msetting < ApplicationRecord
  # # Danh sách các stype để chọn cho select option
  # STYPES = {
  #   'HOLPRO' => 'Chức năng nghỉ phép',
  #   'EXIM' => 'Quản lý kho',
  #   'ORDER' => 'Quy trình mua sắm',
  #   # thêm các stype khác
  # }

  # # Validate
  # validates :stype, :name, :scode, :svalue, :valid_from, :valid_to, presence: true
  # validate :valid_date_range

  # before_validation :set_scode

  # private

  # def set_scode
  #   self.scode = name.to_s.parameterize.upcase if name.present?
  # end

  # def valid_date_range
  #   if valid_from && valid_to && valid_from > valid_to
  #     errors.add(:valid_to, "phải lớn hơn hoặc bằng ngày bắt đầu")
  #   end
  # end
   # Danh mục module/feature cho stype (key lưu DB, value hiển thị)
  STYPES = {
    'LEAVE'   => 'Cấu hình nghỉ phép',
    'ORDER'   => 'Cấu hình mua sắm',
    'PAYROLL' => 'Cấu hình chấm công',
    'SYSTEM'  => 'Thiết lập hệ thống'
  }.freeze

  # Chuẩn hoá trước khi validate
  before_validation :normalize_fields

  # Validations
  validates :stype, presence: { message: "Vui lòng chọn loại chức năng" }, inclusion: { in: STYPES.keys, message: "Loại chức năng không hợp lệ" }
  validates :name,  presence: { message: "Vui lòng nhập tên chức năng" }, length: { maximum: 255, message: "Không được nhập quá 255 ký tự" }
  validates :scode, presence: { message: "Vui lòng nhập mã chức năng" }, length: { maximum: 255, message: "Không được nhập quá 255 ký tự" },
                    format: { with: /\A[A-Z0-9\-]+\z/, message: "chỉ gồm A-Z, 0-9, dấu gạch ngang" },
                    uniqueness: { scope: :stype, case_sensitive: false, message: "Mã này đã tồn tại" } # mỗi stype không trùng scode

  validates :svalue, presence: { message: "Vui lòng nhập giá trị của chức năng" }
  # validates :valid_from, presence: true
  # validates :valid_to,   presence: true
  # validate  :valid_range

  private

  def normalize_fields
    self.stype = stype.to_s.strip.upcase.presence
    self.name  = name.to_s.strip.presence
    # sinh scode từ name nếu trống, hoặc chuẩn hoá scode về UPPER-KEBAB
    if scode.blank? && name.present?
      self.scode = name.mb_chars.normalize(:kd).gsub(/[^\x00-\x7F]/n, '') # bỏ dấu
                       .to_s.parameterize.upcase # "chuc nang 1" => "CHUC-NANG-1"
    else
      self.scode = scode.to_s.strip.upcase.gsub(/[^\w\-]/, '-').squeeze('-')
    end
  end

  # def valid_range
  #   return if valid_from.blank? || valid_to.blank?
  #   if valid_to < valid_from
  #     errors.add(:valid_to, "phải lớn hơn hoặc bằng Ngày bắt đầu")
  #   end
  # end
end
