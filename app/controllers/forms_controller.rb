class FormsController < ApplicationController
    before_action :authorize
    def index 
        search = params[:search] || ''
        sql = Form.where("name LIKE ? OR scode LIKE ? OR status LIKE ?", "%#{search}%", "%#{search}%", "%#{search}%")
        @forms = pagination_limit_offset(sql, 10)
        @form = Form.new
    end

    def update
        id = params[:form_id_add]
        sName = params[:form_name_add].squish
        strScode = params[:form_scode_add].squish
        strApp = params[:form_app_add].squish
        strNote = params[:form_note_add].squish
        strContent = params[:form_content_add].squish
        strStatus = params[:form_status_add].squish
        msg = lib_translate("Not_Success")
        if id == ''
            form = Form.new
            form.name = sName
            form.scode = strScode
            form.app = strApp
            form.note = strNote
            form.contents = strContent            
            form.status = strStatus
            form.save
            msg = lib_translate("Create_successfully")
        else
            form = Form.where("id = #{id}").first
            if !form.nil?
                form.update(
                    {
                        name: sName,
                        scode: strScode,
                        app: strApp,
                        note: strNote,
                        contents: strContent,
                        status: strStatus,
                    }
                )
    
                change_column_value = form.previous_changes
                change_column_name = form.previous_changes.keys
                if change_column_name  != ""
                  for changed_column in change_column_name do 
                      if changed_column != "updated_at"
                          fvalue = change_column_value[changed_column][0]
                          tvalue = change_column_value[changed_column][1]
                          
                        log_history(Form, changed_column, fvalue ,tvalue, @current_user.email)
                        
                      end
                  end  
                end   
                msg = lib_translate("Update_successfully")
            end
        end
        redirect_to forms_index_path(lang: session[:lang],page: session[:page], per_page: session[:per_page], search: session[:search]), notice: msg
    end

    def del
        id = params[:id]
        msg = lib_translate("Not_Success")
        form = Form.where("id = #{id}").first
        if !form.nil?
            form.destroy
            log_history(form, "Xóa", form.name , "Đã xóa khỏi hệ thống", @current_user.email)
            msg = lib_translate("Delete_successfully")
        end

        redirect_to forms_index_path(lang: session[:lang],page: session[:page], per_page: session[:per_page], search: session[:search]), notice: msg
    end
end