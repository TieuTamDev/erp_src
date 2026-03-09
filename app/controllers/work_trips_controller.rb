class WorkTripsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_work_trip, only: [:show, :edit, :update, :destroy, :approve, :reject]
  before_action :check_permissions, only: [:index, :approve, :reject]

  # GET /work_trips
  def index
    @work_trips = WorkTrip.includes(:user, :shiftselections)
                          .where(user_id: current_user.id)
                          .order(created_at: :desc)
                          .page(params[:page])
                          .per(20)

    respond_to do |format|
      format.html
      format.json { render json: @work_trips }
    end
  end

  # GET /work_trips/1
  def show
    respond_to do |format|
      format.html
      format.json { render json: @work_trip }
    end
  end

  # GET /work_trips/new
  def new
    @work_trip = WorkTrip.new
    @work_trip.trip_dates.build
  end

  # GET /work_trips/1/edit
  def edit
  end

  # POST /work_trips
  def create
    @work_trip = WorkTrip.new(work_trip_params)
    @work_trip.user_id = current_user.id
    @work_trip.status = 'PENDING'

    if @work_trip.save
      # Create shiftissues for each trip date
      create_shiftissues_for_trip
      
      # Send notification to approver
      send_work_trip_notification(@work_trip, 'created')
      
      respond_to do |format|
        format.html { redirect_to @work_trip, notice: 'Đề xuất đi công tác đã được tạo thành công.' }
        format.json { render json: { success: true, work_trip: @work_trip }, status: :created }
      end
    else
      respond_to do |format|
        format.html { render :new }
        format.json { render json: { success: false, errors: @work_trip.errors }, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /work_trips/1
  def update
    if @work_trip.update(work_trip_params)
      respond_to do |format|
        format.html { redirect_to @work_trip, notice: 'Đề xuất đi công tác đã được cập nhật thành công.' }
        format.json { render json: { success: true, work_trip: @work_trip } }
      end
    else
      respond_to do |format|
        format.html { render :edit }
        format.json { render json: { success: false, errors: @work_trip.errors }, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /work_trips/1
  def destroy
    if @work_trip.status == 'PENDING'
      @work_trip.destroy
      respond_to do |format|
        format.html { redirect_to work_trips_url, notice: 'Đề xuất đi công tác đã được hủy.' }
        format.json { render json: { success: true } }
      end
    else
      respond_to do |format|
        format.html { redirect_to work_trips_url, alert: 'Không thể hủy đề xuất đã được duyệt.' }
        format.json { render json: { success: false, error: 'Không thể hủy đề xuất đã được duyệt.' }, status: :unprocessable_entity }
      end
    end
  end

  # GET /work_trips/pending_approvals
  def pending_approvals
    @work_trips = WorkTrip.includes(:user, :shiftselections)
                          .where(status: 'PENDING')
                          .where(approved_by: current_user.id)
                          .order(created_at: :desc)
                          .page(params[:page])
                          .per(20)

    respond_to do |format|
      format.html
      format.json { render json: @work_trips }
    end
  end

  # POST /work_trips/1/approve
  def approve
    if @work_trip.update(status: 'APPROVED', approved_at: Time.current)
      # Update related shiftissues
      update_shiftissues_status('APPROVED')
      
      # Send notification to requester
      send_work_trip_notification(@work_trip, 'approved')
      
      respond_to do |format|
        format.html { redirect_to pending_approvals_work_trips_path, notice: 'Đã duyệt đề xuất đi công tác.' }
        format.json { render json: { success: true, work_trip: @work_trip } }
      end
    else
      respond_to do |format|
        format.html { redirect_to pending_approvals_work_trips_path, alert: 'Có lỗi xảy ra khi duyệt đề xuất.' }
        format.json { render json: { success: false, errors: @work_trip.errors }, status: :unprocessable_entity }
      end
    end
  end

  # POST /work_trips/1/reject
  def reject
    rejection_reason = params[:rejection_reason]
    
    if rejection_reason.blank?
      respond_to do |format|
        format.html { redirect_to pending_approvals_work_trips_path, alert: 'Vui lòng nhập lý do từ chối.' }
        format.json { render json: { success: false, error: 'Vui lòng nhập lý do từ chối.' }, status: :unprocessable_entity }
      end
      return
    end

    if @work_trip.update(status: 'REJECTED', approved_at: Time.current, rejection_reason: rejection_reason)
      # Update related shiftissues
      update_shiftissues_status('REJECTED', rejection_reason)
      
      # Send notification to requester
      send_work_trip_notification(@work_trip, 'rejected')
      
      respond_to do |format|
        format.html { redirect_to pending_approvals_work_trips_path, notice: 'Đã từ chối đề xuất đi công tác.' }
        format.json { render json: { success: true, work_trip: @work_trip } }
      end
    else
      respond_to do |format|
        format.html { redirect_to pending_approvals_work_trips_path, alert: 'Có lỗi xảy ra khi từ chối đề xuất.' }
        format.json { render json: { success: false, errors: @work_trip.errors }, status: :unprocessable_entity }
      end
    end
  end

  # GET /work_trips/reports
  def reports
    @start_date = params[:start_date] || 1.month.ago.beginning_of_month
    @end_date = params[:end_date] || Date.current.end_of_month
    
    @work_trips = WorkTrip.includes(:user, :shiftselections)
                          .where(created_at: @start_date..@end_date)
                          .order(created_at: :desc)
    
    @statistics = {
      total: @work_trips.count,
      pending: @work_trips.where(status: 'PENDING').count,
      approved: @work_trips.where(status: 'APPROVED').count,
      rejected: @work_trips.where(status: 'REJECTED').count
    }

    respond_to do |format|
      format.html
      format.json { render json: { work_trips: @work_trips, statistics: @statistics } }
    end
  end

  private

  def set_work_trip
    @work_trip = WorkTrip.find(params[:id])
  end

  def check_permissions
    unless current_user.can_approve_work_trips?
      redirect_to root_path, alert: 'Bạn không có quyền truy cập trang này.'
    end
  end

  def work_trip_params
    params.require(:work_trip).permit(
      :destination, :purpose, :start_date, :end_date, :transportation, 
      :accommodation, :estimated_cost, :approved_by, :note, :docs,
      trip_dates_attributes: [:id, :date, :shift_ids, :_destroy]
    )
  end

  def create_shiftissues_for_trip
    @work_trip.trip_dates.each do |trip_date|
      trip_date.shift_ids.each do |shift_id|
        shift = find_shift(current_user.id, trip_date.date, shift_id)
        next unless shift

        Shiftissue.create!(
          shiftselection_id: shift.id,
          stype: 'WORK-TRIP',
          status: 'PENDING',
          name: "Đi công tác - #{@work_trip.destination}",
          note: @work_trip.purpose,
          approved_by: @work_trip.approved_by,
          us_start: shift.start_time,
          us_end: shift.end_time,
          docs: @work_trip.docs
        )
      end
    end
  end

  def update_shiftissues_status(status, reason = nil)
    @work_trip.trip_dates.each do |trip_date|
      trip_date.shift_ids.each do |shift_id|
        shift = find_shift(@work_trip.user_id, trip_date.date, shift_id)
        next unless shift

        shiftissue = Shiftissue.find_by(
          shiftselection_id: shift.id,
          stype: 'WORK-TRIP',
          status: 'PENDING'
        )
        
        if shiftissue
          attrs = { status: status, approved_at: Time.current }
          attrs[:content] = reason if reason.present?
          shiftissue.update!(attrs)
        end
      end
    end
  end

  def find_shift(user_id, date, shift_id, include_day_off: true)
    Shiftselection.joins(:scheduleweek)
                  .where(scheduleweeks: { user_id: user_id, status: 'APPROVED' })
                  .where(work_date: date.beginning_of_day..date.end_of_day)
                  .where(workshift_id: shift_id)
                  .first
  end

  def send_work_trip_notification(work_trip, action)
    # Implementation for sending notifications
    # This would integrate with your existing notification system
    case action
    when 'created'
      # Notify approver
      NotificationJob.perform_later(
        user_id: work_trip.approved_by,
        title: 'Đề xuất đi công tác mới',
        content: "#{work_trip.user.full_name} đã tạo đề xuất đi công tác đến #{work_trip.destination}",
        type: 'work_trip_created'
      )
    when 'approved'
      # Notify requester
      NotificationJob.perform_later(
        user_id: work_trip.user_id,
        title: 'Đề xuất đi công tác đã được duyệt',
        content: "Đề xuất đi công tác đến #{work_trip.destination} đã được duyệt",
        type: 'work_trip_approved'
      )
    when 'rejected'
      # Notify requester
      NotificationJob.perform_later(
        user_id: work_trip.user_id,
        title: 'Đề xuất đi công tác bị từ chối',
        content: "Đề xuất đi công tác đến #{work_trip.destination} đã bị từ chối. Lý do: #{work_trip.rejection_reason}",
        type: 'work_trip_rejected'
      )
    end
  end
end
