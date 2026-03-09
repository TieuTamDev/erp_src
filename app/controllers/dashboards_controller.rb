class DashboardsController < ApplicationController
  before_action :authorize, only: [:index]
  include NotifiesHelper
  include HolidayShared
  include StreamConcern
  before_action -> { prepare_holiday_data(session[:user_id]) }, only: [:index]
  def index
    @STYPE = STYPE.except("NOTIFICATION", "LEAVE_REQUEST")
    gon.notifies_index_path = notifies_index_path(
      is_handle: true,
      format: :json
    )
    @ids_departments_login = get_id_departments_login(session[:user_id])
    @next_nodes_vbt = []
    @next_nodes_vbd = []
    @departments = []
    @list_users_uorg = []
    users = []
    forms = nil
    leaders = []
    @users = []
    @department_leader_id = nil
    @department_leader_id_vbt = nil
    @users_leader_handle = nil
    @users_department_handle = nil
    @department_name_line_pb = []
    @department_name_line = []
    @mandoc= Mandoc.new
    @mandocfroms= Mandocfrom.where(status: "ACTIVE").order(:name)
    @mandocbooks = Mandocbook.where(status: "ACTIVE").order(:name)
    @mandoctypes = Mandoctype.where(status: "ACTIVE").order(:name)
    @mandocpriorities = Mandocpriority.where(status: "ACTIVE").order(:name)
    @mandoc= Mandoc.new
    # Đạt vũ code
    @newMandoc_dhandle = Mandocdhandle.new
    @oDeparment_login = get_departments_login(session[:user_id])

    oUserORG = Uorg.where(user_id: session[:user_id]).first
    if !oUserORG.nil?
      # Lấy danh sách phòng ban/nhân sự/đơn vị chủ quản
      @departments_mandoc = Department.where(organization_id: oUserORG.organization_id)
      @departments = Department.where(organization_id: oUserORG.organization_id)
      id_users_uorg = Uorg.where(organization_id: oUserORG.organization_id).pluck(:user_id)
      @list_users_uorg = User.where(id: id_users_uorg)
      @organization_name = oUserORG.organization&.name
      @organization_scode = oUserORG.organization&.scode

      # Sơ đồ văn bản đến
      oStreams =  Operstream.joins(:stream).select("streams.*").where("operstreams.organization_id = ? AND streams.scode = ?", oUserORG.organization_id, 'QLVB-VB-TOI')
      oStreams.each do |stream|
        @oDeparment_login.each do |department|
          @users = get_users_department_from_user_login(department.id, department.leader)
          @nodeLink = Node.where("stream_id = #{stream.id} AND nfirst IS NULL").first
          if !@nodeLink.nil?
              # don vi có trên sơ đồ
              if !department.nil?
                  login_pb = Department.where(id: department.id).first
                  if !login_pb.nil?
                      @organization_pb_login = login_pb.stype
                      sodo_pb = Department.where(id: @nodeLink.department_id).first
                      if !sodo_pb.nil?
                          @orrganization_pb_sodo = sodo_pb.stype
                          if !@result
                            if @organization_pb_login == @orrganization_pb_sodo
                                @result = true
                                @department_name_line_pb = Connect.where("stream_id = #{stream.id} AND nbegin = #{@nodeLink.department_id}").select(:nend, :forms)
                            else
                                @result = false
                            end
                          end
                      end
                  end
              end
          end
          nFirst = Node.where(stream_id:stream.id, nfirst: "YES").first
          if !nFirst.nil?
            @department_name_line = Connect.where("stream_id = #{stream.id} AND nbegin = #{nFirst.department_id}").select(:nend, :forms)
            @department_leader_id_vbt = Connect.where("stream_id = #{stream.id} AND nbegin = #{nFirst.department_id}").first.nend
            if !@department_leader_id_vbt.nil?
                positionjob_ids =  Positionjob.where("department_id = #{@department_leader_id_vbt}").pluck(:id)
                works = Work.where(positionjob_id: positionjob_ids ).pluck(:user_id)
                @users_leader_handle = User.select("first_name,last_name,id").where(id: works)

                positionjob_ids_by_scode = Positionjob.where("department_id = ? AND (scode LIKE ? OR scode LIKE ?)", @department_leader_id_vbt, "%TRUONG%", "%PHO%").pluck(:id)
                works_user = Work.where(positionjob_id: positionjob_ids_by_scode).pluck(:user_id)
                @users_department_handle = User.select("first_name,last_name,id").where(id: works_user)
            end
            nend_ids = Connect.where(stream_id: stream.id).where(nbegin: nFirst.department_id)
            node_ends = Node.where(stream_id: stream.id).where(department_id:nend_ids.pluck(:nend))
            node_ends.each do |node|
              users = []
              leaders = []
              node.department.works.each do |work|
                if !work&.user&.avatar.nil?
                  avatar_url = "#{request.base_url}/mdata/hrm/#{Mediafile.where("id = #{work.user.avatar}").first&.file_name}"
                end
                if work&.positionjob&.scode&.include?("TRUONG") || work&.positionjob&.scode&.include?("PHO") || work&.positionjob&.scode&.include?("GIAM-DOC") || work&.positionjob&.scode&.include?("CHU-TICH")
                  leaders.push(
                    id: work.user.id,
                    sid: work&.user&.sid,
                    name: "#{work&.user&.last_name} #{work&.user&.first_name}",
                    avatar:avatar_url,
                    email: work&.user&.email,
                    mobile: work&.user&.mobile,
                    positionjob_name: work&.positionjob&.name,
                  )
                else
                  users.push(
                    id: work.user.id,
                    sid: work&.user&.sid,
                    name: "#{work&.user&.last_name} #{work&.user&.first_name}",
                    avatar:avatar_url,
                    email: work&.user&.email,
                    mobile: work&.user&.mobile,
                    positionjob_name: work&.positionjob&.name,
                  )
                end
              end
              node.stream.connects.each do |connect|
                if connect.nend.to_i == node.department_id.to_i && connect.nbegin.to_i ==  nFirst.department_id.to_i
                  forms = connect.forms
                end
              end
                @next_nodes_vbt.push({
                  department_id: node.department.id,
                  department_name: node.department.name,
                  department_scode: node.department.scode,
                  users: users,
                  leaders: leaders,
                  forms: forms
                })
            end
          end
          node = Node.where(stream_id:stream.id).where(department_id:department.id).first
          if !node.nil?
            nend_ids = Connect.where(stream_id: stream.id).where(nbegin:department.id)
            node_ends = Node.where(stream_id: stream.id).where(department_id:nend_ids.pluck(:nend))
            node_ends.each do |node|
              users = []
              leaders = []
              node.stream.connects.each do |connect|
                if connect.nend.to_i == node.department_id.to_i && connect.nbegin.to_i ==  department.id.to_i
                  forms = connect.forms
                  oDeparmentLeader = Department.where(id: connect.nend).first
                  if !oDeparmentLeader.nil?
                      @department_user_id_BLD = oDeparmentLeader.id
                      department_leader_name = oDeparmentLeader.name
                      oPositionjobId = Positionjob.where(department_id: @department_user_id_BLD).pluck(:id)
                      if !oPositionjobId.nil?
                          leader_id = Work.where(positionjob_id: oPositionjobId).pluck(:user_id)
                          @oUserLeader = User.where(id: leader_id)
                      end
                  end
                end
              end
                @next_nodes_vbt.push({
                  department_id: node.department.id,
                  department_name: node.department.name,
                  department_scode: node.department.scode,
                  forms: forms
                })
            end
          end
          @next_nodes_vbt = @next_nodes_vbt.uniq
        end
      end
      # Sơ đồ văn bản đi
      oStreams =  Operstream.joins(:stream).select("streams.*").where("operstreams.organization_id = ? AND streams.scode = ?", oUserORG.organization_id, 'QLVB-VB-DI')
      oStreams.each do |stream|
        @users_leader_handle = nil
        last_department_id = Node.where("stream_id = #{stream.id}").last.department_id
        if !last_department_id.nil?
            @department_leader_id_handel = Connect.where("stream_id = #{stream.id} AND nend = #{last_department_id}").first.nend
            if !@department_leader_id_handel.nil?
            positionjob_ids =  Positionjob.where("department_id = #{@department_leader_id_handel}").pluck(:id)
            works = Work.where(positionjob_id: positionjob_ids ).pluck(:user_id)
            @users_leader_handle = User.select("first_name,last_name,id").where(id: works)
            # .where(organization_id:organization_id)
            end
        end
        @oDeparment_login.each do |department|
          nFirst = Node.where(stream_id:stream.id, nfirst: "YES").first
          if !nFirst.nil?
            @department_leader_id = Connect.where("stream_id = #{stream.id} AND nbegin = #{nFirst.department_id}").first.nend
            nend_ids = Connect.where(stream_id: stream.id).where(nbegin: nFirst.department_id)
            node_ends = Node.where(stream_id: stream.id).where(department_id:nend_ids.pluck(:nend))
            node_ends.each do |node|
              users = []
              leaders = []
              node.department.works.each do |work|
                if !work&.user&.avatar.nil?
                  avatar_url = request.base_url + "/mdata/hrm/" +  Mediafile.where("id = #{work.user.avatar}").first&.file_name
                end
                if work&.positionjob&.scode&.include?("TRUONG") || work&.positionjob&.scode&.include?("PHO") || work&.positionjob&.scode&.include?("GIAM-DOC") || work&.positionjob&.scode&.include?("CHU-TICH")
                  leaders.push(
                    id: work.user.id,
                    sid: work&.user&.sid,
                    name: "#{work&.user&.last_name} #{work&.user&.first_name}",
                    avatar:avatar_url,
                    email: work&.user&.email,
                    mobile: work&.user&.mobile,
                    positionjob_name: work&.positionjob&.name,
                  )
                else
                  users.push(
                    id: work.user.id,
                    sid: work&.user&.sid,
                    name: "#{work&.user&.last_name} #{work&.user&.first_name}",
                    avatar:avatar_url,
                    email: work&.user&.email,
                    mobile: work&.user&.mobile,
                    positionjob_name: work&.positionjob&.name,
                  )
                end
              end
              node.stream.connects.each do |connect|
                if connect.nend.to_i == node.department_id.to_i && connect.nbegin.to_i ==  nFirst.department_id.to_i
                  forms = connect.forms
                end
              end
                @next_nodes_vbd.push({
                  department_id: node.department.id,
                  department_name: node.department.name,
                  department_scode: node.department.scode,
                  users: users,
                  leaders: leaders,
                  forms: forms
                })
            end
          end
          node = Node.where(stream_id:stream.id).where(department_id:department.id).first
          if !node.nil?
            nend_ids = Connect.where(stream_id: stream.id).where(nbegin:department.id)
            node_ends = Node.where(stream_id: stream.id).where(department_id:nend_ids.pluck(:nend))
            node_ends.each do |node|
              node.stream.connects.each do |connect|
                if connect.nend.to_i == node.department_id.to_i && connect.nbegin.to_i ==  department.id.to_i
                  forms = connect.forms
                end
              end
                @next_nodes_vbd.push({
                  department_id: node.department.id,
                  department_name: node.department.name,
                  department_scode: node.department.scode,
                  forms: forms
                })
            end
          end
          @next_nodes_vbd = @next_nodes_vbd.uniq
        end
      end
    end

    session[:mandoc_per_page] = params[:mandoc_per_page]&.to_i || 5
    session[:mandoc_page] = params[:mandoc_page]&.to_i || 1
    session[:mandoc_search] = params[:mandoc_search] || ''
    mandocOffset = (session[:mandoc_page] - 1) * session[:mandoc_per_page]
    @mandoc_total_records = Mandocuhandle.where(user_id: session[:user_id], status: "CHUAXULY").joins(mandocdhandle: :mandoc).where("mandocs.contents LIKE ? ", "%#{session[:mandoc_search]}%").count
    session[:mandoc_total_pages] = (@mandoc_total_records.to_f / session[:mandoc_per_page].to_f).ceil
    @Mandoc = Mandocuhandle.where(user_id: session[:user_id], status: "CHUAXULY").joins(mandocdhandle: :mandoc).select("mandocdhandles.id as d_id, mandocdhandles.department_id as d_department_id, mandocdhandles.srole as d_srole, mandocdhandles.deadline as d_deadline, mandocdhandles.contents as d_contents, mandocdhandles.status as d_status, mandocuhandles.id as u_id, mandocuhandles.user_id as u_user_id, mandocuhandles.srole as u_srole, mandocuhandles.deadline as u_deadline, mandocuhandles.contents as u_contents, mandocuhandles.status as u_status, mandocuhandles.notes as u_notes, mandocuhandles.sread as u_sread, mandocuhandles.received_at as u_received_at , mandocuhandles.sothers as u_sothers, mandocs.*").where("mandocs.contents LIKE ? ", "%#{session[:mandoc_search]}%").order(created_at: :desc).limit(session[:mandoc_per_page]).offset(mandocOffset)
    leave_request()
    handle_request()
    work =  Work.where(user_id: session[:user_id]).where.not(positionjob_id: nil).first
    @department_id_leave = work&.positionjob&.department&.id
    # ===================== Code cũ =======================
        # Holiday
        session[:h_per_page] = params[:h_per_page]&.to_i || 5
        session[:h_page] = params[:h_page]&.to_i || 1
        session[:h_search] = params[:h_search] || ''
        holidayOffset = (session[:h_page] - 1) * session[:h_per_page]
        @h_total_records = Holiday.where(status: "ACTIVE", created_at: (DateTime.now - 30.day)..DateTime.now).count
        session[:h_total_pages] = (@h_total_records.to_f / session[:h_per_page].to_f).ceil
        @holidays = Holiday.where(status: "ACTIVE", created_at: (DateTime.now - 30.day)..DateTime.now).order(created_at: :desc).limit(session[:h_per_page]).offset(holidayOffset)


        # End Holiday
        session[:d_per_page] = params[:d_per_page]&.to_i || 5
        session[:d_page] = params[:d_page]&.to_i || 1
        session[:d_search] = params[:d_search] || ''
        disOffset = (session[:d_page] - 1) * session[:d_per_page]
        @d_total_records = Discipline.where(status: "ACTIVE", mdate: (DateTime.now - 30.day)..DateTime.now).joins(:user).where("email LIKE ? OR sid = ? OR concat(last_name,' ',first_name) LIKE ? OR name LIKE ?", "%#{session[:d_search]}%", "#{session[:d_search]}", "%#{session[:d_search]}%", "%#{session[:d_search]}%").count
        session[:d_total_pages] = (@d_total_records.to_f / session[:d_per_page].to_f).ceil
        @oDiscipline = Discipline.where(status: "ACTIVE", mdate: (DateTime.now - 30.day)..DateTime.now).joins(:user).where("email LIKE ? OR sid = ? OR concat(last_name,' ',first_name) LIKE ? OR name LIKE ?", "%#{session[:d_search]}%", "#{session[:d_search]}", "%#{session[:d_search]}%", "%#{session[:d_search]}%").order(created_at: :desc).limit(session[:d_per_page]).offset(disOffset)
        #nhân sự mới nhất

        # lay danh sach nhan su co sinh nhat 15 ngay toi
        session[:u_per_page] = params[:u_per_page]&.to_i || 5
        session[:u_page] = params[:u_page]&.to_i || 1
        session[:u_search] = params[:u_search] || ''
        newUserOffset = (session[:u_page] - 1) * session[:u_per_page]
        @u_total_records = User.where(status: "ACTIVE", created_at: (DateTime.now - 30.day)..DateTime.now).where("concat(last_name, ' ', first_name) LIKE ? OR email LIKE ? OR sid = ?", "%#{session[:u_search]}%","%#{session[:u_search]}%", "#{session[:u_search]}").count
        session[:u_total_pages] = (@u_total_records.to_f / session[:u_per_page].to_f).ceil
        @newUser = User.where(status: "ACTIVE", created_at: (DateTime.now - 30.day)..DateTime.now).where("concat(last_name, ' ', first_name) LIKE ? OR email LIKE ? OR sid = ?", "%#{session[:u_search]}%","%#{session[:u_search]}%", "#{session[:u_search]}").order(created_at: :desc).limit(session[:u_per_page]).offset(newUserOffset)

        currentYear = Time.now.utc.to_date.year.to_i
        session[:b_per_page] = params[:b_per_page]&.to_i || 5
        session[:b_page] = params[:b_page]&.to_i || 1
        session[:b_search] = params[:b_search] || ''
        birtOffset = (session[:b_page] - 1) * session[:b_per_page]
        @b_total_records = User.where("DATEDIFF(concat('#{currentYear}-' ,DATE_FORMAT(birthday,'%m-%d')) , CURDATE()) < 15 && DATEDIFF(concat('#{currentYear}-' ,DATE_FORMAT(birthday,'%m-%d')) , CURDATE()) >= 0").where("concat(last_name, ' ', first_name) LIKE ? OR email LIKE ? OR sid = ?", "%#{session[:b_search]}%","%#{session[:b_search]}%", "#{session[:b_search]}").count
        session[:b_total_pages] = (@b_total_records.to_f / session[:b_per_page].to_f).ceil
        @userBirthday = User.where("DATEDIFF(concat('#{currentYear}-' ,DATE_FORMAT(birthday,'%m-%d')) , CURDATE()) < 15 && DATEDIFF(concat('#{currentYear}-' ,DATE_FORMAT(birthday,'%m-%d')) , CURDATE()) >= 0").where("concat(last_name, ' ', first_name) LIKE ? OR email LIKE ? OR sid = ?", "%#{session[:b_search]}%","%#{session[:b_search]}%", "#{session[:b_search]}").order(created_at: :desc).limit(session[:b_per_page]).offset(birtOffset)

        # tính % độ tuổi của nhân sự H-Anh
        # Tính độ tuổi của từng user và phân loại theo giới tính và % độ tuổi trong mảng age_ranges
        today = Date.today
        ageMale = User.where(gender: 0)
        ageFemale= User.where(gender: 1)
        arr_male=[]
        arr_female=[]
        ageMale.each do |user|
            birthday = user.birthday
            if birthday.present?              
              age_male = today.year - birthday.year - ((today.month > birthday.month || (today.month == birthday.month && today.day >= birthday.day)) ? 0 : 1)
              arr_male.push(age_male)
            end
        end
        ageFemale.each do |user|
            birthday = user.birthday
            if birthday.present?             
              age_female = today.year - birthday.year - ((today.month > birthday.month || (today.month == birthday.month && today.day >= birthday.day)) ? 0 : 1)
              arr_female.push(age_female)
            end
        end
        age_ranges = [[18, 20], [21, 24], [25, 29], [30, 34], [35, 39], [40, 44], [45, 49], [50, 54], [55, 59], [60, 64]]
        # Tính tổng số lượng age_male và age_female
        @age_male_array = []
        @age_female_array = []

        age_ranges.each_with_index do |range, index|
          @age_male_array << calculate_age_percentages([range], arr_male).first
        end
        age_ranges.each_with_index do |range, index|
          @age_female_array << -calculate_age_percentages([range], arr_female).first
        end



        # bieu do bien dong nhan su
        @month_user_change_list = [lib_translate('Jan'),lib_translate('Feb'),lib_translate('Mar'),lib_translate('Apr'),lib_translate('May'),lib_translate('Jun'),lib_translate('Jul'),lib_translate('Aug'),lib_translate('Sep'),lib_translate('Oct'),lib_translate('Nov'),lib_translate('Dec')]
        @new_user_change_count = [0,0,0,0,0,0,0,0,0,0,0,0]
        @old_user_change_count = [0,0,0,0,0,0,0,0,0,0,0,0]

        list_new_user = User.select('dtfrom, user_id, first_name, last_name,  MAX(dtfrom) as nearest_day').joins(:contracts).where('extract(year from dtfrom) = ?', Time.now.strftime("%Y")).group(:user_id,:dtfrom).order("dtfrom ASC")
        list_user_discipline = User.select('mdate, user_id, first_name, last_name').joins(:disciplines).where('extract(year from mdate) = ? AND disciplines.stype = 4', Time.now.strftime("%Y")).order("mdate ASC")


        (1..12).each do |i|
          list_new_user.each do |user|
            if i == user.nearest_day.strftime("%m").to_i
              @new_user_change_count[i-1] = @new_user_change_count[i-1] + 1
            end
          end
            list_user_discipline.each do |user|
              if i == user.mdate.strftime("%m").to_i
                @old_user_change_count[i-1] = @old_user_change_count[i-1] + 1
              end
            end
        end

        # HA: bieu do phan bo nhan su
        @user_contact_near = Contract.select("MAX(dtfrom) AS dtfrom,dtto, user_id, concat(last_name,' ', first_name) as name, academic_rank").joins(:user).group(:user_id,:dtto);
        @academics_rank = User.select('academic_rank as rank_name').group(:academic_rank)
        # HA : end
        @user = User.where(id: session[:user_id]).first
        if @user.nil?
            return oDepartment
        end
        works = @user.works
        if !works.nil?
            works.each do |work|
                if !work.positionjob.nil? && !work.positionjob.department.nil?
                    oDepartment = work.positionjob.department
                end
            end
        end


        @mandocuhandles= Mandocuhandle.where(user_id: session[:user_id], sread:"KHONG").where.not(status: "DAXULY").order("created_at DESC")
        @mandocdhandle_sp=[]
        @mandocdhandles=[]

        mandocs = Mandoc.where.not(status: "SUCCESS").where(status: "INPROGRESS")
        user = User.where(id:session[:user_id]).first

        mandocs.each do |mandoc|

          if mandoc.sfrom.nil?
            @where= mandoc.mdepartment
            @url= mandocs_outgoing_index_path()
            @title=lib_translate('Document_go')
          else
            @where = mandoc.sfrom
            @url= mandocs_incoming_index_path()
            @title=lib_translate('Document_to')
          end

          # if  mandoc.signed_by == "#{user.last_name} #{user.first_name}" || mandoc.created_by == "#{user.last_name} #{user.first_name}"
          #   @mandocdhandles.push(mandoc.mandocdhandles.last)
          # end
          mandocdhandle_sp = Mandocdhandle.where(mandoc_id: mandoc.id, srole: "PHOIHOPXL").first
          if  !mandocdhandle_sp.nil?
            positionjobs = Positionjob.where(department_id: mandocdhandle_sp.department_id)
            if  !positionjobs.nil?
              positionjobs.each do |positionjob|
                works = Work.where(positionjob_id: positionjob.id)
                if  !works.nil?
                  works.each do  |work|
                    if work.user_id == session[:user_id]
                      @mandocdhandle_sp.push(mandocdhandle_sp)
                    end
                  end
                end
              end
            end
          end
        end

        @notifications = (@mandocdhandle_sp + @mandocdhandles + @mandocuhandles)
        @snotifies = Snotice.where(user_id: session[:user_id]).where(isread: false).order("created_at DESC")

    # ===================== Code cũ =======================
  end
  def leave_request
    @departments, @data_tab, total_items, @page, @per_page, @leader_count, @staff_count = fetch_leave_data(params, current_user, "INDEX")
    @total_pages = (total_items / @per_page.to_f).ceil
  end
  def handle_request
    @data = []
    @data_tab_2 = []
    @data_tab_3 = []
    @depart = nil
    @faculty = nil
    @check_button = nil
    per_page = (params[:per_page] || 10).to_i
    page = (params[:page] || 1).to_i
    offset = (page - 1) * per_page
    list_uhan = Mandocuhandle.joins(mandoc: :holpro).where(user_id: session[:user_id], status: "CHUAXULY" ).where.not(holpros: { id: nil, status: "TEMP" })
    departments = fetch_leaf_departments_by_user(session[:user_id])

    oUserORG = Uorg.find_by(user_id: session[:user_id])
    organization_id = oUserORG.organization_id
    streams = Stream.joins("INNER JOIN operstreams ON operstreams.stream_id = streams.id")
                      .where(operstreams: { organization_id: organization_id })
                      .where("streams.scode LIKE ?", "%DUYET-PHEP-BUH%").first
    stream_id = streams&.id
    check_button = "none"
    if departments.present? && stream_id.present?
      department = departments.first
      if department&.parents.present?
        depart = department.parents
        faculty = department.faculty
      else
        exit_node = Node.where(stream_id:stream_id).where(department_id: department.id).first
        if exit_node.present?
          department_id = department.id
          faculty = department.faculty
          scode = "BOARD-APPROVE"
          check_button ="FINAL_HANDLE"
        else
          first_node = Node.where(stream_id: stream_id, nfirst: "YES").first
          department_id = first_node.department_id
          faculty = department.faculty
          scode = "HR-APPROVED"
          check_button ="FIRST_HANDLE"
        end
        result = stream_connect_by_status("DUYET-PHEP-BUH", scode)
        depart = result&.first&.dig(:next_department_id)
      end
      @depart = depart
      @faculty = faculty
      @check_button = check_button
    end
    raw_data = []
    list_uhan.each do |item|
      mandocdhandle = Mandocdhandle.find_by(id: item.mandocdhandle_id)
      mandoc = Mandoc.find_by(id: mandocdhandle&.mandoc_id)
      holpro = Holpro.find_by(id: mandoc&.holpros_id)
      
      holiday = Holiday.find_by(id: holpro&.holiday_id)
      details = get_handle_leave_details(mandoc&.holpros_id)
      user_id = holiday&.user_id
      full_name, sid = get_user_info(user_id)
      full_name_handler, _ = get_user_info(session[:user_id])
      status =  if item.status == "CHUAXULY"
                  "Chưa xử lý"
                else
                  "Đã xử lý"
                end
      department_user = fetch_leaf_departments_by_user(user_id)
      department = department_user.first
      department_name = department&.name
      department_id = department&.id
      raw_data.push(
        user_id: user_id,
        uhandle_id: item.id,
        holpros_id: mandoc&.holpros_id,
        sender: full_name, 
        handler: full_name_handler, 
        department: department_name,
        department_id: department_id,
        time: time_ago_in_custom_format(item.created_at),
        sender_sid: sid,
        status: status,
        details: details,
        note: item.notes
        )
    end
    if params[:search].present?
      keyword = params[:search].strip.downcase
      raw_data.select! do |record|
        record[:sender].to_s.downcase.include?(keyword) ||
        record[:sender_sid].to_s.downcase.include?(keyword)
      end
    end

    if params[:department_id].present?
      raw_data.select! do |record|
        record[:department_id].to_s == params[:department_id].to_s
      end
    end
    @total_items = raw_data.size
    @total_pages = (@total_items / per_page.to_f).ceil
    @page = page
    @per_page = per_page
    @data = raw_data.slice(offset, per_page)
  end
  def time_ago_in_custom_format(time)
    return '' if time.nil?

    seconds_diff = Time.current - time

    days = (seconds_diff / 1.day).to_i
    hours = ((seconds_diff % 1.day) / 1.hour).to_i
    minutes = ((seconds_diff % 1.hour) / 1.minute).to_i

    if days > 0
      "#{days} ngày #{hours} giờ"
    elsif hours > 0
      minutes > 0 ? "#{hours} giờ #{minutes} phút" : "#{hours} giờ"
    else
      "#{minutes} phút"
    end
  end
  def list_user_leave
    @departments, @data_tab, total_items, @page, @per_page, @leader_count, @staff_count = fetch_leave_data(params, current_user, "LOAD")
    @user_leave = params[:user_leave]
    @daterange = params[:daterange]
    @total_pages = (total_items / @per_page.to_f).ceil
  end

  def fetch_leave_data(params, current_user, action)
    from_date, to_date = parse_daterange(params[:daterange])
    uorgs = current_user.uorgs

    # 1. Xác định tổ chức & danh sách phòng ban
    if uorgs.size > 1
      organization_id = Organization.find_by(scode: "BMTU")&.id || Organization.find_by(scode: "BMU")&.id
      uorg_scode      = "BMU"
    else
      organization_id = uorgs.first&.organization&.id
      code_org = Organization.find_by(id: organization_id)
      if code_org == "BMTU" || code_org == "BMU"
        uorg_scode = "BMU"
      else
        uorg_scode = "BUH"
      end
    end

    departments = case uorg_scode
                  when "BUH"
                    Department.where(organization_id: Organization.where(scode: "BUH")).where.not(name: "Quản lý ERP")
                  when "BMU"
                    Department.where(organization_id: Organization.where(scode: %w[BMU BMTU])).where.not(name: "Quản lý ERP")
                  end

    # 2. Lấy danh sách user thuộc phòng ban được quyền xem    
    department_ids   = []
    department_user = fetch_leaf_departments_by_user(session[:user_id])

    status_search = params[:status]
    department = department_user.first
    department_id = department&.id
    check_faculty = department&.faculty
    all_department_ids = fetch_all_sub_department_ids([department_id])
    check_view = Work.joins(stask: { accesses: :resource })
                                    .where(
                                      resources: { scode: "VIEW-ALL-REQUEST" },
                                      works:     { user_id: session[:user_id] },
                                      accesses:  { permision: "ADM" }
                                    )
                                    .exists?
    if (uorg_scode == "BUH" && ["PTCHC(BUH)", "BGD(BUH)"].include?(check_faculty)) || check_view
      department_ids      = Department.where(organization_id: organization_id).pluck(:id)
      child_departments   = Department.where(parents: department_ids).pluck(:id)
      all_departments     = department_ids + child_departments
      list_user_ids = Work.where(positionjob_id: Positionjob.where(department_id: all_departments))
                      .distinct
                      .pluck(:user_id)
    else
      list_user_ids = Work.where(positionjob_id: Positionjob.where(department_id: all_department_ids).pluck(:id))
                      .distinct
                      .pluck(:user_id)
    end

    leadership_keywords = /trưởng|phó|giám đốc|hiệu|phụ trách khoa nội tim mạch|cố vấn chuyên môn/i
    today               = Date.current
    raw_data = []
    list_user_ids = list_user_ids.uniq
    list_user_ids.each do |user|
      full_name, sid = get_user_info(user)
      positionjob_name, department_name = fetch_position_and_department_name(user)
      if positionjob_name.present?
        check_nhom = positionjob_name.match?(leadership_keywords) ? "Lãnh đạo" : "Nhân viên"
        nhom = check_nhom
      else
        nhom = ""
        check_nhom = ""
      end


      detail_rows = []
      oHol = Holiday.find_by(user_id: user, year: Time.current.year)

      if oHol.present?
        list_hols = Holpro.where(
          holiday_id: oHol.id,
          status: ["DONE", "CANCEL-DONE"]
        ).where.not(status: "TEMP")

        list_hols.each do |hol|
          # truyền from_date/to_date vào
          get_leave_details(hol.id, from_date: from_date, to_date: to_date).each do |d|
            d[:days].each do |day_info|
              detail_rows << {
                hinh_thuc_nghi: d[:leave_type],
                thoi_gian_nghi: day_info[:display],
                tong_so_ngay: day_info[:total_days]
              }
            end
          end
        end
      end
      # Chỉ thêm vào raw_data nếu có detail_rows
      if detail_rows.any?
        raw_data << {
          nhom: nhom,
          sender: full_name,
          sender_sid: sid.to_s,
          pos_name: positionjob_name.to_s,
          department: department_name,
          user_id: user,
          created_at: oHol&.created_at || Time.current,
          detail_rows: detail_rows,
          check_nhom: check_nhom
        }
      end
    end

    # 4. Lọc theo từ khóa tìm kiếm & vai trò
    if params[:search_leave].present?
      keyword = params[:search_leave].strip.downcase
      raw_data.select! { |r| r[:sender].downcase.include?(keyword) || r[:sender_sid].downcase.include?(keyword) }
    end

    if params[:user_leave].present?
      raw_data.select! do |r|
        if params[:user_leave] == 'LANH-DAO'
          r[:pos_name].match?(leadership_keywords)
        elsif params[:user_leave] == 'NHAN-VIEN'
          !r[:pos_name].match?(leadership_keywords)
        else
          true
        end
      end
    end

    # 5. Thống kê lãnh đạo / nhân viên
    unique_users  = raw_data.map { |r| [r[:user_id], r[:pos_name]] }.uniq
    leader_count = unique_users.count { |_, p| p.to_s.match?(leadership_keywords) }

    staff_count   = unique_users.size - leader_count

    # 6. Phân trang & trả về
    raw_data.sort_by { |r| -r[:created_at].to_i }.yield_self do |data|
      page     = (params[:page]     || 1).to_i
      per_page = (params[:per_page] || 10).to_i
      offset   = (page - 1) * per_page

      [
        departments,               # 0 - Danh sách phòng ban
        data.slice(offset, per_page) || [], # 1 - Dữ liệu trang hiện tại
        data.size,                 # 2 - Tổng bản ghi
        page,                      # 3 - Số trang hiện tại
        per_page,                  # 4 - Số bản ghi / trang
        leader_count,              # 5 - Lãnh đạo
        staff_count                # 6 - Nhân viên
      ]
    end
  end
  def get_user_info(user_id)
    oUser = User.where(id: user_id).first
    full_name = ""
    sid = ""
    if oUser.present?
      full_name = "#{oUser.last_name} #{oUser.first_name}"
      sid = oUser.sid
    end
    [full_name, sid]
  end
  def get_leave_details(holpros_id, from_date: nil, to_date: nil)
    holpros = Holpro.find_by(id: holpros_id)
    return [] unless holpros

    holpros_details = Holprosdetail.where(holpros_id: holpros.id)

    label_map = {
      "NGHI-PHEP" => "Nghỉ phép",
      "NGHI-KHONG-LUONG" => "Nghỉ không lương",
      "NGHI-CHE-DO-BAO-HIEM-XA-HOI" => "Nghỉ BHXH",
      "NGHI-CDHH" => "Nghỉ chế độ (Hiếu/Hỷ)"
    }

    grouped_by_type = holpros_details.group_by(&:sholtype)

    grouped_by_type.map do |stype, records|
      # Parse tất cả chi tiết
      parsed_dates = records.flat_map do |record|
        record.details.to_s.split("$$$").map do |seg|
          date_str, session = seg.split("-")
          begin
            d = Date.strptime(date_str, "%d/%m/%Y")
            {
              date: d,
              session: (session || "ALL").upcase
            }
          rescue
            nil
          end
        end
    end.compact
    # 👉 Filter theo range nếu có
    if from_date && to_date
      parsed_dates.select! { |h| h[:date] >= from_date && h[:date] <= to_date }
    end
    parsed_dates = parsed_dates.uniq.sort_by { |h| h[:date] }
    # Tách ALL và AM/PM
    all_days = parsed_dates.select { |h| h[:session] == "ALL" }
    half_days = parsed_dates.reject { |h| h[:session] == "ALL" }
    # Gom ALL liên tiếp thành khoảng
    ranges = []
    all_days.each do |h|
      if ranges.empty? || ranges.last.last[:date] + 1 != h[:date]
        ranges << [h]
      else
        ranges.last << h
      end
    end
    formatted_entries = []
    # Thêm các khoảng ALL
    ranges.each do |range|
      if range.size > 1
        formatted_entries << {
          display: "Từ #{range.first[:date].strftime('%d/%m/%Y')} đến #{range.last[:date].strftime('%d/%m/%Y')}",
          total_days: range.size
        }
      else
        formatted_entries << {
          display: "#{range.first[:date].strftime('%d/%m/%Y')}",
          total_days: 1
        }
      end
    end
    # Thêm các ngày nửa buổi
    half_days.each do |h|
      buoi = h[:session] == "AM" ? "(buổi sáng)" : "(buổi chiều)"
      formatted_entries << {
        display: "#{h[:date].strftime('%d/%m/%Y')} #{buoi}",
        total_days: 0.5
        }
      end
      {
        leave_type: label_map[stype] || stype.to_s.titleize,
        days: formatted_entries
      }
    end
  end
  def get_handle_leave_details(holpros_id)
    holpros = Holpro.find_by(id: holpros_id)
    return [] unless holpros
    holpros_details = Holprosdetail.where(holpros_id: holpros.id)
    label_map = {
      "NGHI-PHEP" => "Nghỉ phép",
      "NGHI-KHONG-LUONG" => "Nghỉ không lương",
      "NGHI-CHE-DO-BAO-HIEM-XA-HOI" => "Nghỉ BHXH",
      "NGHI-CDHH" => "Nghỉ chế độ (Hiếu/Hỷ)"
    }
    grouped_by_type = holpros_details.group_by(&:sholtype)

    grouped_by_type.map do |stype, records|
      all_dates = records.flat_map do |record|
        record.details.to_s.split("$$$").map do |seg|
          Date.strptime(seg.split("-").first, "%d/%m/%Y") rescue nil
        end
      end.compact.uniq.sort
      ranges = []
      all_dates.each do |date|
        if ranges.empty? || ranges.last.last + 1 != date
          ranges << [date]
        else
          ranges.last << date
        end
      end
      formatted_ranges = ranges.map do |range|
        if range.size > 1
          "Từ #{range.first.strftime('%d/%m/%Y')} đến #{range.last.strftime('%d/%m/%Y')}"
        else
          range.first.strftime('%d/%m/%Y')
        end
      end
      {
        leave_type: label_map[stype] || stype.to_s.titleize,
        days: formatted_ranges
      }
    end
  end

  def extract_dates_from_details_date_range(details)
    return [] if details.blank?

    details.split('$$$').map do |item|
      date_str = item.split('-').first&.strip
      begin
        Date.strptime(date_str, "%d/%m/%Y")
      rescue
        nil
      end
    end.compact
  end
  def parse_daterange(daterange)
    if daterange.blank?
      today = Date.today
      return [today, today.next_month]
    end

    date_parts = daterange.split(/ đến | - | to /).map(&:strip)

    begin
      from_date = Date.strptime(date_parts[0], "%d/%m/%Y")
      to_date   =
        if date_parts.size > 1 && !date_parts[1].empty?
          Date.strptime(date_parts[1], "%d/%m/%Y")
        else
          # ⚡ Nếu chỉ có 1 ngày => lấy đúng ngày đó
          from_date
        end
    rescue ArgumentError
      return [nil, nil]
    end

    [from_date, to_date]
  end

  def fetch_leaf_departments_by_user(user_id)
    positionjob_ids = Work.where(user_id: user_id)
                          .where.not(positionjob_id: nil)
                          .pluck(:positionjob_id)

    department_ids = Positionjob.where(id: positionjob_ids).pluck(:department_id)

    departments = Department.where(id: department_ids).where.not(parents: [nil, ""])

    if departments.present?
      parent_ids = departments.map(&:parents).compact.map(&:to_i)
      departments.reject { |dept| parent_ids.include?(dept.id) }
    else
      Department.where(id: department_ids).limit(1)
    end
  end
  def fetch_all_sub_department_ids(root_ids)
      all_ids = root_ids.dup
      queue = root_ids.dup

      while queue.any?
        current_id = queue.shift
        children = Department.where(parents: current_id).pluck(:id)
        queue.concat(children)
        all_ids.concat(children)
      end

      all_ids.uniq
  end
  def fetch_position_and_department_name(user_id)
    department_user = fetch_leaf_departments_by_user(user_id)
    return [nil, nil] if department_user.blank?

    department = department_user.first
    return [nil, nil] if department.nil?

    # lưu lại tên của department con đầu tiên
    child_name = department.name  

    # tìm department gốc (cha cao nhất có parents = nil)
    parent_department = department
    while parent_department&.parents.present?
      parent_department = Department.find_by(id: parent_department.parents)
    end

    # nếu có cha gốc thì format "cha - con", nếu không thì chỉ lấy tên hiện tại
    if parent_department && parent_department.id != department.id
      department_name = "#{parent_department.name} - #{child_name}"
    else
      department_name = child_name
    end

    # tìm lại positionjob_name dựa theo department của user
    work = Work.includes(:positionjob)
              .where(user_id: user_id)
              .where.not(positionjob_id: nil)
              .detect { |w| w.positionjob&.department_id == department.id }

    positionjob_name = work&.positionjob&.name

    [positionjob_name, department_name]
  end
 

  def calculate_total_days(day_str)
    if day_str.start_with?("Từ")
      parts = day_str.scan(/\d{2}\/\d{2}\/\d{4}/)
      from_date = Date.strptime(parts[0], "%d/%m/%Y")
      to_date   = Date.strptime(parts[1], "%d/%m/%Y")
      (to_date - from_date).to_i + 1
    else
      1
    end
  end

  def get_user_info_leave(user_id)
    oUser = User.where(id: user_id).first
    full_name = ""
    sid = ""
    phone = ""
    if oUser.present?
      full_name = "#{oUser.last_name} #{oUser.first_name}"
      sid = oUser.sid
      raw_phone = oUser.phone.presence || oUser.mobile
      phone = raw_phone.to_s.sub(/^'/, "")
    end
    [full_name, sid, phone]
  end

  def get_departments_login(user_id)
      oDepartment = []
      @user = User.where(id: user_id).first
      if @user.nil?
          return oDepartment
      end
      works = @user.works
      if !works.nil?
          works.each do |work|
              if !work.positionjob.nil? && !work.positionjob.department.nil?
                  oDepartment.push(work.positionjob.department)
              end
          end
      end
      oDepartment
  end
  def get_id_departments_login(user_id)
      ids_department = []
      @user = User.where(id: user_id).first
      if @user.nil?
          return ids_department
      end
      works = @user.works
      if !works.nil?
          works.each do |work|
              if !work.positionjob.nil? && !work.positionjob.department.nil?
                  ids_department.push(work.positionjob&.department&.id)
              end
          end
      end
      ids_department
  end

  def get_users_department_from_user_login(id_department, leader)
      oUsers = []
      email = User.where(id: session[:user_id]).first.email
      id_positionjobs = Positionjob.where(department_id: id_department).pluck(:id)
      if !id_positionjobs.nil?
          id_users = Work.where(positionjob_id: id_positionjobs).pluck(:user_id)
          if !id_users.nil?
              oUsers = User.where.not(email: leader).where.not(email: email).where(id: id_users)
          end
      end
      oUsers
  end















































  def check_age_gender

  end

  def options_table

  end

  def personnelbymonth
    status_user = params[:status_dashboard]

    month = params[:month]
    year = params[:year]

    list_new_user = User.select('dtfrom, user_id, first_name, last_name,  MAX(dtfrom) as nearest_day').joins(:contracts).where('extract(year from dtfrom) = ? AND extract(month from dtfrom) =?', year, month).group(:user_id,:dtfrom).order("dtfrom ASC")

    list_user_discipline = User.select('mdate, user_id, first_name, last_name').joins(:disciplines).where('extract(year from mdate) = ? AND extract(month from mdate) = ? AND disciplines.stype = 4', year, month).order("mdate ASC")

    data = []
    (1..31).each do |i|
      data.push({day: i,new_count:0,old_count:0})


      # danh sach nhan vien nghi viec

    end

     #  danh sach nhan vien moi
    data.each do |item|

      list_new_user.each do |user|
        if item[:day] == user.nearest_day.strftime("%d").to_i
          item[:new_count] = item[:new_count] + 1
        end
      end

      list_user_discipline.each do |user|
        if item[:day] == user.mdate.strftime("%d").to_i
          item[:old_count] = item[:old_count] + 1
        end
      end

    end

    #  xoa nhung ngay khong co bien dong du lieu
    data = data.reject { |item| item[:new_count] == 0 && item[:old_count] == 0}

      render json:{
        month: month,
        year:year,
        days:data
      }
  end
  def calculate_age_percentages(age_ranges, age_male)
    male_count = age_male.length
    age_counts = Array.new(age_ranges.length, 0)

    age_male.each do |age|
      age_ranges.each_with_index do |range, index|
        if age >= range[0] and age <= range[1]
          age_counts[index] += 1
          break
        end
      end
    end

    age_percentages = []
    age_counts.each do |count|
      percentage = (count.to_f / male_count.to_f) * 100
      age_percentages << percentage.round(2)
    end

    return age_percentages
  end

  def update_isread_snotify
    snotice_id = params[:snotice_id]
    user_id = params[:user_id]

    oSnotice = Snotice.where(user_id: user_id).where(id: snotice_id).first
    if !oSnotice.nil?
        oSnotice.update({
            isread: true,
            dtread: DateTime.now,
        })
    end
    session[:per_sftraining] = false
    session[:per_assets] = false
        if is_access(session["user_id"], "SFTRAINING", "READ")
            session[:per_sftraining] = true

            oUser = User.where(id: session["user_id"]).first
            session[:user_avatar] = ""
            if !oUser.nil?
                session[:user_avatar] = Mediafile.where(id: oUser&.avatar).first&.file_name
                session[:user_fullname] = oUser.last_name + " " + oUser.first_name
                session[:user_id_login] = oUser.id

                session[:login] = true
                oWork = Work.where(user_id: oUser.id)
                oStask = Stask.where(id: oWork.pluck(:stask_id))
                oPositionjob = Positionjob.where(id: oWork.pluck(:positionjob_id))
                department = Positionjob.where(id: oWork.pluck(:positionjob_id)).first
                session[:arrWorkName] = oStask.pluck(:name) + oPositionjob.pluck(:name)
                session[:department_id] = department&.department_id
            end
            redirect_to url_for("https://capp.bmtu.edu.vn/sftraining/dashboard/index?lang=vi")
            # redirect_to url_for("https://erp.bmtu.edu.vn/sftraining/dashboard/index?lang=vi")
        elsif is_access(session["user_id"], "MASSET", "READ")
          session[:per_assets] = true

          oUser = User.where(id: session["user_id"]).first
          session[:user_avatar] = ""
          if !oUser.nil?
              session[:user_avatar] = Mediafile.where(id: oUser&.avatar).first&.file_name
              session[:user_fullname] = oUser.last_name + " " + oUser.first_name
              session[:user_id_login] = oUser.id

              session[:login] = true
              oWork = Work.where(user_id: oUser.id)
              oStask = Stask.where(id: oWork.pluck(:stask_id))
              oPositionjob = Positionjob.where(id: oWork.pluck(:positionjob_id))
              department = Positionjob.where(id: oWork.pluck(:positionjob_id)).first
              session[:arrWorkName] = oStask.pluck(:name) + oPositionjob.pluck(:name)
              session[:arrWorkScode] = oPositionjob.pluck(:scode)
              session[:department_id] = department&.department_id
              session[:organization] = Organization.where(id: oUser.uorgs.pluck(:organization_id)).pluck(:scode)
          end
          redirect_to url_for("https://capp.bmtu.edu.vn/masset?lang=vi")
          # redirect_to url_for("https://erp.bmtu.edu.vn/sftraining/dashboard/index?lang=vi")
        else
            session[:per_sftraining] = false
            session[:per_assets] = false
            redirect_to url_for(:back), notice: "Bạn không có quyền truy cập trang này"
        end
  end
end
