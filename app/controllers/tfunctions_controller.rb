class TfunctionsController < ApplicationController
  include WorksHelper
  before_action :authorize
  before_action :set_tfunction, only: [:show, :edit, :update, :destroy]

  def index
    @tfunctions = Tfunction.all.sorted
    
    respond_to do |format|
      format.html
      format.js
    end
  end

  def new
    @tfunction = Tfunction.new
    
    respond_to do |format|
      format.html
      format.js
    end
  end
  
  def create
    @tfunction = Tfunction.new(tfunction_params)
    @tfunction.stype = 'FUNCTIONS'
    
    respond_to do |format|
      if @tfunction.save
        flash[:notice] = 'Thêm chức năng thành công!'
        format.js { render js: "window.location = '#{works_index_path(lang: session[:lang], tab: TAB_NAMES[:functions])}'" }
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
      if @tfunction.update(tfunction_params)
        flash[:notice] = 'Cập nhật chức năng thành công!'
        format.js { render js: "window.location = '#{works_index_path(lang: session[:lang], tab: TAB_NAMES[:functions])}'" }
      else
        format.js { render :edit }
      end
    end
  end
  
  def destroy
    if @tfunction.can_be_deleted
      @tfunction.destroy
      flash[:notice] = 'Chức năng đã được xóa thành công!'
    else
      flash[:alert] = 'Đối với các chức năng đã được gán nhiệm vụ, hệ thống sẽ không cho phép xóa. Để xóa chức năng, vui lòng xóa toàn bộ các nhiệm vụ liên quan trước.'
    end

    render js: "window.location = '#{works_index_path(lang: session[:lang], tab: TAB_NAMES[:functions])}'"
  end

  private
  
  def set_tfunction
    @tfunction = Tfunction.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.html { redirect_to tfunctions_path, alert: "Không tìm thấy chức năng" }
      format.js { render js: "alert('Không tìm thấy chức năng');" }
    end
  end

  def tfunction_params
    params.require(:tfunction).permit(:name, :scode, :sdesc, :sorg, :department_id)
  end
end