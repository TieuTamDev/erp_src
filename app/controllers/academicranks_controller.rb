class AcademicranksController < ApplicationController
  before_action :authorize
    # Huy review 03/03/2023
  def index 
    search = params[:search] || ''
    sql = Academicrank.where("name LIKE ? OR scode LIKE ? OR status LIKE ?", "%#{search}%", "%#{search}%", "%#{search}%")
    @academicranks = pagination_limit_offset(sql, 10)
    @academicrank = Academicrank.new
  end

  def update
    id = params[:academicrank_id]
    pName = params[:academicrank_name]
    pScode = params[:academicrank_scode]
    pStatus = params[:sel_status]  
    msg = lib_translate("Not_Success")
    if id == ""
      academicrank = Academicrank.new
      academicrank.id = id
      academicrank.name = pName
      academicrank.scode = pScode
      academicrank.status = pStatus
      academicrank.save
      msg = lib_translate("Create_successfully")
    else
      oacademicrank = Academicrank.where("id = #{id}").first
      if !oacademicrank.nil?
        oacademicrank.update({name: pName, scode: pScode, status: pStatus})
        #Save updated  history (Đạt 10/01/2023)
        change_column_value = oacademicrank.previous_changes
        change_column_name = oacademicrank.previous_changes.keys
        if change_column_name  != ""
          for changed_column in change_column_name do 
              if changed_column != "updated_at"
                  fvalue = change_column_value[changed_column][0]
                  tvalue = change_column_value[changed_column][1]                   
                  log_history(Academicrank, changed_column, fvalue ,tvalue, @current_user.email)                  
              end
          end  
        end   
        msg = lib_translate("Update_successfully")
      end
    end
    redirect_to academicrank_index_path(lang: session[:lang],page: session[:page], per_page: session[:per_page], search: session[:search]), notice: msg

  end

  def del
    pId = params[:id]
    academicrank = Academicrank.where("id = #{pId}").first
    if !academicrank.nil?
      academicrank.destroy
      log_history(Academicrank, "Xóa", academicrank.name , "Đã xóa khỏi hệ thống", @current_user.email)
      msg = lib_translate("Delete_successfully")
    end
    redirect_to academicrank_index_path(lang: session[:lang],page: session[:page], per_page: session[:per_page], search: session[:search]), notice: msg
  end
end