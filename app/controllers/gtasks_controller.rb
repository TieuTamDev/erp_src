class GtasksController < ApplicationController
  include WorksHelper
  before_action :authorize
  before_action :set_gtask, only: [:show, :edit, :update, :destroy, :assign_stasks, :update_stasks]

  def index
    respond_to do |format|
      format.html
      format.js
    end
  end

  def new
    @gtask = Gtask.new
    
    respond_to do |format|
      format.html
      format.js
    end
  end
  
  def create
    @gtask = Gtask.new(gtask_params)
    
    respond_to do |format|
      if @gtask.save
        flash[:notice] = 'Thêm nhóm công việc thành công!'
        format.js { render js: "window.location = '#{works_index_path(lang: session[:lang], tab: TAB_NAMES[:gtasks])}'" }
      else
        format.js { render :new }
      end
    end
  end
  
  def show
    respond_to do |format|
      format.html
      format.js
    end
  end
  
  def edit
    respond_to do |format|
      format.html
      format.js
    end
  end
  
  def update
    respond_to do |format|
      if @gtask.update(gtask_params)
        flash[:notice] = 'Cập nhật nhóm công việc thành công!'
        format.js { render js: "window.location = '#{works_index_path(lang: session[:lang], tab: TAB_NAMES[:gtasks])}'" }
      else
        format.js { render :edit }
      end
    end
  end
  
  def destroy
    if @gtask.can_be_deleted
      @gtask.destroy
      flash[:notice] = 'Nhóm công việc đã được xóa thành công!'
    else
      flash[:alert] = 'Đối với các nhóm công việc đã được gán công việc, hệ thống sẽ không cho phép xóa. Để xóa nhóm công việc, vui lòng xóa toàn bộ các công việc liên quan trước!'
    end

    render js: "window.location = '#{works_index_path(lang: session[:lang], tab: TAB_NAMES[:gtasks])}'"
  end

  def assign_stasks
    @unassigned_stasks = Stask.where(gtask_id: [nil, @gtask.id]).order('created_at DESC')
    
    respond_to do |format|
      format.html
      format.js
    end
  end

  def update_stasks
    stask_ids = params[:stask_ids] || []

    Stask.where(id: stask_ids).update_all(gtask_id: @gtask.id)

    @gtask.stasks.where.not(id: stask_ids).update_all(gtask_id: nil)
    
    flash[:notice] = 'Cập nhật công việc cho nhóm thành công!'
    
    respond_to do |format|
      format.js { render js: "window.location = '#{works_index_path(lang: session[:lang], tab: TAB_NAMES[:gtasks])}'" }
    end
  end

  def unassign_stask
    @stask = Stask.find(params[:stask_id])
    @stask.update(gtask_id: nil)
    
    flash[:notice] = "Đã gỡ bỏ công việc #{@stask.name} khỏi nhóm!"
    
    respond_to do |format|
      format.js { render js: "window.location = '#{works_index_path(lang: session[:lang], tab: TAB_NAMES[:gtasks])}'" }
    end
  end

  private
  
  def set_gtask
    @gtask = Gtask.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.html { redirect_to gtasks_path, alert: "Không tìm thấy nhóm công việc" }
      format.js { render js: "alert('Không tìm thấy nhóm công việc');" }
    end
  end

  def gtask_params
    params.require(:gtask).permit(:name, :scode, :sdesc, :iorder, :sorg)
  end
end