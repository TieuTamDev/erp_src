class EducationController < ApplicationController
  before_action :authorize    
  # Huy review 03/03/2023
    def edit 
        search = params[:search] || ''
        sql = Education.where("name LIKE ? OR scode LIKE ? OR status LIKE ?", "%#{search}%", "%#{search}%", "%#{search}%")
        @educations = pagination_limit_offset(sql, 10)
        @education = Education.new
      end
    
      def update
        id = params[:education_id_add]
        sName = params[:education_name_add].squish
        strScode = params[:education_scode_add].squish
        strStatus = params[:education_status_add].squish
        msg = lib_translate("Not_Success")
        if id == ''
          education = Education.new
          education.name = sName
          education.scode = strScode
          education.status = strStatus
          education.save
          msg = lib_translate("Create_successfully")
        else
          education = Education.where("id = #{id}").first
          if !education.nil?
            education.update(
              {
                name: sName,
                scode: strScode,
                status: strStatus
              }
            )
  
            #Save updated  history (Đạt 10/01/2023)
            change_column_value = education.previous_changes
            change_column_name = education.previous_changes.keys
            if change_column_name  != ""
              for changed_column in change_column_name do 
                  if changed_column != "updated_at"
                      fvalue = change_column_value[changed_column][0]
                      tvalue = change_column_value[changed_column][1]
  
                    log_history(Education, changed_column, fvalue ,tvalue, @current_user.email)
                    
                  end
              end  
            end  
            msg = lib_translate("Update_successfully")  
          end 
        end
        redirect_to education_edit_path(lang: session[:lang],page: session[:page], per_page: session[:per_page], search: session[:search]), notice: msg
      end
  
      def del
        id = params[:id]
        msg = lib_translate("Not_Success")
        education = Education.where("id = #{id}").first
        if !education.nil?
          education.destroy   
          log_history(Education, "Xóa", education.name , "Đã xóa khỏi hệ thống", @current_user.email)
          msg = lib_translate("Delete_successfully")
        end
        redirect_to education_edit_path(lang: session[:lang],page: session[:page], per_page: session[:per_page], search: session[:search]), notice: msg
      end
end 