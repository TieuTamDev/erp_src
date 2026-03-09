class Appointment < ApplicationRecord
  include AppointmentStatusManagement

  belongs_to :user
  belongs_to :survey
  has_many :appointsurveys
  has_many :mandocs
  belongs_to :department, 
             ->(appointment) { where(id: appointment.new_dept) }, 
             class_name: 'Department', 
             foreign_key: :new_dept,
             primary_key: :id
             
  belongs_to :positionjob, 
             ->(appointment) { where(id: appointment.new_position) }, 
             class_name: 'Positionjob', 
             foreign_key: :new_position,
             primary_key: :id

  belongs_to :mandocpriority, 
             ->(appointment) { where(scode: appointment.priority) }, 
             class_name: 'Mandocpriority', 
             foreign_key: :priority,
             primary_key: :scode

  # Scopes
  scope :pending_approvals, -> { where(result: RESULTS[:pending]) }
  scope :approved, -> { where(result: RESULTS[:approved]) }
  scope :rejected, -> { where(result: RESULTS[:rejected]) }
  scope :on_probation, -> { where(result: RESULTS[:probation]) }
  
  # Scope để đếm tổng số bản ghi
  scope :count_filtered_appointments, ->(search, user_id, is_handle = nil) {
    query = joins(mandocs: [mandocdhandles: :mandocuhandles])
            .joins("LEFT JOIN mandocpriorities ON appointments.priority = mandocpriorities.scode")
            .where(mandocuhandles: {user_id: user_id})
            .order("appointments.created_at DESC")
    query = query.where(mandocuhandles: {sread: "PROCESS"})  if is_handle.present?
    query = query.where("appointments.title LIKE ?", "%#{search}%")  if search.present?
    query.uniq.count
  }

  def self.filtered_appointments(search, user_id, page, per_page, is_handle = nil)
    query = joins(mandocs: [mandocdhandles: :mandocuhandles])
            .joins("LEFT JOIN mandocpriorities ON appointments.priority = mandocpriorities.scode")
            .select("appointments.*, mandocpriorities.note AS color_priority, mandocpriorities.name AS priority_name").where(mandocuhandles: {user_id: user_id})
            .order("appointments.created_at DESC")
    query = query.where(mandocuhandles: {sread: "PROCESS"})  if is_handle.present?
    query = query.where("appointments.title LIKE ?", "%#{search}%")  if search.present?
    query = query.uniq.offset((page - 1) * per_page).limit(per_page)

    query.map do |appointment|
      {
        id: appointment.id,
        title: appointment.title, 
        user_handles: fetch_user_handles(appointment.id), 
        stype: STYPE[appointment.stype&.to_sym],
        priority: appointment.priority_name,
        dt_start: appointment.created_at.in_time_zone('Asia/Ho_Chi_Minh').strftime('%d/%m/%Y'),
        result: appointment.result_name,
        status: appointment.status,
        note: appointment.note,
        result_color: appointment.result_color,
        color_priority: appointment.color_priority
      }
    end
  end

  private_class_method def self.fetch_user_handles(appointment_id)
    Mandocuhandle.joins(:mandoc, :user)
    .where(mandocs: { appointment_id: appointment_id }, mandocuhandles: { sread: "PROCESS" })
    .pluck("CONCAT(users.last_name, ' ', users.first_name)")
    .uniq.map {|name| "#{name}" }.join(', ')
  end
  
  def result_name
    self.class::RESULTS[self.result&.to_sym] || 'Đang xử lý'
  end

  def result_color 
    self.class::RESULT_COLORS[self.result&.to_sym] || 'badges-warning'
  end
end
