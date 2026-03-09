class GsurveysController < ApplicationController
    before_action :authorize
    def index
        search = params[:search] || ''
        sql = Gsurvey.where("name LIKE ? OR code LIKE ? OR note LIKE ?", "%#{search}%", "%#{search}%", "%#{search}%")
        @gsurveys = pagination_limit_offset(sql, 10)
    
    end

    def update
        id = params[:gsurvey_id_add]
        sName = params[:gsurvey_name_add].squish
        strCode = params[:gsurvey_code_add].squish
        strIorder = params[:gsurvey_iorder_add].squish
        strNote = params[:gsurvey_note_add].squish
        strStatus = params[:gsurvey_status_add].squish
        msg = lib_translate("Not_Success")
        if id == ''
            gsurvey = Gsurvey.new
            gsurvey.name = sName
            gsurvey.code = strCode
            gsurvey.iorder = strIorder
            gsurvey.note = strNote
            gsurvey.status = strStatus
            gsurvey.save
            msg = lib_translate("Create_successfully")
        else
            gsurvey = Gsurvey.where(id: id).first
            if !gsurvey.nil?
                gsurvey.update(
                    {
                        name: sName,
                        code: strCode,
                        iorder: strIorder,
                        note: strNote,
                        status: strStatus,
                    }
                )    
                change_column_value = gsurvey.previous_changes
                change_column_name = gsurvey.previous_changes.keys
                if change_column_name  != ""
                  for changed_column in change_column_name do 
                      if changed_column != "updated_at"
                          fvalue = change_column_value[changed_column][0]
                          tvalue = change_column_value[changed_column][1]                          
                        log_history(Gsurvey, changed_column, fvalue ,tvalue, @current_user.email)                        
                      end
                  end  
                end   
                msg = lib_translate("Update_successfully")
            end
        end
        redirect_to :back, notice: msg
    
    end

    def del
        id = params[:id]
        msg = lib_translate("Not_Success")
        gsurvey = Gsurvey.where("id = #{id}").first
        if !gsurvey.nil?
            gsurvey.destroy
            log_history(Gsurvey, "Xóa", gsurvey.name , "Đã xóa khỏi hệ thống", @current_user.email)
            msg = lib_translate("Delete_successfully")
        end
        redirect_to :back, notice: msg
    
    end
  
    
end
  