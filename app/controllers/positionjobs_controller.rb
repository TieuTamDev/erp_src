class PositionjobsController < ApplicationController
  before_action :authorize    
  skip_before_action :verify_authenticity_token
  before_action :set_positionjob, only: [:show, :edit, :update, :destroy]
  def index

    @positionjobs = Positionjob.all

    @stasks = Stask.where(status: "ACTIVE")

    @departments = Department.all

    @user= User.where.not(email:"admin@gmail.com")

    @positionjob = Positionjob.new
    
  end
  def edit
    idCkdub = params[:id]
    nameUp = params[:name]
    scode = params[:scode]
    department_id = params[:department_id]
    ckNamePositionjob = Positionjob.where(name: nameUp, department_id: department_id).where.not(id: idCkdub).first
    ckScodePositionjob = Positionjob.where(scode: scode, department_id: department_id).where.not(id: idCkdub).first
    ckNamePositionjobNew = Positionjob.where(name: nameUp, department_id: department_id).first
    ckScodePositionjobNew = Positionjob.where(scode: scode, department_id: department_id).first

    nameDepartment = Department.where(id: department_id).first
    ckPositionjobScode = Positionjob.where(id:idCkdub).first


    # if  !ckPositionjobScode.nil?
    #     if  ckPositionjobScode.name==nameUp && ckPositionjobScode.scode == scode 
    #       render json: {result: 'false', id: ckPositionjobScode.id}
    #     else
    #         if  !ckNamePositionjob.nil? 
    #           render json: {results: 'true', name: nameUp,  department_id: ckNamePositionjob.department.name, id: ckPositionjobScode.id}
    #         elsif !ckScodePositionjob.nil?
    #           render json: {results: 'true', scode: scode , department_id: ckScodePositionjob.department.name, id: ckPositionjobScode.id}
    #         else
    #           render json: {results: 'false' , id: ckPositionjobScode.id}
    #         end
    #     end
    # else
    #     if  !ckNamePositionjob.nil? 
    #       render json: {msg: 'true', name: nameUp, department_id: nameDepartment.name, id: Positionjob.ids.last}
    #     elsif !ckScodePositionjob.nil?
    #       render json: {msg: 'true', scode:scode, department_id: nameDepartment.name, id: Positionjob.ids.last}
    #     else
    #       render json: {msg: 'false'}
    #     end
    # end
    if  !ckPositionjobScode.nil?
      if  ckPositionjobScode.name == nameUp && ckPositionjobScode.scode == scode && "#{!ckPositionjobScode.department.nil? ? ckPositionjobScode.department.id : ""}" == department_id
        render json: {result: 'false', id: ckPositionjobScode.id}
      elsif !ckNamePositionjob.nil?
        render json: {result: 'true', name: nameUp, department_id: nameDepartment.name, id: ckPositionjobScode.id}
      elsif !ckScodePositionjob.nil?
        render json: {result: 'true', scode: scode, department_id: nameDepartment.name, id: ckPositionjobScode.id}
      else
        render json: {result: 'false'}
      end
    else
      if !ckNamePositionjobNew.nil?
        render json: {result: 'true', name: nameUp, department_id: ckNamePositionjobNew.department.name, id: Positionjob.ids.last}
      elsif !ckScodePositionjobNew.nil?
        render json: {result: 'true', scode: scode, department_id: ckScodePositionjobNew.department.name, id: Positionjob.ids.last}
      else
        render json: {result: 'false', id: Positionjob.ids.last}
      end
    end
  end

  def update
    id= params[:txt_id_pj]
    name =params[:txt_name_pj]
    sCode = params[:txt_scode_pj]
    desc = params[:txt_desc_pj]
    department_id= params[:txt_department_id_pj]
    create_by = params[:txt_create_by_pj]
    selStatus= params[:sel_status_pj]
    ignore_attend = params[:ignore_attend] 

        if id == "" || id.nil?
          oPositionjobs = Positionjob.new
          oPositionjobs.name = name
          oPositionjobs.scode = sCode
          oPositionjobs.note = desc
          oPositionjobs.department_id = department_id
          oPositionjobs.created_by = create_by
          oPositionjobs.status = selStatus
          oPositionjobs.ignore_attend = ignore_attend
          if oPositionjobs.save
            
            # update user permission status
            update_ids = Work.where(positionjob_id:oPositionjobs.id).pluck(:user_id)
            updateUsersPermissionChange(update_ids)

            flash[:notice] = lib_translate('Successfully_updated_position_job')
            redirect_to positionjobs_index_path(lang: session[:lang])
            session[:positionjob_id] = oPositionjobs.id
          end 
        else
          oPositionjobs = Positionjob.where(id: id).first
          oPositionjobs.update({name: name, scode: sCode ,note: desc , department_id: department_id, created_by: create_by, status: selStatus, ignore_attend: ignore_attend});
          # update user permission status
          update_ids = Work.where(positionjob_id:id).pluck(:user_id)
          updateUsersPermissionChange(update_ids)

          session[:positionjob_id] = id
          change_column_value = oPositionjobs.previous_changes
          change_column_name = oPositionjobs.previous_changes.keys
          if change_column_name  != ""
            for changed_column in change_column_name do 
                if changed_column != "updated_at"
                    fvalue = change_column_value[changed_column][0]
                    tvalue = change_column_value[changed_column][1]
  
                  log_history(Positionjob, changed_column, fvalue ,tvalue, @current_user.email)
                  
                end
            end  
          end   

          if oPositionjobs.save
            flash[:notice] = lib_translate('Successfully_updated_position_job')
            redirect_to positionjobs_index_path(lang: session[:lang])
          end 
        end
   
  end

  def update_responsible
   
    list_id_tasks= params[:tasks]
    namepositionjob= params[:namejob]
    positionjobs = Positionjob.where(id: namepositionjob).first
    idJobPos= params[:idJobPos]

    arr_tasks = []
    info_job=[]

    user_ids = []
    if idJobPos.nil? || idJobPos == ""

      if list_id_tasks.nil? || list_id_tasks == ""
        oResponsible = Responsible.where(positionjob_id: positionjobs.id).delete_all
        
        render json: {
          msg: "true",
        }
      else
        oResponsible = Responsible.where( positionjob_id: positionjobs.id).delete_all

        list_id_tasks.each do |id_task|
          positionjobs.responsibles.create({
            stask_id: id_task,
            desc: positionjobs.note,
            status: positionjobs.status
          })
        end 
        render json: {
          msg: "true",
        } 
        
      end

    else

      positionjobs = Positionjob.where(id: idJobPos).first
      
      positionjobs.responsibles.each do |task|
        arr_tasks.push({name: task.stask.name, id: task.stask.id} )
      end

      render json: {arr_tasks: arr_tasks , info_job: positionjobs,name: User.select(:first_name, :last_name).where(id: positionjobs.created_by).first}
      
    end
  end
 
  def del
    id = params[:id]
    id_responsible = params[:id_reponsible]
    if !id.nil? 
      oWorks = Work.where(positionjob_id: id)
      if !oWorks.nil?
        oWorks.each do |oWork|
          oWork.update({
            positionjob_id: "",
          })
        end
      end

      # update user permission status
      update_ids = oWorks.pluck(:user_id)
      updateUsersPermissionChange(update_ids)

      @oPositionjobs = Positionjob.where(id: id).first
      @oPositionjobs.destroy

      session[:positionjob_id] = ""
      log_history(Positionjob, "Xóa", @oPositionjobs.name , "Đã xóa khỏi hệ thống", @current_user.email)
      redirect_to positionjobs_index_path(lang: session[:lang]),notice: lib_translate("Successfully_deleted_position_job")
    else  
      reponsibles = Responsible.where(id: id_responsible).first
      
      # update user permission status
      positionjob_id = reponsibles.positionjob_id
      update_ids = Work.where(positionjob_id:positionjob_id).pluck(:user_id)
      updateUsersPermissionChange(update_ids)

      reponsibles.destroy

      redirect_to positionjobs_index_path(lang: session[:lang])
    end
  end
  def hrlist_index
  
  end
  def authority_level
    search = params[:search].to_s.strip || ''
    sql = Positionjob.left_outer_joins(:department)
                      .where(is_root: nil)
                      .where("positionjobs.name LIKE ? OR positionjobs.scode LIKE ? OR departments.name LIKE ?", "%#{search}%", "%#{search}%", "%#{search}%")
                      .order('created_at DESC')
    @positionjobs = pagination_limit_offset(sql, 10)
  end
  def new
    @positionjob = Positionjob.new
    respond_to do |format|
      format.html
      format.js
    end
  end
  def show
    respond_to do |format|
      format.html
      format.js
    end
  end
  def update
    respond_to do |format|
      if @positionjob.update(positionjob_params)
        flash[:notice] = 'Cập nhật cấp quyền hạn thành công!'
        format.js { render js: "window.location = '#{positionjob_authority_level_path(lang: session[:lang])}'" }
      else
        format.js { render :edit }
      end
    end
  end
  def edit
    @positionjob = Positionjob.find(params[:id])
    respond_to do |format|
      format.html
      format.js
    end
  end
  def create
    @positionjob = Positionjob.new(positionjob_params)
  
    respond_to do |format|
      if @positionjob.save
        flash[:notice] = 'Thêm cấp quyền hạn thành công!'
        format.js { render js: "window.location = '#{positionjob_authority_level_path(lang: session[:lang])}'" }
      else
        format.js { render :new }
      end
    end
  end
  def destroy
    if @positionjob.can_be_deleted
      @positionjob.destroy
      flash[:notice] = 'Cấp quyền hạn đã được xóa thành công!'
    else
      flash[:alert] = 'Đối với các cấp quyền hạn đã được gán cho nhân sự, hệ thống sẽ không cho phép xóa. Để xóa cấp quyền hạn, vui lòng xóa toàn bộ các quyền hạn liên quan tới các nhân sự trước!'
    end

    render js: "window.location = '#{positionjob_authority_level_path(lang: session[:lang])}'"
  end
  def set_positionjob
    @positionjob = Positionjob.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      respond_to do |format|
        format.html { redirect_to tfunctions_path, alert: "Không tìm thấy chức năng" }
        format.js { render js: "alert('Không tìm thấy chức năng');" }
      end
    end
  def positionjob_params
    params.require(:positionjob).permit(:name, :scode, :note, :iorder, :amount, :ignore_attend)
  end
end
