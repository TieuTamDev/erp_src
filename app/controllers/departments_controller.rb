# Author: Đồng, Vũ
class DepartmentsController < ApplicationController
  include WorksHelper
  include DepartmentsHelper

  before_action :authorize
  before_action :set_department
  skip_before_action :verify_authenticity_token

  def index
    @tbdepartmenttypes = Tbdepartmenttype.all
    @department = Department.new
    @documents = Ddoc.all
    @document = Ddoc.new
    @mediafiles = Mediafile.all
    @users = User.where.not(email:"admin@gmail.com")
    @organizations = Organization.all
    # Lấy đơn vị chủ quản của người dùng
    user_org_ids = Uorg.where(user_id: session[:user_id]).pluck(:organization_id)

    search = params[:search] || ''
    sql = Department.where("name LIKE ? OR stype LIKE ? OR scode LIKE ? OR name_en LIKE ? OR leader LIKE ? OR issued_date LIKE ? OR issue_id LIKE ?", "%#{search}%", "%#{search}%", "%#{search}%","%#{search}%", "%#{search}%", "%#{search}%", "%#{search}%")
                    .where(parents: nil)                
                    .where(organization_id: user_org_ids)
    @departments = pagination_limit_offset(sql, 10)
  end

  def fetch_by_organization
    @departments = Department.where(organization_id: params[:organization_id])
    respond_to do |format|
      format.js
    end
  end

  def department_list
    # Lấy đơn vị chủ quản của người dùng
    user_org_ids = Uorg.where(user_id: session[:user_id]).pluck(:organization_id)
    if is_access(session["user_id"], "DEPARTMENT-LIST","READ")
      @group_list =  Department.select("tbdepartmenttypes.name as name,tbdepartmenttypes.id,COUNT(departments.id) as count")
                              .joins("JOIN tbdepartmenttypes ON tbdepartmenttypes.id = departments.stype")
                              .where(parents: nil)
                              .where(organization_id: user_org_ids)
                              .group("tbdepartmenttypes.id")
                              .order("tbdepartmenttypes.name")
      
    else
      redirect_to departments_department_details_path(lang: session[:lang], department_id: session[:department_id])
    end
  end

  def get_department_by_stype
    stype = params[:stype]
    search = params[:search]&.strip || ""
    # Lấy đơn vị chủ quản của người dùng
    user_org_ids = Uorg.where(user_id: session[:user_id]).pluck(:organization_id)

    sql = Department.select("departments.*,users.last_name, users.first_name,organizations.name as org_name,COUNT(DISTINCT works.user_id) as user_count,
                            EXISTS (SELECT 1 FROM departments AS d2 WHERE d2.parents = departments.id) AS has_child")
                    .joins("LEFT JOIN positionjobs ON positionjobs.department_id = departments.id")
                    .joins("LEFT JOIN works ON works.positionjob_id = positionjobs.id")
                    .joins("LEFT JOIN users ON users.email = departments.leader")
                    .joins("LEFT JOIN organizations ON organizations.id = departments.organization_id")
                    .group("departments.id")
                    .order("departments.name")
                    .where(stype:stype)
                    .where(organization_id: user_org_ids)
                    .where("departments.name LIKE ?","%#{search}%")
    
    @departments = limit_offset_query(sql)
    
  end

  def get_department_childs
    @parent_id = params[:parent_id]

    @departments = Department.select("departments.*,organizations.name as org_name,COUNT(DISTINCT works.user_id) as user_count,
                        CONCAT(deputy_user.first_name,' ',deputy_user.last_name) as deputy_name,
                        CONCAT(leader_user.first_name,' ',leader_user.last_name) as leader_name,
                        EXISTS (SELECT 1 FROM departments AS d2 WHERE d2.parents = departments.id) AS has_child")
                .joins("LEFT JOIN positionjobs ON positionjobs.department_id = departments.id")
                .joins("LEFT JOIN works ON works.positionjob_id = positionjobs.id")
                .joins("LEFT JOIN users as leader_user ON leader_user.email = departments.leader")
                .joins("LEFT JOIN users as deputy_user ON deputy_user.email = departments.deputy")
                .joins("LEFT JOIN organizations ON organizations.id = departments.organization_id")
                .group("departments.id")
                .order("departments.name")
                .where("departments.parents = ?",@parent_id)
    
  end

  def department_details
      department_id = params[:department_id]
      search = params[:search].to_s.strip || ''
      @tab_names = TAB_NAMES.dup
      # Nếu là subdepartment thì loại bỏ 5 tab: users, report, kpi, rewards
      @tab_names = @tab_names.except(:users, :report, :kpi, :rewards) if @oDepartment.is_subdepartment?
      @current_tab = params[:tab] || @tab_names[:info]
      @is_subdepartment = @oDepartment.is_subdepartment?

      if @current_tab == @tab_names[:info]
        @department = Department.select("departments.*,tbdepartmenttypes.name as stype, CONCAT(users.last_name, ' ' , users.first_name) as leader_name, organizations.name as organization_name, CONCAT(user_2.last_name, ' ' , user_2.first_name) as issued_name")
                              .joins("LEFT JOIN tbdepartmenttypes ON tbdepartmenttypes.id = departments.stype")
                              .joins("LEFT JOIN users ON users.email= departments.leader")
                              .joins("LEFT JOIN users as user_2 ON user_2.email = departments.issued_by")
                              .joins("LEFT JOIN organizations ON organizations.id= departments.organization_id")
                              .find(department_id)
        return false
      end
      if @current_tab == @tab_names[:tasks]
        @tfunctions = Tfunction.where(is_root: nil, stype: "FUNCTIONS")
        
        # # Lấy tất cả các chức năng (FUNCTIONS) và không phụ thuộc vào parent nào
        # @functions = Tfunction.where(department_id: @oDepartment.id, stype: "FUNCTIONS")
        #                      .where("name LIKE ? OR scode LIKE ?", "%#{search}%", "%#{search}%")
        #                      .order('created_at DESC')
        
        # # Đối với mỗi chức năng, lấy các nhiệm vụ liên quan
        # @functions.each do |function|
        #   # Lấy các nhiệm vụ thuộc chức năng
        #   function.duties = Tfunction.where(stype: "DUETIES", parent: function.is_root)
        #                             .order('created_at DESC')
          
        #   # Đối với mỗi nhiệm vụ, lấy các công việc liên quan
        #   function.duties.each do |duty|
        #     duty.tasks = Stask.where(tfunction_id: duty.id)
        #                       .order('created_at DESC')
        #   end
        # end
  
  
        positionjobs = Positionjob.where(department_id: department_id)
        works = Work.where(positionjob_id: positionjobs.pluck(:id))
        stasks = Stask.where(id: works.pluck(:stask_id))
        stasks_in_gtask = works.pluck(:gtask_id).compact.empty? ? [] : Stask.where(gtask_id: works.pluck(:gtask_id).compact)
        @data_stasks = stasks + stasks_in_gtask
        duty_ids = @data_stasks.pluck(:tfunction_id).compact.uniq
        duties = Tfunction.where(id: duty_ids)
        function_ids = duties.pluck(:parent).uniq
        @functions = Tfunction.where(id: function_ids)
                              .where("name LIKE ? OR scode LIKE ?", "%#{search}%", "%#{search}%")
        @functions = pagination_limit_offset(@functions, 10)
        @stasks_without_duty = @data_stasks.select { |s| s.tfunction_id.blank? }
        return false
      end
      if @current_tab == @tab_names[:positionjobs]
        dueties = Tfunction.where(department_id: @oDepartment.id, stype: "DUETIES")
        @stasks = Stask.where(tfunction_id: dueties.pluck(:id))
        positionjob_ids = Positionjob.where(department_id: @oDepartment.id).pluck(:id, :is_root).flatten.uniq.map(&:to_i)
  
        @positionjobs_to_add = Positionjob.where.not(id: positionjob_ids)
                                          .where(is_root: nil)
                                          .order(created_at: :desc)
  
        @positionjobs_to_edit = Positionjob.where(id: positionjob_ids)
                                           .order(created_at: :desc)
  
        users_id = Work.left_outer_joins(:positionjob, :user)
                                      .where(positionjobs: {department_id: @oDepartment.id})
                                    .select("users.*").pluck(:id).uniq
        # Lấy đơn vị chủ quản của người dùng
        user_org_ids = Uorg.where(user_id: session[:user_id]).pluck(:organization_id)
        @users = User.joins(:uorgs)
                     .where(uorgs: { organization_id: user_org_ids })
                     .order(:last_name)
                     .distinct
        positionjob_query = Positionjob.where(department_id: @oDepartment.id)
        positionjob_query = positionjob_query.where("positionjobs.name LIKE ? OR positionjobs.amount LIKE ?", "%#{search}%", "%#{search}%") if search.present?
        paginated_jobs = pagination_limit_offset(positionjob_query, 10)
    
        job_ids = paginated_jobs.pluck(:id)
    
        records = Positionjob.select("
                              positionjobs.id AS positionjob_id,
                              positionjobs.name AS positionjob_name,
                              positionjobs.is_root AS is_root,
                              users.id AS user_id,
                              users.first_name,
                              users.last_name
                            ")
                            .joins("LEFT JOIN works ON works.positionjob_id = positionjobs.id")
                            .joins("LEFT JOIN users ON users.id = works.user_id")
                            .where(positionjobs: { id: job_ids })
    
        records_grouped = records.group_by(&:positionjob_id)
    
        @positionjobs = paginated_jobs.map do |pj|
          users = records_grouped[pj.id]&.map do |r|
            next if r.user_id.nil?
            {
              id: r.user_id,
              user_name: "#{r.last_name} #{r.first_name}"
            }
          end&.compact&.uniq || []
    
          # appointment = Appointment.where()
          {
            id: pj.id,
            name: pj.name,
            amount: pj.amount,
            users: users
          }
        end
  
        return false
      end
      if @current_tab == @tab_names[:users]
        users = Positionjob.select("positionjobs.amount,positionjobs.name as positionjob_name,
                                    positionjobs.id as positionjob_id,users.sid,users.id,
                                    users.last_name,users.first_name,users.birthday, users.education,
                                    users.email,users.mobile,users.phone")
                        .joins("LEFT JOIN works ON works.positionjob_id = positionjobs.id")
                        .joins("LEFT JOIN users ON users.id = works.user_id")
                        .where("positionjobs.department_id = ?",department_id)
                        .group("positionjobs.id,users.id")
        @positionjob_groups = {}
        users.each do |user|
          if @positionjob_groups[user.positionjob_id]
            @positionjob_groups[user.positionjob_id][:users] << user.attributes.except('positionjob_name', 'positionjob_id','amount').symbolize_keys
          else 
            @positionjob_groups[user.positionjob_id] = {
              name:user.positionjob_name,
              amount:user.amount,
              users:[user.attributes.except('positionjob_name', 'positionjob_id','amount').symbolize_keys]
            }
          end
        end
        
        @users = User.where.not(email:"admin@gmail.com") # TODO: chuyen sang select2 ajax
  
        return false
      end
      if @current_tab == @tab_names[:subdepartments]
        sql = Department.includes(:leader_user, :deputy_user)
                        .where(parents: department_id)
                        .where("departments.name LIKE ? OR departments.scode LIKE ?", "%#{search}%", "%#{search}%")
                        .order('departments.created_at DESC')
        @subdepartments = pagination_limit_offset(sql, 10)
        return false
      end
      if @current_tab == @tab_names[:report]
        return false
      end
      if @current_tab == @tab_names[:kpi]
        return false
      end
      if @current_tab == @tab_names[:rewards]
        return false
      end
    
    
  end

  def assign_stasks
    positionjob_id = params[:positionjob_id]
    department_id = params[:department_id]
    @department = Department.where(id: department_id).first
    @position = Positionjob.where(id: positionjob_id).first
    if !@position.nil?
      @users = Work.joins(:user).where(positionjob_id: @position.id).select("users.*").order("users.last_name ASC").uniq
    end
  end

  def export_excel
    export_fields = params[:export_fields].split(",")
    columns = DepartmentsHelper::EXPORT_FIELDS.select{|column| export_fields.include?(column[:name])}
    # Lấy đơn vị chủ quản của người dùng
    user_org_ids = Uorg.where(user_id: session[:user_id]).pluck(:organization_id)
    
    departments = Department.select("departments.*,
                                      tbdepartmenttypes.name as stype,
                                      CONCAT(users.last_name, ' ' , users.first_name) as leader_name,
                                      organizations.name as organization_name,
                                      CONCAT(user_2.last_name, ' ' , user_2.first_name) as issued_name")
                            .joins("LEFT JOIN tbdepartmenttypes ON tbdepartmenttypes.id = departments.stype")
                            .joins("LEFT JOIN users ON users.email= departments.leader")
                            .joins("LEFT JOIN users as user_2 ON user_2.email = departments.issued_by")
                            .joins("LEFT JOIN organizations ON organizations.id= departments.organization_id")
                            .where(parents: nil)
                            .where(organization_id: user_org_ids)
    

    package = Axlsx::Package.new
    workbook = package.workbook
    sheet = workbook.add_worksheet(name: 'Danh sách phòng ban')
    col_style = workbook.styles.add_style(font_name:"Cambria",b: true,bg_color: "FBE2D5",border: { style: :thin, color: '00000000'},alignment: {horizontal: :center ,vertical: :center})
    header_style = workbook.styles.add_style(font_name:"Cambria",sz: 14,border: { style: :thin, color: '00000000'},alignment: {horizontal: :center ,vertical: :center})
    row_style = workbook.styles.add_style(font_name:"Cambria",border: { style: :thin, color: '00000000'})
    row_center_style = workbook.styles.add_style(font_name:"Cambria",border: { style: :thin, color: '00000000'},alignment: {horizontal: :center ,vertical: :center})
    sheet.add_row(["Danh sách phòng ban"],style: header_style,height:26)
    sheet.merge_cells("A1:#{number_to_column_letter(3)}1")
    sheet.add_row(columns.map{|field| field[:text]},style: col_style,height:24)
    name_list = columns.map{|field| field[:name]}
    departments.each do |department|
      row = []
      if name_list.include?("deputy_name") || name_list.include?("deputy_email")
        # get deputy name
        users = User.select("users.id,CONCAT(users.last_name, ' ' , users.first_name) as deputy_name,users.email,positionjobs.name as positionjob_name")
                .joins(:works)
                .joins("LEFT JOIN positionjobs ON positionjobs.id = works.positionjob_id")
                .joins("LEFT JOIN departments ON departments.id = positionjobs.department_id")
                .where("departments.id = ?",department.id)
        keywords = ["phó"]
        not_keywords = ["phó hiệu trưởng"]
        deputy = users.select{ |user| 
                              keywords.any? { |keyword| user.positionjob_name&.downcase&.strip&.unicode_normalize(:nfc).include?(keyword) } && 
                              !not_keywords.any? { |keyword| user.positionjob_name&.downcase&.strip&.unicode_normalize(:nfc).include?(keyword) }  
                              }.first
        
      end
      columns.each do |column|
        case column[:name]
        when "status"
          value = department[column[:name]] == "0" ? 'Hoạt động' : 'Không hoạt động'
        when "user_count"
          value = User.select("COUNT(DISTINCT users.id) as user_count")
                      .joins(:works)
                      .joins("LEFT JOIN positionjobs ON positionjobs.id = works.positionjob_id")
                      .joins("LEFT JOIN departments ON departments.id = positionjobs.department_id")
                      .where("departments.id = ?",department.id)
                      .group("departments.id").first&.user_count || 0
        when "deputy_name"
          value = deputy&.deputy_name
        when "deputy_email"
          value = deputy&.email
        when "issued_date"
          value = department[column[:name]]&.strftime("%d/%m/%Y")
        else
          value = department[column[:name]]
        end

        row << value
      end
      row = sheet.add_row(row,style: row_style)
      columns.each_with_index do |column,index|
        row[index].style = row_center_style if column[:center] == true
      end
    end

    sheet.column_widths *columns.map{|column| column[:size]}

    file_name = "Danh sách phòng ban.xlsx"
    ## Gửi data để tải xuống
    send_data   package.to_stream.read,
                filename: file_name,
                type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                disposition: 'attachment'
    
  end

  def number_to_column_letter(number)
    return '' if number < 1
    column = ''
    while number > 0
      mod = (number - 1) % 26
      column = (65 + mod).chr + column
      number = (number - 1) / 26
    end
    column
  end

  def get_positionjob_users
    positionjob_id = params[:positionjob_id]
    @view_id = params[:view_id]
    @users = Work.select("users.id as id,users.last_name,users.first_name,users.sid,users.birthday, users.education,users.email,users.mobile,users.phone")
                .joins(:user)
                .where(positionjob_id:positionjob_id)
                .distinct
    @positionjob = Positionjob.find(positionjob_id)

  end

  def upload_file_processing
    file = params["file"]
    id_mediafile =  upload_mediafile(file)
    render plain: "#{id_mediafile}"
  end

  def update
    idDepartment = params[:idDepartment]
    @mediafiles = Mediafile.all.order("created_at DESC")

    @ddoclist = Ddoc.where(department_id: idDepartment)

    id = params[:department_id]
    idDoc = params[:document_id]
    sName = params[:txt_name_department] || ""
    sNameEn = params[:txt_name_en_department] || ""
    sScode = params[:txt_scode_department] || ""
    sEmail = params[:txt_email_department] || ""
    sIssueddt = params[:dt_issued_date_dep] || ""
    sIssuedby = params[:txt_issued_by] || ""
    sLeader = params[:txt_leader_department] || ""
    sIssuedid = params[:txt_issue_id_department] || ""
    sStype = params[:sel_department_type] || ""
    sNote = params[:department_note] || ""
    sStatus = params[:sel_status_dep] || ""
    organization_id = params[:organization_id]
    sFaculty = params[:txt_faculty]
    is_virtual = params[:is_virtual] || nil

    if idDepartment.nil? || idDepartment == ""
      if id == ""
          newDepart = Department.create({
            name: sName.strip,
            name_en: sNameEn.strip,
            scode: sScode.strip,
            email: sEmail.strip,
            issued_date: sIssueddt.strip,
            issued_by: sIssuedby.strip,
            leader: sLeader.strip,
            issue_id: sIssuedid.strip,
            status: sStatus.strip,
            note: sNote.strip,
            stype: sStype,
            organization_id: organization_id,
            faculty: sFaculty,
            is_virtual: is_virtual
          })
          #Save updated  history (Hải 15/10/2025)
          log_history(Department, "Thêm mới", newDepart.name , "Thêm mới phòng ban", @current_user.email)
          redirect_to departments_index_path(lang: session[:lang]), notice: lib_translate("Successfully")
      else

        oDepartments = Department.where("id = #{id}").first
        oDepartments.update({
          name: sName.strip,
          name_en: sNameEn,
          scode: sScode,
          email: sEmail,
          issued_date: sIssueddt,
          issued_by: sIssuedby,
          leader: sLeader.strip,
          note: sNote,
          status: sStatus,
          stype: sStype,
          issue_id: sIssuedid,
          organization_id: organization_id,
          faculty: sFaculty,
          is_virtual: is_virtual
        });

        #Save updated  history (Đạt 10/01/2023)
        change_column_value = oDepartments.previous_changes
        change_column_name = oDepartments.previous_changes.keys
        if change_column_name  != ""
            for changed_column in change_column_name do 
                if changed_column != "updated_at"
                    fvalue = change_column_value[changed_column][0]
                    tvalue = change_column_value[changed_column][1]
                      
                  log_history(Department, changed_column, fvalue ,tvalue, @current_user.email)                    
                end
            end  
        end   
        #end Save updated  history 

        redirect_to department_details_path(lang: session[:lang], id: session[:id_detal_department]) ,notice:  lib_translate("Update_successful_department")
      end

    else
        @ddoc = Ddoc.all.order("created_at DESC")
        listDe =[];
        @ddoclist = Ddoc.where(department_id: idDepartment)

        @ddoclist.each do |doc|
          listDe.push({file_owner: doc.mediafile.owner, file_name: doc.mediafile.file_name,
          created_at: doc.mediafile.created_at.strftime("%d/%m/%Y"),
          id: doc.id, department_id: doc.department_id})
        end
        render json:{keyDe: @ddoclist, listDe: listDe }
    end
  end

  def del
    id = params[:id]
    did = params[:did]
    ck_action = params[:ck_action]
    current_page = params[:currentpage]


    if ck_action == "document"
      @documentse = Ddoc.where("id = #{did}").first
      if !@documentse.nil?
        @id_mediafile = @documentse.mediafile_id
        @documentse.destroy  
        delete_mediadile(@id_mediafile)
      end
      if current_page == "index"
      redirect_to departments_index_path(  lang: session[:lang]) ,notice: lib_translate("Delete_file_successful_department")
      else 
      redirect_to department_details_path(id: session[:id_detal_department] ,  lang: session[:lang]) ,notice: lib_translate("Delete_file_successful_department")      
      end

    else

      department = Department.where("id = #{id}").first
      department.destroy
      log_history(Department, "Xóa", department.name , "Đã xóa khỏi hệ thống", @current_user.email)
      redirect_to departments_index_path(lang: session[:lang]) ,notice: lib_translate("Delete_successful_department")

    end

  end

  def check_user_org
    @oUser_id = params[:oUser_id] 
    @oUorg = Uorg.where(user_id: @oUser_id).pluck(:organization_id)
    if @oUorg.nil?
      render json: false
    else
      @organ_scode = Organization.where(id: @oUorg).pluck(:scode)
      render json: {organization_scode: @organ_scode}
    end 
  end 

  def departments_upload_mediafile
    file = params["file"]
    department_id = params["department_id"]
    # kiểm tra có file hay ko
    if !file.nil? && file !=""
      #upload file
      @id_mediafile =  upload_document(file)
      # update file ddocs
      @ddocs = Ddoc.new
      @ddocs.department_id = department_id
      @ddocs.note = @id_mediafile[:name]
      @ddocs.mediafile_id = @id_mediafile[:id]
      @ddocs.status = @id_mediafile[:status]
      @ddocs.save
      #send data to font end
      @department = Department.where(id: department_id).first
      @data = {relative_id:department_id,id:@ddocs.id ,file_id:@id_mediafile[:id], file_name:@id_mediafile[:name], file_owner: @id_mediafile[:owner],created_at:@ddocs.created_at}
      render json: @data
    else
      render json: "No file!"
    end
  end

  def details

    @tbdepartmenttypes = Tbdepartmenttype.all

    @organizations = Organization.all

    @alldep = Department.all
    id = params[:id]
    session[:id_detal_department] = id
    @department = Department.where("id = #{id}").first
    @oDocument = Ddoc.where("department_id = #{id}")

    @user = User.where.not(email:"admin@gmail.com")
    @Posjob = Positionjob.where("department_id = #{id}").pluck(:id)
    @Works = Work.where(positionjob_id: @Posjob ).pluck(:user_id)
    @users = User.where(id: @Works)

  end

  # Thêm chức năng cho đơn vị
  def add_function_into_department
    function_id = params[:function_id]
    function = Tfunction.where(id: function_id).first
    if !function.nil?
      # ClONE Tfunction stype FUNCTIONS
      dueties = Tfunction.where(parent: function.id)
      new_function = function.dup
      new_function.department_id = @oDepartment.id
      new_function.is_root = function.id
      new_function.scode = "#{function.scode}-CLONE-#{@oDepartment.id}"
      if new_function.save
      #   dueties = Tfunction.where(parent: function.id)
      #   tasks_by_function = Stask.where(tfunction_id: dueties.pluck(:id)).group_by(&:tfunction_id)
      #   # ClONE Tfunction stype DUETIES
      #   dueties.each do |duety|
      #     new_duety = duety.dup
      #     new_duety.parent = new_function.id
      #     new_duety.is_root = duety.id
      #     new_duety.department_id = @oDepartment.id
      #     new_duety.scode = "#{duety.scode}-CLONE"
      #     if new_duety.save
      #       # CLONE stasks of tfunctions stype DUETIES
      #       tasks = tasks_by_function[duety.id] || []
      #       tasks.each do |task|
      #         new_task = task.dup
      #         new_task.tfunction_id = new_duety.id
      #         new_task.is_root = task.id
      #         new_task.save
      #       end
      #     end
      #   end
        msg = "Thêm chức năng thành công"
      else
        msg = new_function.errors.full_messages.join(", ")
      end
    end
    redirect_to :back, notice: msg
  end
  # 
  def get_stasks_of_user
    user_id = params[:user_id]
    positionjob_id = params[:positionjob_id]
    # get stask in responsible table
    # stasks_in_pj = Work.joins(positionjob: {responsibles: :stask}).where(works: {user_id: user_id}).select("stasks.*")
    # get stask in work table
    # works = Work.includes(:stask).where(user_id: user_id)
    # stasks_in_pj = works.select { |w| w.positionjob_id.present? }
    # other_stasks = works.select { |w| w.positionjob_id.nil? }.map(&:stask)
    works = Work.where(user_id: user_id, positionjob_id: positionjob_id)

    # Lọc ra những stasks không có accesses
    stasks = Stask.where(id: works.pluck(:stask_id))
                  .left_joins(:accesses)
                  .where(accesses: { id: nil })

    duty_ids = stasks.pluck(:tfunction_id).uniq
    duties = Tfunction.where(id: duty_ids)
    function_ids = duties.pluck(:parent).uniq
    functions = Tfunction.where(id: function_ids)
  
    stask_datas = functions.map do |func|
      related_duties = duties.select { |d| d.parent.to_s == func.id.to_s }
    
      duties_data = related_duties.map do |duty|
        related_stasks = stasks.select { |s| s.tfunction_id == duty.id }
        next nil if related_stasks.empty?
    
        {
          duty_name: duty.name,
          stasks: related_stasks.as_json(only: [:id, :name])
        }
      end.compact
    
      next nil if duties_data.empty?
    
      {
        function_name: func.name,
        duties: duties_data
      }
    end.compact
    # group stasks
    gtasks = Gtask.where(id: works.pluck(:gtask_id)) 
    gtask_datas = gtasks.includes(:stasks).map do |gtask|
      # Lọc stasks trong gtask để chỉ lấy những stasks không có accesses
      filtered_stasks = gtask.stasks.left_joins(:accesses)
                                    .where(accesses: { id: nil })
      
      next nil if filtered_stasks.empty?
      {
        id: gtask.id,
        name: gtask.name,
        stasks: filtered_stasks.map do |stask|
          {
            id: stask.id,
            name: stask.name
          }
        end
      }
    end.compact
    # stasks without function
    stasks_without_duty = stasks.select{ |t| t.tfunction_id.nil? }
    render json: {
      stask_datas: stask_datas, 
      stask_ids: stasks.pluck(:id), 
      gtask_datas: gtask_datas, 
      gtask_ids: works.pluck(:gtask_id).compact,
      stasks_without_duty: stasks_without_duty,
    }
  end
  
  def get_stasks
    search = params[:search].to_s.strip
    duty_id = params[:duty_id].presence
    function_id = params[:function_id].presence

    functions = Tfunction.where(stype: 'FUNCTIONS', is_root: nil).order(created_at: :desc)
    duties = function_id ? Tfunction.where(stype: 'DUETIES', parent: function_id).order(created_at: :desc) : Tfunction.where(stype: 'DUETIES').order(created_at: :desc)    
    stasks_without_duty = []
    stasks_nested = build_nested_stasks(
      functions: functions,
      duties: duties,
      search: search,
      duty_id: duty_id,
      function_id: function_id
    )
    # Lọc gtasks để chỉ lấy những stasks không có accesses
    gtasks = Gtask.includes(stasks: :accesses)
    gtasks = Gtask.where("name LIKE ?", "%#{search}%") if search.present?
    gtask_data = gtasks.map do |gtask|
      # Lọc stasks không có accesses
      filtered_stasks = gtask.stasks.select { |stask| stask.accesses.empty? }
      
      next nil if filtered_stasks.empty?

      {
        id: gtask.id,
        name: gtask.name,
        stasks: filtered_stasks.map do |stask|
          {
            id: stask.id,
            name: stask.name
          }
        end
      }
    end.compact

    if function_id.nil? && duty_id.nil?
      # Lọc stasks without duty và không có accesses
      stasks_without_duty = Stask.where(tfunction_id: nil)
                                .left_joins(:accesses)
                                .where(accesses: { id: nil })
                                .order(created_at: :desc)
      stasks_without_duty = stasks_without_duty.where("name LIKE ?", "%#{search}%") if search.present?
    end
    respond_to do |format|
      format.js {
        render js: "getDatas(
          #{functions.as_json(only: [:id, :name]).to_json.html_safe},
          #{duties.as_json(only: [:id, :name, :parent]).to_json.html_safe},
          #{stasks_nested.to_json.html_safe},
          #{function_id.to_json},
          #{duty_id.to_json},
          #{gtask_data.to_json.html_safe},
          #{stasks_without_duty.to_json.html_safe}
        )"
      }
    end
  end

  def get_users
    search = params[:search]
    positionjob_id = params[:positionjob_id]
    users_exits = Work.select("users.id as user_id").joins(:user).where(positionjob_id:positionjob_id).distinct
    users = User.select("concat(users.last_name,' ', users.first_name) as name, users.id")
                .where("concat(users.last_name,' ', users.first_name) like :search OR users.sid like :search ",{search: "%#{search}%"})
                .where.not(id:users_exits.pluck(:user_id))
    
    render json: { items: users ,data:users_exits}
  end
  
  def build_nested_stasks(functions:, duties:, search: nil, duty_id: nil, function_id: nil)
    stasks_nested = []
  
    filtered_functions = function_id.present? ? functions.where(id: function_id) : functions
  
    filtered_functions.each do |func|
      func_duties = duties.select { |d| d.parent.to_s == func.id.to_s }
  
      # Nếu chọn duty_id thì chỉ lấy nhiệm vụ đó
      func_duties = func_duties.select { |d| d.id.to_s == duty_id.to_s } if duty_id.present?
  
      duties_data = func_duties.map do |duty|
        # Lọc stasks không có accesses
        tasks = Stask.where(tfunction_id: duty.id)
                    .left_joins(:accesses)
                    .where(accesses: { id: nil })
                    .order(created_at: :desc)
        tasks = tasks.where("name LIKE ?", "%#{search}%") if search.present?
        next if tasks.empty?  # Bỏ qua nếu không có công việc phù hợp
        {
          duty_name: duty.name,
          duty_id: duty.id,
          stasks: tasks.as_json(only: [:id, :name])
        }
      end.compact
  
      if duties_data.any?
        stasks_nested << {
          function_name: func.name,
          function_id: func.id,
          duties: duties_data
        }
      end
    end
  
    stasks_nested
  end

  def get_gtasks
    # Lọc gtasks để chỉ lấy những stasks không có accesses
    gtask_data = Gtask.includes(stasks: :accesses).map do |gtask|
      # Lọc stasks không có accesses
      filtered_stasks = gtask.stasks.select { |stask| stask.accesses.empty? }
      
      next nil if filtered_stasks.empty?

      {
        id: gtask.id,
        name: gtask.name,
        stasks: filtered_stasks.map do |stask|
          {
            id: stask.id,
            name: stask.name
          }
        end
      }
    end.compact

    respond_to do |format|
      format.js { render js: "renderGtasks(#{gtask_data.to_json.html_safe})"}
    end
  end
  def add_stasks_into_user
    user_id = params[:user_id]
    positionjob_id = params[:positionjob_id]
    department_id = params[:department_id]
    stask_ids = params[:stask_ids].split(",")
    gtask_ids = params[:gtask_ids].split(",")
    other_stasks = params[:other_statsks] || []

    position = Positionjob.where(id: positionjob_id).first
    if !position.nil?
      # remove all stasks and gtasks
      Work.where(positionjob_id: positionjob_id, user_id: user_id).destroy_all
      # Create work if 2 array nil
      if stask_ids.length < 1 && gtask_ids.length < 1
        Work.create({
          positionjob_id: position.id,
          user_id: user_id
        })
      end
      # add stask to positionjob of user
      if stask_ids.length > 0
        # # add into works table
        stask_ids.each do |tid|
          Work.create({
            stask_id: tid,
            positionjob_id: position.id,
            user_id: user_id
          })
        end
      end
      # add group tasks
      if gtask_ids.length > 0
        gtask_ids.each do |gid|
          Work.create({
            gtask_id: gid,
            positionjob_id: position.id,
            user_id: user_id
          })
        end
      end
      updateUsersPermissionChange(user_id)
    end
    redirect_to :back, notice: "Cập nhật công việc thành công"
  end

  def add_user_positionjob
    user_ids = params[:user_ids] || []
    positionjob_id = params[:positionjob_id]
    b_success = true
    ActiveRecord::Base.transaction do
      begin
        user_ids.each do |user_id|
          Work.create({user_id: user_id, positionjob_id: positionjob_id})
        end
      rescue => e
        b_success = false
        raise ActiveRecord::Rollback
      end
    end

    respond_to do |format|
      format.js { render js: "OnAddUserPositionjob(#{b_success.to_json.html_safe},'#{positionjob_id}',#{user_ids.to_json.html_safe})"}
    end

  end

  def set_department
    @department_id = params[:department_id]
    @oDepartment = Department.find_by(id: @department_id)
  end

# Vu: Streams
  def streams
    @departments = Department.all
    @streams = Stream.select(:name, :id)
    @formsList = Form.all
  end

  def streams_update

    stream = nil
    @curr_id = 0
    diagram = nil

    begin
      diagram = JSON.parse(params[:data])

      if diagram.nil?
        raise
      end

      if !diagram['id'].nil?
        stream = Stream.where(id: diagram['id']).first
      else
        stream = Stream.new
      end

      stream.name = diagram['name']
      stream.scode = diagram['scode']
      stream.note = diagram['note']
      stream.status = diagram['status']
      stream.save

      # update nodes
      Node.where(stream_id: stream.id).destroy_all
      diagram['nodes'].each do |node|
        node = Node.create(node.merge({ stream_id: stream.id }))
        node.stream_id = stream.id
      end

      # update connects
      Connect.where(stream_id: stream.id).destroy_all
      diagram['connects'].each do |connect|
        Connect.create(connect.merge({ stream_id: stream.id }))
      end


    curr_id = stream.id
    rescue Exception => e
      raise
    end

    streams = Stream.select(:name, :id)

    respond_to do |format|
      format.js { render js: "onSaveSuccess(#{streams.to_json.html_safe},#{curr_id});"}
    end

  end

  def streams_edit
    id = params[:stream_id].to_i
    stream = Stream.where(id: id).first
    nodes = Node.joins(:department).select('nodes.department_id,nodes.color,nodes.px,nodes.py,nodes.height,nodes.width,departments.name,nodes.nfirst').where({stream_id: id})
    connects = Connect.where({stream_id: id})
    respond_to do |format|
      format.js {render js: "loadDiagramData(#{stream.to_json.html_safe},#{nodes.to_json.html_safe},#{connects.to_json.html_safe});"}
    end
  end

  def streams_delete
    id = params[:stream_id].to_i
    Node.where(stream_id: id).destroy_all
    Connect.where(stream_id: id).destroy_all
    Stream.where(id: id).destroy_all
    streams = Stream.select(:name, :id)

    respond_to do |format|
      format.js {render js: "loadDiagramList(#{streams.to_json.html_safe});toggleLoading(false,'button-delete');"}
    end
  end
  # Vu: Streams end

end
