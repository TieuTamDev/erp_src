class TbhospitalsController < ApplicationController
  before_action :authorize
    # Huy review 03/03/2023
    def index 
        search = params[:search] || ''
        sql = Tbhospital.where("name LIKE ? OR scode LIKE ? OR status LIKE ?", "%#{search}%", "%#{search}%", "%#{search}%")
        @tbhospitalss = pagination_limit_offset(sql, 10)
        @tbhospitals = Tbhospital.new
    end

  def update
    id = params[:tbhospitals_id_add]
    sName = params[:tbhospitals_name_add].squish
    strScode = params[:tbhospitals_scode_add].squish
    strStatus = params[:tbhospitals_status_add].squish
    msg = lib_translate("Not_Success")

    if id == ''
        tbhospitals = Tbhospital.new
        tbhospitals.name = sName
        tbhospitals.scode = strScode
        tbhospitals.status = strStatus
        tbhospitals.save
        msg = lib_translate("Create_successfully")
    else
        tbhospitals = Tbhospital.where("id = #{id}").first
        if !tbhospitals.nil?
          tbhospitals.update(
              {
                  name: sName,
                  scode: strScode,
                  status: strStatus
              }
          )
  
          change_column_value = tbhospitals.previous_changes
          change_column_name = tbhospitals.previous_changes.keys
          if change_column_name  != ""
            for changed_column in change_column_name do 
                if changed_column != "updated_at"
                    fvalue = change_column_value[changed_column][0]
                    tvalue = change_column_value[changed_column][1]
                    log_history(Tbhospital, changed_column, fvalue ,tvalue, @current_user.email)
                end
            end  
          end
          msg = lib_translate("Update_successfully")
        end
      end
      redirect_to tbhospitals_index_path(lang: session[:lang]), notice: msg
end

def del
    id = params[:id]
    msg = lib_translate("Not_Success")
    tbhospitals = Tbhospital.where("id = #{id}").first
    if !tbhospitals.nil?
      tbhospitals.destroy   
      log_history(Tbhospital, "Xóa", tbhospitals.name , "Đã xóa khỏi hệ thống", @current_user.email)
      msg = lib_translate("Delete_successfully")
    end
    redirect_to tbhospitals_index_path(lang: session[:lang]), notice: msg
end
end
