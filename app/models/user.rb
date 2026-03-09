class User < ApplicationRecord
    has_secure_password
    belongs_to :workins
    has_many :stasks, through: :works
    has_many :identitys, class_name: "Identity"
    has_many :mediafiles, through: :identitys
    has_many :organizations, through: :uorgs
    # Lê Ngọc Huy
    has_many :acchist, dependent: :destroy
    has_many :addresses, dependent: :destroy
    has_many :applies, dependent: :destroy
    has_many :archives, dependent: :destroy
    has_many :banks, dependent: :destroy
    has_many :benefits, dependent: :destroy
    has_many :contracts, dependent: :destroy
    has_many :disciplines, dependent: :destroy
    has_many :holidays, dependent: :destroy
    has_many :identities, dependent: :destroy
    has_many :reviews, dependent: :destroy
    has_many :socials, dependent: :destroy
    has_many :workins, dependent: :destroy
    has_many :works, dependent: :destroy
    has_many :uorgs, dependent: :destroy
    has_many :mandocuhandles, dependent: :destroy
    has_many :scheduleweek, dependent: :destroy
    has_many :docs, dependent: :destroy
    # Hải 10/10/2025
    has_many :appointments, dependent: :destroy
    has_many :appointsurveys, dependent: :destroy
    has_many :payslips, dependent: :destroy
    has_many :scheduleweeks, dependent: :destroy
    has_many :shiftselections, dependent: :destroy
    has_many :signatures, dependent: :destroy
    has_many :snotices, dependent: :destroy
    has_many :attends, dependent: :destroy

    belongs_to :academicrank,
        ->(user) { where(name: user.academic_rank) },
        class_name: 'Academicrank',
        foreign_key: :academic_rank,
        primary_key: :name
    belongs_to :mediafile,
        ->(user) { where(id: user.avatar) },
        class_name: 'Academicrank',
        foreign_key: :avatar,
        primary_key: :id

    # Khoa Nguyen - 05/07/2025
    def new_full_name
        "#{last_name} #{first_name}".strip
    end

    def self.get_info_user(user_id)
        select("
                users.id,
                users.sid,
                users.username,
                users.email,
                users.gender,
                users.nationality,
                users.ethnic,
                users.religion,
                users.marriage,
                users.insurance_no,
                users.education,
                users.academic_rank,
                users.stype,
                users.status,
                users.note,
                users.first_name,
                users.last_name,
                users.birthday,
                users.taxid,
                users.insurance_reg_place,
                users.place_of_birth,
                users.email1,
                users.phone,
                users.mobile,
                users.avatar,
                users.staff_status,
                users.staff_type,
                users.benefit_type,
                CONCAT(users.last_name, ' ', users.first_name) as full_name,
                positionjobs.name as positionjob_name,
                departments.name as department_name,
                mediafiles.file_name as avatar_name")
        .joins(works: [positionjob: :department])
        .joins("LEFT JOIN mediafiles ON users.avatar = mediafiles.id")
        .preload(:organizations)
        .find_by(users: { id: user_id })
        &.yield_self do |user|
            user&.attributes&.merge(
            organizations: user.organizations.pluck(:scode)
            ) || {}
        end
    end

    def self.get_department_user(user_id)
        select("users.id,
                departments.id as department_id,
                departments.name as department_name,
                departments.scode as department_scode")
        .joins(works: [positionjob: :department])
        .find_by(users: { id: user_id })
    end

    # Scope để lấy work mới nhất với stask_id IS NULL và gtask_id IS NULL
    scope :with_basic_work, -> {
        joins("INNER JOIN works ON works.user_id = users.id
                AND works.id = (
                    SELECT w.id
                    FROM works w
                    INNER JOIN positionjobs pj ON pj.id = w.positionjob_id
                    INNER JOIN departments d ON d.id = pj.department_id
                    WHERE w.user_id = users.id
                    AND w.positionjob_id IS NOT NULL
                    AND pj.name IS NOT NULL
                    AND pj.department_id IS NOT NULL
                    ORDER BY w.created_at DESC
                    LIMIT 1
                )")
        .joins("LEFT JOIN positionjobs ON positionjobs.id = works.positionjob_id")
        .joins("LEFT JOIN departments ON departments.id = positionjobs.department_id")
        .joins(:uorgs)
    }

    scope :by_organization_ids, ->(org_ids) {
        where(uorgs: { organization_id: org_ids })
    }

    scope :active_cohuu, -> {
        where(status: "ACTIVE")
        .where("LOWER(users.staff_type) LIKE '%cơ hữu%'")
    }

    scope :search_by_sid_or_name, ->(term) {
        where("LOWER(users.sid) LIKE :search OR LOWER(CONCAT(users.last_name, ' ', users.first_name)) LIKE :search", search: "%#{term.downcase}%")
    }

    scope :by_department, ->(dept_id) {
        where("positionjobs.department_id = ?", dept_id)
    }

    def latest_department_name
    Work.joins(positionjob: :department)
        .where(user_id: id)
        .where.not(positionjob_id: nil)
        .where.not(positionjobs: { name: nil, department_id: nil })
        .where.not(departments: { name: 'Quản lý ERP' })
        .where(departments: { is_virtual: nil, parents: nil })
        .order(updated_at: :desc)
        .limit(1)
        .pluck('departments.name')
        .first
  end
end
