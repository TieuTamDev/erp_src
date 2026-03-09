class Mandocdhandle < ApplicationRecord
  belongs_to :mandoc
  belongs_to :department
  has_many :mandocuhandles, dependent: :destroy

  scope :with_main_handler_info, -> do
    joins("INNER JOIN mandocuhandles ON mandocuhandles.mandocdhandle_id = mandocdhandles.id")
    .joins("INNER JOIN users ON users.id = mandocuhandles.user_id")
    .joins(<<~SQL)
      LEFT JOIN works ON works.user_id = users.id AND works.id = (
        SELECT w.id
        FROM works w
        INNER JOIN positionjobs pj ON pj.id = w.positionjob_id
        INNER JOIN departments d ON d.id = pj.department_id
        WHERE w.user_id = users.id
          AND w.positionjob_id IS NOT NULL
          AND pj.name IS NOT NULL
          AND pj.department_id IS NOT NULL
          AND d.name != 'Quản lý ERP'
        ORDER BY w.updated_at DESC
        LIMIT 1
      )
    SQL
    .joins("LEFT JOIN positionjobs ON positionjobs.id = works.positionjob_id")
    .where(mandocuhandles: { srole: "MAIN" })
    .select("
      mandocdhandles.id,
      mandocuhandles.id AS mandocuhandle_id,
      CONCAT(users.last_name, ' ', users.first_name) AS handler_name,
      mandocuhandles.updated_at,
      mandocuhandles.status,
      positionjobs.name AS user_position
    ")
    .distinct
    .order("mandocdhandles.id ASC, mandocuhandles.id ASC")
  end
end
