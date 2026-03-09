class EthnicsController < ApplicationController
    before_action :authorize
    def index 
        search = params[:search] || ''
        sql = Ethnic.where("name LIKE ? OR scode LIKE ? OR status LIKE ?", "%#{search}%", "%#{search}%", "%#{search}%")
        @ethnics = pagination_limit_offset(sql, 10)
        @ethnic = Ethnic.new
    end

    def update
        id = params[:ethnic_id_add]
        sName = params[:ethnic_name_add].squish
        strScode = params[:ethnic_scode_add].squish
        strStatus = params[:ethnic_status_add].squish
        msg = lib_translate("Not_Success")
        if id == ''
            ethnic = Ethnic.new
            ethnic.name = sName
            ethnic.scode = strScode
            ethnic.status = strStatus
            ethnic.save
            msg = lib_translate("Create_successfully")
        else
            ethnic = Ethnic.where("id = #{id}").first
            if !ethnic.nil?
                ethnic.update(
                    {
                        name: sName,
                        scode: strScode,
                        status: strStatus
                    }
                )
    
                change_column_value = ethnic.previous_changes
                change_column_name = ethnic.previous_changes.keys
                if change_column_name  != ""
                  for changed_column in change_column_name do 
                      if changed_column != "updated_at"
                          fvalue = change_column_value[changed_column][0]
                          tvalue = change_column_value[changed_column][1]
                          
                        log_history(Ethnic, changed_column, fvalue ,tvalue, @current_user.email)
                        
                      end
                  end  
                end   
                msg = lib_translate("Update_successfully")
            end
        end
        redirect_to ethnic_index_path(lang: session[:lang],page: session[:page], per_page: session[:per_page], search: session[:search]), notice: msg
    end

    def del
        id = params[:id]
        msg = lib_translate("Not_Success")
        ethnic = Ethnic.where("id = #{id}").first
        if !ethnic.nil?
            ethnic.destroy
            log_history(Ethnic, "Xóa", ethnic.name , "Đã xóa khỏi hệ thống", @current_user.email)
            msg = lib_translate("Delete_successfully")
        end

        redirect_to ethnic_index_path(lang: session[:lang],page: session[:page], per_page: session[:per_page], search: session[:search]), notice: msg
    end

    
  
end