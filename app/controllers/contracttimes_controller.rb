class ContracttimesController < ApplicationController
    before_action :authorize
      # Huy review 03/03/2023
    def index
        search = params[:search] || ''
        sql = Contracttime.where("name LIKE ? OR scode LIKE ? OR status LIKE ?", "%#{search}%", "%#{search}%", "%#{search}%")
        @contracttimes = pagination_limit_offset(sql, 10)
        @contracttime = Contracttime.new
    end

    def update
        id = params[:contracttime_id_add]
        sName = params[:contracttime_name_add].squish
        strScode = params[:contracttime_scode_add].squish
        strStatus = params[:contracttime_status_add].squish
        msg = lib_translate("Not_Success")
        if id == ''
            contracttime = Contracttime.new
            contracttime.name = sName
            contracttime.scode = strScode
            contracttime.status = strStatus
            contracttime.save
            msg = lib_translate("Create_successfully")
        else
            contracttime = Contracttime.where("id = #{id}").first
            if !contracttime.nil?
                contracttime.update(
                    {
                        name: sName,
                        scode: strScode,
                        status: strStatus
                    }
                )
                #Save updated  history (Đạt 10/01/2023)
                change_column_value = contracttime.previous_changes
                change_column_name = contracttime.previous_changes.keys
                if change_column_name  != ""
                    for changed_column in change_column_name do 
                        if changed_column != "updated_at"
                            fvalue = change_column_value[changed_column][0]
                            tvalue = change_column_value[changed_column][1]                        
                        log_history(Contracttime, changed_column, fvalue ,tvalue,  @current_user.email)
                        end
                    end  
                end   
                #end Save updated  history           
                msg = lib_translate("Update_successfully")
            end
        end
        redirect_to contracttime_index_path(lang: session[:lang],page: session[:page], per_page: session[:per_page], search: session[:search]), notice: msg
    end

    def del
        id = params[:id]
        contracttime = Contracttime.where("id = #{id}").first
        msg = lib_translate("Not_Success")
        if !contracttime.nil?
            contracttime.destroy
            log_history(Contracttime, "Xóa", contracttime.name , "Đã xóa khỏi hệ thống", @current_user.email)
            msg = lib_translate("Delete_successfully")
        end
        redirect_to contracttime_index_path(lang: session[:lang],page: session[:page], per_page: session[:per_page], search: session[:search]), notice: msg
    end
end