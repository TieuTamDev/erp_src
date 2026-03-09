class DisciplinesController < ApplicationController
    skip_before_action :verify_authenticity_token
    before_action :authorize
    # Huy review 03/03/2023
    def edit
      search = params[:search] || ''
      sql = Discipline.joins(:user).where("email LIKE ? OR sid = ? OR concat(last_name,' ',first_name) LIKE ? OR name LIKE ?", "%#{search}%", "#{search}", "%#{search}%", "%#{search}%")
      @disciplines = pagination_limit_offset(sql, 10)
      @discipline = Discipline.new

      @users = User.where.not(email: "admin@gmail.com")
      @documents = Discdoc.all
      @document = Discdoc.new

    end

    def update
      idDiscipline = params[:idDiscipline]
      id = params[:discipline_id_add]
      sId = params[:discipline_user_id_add]
      sName = params[:discipline_name_add]
      sCode = params[:discipline_scode_add]
      sDate = params[:discipline_mdate_add]
      sStype = params[:sel_discipline_stype_add]
      sStatus = params[:sel_discipline_status_add]
      sNote = params[:discipline_note_add]

      

      if idDiscipline.nil? || idDiscipline == ""
        if id == ""
          discipline = Discipline.new
          discipline.user_id = sId
          discipline.name = sName
          discipline.scode = sCode
          discipline.mdate = sDate
          discipline.stype = sStype
          discipline.status = sStatus
          discipline.note = sNote
          discipline.save
          msg = lib_translate("Create_successfully")
          if sStype == "4" && sStatus == "ACTIVE"
            oUserUpdate = User.where(id: sId).first
            if !oUserUpdate.nil?
              oUserUpdate.update({status: "INACTIVE",  note: "Buộc thôi việc" });
              #Save updated  history (Đạt 10/01/2023)
              change_column_value = oUserUpdate.previous_changes
              change_column_name = oUserUpdate.previous_changes.keys
              if change_column_name  != ""
                  for changed_column in change_column_name do 
                      if changed_column != "updated_at"
                          fvalue = change_column_value[changed_column][0]
                          tvalue = change_column_value[changed_column][1]
                      log_history(User, changed_column, fvalue ,tvalue, @current_user.email)
                      end
                  end  
              end   
            end
            #end Save updated  history 
          else
            oUserUpdate = User.where(id: sId).first
            if !oUserUpdate.nil?
              oUserUpdate.update({status: "ACTIVE",  note: "" });
              #Save updated  history (Đạt 10/01/2023)
              change_column_value = oUserUpdate.previous_changes
              change_column_name = oUserUpdate.previous_changes.keys
              if change_column_name  != ""
                  for changed_column in change_column_name do 
                      if changed_column != "updated_at"
                          fvalue = change_column_value[changed_column][0]
                          tvalue = change_column_value[changed_column][1]                       
                      log_history(User, changed_column, fvalue ,tvalue, @current_user.email)
                      end
                  end  
              end   
              #end Save updated  history 
            end
          end  
        else
          oDiscipline = Discipline.where("id = #{id}").first
          if !oDiscipline.nil?
            oDiscipline.update({user_id: sId ,name: sName, scode: sCode, stype: sStype, mdate:sDate, status: sStatus,  note: sNote });
            #Save updated  history (Đạt 10/01/2023)
            change_column_value = oDiscipline.previous_changes
            change_column_name = oDiscipline.previous_changes.keys
            if change_column_name  != ""
                for changed_column in change_column_name do 
                    if changed_column != "updated_at"
                        fvalue = change_column_value[changed_column][0]
                        tvalue = change_column_value[changed_column][1]
                    log_history(Discipline, changed_column, fvalue ,tvalue, @current_user.email)
                    end
                end  
            end   
            #end Save updated  history 
            if sStype == "4" && sStatus == "ACTIVE"
              oUserUpdate = User.where(id: sId).first
              if !oUserUpdate.nil?
                oUserUpdate.update({status: "INACTIVE",  note: "Buộc thôi việc" });
                #Save updated  history (Đạt 10/01/2023)
                change_column_value = oUserUpdate.previous_changes
                change_column_name = oUserUpdate.previous_changes.keys
                if change_column_name  != ""
                    for changed_column in change_column_name do 
                        if changed_column != "updated_at"
                            fvalue = change_column_value[changed_column][0]
                            tvalue = change_column_value[changed_column][1]
                        log_history(User, changed_column, fvalue ,tvalue, @current_user.email)
                        end
                    end  
                end   
                #end Save updated  history 
              end
            else
              oUserUpdate = User.where(id: sId).first
              if !oUserUpdate.nil?
                oUserUpdate.update({status: "ACTIVE",  note: "" });
                #Save updated  history (Đạt 10/01/2023)
                change_column_value = oUserUpdate.previous_changes
                change_column_name = oUserUpdate.previous_changes.keys
                if change_column_name  != ""
                    for changed_column in change_column_name do 
                        if changed_column != "updated_at"
                            fvalue = change_column_value[changed_column][0]
                            tvalue = change_column_value[changed_column][1]
                        log_history(User, changed_column, fvalue ,tvalue, @current_user.email)
                        end
                    end  
                end   
                #end Save updated  history 
              end
            end
            msg = lib_translate("Update_successfully")
          end
        end 
        redirect_to discipline_edit_path(id: sId , lang: session[:lang]), notice: msg
      else
        listAr =[];
        disdoclist = Discdoc.where(discipline_id: idDiscipline)

        disdoclist.each do |disdoc|
          listAr.push(file_owner: disdoc.mediafile.owner, file_name: disdoc.mediafile.file_name, 
          created_at: disdoc.mediafile.created_at.strftime("%d/%m/%Y"),
          relative_id: disdoc.discipline_id, id: disdoc.id)
        end 
        render json:{keyAr: disdoclist, listAr: listAr }
        end
    end

  def details
    id = params[:id]
    session[:id_detal] = id
    @discipline = Discipline.where("id = #{id}").first
    
  end

  def del
    id = params[:id]
    uid = params[:uid]
    did = params[:did]
    ck_action = params[:ck_action]
    msg = lib_translate("Not_Success")
    if ck_action == "document"
      discdoc = Discdoc.where("id = #{did}").first
      if !discdoc.nil?
        @id_mediafile = discdoc.mediafile_id
        discdoc.destroy  
        delete_mediadile(@id_mediafile)
        msg = lib_translate("Delete_successfully")
      end
      redirect_to discipline_edit_path(id: id, uid: uid,lang: session[:lang]), notice: msg
    else
      #end Save updated  history 
      discipline = Discipline.where("id = #{id}").first
      if !discipline.nil?
        discipline.destroy
        oUserUpdate = User.where(id: uid).first
        if !oUserUpdate.nil?
          oUserUpdate.update({status: "ACTIVE",  note: "" });
          #Save updated  history (Đạt 10/01/2023)
          change_column_value = oUserUpdate.previous_changes
          change_column_name = oUserUpdate.previous_changes.keys
          if change_column_name  != ""
              for changed_column in change_column_name do 
                  if changed_column != "updated_at"
                      fvalue = change_column_value[changed_column][0]
                      tvalue = change_column_value[changed_column][1]
                  log_history(User, changed_column, fvalue ,tvalue, @current_user.email)              
                  end
              end  
          end   
        end
        log_history(Discipline, "Xóa", discipline.name , "Đã xóa khỏi hệ thống", @current_user.email)
        msg = lib_translate("Delete_successfully")
      end
      redirect_to discipline_edit_path(id: id , lang: session[:lang]), notice: msg
    end
  end
  
  def discipline_upload_mediafile
    file = params["file"]
    discipline_id = params["discipline_id"]
    # kiểm tra có file hay ko
    if !file.nil? && file !=""
      #upload file
      @id_mediafile =  upload_document(file)
      # update file discdoc
      @discdoc = Discdoc.new
      @discdoc.discipline_id = discipline_id
      @discdoc.note = @id_mediafile[:name]
      @discdoc.mediafile_id = @id_mediafile[:id]
      @discdoc.status = @id_mediafile[:status]
      @discdoc.save
      #send data to font end
      @discipline = Discipline.where("id = #{discipline_id}").first
      
      @data = {
        discipline_id:discipline_id, 
        id_doc:@discdoc.id ,
        file_id:@id_mediafile[:id], 
        file_name:@id_mediafile[:name], 
        file_owner: @id_mediafile[:owner], 
        created_at:@discdoc[:created_at].strftime("%d/%m/%Y")}
      render json: @data
    else
      render json: "No file!"
    end
  end 
end
  