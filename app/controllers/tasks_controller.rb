class TasksController < ApplicationController
  include WorksHelper
  before_action :authorize
  before_action :set_task, only: [:show, :edit, :update, :destroy]

  def index
    respond_to do |format|
      format.html
      format.js
    end
  end

  def new
    @task = Stask.new
    @function_options = Tfunction.where(stype: 'FUNCTIONS').sorted.map { |f| [f.name, f.id] }
    @duety_options = Tfunction.where(stype: 'DUETIES').sorted.map { |f| [f.name, f.id] }
    respond_to do |format|
      format.html
      format.js
    end
  end
  
  def create
    message = 'Thêm công việc thành công!'
    created_media_ids = []
    ActiveRecord::Base.transaction do
      begin
        @task = Stask.new(task_params)
        @task.tfunction_id = params[:tfunction_id]
        @task.created_by = session[:user_id]
        @task.status = 'ACTIVE'
        @task.handling_process = 'APPROVED'

        if params[:tfunction_id].present?
          @selected_duety = Tfunction.find_by(id: params[:tfunction_id])
          @selected_function = Tfunction.find(@selected_duety.parent.to_i) if @selected_duety
        end

        files = params[:files] || []
        if !@task.save
          raise ActiveRecord::Rollback
        end
        files.each do |file|
          mediafile_id = upload_mediafile(file)
          created_media_ids << mediafile_id # lưu cho trường hợp rollback
          Taskdoc.create({
            mediafile_id:mediafile_id,
            stask_id:@task.id,
          })
        end
      rescue => e
        position = e.backtrace.to_json.html_safe.gsub("\`","")
        msg = e.message.gsub("\`","")
        message = 'Lỗi khi thêm công việc!'
        # remove medias
        created_media_ids.each do |id|
          Taskdoc.find_by(mediafile_id: id).destroy
          delete_mediadile(id)
        end
        Errlog.create({
          msg: msg,
          msgdetails: msg,
          surl: request.fullpath,
          owner: "#{session[:user_id]}/#{session[:user_fullname]}",
          dtaccess: DateTime.now,
        })
        raise ActiveRecord::Rollback
      end
    end

    flash[:notice] = message
    redirect_to works_index_path(lang: session[:lang], tab: TAB_NAMES[:tasks])

  end
  
  def show
    respond_to do |format|
      format.html
      format.js
    end
  end
  
  def edit
    @duety_options = Tfunction.where(stype: 'DUETIES').sorted.map { |f| [f.name, f.id] }
    @selected_duety = Tfunction.find(@task.tfunction_id) if !@task.tfunction_id.nil?
    @selected_function = Tfunction.find(@selected_duety.parent.to_i) if @selected_duety

    @stored_medias = []
    @stored_medias = Taskdoc.where(stask_id: @task.id).map do |doc|
      {
        doc_id:doc.id,
        file_name: doc.mediafile.file_name,
        file_type: doc.mediafile.file_type,
        file_size: doc.mediafile.file_size,
      }
    end

    respond_to do |format|
      format.html
      format.js
    end
  end
  
  def update
    message = "Cập nhật công việc thành công!"
    created_media_ids = []
    ActiveRecord::Base.transaction do
      begin
        @task.tfunction_id = params[:tfunction_id]
        if @task.update(task_params)
          message = "Cập nhật công việc thành công!"
        end
        # remove stored medias
        remove_taskdocs = params[:remove_taskdocs].split(",")
        taskdocs = Taskdoc.where(id: remove_taskdocs)
        taskdocs.each do |taskdoc|
          taskdoc.destroy
          delete_mediadile(taskdoc.mediafile_id)
        end

        # upload medias
        files = params[:files] || []

        files.each do |file|
          mediafile_id = upload_mediafile(file)
          created_media_ids << mediafile_id # lưu cho trường hợp rollback
          Taskdoc.create({
            mediafile_id:mediafile_id,
            stask_id:@task.id,
          })
        end
      rescue => e
        position = e.backtrace.to_json.html_safe.gsub("\`","")
        msg = e.message.gsub("\`","")
        message = "#{e.message} - Lỗi khi cập nhật công việc!"
        
        # remove medias
        created_media_ids.each do |id|
          Taskdoc.find_by(mediafile_id: id).destroy
          delete_mediadile(id)
        end
        Errlog.create({
          msg: e.message,
          msgdetails: e.message,
          surl: request.fullpath,
          owner: "#{session[:user_id]}/#{session[:user_fullname]}",
          dtaccess: DateTime.now,
        })
      end
    end

    flash[:notice] = message
    redirect_to works_index_path(lang: session[:lang], tab: TAB_NAMES[:tasks])
  end
  
  def destroy
    if @task.can_be_deleted
      @task.destroy
      flash[:notice] = 'Công việc đã được xóa thành công!'
    else
      flash[:alert] = 'Đối với các công việc đã được phân công cho nhân sự, hệ thống sẽ không cho phép xóa. Để xóa công việc, vui lòng gỡ bỏ toàn bộ các công việc liên quan đến các nhân sự trước.!'
    end

    render js: "window.location = '#{works_index_path(lang: session[:lang], tab: TAB_NAMES[:tasks])}'"
  end

  def get_duties
    search = params[:search]&.strip

    duties = Tfunction.select(:id, :name, :scode)
                      .where(stype: 'DUETIES', parent: params[:function_id], is_root: nil)
                      .order('created_at DESC')

    if search.present?
      duties = duties.where('LOWER(name) LIKE ?', "%#{search&.downcase}%")
    end

    items = duties.map { |f| { id: f.id, name: f.name, scode: f.scode } }
    if search.blank?
      items.unshift({ id: 0, name: "Chọn nhiệm vụ", scode: "" })
    end
    
    render json: { items: items }
  end

  def get_functions
    search = params[:search]&.strip
  
    functions = Tfunction.select(:id, :name, :scode)
                          .where(stype: 'FUNCTIONS', parent: nil, is_root: nil)
                          .order('created_at DESC')
    if search.present?
      functions = functions.where('LOWER(name) LIKE ?', "%#{search&.downcase}%")
    end

    items = functions.map { |f| { id: f.id, name: f.name, scode: f.scode } }

    if search.blank?
      items.unshift({ id: 0, name: "Chọn chức năng", scode: "" })
    end
  
    render json: { items: items }
  end

  private
  
  def set_task
    @task = Stask.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    respond_to do |format|
      format.html { redirect_to tasks_path, alert: "Không tìm thấy công việc" }
      format.js { render js: "alert('Không tìm thấy công việc');" }
    end
  end

  def task_params
    params.require(:stask).permit(:name, :scode, :desc, :dtfrom, :dtto, :created_by, :status, :frequency, :level_handling, :level_difficulty, :priority, :handling_process, :tfunction_id, :note, :gtask_id)
  end
end