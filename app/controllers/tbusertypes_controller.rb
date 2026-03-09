class TbusertypesController < ApplicationController
    before_action :authorize
      # Huy review 03/03/2023
    def index
        search = params[:search] || ''
        sql = Tbusertype.where("name LIKE ? OR scode LIKE ? OR status LIKE ?", "%#{search}%", "%#{search}%", "%#{search}%")
        @tbusertypes = pagination_limit_offset(sql, 10)
        @tbusertype = Tbusertype.new
    end

    def update
        id = params[:tbusertype_id_add]
        sName = params[:tbusertype_name_add].squish
        strScode = params[:tbusertype_scode_add].squish
        strStatus = params[:tbusertype_status_add].squish
        msg = lib_translate("Not_Success")
        if id == ''
            tbusertype = Tbusertype.new
            tbusertype.name = sName
            tbusertype.scode = strScode
            tbusertype.status = strStatus
            tbusertype.save
            msg = lib_translate("Create_successfully")
        else
            tbusertype = Tbusertype.where("id = #{id}").first
            if !tbusertype.nil?
                tbusertype.update(
                    {
                        name: sName,
                        scode: strScode,
                        status: strStatus
                    }
                )
                
                change_column_value = tbusertype.previous_changes
                change_column_name = tbusertype.previous_changes.keys
                if change_column_name  != ""
                    for changed_column in change_column_name do 
                        if changed_column != "updated_at"
                            fvalue = change_column_value[changed_column][0]
                            tvalue = change_column_value[changed_column][1]
                            log_history(Tbusertype, changed_column, fvalue ,tvalue, @current_user.email)
                        end
                    end  
                end
                msg = lib_translate("Update_successfully")
            end
        end
        redirect_to tbusertype_index_path(lang: session[:lang],page: session[:page], per_page: session[:per_page], search: session[:search]), notice: msg
    end

    def del
        id = params[:id]
        msg = lib_translate("Not_Success")
        tbusertype = Tbusertype.where("id = #{id}").first
        if !tbusertype.nil?
            tbusertype.destroy
            log_history(Tbusertype, "Xóa", tbusertype.name , "Đã xóa khỏi hệ thống", @current_user.email)
            msg = lib_translate("Update_successfully")
        end
        redirect_to tbusertype_index_path(lang: session[:lang],page: session[:page], per_page: session[:per_page], search: session[:search]), notice: msg
    end
end