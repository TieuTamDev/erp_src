class MandoctypeController < ApplicationController
    before_action :authorize
    def index
        @Mandoctypes = Mandoctype.all.order(id: :desc)
        @Mandoctype = Mandoctype.new
    end

    def update
        id = params[:mandoctype_id_add]
        sName = params[:mandoctype_name_add].squish
        strScode = params[:mandoctype_scode_add].squish
        strStatus = params[:mandoctype_status_add].squish
        strNote = params[:mandoctype_note_add].squish
        if id == ''
            mandocType = Mandoctype.new
            mandocType.name = sName
            mandocType.scode = strScode
            mandocType.status = strStatus
            mandocType.note = strNote
            mandocType.save
            redirect_to mandoctype_index_path(lang: session[:lang]), notice: lib_translate('Add_message')
        else
            mandocType = Mandoctype.where("id = #{id}").first
            mandocType.update(
                {
                    name: sName,
                    scode: strScode,
                    status: strStatus,
                    note: strNote
                }
            )
            
            change_column_value = mandocType.previous_changes
            change_column_name = mandocType.previous_changes.keys
            if change_column_name  != ""
              for changed_column in change_column_name do 
                  if changed_column != "updated_at"
                      fvalue = change_column_value[changed_column][0]
                      tvalue = change_column_value[changed_column][1]
    
                    log_history(Mandoctype, changed_column, fvalue ,tvalue, @current_user.email)
                    
                  end
              end  
            end   
            redirect_to mandoctype_index_path(lang: session[:lang]), notice: lib_translate('Update_success')
        end
    end

    def del
        id = params[:id]
        mandocType = Mandoctype.where("id = #{id}").first
        mandocType.destroy
        log_history(Mandoctype, "Xóa", mandocType.name , "Đã xóa khỏi hệ thống", @current_user.email)
        redirect_to mandoctype_index_path(lang: session[:lang]), notice: lib_translate('delete_message')
    end

    def get_all
        datas = Mandoctype.select("id,name")
        respond_to do |format|
            format.js { render js: "reloadMandocType(#{datas.to_json.html_safe})"}
        end
    end

    def check_duplicate
        id_check = params[:id_check]
        name_check = params[:name_check].squish
        scode_check = params[:scode_check].squish        
        @Duplicate = "".to_json.html_safe
        oCheckId = Mandoctype.where(id: id_check).first
        oCheckName = Mandoctype.where(name: name_check).first
        oCheckScode = Mandoctype.where(scode: scode_check).first
        
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