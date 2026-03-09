class ReleasedMandocsController < ApplicationController
    before_action :authorize

    def incoming_index 
      @mandoc= Mandoc.new
        session[:last_url] = request.url
        search = params[:search] || ''
        oUserORG = Uorg.where(user_id: session[:user_id]).first
        if !oUserORG.nil?
          organization_id = oUserORG.organization_id
          @organization_name = oUserORG.organization&.name
          @departments = Department.where(organization_id: organization_id)
          id_users_uorg = Uorg.where(organization_id: organization_id).pluck(:user_id)
          @list_users_uorg = User.where(id: id_users_uorg)
          value_sno = Mandoc.where("sfrom is not null AND YEAR(created_at) = YEAR(CURRENT_DATE())").where(organization_id: organization_id).select(:sno).last
          @value_sno = value_sno&.sno.to_i + 1
          sql = Mandoc.where("notes LIKE ? OR signed_by LIKE ? OR ssymbol LIKE ? OR sfrom LIKE ? OR type_book LIKE ? OR DATE_FORMAT(DATE_ADD(effective_date, INTERVAL 7 HOUR), '%d/%m/%Y') LIKE ?", "%#{search}%", "%#{search}%", "%#{search}%", "%#{search}%", "%#{search}%" , "%#{search}%").where(organization_id: organization_id).where("sfrom IS NOT NULL").where(status: ["INACTIVE", "DELETE"]).order(id: :desc)
          @incoming = pagination_limit_offset(sql, 10)
        else 
          redirect_to dashboards_index_path(lang: session[:lang]) and return
        end
        @mandocbooks = Mandocbook.where(status: "ACTIVE")
        @mandoctypes = Mandoctype.where(status: "ACTIVE")
        @mandocpriorities = Mandocpriority.where(status: "ACTIVE")
        @mandocfroms= Mandocfrom.where(status: "ACTIVE")
    end    

    def incoming_update
      organization_id = ""
      department_id =""
      oUserORG = Uorg.where(user_id: session[:user_id]).first
      if !oUserORG.nil?
          organization_id = oUserORG.organization_id
      end
      id_mandoc = params[:mandoc_id]
      type_book = params[:type_book]
      sno = params[:sno]
      ssymbol = params[:ssymbol]
      department_handle_release = params[:department_handle_release]
      stype = params[:stype]
      slink = params[:slink]
      created_by = params[:created_by]
      received_at = params[:received_at]
      effective_date = params[:effective_date]
      spriority = params[:spriority]
      number_pages = params[:number_pages]
      sfrom = params[:sfrom]
      contents = params[:contents]
      notes = params[:notes]
      department_id = params[:department_id_user_login]
      media_ids= params[:media_ids] || []
      option_medias = params[:option_media] || []
      # if !contents.nil? || contents != ""
      #     contents =  contents.gsub(/\s+/, " ").strip
      # end
      if id_mandoc == "" 
          @mandoc = Mandoc.new
          @mandoc.type_book = type_book
          @mandoc.sno = sno
          @mandoc.ssymbol = ssymbol
          @mandoc.stype = stype
          @mandoc.contents = contents
          @mandoc.notes = notes
          @mandoc.slink = slink
          @mandoc.created_by = created_by
          @mandoc.received_at = received_at
          @mandoc.effective_date = effective_date
          @mandoc.spriority = spriority
          @mandoc.number_pages = number_pages
          @mandoc.sfrom = sfrom
          @mandoc.status = "INACTIVE"
          @mandoc.deadline = ""
          @mandoc.organization_id = organization_id
          if @mandoc.save
              media_ids.each do |id|
                mandocsfile = Mandocfile.where(id: id)
                option_medias.each do |option_media|
                    if !mandocsfile.nil? 
                        if option_media.include?(id)
                            mandocsfile.update({mandoc_id: @mandoc.id, dtype: 'ENACT'})
                        end
                    end
                end
              end
                
              # Dat + Vu
              # Save first mandoc dhandle
              works = @current_user.works
              works.each do |work|
                  if !work&.positionjob.nil? && !work&.positionjob&.department.nil?
                    department_id = work&.positionjob&.department&.id
                  end
              end
              if !department_id.nil?
                mandhandlesss = Mandocdhandle.create({
                    mandoc_id: @mandoc.id,
                    department_id: department_id,
                    srole: "XULY",
                    deadline: "",
                    contents: contents
                }) 
                mandhandle_id = Mandocdhandle.where(mandoc_id: @mandoc.id).last.id
                if !mandhandle_id.nil?
                    Mandocuhandle.create({
                        mandocdhandle_id: mandhandlesss.id,
                        user_id: session[:user_id],
                        srole: "XULY",
                        deadline: "",
                        contents: contents,
                        sread: "CO",
                        status: "DAXULY"
                    })
                end

                mandocdhandle_department_handle_release = Mandocdhandle.create({
                    mandoc_id: @mandoc.id,
                    department_id: department_handle_release,
                    srole: "XULY",
                    deadline: "",
                    contents: contents
                }) 

                Mandocuhandle.create({
                  mandocdhandle_id: mandocdhandle_department_handle_release.id,
                  srole: "XULY",
                  sread: "CO",
                  deadline: "",
                  status: "DAXULY",
                  contents: contents
                })

                # list_Trpp = []
                # positionjob_ids_list = Positionjob.where("department_id = ? AND (scode LIKE ? OR scode LIKE ?)", department_handle_release, "%TRUONG%", "%PHO%")
                # if !positionjob_ids_list.nil?
                #     positionjob_ids_list.each do |positionjob|
                #         works = Work.where(positionjob_id: positionjob.id)
                #         if !works.nil?
                #             works.each do |work|
                #                 oUser = User.where(id: work.user_id).first
                #                 if !oUser.nil?
                #                     list_Trpp.push(oUser.id)
                #                 end
                #             end 
                #         end 
                #     end 
                #     list_Trpp.uniq
                #     if !list_Trpp.nil?
                #         list_Trpp.each do |list|
                #             Mandocuhandle.create({
                #                 mandocdhandle_id: mandocdhandle_department_handle_release.id,
                #                 user_id: list,
                #                 srole: "XULY",
                #                 sread: "CO",
                #                 deadline: "",
                #                 status: "DAXULY",
                #                 contents: contents
                #             })
                #         end
                #     end
                # end 

                mandhandlesss = Mandocdhandle.create({
                  mandoc_id: @mandoc.id,
                  department_id: department_id,
                  srole: "XULY",
                  deadline: "",
                  contents: contents
                }) 
                mandhandle_id = Mandocdhandle.where(mandoc_id: @mandoc.id).last.id
                if !mandhandle_id.nil?
                    Mandocuhandle.create({
                        mandocdhandle_id: mandhandlesss.id,
                        user_id: session[:user_id],
                        srole: "XULY",
                        deadline: "",
                        contents: "Ban hành văn bản",
                        sread: "CO",
                        status: "DAXULY"
                    })
                end
              end
            end 
        else
            mandoc_update = Mandoc.where(id:id_mandoc).first
            mandoc_update.update({
                type_book: type_book,
                sno: sno,
                ssymbol: ssymbol,
                stype: stype,
                contents: contents,
                notes: notes,
                slink: slink,
                created_by: created_by,
                received_at: received_at,
                effective_date: effective_date,
                spriority: spriority,
                number_pages: number_pages
            });
                media_ids.each do |id|
                    mandocsfile = Mandocfile.where(id: id)
                    if !mandocsfile.nil?
                        mandocsfile.update({mandoc_id: id_mandoc})
                    end
                end    
        end
        redirect_to released_mandocs_incoming_index_path(lang: session[:lang])
    end
    
    def outgoing_index
      session[:last_url] = request.url
      @mandoc= Mandoc.new
        search = params[:search] || ''
        oUserORG = Uorg.where(user_id: session[:user_id]).first
        if !oUserORG.nil?
            organization_id = oUserORG.organization_id
            @organization_name = oUserORG.organization&.name
            @departments = Department.where(organization_id: organization_id)
            id_users_uorg = Uorg.where(organization_id: organization_id).pluck(:user_id)
            @list_users_uorg = User.where(id: id_users_uorg)
            sql = Mandoc.where("notes LIKE ? OR signed_by LIKE ? OR ssymbol LIKE ? OR type_book LIKE ? OR DATE_FORMAT(DATE_ADD(effective_date, INTERVAL 7 HOUR), '%d/%m/%Y') LIKE ?", "%#{search}%", "%#{search}%", "%#{search}%", "%#{search}%" , "%#{search}%").where(organization_id: organization_id).where(status: ["INACTIVE", "DELETE"]).where("sfrom IS NULL").order(id: :desc)
            @outgoing =  pagination_limit_offset(sql, 10)
        else
          redirect_to dashboards_index_path(lang: session[:lang]) and return
        end
        
        @mandocbooks = Mandocbook.where(status: "ACTIVE")
        @mandoctypes = Mandoctype.where(status: "ACTIVE")
        @mandocpriorities = Mandocpriority.where(status: "ACTIVE")
        @mandocfroms= Mandocfrom.where(status: "ACTIVE")
    end

    def outgoing_update
      id_mandoc = params[:id_mandoc]
      type_book = params[:type_book]
      sno = params[:sno]
      ssymbol = params[:ssymbol]
      stype = params[:stype]
      signed_by = params[:signed_by]
      slink = params[:slink]
      created_by = params[:created_by]
      received_at = params[:received_at]
      effective_date = params[:effective_date]
      spriority = params[:spriority]
      number_pages = params[:number_pages]
      contents = params[:contents]
      status = params[:status]
      notes = params[:notes]
      media_ids= params[:media_ids] || []
      option_medias = params[:option_media] || []
      param_id_department = params[:mdepartment]
      
      if !param_id_department.nil?
          depart = Department.where(id: param_id_department).first
          if !depart.nil?
            mdepartment = depart.name
          end
      end
      organization_id = ""
      oUserORG = Uorg.where(user_id: session[:user_id]).first
      if !oUserORG.nil?
          organization_id = oUserORG.organization_id
      end

      if id_mandoc == "" 
          @mandoc = Mandoc.new
          @mandoc.type_book = type_book
          @mandoc.sno = sno
          @mandoc.ssymbol = ssymbol
          @mandoc.stype = stype
          @mandoc.signed_by = signed_by
          @mandoc.contents = contents
          @mandoc.notes = notes
          @mandoc.slink = slink
          @mandoc.created_by = created_by
          @mandoc.received_at = received_at
          @mandoc.mdepartment = mdepartment
          @mandoc.spriority = spriority
          @mandoc.number_pages = number_pages
          @mandoc.effective_date = effective_date || ""
          @mandoc.status = "INACTIVE"
          @mandoc.deadline = DateTime.now() + 15.days
          @mandoc.organization_id = organization_id
          if @mandoc.save
              media_ids.each do |id|
                  mandocsfile = Mandocfile.where(id: id)
                  option_medias.each do |option_media|
                      if !mandocsfile.nil? 
                          if option_media.include?(id)
                              mandocsfile.update({mandoc_id: @mandoc.id, dtype: 'ENACT'})
                          end
                      end
                  end
              end

              
              oWork = Work.where(user_id: session[:user_id])
              department = Positionjob.where(id: oWork.pluck(:positionjob_id)).first
              department_id = department&.department_id

              

              if !department_id.nil?
                mandhandlesss = Mandocdhandle.create({
                    mandoc_id: @mandoc.id,
                    department_id: department_id,
                    srole: "XULY",
                    deadline: "",
                }) 
                mandhandle_id = Mandocdhandle.where(mandoc_id: @mandoc.id).last.id
                if !mandhandle_id.nil?
                    Mandocuhandle.create({
                        mandocdhandle_id: mandhandlesss.id,
                        user_id: session[:user_id],
                        srole: "XULY",
                        sread: "CO",
                        status: "DAXULY",
                        deadline: DateTime.now,
                    })
                end
              end 

          end  
             
      end
      redirect_to released_mandocs_outgoing_index_path(lang: session[:lang])
    end

    def remove_mediafile
      id_mediafile = params[:id_mediafile]
      id_tr_render = params[:id_tr_render]
      id_mandocfile = params[:id_mandocfile]
      if !id_mediafile.nil? && id_mediafile != ""
          oMedia = Mediafile.where(id: id_mediafile).first
          if !oMedia.nil?
            oMedia.destroy
            respond_to do |format|
              format.js {
                render js: "deleteTrMediafile(#{id_tr_render.to_json.html_safe}, #{id_mandocfile});"
              }
            end
          end
      end
    end
    

    def import_mandoc
        file = params[:file]
        excel_datas = []
        creates = []
        updates = []
        valids = []
        trans_line = lib_translate("Line")
        trans_invalid = lib_translate("Invalid")
        trans_empty = lib_translate("Empty")
        tran_unknow = lib_translate("Undefined")
        had_error = false
        error_message = ""
        record_found = false
        organization_id = ""
        oUserORG = Uorg.where(user_id: session[:user_id]).first
        if !oUserORG.nil?
            organization_id = oUserORG.organization_id
        end
        oUsername = User.where(id: session[:user_id]).first
        if !oUsername.nil?
            name = "#{oUsername.last_name} #{oUsername.first_name}"
        end
        begin
        excel_datas = read_excel(file,1)
        # Loop through each row and create a new record
        excel_datas.each_with_index do |row,index|
            stt = (index + 1) + 1
            sno = row[0]
            created_at = row[1]
            ssymbol = row[2]
            effective_date = row[3]
            received_at = row[4]
            sfrom = row[5]
            type_book = row[6]
            contents = row[7]
            mdepartment = row[8]
            created_by = row[9]
            deadline = row[10]

            if deadline.nil?
                deadline = received_at
            end
            if sfrom.nil?
                valids.push({
                    line: "#{trans_line} #{stt.to_s}",
                    message:"Cơ quan ban hành #{trans_empty}"
                })
                next
            end
            if created_by.nil?
              created_by = name
            end
            if effective_date.nil?
              effective_date = received_at
            end
            if created_at.nil?
              created_at = effective_date
            end
            mandoctype = Mandoctype.where(name: type_book).first
              scode_type = ""
              if !mandoctype.nil?
                scode_type = mandoctype.scode
              else
                valids.push({
                        line: "#{trans_line} #{stt.to_s}",
                        message:"Loại sổ #{tran_unknow}"
                    })
                next
              end
          attrs = {
            sno: sno,
            created_at:created_at ,
            ssymbol: ssymbol,
            effective_date:effective_date ,
            received_at:received_at ,
            sfrom: sfrom,
            stype: scode_type ,
            contents: contents,
            mdepartment: mdepartment,
            created_by: created_by,
            deadline: deadline,
            status: "INACTIVE",
            organization_id: organization_id

          }

        ##### update
        if !ssymbol.nil?
            mandoc_check = Mandoc.where(ssymbol: ssymbol, sno: sno).where("sfrom IS NOT NULL").where("organization_id = ? AND YEAR(DATE_ADD(effective_date, INTERVAL 7 HOUR)) = ?", organization_id, Date.parse(effective_date.to_s).year).first
            if !mandoc_check.nil?
                mandoc_check.update(attrs)
                updates.push(mandoc_check)
                next
            end
        else 
          mandoc_check = Mandoc.where(contents: contents, sfrom: sfrom, sno: sno).where("sfrom IS NOT NULL").where("organization_id = ? AND YEAR(DATE_ADD(effective_date, INTERVAL 7 HOUR)) = ?", organization_id, Date.parse(effective_date.to_s).year).first
            if !mandoc_check.nil?
              mandoc_check.update(attrs)
              updates.push(mandoc_check)
              next
            end
        end
        

        #####create new
        madoc_create =  Mandoc.create(attrs);
        if madoc_create.nil?
          valids.push({
            line: "#{trans_line} #{stt.to_s}",
            message:"#{lib_translate("Can_not_create")}: #{tran_unknow}"
          })
          next
        end
        creates.push(madoc_create)

      end
        rescue Exception => e
        had_error = true
        error_message = e.message
        creates.each do |madoc_created|
            madoc_created.destroy
        end
        ensure
        result = {}
        if had_error
            result = {
            code:503,
            message:error_message,
            }
        else
            result = {
            code:200,
            result_total:excel_datas.size,
            success_count:creates.size,
            updates:updates,
            valids:valids,
            creates:creates
            }
        end
        respond_to do |format|
            format.js {
            render js: "#{result.to_json.html_safe}"
            }
        end
        end

    end
    def import_mandoc_out
        file = params[:file]
        excel_datas = []
        creates = []
        updates = []
        valids = []
        test_data = []
        trans_line = lib_translate("Line")
        trans_invalid = lib_translate("Invalid")
        trans_empty = lib_translate("Empty")
        tran_unknow = lib_translate("Undefined")
        had_error = false
        error_message = ""
        record_found = false
        organization_id = ""
        oUserORG = Uorg.where(user_id: session[:user_id]).first
        if !oUserORG.nil?
            organization_id = oUserORG.organization_id
        end
        begin
            excel_datas = read_excel(file,1)
            # Loop through each row and create a new record
            excel_datas.each_with_index do |row,index|
                stt = (index + 1) + 1
                sno = row[0]
                type_book = row[1]
                ssymbol = row[2]
                notes = row[3]
                mdepartment = row[4]
                created_by = row[5]
                signed_by = row[6]
                effective_date = row[7]
                received_at = row[8]
                received_place = row[9]
              if effective_date.nil?
                  valids.push({
                      line: "#{trans_line} #{stt.to_s}",
                      message:"Ngày ban hành#{trans_empty}"
                  })
                  next
              end
              if received_at.nil?
                received_at = effective_date
              end
              mandoctype = Mandoctype.where(name: type_book).first
              scode_type = ""
              if !mandoctype.nil?
                scode_type = mandoctype.scode
              else
                valids.push({
                        line: "#{trans_line} #{stt.to_s}",
                        message:"Loại sổ #{tran_unknow}"
                    })
                next
              end
              # 2023-01-24
              attrs = {
                sno: sno,
                stype: scode_type,
                ssymbol: ssymbol,
                notes: notes,
                mdepartment: mdepartment,
                created_by: created_by,
                signed_by: signed_by,
                effective_date: effective_date,
                received_at:received_at ,
                received_place: received_place,
                deadline: effective_date,
                status: "INACTIVE",
                organization_id: organization_id
              }
            ##### update
            mandoc_check = Mandoc.where(ssymbol: ssymbol, notes: notes).where("sfrom IS NULL").where("organization_id = ? AND YEAR(DATE_ADD(effective_date, INTERVAL 7 HOUR)) = ?", organization_id, Date.parse(effective_date.to_s).year).first
            if !mandoc_check.nil?
                mandoc_check.update(attrs)
                updates.push(mandoc_check)
              next
            end

            #####create new
            madoc_create =  Mandoc.create(attrs);
            if madoc_create.nil?
              valids.push({
                line: "#{trans_line} #{stt.to_s}",
                message:"#{lib_translate("Can_not_create")}: #{tran_unknow}"
              })
              next
            end
            creates.push(madoc_create)

          end
        rescue Exception => e
          had_error = true
          error_message = e.message
          creates.each do |madoc_created|
            madoc_created.destroy
          end
        ensure
          result = {}
          if had_error
            result = {
              code:503,
              message:error_message,
            }
          else
            result = {
              code:200,
              result_total:excel_datas.size,
              success_count:creates.size,
              updates:updates,
              valids:valids,
              creates:creates
            }
          end
          respond_to do |format|
            format.js {
              render js: "#{result.to_json.html_safe}"
            }
          end
        end
    end

    def mandoc_save_mandocmedia
      mandoc_id = params[:mandoc_id]
      media_ids = params[:media_ids] || []
      option_medias = params[:option_media] || []
      success = true
      count = 0
      mandoc = Mandoc.where(id: mandoc_id).first
      begin
        if !mandoc.nil?
          media_ids.each do |media_id|
            dtype = ""
            option_medias.each do |option_media|
              if option_media.include?(media_id) && option_media.include?("process")
                dtype = 'PROCESS'
              elsif option_media.include?(media_id) && option_media.include?("coordinate")
                dtype = 'COORDINATE'
              elsif option_media.include?(media_id) && option_media.include?("reference")
                dtype = 'REFERENCE'
              end
            end
              Mandocfile.create({
                mandoc_id:mandoc_id,
                mediafile_id: media_id,
                dtype: dtype
              })
              count = count + 1
          end
          
        else
          success = false
        end
      rescue Exception => e
        success = false
      ensure
        respond_to do |format|
          format.js {
            render js: "onSavedMandocFiles(true,#{mandoc_id.to_json.html_safe});"
          }
        end
      end
      
  end

  def mandocfile_upload_mediafile
      file = params[:file]
      mandoc_id = params["mandoc_id"]
      # kiểm tra có file hay ko
      if !file.nil? && file !=""
          #upload file
          id_mediafile =  upload_document(file)

          mandocsfile = Mandocfile.new
          mandocsfile.mandoc_id = mandoc_id
          mandocsfile.mediafile_id = id_mediafile[:id]
          mandocsfile.save
          #send data to font end
          data = {
            mandoc_id:mandoc_id,
            id:mandocsfile.id,
            file_id:id_mediafile[:id],
            file_name:id_mediafile[:name],
            file_owner: id_mediafile[:owner],
            created_at: mandocsfile[:created_at].strftime('%H:%M %d/%m/%Y'),
            type: "new-item"
          }
              
          render json: data
      else
          render json: "No file!"
      end
  end
  def mandocfile_upload_mediafile_new
        file = params["file"]
        mandoc_id = params["id_mandoc"]
        # kiểm tra có file hay ko
        if !file.nil? && file !=""
            #upload file
            @id_mediafile =  upload_document(file)
            # update file mandocsfile
            @mandocsfile = Mandocfile.new
            @mandocsfile.mandoc_id = mandoc_id
            @mandocsfile.mediafile_id = @id_mediafile[:id]
            @mandocsfile.save
                #send data to font end
            data = {
                mandoc_id:mandoc_id, 
                id:@mandocsfile.id ,
                file_id:@id_mediafile[:id], 
                file_name:@id_mediafile[:name], 
                file_owner: @id_mediafile[:owner], 
                created_at: @mandocsfile[:created_at].strftime("%d/%m/%Y")}
            render json: data
        else
            render json: "No file!"
        end
    end
  def delete_mandocfile
      id = params[:aid]
      @mandocfile = Mandocfile.where(id: id).first
      @mandocfile.destroy
      redirect_to released_mandocs_incoming_index_path(lang: session[:lang]) , notice: lib_translate("delete_message")
  end

  def delete_mandocfile_out
      id = params[:aid]
      @mandocfile = Mandocfile.where(id: id).first
      @mandocfile.destroy
      redirect_to released_mandocs_outgoing_index_path(lang: session[:lang]) , notice: lib_translate("delete_message")
  end
  # end of function upload file mandocs
  def find_one
      mandoc_id = params[:mandoc_id]
      func_name = params[:func_name]
      type = params[:type] || ""
  
      oMandoc = Mandoc.where(id: mandoc_id).first
      listfiles = []
      if type == "release"
        mandoc_medias = Mandocfile.where(mandoc_id: mandoc_id, dtype: "ENACT").order(created_at: :desc)
        mandoc_medias.each do |y|
            listfiles.push({
              id: y.id,
              relative_id: y.mandoc_id,
              file_name: y.mediafile.file_name,
              file_type: y.mediafile.file_type,
              created_at: y.created_at.strftime('%H:%M %d/%m/%Y'),
              dtype: y.dtype,
              file_owner: y.mediafile.owner
            })
        end
      else
        mandoc_medias = Mandocfile.where(mandoc_id: mandoc_id).order(created_at: :desc)
        mandoc_medias.each do |y|
            listfiles.push({
              id: y.id,
              relative_id: y.mandoc_id,
              file_name: y.mediafile.file_name,
              file_type: y.mediafile.file_type,
              created_at: y.created_at.strftime('%H:%M %d/%m/%Y'),
              dtype: y.dtype,
              file_owner: y.mediafile.owner
            })
        end
      end
      
    
      respond_to do |format|
          format.js { render js: "#{func_name}(#{oMandoc.to_json.html_safe},#{listfiles.to_json.html_safe})"}
      end
  end

  def get_users_by_department
    positionjob_ids = Positionjob.where(department_id: params[:department_id]).pluck(:id)
    works = Work.where(positionjob_id: positionjob_ids).pluck(:user_id)
    @users = User.select("id,first_name,last_name").where(id: works)

    render json: @users
  end

  # LÊ NGỌC HUY
  # Upload file to tinyMCE
  def upload_file_tinymce
    file = params["file"]
    if !file.nil? && file !=""
       datas = upload_document(file)
       url_img = request.base_url + "/mdata/hrm/" + datas[:name]
      render json: { location: url_img }
    else
      render json: { error: 'No file uploaded' }
    end
 end
end