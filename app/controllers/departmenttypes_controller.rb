class DepartmenttypesController < ApplicationController
  before_action :authorize
  # Huy review 03/03/2023
  def index
    search = params[:search] || ''
    sql = Departmenttype.where("name LIKE ? OR scode LIKE ? OR status LIKE ?", "%#{search}%", "%#{search}%", "%#{search}%")
    @departmenttypes = pagination_limit_offset(sql, 10)
    @departmenttype = Departmenttype.new
  end

  def update
    id = params[:departmenttype_id]
    pName = params[:departmenttype_name]
    pScode = params[:departmenttype_scode]
    pStatus = params[:sel_status]
    msg = lib_translate("Not_Success")

    if id == ""
      departmenttype = Departmenttype.new
      departmenttype.id = id
      departmenttype.name = pName
      departmenttype.scode = pScode
      departmenttype.status = pStatus
      departmenttype.save
      msg = lib_translate("Create_successfully")
    else
      oDepartmenttype = Departmenttype.where("id = #{id}").first
      msg = lib_translate("Not_Success")
      if !oDepartmenttype.nil?
        oDepartmenttype.update({name: pName, scode: pScode, status: pStatus})
        #Save updated  history (Đạt 10/01/2023)
        change_column_value = oDepartmenttype.previous_changes
        change_column_name = oDepartmenttype.previous_changes.keys
        if change_column_name  != ""
            for changed_column in change_column_name do 
                if changed_column != "updated_at"
                  fvalue = change_column_value[changed_column][0]
                  tvalue = change_column_value[changed_column][1]            
                  log_history(Departmenttype, changed_column, fvalue ,tvalue, @current_user.email)
                end
            end  
        end  
        msg = lib_translate("Update_successfully")
      end
    end
    redirect_to departmenttype_index_path(lang: session[:lang],page: session[:page], per_page: session[:per_page], search: session[:search]), notice: msg
  end

  def del
    pId = params[:id]
    departmenttype = Departmenttype.where("id = #{pId}").first
    msg = lib_translate("Not_Success")
    if !departmenttype.nil?
      departmenttype.destroy
      log_history(Departmenttype, "Xóa", departmenttype.name , "Đã xóa khỏi hệ thống", @current_user.email)
      msg = lib_translate("Delete_successfully")
    end 
    redirect_to departmenttype_index_path(lang: session[:lang],page: session[:page], per_page: session[:per_page], search: session[:search]), notice: msg
  end
end