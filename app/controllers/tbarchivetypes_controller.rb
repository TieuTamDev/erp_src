class TbarchivetypesController < ApplicationController
    before_action :authorize   
      # Huy review 03/03/2023
    def index 
        search = params[:search] || ''
        sql = Tbarchivetype.where("name LIKE ? OR scode LIKE ? OR status LIKE ?", "%#{search}%", "%#{search}%", "%#{search}%")
        @tbarchivetypes = pagination_limit_offset(sql, 10)
        @tbarchivetype = Tbarchivetype.new

       
    end
    def update
        id = params[:tbarchivetype_id]
        name = params[:tbarchivetype_name_add].squish
        strScode = params[:tbarchivetype_scode_add].squish
        strStatus = params[:tbarchivetype_status_add].squish
        msg = lib_translate("Not_Success")
        if id == ''
            addTbarchivetype = Tbarchivetype.new
            addTbarchivetype.name = name
            addTbarchivetype.scode = strScode
            addTbarchivetype.status = strStatus
            addTbarchivetype.save
            msg = lib_translate("Create_successfully")
        else
            addTbarchivetype = Tbarchivetype.where(id: id).first
            if !addTbarchivetype.nil?
                addTbarchivetype.update(
                    {
                    name: name,
                    scode: strScode,
                    status: strStatus
                    }
                )
                change_column_value = addTbarchivetype.previous_changes
                change_column_name = addTbarchivetype.previous_changes.keys
                if change_column_name  != ""
                    for changed_column in change_column_name do 
                        if changed_column != "updated_at"
                            fvalue = change_column_value[changed_column][0]
                            tvalue = change_column_value[changed_column][1]
                            log_history(Tbarchivetype, changed_column, fvalue ,tvalue, @current_user.email)
                        end
                    end  
                end
                msg = lib_translate("Update_successfully")
            end
        end
        redirect_to tbarchivetypes_index_path(lang: session[:lang],page: session[:page], per_page: session[:per_page], search: session[:search]), notice: msg
    end

    def del
        id = params[:id]
        msg = lib_translate("Not_Success")
        delTbarchivetype = Tbarchivetype.where(id: id).first
        if !delTbarchivetype.nil?
            delTbarchivetype.destroy
            log_history(Tbarchivetype, "Xóa", delTbarchivetype.name , "Đã xóa khỏi hệ thống", @current_user.email)
            msg = lib_translate("Delete_successfully")
        end
        redirect_to tbarchivetypes_index_path(lang: session[:lang],page: session[:page], per_page: session[:per_page], search: session[:search]), notice: msg
    end
end
