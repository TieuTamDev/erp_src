class DuetiesController < ApplicationController
  include WorksHelper
  before_action :authorize
  before_action :set_duety, only: [:show, :edit, :update, :destroy]

  def index
    @tfunctions = Tfunction.all.sorted
    
    respond_to do |format|
      format.html
      format.js
    end
  end

  def new
    @duety = Tfunction.new
    @function_options = Tfunction.where(stype: 'FUNCTIONS', is_root: nil, parent: nil).sorted.map { |f| [f.name, f.id] }
    
    respond_to do |format|
      format.html
      format.js
    end
  end
  
  def create
    @function_options = Tfunction.where(stype: 'FUNCTIONS', is_root: nil, parent: nil).sorted.map { |f| [f.name, f.id] }
    @parent = params[:parent].presence || nil
    @duety = Tfunction.new(duety_params)
    @duety.stype = 'DUETIES'
    @duety.parent = params[:parent]

    if params[:parent].present?
      @selected_function = Tfunction.find_by(id: params[:parent])
    end
    
    respond_to do |format|
      if @duety.save
        flash[:notice] = 'Thêm nhiệm vụ thành công!'
        format.js { render js: "window.location = '#{works_index_path(lang: session[:lang], tab: TAB_NAMES[:dueties])}'" }
      else
        flash[:alert] = 'Thêm nhiệm vụ thất bại!'
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
    @function_options = Tfunction.where(stype: 'FUNCTIONS', is_root: nil, parent: nil).sorted.map { |f| [f.name, f.id] }
    selected_duety = Tfunction.find(params[:id])
    @selected_function = Tfunction.find(selected_duety.parent.to_i)
    respond_to do |format|
      format.html
      format.js
    end
  end
  
  def update
    respond_to do |format|
      @duety.parent = params[:parent]
      if @duety.update(duety_params)
        flash[:notice] = 'Cập nhật nhiệm vụ thành công!'
        format.js { render js: "window.location = '#{works_index_path(lang: session[:lang], tab: TAB_NAMES[:dueties])}'" }
      else
        flash[:alert] = 'Cập nhật nhiệm vụ thất bại!'
        format.js { render :edit }
      end
    end
  end
  
  def destroy
    if @duety.can_be_deleted
      @duety.destroy
      flash[:notice] = 'Nhiệm vụ đã được xóa thành công!'
    else
      flash[:alert] = 'Đối với các nhiệm vụ đã được gán công việc, hệ thống sẽ không cho phép xóa. Để xóa nhiệm vụ, vui lòng xóa toàn bộ các công việc liên quan trước.'
    end
    
    render js: "window.location = '#{works_index_path(lang: session[:lang], tab: TAB_NAMES[:dueties])}'"
  end

  private
  
  def set_duety
    @duety = Tfunction.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.html { redirect_to tfunctions_path, alert: "Không tìm thấy nhiệm vụ" }
      format.js { render js: "alert('Không tìm thấy nhiệm vụ');" }
    end
  end

  def duety_params
    params.require(:tfunction).permit(:name, :scode, :sdesc, :sorg, :department_id, :parent)
  end
end
