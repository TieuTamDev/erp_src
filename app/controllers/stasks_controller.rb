class StasksController < ApplicationController
  before_action :authorize
  def index
    @access = Access.all
    @resource = Resource.all
    @permisions = Permission.all
    @acces = Access.new
    @stask = Stask.new
    @users = User.all
    search = params[:search] || ''
    sql = Stask.where("name LIKE ? OR created_by LIKE ?", "%#{search}%", "%#{search}%")
    @stasks = pagination_limit_offset(sql, 10)
  end

  def del_user_asign
    arrIdUser = params[:user_checked].split(",")
    id_stask = params[:id_stask]
    msg = lib_translate("Not_success")
    if !arrIdUser.nil? && !arrIdUser.empty? && arrIdUser != ""
      update_ids = []
      arrIdUser.each do |id_user|
        oWork = Work.where(positionjob_id: nil, stask_id: id_stask, user_id: id_user).first
        if !oWork.nil?
          update_ids.push(id_user)
          oWork.destroy
          msg = lib_translate("Success")
        end
      end
      # update permission status
      if !update_ids.nil?
        updateUsersPermissionChange(update_ids)
      end
    end
    redirect_to stask_edit_path(lang: session[:lang],page: session[:page], per_page: session[:per_page], search: session[:search]),notice: msg
  end

  def del_work
    id_stask = params[:id_stask]
    name_stask = params[:name_stask]
    oWork = Work.where(positionjob_id: nil, stask_id: id_stask)

    # update permission status
    user_ids = oWork.pluck(:user_id)
    updateUsersPermissionChange(user_ids)

    msg = lib_translate("Not_success")
    if !oWork.nil?
      oWork.destroy_all
      log_history("Công việc kiêm nhiệm", "Xóa", name_stask, "Đã xóa khỏi hệ thống", @current_user.email)
      msg = lib_translate("Delete_successful_stask")
    end
    redirect_to stask_edit_path(lang: session[:lang],page: session[:page], per_page: session[:per_page], search: session[:search]),notice: msg
  end

  def edit
    search = params[:search] || ''
    sql = Work.joins(:stask).where(positionjob_id: nil).where.not(stask_id: nil).where("name LIKE ?", "%#{search}%")
    per_page = params[:per_page]&.to_i || 10
    page = params[:page]&.to_i || 1
    search = params[:search] || ''

    offset = (page - 1) * per_page
    @total_records = sql.group(:stask_id, :positionjob_id).count.size
    total_pages = (@total_records.to_f / per_page.to_f).ceil

    session[:per_page] = per_page
    session[:page] = page
    session[:search] = search
    session[:total_pages] = total_pages

    @oWorks = sql.order(created_at: :desc).limit(per_page).offset(offset)
  end

  def asign_stask_user
    arrIdUser = params[:user_checked].split(",")
    id_stask = params[:id_stask]
    msg = lib_translate("Not_success")
    if !arrIdUser.nil? && !arrIdUser.empty? && arrIdUser != ""
      arrIdUser.each do |id_user|
        oWork = Work.where(user_id: id_user, stask_id: id_stask).first
        if oWork.nil?
          Work.create({
            user_id: id_user,
            status: "ACTIVE",
            stask_id: id_stask,
          })
        end
      end
      # update permission status
      update_ids = Work.where(stask_id: id_stask).pluck(:user_id)
      if !update_ids.nil?
        updateUsersPermissionChange(update_ids)
      end
      msg = lib_translate("Success")
    end
    redirect_to stasks_index_path(lang: session[:lang],page: session[:page], per_page: session[:per_page], search: session[:search]),notice: msg
  end

  def list_user_asign_stask
    id_stask = params[:id_stask]
    datas = []
    if !id_stask.nil? && id_stask != ""
      oWorks = Work.where(stask_id: id_stask)
      oWorks.each do |work|
        department_name = ""
        job_name = ""
        works = work.user.works
        works.each do |work|
            if !work.positionjob.nil? && !work.positionjob.department.nil?
              department_name = work.positionjob.department.name
              job_name = work.positionjob.name
            end
        end
        datas.append({
          "id" => !work.user.nil? ? work.user.id : '',
          "full_name" => "#{!work.user.nil? ? work.user.last_name : ''} #{!work.user.nil? ? work.user.first_name : ''}",
          "email" => !work.user.nil? ? work.user.email : '',
          "department_name" => department_name,
          "job_name" => job_name,
        })
      end
      datas.uniq
    end
    respond_to do |format|
        format.js { render js: "getListUserAsignStask(#{datas.to_json.html_safe})"}
    end
  end

  def access_update
    stask_id = params[:stask_id]
    resource_scode = params[:resource_scode]
    permission = params[:permission]
    msg = lib_translate("Edit_successfully")

    if permission.nil?
      Access.where({resource_id: Resource.where(scode: resource_scode).pluck(:id) , stask_id: stask_id.to_i}).destroy_all
      resource_scode.each do |resource|
        @access = Access.new
        @access.stask_id = stask_id
        @access.resource_id = Resource.where("scode = '#{resource}'").first.id
        @access.permision = permission
        @access.save
      end
      msg = lib_translate("Edit_successfully")

    else
      # xoa toa bo access cu
      Access.where({resource_id: Resource.where("scode = '#{resource_scode}'").first.id , stask_id: stask_id.to_i}).destroy_all
      # capnhat access moi
      permission.each do |permission|
        @access = Access.new
        @access.stask_id = stask_id
        @access.resource_id = Resource.where("scode = '#{resource_scode}'").first.id
        @access.permision = permission
        @access.save
        msg = lib_translate("Edit_successfully")
      end
    end
    session[:table_stask_id] = stask_id

    # update permission status
    update_ids = Work.where(stask_id: stask_id).pluck(:user_id)
    if !update_ids.nil?
      updateUsersPermissionChange(update_ids)
    end

    redirect_to stasks_index_path(lang: session[:lang],page: session[:page], per_page: session[:per_page], search: session[:search]),notice: msg
  end

  def access_del
    sid = params[:id]
    stask_id = params[:stask_id]
    resource_id = params[:resource_id]
    ck_action = params[:ck_action]
    table_stask_id = params[:table_stask_id]
    msg = lib_translate("Not_success")
    if !ck_action.nil?
      Access.where({resource_id: resource_id.to_i, stask_id: stask_id.to_i}).destroy_all
      msg = lib_translate("Delete_resource_successfully")
    else
      @access = Access.where("id = #{sid}").first
      @access.destroy
      if @acces.nil?
        @access = Access.new
        if !stask_id.nil?
          @access.stask_id = stask_id
        end
        if !resource_id.nil?
          @access.resource_id = resource_id
        end
        @access.save
      end
      msg = lib_translate("Delete_resource_successfully")
    end
    session[:table_stask_id] = stask_id

    # update permission status
    update_ids = Work.where(stask_id: stask_id).pluck(:user_id)
    if !update_ids.nil?
      updateUsersPermissionChange(update_ids)
    end

    redirect_to stasks_index_path(lang: session[:lang],page: session[:page], per_page: session[:per_page], search: session[:search]),notice: msg
  end

  def update
    id = params[:stask_id]
    sName = params[:txt_name]
    sScode = params[:txt_scode]
    if params[:txt_desc] != ""
      sDesc = params[:txt_desc].gsub(/\s+/, " ").strip
    end

    sCreateby = params[:created_by]
    sStatus = params[:sel_status]

    if id == ""
      oStask = Stask.new
      oStask.name = sName
      oStask.scode = sScode
      oStask.desc = sDesc
      oStask.created_by = sCreateby
      oStask.status = sStatus
      oStask.save
      redirect_to stasks_index_path(lang: session[:lang],page: session[:page], per_page: session[:per_page], search: session[:search]),notice: lib_translate("Add_successful_stask")
    else
      oStask = Stask.where("id = #{id}").first
      oStask.update({name: sName, scode: sScode, desc: sDesc,created_by:sCreateby , status: sStatus });

      change_column_value = oStask.previous_changes
      change_column_name = oStask.previous_changes.keys
      if change_column_name  != ""
        for changed_column in change_column_name do
            if changed_column != "updated_at"
                fvalue = change_column_value[changed_column][0]
                tvalue = change_column_value[changed_column][1]
              log_history(Stask, changed_column, fvalue ,tvalue, @current_user.email)
            end
        end
      end

      # # update permission status
      # update_ids = Work.where(stask_id: id).pluck(:user_id)
      # if !update_ids.nil?
      #   updateUsersPermissionChange(update_ids)
      # end

      redirect_to stasks_index_path(lang: session[:lang],page: session[:page], per_page: session[:per_page], search: session[:search]),notice: lib_translate("Update_successful_stask")

    end
        # redirect_to stasks_index_path(lang: session[:lang],page: session[:page], per_page: session[:per_page], search: session[:search]),notice: lib_translate("Add_successful_stask")
  end

  def del
    sid = params[:id]
    oStask = Stask.find_by("id = #{sid}")
    # update permission status
    update_ids = Work.where(stask_id: sid).pluck(:user_id)
    if !update_ids.nil?
      updateUsersPermissionChange(update_ids)
    end

    msg = lib_translate("Not_success")
    if !oStask.nil?
      oStask.destroy
      log_history(Stask, "Xóa", oStask.name , "Đã xóa khỏi hệ thống", @current_user.email)
      msg = lib_translate("Delete_successful_stask")
    end
    redirect_to stasks_index_path(lang: session[:lang],page: session[:page], per_page: session[:per_page], search: session[:search]),notice: msg
  end
end
