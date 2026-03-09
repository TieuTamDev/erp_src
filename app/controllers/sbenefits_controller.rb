class SbenefitsController < ApplicationController
  before_action :authorize    
  def index
    @year = params[:year] || Time.zone.now.year.to_s
    @allbenefit = Sbenefit.where(syear: @year).order(id: :desc)
    @sbenefits = Sbenefit.new
    @tbenefits = Tbbenefit.where.not(status: 'INACTIVE')
    sbenefits_result = Sbenefit.where(syear: @year)  
    @benefit= Benefit.new
    # Sbenefit.where(syear: "2023").delete_all
    # Sbenefit.where(syear: "2022").delete_all
    # Mhistory.destroy_all

    @list_sbenefit = []
    sbenefits_result.each do |sBenefit|
      if !sBenefit.name.nil?
        index = @list_sbenefit.find_index{ |item| item[:name] == sBenefit.name }
        if !index.nil?
          @list_sbenefit[index][sBenefit.stype.to_s] = {
              id: sBenefit.id,
              amount: sBenefit.amount,
              desc: sBenefit.desc
            }
        else
          @list_sbenefit.push({
            name: sBenefit.name,
            "#{sBenefit.stype}": {
              id: sBenefit.id,
              amount: sBenefit.amount,
              desc: sBenefit.desc
            }
          })
        end
      end
    end

  end

  def update
   
    type = params[:sbenefits_add_type]
    id = params[:sbenefits_id_add]
    @strSyear = params[:sbenefits_syear_add]
    strSbenefitName = params[:sbenefits_name_add]     
    @allbenefit = Sbenefit.where(syear: @strSyear).order(id: :desc)    
    if id == '' && type == "1"
      if strSbenefitName.nil?
        sbenefit_id = Sbenefit.where(syear: @strSyear).pluck(:id)
        Benefit.where(sbenefit_id: sbenefit_id).delete_all
        Sbenefit.where(syear: @strSyear).delete_all
        redirect_to sbenefits_index_path(lang: session[:lang],year: @strSyear), notice: lib_translate('delete_message')
      else
        sbenefit_id = Sbenefit.where(syear: @strSyear).where.not(name: strSbenefitName).pluck(:id)
        Benefit.where(sbenefit_id: sbenefit_id).delete_all        
        Sbenefit.where(syear: @strSyear).where.not(name: strSbenefitName).delete_all
        for name in strSbenefitName do 
          if @allbenefit.pluck(:name).include?(name) == false
            tbbenefit_id = Tbbenefit.where(name: name).first.id
            (1..3).each do |stype|
              sbenefits = Sbenefit.new
              sbenefits.name = name
              sbenefits.tbbenefit_id = tbbenefit_id
              sbenefits.amount = 0
              sbenefits.syear = @strSyear
              sbenefits.status = "ACTIVE"
              sbenefits.stype = stype
              sbenefits.btype = "OTHER"
              sbenefits.desc = ""
              sbenefits.save
            end
          end
        end 
        redirect_to sbenefits_index_path(lang: session[:lang],year: @strSyear), notice: lib_translate('Add_message')   
      end
          
    else
      all_Sbenefit_id = Sbenefit.where(syear: @strSyear).pluck(:id)
      for id in all_Sbenefit_id do 

        strAmount = params["amount_benefit_#{id}"]
        if !strAmount.nil?
          strAmount = params["amount_benefit_#{id}"].gsub(',','')
        end

        strDesc = params["desc_benefit_#{id}"]  
        if !strDesc.nil?
          strDesc = params["desc_benefit_#{id}"].squish
        end   

        if strAmount.to_i > 0 && strAmount != ""
          strBtype = "MONEY"
        else
          strBtype = "OTHER"
          strAmount = 0
        end        
        sbenefits = Sbenefit.where("id = #{id}").first
        sbenefits.update({
                amount: strAmount,
                desc: strDesc,
                btype: strBtype
            })       
        #update user benefits
        update_user_benefit = Benefit.where(sbenefit_id: id)
        if !update_user_benefit.nil? 
          update_user_benefit.each do |update_user_benefit_value|
            update_user_benefit_value.update ({
              amount: strAmount,
              btype: strBtype,
              desc: strDesc
            })          
          end
        end
        #end update_user_benefit
            
        # Save updated  history (Đạt 10/01/2023)
          change_column_value = sbenefits.previous_changes
          change_column_name = sbenefits.previous_changes.keys
          if change_column_name  != ""
              for changed_column in change_column_name do 
                  if changed_column != "updated_at"
                      fvalue = change_column_value[changed_column][0]
                      tvalue = change_column_value[changed_column][1]
                  log_history(Sbenefit, changed_column, fvalue ,tvalue, @current_user.email)                
                  end
              end  
          end   
        # end Save updated  history 
      end

    redirect_to sbenefits_index_path(lang: session[:lang], year: @strSyear), notice: lib_translate('Update_success')
    end
  end

  def update_benefit_last_year
    sbenefits_name_update_by_year = params[:sbenefits_name_update_by_year]
    last_year = params[:last_year]
    last_year_benefit = Sbenefit.where(syear: last_year, name:sbenefits_name_update_by_year)
    this_year_benefit_name = Sbenefit.where(syear: last_year.to_i + 1).uniq.pluck(:name)
    last_year_benefit.each do |benefit|

      current_benefit = Sbenefit.where(syear: last_year.to_i + 1)
      current_benefit.each do |current_benefit|
        benefits = Sbenefit.where("id = #{current_benefit.id}").first
        if benefit.tbbenefit_id == current_benefit.tbbenefit_id && benefit.stype == current_benefit.stype
          benefits.update({
                name: benefit.name,
                tbbenefit_id: benefit.tbbenefit_id,
                amount: benefit.amount,
                syear: last_year.to_i + 1,
                status: benefit.status,
                stype: benefit.stype,
                btype: benefit.btype,
                desc: benefit.desc
          })    
          # Save updated  history (Đạt 10/01/2023)
          change_column_value = benefits.previous_changes
          change_column_name = benefits.previous_changes.keys
          if change_column_name  != ""
              for changed_column in change_column_name do 
                  if changed_column != "updated_at"
                      fvalue = change_column_value[changed_column][0]
                      tvalue = change_column_value[changed_column][1]
                  log_history(Sbenefit, changed_column, fvalue ,tvalue, @current_user.email)                
                  end
              end  
          end   
        # end Save updated  history               
        end 
      end
    end 

    #copy old values 
    copy_benefit_value = Sbenefit.where(syear: last_year, name:sbenefits_name_update_by_year).where.not(name: this_year_benefit_name)
    if !copy_benefit_value.nil?
      copy_benefit_value.each do |copy_value|
        sbenefits = Sbenefit.new
        sbenefits.name = copy_value.name
        sbenefits.tbbenefit_id = copy_value.tbbenefit_id
        sbenefits.amount = copy_value.amount
        sbenefits.syear = last_year.to_i + 1
        sbenefits.status = copy_value.status
        sbenefits.stype = copy_value.stype
        sbenefits.btype = copy_value.btype
        sbenefits.desc = copy_value.desc
        sbenefits.save
      end
    end

    redirect_to sbenefits_index_path(lang: session[:lang], year: last_year.to_i + 1), notice: lib_translate('Update_success')
  
  end 

  def get_selected_benefits

  end 

  
  def get_selected_users
    year = params[:select_year]
    stype = params[:benefit_type]
    target = params[:target]

    oBenefitList = Sbenefit.where(syear: year, stype:stype)

    if target == "TATCA" 
      oUserList = User.select("id,first_name,last_name,avatar,sid").where(benefit_type: stype)
    elsif target == "NAM" 
      oUserList = User.select("id,first_name,last_name,avatar,sid").where(benefit_type: stype, gender:"0")      
    else
      oUserList = User.select("id,first_name,last_name,avatar,sid").where(benefit_type: stype, gender:"1")    
    end

    if oUserList != nil && oBenefitList != nil
      render json: {result_users_list: oUserList, result_benefits_list: oBenefitList}  
    end 
  end 

  def add_multiply_benefits
    userArray = params[:userArray].split(",")
    benefitArray = params[:benefitArray].split(",")
    staff_selected_year = params[:staff_selected_year]
    oBenefit = Sbenefit.where(id: benefitArray)

    if !userArray.nil? 
      userArray.each do |user_id|
        oUser = User.where(id: user_id).first 
        oBenefit = Sbenefit.where(id: benefitArray)
        if !oBenefit.first.nil? 
          oUserBenefits = Benefit.where(user_id: user_id, syear:staff_selected_year, status: "ACTIVE", stype: oBenefit.first.stype).where("sbenefit_id IS NOT NULL")
          log_history(Benefit, "Cập nhật: #{oUser.last_name} #{oUser.first_name} ", oUserBenefits.pluck(:name).to_s.delete('"').delete('[]') ,oBenefit.pluck(:name).to_s.delete('"').delete('[]'), @current_user.email)        
          oUserBenefits.destroy_all       
          oBenefit.each do |benefit_value|      
              oNewUserbenefits = Benefit.new  
              oNewUserbenefits.user_id = user_id
              oNewUserbenefits.name = benefit_value.name
              oNewUserbenefits.amount = benefit_value.amount
              oNewUserbenefits.stype = benefit_value.stype
              oNewUserbenefits.syear = benefit_value.syear
              oNewUserbenefits.desc = benefit_value.desc
              oNewUserbenefits.sbenefit_id = benefit_value.id
              oNewUserbenefits.btype = benefit_value.btype
              oNewUserbenefits.status="ACTIVE"
              oNewUserbenefits.save        
          end
        else
          oDeleteUserBenefits = Benefit.where(user_id: user_id, syear:staff_selected_year, status: "ACTIVE", stype: User.where(id: user_id).first.benefit_type).where("sbenefit_id IS NOT NULL")
          log_history(Benefit, "Cập nhật: #{oUser.last_name} #{oUser.first_name} ", oDeleteUserBenefits.pluck(:name).to_s.delete('"').delete('[]') , " " , @current_user.email)        
          oDeleteUserBenefits.destroy_all
        end
      end
    end

      
    redirect_to sbenefits_index_path(lang: session[:lang], year: staff_selected_year), notice: lib_translate('Update_success')
  end

end
