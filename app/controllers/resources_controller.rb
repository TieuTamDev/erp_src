class ResourcesController < ApplicationController
  before_action :authorize   
    # Huy review 03/03/2023
  def edit 
    search = params[:search] || ''
    sql = Resource.where("url LIKE ? OR status LIKE ? OR app LIKE ?", "%#{search}%", "%#{search}%", "%#{search}%")
    @resources = pagination_limit_offset(sql, 10)
    @resource = Resource.new
  end

  def update
    id = params[:resource_id_add]
    sUrl = params[:resource_url_add].squish
    strScode = params[:resource_scode_add].squish
    strApp = params[:resource_app_add].squish
    strStatus = params[:resource_status_add].squish
    msg = lib_translate("Not_Success")
    if id == ''
      oResource = Resource.new
      oResource.url = sUrl
      oResource.scode = strScode
      oResource.app = strApp
      oResource.status = strStatus
      oResource.save
      msg = lib_translate("Create_successfully")
    else
      oResource = Resource.where("id = #{id}").first
      if !oResource.nil?
        oResource.update(
          {
            url: sUrl,
            scode: strScode,
            app: strApp,
            status: strStatus
          }
        )

        # update permission status
        stask_ids = Access.where(resource_id:oResource.id).pluck(:stask_id)
        user_ids = Work.where(stask_id:stask_ids).pluck(:user_id)
        updateUsersPermissionChange(user_ids)

        change_column_value = oResource.previous_changes
        change_column_name = oResource.previous_changes.keys
        if change_column_name  != ""
          for changed_column in change_column_name do 
              if changed_column != "updated_at"
                  fvalue = change_column_value[changed_column][0]
                  tvalue = change_column_value[changed_column][1]
  
                log_history(Resource, changed_column, fvalue ,tvalue, @current_user.email)
                
              end
          end  
        end   
        msg = lib_translate("Update_successfully")
      end
    end
    redirect_to resource_edit_path(lang: session[:lang],page: session[:page], per_page: session[:per_page], search: session[:search]), notice: msg
  end

  def required 
    oScode = params[:scode] 
    check_Scode = Resource.where(scode: oScode).first

    if check_Scode == nil
      render json:{result_scode: true}    
    else
      render json: {result_scode: false}    
    end     
  end

  def del
    id = params[:id]
    msg = lib_translate("Not_Success")
    oResource = Resource.where("id = #{id}").first
    if !oResource.nil?
      
      stask_ids = Access.where(resource_id:oResource.id).pluck(:stask_id)
      user_ids = Work.where(stask_id:stask_ids).pluck(:user_id)
      updateUsersPermissionChange(user_ids)

      oResource.destroy
      log_history(Resource, "Xóa", oResource.url , "Đã xóa khỏi hệ thống", @current_user.email)
      msg = lib_translate("Delete_successfully")
    end
    redirect_to resource_edit_path(lang: session[:lang],page: session[:page], per_page: session[:per_page], search: session[:search]), notice: msg
  end
end
