class Stask < ApplicationRecord
    include ApplicationHelper

    attr_accessor :files
    has_many :responsibles, class_name: "responsible"
    has_many :accesss, class_name: "access"
    has_many :accesses
    has_many :positionjobs, through: :responsibles
    has_many :resources, through: :access
    has_many :responsibles, :dependent => :destroy
    has_many :works, :dependent => :destroy
    has_many :accesses, :dependent => :destroy
    belongs_to :tfunction
    belongs_to :gtask
    has_many :taskdocs

    # Khoa Nguyen - Lấy các công việc thuộc một nhiệm vụ cụ thể
    scope :tasks_of, ->(duty_id) { where(tfunction_id: duty_id) }

    before_validation :strip_whitespace
    validates :name, presence: true
    validates :name, length: { maximum: 255 }
    validate :custom_error_messages

    before_save :normalize_tfunction_id 

    def files
      taskdocs.includes(:mediafile).map do |doc|
        next unless doc.mediafile
        
        {
          doc_id: doc.id,
          file_name: doc.mediafile.file_name,
          file_type: doc.mediafile.file_type,
          file_size: doc.mediafile.file_size,
          file_icon: get_file_icon(doc.mediafile.file_type)
        }
      end.compact
    end

    def can_delete?
      return false if taskdocs.exists?
      return false if works.exists?
      true
    end

    alias_method :can_be_deleted, :can_delete?

    private

    def strip_whitespace
      self.name = name&.strip
    end

    def normalize_tfunction_id
      if tfunction_id == 0
        self.tfunction_id = ""
      end
    end

    def get_file_icon(file_type)
      case file_type
      when 'application/msword', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
        'doc'
      when /^image\//
        'photo'
      when 'application/pdf'
        'pdf'
      when 'application/vnd.ms-excel', 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
        'excel'
      when 'application/vnd.ms-powerpoint', 'application/vnd.openxmlformats-officedocument.presentationml.presentation'
        'powerpoint'
      when 'text/plain'
        'text'
      when 'application/zip', 'application/x-rar-compressed', 'application/x-7z-compressed'
        'archive'
      else
        'file'
      end
    end

    def custom_error_messages
      if errors[:name].any?
        name_details = errors.details[:name]
        errors.delete(:name)
        
        if name_details.any? { |e| e[:error] == :too_long }
          errors.add(:name, "Tên quá dài (tối đa 255 ký tự)")
        elsif name_details.any? { |e| e[:error] == :blank }
          errors.add(:name, "Vui lòng nhập tên công việc")
        end
      end
    end
end
