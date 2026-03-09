class PermissionsController < ApplicationController
  before_action :authorize
    # Huy review 03/03/2023
  def index 
    search = params[:search] || ''
    sql = Permission.where("name LIKE ? OR scode LIKE ? OR status LIKE ?", "%#{search}%", "%#{search}%", "%#{search}%")
    @permissions = pagination_limit_offset(sql, 10)
    @permission = Permission.new
  end

  def check_unique_per
    perId= params[:per_id]
    perName = params[:check_pername]

    ckPer= Permission.where(scode: perName).first
    check_per = Permission.where(id: perId).first
    if !check_per.nil?
        if check_per.scode == perName 
          render json: {result: 'false'}
        else
            if ckPer.nil?
              render json: {results: 'false'}
            else
              render json: {results: 'true', scode: perName}
            end
        end
    else
        if ckPer.nil?
          render json: {msg: 'false'}  
        else
          render json:{ msg: 'true', scode: perName}
        end
    end
  end

  def update
    id = params[:per_id]
    pName = params[:per_name]
    pScode = params[:per_scode]
    pStatus = params[:sel_status]
    msg = lib_translate("Not_Success")

    if id == ""
      permission = Permission.new
      permission.id = id
      permission.name = pName
      permission.scode = pScode
      permission.status = pStatus
      permission.save
      msg = lib_translate("Create_successfully")
    else
      oPermission = Permission.where("id = #{id}").first
      if !oPermission.nil?
        oPermission.update({name: pName, scode: pScode, status: pStatus})
        change_column_value = oPermission.previous_changes
        change_column_name = oPermission.previous_changes.keys
        if change_column_name  != ""
          for changed_column in change_column_name do 
              if changed_column != "updated_at"
                  fvalue = change_column_value[changed_column][0]
                  tvalue = change_column_value[changed_column][1]
  
                log_history(Permission, changed_column, fvalue ,tvalue, @current_user.email)
                
              end
          end  
        end
        msg = lib_translate("Update_successfully")   
      end
    end
    redirect_to permissions_index_path(lang: session[:lang],page: session[:page], per_page: session[:per_page], search: session[:search]), notice: msg
  end

  def del
    pId = params[:id]
    msg = lib_translate("Not_Success")
    permission = Permission.where("id = #{pId}").first
    if !permission.nil?
      permission.destroy
      log_history(Permission, "Xóa", permission.name , "Đã xóa khỏi hệ thống", @current_user.email)
      msg = lib_translate("Delete_successfully")
    end
    redirect_to permissions_index_path(lang: session[:lang],page: session[:page], per_page: session[:per_page], search: session[:search]), notice: msg
  end
end
