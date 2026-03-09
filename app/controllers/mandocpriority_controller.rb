class MandocpriorityController < ApplicationController
    before_action :authorize
    def index
        @Mandocprioritys = Mandocpriority.all.order(id: :desc)
        @Mandocpriority = Mandocpriority.new
    end

    def update
        id = params[:mandocpriority_id_add]
        sName = params[:mandocpriority_name_add].squish
        strScode = params[:mandocpriority_scode_add].squish
        strStatus = params[:mandocpriority_status_add].squish
        strNote = params[:mandocpriority_note_add]
        if id == ''
            mandocpriority = Mandocpriority.new
            mandocpriority.name = sName
            mandocpriority.scode = strScode
            mandocpriority.status = strStatus
            mandocpriority.note = strNote
            mandocpriority.save
            redirect_to mandocpriority_index_path(lang: session[:lang]), notice: lib_translate('Add_message')
        else
            mandocpriority = Mandocpriority.where("id = #{id}").first
            mandocpriority.update(
                {
                    name: sName,
                    scode: strScode,
                    status: strStatus,
                    note: strNote
                }
            )
            
            change_column_value = mandocpriority.previous_changes
            change_column_name = mandocpriority.previous_changes.keys
            if change_column_name  != ""
              for changed_column in change_column_name do 
                  if changed_column != "updated_at"
                      fvalue = change_column_value[changed_column][0]
                      tvalue = change_column_value[changed_column][1]
    
                    log_history(Mandocpriority, changed_column, fvalue ,tvalue, @current_user.email)                    
                  end
              end  
            end   
            redirect_to mandocpriority_index_path(lang: session[:lang]), notice: lib_translate('Update_success')
        end
    end

    def del
        id = params[:id]
        mandocpriority = Mandocpriority.where("id = #{id}").first
        mandocpriority.destroy
        log_history(Mandocpriority, "Xóa", mandocpriority.name , "Đã xóa khỏi hệ thống", @current_user.email)
        redirect_to mandocpriority_index_path(lang: session[:lang]), notice: lib_translate('delete_message')
    end

    def get_all
        datas = Mandocpriority.select("id,name")
        respond_to do |format|
            format.js { render js: "reloadMandocPriority(#{datas.to_json.html_safe})"}
        end
    end

    def check_duplicate
        id_check = params[:id_check]
        name_check = params[:name_check].squish
        scode_check = params[:scode_check].squish        
        @Duplicate = "".to_json.html_safe
        oCheckId = Mandocpriority.where(id: id_check).first
        oCheckName = Mandocpriority.where(name: name_check).first
        oCheckScode = Mandocpriority.where(scode: scode_check).first
        
        if !id_check.nil? && id_check != ""
            if !oCheckId.nil?
                strName = oCheckId.name
                strScode = oCheckId.scode
                if name_check == strName && scode_check == strScode 
                    @Duplicate = false                    
                else
                    if !oCheckName.nil? && name_check != strName
                        @Duplicate = true                        
                    elsif !oCheckScode.nil? && scode_check != strScode
                        @Duplicate = true    
                    else
                        @Duplicate = false                      
                    end
                end
                
            end   
        elsif !oCheckName.nil? || !oCheckScode.nil?             
            @Duplicate = true
        else
            @Duplicate = false       
        end    
    end
end