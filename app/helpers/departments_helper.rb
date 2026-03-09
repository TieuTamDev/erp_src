module DepartmentsHelper
  TAB_NAMES = {
    info: 'Thông tin',
    tasks: 'Chức năng nhiệm vụ',
    positionjobs: 'Mô tả vị trí công việc',
    users: 'Định biên/Danh sách nhân sự',
    subdepartments: 'Nhóm',
    report: 'Chế độ báo cáo',
    kpi: 'Chế độ (KPI)',
    rewards: 'Thi đua khen thưởng',
  }.freeze

  TAB_NAME_KEYS = {
    info: :info,
    tasks: :tasks,
    positionjobs: :positionjobs,
    users: :users,
    subdepartments: :subdepartments,
    report: :report,
    kpi: :kpi,
    rewards: :rewards,
  }.freeze

  EXPORT_FIELDS = [
    { name:"name",              text:"Tên đơn vị",                checked:false, size: 38, center: false},
    { name:"scode",             text:"Mã đơn vị",                 checked:false, size: 30, center: false},
    { name:"status",            text:"Trạng thái",                checked:false, size: 14, center: true },
    { name:"stype",             text:"Loại đơn vị",               checked:false, size: 25, center: false},
    { name:"email",             text:"Email đơn vị",              checked:false, size: 29, center: false},
    { name:"leader_name",       text:"Trưởng đơn vị",             checked:false, size: 30, center: false},
    { name:"issued_date",       text:"Ngày thành lập",            checked:false, size: 19, center: true },
    { name:"organization_name", text:"Đơn vị chủ quản",           checked:false, size: 37, center: false},
    { name:"user_count",        text:"SL nhân sự",                checked:false, size: 12, center: true },
    { name:"deputy_name",       text:"Phó trưởng đơn vị",         checked:false, size: 24, center: false},
    { name:"leader_email",      text:"Email trưởng đơn vị",       checked:false, size: 24, center: false},
    { name:"issue_id",          text:"Quyết định thành lập",      checked:false, size: 30, center: false},
    { name:"deputy_email",      text:"Email phó trưởng đơn vị",   checked:false, size: 24, center: false},
    { name:"name_en",           text:"Tên đơn vị bằng tiếng anh", checked:false, size: 30, center: false},
  ].freeze

end
