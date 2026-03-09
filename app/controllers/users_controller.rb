class UsersController < ApplicationController
  before_action :authorize
  include HolidayShared
  before_action -> { prepare_holiday_data(params[:id])}, only: [:details]
  before_action -> { prepare_holiday_data(params[:uid].nil? ? session[:user_id] : params[:uid] )}, only: [:profile]

  # GET /users
  # GET /users.json

# CONTROLLER DAT CODE
  def index
    @user = User.new
    @userLastid = User.ids.last
    @userOrg = Uorg.where(user_id: session[:user_id]).first
    if !@userOrg.nil?
      @Orgid =  @userOrg.organization_id
    end

    @organizations = Organization.where.not(status: 'INACTIVE')

    search = params[:search] || ''
    if is_access(session["user_id"], "BMTU-BUH","READ")
      sql =  User.where("concat(users.last_name, ' ', users.first_name) LIKE ? OR users.email LIKE ? OR users.sid = ?", "%#{search}%","%#{search}%", "#{search}")
    else
      sql =  User.joins(:uorgs, :organizations).where("users.email NOT LIKE ?", "%adm%").where('organizations.id = ?', @Orgid).where("concat(users.last_name, ' ', users.first_name) LIKE ? OR users.email LIKE ? OR users.sid = ?", "%#{search}%","%#{search}%", "#{search}")
    end
    @users = pagination_limit_offset(sql, 25)
  end

  def show_select
    academicranks = Academicrank.where.not(status: 'INACTIVE')
    ethnics = Ethnic.where.not(status: 'INACTIVE')
    educations = Education.where.not(status: 'INACTIVE')
    religions = Religion.where.not(status: 'INACTIVE')
    nationalitys = Nationality.where.not(status: 'INACTIVE')
    tbusertypes = Tbusertype.where.not(status: 'INACTIVE')
    tbuserstatuss = Tbuserstatus.where.not(status: 'INACTIVE')
    tbhospitals = Tbhospital.where.not(status: 'INACTIVE')

    render json: { academicrank: academicranks, ethnic: ethnics, education: educations, religion: religions, nationality: nationalitys,
     tbusertype: tbusertypes, tbuserstatus: tbuserstatuss, tbhospital: tbhospitals
    }
  end

  def profile
    id = params[:uid].nil? ? session[:user_id] : params[:uid]
    id_file_holiday = session[:id_holiday_user]
    id_file_contract = session[:id_contract_user]
    id_file_identity = session[:id_identity_user]
    id_file_address = session[:id_address_user]
    @detailId = id

    session[:save_tab_details] = params[:page]

    session[:id_detal_user] = id
    @user = User.where(id: id).first
    @userNew = User.new
    @users = User.where.not(email: 'admin@gmail.com')

    mediafile_id = Doc.where(user_id: id).pluck(:mediafile_id).first
    mediafile = Mediafile.find_by(id: mediafile_id)
    @userImage = mediafile&.file_name.present? ? "#{request.base_url}/mdata/hrm/#{mediafile.file_name}" : "#{request.base_url}#{view_context.image_path('no_avatar.jpg')}"

    # Singnature
    @oSignature = Signature.joins(:mediafile).select('signatures.*, mediafiles.file_name as url').where('signatures.user_id = ?', @user.id).order(created_at: :desc)

    # Holiday: Hai
    @holiday = Holiday.new
    @holidays = Holiday.where("user_id = #{id}").order("created_at DESC")
    @departments = Department.all.order("created_at DESC")
    # @holdocs = Holdoc.all
    # Holiday: end

    # Contract
    @contract = Contract.new
    contracts = Contract.where("user_id = #{id}").order("created_at DESC")
    @contracts_data = []
    contracts.each do |contract|
      # check template contract valid
      temp_valid = true
      # data exist
      tmpcontract =  Tmpcontract.where(name: contract.name).first
      if !tmpcontract.nil?
        temp_valid = !tmpcontract.scontent.empty?
      else
        temp_valid = false
      end

      @contracts_data.push({
        id: contract.id,
        user_id: contract.user_id,
        name: contract.name,
        issued_date: contract.issued_date&.strftime('%d/%m/%Y'),
        issued_by: contract.issued_by,
        issued_place: contract.issued_place,
        status: contract.status,
        base_salary: contract.base_salary,
        dtfrom: contract.dtfrom&.strftime('%d/%m/%Y'),
        dtto: contract.dtto&.strftime('%d/%m/%Y'),
        note: contract.note,
        temp_valid: temp_valid
      });
    end
    # Address
    @address = Address.new
    @addresses = Address.where("user_id = #{id}")
    # Identity
    @identity = Identity.new
    @identitys = Identity.where("user_id = #{id}")
    # end
    # Review: Dat
    @review = Review.new
    @reviewEachUser = Review.where("user_id = #{id}").order("created_at DESC")
    # Review: end

    # work: Vu
    @works = Work.where(user_id: id).where.not(positionjob_id: nil,stask_id: nil)
    @positionjobs = Positionjob.where(department_id: nil).all.order('name DESC')
    @stasks = Stask.all.order('name DESC')
    @user_work_tasks = []
    @user_work_positionjobs = []
    @works.each do |work|
      if !work.positionjob_id.nil?
        @user_work_positionjobs.push(work.positionjob_id)
      elsif !work.stask_id.nil?
        @user_work_tasks.push(work.stask_id)
      end
    end
    # work: End

    # Benefit: Vu
    benefit_page = params[:benefit_page].to_i || 1
    benefit_page = 1 if benefit_page <= 0
    @benefit = Benefit.new
        # Thái
    allbenefits = Benefit.where(user_id: id , syear: ((Time.zone.now.year.to_i - 1)..(Time.zone.now.year.to_i+3)) , btype:"MONEY", status: "ACTIVE")
    @add_benefit = Benefit.new

    @list_benefit = []
    allbenefits.each do |benefit|
      if !benefit.name.nil?
        index = @list_benefit.find_index{ |item| item[:name] == benefit.name }
        if !index.nil?
          @list_benefit[index][benefit.syear.to_s] = {
            syear: benefit.syear,
            amount: benefit.amount,
          }
        else
          @list_benefit.push({
            name: benefit.name,
            "#{benefit.syear}": {
              syear: benefit.syear,
              amount: benefit.amount,
            }
          })
        end
      end
    end

    benefit_other=Benefit.where(syear: ((Time.zone.now.year.to_i - 1)..(Time.zone.now.year.to_i+3)), user_id: id, btype:"OTHER" ,status:"ACTIVE")

    @list_benefit_other = []

    benefit_other.each do |benefit_other|
      if !benefit_other.name.nil?
        index = @list_benefit_other.find_index{ |item| item[:name] == benefit_other.name }
        if !index.nil?
          @list_benefit_other[index][benefit_other.syear.to_s] = {
            syear: benefit_other.syear,
            amount: benefit_other.amount,
          }
        else
          @list_benefit_other.push({
            name: benefit_other.name,
            "#{benefit_other.syear}": {
              syear: benefit_other.syear,
              amount: benefit_other.amount,
            }
          })
        end
      end
    end
    # Thai end
    # Benefit: end

    #Archive: Thai
    @archive = Archive.new
    @archives = Archive.where("user_id = #{id}").order("created_at DESC")
    @organization = Organization.where(status: 'ACTIVE')

    # Tbarchivetype
    @tbarchivetype = Tbarchivetype.where(status: "ACTIVE")
    # Tbarchivelevel
    @tbarchivelevel = Tbarchivelevel.where(status: "ACTIVE")
    # Archive: end

    # Apply: Huy
    @apply = Apply.where("user_id = #{id}").order("created_at DESC")
    @bank = Bank.where("user_id = #{id}").order("created_at DESC")
    # Apply: end

    # Social: Huy
    @socials = Social.where("user_id = #{id}").order("created_at DESC")
    @social = Social.new
    # Social: end

    # Work_history
    @work_history= Company.new
    # Education
    @school= School.new

    #Relative
    @relative= Relative.new


    # Bank
    @banks = Bank.new


    # Apply: H-Anh

    # Apply: end
    @works_stask = Work.where("user_id = #{id} AND positionjob_id IS NOT NULL")

    # nationality
    @nationalitys = Nationality.where.not(status: 'INACTIVE')
    @religions = Religion.where.not(status: 'INACTIVE')
    @tbhospitals = Tbhospital.where.not(status: 'INACTIVE')
    @educations = Education.where.not(status: 'INACTIVE')
    @ethnics = Ethnic.where.not(status: 'INACTIVE')
    @academicranks = Academicrank.where.not(status: 'INACTIVE')
    @organizations = Organization.where.not(status: 'INACTIVE')
    @contracttypes = Contracttype.where.not(status: 'INACTIVE')
    @contracttimes = Contracttime.where.not(status: 'INACTIVE')
    @uorgs = Uorg.where(user_id: id)

    # tbuserstatuss - tbusertype : Hai code 27/12
    @tbusertypes = Tbusertype.where.not(status: 'INACTIVE')
    @tbuserstatuss = Tbuserstatus.where.not(status: 'INACTIVE')

    # Hai code 28/12/2022
    @archiveU = Archive.where(user_id: id)
    @countarchive = @archiveU.count

    # Huy
    @payslips= Payslip.where(user_id: id,  syear: Time.zone.now.year).sort_by { |a| (a.smonth.to_i) }
    @data_Basic_Salary = []
    @data_Additional_Income = []
    @data_Deductions = []
    @data_Net = []
    Payslip.where(user_id: id, syear: '2023').sort_by { |a| (a.smonth.to_i) }.each do |payslip|
      @data_Basic_Salary.push(payslip.base_salary ? payslip.base_salary : 0)
      @data_Additional_Income.push(payslip.extra_income ? payslip.extra_income : 0)
      @data_Deductions.push(payslip.dedution ? payslip.dedution : 0)
      @data_Net.push(payslip.snet ? payslip.snet : 0)
    end
    @access = Access.all
    @permission_user = get_user_permission(id, 26)

    # Build cong viec nhan su controller
    # @author: H-Anh
    # @date: 16/02/2023
    #
    @mailUser =  @user.email
    work =  Work.where(user_id: id).first
    if !work.nil?
      depart_id =  Positionjob.where(id: work.positionjob_id).first
      if !depart_id.nil?
        @mailLeader = Department.where(id: depart_id.department_id ).first
        @listWorkleader = Mandocdhandle.select("mandocdhandles.*, max_mandocdhandles.max_id")
                        .from("mandocdhandles").where(department_id: depart_id.department_id)
                        .joins("LEFT JOIN (SELECT mandoc_id, MAX(id) as max_id FROM mandocdhandles GROUP BY mandoc_id) as max_mandocdhandles ON mandocdhandles.id = max_mandocdhandles.max_id")
                        .order("mandocdhandles.id DESC")
        @listWork = Mandocuhandle.select("mandocuhandles.*, max_mandocuhandles.max_id")
                            .from("mandocuhandles").where(user_id: id)
                            .joins("LEFT JOIN (SELECT mandocdhandle_id, MAX(id) as max_id FROM mandocuhandles GROUP BY mandocdhandle_id) as max_mandocuhandles ON mandocuhandles.id = max_mandocuhandles.max_id")
                            .order("mandocuhandles.id DESC")
      end
    end
  end

  def details
    id = params[:id]
    @detailId = id

    session[:save_tab_details] = params[:page]

    session[:id_detal_user] = id
    @user = User.where(id: id).first
    @userImage =
    @userNew = User.new
    @users = User.where.not(email: 'admin@gmail.com')
    @oSignature = Signature.joins(:mediafile).select('signatures.*, mediafiles.file_name as url').where('signatures.user_id = ?', @user.id).order(created_at: :desc)

    mediafile_id = Doc.where(user_id: id).pluck(:mediafile_id).first
    mediafile = Mediafile.find_by(id: mediafile_id)
    @userImage = mediafile&.file_name.present? ? "#{request.base_url}/mdata/hrm/#{mediafile.file_name}" : "#{request.base_url}#{view_context.image_path('no_avatar.jpg')}"

    # Build cong viec nhan su controller
    # @author: H-Anh
    # @date: 16/02/2023
    #
    @mailUser =  @user.email
    work =  Work.where(user_id: id).first
    if !work.nil?
      depart_id =  Positionjob.where(id: work.positionjob_id).first
      if !depart_id.nil?
        @mailLeader = Department.where(id: depart_id.department_id ).first
        if !@mailLeader.nil?
          @listWorkleader = Mandocdhandle.select("mandocdhandles.*, max_mandocdhandles.max_id")
                        .from("mandocdhandles").where(department_id: depart_id.department_id)
                        .joins("LEFT JOIN (SELECT mandoc_id, MAX(id) as max_id FROM mandocdhandles GROUP BY mandoc_id) as max_mandocdhandles ON mandocdhandles.id = max_mandocdhandles.max_id")
                        .order("mandocdhandles.id DESC")
          @listWork = Mandocuhandle.select("mandocuhandles.*, max_mandocuhandles.max_id")
                            .from("mandocuhandles").where(user_id: id)
                            .joins("LEFT JOIN (SELECT mandocdhandle_id, MAX(id) as max_id FROM mandocuhandles GROUP BY mandocdhandle_id) as max_mandocuhandles ON mandocuhandles.id = max_mandocuhandles.max_id")
                            .order("mandocuhandles.id DESC")
        end
      end
    end
    #
    # end

    # Holiday: Hai
    @holiday = Holiday.new
    @holidays = Holiday.where("user_id = #{id}").order("created_at DESC")
    @departments = Department.all.order("created_at DESC")
    # Holiday: end

    # Contract
    @contract = Contract.new
    contracts = Contract.where("user_id = #{id}").order("dtfrom DESC")
    @contracts_data = []
    contracts.each do |contract|
      # check template contract valid
      temp_valid = true
      # data exist
      tmpcontract =  Tmpcontract.where(name: contract.name).first
      if !tmpcontract.nil?
        temp_valid = !tmpcontract.scontent.empty?
      else
        temp_valid = false
      end

      @contracts_data.push({
        id: contract.id,
        user_id: contract.user_id,
        name: contract.name,
        issued_date: contract.issued_date&.strftime('%d/%m/%Y'),
        issued_by: contract.issued_by,
        issued_place: contract.issued_place,
        status: contract.status,
        base_salary: contract.base_salary,
        dtfrom: contract.dtfrom&.strftime('%d/%m/%Y'),
        dtto: contract.dtto&.strftime('%d/%m/%Y'),
        note: contract.note,
        temp_valid: temp_valid
      });
    end

    # Address
    @address = Address.new
    @addresses = Address.where("user_id = #{id}")
    # Identity
    @identity = Identity.new
    @identitys = Identity.where("user_id = #{id}")
    # end
    # Review: Dat
    @review = Review.new
    @reviewEachUser = Review.where("user_id = #{id}").order("created_at DESC")
    # Review: end

    # Benefit: Vu
    benefit_page = params[:benefit_page].to_i || 1
    benefit_page = 1 if benefit_page <= 0
    @benefit = Benefit.new

    # Thái
    allbenefits = Benefit.where(user_id: id , syear: ((Time.zone.now.year.to_i - 1)..(Time.zone.now.year.to_i+3)) , btype:"MONEY", status: "ACTIVE")
    @add_benefit = Benefit.new

    @list_benefit = []
    allbenefits.each do |benefit|
      if !benefit.name.nil?
        index = @list_benefit.find_index{ |item| item[:name] == benefit.name }
        if !index.nil?
          @list_benefit[index][benefit.syear.to_s] = {
            syear: benefit.syear,
            amount: benefit.amount,
          }
        else
          @list_benefit.push({
            name: benefit.name,
            "#{benefit.syear}": {
              syear: benefit.syear,
              amount: benefit.amount,
            }
          })
        end
      end
    end

    benefit_other=Benefit.where(syear: ((Time.zone.now.year.to_i - 1)..(Time.zone.now.year.to_i+3)), user_id: id, btype:"OTHER" ,status:"ACTIVE")

    @list_benefit_other = []

    benefit_other.each do |benefit_other|
      if !benefit_other.name.nil?
        index = @list_benefit_other.find_index{ |item| item[:name] == benefit_other.name }
        if !index.nil?
          @list_benefit_other[index][benefit_other.syear.to_s] = {
            syear: benefit_other.syear,
            amount: benefit_other.amount,
          }
        else
          @list_benefit_other.push({
            name: benefit_other.name,
            "#{benefit_other.syear}": {
              syear: benefit_other.syear,
              amount: benefit_other.amount,
            }
          })
        end
      end
    end
    # Thai end
    # Benefit: end

    #Archive: Thai
    @archive = Archive.new
    @archives = Archive.where("user_id = #{id}").order("created_at DESC")
    @organization = Organization.where(status: 'ACTIVE')

    # Tbarchivetype
    @tbarchivetype = Tbarchivetype.where(status: "ACTIVE")
    # Tbarchivelevel
    @tbarchivelevel = Tbarchivelevel.where(status: "ACTIVE")
    # Archive: end

    # Apply: Huy
    @apply = Apply.where("user_id = #{id}").order("created_at DESC") #Đạt code
    @bank = Bank.where("user_id = #{id}").order("created_at DESC") #Đồng code
    # Apply: end

    # Social: Huy
    @socials = Social.where("user_id = #{id}").order("created_at DESC")
    @social = Social.new
    # Social: end


    # Work_history
    @work_history= Company.new

    # Education
    @school= School.new

    #Relative
    @relative= Relative.new


    # Bank
    @banks = Bank.new


    # Apply: H-Anh

    # Apply: end
    @works_stask = Work.where("user_id = #{id} AND positionjob_id IS NOT NULL")

    # nationality
    @nationalitys = Nationality.where.not(status: 'INACTIVE')
    @religions = Religion.where.not(status: 'INACTIVE')
    @tbhospitals = Tbhospital.where.not(status: 'INACTIVE')
    @educations = Education.where.not(status: 'INACTIVE')
    @ethnics = Ethnic.where.not(status: 'INACTIVE')
    @academicranks = Academicrank.where.not(status: 'INACTIVE')
    @organizations = Organization.where.not(status: 'INACTIVE')
    @contracttypes = Contracttype.where.not(status: 'INACTIVE')
    @contracttimes = Contracttime.where.not(status: 'INACTIVE')
    @uorgs = Uorg.where(user_id: id)

    # tbuserstatuss - tbusertype : Hai code 27/12
    @tbusertypes = Tbusertype.where.not(status: 'INACTIVE')
    @tbuserstatuss = Tbuserstatus.where.not(status: 'INACTIVE')

    # Hai code 28/12/2022
    @archiveU = Archive.where(user_id: id)
    @countarchive = Archive.where(user_id: id).count

    # Huy
    @payslips= Payslip.where(user_id: id,  syear: Time.zone.now.year).sort_by { |a| (a.smonth.to_i) }
    @data_Basic_Salary = []
    @data_Additional_Income = []
    @data_Deductions = []
    @data_Net = []
      Payslip.where(user_id: id, syear: Time.zone.now.year).sort_by { |a| (a.smonth.to_i) }.each do |payslip|
        @data_Basic_Salary.push(payslip.base_salary ? payslip.base_salary : 0)
        @data_Additional_Income.push(payslip.extra_income ? payslip.extra_income : 0)
        @data_Deductions.push(payslip.dedution ? payslip.dedution : 0)
        @data_Net.push(payslip.snet ? payslip.snet : 0)
      end
  end

  def export_users
    #params
    datas = []
    session_export_user = session[:organization]
    # check export giua cac don vi
    # Dong 17/07/2024
    if session_export_user.present?
      if session_export_user.length > 1
        oUsers = User.all
      else
        oUsers = User.joins(uorgs: :organization).select("users.*, organizations.scode AS organization_scode").where(organizations: { scode: session_export_user })
      end
    else
      oUsers = User.none
    end

    oUsers.each_with_index do |user, index|
      name_positionjob = ""
      name_department = ""
      works = user.works.where("positionjob_id IS NOT NULL")
      works.each do |work|
        if !work&.positionjob.nil? && !work&.positionjob&.department.nil?
          if work&.positionjob&.department&.is_virtual.nil? && work&.positionjob&.department&.parents.nil?
            name_department = work&.positionjob&.department&.name
            name_positionjob = work&.positionjob&.name
          end
        end
      end
      oWork = Work.where(user_id: user.id).where.not(positionjob_id: nil).first
      if oWork.present?
        oPositionjob =  Positionjob.where(id: oWork&.positionjob_id).first
        if oPositionjob.present?
          oDepartment = Department.where(id: oPositionjob.department_id).first
          if oDepartment.present?
            name_positionjob = oPositionjob&.name
            name_department = oDepartment&.name
          end
        end
      end
      datas.push([
        index + 1,
        user.first_name,
        user.last_name,
        user.birthday&.strftime("%d/%m/%Y"),
        user.place_of_birth,
        user.m_place_of_birth,
        user.sid,
        user.email,
        user.email1,
        user.benefit_type,
        user.gender == "0" ? "Nam" : user.gender == "1" ? "Nữ" : user.gender == "2" ? "Khác" : "",
        user&.organizations&.pluck(:scode)&.join(", "),
        "'#{user.phone}",
        "'#{user.mobile}",
        user.staff_status,
        user.staff_type,
        lib_translate(user.stype),
        user.religion,
        user.nationality,
        user.ethnic,
        user.education,
        user.academic_rank,
        lib_translate(user.marriage),
        user.insurance_no,
        user.taxid,
        name_department,
        name_positionjob,
        user.note,
    ])
    end

    # Tạo excel package
    workbook = export_excel(datas)
    file_name = "Danh sách nhân sự.xlsx"
    ## Gửi data để tải xuống
    send_data   workbook.to_stream.read,
                filename: file_name,
                type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                disposition: 'attachment'
  end

  def export_excel(datas)
    package = Axlsx::Package.new
    workbook = package.workbook
    sheet = workbook.add_worksheet(name: 'Sheet1')
    cols_left_style = workbook.styles.add_style(font_name:"Arial",bg_color: "",border: { style: :thin, color: '00000000'},alignment: {horizontal: :left ,vertical: :center},sz: 10)
    cols_center_style = workbook.styles.add_style(font_name:"Arial",bg_color: "",border: { style: :thin, color: '00000000'},alignment: {horizontal: :center ,vertical: :center},sz: 10)
    custom_header_export_excel(workbook, sheet)
    datas.each_with_index do |row|
        added_row = sheet.add_row(row, style:cols_center_style)
        row_index = added_row.row_index
        sheet.rows[row_index].cells[1].style = cols_left_style
        sheet.rows[row_index].cells[2].style = cols_left_style
        sheet.rows[row_index].cells[4].style = cols_left_style
        sheet.rows[row_index].cells[5].style = cols_left_style
        sheet.rows[row_index].cells[6].style = cols_left_style
        sheet.rows[row_index].cells[7].style = cols_left_style
        sheet.rows[row_index].cells[8].style = cols_left_style
        sheet.rows[row_index].cells[19].style = cols_left_style
        sheet.rows[row_index].cells[20].style = cols_left_style
    end
    sheet.column_widths 7,10,20,15,20,20,20,25,25,20,15,20,20,20,20,20,20,15,15,15,20,15,20,20,20,30,30,30
    package
  end

  def custom_header_export_excel(workbook, sheet)
    # Style
    default_font = workbook.styles.add_style(font_name:"Arial",sz: 10)
    org_name_style = workbook.styles.add_style(font_name:"Arial",sz: 10, alignment: {horizontal: :center ,vertical: :center})
    department_name_style = workbook.styles.add_style(font_name:"Arial",sz: 10, alignment: {horizontal: :center ,vertical: :center}, b: true)
    horizontal_center = workbook.styles.add_style(font_name:"Arial",alignment: {horizontal: :center ,vertical: :center},sz: 16, b: true)
    title_css = workbook.styles.add_style(font_name:"Arial",border: { style: :thin, color: '00000000'},alignment: {horizontal: :center ,vertical: :center},sz: 10, b: true)
    cols_left_style = workbook.styles.add_style(font_name:"Arial",bg_color: "",fg_color: '305496',border: { style: :thin, color: '00000000'},alignment: {horizontal: :left ,vertical: :center},sz: 10, b: true)
    cols_center_style = workbook.styles.add_style(font_name:"Arial",bg_color: "",fg_color: '305496',border: { style: :thin, color: '00000000'},alignment: {horizontal: :center ,vertical: :center},sz: 10, b: true)
    b = workbook.styles.add_style(font_name:"Arial",alignment: {horizontal: :left ,vertical: :center},sz: 10, b: true)

    # Tên bảng
    sheet.add_row(["DANH SÁCH NHÂN SỰ"],height:30, style:horizontal_center)
    sheet.merge_cells("A1:S1")
    sheet.add_row()
    added_row = sheet.add_row(["STT","Tên","Họ tên đệm","Ngày sinh","Quê quán","Nơi sinh", "Mã nhân sự", "Email", "Email khác", "Loại phúc lợi", "Giới tính", "Đơn vị lớn", "Số điện thoại", "Di động", "Tình trạng nhân sự", "Loại nhân sự", "Vị trí (Nhân sự/Ứng viên)", "Tôn giáo", "Quốc tịch", "Dân tộc", "Trình độ học vấn", "Học vị", "Tình trạng hôn nhân", "Mã số BHYT", "Mã số thuế","Phòng ban","Vị trí CV", "Ghi chú"],height:22,style:cols_center_style)
    row_index = added_row.row_index
    sheet.rows[row_index].cells[1].style = cols_left_style
    sheet.rows[row_index].cells[2].style = cols_left_style
    sheet.rows[row_index].cells[4].style = cols_left_style
    sheet.rows[row_index].cells[5].style = cols_left_style
    sheet.rows[row_index].cells[6].style = cols_left_style
    sheet.rows[row_index].cells[7].style = cols_left_style
    sheet.rows[row_index].cells[8].style = cols_left_style
    sheet.rows[row_index].cells[19].style = cols_left_style
    sheet.rows[row_index].cells[20].style = cols_left_style
  end

  def social_update
    id = params[:social_add_id]
    uid = params[:user_id]
    name = params[:social_add_name]
    slink = params[:slink_add]
    note = params[:note_add_social].gsub(/\s+/, " ").strip
    strStatus = params[:social_add_status]
    if id == ''
      @social = Social.new
      @social.user_id = uid
      @social.name = name
      @social.slink = slink
      @social.note = note
      @social.status = strStatus
      @social.save
    else
      @social = Social.where("id = #{id}").first
      @social.update(
        {
          name: name,
          slink: slink,
          note: note,
          status: strStatus
        }
      )
      #Save updated  history (Đạt 10/01/2023)
      change_column_value = @social.previous_changes
      change_column_name = @social.previous_changes.keys
      if change_column_name  != ""
          for changed_column in change_column_name do
              if changed_column != "updated_at"
                  fvalue = change_column_value[changed_column][0]
                  tvalue = change_column_value[changed_column][1]


              log_history(Social, changed_column, fvalue ,tvalue, @current_user.email)

              end
          end
      end
      #end Save updated  history
    end
    redirect_to user_details_path(id: session[:id_detal_user] , lang: session[:lang]) , notice: lib_translate("Successfully")
  end

  def social_del
      id = params[:id]
      @social = Social.where("id = #{id}").first
      @social.destroy
      log_history(Social, "Xóa: #{@social.user.last_name} #{@social.user.first_name}",  "#{@social.name}" , "Đã xóa khỏi hệ thống", @current_user.email)
      redirect_to user_details_path(id: session[:id_detal_user] , lang: session[:lang]) , notice: lib_translate("Successfully")
  end

  def adoc_upload_mediafile
    id = params[:id]
    @apply = Apply.where(user_id: id).first
    file = params["file"]
    cvs_id = @apply.id
    # kiểm tra có file hay ko
    if !file.nil? && file !=""
      #upload file
      @id_mediafile =  upload_document(file)
      # update file idendoc
      @adoc = Adoc.new
      @adoc.apply_id = cvs_id
      @adoc.note = @id_mediafile[:name]
      @adoc.mediafile_id = @id_mediafile[:id]
      @adoc.status = @id_mediafile[:status]
      @adoc.save
      #send data to font end
      @data = {apply_id:cvs_id,id: @adoc.id ,file_id:@id_mediafile[:id], file_name:@id_mediafile[:name], created_at:@adoc[:created_at].strftime("%d/%m/%Y"), file_owner: @id_mediafile[:owner]}
      render json: @data
    else
      render json: "No file!"
    endder json: "No file!"
    end
  end

  def adoc_del
    id = params[:aid]
    @adoc = Adoc.where(id: id).first
    @id_mediafile = @adoc.mediafile_id
    @adoc.destroy
    delete_mediadile(@id_mediafile)
    redirect_to user_details_path(id: session[:id_detal_user] , lang: session[:lang]) , notice: lib_translate("delete_message")
  end

  def update
    id = params[:user_id]
    organization_user = params[:organization_user]
    typeupdate = params[:type_upadte]
    update_tax_code = params[:update_tax_code]
    if id == ""
      id = params[:user_id]
      strFirstname= params[:user_first_name_add].capitalize.strip;
      strLastname= params[:user_last_name_add].mb_chars.titleize.strip;
      sid = params[:user_sid_add].upcase
      strUsername = params[:user_username_add].strip
      strEmail = params[:user_email_add].strip
      strPassword = params[:user_password_add].strip
      strGender = params[:user_gender_add].strip
      strNationality = params[:user_nationality_add]
      strEthnic = params[:user_ethnic_add]
      strReligion = params[:user_religion_add]
      strMarriage = params[:user_Marriage_add].strip
      strinsurance_No = params[:user_insurance_No_add].strip
      strEducation = params[:user_education_add]
      strAcademic_rank = params[:user_academic_add]
      strStatus = params[:user_status_add].strip
      strStype = params[:user_stype_add].strip
      strNote = params[:user_note_add].gsub(/\s+/, " ").strip
      strBirthday = params[:user_birthday_add].strip
      strPlaceOfBirth = params[:user_place_of_birth_add].strip
      strMPlaceOfBirth = params[:user_m_place_of_birth_add].strip
      strOtherEmail = params[:user_email_2_add].strip
      strPhone = params[:user_phone_add].strip
      strMobile = params[:user_mobile_add].strip
      strTaxId = params[:user_taxid_add].strip
      strIsuranceplace = params[:user_insurance_placed_add].strip
      # Hai code 27/12/2022
      strStaffType = params[:user_tbusertype_add]
      strStaffStatus = params[:user_tbuserstatus_add]
      strBenefittype = params[:user_benefit_type_add]
      strTwoFA = params[:twofa]
      twofa_exam = params[:twofa_exam]
      ignore_attend = params[:ignore_attend]
      # end Hai code
      termination_date = params[:termination_date]


      @user = User.new
      @user.sid = sid
      @user.first_name = strFirstname
      @user.last_name = strLastname
      @user.username = strUsername
      @user.email = strEmail
      @user.password_digest =  Digest::MD5.hexdigest(strPassword)
      @user.gender = strGender
      @user.nationality = strNationality
      @user.ethnic = strEthnic
      @user.religion = strReligion
      @user.marriage = strMarriage
      @user.insurance_no = strinsurance_No
      @user.education = strEducation
      @user.academic_rank = strAcademic_rank
      @user.status = strStatus
      @user.stype = strStype
      @user.note = strNote
      @user.birthday = strBirthday
      @user.taxid = strTaxId
      @user.insurance_reg_place = strIsuranceplace
      @user.place_of_birth = strPlaceOfBirth
      @user.m_place_of_birth = strMPlaceOfBirth
      @user.email1 = strOtherEmail
      @user.phone = strPhone
      @user.mobile = strMobile
      # Hai code 27/12/2022
      @user.staff_type = strStaffType
      @user.staff_status = strStaffStatus
      @user.benefit_type = strBenefittype
      @user.termination_date = termination_date
      @user.twofa = strTwoFA == "on" ? "YES" : "NO"
      @user.twofa_exam = twofa_exam == "on" ? "YES" : "NO"
      @user.ignore_attend = ignore_attend == "TRUE" ? "TRUE" : "FALSE"
      # end Hai code
      @user.save

      @apply = Apply.new
      @apply.user_id = @user.id
      @apply.name = strLastname + ' ' + strFirstname
      @issued_date = @user.created_at.strftime('%d-%m-%Y')
      @apply.save

      @addNewWork = Work.new
      @addNewWork.user_id = @user.id
      @addNewWork.save

      Uorg.where(user_id: @user.id).delete_all
      if !organization_user.nil?
        organization_user.each do |organization|
          @Uorg = Uorg.new
          if !@user.id.nil?
            @Uorg.user_id = @user.id
          end
          if !organization.nil?
            @Uorg.organization_id = organization
          end
          @Uorg.save
        end
      end


      redirect_to users_index_path(lang: session[:lang],page: session[:page], per_page: session[:per_page], search: session[:search]), notice: lib_translate("Add_new_staff_successfully")

    elsif update_tax_code == "update_tax_code"
      strinsurance_No = params[:user_insurance_No_add].strip
      strTaxId = params[:user_taxid_add]
      strIsuranceplace = params[:user_insurance_placed_add]
      @oUpdateUsersTax = User.where(id: id).first
      @oUpdateUsersTax.update({
        taxid: strTaxId,
        insurance_reg_place: strIsuranceplace,
        insurance_no: strinsurance_No,
      })
      #Save updated  history (Đạt 10/01/2023)
      change_column_value = @oUpdateUsersTax.previous_changes
      change_column_name = @oUpdateUsersTax.previous_changes.keys
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
      redirect_to user_details_path(id: id , lang: session[:lang]), notice: lib_translate("Update_staff_successfully")
    elsif typeupdate == "update_pwd"
      oUpdateUsersPwd = User.where(id: id).first
      oUpdateUsersPwd.update({
        password_digest:  Digest::MD5.hexdigest(params[:user_password_add].strip)
      })
      redirect_to user_details_path(id: id , lang: session[:lang]), notice: lib_translate("Update_staff_successfully")
    else
      oUpdateUser = User.where("id = #{id}").first
      Uorg.where(user_id: id).delete_all
      if !organization_user.nil?
        organization_user.each do |organization|
          @Uorg = Uorg.new
          if !id.nil?
            @Uorg.user_id = id
          end
          if !organization.nil?
            @Uorg.organization_id = organization
          end
          @Uorg.save
        end
      end
      strGender = params[:user_gender_add].strip
      strNationality = params[:user_nationality_add]&.strip
      strEthnic = params[:user_ethnic_add]
      sid = params[:user_sid_add]
      strUsername = params[:user_username_add].strip
      strEmail = params[:user_email_add].strip
      strPassword = params[:user_password_add].strip
      strReligion = params[:user_religion_add]
      strMarriage = params[:user_Marriage_add].strip
      strinsurance_No = params[:user_insurance_No_add].strip
      strEducation = params[:user_education_add]
      strAcademic_rank = params[:user_academic_add]
      strStatus = params[:user_status_add].strip
      strStype = params[:user_stype_add].strip
      strNote = params[:user_note_add].gsub(/\s+/, " ").strip
      strFirstname= params[:user_first_name_add].capitalize.strip;
      strLastname= params[:user_last_name_add].mb_chars.titleize.strip;
      strBirthday = params[:user_birthday_add].strip

      strPlaceOfBirth = params[:user_place_of_birth_add]
      strMPlaceOfBirth = params[:user_m_place_of_birth_add]
      strOtherEmail = params[:user_email_2_add]
      strPhone = params[:user_phone_add]
      strMobile = params[:user_mobile_add]
      strTaxId = params[:user_taxid_add]
      strIsuranceplace = params[:user_insurance_placed_add]
      # Hai code 27/12/2022
      strStaffType = params[:user_tbusertype_add]
      strStaffStatus = params[:user_tbuserstatus_add]
      strBenefittype = params[:user_benefit_type_add]
      strTwoFA = params[:twofa]
      twofa_exam = params[:twofa_exam]
      ignore_attend = params[:ignore_attend]
      termination_date = params[:termination_date]


      # end Hai code
      # update apply

      if Work.where(user_id: id).first == ""
        @addNewWork = Work.new
        @addNewWork.user_id = id
        @addNewWork.save
      end

      apply = Apply.where(user_id: id).first
      apply.update({
        name: strLastname + ' ' + strFirstname
      });

      #Save updated  history (Đạt 10/01/2023)
      change_column_value = apply.previous_changes
      change_column_name = apply.previous_changes.keys
      if change_column_name  != ""
          for changed_column in change_column_name do
              if changed_column != "updated_at"
                  fvalue = change_column_value[changed_column][0]
                  tvalue = change_column_value[changed_column][1]


              log_history(Apply, changed_column, fvalue ,tvalue, @current_user.email)

              end
          end
      end
      #end Save updated  history
      benefit=Benefit.where(user_id: id, stype: User.where(id:id).first.benefit_type)
      if !benefit.nil?
        benefit.update({
          status:"INACTIVE"
        })
      end

      dataupdate =  {
        first_name: strFirstname,
        last_name: strLastname,
        sid: sid,
        username: strUsername,
        email: strEmail,
        gender: strGender,
        nationality: strNationality,
        ethnic: strEthnic,
        religion: strReligion,
        marriage: strMarriage,
        insurance_no: strinsurance_No,
        education: strEducation,
        academic_rank: strAcademic_rank,
        status: strStatus,
        stype: strStype,
        birthday: strBirthday,
        note: strNote,
        taxid: strTaxId,
        insurance_reg_place: strIsuranceplace,
        place_of_birth: strPlaceOfBirth,
        m_place_of_birth: strMPlaceOfBirth,
        email1: strOtherEmail,
        phone: strPhone,
        password_digest: strPassword,
        mobile: strMobile,
        staff_type: strStaffType,
        staff_status: strStaffStatus,
        benefit_type: strBenefittype,
        tmppwd: nil,
        twofa: strTwoFA == "on" ? "YES" : "NO",
        twofa_exam: twofa_exam == "on" ? "YES" : "NO",
        ignore_attend: ignore_attend == "TRUE" ? "TRUE" : "FALSE",
        termination_date: termination_date,

      }
      if strStatus == "ACTIVE"
        oUpdateUser.update(login_failed:0)
      end
      benefit_ac=Benefit.where(user_id: id, stype: strBenefittype)
      if !benefit_ac.nil?
        benefit_ac.update({
          status:"ACTIVE"
        })
      end
      if strPassword.length < 8
        strPassword = params[:user_password_add].strip
        dataupdate[:password_digest] = nil if !dataupdate[:password_digest].nil?
        oUpdateUser.update(dataupdate.compact!)

        #Save updated  history (Đạt 10/01/2023)
        change_column_value = oUpdateUser.previous_changes
        change_column_name = oUpdateUser.previous_changes.keys
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
      else
        oUpdateUser.update({
          password_digest:  Digest::MD5.hexdigest(params[:user_password_add].strip)
        })
        #Save updated  history (Đạt 10/01/2023)
        change_column_value = oUpdateUser.previous_changes
        change_column_name = oUpdateUser.previous_changes.keys
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

      if typeupdate == "1"
        redirect_to users_index_path(lang: session[:lang],page: session[:page], per_page: session[:per_page], search: session[:search]), notice: lib_translate("Update_staff_successfully")
      else
        redirect_to user_details_path(id: id , lang: session[:lang]), notice: lib_translate("Update_staff_successfully")
      end

    end
  end

  # Change user password
  # @author: Vũ
  # @date: 06/04/2023
  # args:
  #  + user_id: id user login
  #  + old_password: old password
  #  + new_password: new password
  #  + confirm_password: confirm password
  # return: boolean
  def change_password
    bSuccess = false
    sMessage = ""
    sUser_id = params[:user_id]
    sOld_password = params[:password]
    sNew_password = params[:new_password] || ''
    sConfirm_password = params[:confirm_password]
    msg = ''
    success = false
    field = ''
    sNew_password = sNew_password.strip
    oUser = User.where(id: sUser_id).first

    if oUser.nil?
      msg = lib_translate("User_does_not_exist")
      field = 'user_id'
    elsif sOld_password.length < 8 #min lenght
      msg = lib_translate("Pwd_invalid_min_8")
      field = 'password'
    elsif Digest::MD5.hexdigest(sOld_password.strip) != oUser.password_digest && Digest::MD5.hexdigest(sOld_password.strip) != oUser.tmppwd
      msg = lib_translate("Incorrect_password")
      field = 'password'
    elsif sNew_password.length < 8 #min lenght
      msg = lib_translate("Pwd_invalid_min_8")
      field = 'new_password'
    elsif !sNew_password.match(/\d/) #number
      msg = lib_translate("Pwd_invalid_contain_one_number")
      field = 'new_password'
    elsif !sNew_password.match(/[A-Z]/) # uppercase
      msg = lib_translate("Pwd_invalid_contain_upercase")
      field = 'new_password'
    elsif !sNew_password.match(/[a-z]/) # regular char
      msg = lib_translate("Pwd_invalid_contain_regurlar")
      field = 'new_password'
    elsif !sNew_password.match(/[!@#$%^&*(),.?":{}|<>]/) # special
      msg = "#{lib_translate("Pwd_invalid_symbol")}: !@#$%^&*..."
      field = 'new_password'
    elsif Digest::MD5.hexdigest(sNew_password.strip) == oUser.password_digest || Digest::MD5.hexdigest(sNew_password.strip) == oUser.tmppwd
      msg = lib_translate("Pwd_newpass_cannot_same")
      field = 'new_password'
    elsif sNew_password != sConfirm_password
      msg = lib_translate("Pwd_invalid_confirm_pwd")
      field = 'confirm_password'
    else
      bSuccess = true
    end

    if bSuccess
      oUser.update({
        password_digest: Digest::MD5.hexdigest(sNew_password),
        tmppwd: nil
      })
      session[:force_change_pw] = false
    end

    hResult = {
      msg: msg,
      success: bSuccess,
      field: field,
    }
    respond_to do |format|
      format.js {
        render js: "changePasswordResult(#{hResult.to_json.html_safe})"
      }
    end
  end

  def update_avatar
    file = params[:file]
    user_id = params[:user_id]
    current_direct = params[:current_direct]
    oUser = User.where("id = #{user_id}").first
    status = true
    message = ""

    if oUser.nil?
      status = false
      message = lib_translate("User_not_exits")
    elsif file.nil? || file ==""
       status = false
       message = lib_translate("No_file")
    elsif file.size.to_f/(1024*1024) > 3
      logger.info "Upload avatar file > 3MB.User id: #{session[:user_id]} Client IP: #{request.remote_ip} Time: #{Time.now}"
      status = false
      message = lib_translate("Invalid_file_size")
    else
      new_avatar = upload_mediafile(file)
      if new_avatar.nil?
        status = false
        message = "#{lib_translate("An_unknown_error")} #{lib_translate("Plesase_try_again")}"
      else
        if !oUser.avatar.nil?
          old_avatar = Mediafile.where("id = #{oUser.avatar}").first
          old_avatar.destroy if !old_avatar.nil?
        end
        oUser.update({avatar: new_avatar})
        #Save updated  history (Đạt 10/01/2023)
        change_column_value = oUser.previous_changes
        change_column_name = oUser.previous_changes.keys
        if change_column_name  != ""
          for changed_column in change_column_name do
            if changed_column != "updated_at"
              fvalue = change_column_value[changed_column][0]
              tvalue = change_column_value[changed_column][1]
              log_history(User, changed_column, fvalue ,tvalue, @current_user.email)
            end
          end
        end
        status = true
        message = lib_translate("Update_staff_successfully")
      end
    end

    # Redirect
    if current_direct == "details"
      if status
        redirect_to user_details_path(id: user_id , lang: session[:lang]), notice: message
      else
        redirect_to user_details_path(id: user_id , lang: session[:lang]), alert: message
      end
    else
      if status
        redirect_to user_profile_path(id: user_id , lang: session[:lang]), notice: message
      else
        redirect_to user_profile_path(id: user_id , lang: session[:lang]), alert: message
      end
    end

  end

  def del
    id = params[:id]
    @user = User.where("id = #{id}").first
    if @user.email != "admin@gmail.com"
    @user.destroy
    log_history(User, "Xóa", "#{@user.last_name} #{@user.first_name}", "Đã xóa khỏi hệ thống", @current_user.email)
    redirect_to users_index_path(lang: session[:lang],page: session[:page], per_page: session[:per_page], search: session[:search]), notice: lib_translate("Delete_staff_successfully")
    else
    redirect_to users_index_path(lang: session[:lang],page: session[:page], per_page: session[:per_page], search: session[:search]), alert: "Account Admin not delete!!!"
    end
  end

  def checkOrg
    @oOrgid = params[:oOrgid]
    @oUorg = Uorg.where(organization_id: @oOrgid).first
    if @oUorg.nil?
      render json: false
    else
      @organ_scode = Organization.where(id: @oUorg.organization_id).first.scode
      render json: {organization_scode: @organ_scode}
    end


  end

  def check_unique_sid

      sidcheck = params[:check_id]
      check_id = User.where(sid: sidcheck).first

      if check_id == nil
        render json:{result_sid: true}
      else
        render json: {result_sid: false}
      end

  end

  def check_unique_username
    usernamecheck = params[:check_username]
    check_username = User.where(username: usernamecheck).first
    if check_username == nil
      render json: {result_usn: true}
    else
      render json: {result_usn: false}
    end
  end

  def check_username_exists
    usernamecheck = params[:check_username]
    check_username = User.where(username: usernamecheck).first
    if check_username == nil
      render json: false
    else
      render json: true
    end
  end
  def check_positionjob_exists
    check_positionjob = params[:check_positionjob]
    check_positionjob = Positionjob.where(name: check_positionjob).first
    if check_positionjob == nil
      render json: false
    else
      render json: true
    end
  end

  def check_unique_email
    emailcheck = params[:check_email]
    check_email = User.where(email: emailcheck).first
    if check_email == nil
      render json: true
    else
      render json: false
    end
  end

  def review_edit
    @review = Review.new
    @mediafiles = Mediafile.all.order("created_at DESC")
    @reviews = Review.all.order("created_at DESC")

    # start show filemedia list
    @revdocs = Revdoc.all.order("created_at DESC")
    listRe =[];
    idReview = params[:idReview]

    user = Review.select('user_id').where( id: idReview).first
    @revdocList = Revdoc.where(review_id: idReview)

    @revdocList.each do |revdoc|
      listRe.push(uid:user.user_id ,file_owner: revdoc.mediafile.owner, file_name: revdoc.mediafile.file_name,
      created_at: revdoc.mediafile.created_at.strftime("%d/%m/%Y"),
      relative_id: revdoc.review_id, id: revdoc.id)
    end
    render json:{keyRe: @revdocList, docs: listRe }


  end

  def review_update
    id = params[:review_id_add]
    user_id = params[:review_sid_add]
    review_reviewed_by = params[:review_reviewed_by_add].squish
    review_reviewed_place = params[:review_reviewed_place_add].squish
    review_reviewed_date = params[:review_reviewed_date_add].squish
    review_content = params[:review_content_add].squish
    review_result = params[:review_result_add].squish
    review_status = params[:review_status_add].squish

    # start show filemedia list
    @revdocs = Revdoc.all
    # end
    if id == ""
      file =  params["review_mediafile_id_add"]

      if file == ""
        @review = Review.new
        @review.user_id = user_id
        @review.reviewed_by = review_reviewed_by
        @review.reviewed_place = review_reviewed_place
        @review.reviewed_date = review_reviewed_date
        @review.content = review_content
        @review.result = review_result
        @review.status = review_status
        @review.save
        session[:save_tab_details] = "review"
        redirect_to user_details_path(id: user_id , lang: session[:lang]), notice: lib_translate("Creat_new_review_successfully")
      end

      # Gọi hàm upload file
      if !file.nil? && file !=""
          id_mediafile = upload_mediafile(file)
      end
      # End gọi hàm upload file

      @review = Review.new
      @review.user_id = user_id
      @review.mediafile_id = id_mediafile
      @review.reviewed_by = review_reviewed_by
      @review.reviewed_place = review_reviewed_place
      @review.reviewed_date = review_reviewed_date
      @review.content = review_content
      @review.result = review_result
      @review.status = review_status
      @review.save
      session[:save_tab_details] = "review"
      redirect_to user_details_path(id: user_id , lang: session[:lang]), notice: lib_translate("Creat_new_review_successfully")
    else
      @oReview = Review.where("id = #{id}").first
        file = params["review_mediafile_id_add"]
        # Upload file
        if !file.nil? && file !=""
          id_mediafile = upload_mediafile(file)
          @oReview.update({ mediafile_id: id_mediafile, reviewed_by: review_reviewed_by, reviewed_place: review_reviewed_place, reviewed_date: review_reviewed_date, content: review_content, result: review_result, status: review_status});
          #Save updated  history (Đạt 10/01/2023)
          change_column_value = @oReview.previous_changes
          change_column_name = @oReview.previous_changes.keys
          if change_column_name  != ""
              for changed_column in change_column_name do
                  if changed_column != "updated_at"
                      fvalue = change_column_value[changed_column][0]
                      tvalue = change_column_value[changed_column][1]

                  log_history(Review, changed_column, fvalue ,tvalue, @current_user.email)
                  end
              end
          end
          #end Save updated  history
        else
          @oReview.update({ reviewed_by: review_reviewed_by, reviewed_place: review_reviewed_place, reviewed_date: review_reviewed_date, content: review_content, result: review_result, status: review_status });
          #Save updated  history (Đạt 10/01/2023)
          change_column_value = @oReview.previous_changes
          change_column_name = @oReview.previous_changes.keys
          if change_column_name  != ""
              for changed_column in change_column_name do
                  if changed_column != "updated_at"
                      fvalue = change_column_value[changed_column][0]
                      tvalue = change_column_value[changed_column][1]

                  log_history(Review, changed_column, fvalue ,tvalue, @current_user.email)
                  end
              end
          end
          #end Save updated  history
        end
        # End
        session[:save_tab_details] = "review"
        redirect_to user_details_path(id: user_id , lang: session[:lang]), notice: lib_translate("Update_review_successfully")
    end
  end

  def review_del
    sid = params[:id]
    uid = params[:uid]
    did = params[:did]
    ck_action = params[:ck_action]
    if ck_action == "document"
      @revdoc = Revdoc.where("id = #{did}").first
      @id_mediafile = @revdoc.mediafile_id
      @revdoc.destroy
      delete_mediadile(@id_mediafile)
      redirect_to user_details_path(id: uid , lang: session[:lang]) , notice: lib_translate("Delete_review_successfully")

    else
      @review = Review.where("id = #{sid}").first
      @review.destroy
      log_history(Review, "Xóa", "#{@review.user.last_name} #{@review.user.first_name}", "Đã xóa khỏi hệ thống", @current_user.email)
      session[:save_tab_details] = "review"
      redirect_to user_details_path(id: uid , lang: session[:lang]) , notice: lib_translate("Delete_review_successfully")
    end
  end

  def review_details
    id = session[:user_id]
    session[:id_detal] = id
    @review = Review.where("id = #{id}").first
  end

  def review_upload_mediafile
    file = params["file"]
    review_id = params["review_id"]
    # kiểm tra có file hay ko
    if !file.nil? && file !=""
      #upload file
      @mediafile =  upload_document(file)
      # update file revdoc
      @revdoc = Revdoc.new
      @revdoc.review_id = review_id
      @revdoc.note = @mediafile[:name]
      @revdoc.mediafile_id = @mediafile[:id]
      @revdoc.status = @mediafile[:status]
      @revdoc.save
      #send data to font end
      @review = Review.where(id: review_id).first
      @data = {review_id:review_id,id:@revdoc.id ,file_id:@mediafile[:id], file_name:@mediafile[:name], created_at:@revdoc[:created_at].strftime("%d/%m/%Y"),file_owner: @mediafile[:owner], uid:@review[:user_id], review_id:@review[:id]}

      render json: @data
    else
      render json: "No file!"
    end
  end

# END CONTROLLER DAT CODE

# CONTROLLER H.ANH
  # contract
    def contract_edit
      @contracts = Contract.all.order("created_at DESC")
      @contract = Contract.new
      @mediafiles = Mediafile.all
      @users = User.all
      # start show filemedia list
      @condocs = Condoc.all.order("created_at DESC")
      listCon =[];
      idCon = params[:idContract]

      user = Contract.select('user_id').where("id = #{idCon}").first
      @conDocList = Condoc.where(contract_id: idCon)

      @conDocList.each do |conDoc|
        listCon.push(uid:user.user_id ,file_owner: conDoc.mediafile.owner, file_name: conDoc.mediafile.file_name, created_at: conDoc.mediafile.created_at.strftime("%d/%m/%Y"), relative_id: conDoc.contract_id, id: conDoc.id)
      end
      render json:{keyContract: @conDocList, docs: listCon }
      # end
    end

    def contract_update
      contract_data = {
        id: params[:contract_id],
        user_id: params[:contract_user_id],
        name: params[:contract_name],
        issued_date: params[:contract_issued_date],
        issued_by: params[:contract_issued_by],
        issued_place: params[:contract_issued_place],
        dtfrom: params[:dt_dtfrom],
        dtto: params[:dt_dtto],
        status: params[:status],
        note: params[:contract_note],
        base_salary: params[:contract_base_salary].gsub(',','')
      }

      # status handle
      if !contract_data[:status].nil?
        contract_data[:status] = "ACTIVE"
      end
      # start show filemedia list
      @condocs = Condoc.all
      # end
      if contract_data[:id] == ""
        file = params["contract_mediafile_id_add"]
        if file == ""
            @contract = Contract.create(contract_data)
            session[:save_tab_details] = "contract"
            if !@contract.nil?
              @detailsCon = Contractdetail.create({
                contract_id: @contract.id,
                amount: @contract.base_salary,
                name: @contract.name
              })
              redirect_to user_details_path(id: contract_data[:user_id] , lang: session[:lang],page:'contract'), notice: lib_translate("Add_new_contract_successfully")
            else
              redirect_to user_details_path(id: contract_data[:user_id] , lang: session[:lang],page:'contract'), notice: lib_translate("Add_new_contract_failed")
            end
        end
          # Upload file
        if !file.nil? && file !=""
          id_mediafile = upload_mediafile(file)
        end
        # End
        session[:save_tab_details] = "contract"
        @contract = Contract.create(contract_data)
        if !@contract.nil?
          @detailsCon = Contractdetail.create({
            contract_id: @contract.id,
            amount: @contract.base_salary,
            name: @contract.name
          })
          if session[:organization].to_a.include?("BUH")
            contracttype = Contracttype.find_by(name: params[:contract_name])
            is_seniority = contracttype&.is_seniority
  
            holiday = find_or_create_holiday(params[:contract_user_id], Time.current.year)
  
            existing_contracts = Contract.where(user_id: params[:contract_user_id])
                                        .where.not(dtfrom: nil)
                                        .order(:dtfrom)
  
            is_first_contract = existing_contracts.size == 1
            should_process = if is_first_contract
                                  %w[YES_PROBATION YES_OFFICIAL].include?(is_seniority)
                                else
                                  is_seniority == "YES_OFFICIAL"
                                end
  
            if should_process
              department = fetch_leaf_departments_by_user(params[:contract_user_id])&.first
              actual_holno = calculate_actual_holno_sup(
                params[:contract_user_id],
                department&.id
              )
              holiday.update(total: actual_holno)
              holiday.holdetails
                    .find_by(stype: "VI-TRI")
                    &.update(amount: actual_holno)
            end
          end

          redirect_to user_details_path(id: contract_data[:user_id] , lang: session[:lang],page:'contract'), notice: lib_translate("Add_new_contract_successfully")
        else
          redirect_to user_details_path(id: contract_data[:user_id] , lang: session[:lang],page:'contract'), notice: lib_translate("Add_new_contract_successfully")
        end

      else
        @oContract = Contract.where("id = #{contract_data[:id]}").first
        # update contract detail
        contractdetail = Contractdetail.where("contract_id = #{@oContract.id}").first
        if contractdetail.nil?
          @detailsCon = Contractdetail.create({
            contract_id: @oContract.id,
            amount: contract_data[:basic_Salary],
            name: contract_data[:name]
          })
        else
          contractdetail.update({amount: contract_data[:basic_Salary], name: contract_data[:name]})
        end
        # Upload file
        file = params["contract_mediafile_id_add"]
        id_mediafile = @oContract.mediafile_id
        if !file.nil? && file !=""
          id_mediafile = upload_mediafile(file)
        end
        @oContract.update(contract_data)

        #Save updated  history (Đạt 10/01/2023)
        change_column_value = @oContract.previous_changes
        change_column_name = @oContract.previous_changes.keys
        if change_column_name  != ""
            for changed_column in change_column_name do
                if changed_column != "updated_at"
                  fvalue = change_column_value[changed_column][0]
                  tvalue = change_column_value[changed_column][1]
                  log_history(Contract, changed_column, fvalue ,tvalue, @current_user.email)
                end
            end
        end

        session[:save_tab_details] = "contract"
        redirect_to user_details_path(id: contract_data[:user_id] , lang: session[:lang],page:'contract'), notice:  lib_translate("Update_contract_successfully")
      end
    end
    def find_or_create_holiday(user_id, year)
      holiday = Holiday.find_or_create_by(user_id: user_id, year: year) do |h|
        h.total = 0
        h.used  = 0
      end

      create_default_holdetails(holiday) if holiday.holdetails.empty?
      holiday
    end
    def create_default_holdetails(holiday)
      Holdetail.create!([
        {
          holiday_id: holiday.id,
          name: "Phép theo vị trí",
          amount: 0,
          stype: "VI-TRI"
        },
        {
          holiday_id: holiday.id,
          name: "Phép thâm niên",
          amount: 0,
          stype: "THAM-NIEN"
        },
        {
          holiday_id: holiday.id,
          name: "Phép tồn",
          amount: 0,
          stype: "TON",
          dtdeadline: Time.zone.local(Time.current.year, 3, 31).end_of_day.iso8601
        }
      ])
    end

    def fetch_leaf_departments_by_user(user_id)
      positionjob_ids = Work.where(user_id: user_id)
                            .where.not(positionjob_id: nil)
                            .pluck(:positionjob_id)

      department_ids = Positionjob.where(id: positionjob_ids).pluck(:department_id)
      # h.anh
      # update: chỉ lấy theo vị trí các phòng ban đang hoạt động
      # 21/10/2025
      departments = Department.where(id: department_ids, status: "0").where.not(parents: [nil, ""])

      if departments.present?
        parent_ids = departments.map(&:parents).compact.map(&:to_i)
        departments.reject { |dept| parent_ids.include?(dept.id) }
      else
        Department.where(id: department_ids, status: "0").limit(1)
      end
    end
    def calculate_actual_holno_sup(user_id, department_id)
      user = User.find_by(id: user_id)
      return [0, 0, 0, false] unless user

      contracts = Contract.where(user_id: user_id)
      contracttypes = Contracttype
        .where(name: contracts.map(&:name))
        .pluck(:name, :is_seniority)
        .to_h

      seniority_contracts = contracts
        .select { |c| contracttypes[c.name]&.include?("YES") && c.dtfrom }
        .sort_by(&:dtfrom)

      holno = Positionjob
        .where(
          id: Work.where(user_id: user_id)
                  .where.not(positionjob_id: nil)
                  .pluck(:positionjob_id),
          department_id: department_id
        ).first&.holno.to_f || 0

      # Mặc định là cả năm hiện tại
      today = Time.zone.today
      year = today.year
      start_date = Date.new(year, 1, 1)
      end_date = Date.new(year, 12, 31)

      # Nếu có hợp đồng trong năm thì lấy ngày bắt đầu làm việc
      if sorted_contracts.any?
        contract_start = sorted_contracts.first.dtfrom.to_date
        start_date = contract_start if contract_start.year <= year
      end
      if start_date.year < year
        check_tnlv = true
        worked_months_to_end = 12
        worked_months_to_now = 12
        actual_holno = holno
      elsif user.termination_date.present? && user.termination_date&.year == year
        check_tnlv = false
        worked_months_to_now = calculate_months_with_15_rule(start_date, today, false)
        worked_months_to_end = calculate_months_with_15_rule(start_date, user.termination_date, true)
        actual_holno = (holno * worked_months_to_now / 12.0).round
      else
        check_tnlv = false
        worked_months_to_now = calculate_months_with_15_rule(start_date, today, false)
        worked_months_to_end = calculate_months_with_15_rule(start_date, end_date, false)
        actual_holno = (holno / 12.0 * worked_months_to_end ).round
      end

      return actual_holno, worked_months_to_now, worked_months_to_end, check_tnlv
    end

    def calculate_months_with_15_rule(start_date, end_date, check)
      return 0 if start_date > end_date

      months = 0
      current = start_date
      # Tháng đầu tiên
      if start_date.day <= 15
        months += 1
      end
      # Tháng kế tiếp đến tháng của end_date (trừ tháng đầu)
      first_full_month = start_date.next_month.beginning_of_month

      while first_full_month <= end_date.beginning_of_month
        months += 1
        first_full_month = first_full_month.next_month
      end
      # Áp dụng trừ tháng cuối nếu check == true và nghỉ trước/đúng ngày 15
      if check && end_date.day <= 15
        months -= 1
      end
      months
    end
    def contract_preview
      @contract_id = params[:id]
      scontent = ""
      contractdetail = Contractdetail.where("contract_id = #{@contract_id}").first
      @contractdetail_id = contractdetail.id
      @contract = Contract.where("id = #{@contract_id}").first
      @token_preview = []
      @existTokens = [] # a list of assets inherited from an existing contract

      # get content
      if !contractdetail.nil?
        scontent = contractdetail.scontent
        if scontent.nil? || scontent.strip.empty?
          contracttype = Contracttype.where(name: @contract.name).first
          if !contracttype.nil?
            # get content from template
            tmpcontract =  Tmpcontract.where(name: contracttype.name).first
            if !tmpcontract.nil?
              scontent = tmpcontract.scontent
            end
          end
        end
      end

      # get token list from content
      token_names = scontent.scan(/(?<=<span class="token-display">).*?(?=<\/span>)/).flatten
      token_names = token_names.uniq
      token_names.each do |token|
        @token_preview.push({
          name: token,
          value: token,
          id: nil
          })
      end

      # static token list
      default_tokens = get_contract_token_value(@contract_id)
      # get saved token value
      if !contractdetail.nil?
        uctokens = Uctoken.where(contractdetail_id: @contractdetail_id)
        if uctokens.size > 0 # on open saved contract
          uctokens.each do |uctoken|
            @token_preview.each do |token|
                if uctoken.token == token[:name]
                  token[:id] = uctoken.id
                  token[:value] = uctoken.svalue
                end
            end
          end
        else # on open unsaved contract
          # Get all token saved from all saved contract of user. Use when loadding page done?
          detail_ids = Contractdetail.select("contractdetails.id")
          .where("contractdetails.id != #{@contractdetail_id} AND contracts.user_id = #{@contract.user_id}")
          .joins("JOIN contracts ON contracts.id = contractdetails.contract_id");
          detail_ids.each do |detail|
            uctokens = Uctoken.where(contractdetail_id: detail.id).order(updated_at: :desc)
            uctokens.each do |token|
              if !token.token.strip.empty? && token.token.strip != token.svalue.strip && !default_tokens.any? {|df_token| df_token[:name] == token.token}
                index = @existTokens.index {|item| item[:name] == token.token}
                if !index.nil?
                  @existTokens[index][:value] = token.svalue
                else
                  @existTokens.push({
                    name: token.token,
                    value: token.svalue
                  })
                end
              end
            end
          end
        end
      end

      # get value of default token
      user = User.where("id = #{@contract.user_id}").first
      @token_preview.each do |token|
        default_tk = default_tokens.detect{ |item| item[:name] == token[:name] }
        if !default_tk.nil?
          token[:value] = default_tk[:value]
        end
      end

      # scontent
      @scontent_preview = scontent

      # export data
      if params[:export] == "true"
        # make content for pdf
        scontent_pdf = scontent
        @token_preview.each do |token|
          if !token[:name].strip.empty? && token[:name].strip != token[:value].strip
            data_tag = "<span class=\"token-display\">#{token[:value]}</span>"
          else
            data_tag = "<span class=\"token-display\"></span>"
          end
          scontent_pdf = scontent_pdf.gsub("<span class=\"token-display\">#{token[:name]}</span>",data_tag)
        end
        pdf = WickedPdf.new.pdf_from_string(scontent_pdf.html_safe,
                                            encoding: "UTF-8",
                                            layout:'layouts/pdf/contract_layout.html.erb',
                                            margin: { :top => 0, :bottom => 0, :left => 0 , :right => 0})
        send_data pdf,  type: 'application/pdf',
                        disposition: 'attachment',
                        filename:"Contract_#{Time.now.strftime("%d_%m_%Y")}.pdf"
      end

    end

    def contract_preview_update
      @contract_id = params[:contract_id]
      contractdetail_id = params[:contractdetail_id]
      names = params[:names]
      values = params[:values]
      ids = params[:ids]
      ids.each_with_index do |id, index|
        if id.to_i != 0
            # update exits token
            token = Uctoken.where("id = #{id}");
            if !token.nil?
              token.update({
                token:names[index],
                svalue:values[index]
              })
            end
        else
            # create new
            Uctoken.create({
              contractdetail_id: contractdetail_id,
              token:names[index],
              svalue:values[index]
            })
        end
      end
      # save contract template
      contractdetail = Contractdetail.where("contract_id = #{@contract_id}").first
      contract = Contract.where(id: @contract_id).first
      if !contractdetail.nil? && !contract.nil?
        contracttype = Contracttype.where(name: contract.name).first
          name = contracttype.name
          if !contracttype.nil?
            # get content from template
            tmpcontract =  Tmpcontract.where(name: contracttype.name).first
            if !tmpcontract.nil?
              scontent = tmpcontract.scontent
              contractdetail.update({
                scontent:scontent
              })
            end
          end
      end
      redirect_to user_contract_preview_path(id: @contract_id,lang: session[:lang],export: params[:export]), notice: lib_translate("Update_contract_successfully")
    end

    def contract_del
      sid = params[:id]
      uid = params[:uid]
      did = params[:did]
      ck_action = params[:ck_action]
      if ck_action == "document"
        @condoc = Condoc.where("id = #{did}").first
        @id_mediafile = @condoc.mediafile_id
        @condoc.destroy
        delete_mediadile(@id_mediafile)
        redirect_to user_details_path(id: uid , lang: session[:lang],page:'contract'), notice: lib_translate("Delete_contract_successfully")

      else
        @contract = Contract.where("id = #{sid}").first
        @contract.destroy
        session[:save_tab_details] = "contract"
        log_history(Contract, "Xóa: #{@contract.user.last_name} #{@contract.user.first_name}", "#{@contract.name}" , "Đã xóa khỏi hệ thống", @current_user.email)

        redirect_to user_details_path(id: uid , lang: session[:lang],page:'contract'), notice: lib_translate("Delete_contract_successfully")
      end

    end

    def contract_upload_mediafile
      file = params["file"]
      contract_id = params["contract_id"]
      # kiểm tra có file hay ko
      if !file.nil? && file !=""
        #upload file
        @id_mediafile =  upload_document(file)
        # update file condoc
        @condoc = Condoc.new
        @condoc.contract_id = contract_id
        @condoc.note = @id_mediafile[:name]
        @condoc.mediafile_id = @id_mediafile[:id]
        @condoc.status = @id_mediafile[:status]

        @condoc.save
        #send data to font end
        @contract = Contract.where(id: contract_id).first
        @data = {contract_id:contract_id,id:@condoc.id ,file_id:@id_mediafile[:id], file_name:@id_mediafile[:name], created_at:@condoc[:created_at].strftime("%d/%m/%Y"), file_owner: @id_mediafile[:owner], uid:@contract[:user_id], contract_id:@contract[:id]}
        render json: @data
      else
        render json: "No file!"
      end
    end

    def contract_pdf
      @date = {
        month: Time.now.strftime("%m"),
        year: Time.now.strftime("%Y"),
        day: Time.now.strftime("%d")
      }
      respond_to do |format|
          format.pdf do
              to_date = Time.now.strftime("%d_%m_%Y")
              render  pdf: "demo_contract_#{to_date}",
                      template: '/users/template/contract/pdf_contract.html.erb'
          end
      end
    end

  # end contract
  # address
    def address_edit
      @address = Address.all
      @addresses = Address.new
      @mediafiles = Mediafile.all
      @users = User.all

      # start show filemedia list
      @adddocs = Adddoc.all.order("created_at DESC")
      listAdd =[];
      idAdd = params[:idAddress]

      # get user_id
      user = Address.select('user_id').where("id = #{idAdd}").first
      @addDocList = Adddoc.where(address_id: idAdd)

      @addDocList.each do |addDoc|
        listAdd.push(uid:user.user_id ,file_owner: addDoc.mediafile.owner, file_name: addDoc.mediafile.file_name, created_at: addDoc.mediafile.created_at.strftime("%d/%m/%Y"), relative_id: addDoc.address_id, id: addDoc.id)
      end
      render json:{keyAddress: @addDocList, docs: listAdd }
      # end
    end

    def address_update
      id = params[:address_id]
      aId = params[:address_user_id]
      aName = params[:address_name]
      aCountry = params[:ls_country]
      aProvince = params[:ls_province]
      aCity = params[:ls_city]
      aDistrict = params[:ls_district]
      aWard = params[:ls_ward]
      aStreet = params[:address_street]
      aNo = params[:address_no]

      aStype = params[:sel_stype]
      aStatus = params[:sel_status]

       # start show filemedia list
        @adddocs = Adddoc.all
      # end

          if id == ""
              file =  params["address_mediafile_id_add"]

              if file == ""

                @address = Address.new
                @address.user_id = aId
                @address.name = aName
                @address.country = aCountry
                @address.province = aProvince
                @address.city = aCity
                @address.district = aDistrict
                @address.ward = aWard
                @address.street = aStreet
                @address.no = aNo

                @address.stype = aStype
                @address.status = aStatus
                @address.save
                session[:save_tab_details] = "address"
                redirect_to user_details_path(id: aId , lang: session[:lang]), notice: lib_translate("Add_new_address_successfully")
              end
                # Gọi hàm upload file
              if !file.nil? && file !=""
                id_mediafile = upload_mediafile(file)
              end
              # End gọi hàm upload file
              @address = Address.new
                @address.user_id = aId
                @address.name = aName
                @address.country = aCountry
                @address.province = aProvince
                @address.city = aCity
                @address.district = aDistrict
                @address.ward = aWard
                @address.street = aStreet
                @address.no = aNo
                @address.mediafile_id = id_mediafile

                @address.stype = aStype
                @address.status = aStatus
                @address.save
                session[:save_tab_details] = "address"
                redirect_to user_details_path(id: aId , lang: session[:lang]), notice: lib_translate("Add_new_address_successfully")
          else
              @oAddress = Address.where("id = #{id}").first
              file = params["address_mediafile_id_add"]
              # Upload file
              if !file.nil? && file !=""
                id_mediafile = upload_mediafile(file)
                @oAddress.update({user_id: aId ,name: aName, country: aCountry, province: aProvince, city: aCity, district: aDistrict, ward: aWard, street: aStreet, no: aNo, mediafile_id: id_mediafile, stype: aStype, status: aStatus});

                change_column_value = @oAddress.previous_changes
                change_column_name = @oAddress.previous_changes.keys
                if change_column_name  != ""
                  for changed_column in change_column_name do
                      if changed_column != "updated_at"
                          fvalue = change_column_value[changed_column][0]
                          tvalue = change_column_value[changed_column][1]


                        log_history(Address, changed_column, fvalue ,tvalue, @current_user.email)

                      end
                  end
                end

              else
                  @oAddress.update({user_id: aId ,name: aName, country: aCountry, province: aProvince, city: aCity, district: aDistrict, ward: aWard, street: aStreet, no: aNo, stype: aStype, status: aStatus});
                  #Save updated  history (Đạt 10/01/2023)
                  change_column_value = @oAddress.previous_changes
                  change_column_name = @oAddress.previous_changes.keys
                  if change_column_name  != ""
                      for changed_column in change_column_name do
                          if changed_column != "updated_at"
                              fvalue = change_column_value[changed_column][0]
                              tvalue = change_column_value[changed_column][1]


                          log_history(Address, changed_column, fvalue ,tvalue, @current_user.email)

                          end
                      end
                  end
                  #end Save updated  history
              end
              # End
              session[:save_tab_details] = "address"
              redirect_to user_details_path(id: aId , lang: session[:lang]), notice: lib_translate("Update_address_successfully")
          end
    end

    def address_update_user
      id = params[:address_id]
      aId = params[:address_user_id]
      aName = params[:address_name]
      aCountry = params[:ls_country_user]
      aProvince = params[:ls_province_user]
      aCity = params[:ls_city_user]
      aDistrict = params[:ls_district_user]
      aWard = params[:ls_ward_user]
      aStreet = params[:address_street]
      aNo = params[:address_no]

      aStype = params[:sel_stype]
      aStatus = params[:sel_status]

          if id == ""
              file =  params["address_mediafile_id_add"]

              if file == ""

                @address = Address.new
                @address.user_id = aId
                @address.name = aName
                @address.country = aCountry
                @address.province = aProvince
                @address.city = aCity
                @address.district = aDistrict
                @address.ward = aWard
                @address.street = aStreet
                @address.no = aNo

                @address.stype = aStype
                @address.status = aStatus
                @address.save
                session[:save_tab_details] = "address"
                redirect_to user_details_path(id: aId , lang: session[:lang]), notice: lib_translate("Add_new_address_successfully")
              end
                # Gọi hàm upload file
              if !file.nil? && file !=""
                id_mediafile = upload_mediafile(file)
              end
              # End gọi hàm upload file
              @address = Address.new
                @address.user_id = aId
                @address.name = aName
                @address.country = aCountry
                @address.province = aProvince
                @address.city = aCity
                @address.district = aDistrict
                @address.ward = aWard
                @address.street = aStreet
                @address.no = aNo
                @address.mediafile_id = id_mediafile

                @address.stype = aStype
                @address.status = aStatus
                @address.save
                session[:save_tab_details] = "address"
                redirect_to user_details_path(id: aId , lang: session[:lang]), notice: lib_translate("Add_new_address_successfully")
          else
              @oAddress = Address.where("id = #{id}").first
              file = params["address_mediafile_id_add"]
              # Upload file
              if !file.nil? && file !=""
                id_mediafile = upload_mediafile(file)
                @oAddress.update({user_id: aId ,name: aName, country: aCountry, province: aProvince, city: aCity, district: aDistrict, ward: aWard, street: aStreet, no: aNo, mediafile_id: id_mediafile, stype: aStype, status: aStatus});
                change_column_value = @oAddress.previous_changes
                change_column_name = @oAddress.previous_changes.keys
                if change_column_name  != ""
                  for changed_column in change_column_name do
                      if changed_column != "updated_at"
                          fvalue = change_column_value[changed_column][0]
                          tvalue = change_column_value[changed_column][1]


                        log_history(Address, changed_column, fvalue ,tvalue, @current_user.email)

                      end
                  end
                end

              else
                  @oAddress.update({user_id: aId ,name: aName, country: aCountry, province: aProvince, city: aCity, district: aDistrict, ward: aWard, street: aStreet, no: aNo, stype: aStype, status: aStatus});
                  change_column_value = @oAddress.previous_changes
                  change_column_name = @oAddress.previous_changes.keys
                  if change_column_name  != ""
                    for changed_column in change_column_name do
                        if changed_column != "updated_at"
                            fvalue = change_column_value[changed_column][0]
                            tvalue = change_column_value[changed_column][1]


                          log_history(Address, changed_column, fvalue ,tvalue, @current_user.email)

                        end
                    end
                  end
              end
              # End
              session[:save_tab_details] = "address"
              redirect_to user_details_path(id: aId , lang: session[:lang]), notice: lib_translate("Update_address_successfully")
          end
    end

    def address_details

    end

    def address_del
      sid = params[:id]
      uid = params[:uid]
      did = params[:did]
      ck_action = params[:ck_action]
      if ck_action == "document"
        @adddoc = Adddoc.where("id = #{did}").first
        @id_mediafile = @adddoc.mediafile_id
        @adddoc.destroy
        delete_mediadile(@id_mediafile)
        redirect_to user_details_path(id: uid , lang: session[:lang]), notice: lib_translate("Delete_address_successfully")
      else
        @address = Address.where("id = #{sid}").first
        @address.destroy
        session[:save_tab_details] = "address"
        log_history(Address, "Xóa: #{@address.user.last_name} #{@address.user.first_name}","#{@address.name}" , "Đã xóa khỏi hệ thống", @current_user.email)

        redirect_to user_details_path(id: uid , lang: session[:lang]), notice: lib_translate("Delete_address_successfully")
      end

    end

    def address_upload_mediafile
      file = params["file"]
      address_id = params["address_id"]
      # kiểm tra có file hay ko
      if !file.nil? && file !=""
        #upload file
        @id_mediafile =  upload_document(file)
        # update file condoc
        @adddoc = Adddoc.new
        @adddoc.address_id = address_id
        @adddoc.note = @id_mediafile[:name]
        @adddoc.mediafile_id = @id_mediafile[:id]
        @adddoc.status = @id_mediafile[:status]
        @adddoc.save
        #send data to font end
        @address = Address.where(id: address_id).first
        @data = {address_id:address_id,id:@adddoc.id ,file_id:@id_mediafile[:id], file_name:@id_mediafile[:name], created_at:@adddoc[:created_at].strftime("%d/%m/%Y"), file_owner: @id_mediafile[:owner], uid:@address[:user_id], address_id:@address[:id]}
        render json: @data
      else
        render json: "No file!"
      end
    end

  # end address
  # identity
    def identity_edit
      @identitys = Identity.all.order("created_at DESC")
      @identityes = Identity.new
      @mediafiles = Mediafile.all
      @users = User.all

      # start show filemedia list
      @idendocs = Idendoc.all.order("created_at DESC")
      listIden =[];
      idIden = params[:idIdentity]
      # get user_id
      user = Identity.select('user_id').where("id = #{idIden}").first
      @idenDocList = Idendoc.where(identity_id: idIden)
      #  thêm user_id, sửa owenr thành file_owenr, sửa iden_doc thành relative_id
      @idenDocList.each do |idenDoc|
        listIden.push(uid:user.user_id ,file_owner: idenDoc.mediafile.owner, file_name: idenDoc.mediafile.file_name, created_at: idenDoc.mediafile.created_at.strftime("%d/%m/%Y"), relative_id: idenDoc.identity_id, id: idenDoc.id)
      end
      # chuyển listcontract thành docs
      render json:{keyIdentity: @idenDocList, docs: listIden }
      # end

    end

    def identity_update
      id = params[:identity_id]
      iId = params[:identity_user_id]
      iName = params[:identity_name]
      iDate = params[:identity_issued_date]
      iBy = params[:identity_issued_by]
      iPlace = params[:identity_issued_place]
      iExpired = params[:identity_issued_expired]

      iStype = params[:sel_stype]
      iStatus = params[:sel_status]
      # start show filemedia list
      @idendocs = Idendoc.all
      # end
        if id == ""
          file =  params["identity_mediafile_id_add"]

            if file == ""
              @identity = Identity.new
              @identity.user_id = iId
              @identity.name = iName
              @identity.issued_date = iDate
              @identity.issued_by = iBy
              @identity.issued_place = iPlace
              @identity.issued_expired = iExpired
              @identity.stype = iStype
              @identity.status = iStatus
              @identity.save
              session[:save_tab_details] = "identity"
              redirect_to user_details_path(id: iId , lang: session[:lang]), notice: lib_translate("Add_new_identity_successfully")
            end
            # Gọi hàm upload file
            if !file.nil? && file !=""
              id_mediafile = upload_mediafile(file)
            end
            # End gọi hàm upload file
            @identity = Identity.new
            @identity.user_id = iId
            @identity.name = iName
            @identity.issued_date = iDate
            @identity.issued_by = iBy
            @identity.issued_place = iPlace
            @identity.issued_expired = iExpired
            @identity.stype = iStype
            @identity.status = iStatus
            @identity.mediafile_id = id_mediafile
            @identity.save
            session[:save_tab_details] = "identity"
            redirect_to user_details_path(id: iId , lang: session[:lang]), notice: lib_translate("Add_new_identity_successfully")
        else
            @oIdentity = Identity.where("id = #{id}").first
            file = params["identity_mediafile_id_add"]
            # Upload file
            if !file.nil? && file !=""
              id_mediafile = upload_mediafile(file)
              @oIdentity.update({user_id: iId ,name: iName, issued_date: iDate, issued_by: iBy, issued_place: iPlace, issued_expired: iExpired, stype: iStype, status: iStatus ,mediafile_id: id_mediafile });
              change_column_value = @oIdentity.previous_changes
              change_column_name = @oIdentity.previous_changes.keys
              if change_column_name  != ""
                for changed_column in change_column_name do
                    if changed_column != "updated_at"
                        fvalue = change_column_value[changed_column][0]
                        tvalue = change_column_value[changed_column][1]


                      log_history(Identity, changed_column, fvalue ,tvalue, @current_user.email)

                    end
                end
              end

            else
              @oIdentity.update({user_id: iId ,name: iName, issued_date: iDate, issued_by: iBy, issued_place: iPlace, issued_expired: iExpired, stype: iStype, status: iStatus });
              change_column_value = @oIdentity.previous_changes
              change_column_name = @oIdentity.previous_changes.keys
              if change_column_name  != ""
                for changed_column in change_column_name do
                    if changed_column != "updated_at"
                        fvalue = change_column_value[changed_column][0]
                        tvalue = change_column_value[changed_column][1]


                      log_history(Identity, changed_column, fvalue ,tvalue, @current_user.email)

                    end
                end
              end

            end
            # End
            session[:save_tab_details] = "identity"
            redirect_to user_details_path(id: iId , lang: session[:lang]), notice: lib_translate("Update_identity_successfully")
        end
    end


    def identity_details
      id = params[:id]
      session[:id_detal] = id
      @identity = Identity.where("id = #{id}").first
    end


    def identity_del
      sid = params[:id]
      uid = params[:uid]
      did = params[:did]
      ck_action = params[:ck_action]
      if ck_action == "document"
        @idendoc = Idendoc.where("id = #{did}").first
        @id_mediafile = @idendoc.mediafile_id
        @idendoc.destroy
        delete_mediadile(@id_mediafile)
        redirect_to user_details_path(id: uid , lang: session[:lang]), notice: lib_translate("Delete_identity_successfully")
      else
        @identity = Identity.where("id = #{sid}").first
        @identity.destroy
        session[:save_tab_details] = "identity"
        log_history(Identity, "Xóa: #{@identity.user.last_name} #{@identity.user.first_name}", "#{@identity.name}" , "Đã xóa khỏi hệ thống", @current_user.email)

        redirect_to user_details_path(id: uid , lang: session[:lang]), notice: lib_translate("Delete_identity_successfully")
      end

    end

    def identity_upload_mediafile
      file = params["file"]
      identity_id = params["identity_id"]
      # kiểm tra có file hay ko
      if !file.nil? && file !=""
        #upload file
        @id_mediafile =  upload_document(file)
        # update file idendoc
        @idendoc = Idendoc.new
        @idendoc.identity_id = identity_id
        @idendoc.note = @id_mediafile[:name]
        @idendoc.mediafile_id = @id_mediafile[:id]
        @idendoc.status = @id_mediafile[:status]
        @idendoc.save
        #send data to font end
        @identity = Identity.where(id: identity_id).first
        @data = {identity_id:identity_id,id:@idendoc.id ,file_id:@id_mediafile[:id], file_name:@id_mediafile[:name], created_at:@idendoc[:created_at].strftime("%d/%m/%Y"), file_owner: @id_mediafile[:owner], uid:@identity[:user_id], identity_id:@identity[:id]}
        render json: @data
      else
        render json: "No file!"
      end
    end

    def check_unique_iden
      idenId= params[:identity_id]
      idenName = params[:check_idenname]

      ckIden= Identity.where(name: idenName).first
      check_iden = Identity.where(id: idenId).first
      if !check_iden.nil?
          if check_iden.name == idenName
            render json: {result: 'false'}
          else
              if ckIden.nil?
                render json: {results: 'false'}
              else
                render json: {results: 'true', scode: idenName}
              end
          end
      else
          if ckIden.nil?
            render json: {msg: 'false'}
          else
            render json:{ msg: 'true', scode: idenName}
          end
      end
    end
  #end identity

# END CONTROLLER H.ANH

# CONTROLLER HAI CODE
  def holiday_edit
    @holiday = Holiday.new
    @holidays = Holiday.all.order("created_at DESC")
    @mediafiles = Mediafile.all.order("created_at DESC")
    @departments = Department.all.order("created_at DESC")

    # start show filemedia list
    @holdocs = Holdoc.all.order("created_at DESC")
    list =[];
    idHol = params[:idHoliday]
    @holdocList = Holdoc.where(holiday_id: idHol)
    user = Holiday.select('user_id').where("id = #{idHol}").first

    @holdocList.each do |holdoc|
      list.push(uid:user.user_id,file_owner: holdoc.mediafile.owner, file_name: holdoc.mediafile.file_name,
      created_at: holdoc.mediafile.created_at.strftime("%d/%m/%Y"),
      relative_id: holdoc.holiday_id, id: holdoc.id )
    end
    render json:{key: @holdocList, docs: list }
    # end
  end

  def holiday_update
    id = params[:holiday_id_add]
    sId = params[:holiday_user_id_add]
    sName = params[:holiday_name_add]
    sDate = params[:holiday_issued_date_add]
    sPlace = params[:holiday_issued_place_add]
    sStatus = params[:sel_holiday_status_add]
    sStype = params[:sel_holiday_stype_add]
    sMedia = params[:holiday_mediafile_id_add]
    sNote = params[:holiday_note_add].gsub(/\s+/, " ").strip

    # start show filemedia list
      @holdocs = Holdoc.all
    # end

    if id == ""
        file = params["holiday_mediafile_id_add"]

        if file == ""
          @holiday = Holiday.new
          @holiday.user_id = sId
          @holiday.name = sName
          @holiday.issued_date = sDate
          @holiday.issued_place = sPlace
          @holiday.status = sStatus
          @holiday.stype = sStype
          @holiday.note = sNote
          @holiday.save
          session[:save_tab_details] = "holiday"
          redirect_to user_details_path(id: sId , lang: session[:lang]), notice:lib_translate("Add_new_holiday_successfully")
        end
        # Upload file
        if !file.nil? && file !=""
          id_mediafile = upload_mediafile(file)
        end
        # End
        @holiday = Holiday.new
        @holiday.user_id = sId
        @holiday.name = sName
        @holiday.issued_date = sDate
        @holiday.issued_place = sPlace
        @holiday.status = sStatus
        @holiday.stype = sStype
        @holiday.mediafile_id = id_mediafile
        @holiday.note = sNote
        @holiday.save
        session[:save_tab_details] = "holiday"
        redirect_to user_details_path(id: sId , lang: session[:lang]), notice:lib_translate("Add_new_holiday_successfully")

    else

      @oHoliday = Holiday.where("id = #{id}").first
        file = params["holiday_mediafile_id_add"]
        # Upload file
        if !file.nil? && file !=""
          id_mediafile = upload_mediafile(file)
          @oHoliday.update({user_id: sId ,name: sName, issued_place: sPlace, stype: sStype, mediafile_id: id_mediafile, issued_date:sDate, status: sStatus,  note: sNote });
          change_column_value = @oHoliday.previous_changes
          change_column_name = @oHoliday.previous_changes.keys
          if change_column_name  != ""
            for changed_column in change_column_name do
                if changed_column != "updated_at"
                    fvalue = change_column_value[changed_column][0]
                    tvalue = change_column_value[changed_column][1]


                  log_history(Holiday, changed_column, fvalue ,tvalue, @current_user.email)

                end
            end
          end
        else

          @oHoliday.update({user_id: sId ,name: sName, issued_place: sPlace, stype: sStype, issued_date:sDate, status: sStatus,  note: sNote });

          change_column_value = @oHoliday.previous_changes
          change_column_name = @oHoliday.previous_changes.keys
          if change_column_name  != ""
            for changed_column in change_column_name do
                if changed_column != "updated_at"
                    fvalue = change_column_value[changed_column][0]
                    tvalue = change_column_value[changed_column][1]


                  log_history(Holiday, changed_column, fvalue ,tvalue, @current_user.email)

                end
            end
          end
        end
        # End
        session[:save_tab_details] = "holiday"
        redirect_to user_details_path(id: sId , lang: session[:lang]), notice: lib_translate("Update_holiday_successfully")
    end
  end

  def holiday_details
    id = params[:id]
    session[:id_detal] = id
    @holiday = Holiday.where("id = #{id}").first
  end

  def holiday_del
    sid = params[:id]
    uid = params[:uid]
    did = params[:did]
    ck_action = params[:ck_action]
    if ck_action == "document"

      @holdoc = Holdoc.where("id = #{did}").first
      @id_mediafile = @holdoc.mediafile_id
      @holdoc.destroy
      delete_mediadile(@id_mediafile)
      redirect_to user_details_path(id: uid , lang: session[:lang]), notice:lib_translate("delete_message")

    else
      @holiday = Holiday.where("id = #{sid}").first
      @holiday.destroy
      session[:save_tab_details] = "holiday"
      log_history(Holiday, "Xóa: #{@holiday.user.last_name} #{@holiday.user.first_name}","#{@holiday.name}" , "Đã xóa khỏi hệ thống", @current_user.email)
      redirect_to user_details_path(id: uid , lang: session[:lang]), notice:lib_translate("Delete_holiday_successfully")
    end

  end

  def holiday_upload_mediafile
    file = params["file"]
    holiday_id = params["holiday_id"]
    # kiểm tra có file hay ko
    if !file.nil? && file !=""
      #upload file
      @mediafile =  upload_document(file)
      # update file holdoc
      @holdoc = Holdoc.new
      @holdoc.holiday_id = holiday_id
      @holdoc.note = @mediafile[:name]
      @holdoc.mediafile_id = @mediafile[:id]
      @holdoc.status = @mediafile[:status]
      @holdoc.save
      #send data to font end
      @holiday = Holiday.where(id: holiday_id).first
      @data = {holiday_id: holiday_id, id:@holdoc.id ,file_id:@mediafile[:id], file_name:@mediafile[:name], created_at:@holdoc[:created_at].strftime("%d/%m/%Y"),file_owner: @mediafile[:owner], uid:@holiday[:user_id], holiday_id:@holiday[:id]}
      render json: @data
    else
      render json: "No file!"
    end
  end

  # work
  def work_edit
    @work = Work.new
    @works = Work.all.order("created_at DESC")
    @positionjobs = Positionjob.all.order("created_at DESC")
  end

  def work_edit_status
      ckbVlBtn = params[:ckbVlBtn]
      nBtnid = params[:idSwitch]
      if ckbVlBtn == 'true'
        @Work = Work.where(id: nBtnid)
        @Work.update({status: "ACTIVE"})
        change_column_value = @Work.previous_changes
        change_column_name = @Work.previous_changes.keys
        if change_column_name  != ""
          for changed_column in change_column_name do
              if changed_column != "updated_at"
                  fvalue = change_column_value[changed_column][0]
                  tvalue = change_column_value[changed_column][1]


                log_history(Work, changed_column, fvalue ,tvalue, @current_user.email)

              end
          end
        end
        render json: ckbVlBtn

      else
        @Work = Work.where(id: nBtnid)
        @Work.update({status: "INACTIVE"})
        change_column_value = @Work.previous_changes
        change_column_name = @Work.previous_changes.keys
        if change_column_name  != ""
          for changed_column in change_column_name do
              if changed_column != "updated_at"
                  fvalue = change_column_value[changed_column][0]
                  tvalue = change_column_value[changed_column][1]


                log_history(Work, changed_column, fvalue ,tvalue, @current_user.email)

              end
          end
        end
        render json: ckbVlBtn

      end
  end

  def work_update
    user_id = params[:user_id]
    stasks = params[:stasks] || []
    positionjobs = params[:positionjobs] || []

    Work.where(user_id: user_id).destroy_all
    # # add new
    stasks.each do |id|
      Work.create({
        user_id:user_id.to_i,
        stask_id:id.to_i,
        status: "ACTIVE"
      })
    end
    positionjobs.each do |positionjob_id|
      Work.create({
        user_id:user_id.to_i,
        positionjob_id:positionjob_id.to_i,
        status: "ACTIVE"
      })
    end
    redirect_to user_details_path(id: user_id , lang: session[:lang]), notice:lib_translate("Update_success")
  end

  def work_del
    sid = params[:id]
    uid = params[:uid]
    @work = Work.where("id = #{sid}").first
    @id_mediafile = @work.mediafile_id
    @work.destroy
    delete_mediadile(@id_mediafile)
    session[:save_tab_details] = "work"
    redirect_to user_details_path(id: uid , lang: session[:lang]), notice:lib_translate("Delete_work_success")
  end
# END CONTROLLER HAI CODE

# Q.Thai Archive
  def archive_edit
    @archive = Archive.new
    @archives = Archive.all.order("created_at DESC")
    @mediafiles = Mediafile.all.order("created_at DESC")

    # start show filemedia list
    @ardocs = Ardoc.all.order("created_at DESC")
    listAr =[];
    idArchive = params[:idArchive]

    user = Archive.select('user_id').where("id = #{idArchive}").first
    @ardoclist = Ardoc.where(archive_id: idArchive)

    @ardoclist.each do |doc|
      listAr.push(uid:user.user_id ,file_owner: doc.mediafile.owner, file_name: doc.mediafile.file_name,
      created_at: doc.mediafile.created_at.strftime("%d/%m/%Y"),
      relative_id: doc.archive_id, id: doc.id)
    end
    render json:{keyAr: @ardoclist, docs: listAr }
    # end
  end

  def archive_update
    id_archive = params[:archive_id_add]
    sId_archive = params[:archive_user_id_add]
    sName_archive = params[:archive_name_add]
    sDate_archive = params[:archive_issued_date_add]
    sPlace_archive = params[:sel_archive_issued_place_add]
    sStatus_archive = params[:sel_archive_status_add]
    sStype_archive = params[:sel_archive_stype_add]
    sMedia_archive = params[:archive_mediafile_id_add]

    issue_id = params[:archive_issue_id]
    issue_type = params[:sel_archive_issue_type]
    issue_level = params[:sel_archive_issue_level]

    # start show filemedia list
    @archives = Ardoc.all.order("created_at DESC")
    # end
    if id_archive == ""
      file = params["archive_mediafile_id_add"]
      if file == ""
        @archive = Archive.new
        @archive.user_id = sId_archive
        @archive.name = sName_archive
        @archive.issued_date = sDate_archive
        @archive.issued_place = sPlace_archive
        @archive.status = sStatus_archive
        @archive.stype = sStype_archive
        @archive.issue_id = issue_id
        @archive.issue_type = issue_type
        @archive.issue_level = issue_level

        @archive.save
        session[:save_tab_details] = "archive"
        redirect_to user_details_path(id: sId_archive , lang: session[:lang]), notice:lib_translate("Create_archive_successfully")
      end
      # Upload file
      if !file.nil? && file !=""
        id_mediafile = upload_mediafile(file)
      end
      # End

      @archive = Archive.new
      @archive.user_id = sId_archive
      @archive.name = sName_archive
      @archive.issued_date = sDate_archive
      @archive.issued_place = sPlace_archive
      @archive.status = sStatus_archive
      @archive.mediafile_id = id_mediafile
      @archive.issue_id = issue_id
      @archive.issue_type = sStype_archive
      @archive.issue_level = issue_level
      @archive.save
      session[:save_tab_details] = "archive"
      redirect_to user_details_path(id: sId_archive , lang: session[:lang]), notice:lib_translate("Create_archive_successfully")
    else
      @oArchive = Archive.where("id = #{id_archive}").first
      file = params["archive_mediafile_id_add"]
      # Upload file
      if !file.nil? && file !=""
        id_mediafile = upload_mediafile(file)
        @oArchive.update({
          user_id: sId_archive,
          name: sName_archive,
          issued_place: sPlace_archive,
          mediafile_id: id_mediafile,
          issued_date:sDate_archive,
          status: sStatus_archive,
          issue_id: issue_id,
          issue_type: sStype_archive,
          issue_level: issue_level
           });

        change_column_value = @oArchive.previous_changes
        change_column_name = @oArchive.previous_changes.keys
        if change_column_name  != ""
          for changed_column in change_column_name do
              if changed_column != "updated_at"
                  fvalue = change_column_value[changed_column][0]
                  tvalue = change_column_value[changed_column][1]


                log_history(Archive, changed_column, fvalue ,tvalue, @current_user.email)

              end
          end
        end
      else
        @oArchive.update({user_id: sId_archive,
          name: sName_archive,
          issued_place: sPlace_archive,
          issued_date:sDate_archive,
          status: sStatus_archive,
          issue_id: issue_id,
          issue_type: sStype_archive,
          issue_level: issue_level });

          change_column_value = @oArchive.previous_changes
          change_column_name = @oArchive.previous_changes.keys
          if change_column_name  != ""
            for changed_column in change_column_name do
                if changed_column != "updated_at"
                    fvalue = change_column_value[changed_column][0]
                    tvalue = change_column_value[changed_column][1]


                  log_history(Archive, changed_column, fvalue ,tvalue, @current_user.email)

                end
            end
          end

      end
      # End
      session[:save_tab_details] = "archive"
      redirect_to user_details_path(id: sId_archive , lang: session[:lang]), notice: lib_translate("Update_archive_successfully")
    end

  end

  def archive_del
    sid = params[:id]
    uid = params[:uid]
    did = params[:did]
    ck_action = params[:ck_action]
    if ck_action == "document"
      @ardoc = Ardoc.where("id = #{did}").first
      @id_mediafile = @ardoc.mediafile_id
      @ardoc.destroy
      delete_mediadile(@id_mediafile)
      redirect_to user_details_path(id: uid , lang: session[:lang]), notice:lib_translate("delete_message")
    else
      @archive = Archive.where("id = #{sid}").first
      @archive.destroy
      oUser = User.where(id: @archive.user_id).first
      session[:save_tab_details] = "archive"
      log_history(Archive, "Xóa: #{@archive.user.last_name} #{@archive.user.first_name}", "#{@archive.name}" , "Đã xóa khỏi hệ thống", @current_user.email)
      redirect_to user_details_path(id: uid , lang: session[:lang]), notice:lib_translate("Delete_archive_successfully")
    end

  end

  def archive_upload_mediafile
    file = params["file"]
    archive_id = params["archive_id"]
    # kiểm tra có file hay ko
    if !file.nil? && file !=""
      #upload file
      @mediafile =  upload_document(file)
      # update file ardoc
      @ardoc = Ardoc.new
      @ardoc.archive_id = archive_id
      @ardoc.note = @mediafile[:name]
      @ardoc.mediafile_id = @mediafile[:id]
      @ardoc.status = @mediafile[:status]
      @ardoc.save
      #send data to font end
      @archive = Archive.where("id = #{archive_id}").first

      @data = {archive_id:archive_id,id:@ardoc.id ,file_id:@mediafile[:id], file_name:@mediafile[:name], created_at:@ardoc[:created_at].strftime("%d/%m/%Y"),file_owner: @mediafile[:owner], uid:@archive[:user_id], archive_id:@archive[:id]}

      render json: @data
    else
      render json: "No file!"
    end
  end

  def archive_details
    id = params[:id]
    session[:id_detal] = id
    media_only_archive = params[:media_only_archive]

    @archive_doc = Archive.where(id: id).first

    # if @archive_doc.nil?
    #   respond_to do |format|
    #     format.js {render js_archive: "toggleLoadingScreen(false);showAlert('#{lib_translate("Data_not_exist")}','warning');"}
    #   end
    # else
    #   mediaList = []
    #   @archive_doc.ardocs.each do |ardoc|
    #     mediafile = ardoc.mediafile
    #     mediaList.push({
    #       relative_id:id,
    #       id:ardoc.id,
    #       file_id:mediafile[:id],
    #       file_name:mediafile[:file_name],
    #       created_at: mediafile[:created_at].strftime("%d/%m/%Y"),
    #       file_owner:mediafile[:owner]
    #     })
    #   end

    #   archive_hash = {
    #     id:@archive_doc.id,
    #     name: @archive_doc.name,
    #     amount: @archive_doc.amount,
    #     stype: @archive_doc.stype,
    #     dtfrom: @archive_doc.dtfrom.strftime('%d/%m/%Y'),
    #     dtto: @archive_doc.dtto.strftime('%d/%m/%Y'),
    #     status: @archive_doc.status
    #   }

    #   respond_to do |format|
    #     if media_only_archive == "true"
    #       format.js {render js_archive: "toggleLoadingScreen(false);openArchiveDoc(#{id},#{mediaList.to_json})"}
    #     else
    #       format.js {render js_archive: "toggleLoadingScreen(false);openFormUpdateArchive(#{archive_hash.to_json},#{mediaList.to_json})"}
    #     end
    #   end
    # end
  end
# end Archive

# Benefit: Vu
  def benefit_edit
    benefit_benefit_page = params[:page].to_i || 1
    id = params[:id]
    limit = 10
    @benefits = Benefit.where(user_id: id).limit(limit).offset((benefit_page-1)*limit)
    benefits_total_items = @benefits.except(:offset, :limit, :order).count
    @benefit_pagins = render_pagin(user_benefit_edit_path(id: id , lang: session[:lang]),benefit_page,(benefits_total_items.to_f/limit))
    redirect_to user_details_path(id: id , lang: session[:lang], page: benefit_page)
  end
  # Thái 10/1
  def benefit_update
    benefit_id = params[:benefit_id]
    user_id = params[:benefit_user_id]
    benefit_name = params[:benefit_name]
    benefit_amount = params[:benefit_amount]
    benefit_stype = params[:benefit_stype_add_other]
    # dt_dtfrom = params[:benefit_dtfrom]
    # dt_dtto = params[:benefit_dtto]
    # sel_status = params[:sel_status]
    benefit_year = params[:benefit_year_add_other]
    benefit_desc = params[:benefit_desc]
    benefit_btype= params[:benefit_btype]
    benefit_name_add = params[:benefit_name_add]
    benefit_add= params[:benefit_add]
    benefit_type_add = params[:benefit_type_add]
    # using ajax
    sYear = params[:sYear]
    benefit_type = params[:benefit_type]
    list_id_sbenefit = params[:sbenefit_id]
    benefit_user_id = params[:user_id]

    list_benefit=Benefit.where(user_id: benefit_user_id , syear: sYear)

    if sYear.nil?
      if benefit_id == "" || benefit_id.nil?

        if benefit_btype == "OTHER"
          benefit_other_all = Benefit.where(syear: benefit_year, status:"ACTIVE",user_id:user_id, btype: "OTHER").where.not(id: benefit_name_add)
          if !benefit_other_all.nil?
            benefit_other_all.delete_all
            # benefit_other_all.each do |benefit_other|
            #   benefit_other.destroy
            # end
          end
        end
        if benefit_btype == "MONEY"
          benefit_all = Benefit.where(syear: benefit_year, status:"ACTIVE",user_id:user_id, btype: "MONEY").where.not(id: benefit_name_add)
          if !benefit_all.nil?
            benefit_all.delete_all
            # benefit_all.each do |benefit|
            #   Benefit.where(id: benefit.id).first.destroy
            # end
          end
        end


        if !benefit_name_add.nil?


          benefit_name_add.each do |benefit_add_other|
              check_id_other= Benefit.where(sbenefit_id: benefit_add_other,user_id:user_id, syear: benefit_year,status:"ACTIVE").first
              sbenefit= Sbenefit.where(id: benefit_add_other , stype: benefit_stype).first

              if check_id_other.nil? && !sbenefit.nil?
                @benefit = Benefit.new
                @benefit.user_id = user_id
                @benefit.name = sbenefit.name
                @benefit.amount = sbenefit.amount
                @benefit.stype = benefit_stype
                @benefit.syear = benefit_year
                @benefit.desc = sbenefit.desc
                @benefit.sbenefit_id = benefit_add_other
                @benefit.btype = sbenefit.btype
                @benefit.status="ACTIVE"
                @benefit.save
              # else
              #   if  sbenefit.nil?
              #     return
              #   end
              #   check_id_other.update({
              #     user_id: user_id,
              #     name: sbenefit.first.name,
              #     amount:  sbenefit.first.amount,
              #     stype: benefit_stype,
              #     syear: benefit_year,
              #     desc:  sbenefit.first.desc,
              #     sbenefit_id:  benefit_add_other,
              #     btype:  sbenefit.first.btype
              #   });

                # change_column_value = check_id_other.previous_changes
                # change_column_name = check_id_other.previous_changes.keys
                # if change_column_name  != ""
                #   for changed_column in change_column_name do
                #       if changed_column != "updated_at"
                #           fvalue = change_column_value[changed_column][0]
                #           tvalue = change_column_value[changed_column][1]
                #

                #         log_history(Sbenefit, changed_column, fvalue ,tvalue, @current_user.email)

                #       end
                #   end
                # end
              end
          end
        elsif benefit_add=="add"
          if benefit_amount.nil?
            return
          end
          @add_benefit = Benefit.new
          @add_benefit.user_id = user_id
          @add_benefit.name = benefit_name
          @add_benefit.amount = benefit_amount.gsub(',','')
          # @add_benefit.stype = benefit_stype
          @add_benefit.syear = benefit_year
          @add_benefit.desc = benefit_desc
          if benefit_amount.nil? || benefit_amount == ""
            @add_benefit.btype = "OTHER"
          else
            @add_benefit.btype = "MONEY"
          end
          @add_benefit.status="ACTIVE"
          @add_benefit.save
        else

        end
          flash[:notice] =lib_translate("Create_benefit_successfully")
          session[:save_tab_details] = "benefit"
          redirect_to user_details_path(id: user_id , lang: session[:lang],page:'benefit'), notice:lib_translate("Create_benefit_successfully")

      else

      end
    else
      sbenefit=Sbenefit.where(syear: sYear , stype: benefit_type)
      benefit_other= Benefit.where(syear: sYear, user_id: benefit_user_id)
      render json: { sbenefit: sbenefit, list_benefit:list_benefit ,benefit_other: benefit_other}
    end

  end
  # end Thái
  def benefit_details
    benefit_id = params[:benefit_id]
    media_only = params[:media_only]
    benefit = Benefit.where(id: benefit_id).first
    if benefit.nil?
      respond_to do |format|
        format.js {render js: "toggleLoadingScreen(false);showAlert('#{lib_translate("Data_not_exist")}','warning');"}
      end
    else
      mediaList = []
      benefit.bedocs.each do |bedoc|
        mediafile = bedoc.mediafile
        mediaList.push({
          relative_id:benefit_id,
          id:bedoc.id ,
          file_id:mediafile[:id],
          file_name:mediafile[:file_name],
          created_at: mediafile[:created_at].strftime("%d/%m/%Y"),
          file_owner:mediafile[:owner]
        })
      end

      benefit_hash = {
        id:benefit.id,
        name: benefit.name,
        amount: benefit.amount,
        stype: benefit.stype,
        # dtfrom: benefit.dtfrom.strftime('%d/%m/%Y'),
        # dtto: benefit.dtto.strftime('%d/%m/%Y'),
        status: benefit.status,
        syear: benefit.syear,
        desc: benefit.desc

      }

      respond_to do |format|
        if media_only == "true"
          format.js {render js: "toggleLoadingScreen(false);openBenefitDoc(#{benefit_id},#{mediaList.to_json})"}
        else
          format.js {render js: "toggleLoadingScreen(false);openFormUpdateBenefit(#{benefit_hash.to_json},#{mediaList.to_json})"}
        end
      end

    end
  end

  def benefit_del
    benefit_id = params[:benefit_id]
    user_id = params[:user_id]
    doc_id = params[:doc_id]
    ck_action = params[:ck_action]
    media_only = params[:media_only]
    name= params[:name]
    uid=params[:uid]
    if ck_action == "document"
      Bedoc.where("id = #{doc_id}").first.destroy
      # get new doclist
      bedocs = Bedoc.where(benefit_id: benefit_id)
      mediaList = []
      bedocs.each do |bedoc|
        mediafile = bedoc.mediafile
        mediaList.push({
          relative_id:benefit_id,
          id:bedoc.id ,
          file_id:mediafile[:id],
          file_name:mediafile[:file_name],
          created_at: mediafile[:created_at].strftime("%d/%m/%Y"),
          file_owner:mediafile[:owner]
        })
      end
      respond_to do |format|
        format.js {render js: "toggleLoadingScreen(false);showAlert('#{lib_translate("Update_benefit_successfully")}','success');onDeleteDoc(#{benefit_id},#{doc_id},#{media_only});"}
      end
    elsif !name.nil? || name == ""
      # Benefit.where("id = #{benefit_id}").first.destroy
      Benefit.where(name: name).delete_all
      session[:save_tab_details] = "benefit"
      redirect_to user_details_path(id: uid , lang: session[:lang],page:'benefit'), notice:lib_translate("Delete_benefit_successfully")
    else

    end

  end

  def benefit_upload_mediafile
    file = params["file"]
    benefit_id = params["benefit_id"]
    # kiểm tra có file hay ko
    if !file.nil? && file !=""
      #upload file
      media_file =  upload_document(file)
      # update file bedoc
      bedoc = Bedoc.new
      bedoc.benefit_id = benefit_id
      bedoc.note = media_file[:name]
      bedoc.mediafile_id = media_file[:id]
      bedoc.status = media_file[:status]
      bedoc.save
      #send data to font end
      benefit = Benefit.where(id: benefit_id).first
      data = {  relative_id:benefit_id,
                id:bedoc.id ,
                file_id:media_file[:id],
                file_name:media_file[:name],
                created_at: bedoc[:created_at].strftime("%d/%m/%Y"),
                file_owner:media_file[:owner]
            }
      render json: data
    else
      render json: "No file!"
    end
  end
# Benefit: Vu - End

  def chart_benefit
    id = params[:user_id]
    syear = params[:syear]
    @data_Basic_Salary = []
    @data_Additional_Income = []
    @data_Deductions = []
    @data_Net = []
    @data_table = []
      Payslip.where(user_id: id, syear: syear).sort_by { |a| (a.smonth.to_i) }.each do |payslip|
        @data_Basic_Salary.push(payslip.base_salary ? payslip.base_salary : 0)
        @data_Additional_Income.push(payslip.extra_income ? payslip.extra_income : 0)
        @data_Deductions.push(payslip.dedution ? payslip.dedution : 0)
        @data_Net.push(payslip.snet ? payslip.snet : 0)
        @data_table.push({
          id: payslip.id,
          year: payslip.syear,
          month: payslip.smonth,
          basic_Salary: payslip.base_salary ? payslip.base_salary : 0,
          additional_Income: payslip.extra_income ? payslip.extra_income : 0,
          Deductions: payslip.dedution ? payslip.dedution : 0,
          Net: payslip.snet ? payslip.snet : 0
          })
      end
      render json:{
        data_Basic_Salary:@data_Basic_Salary,
        data_Additional_Income:@data_Additional_Income,
        data_Deductions:@data_Deductions,
        data_Net:@data_Net,
        data_Table:@data_table
      }
  end

  def work_history_update
    id_of_company= params[:text_field_id_of_company]
    apply_id_company= params[:text_field_apply_id_company]
    name_company= params[:text_field_name]
    position_company= params[:text_field_position]
    period_company= params[:text_field_period]
    leader_company= params[:text_field_leader]
    comments_company= params[:text_field_comments].gsub(/\s+/, " ").strip
    status_company= params[:company_status_add]
    department_company= params[:text_field_working_part]
    if id_of_company==""
      @addCompany =Company.new
      @addCompany.apply_id = apply_id_company
      @addCompany.name= name_company.strip
      @addCompany.position= position_company.strip
      @addCompany.period= period_company.strip
      @addCompany.leader= leader_company.strip
      @addCompany.comments= comments_company.strip
      @addCompany.status= status_company
      @addCompany.department= department_company.strip
      @addCompany.save
      redirect_to user_details_path(id: session[:id_detal_user] , lang: session[:lang]), notice:lib_translate("Add_message_company")
    else
      oCompany= Company.where(id: id_of_company).first
      oCompany.update({
        apply_id: apply_id_company,
        name: name_company,
        position: position_company,
        period: period_company,
        leader: leader_company,
        comments: comments_company,
        department: department_company,
        status: status_company
      })

      change_column_value = oCompany.previous_changes
        change_column_name = oCompany.previous_changes.keys
        if change_column_name  != ""
          for changed_column in change_column_name do
              if changed_column != "updated_at"
                  fvalue = change_column_value[changed_column][0]
                  tvalue = change_column_value[changed_column][1]


                log_history(Company, changed_column, fvalue ,tvalue, @current_user.email)

              end
          end
        end
      redirect_to user_details_path(id: session[:id_detal_user] , lang: session[:lang]), notice:lib_translate("update_message_company")

    end
  end

  def work_history_del
    id = params[:id]
    uid= params[:uid]
    oCompany= Company.where(id: id).first
    oCompany.destroy
    log_history(Company, "Xóa: #{oCompany.apply.user.last_name} #{oCompany.apply.user.first_name}", "#{oCompany.name}" , "Đã xóa khỏi hệ thống", @current_user.email)
    redirect_to user_details_path(id: uid , lang: session[:lang]) , notice: lib_translate("delete_message")
  end

  #Bank
  def bank_update

    @bank = Bank.new
    id = params[:bank_id]
    user_id = params[:bank_user_id]
    baName= params[:txt_name_bank].strip
    baBranch= params[:txt_branch_bank].strip
    baAddress= params[:txt_address_bank].strip
    baNumber= params[:txt_ba_number].strip
    baName_bank= params[:sel_bank_name_add].strip
    baStatus= params[:sel_status_ba]

    if id == ""
      @bank.user_id=user_id
      @bank.name=baName
      @bank.branch=baBranch
      @bank.address=baAddress
      @bank.ba_number=baNumber
      @bank.ba_name=baName_bank
      @bank.status=baStatus
      @bank.save
      redirect_to user_details_path(id: session[:id_detal_user] , lang: session[:lang]), notice: lib_translate("Add_message")

    else
        @oBank = Bank.where("id = #{id}").first
        @oBank.update({

          name: baName, branch: baBranch,address: baAddress,
          ba_number: baNumber, ba_name: baName_bank,
          status: baStatus,
          });

        change_column_value = @oBank.previous_changes
        change_column_name = @oBank.previous_changes.keys
        if change_column_name  != ""
          for changed_column in change_column_name do
              if changed_column != "updated_at"
                  fvalue = change_column_value[changed_column][0]
                  tvalue = change_column_value[changed_column][1]


                log_history(Bank, changed_column, fvalue ,tvalue, @current_user.email)

              end
          end
        end


      redirect_to user_details_path(id: session[:id_detal_user] , lang: session[:lang]), notice: lib_translate("Update_bank_message")

    end

  end

  def bank_del

      sid = params[:id]
      # @bank = Bank.where("id = #{id}").first
      @bank = Bank.where(id: sid).first
      @bank.destroy
      redirect_to user_details_path(id: session[:id_detal_user] , lang: session[:lang]), notice: lib_translate("delete_message")
      log_history(Bank, "Xóa: #{@bank.user.last_name} #{@bank.user.first_name}", "#{@bank.name}"  , "Đã xóa khỏi hệ thống", @current_user.email)

  end

  #Education
  def education_update
    id = params[:school_add_id]
    apply_id =  params[:school_add_apply_id]
    strSchoolName = params[:school_add_name].strip
    strSchoolPeriod = params[:school_add_period].strip
    strSchoolCertificate = params[:school_add_certificate].strip
    strSchoolAddress = params[:school_add_address].strip
    strSchoolStatus = params[:school_add_status]
    strSchoolRanking = params[:school_add_ranking]
    dtexpired= params[:term_cetificate] == "Vô thời hạn" ? nil : params[:term_cetificate]
    if id == ""
      @schoolNew = School.new
      @schoolNew.apply_id = apply_id
      @schoolNew.name = strSchoolName
      @schoolNew.period = strSchoolPeriod
      @schoolNew.certificate = strSchoolCertificate
      @schoolNew.address = strSchoolAddress
      @schoolNew.status = strSchoolStatus
      @schoolNew.level = strSchoolRanking
      @schoolNew.dtexpired=dtexpired
      @schoolNew.save
      redirect_to user_details_path(id: session[:id_detal_user] , lang: session[:lang]), notice: lib_translate("Add_new_school_info_successfully")
    else
      @oUpdateSchool = School.where(id: id).first
      @oUpdateSchool.update(
        {
          name: strSchoolName,
          period: strSchoolPeriod,
          certificate: strSchoolCertificate,
          address: strSchoolAddress,
          status: strSchoolStatus,
          level: strSchoolRanking,
          dtexpired: dtexpired
        }
      )

      change_column_value = @oUpdateSchool.previous_changes
        change_column_name = @oUpdateSchool.previous_changes.keys
        if change_column_name  != ""
          for changed_column in change_column_name do
              if changed_column != "updated_at"
                  fvalue = change_column_value[changed_column][0]
                  tvalue = change_column_value[changed_column][1]


                log_history(School, changed_column, fvalue ,tvalue, @current_user.email)

              end
          end
        end
      redirect_to user_details_path(id: session[:id_detal_user] , lang: session[:lang]), notice: lib_translate("Update_school_info_successfully")
    end
  end

  def education_del
    id = params[:id]
    @school = School.where(id: id).first
    @school.destroy
    log_history(School, "Xóa: #{@school.apply.user.last_name} #{@school.apply.user.first_name}",  "#{@school.name}" , "Đã xóa khỏi hệ thống", @current_user.email)
    redirect_to user_details_path(id: session[:id_detal_user] , lang: session[:lang]) , notice: lib_translate("Delete_school_info_successfully")

  end
  # relative Dat
  def relative_update
    id = params[:relative_add_id]
    apply_id =  params[:relative_add_apply_id]
    strRelativeName = params[:relative_add_name].strip
    strRelativeBirthday = params[:relative_add_birthday].strip
    strRelativePhone = params[:relative_add_phone].strip
    strRelativeEmail = params[:relative_add_email].strip
    strRelativeStype = params[:relative_add_stype].strip
    strRelativeState = params[:relative_add_state].strip
    strRelativeNote = params[:relative_add_note].gsub(/\s+/, " ").strip
    strRelativeStatus = params[:relative_add_status].strip
    strRelativeIdcode = params[:relative_add_id_card].strip
    strRelativeIdenType = params[:relative_add_identity_type].strip
    strRelativeIndenStartDate = params[:relative_add_inden_start_date].strip
    strRelativeIndenPlace = params[:relative_add_id_card_Issued_place].strip
    strRelativeTaxcode = params[:relative_add_tax_code].strip
    strRelativeIndenEndDate = params[:relative_add_inden_end_date].strip

    if id == ""
      @relativeNew = Relative.new
      @relativeNew.apply_id = apply_id
      @relativeNew.name = strRelativeName
      @relativeNew.birthday = strRelativeBirthday
      @relativeNew.phone = strRelativePhone
      @relativeNew.email = strRelativeEmail
      @relativeNew.stype = strRelativeStype
      @relativeNew.state = strRelativeState
      @relativeNew.note = strRelativeNote
      @relativeNew.status = strRelativeStatus
      @relativeNew.identity = strRelativeIdcode
      @relativeNew.identity_type = strRelativeIdenType
      @relativeNew.identity_date = strRelativeIndenStartDate
      @relativeNew.identity_place = strRelativeIndenPlace
      @relativeNew.taxid = strRelativeTaxcode
      @relativeNew.identity_expired = strRelativeIndenEndDate
      @relativeNew.save
      redirect_to user_details_path(id: session[:id_detal_user] , lang: session[:lang]), notice: lib_translate("Add_new_relative_successfully")
    else
      @oUpdateRelative = Relative.where(id: id).first
      @oUpdateRelative.update(
        {
          name:strRelativeName,
          birthday:strRelativeBirthday,
          phone:strRelativePhone,
          email:strRelativeEmail,
          stype:strRelativeStype,
          state:strRelativeState,
          note:strRelativeNote,
          status:strRelativeStatus,
          identity:strRelativeIdcode,
          identity_type:strRelativeIdenType,
          identity_date:strRelativeIndenStartDate,
          identity_place:strRelativeIndenPlace,
          taxid:strRelativeTaxcode,
          identity_expired:strRelativeIndenEndDate,
        }
      )

      change_column_value = @oUpdateRelative.previous_changes
        change_column_name = @oUpdateRelative.previous_changes.keys
        if change_column_name  != ""
          for changed_column in change_column_name do
              if changed_column != "updated_at"
                  fvalue = change_column_value[changed_column][0]
                  tvalue = change_column_value[changed_column][1]


                log_history(Relative, changed_column, fvalue ,tvalue, @current_user.email)

              end
          end
        end
      redirect_to user_details_path(id: session[:id_detal_user] , lang: session[:lang]), notice: lib_translate("Update_relative_successfully")
    end

  end

  def relative_del

    sid = params[:id]
    uid = params[:uid]
    did = params[:did]
    ck_action = params[:ck_action]
    if ck_action == "document"
      @reldoc = Reldoc.where("id = #{did}").first
      @reldoc.destroy
      redirect_to user_details_path(id: uid , lang: session[:lang]) , notice: lib_translate("delete_message")

    else
      @relative = Relative.where("id = #{sid}").first
      @relative.destroy
      log_history(Relative, "Xóa: #{@relative.apply.user.last_name} #{@relative.apply.user.first_name}",  "#{@relative.name} " , "Đã xóa khỏi hệ thống", @current_user.email)
      redirect_to user_details_path(id: uid , lang: session[:lang]) , notice: lib_translate("delete_message")
    end
  end

  def relative_upload_mediafile
    file = params["file"]
    relative_id = params["relative_id"]
    # kiểm tra có file hay ko
    if !file.nil? && file !=""
      #upload file
      @mediafile =  upload_document(file)
      # update file revdoc
      @reldoc = Reldoc.new
      @reldoc.relative_id = relative_id
      @reldoc.mediafile_id = @mediafile[:id]
      @reldoc.save
      #send data to font end
      @relative = Relative.where(id: relative_id).first
      @data = {relative_id:relative_id,id:@reldoc.id ,file_id:@mediafile[:id], file_name:@mediafile[:name], created_at:@reldoc[:created_at].strftime("%d/%m/%Y"),file_owner: @mediafile[:owner], uid:@relative[:user_id], relative_id:@relative[:id]}

      render json: @data
    else
      render json: "No file!"
    end

  end

  def relative_edit
    @relative = Relative.new
    @mediafiles = Mediafile.all.order("created_at DESC")
    @relatives = Relative.all.order("created_at DESC")

    # start show filemedia list
    @reldocs = Reldoc.all.order("created_at DESC")
    listRel =[];
    idRelative = params[:idRelative]

    apply_id = Relative.select('apply_id').where( id: idRelative).first
    @reldocList = Reldoc.where(relative_id: idRelative)

    @reldocList.each do |reldoc|
      listRel.push(user:apply_id ,file_owner: reldoc.mediafile.owner, file_name: reldoc.mediafile.file_name,
      created_at: reldoc.mediafile.created_at.strftime("%d/%m/%Y"),
      relative_id: reldoc.relative_id, id: reldoc.id)
    end
    render json:{keyRe: @reldocList, docs: listRel }
  end
  # end relative Dat

  # Import user from excel file
  # @author: Vu
  # @date: 14/02/2023
  # last update: 4:39 21/02/2023
  def import_users
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
    # database
    organizations = Organization.all.map(&:attributes)
    educations = Education.pluck(:name).map(&:downcase)
    regulations = Regulation.pluck(:name).map(&:downcase)
    nationalitys = Nationality.pluck(:name).map(&:downcase)
    ethnics = Ethnic.pluck(:name).map(&:downcase)
    # academicranks = Academicrank.pluck(:name)
    # tbusertypes = Tbusertype.pluck(:name)
    # tbuserstatuss = Tbuserstatus.pluck(:name)

    begin
      # read from excel
      excel_datas = read_excel(file,3)
      excel_datas.each_with_index do |item,index|

        duplicate = false
        stt = (index + 1)

        # data
        first_name = item[1]&.to_s&.strip
        last_name = item[2]&.to_s&.strip
        birthday = item[3]
        place_of_birth = item[4]&.strip
        m_place_of_birth = item[5]&.strip
        sid = item[6]&.to_s&.strip
        email = item[7]&.strip
        email1 = item[8]&.strip
        benefit_type = !["1","2","3"].include?(item[9]) ? "1" : item[9]
        gender = item[10]&.strip
        org_list = item[11]&.split(",")
        org_list_safe = []
        phone = item[12]&.to_s&.strip
        mobile = item[13]&.to_s&.strip
        staff_status = item[14]&.to_s&.strip # new
        staff_type = item[15]&.strip
        stype = item[16]&.strip # new
        religion = item[17]&.strip&.downcase
        nationality = item[18]&.strip&.downcase
        ethnic = item[19]&.strip&.downcase
        education = item[20]&.strip&.downcase
        academic_rank = item[21]&.strip
        marriage = item[22]&.strip
        insurance_no = item[23]&.to_s&.strip # new
        taxid = item[24]&.to_s&.strip # new
        note = item[25]&.to_s&.strip
        termination_date = item[26]&.to_s&.strip || ""


        # check email
        if !is_valid_email?(email)
          valids.push({
            line: "#{trans_line} #{stt.to_s}",
            message:"Email #{trans_invalid}"
          })
          next
        end

        ###### duplicate check
        # email
        user_update = User.where(email: email).first
        if !user_update.nil?
          duplicate = true
        end

        # phone
        # user_exist = User.where(mobile: mobile).first
        # if !user_exist.nil? && !user_update.nil?
        #   if user_exist.id == user_update.id
        #     mobile = nil
        #   else
        #     valids.push({
        #       line: "#{trans_line} #{stt.to_s}",
        #       message:"Số Di động:#{mobile} trùng với nhân sự #{user_exist.first_name} #{user_exist.last_name} [#{user_update.id}] [Email: #{email}] [Mobile: #{mobile}]"
        #     })
        #     next
        #   end
        # end

        ###### valid check
        if first_name.nil? || first_name.empty?
          if duplicate
            first_name = nil
          else
            valids.push({
              line: "#{trans_line} #{stt.to_s}",
              message:"Tên #{trans_empty}"
            })
            next
          end
        end

        if last_name.nil? || last_name.empty?
          if duplicate
            last_name = nil
          else
            valids.push({
              line: "#{trans_line} #{stt.to_s}",
              message:"Họ tên đệm #{trans_empty}"
            })
            next
          end
        end

        begin
          if birthday.instance_of?(Date)
          elsif birthday.instance_of?(String)
            birthday = DateTime.strptime(birthday,"%d/%m/%Y")
          end
        rescue Exception => e
          if duplicate
            birthday = nil
          else
            valids.push({
              line: "#{trans_line} #{stt.to_s}",
              message:"Ngày sinh #{e.message}"
            })
            next
          end
        end

        # employee code
        if sid.nil? || sid.empty?
          valids.push({
            line: "#{trans_line} #{stt.to_s}",
            message:"Mã nhân viên #{trans_invalid}"
          })
          next
        end

        # education exits:  name
        if !educations.include?(education)
          if duplicate
            education = nil
          else
            valids.push({
              line: "#{trans_line} #{stt.to_s}",
              message:"Trình độ học vấn #{trans_invalid}"
            })
            next
          end
        end

        # organization exits: scode
        org_list&.each do |scode|
          organization = organizations.detect {|org| org["scode"] == scode.strip}
          if organization.nil?
            valids.push({
              line: "#{trans_line} #{stt.to_s}",
              message:"Đơn vị chủ quản : #{trans_invalid} [#{scode}]"
            })
          else
            org_list_safe.push(organization["id"])
          end
        end

        ###### Data handle
        case gender
        when nil
          if !duplicate
            gender = "0"
          end
        when "Nam"
          gender = "0"
        when "Nữ"
          gender = "1"
        else
          gender = "2"
        end

        if !regulations.include?(religion)
          if duplicate
            religion = nil
          else
            religion = "Không"
          end
        end

        if !nationalitys.include?(nationality)
          if duplicate
            nationality = nil
          else
            nationality = "Việt Nam"
          end
        end

        if !ethnics.include?(ethnic)
          if duplicate
            ethnic = nil
          else
            ethnic = "Kinh"
          end
        end

        #  marri
        if marriage.nil? || !marriage.empty?
          if duplicate
            marriage= nil
          end
        else
          marriage == "Kết hôn" ? "Married" : "Single"
        end

        # stype
        stype = stype&.downcase == "nhân sự" ? "MEMBER" : "APPLYER"
        ###### default values
        if !duplicate
          username = email ||sid || mobile
          status = "ACTIVE"
          password_digest = Digest::MD5.hexdigest("StaffBMTU23")
        end

        if staff_status == "Nghỉ việc" || !termination_date.empty?
          status = "INACTIVE"
          staff_status = "Nghỉ việc"
        else
          status = "ACTIVE"
        end


        user = {
          sid:sid,
          username:username,
          first_name: first_name,
          last_name: last_name,
          gender:gender,
          email:email,
          email1:email1,
          mobile: mobile,
          phone: phone,
          academic_rank:academic_rank,
          education:education,
          birthday: birthday,
          place_of_birth: place_of_birth,
          m_place_of_birth: m_place_of_birth,
          status:status,
          staff_status:staff_status,
          staff_type:staff_type,
          password_digest:password_digest,
          stype:stype,
          marriage:marriage,
          insurance_no:insurance_no,
          taxid:taxid,
          nationality:nationality,
          religion:religion,
          ethnic:ethnic,
          benefit_type:benefit_type,
          taxid:taxid,
          note:note,
          termination_date: termination_date || nil
        }

        user.compact!
        ###### update info to show
        if !user_update.nil?
          avatar_url = nil
          if !user_update.avatar.nil?
            avatar_url = request.base_url + "/mdata/hrm/" +  Mediafile.where("id = #{user_update.avatar}").first.file_name
          else
            avatar_url = nil
          end
          updates.push(user.merge({avatar_url:avatar_url, id: user_update.id,origin_name: "#{user_update.last_name} #{user_update.first_name}",origin_email: user_update.email,orgs:org_list_safe}))
          next
        end

        #####create new
        user_create = User.create(user);
        if user_create.nil?
          valids.push({
            line: "#{trans_line} #{stt.to_s}",
            message:"#{lib_translate("Can_not_create")}: #{tran_unknow}"
          })
          next
        else
          org_list_safe.each do |id|
            user_create.uorgs.create({
              user_id: user_create.id,
              organization_id: id
            })
          end
          user_create.applies.create({
            user_id:user_create.id,
            name: "#{last_name} #{first_name}",
            issued_date: user_create.created_at.strftime('%d-%m-%Y')
          })
          user_create.works.create({
            user_id: user_create.id
          })


        end
        creates.push(user_create)

      end
    rescue Exception => e
      had_error = true
      error_message = e.message
      tracking = e.backtrace.first.to_json.html_safe
      creates.each do |user_created|
        user_created.destroy
      end
    ensure
      result = {}
      if had_error
        result = {
          code:503,
          message:error_message,
          tracking:tracking
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

  def update_imports

    datas = []
    updateds = []
    errors = []
    file = params[:file]
    begin
      content = file.read.force_encoding("UTF-8")
      datas = []
      if !content.nil?
        datas = JSON.parse(content)
      end

      datas.each do |data|
        id = data["id"]
        orgs = data["orgs"]
        user = User.where(id: id).first
        if !user.nil?
          # remove unnecessary fields
          data_backup = data
          data.delete("username")
          data.delete("email")
          data.delete("id")
          data.delete("avatar_url")
          data.delete("origin_name")
          data.delete("origin_email")
          data.delete("orgs")

          user.update_attributes(data)
          # orgs handle
          user.uorgs.destroy_all
          orgs.each do |id|
            user.uorgs.create({
              user_id: user.id,
              organization_id: id
            })
          end

          if user.save
            updateds.push({id: id,data:data_backup})
          else
            errors.push({
              id: id,
              message: lib_translate("Error_when_update")
            })
          end

        else
          errors.push({
            id: id,
            message: "#{lib_translate("User_not_exits")} - #{data.to_json.html_safe}"
          })
        end
      end

    rescue => exception
      errors.push({
        id: "",
        message: "#{exception.message.to_json.html_safe}"
      })
    end

    respond_to do |format|
      format.js {
        render js: "#{{updateds:updateds,errors:errors}.to_json.html_safe}"
      }
    end
  end

  def upload_file
    file = params[:filepond]

    if !file.nil? && file != ""
        oFile = upload_document(file)
        if !oFile.nil?
            render json: {
                file: oFile
            }
        end
    end
  end

  def remove_file
      id = params[:id_mediafile]
      result = false
      oMediafile = Mediafile.where(id: id).first
      if !oMediafile.nil?
          file_path = "/data/hrm/#{oMediafile.file_name}"
          oMediafile.destroy
          if File.exist?(file_path)
              File.delete(file_path)
              result = true
          end
      end
      render json: {
          id: id,
          result: result
      }
  end

  def singnature_create
    begin
      idu = params[:idu]
      name = params[:name]
      isdefault = params[:isdefault] || false
      singnature_status = params[:singnature_status]
      note_singnature = params[:note_singnature]
      file = params[:filepond]
      media_id = nil
      if !file.nil? && file != ""
        media = upload_document(file)
        if !media.nil?
          media_id = media[:id]
        end
      end
      if (!media_id.nil? && media_id != "") && !idu.nil?
        if isdefault == "true"
          Signature.where(user_id: idu)&.update({
            isdefault: false,
          })
        end
        Signature.create({
          name: name,
          mediafile_id: media_id,
          user_id: idu,
          dtcreated: Time.now,
          isdefault: isdefault,
          status: singnature_status,
          note: note_singnature,
        })
        redirect_to user_details_path(id: idu , lang: session[:lang]), notice: lib_translate("Successfully")
      end
    rescue Exception => exception
      # position = exception.backtrace.to_json.html_safe.gsub("\`","")
      # message = exception.message.gsub("\`","")
      redirect_to user_details_path(id: idu , lang: session[:lang]), notice: lib_translate("Error")
    end

  end

  def singnature_update
    begin
      id = params[:id]
      idu = params[:idu]
      name = params[:name]
      isdefault = params[:isdefault] || false
      singnature_status = params[:singnature_status]
      note_singnature = params[:note_singnature]
      if !idu.nil?
        if isdefault == "true"
          Signature.where(user_id: idu)&.update({
            isdefault: false,
          })
        end
        Signature.where(id: id).first&.update({
          name: name,
          isdefault: isdefault,
          status: singnature_status,
          note: note_singnature,
        })
        redirect_to user_details_path(id: idu , lang: session[:lang]), notice: lib_translate("Successfully")
      end
    rescue Exception => e
      redirect_to user_details_path(id: idu , lang: session[:lang]), notice: lib_translate("Error")
    end

  end

  def singnature_change
    id = params[:id_signature]
    idu = params[:idu]
    if !idu.nil?
      Signature.where(user_id: idu)&.update({
        isdefault: false,
      })
      Signature.where(id: id).first&.update({
        isdefault: true,
      })
    end
  end
  def update_2fa_status
    twofa = params[:twofa]
    user_id = params[:user_id]
    user = User.where(id: user_id)

    if user.present?
      user.update(twofa: twofa)
      respond_to do |format|
        format.js { render js: "succesTwoFA('Cập nhật bảo mật 2 lớp thành công')"}
      end
    end
  end

  def import_user_contract
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
        begin
            # read from excel
            excel_datas = read_excel(file,2)
            excel_datas.each_with_index do |item,index|
                check_exist = false
                stt = (index + 3)
                ##
                # data
                    strUserSid = item[1] || ""
                    srtContractype = item[2] || ""
                    srtIssuedPlace = item[3] || ""
                    srtIssuedBy = item[4] || ""
                    srtIssuedDate = item[5] || ""
                    dateDtFrom = item[6] || ""
                    dateDtto = item[7] || ""
                    strStatus = item[8] || ""
                    strNote = item[9] || ""
                    if strUserSid != ""  &&  srtContractype != "" && dateDtFrom != ""  && srtIssuedPlace != ""
                        oUser = User.where(sid: strUserSid.strip).first
                        avatar_url = nil
                        if !oUser&.avatar.nil?
                            avatar_url = request.base_url + "/mdata/hrm/" +  Mediafile.where("id = #{oUser.avatar}").first.file_name
                        end
                        status = nil
                        if strStatus == "Có hiệu lực"
                            status = "ACTIVE"
                        end

                        if !oUser.nil?
                            updates.push({
                                avatar_url:avatar_url,
                                origin_name: "#{oUser.last_name} #{oUser.first_name}",
                                origin_email: oUser.email,
                                sid: oUser.sid,
                                user_id:oUser.id,
                                srtContractype: srtContractype,
                                srtIssuedBy: srtIssuedBy,
                                srtIssuedDate: srtIssuedDate,
                                dateDtFrom: dateDtFrom,
                                dateDtTo: dateDtFrom,
                                status: status,
                                strStatus: strStatus,
                                srtIssuedPlace: srtIssuedPlace,
                            })
                            creates.push({
                                user_id:oUser.id,
                                sid: oUser.sid,
                                avatar_url:avatar_url,
                                srtContractype: srtContractype,
                                srtIssuedBy: srtIssuedBy,
                                srtIssuedDate: srtIssuedDate,
                                dateDtFrom: dateDtFrom,
                                dateDtTo: dateDtFrom,
                                srtIssuedPlace: srtIssuedPlace,
                            })
                            onewContract = Contract.create({
                                user_id: oUser.id,
                                name: srtContractype,
                                issued_by: srtIssuedBy,
                                issued_date: srtIssuedDate,
                                issued_place: srtIssuedPlace,
                                dtfrom: dateDtFrom,
                                dtto: dateDtFrom,
                                status: status,
                                note: strNote
                            })
                            Contractdetail.create({
                                contract_id: onewContract.id,
                                name: onewContract.name
                            })
                            log_history(request.url, "Thêm","Import hợp đồng: #{onewContract.name}", "CẬP NHẬT THÔNG TIN HỢP ĐỒNG CỦA NHÂN SỰ  #{oUser.last_name} #{oUser.first_name} - #{oUser.sid}", @current_user.email)
                        end
                    else
                        valids.push({
                            line: "#{trans_line} #{stt.to_s}",
                            message:"Thiếu thông tin #{strUserSid}"
                        })
                        next
                    end
                end

        rescue Exception => e
            had_error = true
            error_message = e.message
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
                creates:creates,
                updates:updates,
                valids:valids,
                }
            end
            respond_to do |format|
                format.js {
                render js: "#{result.to_json.html_safe}"
                }
            end
        end
    end
    def download_template_import_contract
        file_path = Rails.root.join('public', 'assets', 'lib', 'ERP-MAU-IMPORT-HOP-DONG.xlsx')
        send_file(file_path, disposition: 'attachment')
    end

    def download_template_import_user
        file_path = Rails.root.join('public', 'assets', 'lib', 'ERP-MAU-IMPORT-NHAN-SU.xlsx')
        send_file(file_path, disposition: 'attachment')
    end

  # POST /uers/upload_image
  # Author: Dat Le
  # Date: 04/08/2025
  # Params:
  #   file        – file ảnh (multipart/form-data)
  #   user_id     –
  def upload_image
    file       = params[:file]
    user_id    = params[:user_id].presence || current_user.id
    doc_id     = params[:doc_id]

    return render json: { success: false, msg: 'missing_file' }, status: :unprocessable_entity if file.blank?

    # giới hạn 3 MB
    if file.size > 3.megabytes
      return render json: { success: false, msg: 'file_too_large' }, status: :unprocessable_entity
    end

    ActiveRecord::Base.transaction do
      mediafile = upload_document(file)
      mediafile_id = mediafile[:id]

      doc = if doc_id.present?
              Doc.find_by!(id: doc_id, user_id: user_id)
            else
              Doc.find_or_initialize_by(user_id: user_id, stype: 'USER_IMAGE')
            end

      doc.update!(
        mediafile_id: mediafile_id,
        udate:        Time.zone.now,
        status:       'ACTIVE'
      )

      render json: {
        success: true,
        doc_id:  doc.id,
        mediafile_id: mediafile_id,
        user_id: user_id
      }, status: :ok
    rescue ActiveRecord::RecordNotFound
      render json: { success: false, msg: 'doc_not_found' }, status: :not_found
    rescue => e
      Rails.logger.error e
      render json: { success: false, msg: 'upload_failed', detail: e.message },
             status: :internal_server_error
    end
  end
  private
end
