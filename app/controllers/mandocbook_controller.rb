class MandocbookController < ApplicationController
    before_action :authorize
    def index
        @MandocBooks = Mandocbook.all.order(id: :desc)
        @MandocBook = Mandocbook.new
    end

    def update
        id = params[:mandocbook_id_add]
        sName = params[:mandocbook_name_add].squish
        strScode = params[:mandocbook_scode_add].squish
        strStatus = params[:mandocbook_status_add].squish
        strNote = params[:mandocbook_note_add]
        if id == ''
            mandocBook = Mandocbook.new
            mandocBook.name = sName
            mandocBook.scode = strScode
            mandocBook.status = strStatus
            mandocBook.note = strNote
            mandocBook.save
            redirect_to mandocbook_index_path(lang: session[:lang]), notice: lib_translate('Add_message')

        else
            mandocBook = Mandocbook.where("id = #{id}").first
            mandocBook.update(
                {
                    name: sName,
                    scode: strScode,
                    status: strStatus,
                    note: strNote
                }
            )
            
            change_column_value = mandocBook.previous_changes
            change_column_name = mandocBook.previous_changes.keys
            if change_column_name  != ""
              for changed_column in change_column_name do 
                  if changed_column != "updated_at"
                      fvalue = change_column_value[changed_column][0]
                      tvalue = change_column_value[changed_column][1]
    
                    log_history(Mandocbook, changed_column, fvalue ,tvalue, @current_user.email)
                    
                  end
              end  
            end   
            redirect_to mandocbook_index_path(lang: session[:lang]), notice: lib_translate('Update_success')
        end
    end

    def del
        id = params[:id]
        mandocBook = Mandocbook.where("id = #{id}").first
        mandocBook.destroy
        log_history(Mandocbook, "Xóa", mandocBook.name , "Đã xóa khỏi hệ thống", @current_user.email)
        redirect_to mandocbook_index_path(lang: session[:lang]), notice: lib_translate('delete_message')
    end

    def get_all
        datas = Mandocbook.select("id,name")
        respond_to do |format|
            format.js { render js: "reloadMandocBook(#{datas.to_json.html_safe})"}
        end
    end
    def check_duplicate
        id_check = params[:id_check]
        name_check = params[:name_check].squish
        scode_check = params[:scode_check].squish        
        @Duplicate = "".to_json.html_safe
        oCheckId = Mandocbook.where(id: id_check).first
        oCheckName = Mandocbook.where(name: name_check).first
        oCheckScode = Mandocbook.where(scode: scode_check).first
        
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