class ShiftselectionsController < ApplicationController
  before_action :authorize
  before_action :get_all_campuses, only: [:process_workshifts_of_departments, :process_workshifts]
  include AttendConcern

  def process_workshifts
    
  end

  def process_workshifts_of_departments
    present_department_id = get_positionjob_department_ids_of_user( session[:user_id] )
    all_department_ids    = Department.get_all_related_departments( present_department_id ).uniq
    @users                = Work.joins({positionjob: :department}, :user)
                                .where(positionjobs: { department_id: all_department_ids })
                                .select("works.user_id", "CONCAT(users.last_name, ' ', users.first_name) as name, users.sid, users.id")
    @users = limit_offset_query(@users)
  end

  def get_workshifts
    week_num = params[:week_num]
    year = params[:year]
    search = params[:search].strip rescue ""

    scheduleweeks = Scheduleweek.select("scheduleweeks.*,CONCAT(users.last_name, ' ', users.first_name) as user_name,users.sid")
			.joins(:user)
      .where("CONCAT(users.last_name, ' ', users.first_name) LIKE ? OR users.sid LIKE ?", "%#{search}%","%#{search}%")
			.where(week_num: week_num, year: year)
			.where(checked_by: session[:user_id])
      .where.not(status:"TEMP")
    @scheduleweeks_pagin = limit_offset_query(scheduleweeks)

    @shiftselections = Shiftselection.where(scheduleweek_id:@scheduleweeks_pagin.pluck(:id))
                                      .where(is_day_off: [nil, "ON-LEAVE", "HOLIDAY", "TEACHING-SCHEDULE"])
                                      .order(:work_date)

  end

  def get_workshifts_of_department
    week_num = params[:week_num]
    year = params[:year]
    search = params[:search].strip rescue ""

    present_department_id = get_positionjob_department_ids_of_user( session[:user_id] )
    all_department_ids    = Department.get_all_related_departments( present_department_id ).uniq
    user_ids              = Work.joins(:positionjob, :user)
                                .where(positionjobs: { department_id: all_department_ids }).pluck(:user_id)

    scheduleweeks = Scheduleweek.select("scheduleweeks.*,CONCAT(users.last_name, ' ', users.first_name) as user_name,users.sid" )
                              .joins(:user)
                              .where("CONCAT(users.last_name, ' ', users.first_name) LIKE ? OR users.sid LIKE ?", "%#{search}%", "%#{search}%" )
                              .where(week_num: week_num, year: year )
                              .where(user_id: user_ids )
                              .where(status: "APPROVED" )
    @scheduleweeks_pagin = limit_offset_query(scheduleweeks)

    @shiftselections = Shiftselection.where(scheduleweek_id:@scheduleweeks_pagin.pluck(:id))
                                      .where(is_day_off: [nil, "ON-LEAVE", "HOLIDAY", "TEACHING-SCHEDULE"])
                                      .order(:work_date)
    @shiftselections.each do |ss|
      has_work_trip = ss.shiftissue.any? { |si| si.stype == 'WORK-TRIP' && si.status == 'APPROVED' }
      ss.is_day_off = 'WORK-TRIP' if has_work_trip
    end                  

  end

  def update_shiflselections
    status = params[:status]
    raw_data = params[:data]
    data = JSON.parse(raw_data) rescue []

    position = ""
    message = ""

    success = true
    ActiveRecord::Base.transaction do
      begin
        data.each do |item|
        scheduleweek = Scheduleweek.find(item["id"])
        scheduleweek.update(status:status,reason:item["reason"],checked_at: DateTime.now)
        shiftselections = Shiftselection.where(scheduleweek_id: item["id"])
        shiftselections.update_all(status:status)
        
        result_message = status == "APPROVED" ? "được duyệt" : "bị từ chối"
        notify = Notify.create(
          title: "Thông báo duyệt kế hoạch tuần",
          contents: "Kế hoạch tuần #{scheduleweek.start_date.to_date.cweek} (#{scheduleweek.start_date.strftime("%d/%m/%Y")} - #{scheduleweek.end_date.strftime("%d/%m/%Y")}) đã #{result_message}.<br>
                      #{status == "REJECTED" ? "<span>Lý do:</span>#{item["reason"]}<span>" : ""}",
          receivers: "Hệ thống ERP",
          stype: "SHIFTSELECTION"
        )
        Snotice.create(
          notify_id: notify.id,
          user_id: scheduleweek.user_id,
          isread: false,
          username: nil
        )
        
        data = {
          start_date: scheduleweek.start_date,
          end_date: scheduleweek.end_date,
          works: shiftselections
        }
        #   # send email
        #   data[:reason] = reason
        #   UserMailer.send_email_reject_shiftselection(scheduleweek.user_id,data)

        end
      rescue => e
        position = e.backtrace.to_json.html_safe.gsub("\`","")
        message = e.message.gsub("\`","")

        success = false

        raise ActiveRecord::Rollback
      end
    end
    
    respond_to do |format|
      format.html
      format.js { render js: "onApproval(#{success}); console.log(`#{message}`,`#{position}`)"}
    end

  end

  def get_positionjob_department_ids_of_user(user_id)
    #1. Lấy hết vị trí công việc
    user_works = Work
      .includes(positionjob: :department)
      .where(user_id: user_id)

    if user_works.present?
      #2. Lấy department id từ vị trí công việc
      work_departments = user_works.map do |w|
        [w&.positionjob_id, w&.positionjob&.department_id]
      end
      # Lấy danh sách deparment_ids
      department_ids = work_departments.map { |_, dep_id| dep_id }.uniq
      # 
      departments = Department.where(id: department_ids)
      # Lấy id của parents
      parent_ids = departments.map(&:parents).compact.uniq
      #3. So sánh các nếu mà department_id là parent của đơn vị khác thì bỏ qua
      main_departments = departments.reject { |dep| parent_ids.include?(dep.id.to_s) }
      # danh sách id department 
      main_department_ids = main_departments.map { |d| d.id }
      # so sánh work_departments để lấy positionjob_id và department_id tương ứng
      valid_pairs = work_departments.select { |pair| main_department_ids.include?(pair[1]) }.map { |sub| sub[1] }
    end
  end

  def get_all_campuses
    # campuses_response = call_api(@CSVC_PATH + "api/v1/mapi_utils/get_all_campuses")
    # campuses = campuses_response["result"].is_a?(Array) ? campuses_response["result"] : []
    @campuses_map = get_all_campus
  end
end