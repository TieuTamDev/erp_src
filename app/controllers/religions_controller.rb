class ReligionsController < ApplicationController
    before_action :authorize    
  # Huy review 03/03/2023
    def index 
        search = params[:search] || ''
        sql = Religion.where("name LIKE ? OR scode LIKE ? OR status LIKE ?", "%#{search}%", "%#{search}%", "%#{search}%")
        @religions = pagination_limit_offset(sql, 10)
        @religion = Religion.new   
    end

    def update
        id = params[:religions_id_add]
        sName = params[:religions_name_add].squish
        strScode = params[:religions_scode_add].squish
        strStatus = params[:religions_status_add].squish
        msg = lib_translate("Not_Success")

        if id == ''
            oReligions = Religion.new
            oReligions.name = sName
            oReligions.scode = strScode
            oReligions.status = strStatus
            oReligions.save
            msg = lib_translate("Create_successfully")

        else
            oReligions = Religion.where("id = #{id}").first
            if !oReligions.nil?
                oReligions.update(
                {
                    name: sName,
                    scode: strScode,
                    status: strStatus
                }
                )
    
                change_column_value = oReligions.previous_changes
                change_column_name = oReligions.previous_changes.keys
                if change_column_name  != ""
                  for changed_column in change_column_name do 
                      if changed_column != "updated_at"
                          fvalue = change_column_value[changed_column][0]
                          tvalue = change_column_value[changed_column][1]                      
                        log_history(Religion, changed_column, fvalue ,tvalue, @current_user.email)
                      end
                  end  
                end   
                msg = lib_translate("Update_successfully")
            end

        end
        redirect_to religions_index_path(lang: session[:lang],page: session[:page], per_page: session[:per_page], search: session[:search]), notice: msg

    end      
  
    def del
        id = params[:id]
        msg = lib_translate("Not_Success")
        oReligion = Religion.where("id = #{id}").first
        if !oReligion.nil?
            oReligion.destroy
            log_history(Religion, "Xóa", oReligion.name , "Đã xóa khỏi hệ thống", @current_user.email)
            msg = lib_translate("Delete_successfully")
        end
        redirect_to religions_index_path(lang: session[:lang],page: session[:page], per_page: session[:per_page], search: session[:search]), notice: msg
    end
end
  
 
