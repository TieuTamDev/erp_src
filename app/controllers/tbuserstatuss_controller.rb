class TbuserstatussController < ApplicationController
    before_action :authorize
      # Huy review 03/03/2023
    def index
        search = params[:search] || ''
        sql = Tbuserstatus.where("name LIKE ? OR scode LIKE ? OR status LIKE ?", "%#{search}%", "%#{search}%", "%#{search}%")
        @tbuserstatuss = pagination_limit_offset(sql, 10)
        @tbuserstatus = Tbuserstatus.new
    end

    def update
        id = params[:tbuserstatus_id_add]
        sName = params[:tbuserstatus_name_add].squish
        strScode = params[:tbuserstatus_scode_add].squish
        strStatus = params[:tbuserstatus_status_add].squish
        msg = lib_translate("Not_Success")
        if id == ''
            tbuserstatus = Tbuserstatus.new
            tbuserstatus.name = sName
            tbuserstatus.scode = strScode
            tbuserstatus.status = strStatus
            tbuserstatus.save
            msg = lib_translate("Create_successfully")
        else
            tbuserstatus = Tbuserstatus.where("id = #{id}").first
            if !tbuserstatus.nil?
                tbuserstatus.update(
                    {
                        name: sName,
                        scode: strScode,
                        status: strStatus
                    }
                )
    
                change_column_value = tbuserstatus.previous_changes
                change_column_name = tbuserstatus.previous_changes.keys
                if change_column_name  != ""
                    for changed_column in change_column_name do 
                        if changed_column != "updated_at"
                            fvalue = change_column_value[changed_column][0]
                            tvalue = change_column_value[changed_column][1]
                            log_history(Tbuserstatus, changed_column, fvalue ,tvalue, @current_user.email)
                        end
                    end  
                end  
                msg = lib_translate("Update_successfully")
            end
        end
        redirect_to tbuserstatus_index_path(lang: session[:lang],page: session[:page], per_page: session[:per_page], search: session[:search]), notice: msg
    end

    def del
        id = params[:id]
        msg = lib_translate("Not_Success")
        tbuserstatus = Tbuserstatus.where("id = #{id}").first
        if !tbuserstatus.nil?
            tbuserstatus.destroy
            log_history(Tbuserstatus, "Xóa", tbuserstatus.name , "Đã xóa khỏi hệ thống", @current_user.email)  
            msg = lib_translate("Delete_successfully")
        end
        redirect_to tbuserstatus_index_path(lang: session[:lang],page: session[:page], per_page: session[:per_page], search: session[:search]), notice: msg
    end
end