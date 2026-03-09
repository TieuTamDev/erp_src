class MandocfromsController < ApplicationController
    before_action :authorize
    def index
        @Mandocfroms = Mandocfrom.all.order(id: :desc)
        @Mandocfrom = Mandocfrom.new
    end
    def update
        id = params[:mandocfrom_id_add]
        sName = params[:mandocfrom_name_add].squish
        strScode = params[:mandocfrom_scode_add].squish
        strStatus = params[:mandocfrom_status_add].squish
        strNote = params[:mandocfrom_note_add]
        if id == ''
            check_unique = Mandocfrom.where(scode: strScode).first
            if !check_unique.nil?
                redirect_to mandocfroms_index_path(lang: session[:lang]), notice: lib_translate('Lõio')
            else
            mandocfrom = Mandocfrom.new
            mandocfrom.name = sName
            mandocfrom.scode = strScode
            mandocfrom.status = strStatus
            mandocfrom.note = strNote
            mandocfrom.save
            redirect_to mandocfroms_index_path(lang: session[:lang]), notice: lib_translate('Add_message')
            end
        else
            mandocfrom = Mandocfrom.where("id = #{id}").first
            mandocfrom.update(
                {
                    name: sName,
                    scode: strScode,
                    status: strStatus,
                    note: strNote
                }
            )
            
            change_column_value = mandocfrom.previous_changes
            change_column_name = mandocfrom.previous_changes.keys
            if change_column_name  != ""
              for changed_column in change_column_name do 
                  if changed_column != "updated_at"
                      fvalue = change_column_value[changed_column][0]
                      tvalue = change_column_value[changed_column][1]
    
                    log_history(Mandocfrom, changed_column, fvalue ,tvalue, @current_user.email)
                    
                  end
              end  
            end   
            redirect_to mandocfroms_index_path(lang: session[:lang]), notice: lib_translate('Update_success')
        end
    end
    def del
        id = params[:id]
        mandocfrom = Mandocfrom.where("id = #{id}").first
        mandocfrom.destroy
        log_history(Mandocfrom, "Xóa", mandocfrom.name , "Đã xóa khỏi hệ thống", @current_user.email)
        redirect_to mandocfroms_index_path(lang: session[:lang]), notice: lib_translate('delete_message')
    end

    def get_all
        datas = Mandocfrom.select("id,name")
        respond_to do |format|
            format.js { render js: "reloadMandocFrom(#{datas.to_json.html_safe})"}
        end
    end
    def check_duplicate
        id_check = params[:id_check]
        name_check = params[:name_check].squish
        scode_check = params[:scode_check].squish        
        @Duplicate = "".to_json.html_safe
        oCheckId = Mandocfrom.where(id: id_check).first
        oCheckName = Mandocfrom.where(name: name_check).first
        oCheckScode = Mandocfrom.where(scode: scode_check).first
        
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