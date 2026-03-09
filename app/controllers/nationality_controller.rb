class NationalityController < ApplicationController
    before_action :authorize    
    # Huy review 03/03/2023
    def index 
      search = params[:search] || ''
      sql = Nationality.where("name LIKE ? OR scode LIKE ? OR status LIKE ?", "%#{search}%", "%#{search}%", "%#{search}%")
      @nationalitys = pagination_limit_offset(sql, 10)
      @nationality = Nationality.new
    end
  
    def update
      id = params[:nationality_id_add]
      sName = params[:nationality_name_add].squish
      strScode = params[:nationality_scode_add].squish 
      strStatus = params[:nationality_status_add].squish
      msg = lib_translate("Not_Success")
      if id == ''
        nationality = Nationality.new
        nationality.name = sName
        nationality.scode = strScode 
        nationality.status = strStatus
        nationality.save
        msg = lib_translate("Create_successfully")
      else
        nationality = Nationality.where("id = #{id}").first
        if !nationality.nil?
          nationality.update(
            {
              name: sName,
              scode: strScode, 
              status: strStatus
            }
          )
  
          change_column_value = nationality.previous_changes
          change_column_name = nationality.previous_changes.keys
          if change_column_name  != ""
            for changed_column in change_column_name do 
                if changed_column != "updated_at"
                    fvalue = change_column_value[changed_column][0]
                    tvalue = change_column_value[changed_column][1]
  
                  log_history(Nationality, changed_column, fvalue ,tvalue, @current_user.email)
                  
                end
            end  
          end   
          msg = lib_translate("Update_successfully")
        end
      end
      redirect_to nationality_index_path(lang: session[:lang],page: session[:page], per_page: session[:per_page], search: session[:search]), notice: msg
    end
  
    def del
      id = params[:id]
      msg = lib_translate("Not_Success")
      nationality = Nationality.where("id = #{id}").first
      if !nationality.nil?
        nationality.destroy
        log_history(Nationality, "Xóa", nationality.name , "Đã xóa khỏi hệ thống", @current_user.email)
        msg = lib_translate("Delete_successfully")
      end
      redirect_to nationality_index_path(lang: session[:lang],page: session[:page], per_page: session[:per_page], search: session[:search]), notice: msg
    end 
end