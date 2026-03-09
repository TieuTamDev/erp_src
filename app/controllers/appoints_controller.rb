class AppointsController < ApplicationController
    before_action :authorize
    def index
        @work = Work.new 
        @workin = Workin.new  
        @positionjobs = Positionjob.all.order("created_at DESC")
        @departments = Department.all.order("created_at DESC")   
        @workins = Workin.all.order("created_at DESC")

        @works_id = params[:works_id] || []

        @workUpdate = []
        @works_id.each do |work_id|
            new_work = Work.select("concat(last_name,' ',first_name) as user_name, positionjobs.name as positionjob_name, positionjob_id").joins(:user,:positionjob).where('works.id = ?',work_id).first
            if !new_work.positionjob.nil?
                department = Department.select('name').where('id = ?',new_work.positionjob.department_id).first
                department_name = department.name
            else
                department_name = "Not find"
                
            end
            @workUpdate.push({
                user_name:new_work.user_name,
                positionjob_name:new_work.positionjob_name,
                department_name:department_name
            })
        end

        search = params[:search] || ''
        sql = Work.joins(:user).where("email LIKE ? OR sid = ? OR concat(last_name,' ',first_name) LIKE ?", "%#{search}%", "#{search}", "%#{search}%").where("positionjob_id IS NOT NULL")
        @works = pagination_limit_offset(sql, 10)
    end

    def edit
        # render positionjobs with departments
        idDepartment = params[:idDepartment]
        list =[];
        @positionjobs = Positionjob.where(department_id: idDepartment)
        @positionjobs.each do |poss|
            list.push(id: poss.id, name: poss.name)
        end
        render json:{key: @positionjobs, list: list }
    end

    def update
        
        positionjob_id_work = params[:positionjob_id_work]
        user_id_work = params[:user_id_work]
        work_id_add = params[:work_id_add]

        works_id = params[:works_id] || []
        users_id = params[:users_id] || []
        departments_id = params[:departments_id] || []
        positionjobs_id = params[:positionjobs_id] || []

        positionjobs_id_old = params[:positionjobs_id_old] || []
        departments_id_old = params[:departments_id_old] || []

        # update work
        
        works_id.each_with_index do |work_id,index|
            work = Work.where(id: work_id).first
            if !work.nil?
                Workin.create({
                    user_id: users_id[index], 
                    # positionjob: positionjobs_id[index],
                    department_id: departments_id[index], 
                    dtstart: work.created_at, 
                    dtend: DateTime.now
                })
                work.update({
                        user_id: users_id[index], 
                        positionjob_id: positionjobs_id[index]
                    })
                

                

                # cập nhật leader cho đơn vị khi bổ nhiệm có vị trí TRUONG-PHONG
                oPositionjob = Positionjob.where(id: positionjobs_id[index]).first
                if !oPositionjob.nil?
                    if oPositionjob.scode.include?("TRUONG")
                        oDepartment = Department.where(id: departments_id[index]).first
                        if !oDepartment.nil?
                            oUsser = User.where(id: users_id[index]).first
                            if !oUsser.nil?
                                oDepartment.update({
                                    leader: oUsser.email
                                })
                            end
                        end
                    end
                end
                #Save updated  history (Đạt 10/01/2023)
                change_column_value = work.previous_changes
                change_column_name = work.previous_changes.keys
                if change_column_name  != ""
                    for changed_column in change_column_name do 
                        if changed_column != "updated_at"
                            fvalue = change_column_value[changed_column][0]
                            tvalue = change_column_value[changed_column][1]                   
                        log_history(Work, changed_column, fvalue ,tvalue,  @current_user.email)                        
                        end
                    end  
                end   
                #end Save updated  history
            end
        end
        if work_id_add.nil? || work_id_add == ""
            oWordDup = Work.where("user_id = ? AND positionjob_id = ?", user_id_work, positionjob_id_work).first
            if !oWordDup.nil?
                oWordDup.update({
                    user_id: user_id_work, 
                    positionjob_id: positionjob_id_work
                })
            else
                Work.create({
                    user_id: user_id_work, 
                    positionjob_id: positionjob_id_work
                })
                # cập nhật leader cho đơn vị khi bổ nhiệm có vị trí TRUONG-PHONG
                oPositionjob = Positionjob.where(id: positionjob_id_work).first
                if !oPositionjob.nil?
                    if oPositionjob.scode.include?("TRUONG")
                        oDepartment = Department.where(id: oPositionjob.department_id).first
                        if !oDepartment.nil?
                            oUsser = User.where(id: user_id_work).first
                            if !oUsser.nil?
                                oDepartment.update({
                                    leader: oUsser.email
                                })
                            end
                        end
                    end
                end
            end
            #end Save updated  history
        end

        redirect_to appoints_index_path(lang: session[:lang],works_id:works_id), notice: lib_translate("Update_work_successfully")
    end

    def del
        id = params[:id]
        apoints = Work.where("id = #{id}").first
        msg = lib_translate("Not_Success")
        if !apoints.nil?
            apoints.destroy
            msg = lib_translate("Delete_successfully")
        end
        redirect_to appoints_index_path(lang: session[:lang],page: session[:page], per_page: session[:per_page], search: session[:search]), notice: msg
    end

    def import_excel
        if params[:file].present? && params[:file].is_a?(ActionDispatch::Http::UploadedFile)
          file = params[:file]
          current_time = Time.current
          current_year = current_time.year
          begin
            excel_datas = read_excel(file, 1)
            excel_datas.each_with_index do |row, index|
                # Mã nhân sự
                sid = row[0].to_s.strip
                # Chức vụ
                name = row[1].to_s.strip    
                # Đơn vị
                depart = row[2].to_s.strip

                user = find_user(sid)
                positionjob = find_positionjob(name, depart)
                unless Work.exists?(user_id: user.id, positionjob_id: positionjob.id)
                    Work.create({
                        user_id: user.id,
                        positionjob_id: positionjob.id
                    })
                end
            end
            if errors.empty?
              flash[:success] = "Import thành công!"
            else
              flash[:error] = "Có lỗi khi import:\n#{errors.join("\n")}"
            end
          rescue => e
            flash[:error] = "Đã xảy ra lỗi khi đọc file: #{e.message}"
          end
        else
          flash[:error] = "Vui lòng chọn một file Excel để import!"
        end
        redirect_to request.referer
    end
    def find_user(sid_cell)
        user = User.find_by(sid: sid_cell)
        raise "Không tìm thấy người dùng với SID '#{sid_cell}'" unless user
        user
    end

    def find_positionjob(name_cell, depart_cell)
        depart = Department.find_by(name: depart_cell)
        raise "Không tìm thấy Đơn vị '#{depart_cell}'" unless depart

        positionjob = Positionjob.find_by(name: name_cell, department_id: depart.id)
        raise "Không tìm thấy Chức vụ '#{name_cell}' trong đơn vị '#{depart.name}'" unless positionjob

        positionjob
    end

end