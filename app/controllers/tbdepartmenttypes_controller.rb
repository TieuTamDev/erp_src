class TbdepartmenttypesController < ApplicationController
  before_action :authorize  
  # Huy review 03/03/2023
    def index 
        search = params[:search] || ''
        sql = Tbdepartmenttype.where("name LIKE ? OR scode LIKE ? OR status LIKE ?", "%#{search}%", "%#{search}%", "%#{search}%")
        @tbdepartmenttypes = pagination_limit_offset(sql, 10)
        @tbdepartmenttype = Tbdepartmenttype.new
    end 
    def update
        id = params[:tbdepartmenttypes_id_add]
        sName = params[:tbdepartmenttypes_name_add].squish
        strScode = params[:tbdepartmenttypes_scode_add].squish
        strStatus = params[:tbdepartmenttypes_status_add].squish
        msg = lib_translate("Not_Success")
        if id == ''
            tbdepartmenttypess = Tbdepartmenttype.new
            tbdepartmenttypess.name = sName
            tbdepartmenttypess.scode = strScode
            tbdepartmenttypess.status = strStatus
            tbdepartmenttypess.save
            msg = lib_translate("Create_successfully")
        else
            tbdepartmenttypess = Tbdepartmenttype.where("id = #{id}").first
            if !tbdepartmenttypess.nil?
                tbdepartmenttypess.update(
                    {
                        name: sName,
                        scode: strScode,
                        status: strStatus
                    }
                )
    
                change_column_value = tbdepartmenttypess.previous_changes
                change_column_name = tbdepartmenttypess.previous_changes.keys
                if change_column_name  != ""
                    for changed_column in change_column_name do 
                        if changed_column != "updated_at"
                            fvalue = change_column_value[changed_column][0]
                            tvalue = change_column_value[changed_column][1]
                            log_history(Tbdepartmenttype, changed_column, fvalue ,tvalue, @current_user.email)
                        end
                    end  
                end   
                msg = lib_translate("Update_successfully")
            end
        end
        redirect_to tbdepartmenttypes_index_path(lang: session[:lang],page: session[:page], per_page: session[:per_page], search: session[:search]), notice: msg
    end 
    def del
        id = params[:id]
        tbdepartmenttypess = Tbdepartmenttype.where("id = #{id}").first
        msg = lib_translate("Not_Success")
        if !tbdepartmenttypess.nil?
            tbdepartmenttypess.destroy
            log_history(Tbdepartmenttype, "Xóa", tbdepartmenttypess.name , "Đã xóa khỏi hệ thống", @current_user.email)
            msg = lib_translate("Delete_successfully")
        end
        redirect_to tbdepartmenttypes_index_path(lang: session[:lang],page: session[:page], per_page: session[:per_page], search: session[:search]), notice: msg
    end 
end  