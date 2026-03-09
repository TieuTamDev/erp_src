class TbbenefitsController < ApplicationController
  before_action :authorize   
  # Huy review 03/03/2023
  def index 
    @userId = session[:user_id]
    @tbbenefit = Tbbenefit.new
    search = params[:search] || ''
    sql = Tbbenefit.where("name LIKE ? OR status LIKE ?", "%#{search}%", "%#{search}%")
    @tbbenefits = pagination_limit_offset(sql, 10)
  end

  def update
      id = params[:tbbenefits_id_add]
      sName = params[:tbbenefits_name_add].squish
      strScode = params[:tbbenefits_scode_add].squish
      strStatus = params[:tbbenefits_status_add].squish
      msg = lib_translate("Not_Success")
      if id == ''
          tbbenefit = Tbbenefit.new
          tbbenefit.name = sName
          tbbenefit.scode = strScode
          tbbenefit.status = strStatus
          tbbenefit.save
          msg = lib_translate("Create_successfully")
        else
          tbbenefit = Tbbenefit.where("id = #{id}").first
          if !tbbenefit.nil?
            tbbenefit.update(
                {
                    name: sName,
                    scode: strScode,
                    status: strStatus
                }
            )      
            #Save updated  history (Đạt 10/01/2023)
            change_column_value = tbbenefit.previous_changes
            change_column_name = tbbenefit.previous_changes.keys
            if change_column_name  != ""
              for changed_column in change_column_name do 
                  if changed_column != "updated_at"
                      fvalue = change_column_value[changed_column][0]
                      tvalue = change_column_value[changed_column][1]
                    log_history(Tbbenefit, changed_column, fvalue ,tvalue, @current_user.email)
                    msg = lib_translate("Update_successfully")
                  end
              end  
            end   
            #end Save updated  history   
            msg = lib_translate("Update_successfully")
          end

          oSbenefit = Sbenefit.where(tbbenefit_id: id)
          if !oSbenefit.nil?   
            oSbenefit.each do |sbenefit|
              sbenefit.update({
                name: sName
              })
            end 
            msg = lib_translate("Update_successfully")
          end  

          sBenefitsId = Sbenefit.where(tbbenefit_id: id).pluck(:id)
          if !sBenefitsId.nil?
            update_user_benefit = Benefit.where(sbenefit_id: sBenefitsId)
            if !update_user_benefit.nil?
              update_user_benefit.each do |update_user_benefit_value|
                update_user_benefit_value.update({
                  name: sName
                })
              end
              msg = lib_translate("Update_successfully")
            end 
          end 
          
        end
        redirect_to tbbenefits_index_path(lang: session[:lang],page: session[:page], per_page: session[:per_page], search: session[:search]), notice: msg
  end

  def del
      id = params[:id]
      sBenefit_Id = Sbenefit.where(tbbenefit_id: id).pluck(:id)
      msg = lib_translate("Not_Success")
      if !sBenefit_Id.nil?
        Benefit.where(sbenefit_id: sBenefit_Id).delete_all
        tbbenefit = Tbbenefit.where("id = #{id}").first
        if !tbbenefit.nil?
          tbbenefit.destroy
          log_history(Tbbenefit, "Xóa", tbbenefit.name , "Đã xóa khỏi hệ thống", @current_user.email)      
          msg = lib_translate("Delete_successfully")
        end   
      end
      
      redirect_to tbbenefits_index_path(lang: session[:lang],page: session[:page], per_page: session[:per_page], search: session[:search]), notice: msg
  end
end
