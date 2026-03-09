module WorksHelper
  # Tab
  TAB_NAMES = {
    works: 'Thư viện',
    functions: 'Chức năng',
    dueties: 'Nhiệm vụ',
    tasks: 'Công việc',
    gtasks: 'Nhóm công việc'
  }.freeze

  TAB_NAME_KEYS = {
    works: :works,
    functions: :functions,
    dueties: :dueties,
    tasks: :tasks,
    gtasks: :gtasks
  }.freeze

  TAB_CONFIGS = {
    functions: { table: Tfunction, stype: 'FUNCTIONS' },
    dueties: { table: Tfunction, stype: 'DUETIES' },
    tasks: { table: Stask },
    gtasks: { table: Gtask }
  }.freeze

  FUNCTIONS_KEYS = {
    FUNCTIONS: :FUNCTIONS,
    DUETIES: :DUETIES
  }.freeze

  # Mức độ thường xuyên
  FREQUENCY_TYPES = {
    daily: "Hàng ngày",
    weekly: "Hàng tuần",
    monthly: "Hàng tháng",
    quarterly: "Hàng quý",
    yearly: "Hàng năm",
    on_demand: "Khi phát sinh",
    project: "Dự án",
    academic_year: "Năm học",
    not_often: "Không thường xuyên",
    periodic: "Định kỳ"
  }.freeze

  FREQUENCY_TYPE_KEYS = {
    daily: :daily,
    weekly: :weekly,
    monthly: :monthly,
    quarterly: :quarterly,
    yearly: :yearly,
    on_demand: :on_demand,
    project: :project,
    academic_year: :academic_year,
    not_often: :not_often,
    periodic: :periodic
  }.freeze

  # Cấp xử lý
  PROCESSING_LEVELS = (1..10).to_a.freeze

  PROCESSING_LEVEL_KEYS = {
    strategic_leader: :strategic_leader,
    middle_leader: :middle_leader,
    department_leader: :department_leader,
    employee: :employee
  }.freeze

  # Độ khẩn
  URGENCY_VALUES = (0..10).to_a.freeze

  # Độ khó
  DIFFICULTY_VALUES = (0..100).to_a.freeze

  def frequency_type(key)
    FREQUENCY_TYPES[key.to_sym] || "Không xác định"
  end

  def processing_level(key)
    PROCESSING_LEVELS[key.to_sym] || "Không xác định"
  end
end