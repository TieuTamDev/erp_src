class ContracttypesController < ApplicationController
  before_action :authorize
    # Huy review 03/03/2023
  def index
    search = params[:search] || ''
    sql = Contracttype.where("name LIKE ? OR scode LIKE ? OR status LIKE ?", "%#{search}%", "%#{search}%", "%#{search}%")
    @contracttypes = pagination_limit_offset(sql, 10)
    @contracttype = Contracttype.new
  end

  def update
    id = params[:contracttype_id]
    pName = params[:contracttype_name]
    pScode = params[:contracttype_scode]
    sel_is_seniority = params[:sel_is_seniority]
    is_official      = params[:is_official]
    pStatus = params[:sel_status]
    msg = lib_translate("Not_Success")
    final_is_seniority =
          if sel_is_seniority == "NO"
            "NO"
          else
            is_official == "YES" ? "YES_OFFICIAL" : "YES_PROBATION"
          end
    if id == ""
      contracttype = Contracttype.new
      contracttype.id = id
      contracttype.name = pName
      contracttype.scode = pScode
      contracttype.status = pStatus
      contracttype.is_seniority = final_is_seniority
      contracttype.save
      msg = lib_translate("Create_successfully")
    else
      ocontracttype = Contracttype.where("id = #{id}").first
      if !ocontracttype.nil?
        ocontracttype.update({name: pName, scode: pScode, status: pStatus, is_seniority: final_is_seniority})
        #Save updated  history (Đạt 10/01/2023)
        change_column_value = ocontracttype.previous_changes
        change_column_name = ocontracttype.previous_changes.keys
        if change_column_name  != ""
          for changed_column in change_column_name do 
              if changed_column != "updated_at"
                fvalue = change_column_value[changed_column][0]
                tvalue = change_column_value[changed_column][1]                
                log_history(Contracttype, changed_column, fvalue ,tvalue, @current_user.email)
              end
            end  
          end   
          #end Save updated  history      
          msg = lib_translate("Update_successfully")
      end
    end
    redirect_to contracttype_index_path(lang: session[:lang],page: session[:page], per_page: session[:per_page], search: session[:search]), notice: msg
  end

  def del
    pId = params[:id]
    contracttype = Contracttype.where("id = #{pId}").first
    msg = lib_translate("Not_Success")
    if !contracttype.nil?
      contracttype.destroy
      log_history(Contracttype, "Xóa", contracttype.name , "Đã xóa khỏi hệ thống", @current_user.email) 
      msg = lib_translate("Delete_successfully")     
    end
    redirect_to contracttype_index_path(lang: session[:lang],page: session[:page], per_page: session[:per_page], search: session[:search]), notice: msg
  end
end