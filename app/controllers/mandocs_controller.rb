class MandocsController < ApplicationController
    before_action :authorize
    # Buld function incoming mandocs controller
    # @author: Q.Hai + Q.Thai
    # @date: 07/02/2023
    #
    def incoming_index
        search = params[:search] || ''
        session[:last_url] = request.url
        # list mandoc by user login  (q.Hải)
        @mandocWithDepartment = get_list_mandocs_with_department(session[:user_id], true)
        @departments = []
        @mandocfroms= Mandocfrom.where(status: "ACTIVE").order(:name)
        @mandocbooks = Mandocbook.where(status: "ACTIVE").order(:name)
        @mandoctypes = Mandoctype.where(status: "ACTIVE").order(:name)
        @mandocpriorities = Mandocpriority.where(status: "ACTIVE").order(:name)
        @users_department_handle_user =[]
        @arrMandoc = []
        @users_leader = nil
        @department_name_line = []
        @department_name_line_pb = []
        @department_leader_id = nil
        @users = []
        @users_leader_handle = nil
        department_id = nil
        users_arr = nil
        arrMandocProcess = []
        list_user = []
        value_sno = 0
        # Hải + Thái
        @mandoc= Mandoc.new
        # Đạt vũ code
        @newMandoc_dhandle = Mandocdhandle.new
        # Huy + H.Anh + Đồng
        oUserORG = Uorg.where(user_id: session[:user_id]).first
        department_ids = []
        if !oUserORG.nil?
            organization_id = oUserORG.organization_id
        else
            redirect_to dashboards_index_path(lang: session[:lang]) and return
        end
        value_sno = Mandoc.where("sfrom is not null AND YEAR(created_at) = YEAR(CURRENT_DATE())").where(organization_id: organization_id).select(:sno).last
        @value_sno = value_sno&.sno.to_i + 1
        # get id department all for user login
        o_user_check = User.find_by(id: session[:user_id])
        if o_user_check.present?
            o_user_check.works.each do |user_work|
                o_user_check_job = user_work.positionjob
                if o_user_check_job.present?
                department_ids << o_user_check_job.department_id
                end
            end
        end
        @departments = Department.where(organization_id: organization_id)
        streams = Operstream.where(organization_id: organization_id).all
        if streams.empty?
            redirect_to operstream_index_path(lang: session[:lang]) and return
        else
            streams.each do |e|
                stream = Stream.where(id: e.stream_id).where("scode LIKE '%QLVB-VB-TOI%'").first
                if stream.nil?
                    next
                elsif !stream.scode.include?("QLVB-VB-TOI")
                    next
                else
                    oCurrentUserTCHC = User.where(id: session[:user_id]).first
                    current_user_department = ""
                    @forms_connect = ""

                    if !oCurrentUserTCHC.nil?
                        works = oCurrentUserTCHC.works
                        works.each do |work|
                            if !work.positionjob.nil? && !work.positionjob.department.nil?
                                current_user_department = work.positionjob.department.id
                            end
                        end
                    end

                    oConnect = Connect.where(stream_id: stream.id,nbegin: current_user_department).first
                    if !oConnect.nil?
                    nend = oConnect.nend
                    @forms_connect = oConnect.forms

                    oDeparmentLeader = Department.where(id: nend).first
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
                    @oDeparment_logins = get_department_from_userlogin(session[:user_id])
                    if !@oDeparment_logins.nil?
                        @oDeparment_logins.each do |depart|
                            department = Department.find_by_id(depart)
                            department = Department.find_by_id(depart)
                            next unless department # Nếu department không tồn tại, tiếp tục vòng lặp với phần tử tiếp theo
                            positionjob_ids_by_login = Positionjob.where("department_id = ? AND (scode LIKE ? OR scode LIKE ?)", department.id, "%TRUONG%", "%PHO%").pluck(:id)
                            next unless positionjob_ids_by_login
                            works_user_id = Work.where(positionjob_id: positionjob_ids_by_login).pluck(:user_id)
                            next unless works_user_id
                            users_department_handle_user = (User.select("first_name,last_name,id").where(id: works_user_id))
                            @users_department_handle_user.push(users_department_handle_user)
                            @users_department_handle_user.each do |users_department_handle_user|
                                users_department_handle_user.each do |userhandle|
                                    list_user.push(userhandle.id)
                                    if !list_user.nil?
                                        user_id = User.where(id: session[:user_id]).first.id
                                        @checkDepartmentUserHandle = list_user.include?(user_id)
                                    end
                                end
                            end
                            @users = get_users_department_from_user_login(depart.id, depart.leader)
                            if !organization_id.nil?
                                oMandocuhandlesProcess = Mandocuhandle.where(user_id: session[:user_id]).where.not(status: "DAXULY")

                                oMandocuhandlesProcess.each do |manprocess|
                                    if !manprocess.mandocdhandle.nil?
                                        if !manprocess.mandocdhandle.mandoc.nil?
                                            mandoc_id = manprocess.mandocdhandle.mandoc.id
                                            arrMandocProcess.push(mandoc_id).uniq
                                        end
                                    end
                                end
                                sql = Mandoc.where("notes LIKE ? OR signed_by LIKE ? OR ssymbol LIKE ? OR sfrom LIKE ? OR type_book LIKE ? OR contents LIKE ? OR contents LIKE ?", "%#{search}%", "%#{search}%", "%#{search}%", "%#{search}%", "%#{search}%", "%#{search}%", "%#{search}%").where.not(status: "INACTIVE").where("sfrom IS NOT NULL").where(organization_id: organization_id, id: arrMandocProcess).order(updated_at: :desc)
                            end

                            #Hải + H.Anh + Đạt
                            # danh sach nhan su ban lanh dao tu bieu do van ban toi
                            firstNode = Node.where("stream_id = #{stream.id} AND nfirst = 'YES'").first
                            if !firstNode.nil?
                                @first_name_department = Department.where(id: firstNode.department_id).first&.name
                                # check id department nv văn thư, nếu trùng với vị trí của
                                department_ids.each do |depart_id|
                                    if depart_id.present?
                                        if depart_id == firstNode.department_id
                                            @department_id_check = firstNode.department_id
                                            break # nếu đã tìm thấy giá trị thỏa mãn thì thoát khỏi vòng lặp
                                        end
                                    end
                                end
                                @department_leader_id = Connect.where("stream_id = #{stream.id} AND nbegin = #{firstNode.department_id}").first.nend
                                if !@department_leader_id.nil?
                                    positionjob_ids =  Positionjob.where("department_id = #{@department_leader_id}").pluck(:id)
                                    works = Work.where(positionjob_id: positionjob_ids ).pluck(:user_id)
                                    @users_leader_handle = User.select("first_name,last_name,id").where(id: works)

                                    positionjob_ids_by_scode = Positionjob.where("department_id = ? AND (scode LIKE ? OR scode LIKE ?)", @department_leader_id, "%TRUONG%", "%PHO%").pluck(:id)
                                    works_user = Work.where(positionjob_id: positionjob_ids_by_scode).pluck(:user_id)
                                    @users_department_handle = User.select("first_name,last_name,id").where(id: works_user)
                                end

                                #Get department line
                                @department_name_line = Connect.where("stream_id = #{stream.id} AND nbegin = #{firstNode.department_id}").select(:nend, :forms)
                                @firstNodePB = 1
                                department_id = Connect.where("stream_id = #{stream.id} AND nbegin = #{firstNode.department_id}").first.nbegin
                                if !department_id.nil?
                                    positionjob_ids =  Positionjob.where("department_id = #{department_id}").pluck(:id)
                                    works = Work.where(positionjob_id: positionjob_ids ).pluck(:user_id)
                                    users_arr = User.select("id").where(id: works)
                                end
                            end
                            arrUserid =  users_arr.ids
                            if !arrUserid.nil?
                                users_id = User.where(id: session[:user_id]).first.id
                                @checkDirectorsHandle = arrUserid.include?(users_id)
                            end
                            mandocs = pagination_limit_offset(sql, 10)
                            mandocs.each do |mandoc|
                                dhandle = Mandocdhandle.joins(:mandoc).select("mandocs.*,mandocdhandles.created_at as created_at,mandocdhandles.deadline as deadline, mandocdhandles.department_id as department_id,mandocdhandles.contents as dhandle_contents").where("mandocdhandles.mandoc_id = #{mandoc.id} AND mandocdhandles.srole = 'XULY'").order(:updated_at).last
                                dhandle_ph = Mandocdhandle.where("srole = 'PHOIHOPXL' AND mandoc_id = #{mandoc.id} AND department_id = #{depart.id}").order(:updated_at).last
                                if !dhandle.nil?
                                    oUmandoc = Mandocuhandle.joins(mandocdhandle: :department).select("mandocuhandles.id as id,mandocuhandles.sothers as sothers, mandocuhandles.mandocdhandle_id as mandocdhandle_id, mandocuhandles.user_id as user_id, mandocuhandles.srole as srole, mandocdhandles.id as mdh_id, departments.id as departments_id, departments.name as department_name").where("mandocdhandles.mandoc_id = ? AND mandocuhandles.user_id = ? ", mandoc.id, session[:user_id]).last
                                    if oUmandoc && dhandle.department_id == depart.id && oUmandoc.sothers != "THU_KY_HIEU_TRUONG"
                                        @arrMandoc.push(dhandle)
                                    end
                                end
                                if !dhandle_ph.nil? && @checkDirectorsHandle != true
                                    @arrMandoc.push(mandoc)
                                end
                            end
                            session[:incoming]=@arrMandoc.size
                            @nodeLink = Node.where("stream_id = #{stream.id} AND nfirst IS NULL").first
                            if !@nodeLink.nil?
                                # don vi có trên sơ đồ
                                if !depart.nil?
                                    login_pb = Department.where(id: depart.id).first
                                    if !login_pb.nil?
                                        @organization_pb_login = login_pb.stype
                                        sodo_pb = Department.where(id: @nodeLink.department_id).first
                                        if !sodo_pb.nil?
                                            @orrganization_pb_sodo = sodo_pb.stype
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
                            last_department_id = Node.where("stream_id = #{stream.id}").last.department_id
                            if !last_department_id.nil?

                            end
                        end
                    end
                    if is_access(session["user_id"], "SP-NHANVIEN","READ")
                        oMandocuhandlesProcess = Mandocuhandle.where(sothers: ["XULY", "TIEPNHAN"], status: "CHUAXULY")
                        oMandocuhandlesProcess.each do |manprocess|
                            if !manprocess.mandocdhandle.nil?
                                if !manprocess.mandocdhandle.mandoc.nil?
                                    mandoc_id = manprocess.mandocdhandle.mandoc.id
                                    arrMandocProcess.push(mandoc_id).uniq
                                end
                            end
                        end
                        sql = Mandoc.where("notes LIKE ? OR signed_by LIKE ? OR ssymbol LIKE ? OR sfrom LIKE ? OR type_book LIKE ? OR contents LIKE ? OR contents LIKE ?", "%#{search}%", "%#{search}%", "%#{search}%", "%#{search}%", "%#{search}%", "%#{search}%", "%#{search}%").where.not(status: "INACTIVE").where("sfrom IS NOT NULL").where(id: arrMandocProcess).order(updated_at: :desc)

                        @arrMandoc = pagination_limit_offset(sql, 10)
                    end
                    if is_access(session["user_id"], "SP-TRUONGPHONG","READ")
                        oMandocuhandlesProcess = Mandocuhandle.where(sothers: ["TPXULY","DUYETVANBAN"], status: "CHUAXULY")
                        oMandocuhandlesProcess.each do |manprocess|
                            if !manprocess.mandocdhandle.nil?
                                if !manprocess.mandocdhandle.mandoc.nil?
                                    mandoc_id = manprocess.mandocdhandle.mandoc.id
                                    arrMandocProcess.push(mandoc_id).uniq
                                end
                            end
                        end
                        sql = Mandoc.where("notes LIKE ? OR signed_by LIKE ? OR ssymbol LIKE ? OR sfrom LIKE ? OR type_book LIKE ? OR contents LIKE ? OR contents LIKE ?", "%#{search}%", "%#{search}%", "%#{search}%", "%#{search}%", "%#{search}%", "%#{search}%", "%#{search}%").where.not(status: "INACTIVE").where("sfrom IS NOT NULL").where(id: arrMandocProcess).order(updated_at: :desc)

                        @arrMandoc = pagination_limit_offset(sql, 10)
                    end
                    if is_access(session["user_id"], "SP-VANTHU","READ")
                        oMandocuhandlesProcess = Mandocuhandle.where(sothers: ["CHUYENVTXULY", "VTTIEPNHAN"], status: "CHUAXULY")
                        oMandocuhandlesProcess.each do |manprocess|
                            if !manprocess.mandocdhandle.nil?
                                if !manprocess.mandocdhandle.mandoc.nil?
                                    mandoc_id = manprocess.mandocdhandle.mandoc.id
                                    arrMandocProcess.push(mandoc_id).uniq
                                end
                            end
                        end
                        sql = Mandoc.where("notes LIKE ? OR signed_by LIKE ? OR ssymbol LIKE ? OR sfrom LIKE ? OR type_book LIKE ? OR contents LIKE ? OR contents LIKE ?", "%#{search}%", "%#{search}%", "%#{search}%", "%#{search}%", "%#{search}%", "%#{search}%", "%#{search}%").where.not(status: "INACTIVE").where("sfrom IS NOT NULL").where(id: arrMandocProcess).order(updated_at: :desc)

                        @arrMandoc = pagination_limit_offset(sql, 10)
                    end
                return
                end
            end
            # Nếu không tìm thấy stream phù hợp trong vòng lặp, chuyển hướng đến operstream_index_path
            redirect_to operstream_index_path(lang: session[:lang])
        end

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
            @mandoc.status = "RECEIVE"
            @mandoc.deadline = ""
            @mandoc.organization_id = organization_id
            if @mandoc.save
                media_ids.each do |id|
                    mandocsfile = Mandocfile.where(id: id)
                    option_medias.each do |option_media|
                        if !mandocsfile.nil?
                            if option_media.include?(id) && option_media.include?("process")
                                mandocsfile.update({mandoc_id: @mandoc.id, dtype: 'PROCESS'})
                            elsif option_media.include?(id) && option_media.include?("coordinate")
                                mandocsfile.update({mandoc_id: @mandoc.id, dtype: 'COORDINATE'})
                            elsif option_media.include?(id) && option_media.include?("reference")
                                mandocsfile.update({mandoc_id: @mandoc.id, dtype: 'REFERENCE'})
                            elsif option_media.include?(id) && option_media.include?("enact")
                                mandocsfile.update({mandoc_id: @mandoc.id, dtype: 'ENACT'})
                            end
                        end
                    end
                end

                # Dat + Vu
                # Save first mandoc dhandle
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
                            srole: "TIEPNHAN",
                            deadline: "",
                            contents: contents,
                            sread: "CO",
                            status: "CHUAXULY",
                            sothers: "VTTIEPNHAN",
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
        redirect_to :back
    end

    def delete_mandocfile_incoming
        id = params[:aid]
        mandocfile = Mandocfile.where(id: id).first
        msg = lib_translate("Not_Success")
        if !mandocfile.nil?
            mandocfile.destroy
            msg = lib_translate("Delete_successfully")
        end
        redirect_to :back , notice: msg
    end
    # end of function incoming mandocs

    # Buld function outgoing mandocs controller
    # @author: Q.Hai + Q.Thai
    # @date: 06/02/2023
    #
    def outgoing_index
        search = params[:search] || ''
        session[:last_url] = request.url
        # list mandoc by user login  (q.Hải)
        @mandocWithDepartment = get_list_mandocs_with_department(session[:user_id], false)
        @arrMandoc = []
        @arrMandocPending = []
        @leader = []
        @users = []
        @mandoc= Mandoc.new
        @mandocbooks = Mandocbook.where(status: "ACTIVE").order(:name)
        @mandoctypes = Mandoctype.where(status: "ACTIVE").order(:name)
        @mandocpriorities = Mandocpriority.where(status: "ACTIVE").order(:name)
        @departments = []
        @list_users_uorg = []
        @users_leader = nil
        @department_name_line = []
        @department_name_line_pb = []
        department_id = nil
        users_arr = nil
        @organization_name=""
        # Đạt vũ code
        oCurrentUser = User.where(id: session[:user_id]).first
        if !oCurrentUser.nil?
            fullname = oCurrentUser.last_name + " " + oCurrentUser.first_name
            @arrMandocPending = Mandoc.where(status: "PENDING", created_by: fullname)
        end

        @newMandoc_dhandle = Mandocdhandle.new
        # danh sach nhan su ban lanh dao tu bieu do van ban di
        @department_leader_id = nil
        # Huy + H.Anh + Đồng
        arrMandocProcess = []
        oUserORG = Uorg.where(user_id: session[:user_id]).first
        if !oUserORG.nil?
            organization_id = oUserORG.organization_id
            @organization_name = oUserORG.organization&.name
            @organization_scode = oUserORG.organization&.scode
        else
            redirect_to dashboards_index_path(lang: session[:lang]) and return
        end
        @testd = []
        @departments = Department.where(organization_id: organization_id)
        id_users_uorg = Uorg.where(organization_id: organization_id).pluck(:user_id)
        @list_users_uorg = User.where(id: id_users_uorg)


        streams =  Operstream.where(organization_id: organization_id ).all
        if streams.empty?
            redirect_to operstream_index_path(lang: session[:lang]) and return
        else
            streams.each do |e|
                stream =  Stream.where(id: e.stream_id).where("scode LIKE '%QLVB-VB-DI%'").first
                # stream = Stream.where("scode = 'QLVB-VB-DI'").first
                if stream.nil?
                    next
                elsif !stream.scode.include?("QLVB-VB-DI")
                    next
                else
                    @oDeparment_logins = get_department_from_userlogin(session[:user_id])
                    if !@oDeparment_logins.nil?
                        @oDeparment_logins.each do |departmentULogin|
                            if !organization_id.nil?
                                user_sign = User.where(id: session[:user_id]).first
                                if !user_sign.nil?
                                    oMandocuhandlesProcess = Mandocuhandle.where(user_id: session[:user_id]).where.not(status: "DAXULY")
                                    oMandocuhandlesProcess.each do |manprocess|
                                        testd = manprocess.mandocdhandle.mandoc
                                        @testd.push(testd)

                                        # if user_sign.email == manprocess.mandocdhandle.mandoc.signed_by || user_sign.email == manprocess.mandocdhandle.mandoc.created_by
                                            if !manprocess.mandocdhandle.nil?
                                                if !manprocess.mandocdhandle.mandoc.nil?
                                                    mandoc_id = manprocess.mandocdhandle.mandoc.id
                                                    arrMandocProcess.push(mandoc_id).uniq
                                                end
                                            end
                                        # end
                                    end
                                end
                                sql = Mandoc.where("notes LIKE ? OR signed_by LIKE ? OR ssymbol LIKE ? OR sfrom LIKE ? OR type_book LIKE ? OR contents LIKE ? OR contents LIKE ?", "%#{search}%", "%#{search}%", "%#{search}%", "%#{search}%", "%#{search}%", "%#{search}%", "%#{search}%").where(status: "INPROGRESS").where("sfrom IS NULL").where(organization_id: organization_id, id: arrMandocProcess).order(updated_at: :desc)
                            end

                            # cac don vi khac xu li văn ban - khong phai van thu
                            @nodeLink = Node.where("stream_id = #{stream.id} AND nfirst IS NULL").first
                            if !@nodeLink.nil?
                                # don vi có trên sơ đồ
                                if !departmentULogin.nil?
                                    login_pb = Department.where(id: departmentULogin.id).first
                                    if !login_pb.nil?
                                        @organization_pb_login = login_pb.stype
                                        sodo_pb = Department.where(id: @nodeLink.department_id).first
                                        if !sodo_pb.nil?
                                            @orrganization_pb_sodo = sodo_pb.stype
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

                            # Hải + Thái change 05/05/2023 : load Trưởng/ phó phòng
                            @lists_leader_email = []

                            # Lấy danh sách trưởng phòng - phó phòng theo work
                            #1. id phòng ban người dùng đăng nhập
                            id_depart_ulogin = departmentULogin.id
                            list_possitionjobs = []
                            list_uid = []
                            @list_id_users_trp = []
                            list_possitionjobsTCHC = []
                            list_uidTCHC = []
                            #2. Danh sách mã chức vụ trong phòng ban departmentULogin
                            if !id_depart_ulogin.nil? && id_depart_ulogin != @department_leader_id_handel&.to_i
                                possitionjobs = Positionjob.where(department_id: id_depart_ulogin)
                                if !possitionjobs.nil?
                                    possitionjobs.each do |pos|
                                        list_possitionjobs.push(pos.id)
                                    end
                                    # danh sách nhân sự trưởng phó phòng theo id
                                    list_possitionjobs.each do |possi|
                                        name_po = Positionjob.where(id: possi).first
                                        if !name_po.nil?
                                            if name_po.scode.include?("TRUONG") || name_po.scode.include?("PHO")
                                                work = Work.where(positionjob_id: possi)
                                                if !work.nil?
                                                    work.each do |wo|
                                                        list_uid.push(wo.user_id)
                                                    end
                                                end
                                                list_uid.each do |user|
                                                    id_user_by_work = User.where(id: user).first
                                                    if !id_user_by_work.nil?
                                                        @lists_leader_email.push(id_user_by_work.email)
                                                        @list_id_users_trp.push(id_user_by_work.id)
                                                    end
                                                end
                                            end

                                        end
                                    end
                                end
                            end
                            # phòng ban không có trưởng phó phòng
                            # Hải + H.Anh change 11/5/2023
                            # dành cho nhân viên thuộc phòng ban không có Trưởng/Phó phòng
                            # mặc định lấy trưởng phó của phòng TCHC
                            if @lists_leader_email.nil? || @lists_leader_email == []
                                phongTCHC = Department.where("name LIKE '%Phòng Tổ Chức%'").where(organization_id: organization_id).first
                                if !phongTCHC.nil?
                                    possitionjobsTCHC = Positionjob.where(department_id: phongTCHC.id)
                                    if !possitionjobsTCHC.nil?
                                        possitionjobsTCHC.each do |pos|
                                            list_possitionjobsTCHC.push(pos.id)
                                        end
                                        # danh sách nhân sự tr/p của TCHC
                                        list_possitionjobsTCHC.each do |possi|
                                            name_poTCHC = Positionjob.where(id: possi).first
                                            if !name_poTCHC.nil?
                                                if name_poTCHC.scode.include?("TRUONG") || name_poTCHC.scode.include?("PHO")
                                                    work = Work.where(positionjob_id: possi)
                                                    if !work.nil?
                                                        work.each do |wo|
                                                            list_uidTCHC.push(wo.user_id)
                                                        end
                                                    end
                                                    list_uidTCHC.each do |user|
                                                        id_user_by_work = User.where(id: user).first
                                                        if !id_user_by_work.nil?
                                                            @lists_leader_email.push(id_user_by_work.email)
                                                            @list_id_users_trp.push(id_user_by_work.id)
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                             # END HAI + H.ANH CODE
                            #END Hải + Thái change 05/05/2023 : load Trưởng/ phó phòng

                            @users = get_users_department_from_user_login(departmentULogin.id, departmentULogin.leader)

                            # Hải + Thái

                            # @mediafilesss = Mandocfile.all
                            # xóa các mandocfile chưa có mandoc_id
                            @mediafilesdelete = Mandocfile.where("mandoc_id is null").delete_all
                            # văn thu xu li văn bản
                            firstNode = Node.where("stream_id = #{stream.id} AND nfirst = 'YES'").first
                            if !firstNode.nil?
                                @department_leader_id = Connect.where("stream_id = #{stream.id} AND nbegin = #{firstNode.department_id}").first.nend
                                if !@department_leader_id.nil?
                                    positionjob_ids =  Positionjob.where("department_id = #{@department_leader_id}").pluck(:id)
                                    works = Work.where(positionjob_id: positionjob_ids ).pluck(:user_id)
                                    @users_leader = User.select("first_name,last_name,id").where(id: works)
                                end

                                #Get department line
                                @department_name_line = Connect.where("stream_id = #{stream.id} AND nbegin = #{firstNode.department_id}").select(:nend, :forms)
                                @firstNodePB = 1
                                department_id = Connect.where("stream_id = #{stream.id} AND nbegin = #{firstNode.department_id}").first.nend
                                if !department_id.nil?
                                    positionjob_ids =  Positionjob.where("department_id = #{department_id}").pluck(:id)
                                    works = Work.where(positionjob_id: positionjob_ids ).pluck(:user_id)
                                    users_arr = User.select("id").where(id: works)
                                end
                            end
                            arrUserid =  users_arr.ids
                            if !arrUserid.nil?
                                users_id = User.where(id: session[:user_id]).first.id
                                @checkDirectorsHandle = arrUserid.include?(users_id)
                            end

                            # load văn bản dựa vào user đăng nhập (Hải code - fix update ngày 13/5/2023)
                            mandocs = pagination_limit_offset(sql, 10)
                            mandocs.each do |mandoc|
                                dhandle = Mandocdhandle.joins(:mandoc).select("mandocs.*,mandocdhandles.created_at as created_at,mandocdhandles.deadline as deadline, mandocdhandles.department_id as department_id,mandocdhandles.contents as dhandle_contents").where("mandocdhandles.mandoc_id = #{mandoc.id} AND mandocdhandles.srole = 'XULY'").order(:updated_at).last
                                dhandle_ph = Mandocdhandle.where("srole = 'PHOIHOPXL' AND mandoc_id = #{mandoc.id} AND department_id = #{departmentULogin.id}").order(:updated_at).last

                                if !dhandle.nil?
                                    oUmandoc = Mandocuhandle.joins(mandocdhandle: :department).select("mandocuhandles.id as id,mandocuhandles.sothers as sothers, mandocuhandles.mandocdhandle_id as mandocdhandle_id, mandocuhandles.user_id as user_id, mandocuhandles.srole as srole, mandocdhandles.id as mdh_id, departments.id as departments_id, departments.name as department_name").where("mandocdhandles.mandoc_id = ? AND mandocuhandles.user_id = ? ", mandoc.id, session[:user_id]).last
                                    if oUmandoc && dhandle.department_id == departmentULogin.id && oUmandoc.sothers != "THU_KY_HIEU_TRUONG"
                                        @arrMandoc.push(dhandle)
                                    end
                                end
                                # Kiểm tra 19/09/2023
                                if !dhandle_ph.nil? && @checkDirectorsHandle != true
                                    @arrMandoc.push(mandoc)
                                end
                            end
                            # end code load văn bản dựa vào user đăng nhập (Hải code - fix update ngày 13/5/2023)
                            session[:outgoing]=@arrMandoc.size
                        end
                    end
                    if is_access(session["user_id"], "SP-NHANVIEN","READ")
                        oMandocuhandlesProcess = Mandocuhandle.where(sothers: ["XULY", "TIEPNHAN"], status: "CHUAXULY")
                        oMandocuhandlesProcess.each do |manprocess|
                            if !manprocess.mandocdhandle.nil?
                                if !manprocess.mandocdhandle.mandoc.nil?
                                    mandoc_id = manprocess.mandocdhandle.mandoc.id
                                    arrMandocProcess.push(mandoc_id).uniq
                                end
                            end
                        end
                        sql = Mandoc.where("notes LIKE ? OR signed_by LIKE ? OR ssymbol LIKE ? OR sfrom LIKE ? OR type_book LIKE ? OR contents LIKE ? OR contents LIKE ?", "%#{search}%", "%#{search}%", "%#{search}%", "%#{search}%", "%#{search}%", "%#{search}%", "%#{search}%")
                                .where(status: "INPROGRESS")
                                .where("sfrom IS NULL")
                                .where(id: arrMandocProcess)
                                .order(updated_at: :desc)

                        @arrMandoc = pagination_limit_offset(sql, 10)
                    end
                    if is_access(session["user_id"], "SP-TRUONGPHONG","READ")
                        oMandocuhandlesProcess = Mandocuhandle.where(sothers: ["TPXULY","DUYETVANBAN"], status: "CHUAXULY")
                        oMandocuhandlesProcess.each do |manprocess|
                            if !manprocess.mandocdhandle.nil?
                                if !manprocess.mandocdhandle.mandoc.nil?
                                    mandoc_id = manprocess.mandocdhandle.mandoc.id
                                    arrMandocProcess.push(mandoc_id).uniq
                                end
                            end
                        end
                        sql = Mandoc.where("notes LIKE ? OR signed_by LIKE ? OR ssymbol LIKE ? OR sfrom LIKE ? OR type_book LIKE ? OR contents LIKE ? OR contents LIKE ?", "%#{search}%", "%#{search}%", "%#{search}%", "%#{search}%", "%#{search}%", "%#{search}%", "%#{search}%")
                                .where(status: "INPROGRESS")
                                .where("sfrom IS NULL")
                                .where(id: arrMandocProcess)
                                .order(updated_at: :desc)

                        @arrMandoc = pagination_limit_offset(sql, 10)
                    end
                    if is_access(session["user_id"], "SP-VANTHU","READ")
                        oMandocuhandlesProcess = Mandocuhandle.where(sothers: ["CHUYENVTXULY"], status: "CHUAXULY")
                        oMandocuhandlesProcess.each do |manprocess|
                            if !manprocess.mandocdhandle.nil?
                                if !manprocess.mandocdhandle.mandoc.nil?
                                    mandoc_id = manprocess.mandocdhandle.mandoc.id
                                    arrMandocProcess.push(mandoc_id).uniq
                                end
                            end
                        end
                        sql = Mandoc.where("notes LIKE ? OR signed_by LIKE ? OR ssymbol LIKE ? OR sfrom LIKE ? OR type_book LIKE ? OR contents LIKE ? OR contents LIKE ?", "%#{search}%", "%#{search}%", "%#{search}%", "%#{search}%", "%#{search}%", "%#{search}%", "%#{search}%")
                                .where(status: "INPROGRESS")
                                .where("sfrom IS NULL")
                                .where(id: arrMandocProcess)
                                .order(updated_at: :desc)

                        @arrMandoc = pagination_limit_offset(sql, 10)
                    end
                    return
                end
            end
            # Nếu không tìm thấy stream phù hợp trong vòng lặp, chuyển hướng đến operstream_index_path
            redirect_to operstream_index_path(lang: session[:lang])
        end


    end

    def get_list_users_with_depatment
        datas = []
        ids_department = params[:select_release_department].split(",")
        if ids_department == ""
            users = nil
        elsif ids_department.include?('all')
            organization_ids = Uorg.where(user_id: session[:user_id]).pluck(:organization_id)
            users = User.joins(:uorgs).where(uorgs: { organization_id: organization_ids })
        else
            users = User.joins(works: :positionjob).where(works: { positionjob_id: Positionjob.where(department_id: ids_department) })
        end
        users.each do |user|
          positionjob = user.works.first&.positionjob
          department = positionjob&.department
          datas.append({
            'users' => user,
            'positionjob' => positionjob,
            'department' => department,
          })
        end

        respond_to do |format|
            format.js { render js: "getListUser(#{datas.uniq.to_json.html_safe})"}
        end
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
        spriority = params[:spriority]
        number_pages = params[:number_pages]
        contents = params[:contents]
        status = params[:status]
        notes = params[:notes]
        media_ids= params[:media_ids] || []

        option_medias = params[:option_media] || []
        mdepartment= params[:mdepartment]
        organization_id = ""
        list_Trpp = []
        oUserORG = Uorg.where(user_id: session[:user_id]).first
        if !oUserORG.nil?
            organization_id = oUserORG.organization_id
        end


        # if !contents.nil? || contents != ""
        #     contents =  contents.gsub(/\s+/, " ").strip
        # end

        department = ""
        oDepartmentOutgoingAdd = Department.where(id: mdepartment).first
        if !oDepartmentOutgoingAdd.nil?
            department = oDepartmentOutgoingAdd.name
        end

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
        @mandoc.spriority = spriority
        @mandoc.number_pages = number_pages
        @mandoc.mdepartment = department || ""
        @mandoc.status = status
        @mandoc.deadline = ""
        @mandoc.organization_id = organization_id

        oMandocPending = Mandoc.where(id: id_mandoc).where(status: "PENDING").first
        if !oMandocPending.nil?
            oMandocPending.destroy
        end
        if @mandoc.save
            media_ids.each do |id|
                mandocsfile = Mandocfile.where(id: id)
                option_medias.each do |option_media|
                    if !mandocsfile.nil?
                        if option_media.include?(id) && option_media.include?("process")
                            mandocsfile.update({mandoc_id: @mandoc.id, dtype: 'PROCESS'})
                        elsif option_media.include?(id) && option_media.include?("coordinate")
                            mandocsfile.update({mandoc_id: @mandoc.id, dtype: 'COORDINATE'})
                        elsif option_media.include?(id) && option_media.include?("reference")
                            mandocsfile.update({mandoc_id: @mandoc.id, dtype: 'REFERENCE'})
                        elsif option_media.include?(id) && option_media.include?("enact")
                            mandocsfile.update({mandoc_id: @mandoc.id, dtype: 'ENACT'})
                        end
                    end
                end
            end

            id_signed = User.where(email: signed_by).first
            if !id_signed.nil?
                department_signed = get_department_from_user_login(id_signed.id)
            end
                mandhandle_man = Mandocdhandle.create({
                    mandoc_id: @mandoc.id,
                    department_id: department_signed.id,
                    srole: "XULY",
                    deadline: "",
                    contents: notes,
                    status: "ACTIVE"
                })

                if !signed_by.nil?
                     # UserMailer.mandoc_handle(signed_by, get_mediafile_mandoc(@mandoc.id), @mandoc.id, department_signed.id, !get_department_from_user_login(session[:user_id]).nil? ? get_department_from_user_login(session[:user_id]).name : "",  (@mandoc.received_at).strftime("%d/%m/%Y"), contents, 'Trưởng/Phó phòng', request.base_url).deliver_later
                end
                user_signed_handle = User.where(email: signed_by).first
                if !user_signed_handle.nil?
                    if user_signed_handle.id == session[:user_id]
                        Mandocuhandle.create({
                        mandocdhandle_id: mandhandle_man.id,
                        user_id: user_signed_handle.id,
                        srole: "XULY",
                        deadline: mandhandle_man.deadline,
                        contents: mandhandle_man.contents,
                        sread: "KHONG",
                        status: "CHUAXULY"
                        })
                    else
                        Mandocuhandle.create({
                        mandocdhandle_id: mandhandle_man.id,
                        user_id: session[:user_id],
                        srole: "TIEPNHAN",
                        deadline: mandhandle_man.deadline,
                        contents: mandhandle_man.contents,
                        sread: "CO",
                        status: "DAXULY"
                        })
                        Mandocuhandle.create({
                        mandocdhandle_id: mandhandle_man.id,
                        user_id: user_signed_handle.id,
                        srole: "XULY",
                        deadline: mandhandle_man.deadline,
                        contents: mandhandle_man.contents,
                        sread: "KHONG",
                        status: "CHUAXULY",
                        sothers: "DUYETVANBAN"
                        })
                    end
                    # danh sách trưởng - phó phòng
                    # bỏ ng dc assign_to ra

                    positionjob_ids_list = Positionjob.where("department_id = ? AND (scode LIKE ? OR scode LIKE ?)", mandhandle_man.department_id, "%TRUONG%", "%PHO%")
                    if !positionjob_ids_list.nil?
                        positionjob_ids_list.each do |positionjob|
                            works = Work.where(positionjob_id: positionjob.id)
                            if !works.nil?
                                works.each do |work|
                                    oUser = User.where(id: work.user_id).first
                                    if !oUser.nil?
                                        list_Trpp.push(oUser.id)
                                    end
                                end
                            end
                        end
                        list_Trpp.uniq
                    end
                    if list_Trpp.include?(user_signed_handle.id)
                        list_Trpp.delete(user_signed_handle.id)
                        if !list_Trpp.nil?
                            list_Trpp.each do |list|
                                Mandocuhandle.create({
                                    mandocdhandle_id: mandhandle_man.id,
                                    user_id: list,
                                    srole: "PHOIHOPXL",
                                    sread: "KHONG",
                                    deadline: mandhandle_man.deadline,
                                    status: "PHOIHOPXL",
                                    contents: mandhandle_man.contents
                                })
                            end
                        end
                    end
                end
            # Store to mandoc dhandle
        end
        redirect_to :back
    end

    def outgoing_change_read
        id_mandoc = params[:id_mandoc]
        oMandocu =Mandocuhandle.joins(:mandocdhandle).where("mandocdhandles.mandoc_id = ? AND mandocuhandles.user_id = ? ", id_mandoc, session[:user_id]).last
        if !oMandocu.nil?
            if oMandocu.srole == "XULY"
                oMandocu.update({
                    sread: "CO"
                })
            else
                oMandocu.update({
                    sread: "CO",
                    status: "DAXULY"
                })
            end
        end
    end

    def del_after_handle
        id = params[:id]
        oMandocuhandleXL = Mandocuhandle.joins(:mandocdhandle).where("mandocdhandles.mandoc_id = ? AND mandocuhandles.srole = ? AND mandocuhandles.sothers = ?", id, "XULY", "DUYETVANBAN").last
        if !oMandocuhandleXL.nil? && oMandocuhandleXL.sread == "KHONG"
            user_id = params[:uhandle_man_id]
            mandoc_del = Mandoc.where(id: id).first
            if !mandoc_del.nil?
                mandoc_del.destroy
                log_history(Mandoc, "Xóa", !mandoc_del.contents.nil? && !mandoc_del.contents.empty? ? mandoc_del.contents : mandoc_del.notes , "Đã xóa khỏi hệ thống", @current_user.email)
            end
            redirect_to(:back, notice: lib_translate('delete_message'))
        else
            redirect_to :back, alert: lib_translate("Bạn không thể xóa văn bản khi đã được Trưởng/Phó phòng kiểm tra")
        end
    end

    def outgoing_edit
        id_mandoc = params[:id_mandoc]
        oMandocuhandleXL = Mandocuhandle.joins(:mandocdhandle).where("mandocdhandles.mandoc_id = ? AND mandocuhandles.srole = ? AND mandocuhandles.sothers = ?", id_mandoc, "XULY", "DUYETVANBAN").last
        if !oMandocuhandleXL.nil? && oMandocuhandleXL.sread == "KHONG"
            type_book = params[:type_book]
            ssymbol = params[:ssymbol]
            stype = params[:stype]
            signed_by = params[:signed_by]
            slink = params[:slink]
            created_by = params[:created_by]
            received_at = params[:received_at]
            spriority = params[:spriority]
            number_pages = params[:number_pages]
            contents = params[:contents]
            notes = params[:notes]
            media_ids= params[:media_ids] || []

            option_medias = params[:option_media] || []
            mdepartment= params[:mdepartment]
            organization_id = ""

            oMandoc = Mandoc.where(id: id_mandoc).first
            if !oMandoc.nil?
                oUserORG = Uorg.where(user_id: session[:user_id]).first
                if !oUserORG.nil?
                    organization_id = oUserORG.organization_id
                end

                department = ""
                oDepartmentOutgoingAdd = Department.where(id: mdepartment).first
                if !oDepartmentOutgoingAdd.nil?
                    department = oDepartmentOutgoingAdd.name
                end

                oMandoc.update({
                    type_book: type_book,
                    ssymbol: ssymbol,
                    stype: stype,
                    signed_by: signed_by,
                    contents: contents,
                    notes: notes,
                    slink: slink,
                    created_by: created_by,
                    received_at: received_at,
                    spriority: spriority,
                    number_pages: number_pages,
                    mdepartment: department || "",
                    organization_id: organization_id,
                })

                media_ids.each do |id|
                    mandocsfile = Mandocfile.where(id: id)
                    option_medias.each do |option_media|
                        if !mandocsfile.nil?
                            if option_media.include?(id) && option_media.include?("process")
                                mandocsfile.update({mandoc_id: oMandoc.id, dtype: 'PROCESS'})
                            elsif option_media.include?(id) && option_media.include?("coordinate")
                                mandocsfile.update({mandoc_id: oMandoc.id, dtype: 'COORDINATE'})
                            elsif option_media.include?(id) && option_media.include?("reference")
                                mandocsfile.update({mandoc_id: oMandoc.id, dtype: 'REFERENCE'})
                            elsif option_media.include?(id) && option_media.include?("enact")
                                mandocsfile.update({mandoc_id: oMandoc.id, dtype: 'ENACT'})
                            end
                        end
                    end
                end
            end
            redirect_to :back, notice: lib_translate("Successfully")
        else
            redirect_to :back, alert: lib_translate("Bạn không thể sửa văn bản khi đã được Trưởng/Phó phòng kiểm tra")
        end
    end

    def outgoing_edit_handle
            id_mandoc = params[:id_mandoc]
            type_book = params[:type_book]
            ssymbol = params[:ssymbol]
            stype = params[:stype]
            signed_by = params[:signed_by]
            slink = params[:slink]
            created_by = params[:created_by]
            received_at = params[:received_at]
            spriority = params[:spriority]
            number_pages = params[:number_pages]
            contents = params[:contents]
            notes = params[:notes]
            media_ids= params[:media_ids] || []

            option_medias = params[:option_media] || []
            mdepartment= params[:mdepartment]
            organization_id = ""

            oMandoc = Mandoc.where(id: id_mandoc).first
            if !oMandoc.nil?
                oUserORG = Uorg.where(user_id: session[:user_id]).first
                if !oUserORG.nil?
                    organization_id = oUserORG.organization_id
                end

                department = ""
                oDepartmentOutgoingAdd = Department.where(id: mdepartment).first
                if !oDepartmentOutgoingAdd.nil?
                    department = oDepartmentOutgoingAdd.name
                end

                oMandoc.update({
                    type_book: type_book,
                    ssymbol: ssymbol,
                    stype: stype,
                    signed_by: signed_by,
                    contents: contents,
                    notes: notes,
                    slink: slink,
                    created_by: created_by,
                    received_at: received_at,
                    spriority: spriority,
                    number_pages: number_pages,
                    mdepartment: department || "",
                    organization_id: organization_id,
                })

                media_ids.each do |id|
                    mandocsfile = Mandocfile.where(id: id)
                    option_medias.each do |option_media|
                        if !mandocsfile.nil?
                            if option_media.include?(id) && option_media.include?("process")
                                mandocsfile.update({mandoc_id: oMandoc.id, dtype: 'PROCESS'})
                            elsif option_media.include?(id) && option_media.include?("coordinate")
                                mandocsfile.update({mandoc_id: oMandoc.id, dtype: 'COORDINATE'})
                            elsif option_media.include?(id) && option_media.include?("reference")
                                mandocsfile.update({mandoc_id: oMandoc.id, dtype: 'REFERENCE'})
                            elsif option_media.include?(id) && option_media.include?("enact")
                                mandocsfile.update({mandoc_id: oMandoc.id, dtype: 'ENACT'})
                            end
                        end
                    end
                end
            end
            redirect_to :back, notice: lib_translate("Successfully")
    end

    def delete_mandocfile_outgoing
        id = params[:aid]
        mandocfile = Mandocfile.where(id: id).first
        msg = lib_translate("Not_Success")
        if !mandocfile.nil?
            mandocfile.destroy
            msg = lib_translate("Delete_successfully")
        end
        redirect_to :back , notice: msg
    end

    def del
        id = params[:id]
        type = params[:type] || ""

        if type != ""
            Mandocuhandle.where("mandocdhandle_id is null").destroy_all
            Mandocdhandle.where("mandoc_id is null").destroy_all

        end
        user_id = params[:uhandle_man_id]
        mandoc_del = Mandoc.where(id: id).first
        if !mandoc_del.nil?
            mandoc_del.destroy
            log_history(Mandoc, "Xóa", !mandoc_del.contents.nil? && !mandoc_del.contents.empty? ? mandoc_del.contents : mandoc_del.notes , "Đã xóa khỏi hệ thống", @current_user.email)
        end
        redirect_to(:back, notice: lib_translate('delete_message'))
    end


    def check_duplicate_symboll
        strSymboll = params[:str_symbol_release]
        release_mandoc_stype = params[:release_mandoc_stype]
        isCheck = true
            oMandoc = Mandoc.where("sfrom IS NULL AND stype = ? AND ssymbol = ? ", release_mandoc_stype, strSymboll).first
            if !oMandoc.nil?
                isCheck = false
            end
        render json: isCheck
    end

    # end of function outgoing mandocs
    # Ban lãnh đạo xử lý văn bản
    def process_index
        search = params[:search] || ''
        session[:last_url] = request.url
        @arrMandoc = []
        @mandocWithULogin =[]
        @oConnectLeader = []


        @mandoc= Mandoc.new
        @mandocbooks = Mandocbook.all
        @mandoctypes = Mandoctype.all
        @mandocpriorities = Mandocpriority.all
        # Đạt vũ code
        @newMandoc_dhandle = Mandocdhandle.new
        @departments = []
        @mandocdhandles = Mandocdhandle.all
        # Hải + Thái
        @mandocs = Mandoc.all
        # Huy + H.Anh + Đồng
        @oDeparment_login = get_department_from_user_login(session[:user_id])
        arrMandocProcess = []

        oUserORG = Uorg.where(user_id: session[:user_id]).first
        if !oUserORG.nil?
            organization_id = oUserORG.organization_id
        else
            redirect_to dashboards_index_path(lang: session[:lang]) and return
        end

        streams =  Operstream.where(organization_id: organization_id ).all
        if streams.empty?
            redirect_to operstream_index_path(lang: session[:lang]) and return
        else
            streams.each do |e|
                stream =  Stream.where(id: e.stream_id).where("scode LIKE '%QLVB-VB-DI%'").first
                # stream = Stream.where("scode = 'QLVB-VB-DI'").first
                if stream.nil?
                    next
                elsif !stream.scode.include?("QLVB-VB-DI")
                    next
                else
                    if !@oDeparment_login.nil?
                        # get list mandoc by user department have to handle
                        oUserORG = Uorg.where(user_id: session[:user_id]).first
                        if !oUserORG.nil?
                            organization_id = oUserORG.organization_id
                            @departments = Department.where(organization_id: organization_id)

                            oMandocuhandlesProcess = Mandocuhandle.where(user_id: session[:user_id]).where.not(status: "DAXULY")

                            oMandocuhandlesProcess.each do |manprocess|
                                if !manprocess.mandocdhandle.nil?
                                    if !manprocess.mandocdhandle.mandoc.nil?
                                        mandoc_id = manprocess.mandocdhandle.mandoc.id
                                        arrMandocProcess.push(mandoc_id).uniq
                                    end
                                end
                            end
                            sql = Mandoc.where("notes LIKE ? OR signed_by LIKE ? OR ssymbol LIKE ? OR sfrom LIKE ? OR type_book LIKE ? OR contents LIKE ? OR contents LIKE ? OR mdepartment LIKE ?", "%#{search}%", "%#{search}%", "%#{search}%", "%#{search}%", "%#{search}%", "%#{search}%", "%#{search}%", "%#{search}%").where(status: "INPROGRESS").where(organization_id: organization_id, id: arrMandocProcess).order(updated_at: :desc)

                        oCurrentUserTCHC = User.where(id: session[:user_id]).first
                        current_user_department = ""
                        @forms_connect = ""

                        if !oCurrentUserTCHC.nil?
                            works = oCurrentUserTCHC.works
                            works.each do |work|
                                if !work.positionjob.nil? && !work.positionjob.department.nil?
                                    current_user_department = work.positionjob.department.id
                                end
                            end
                        end

                        @oConnectLeader = Connect.where(stream_id: stream.id,nbegin: current_user_department)

                        else
                            sql = Mandoc.where("notes LIKE ? OR signed_by LIKE ? OR ssymbol LIKE ? OR sfrom LIKE ? OR type_book LIKE ? OR contents LIKE ? OR contents LIKE ? OR mdepartment LIKE ?", "%#{search}%", "%#{search}%", "%#{search}%", "%#{search}%", "%#{search}%", "%#{search}%", "%#{search}%", "%#{search}%").where(status: "INPROGRESS").where(organization_id: organization_id, id: arrMandocProcess).order(updated_at: :desc)
                        end

                        mandocs = pagination_limit_offset(sql, 10)

                        mandocs.each do |mandoc|
                            dhandle = Mandocdhandle.joins(:mandoc).select("mandocs.*,mandocdhandles.created_at as created_at,mandocdhandles.deadline as deadline, mandocdhandles.department_id as department_id,mandocdhandles.contents as dhandle_contents").where("mandocdhandles.mandoc_id = #{mandoc.id} AND mandocdhandles.srole = 'XULY'").order(:updated_at).last
                            dhandle_ph = Mandocdhandle.where("srole = 'PHOIHOPXL' AND mandoc_id = #{mandoc.id} AND department_id = #{@oDeparment_login.id}").order(:created_at).last
                            if !dhandle.nil?
                                if dhandle.department_id == @oDeparment_login.id
                                    @arrMandoc.push(dhandle)
                                end
                            end
                            if !dhandle_ph.nil?
                                @arrMandoc.push(mandoc)
                            end
                        end
                        @arrMandoc
                        session[:process]=@arrMandoc.size
                        # list mandoc by user login  (q.Hải)
                        @mandocWithULogin = get_list_mandocs_with_user_login(session[:user_id])


                    end
                    if is_access(session["user_id"], "SP-BANGIAMHIEU","READ")
                        oMandocuhandlesProcess = Mandocuhandle.where(sothers: "THU_KY_HIEU_TRUONG", status: "CHUAXULY")
                        oMandocuhandlesProcess.each do |manprocess|
                            if !manprocess.mandocdhandle.nil?
                                if !manprocess.mandocdhandle.mandoc.nil?
                                    mandoc_id = manprocess.mandocdhandle.mandoc.id
                                    arrMandocProcess.push(mandoc_id).uniq
                                end
                            end
                        end
                        sql = Mandoc.where("notes LIKE ? OR signed_by LIKE ? OR ssymbol LIKE ? OR sfrom LIKE ? OR type_book LIKE ? OR contents LIKE ? OR contents LIKE ? OR mdepartment LIKE ?", "%#{search}%", "%#{search}%", "%#{search}%", "%#{search}%", "%#{search}%", "%#{search}%", "%#{search}%", "%#{search}%").where(status: "INPROGRESS").where(id: arrMandocProcess).order(updated_at: :desc)

                        @arrMandoc = pagination_limit_offset(sql, 10)
                    end
                end
            end
        end
    end

    def process_update
        id_mandoc = params[:id_mandoc]
        type_book = params[:type_book]
        sno = params[:sno]
        ssymbol = params[:ssymbol]
        stype = params[:stype]
        signed_by = params[:signed_by]
        slink = params[:slink]
        created_by = params[:created_by]
        effective_date = params[:effective_date]
        spriority = params[:spriority]
        number_pages = params[:number_pages]
        contents = params[:contents]
        notes = params[:notes]
        media_ids= params[:media_ids] || []
        # if !contents.nil? || contents != ""
        #     contents =  contents.gsub(/\s+/, " ").strip
        # end
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
            @mandoc.effective_date = effective_date
            @mandoc.spriority = spriority
            @mandoc.number_pages = number_pages
            @mandoc.status = "INPROGRESS"

            if @mandoc.save
                media_ids.each do |id|
                    mandocsfile = Mandocfile.where(id: id)
                    if !mandocsfile.nil?
                        mandocsfile.update({mandoc_id: @mandoc.id})
                    end
                end
            end
        end

        redirect_to :back
    end

    def assign_users_process
        arrCheck = params[:check].split(",")
        mandoc_id = params[:mandoc_id]
        id_dhandle_dv = params[:id_dhandle_dv]
        if !arrCheck.nil?
            oMandocdhandle = Mandocdhandle.where(mandoc_id: mandoc_id, srole: "XULY").last
            if !oMandocdhandle.nil?
                oUpdate = Mandocuhandle.where(user_id: session[:user_id], mandocdhandle_id: oMandocdhandle.id, srole: "XULY").last
                if !oUpdate.nil?
                    oUpdate.update({
                        sread: "CO",
                        status: "DAXULY",
                        sothers: "PHANCONG"
                    })
                else
                    Mandocuhandle.create({
                        mandocdhandle_id: id_dhandle_dv,
                        user_id: session[:user_id],
                        srole: "TIEPNHAN",
                        deadline: oMandocdhandle.deadline,
                        contents: oMandocdhandle.contents,
                        sread: "CO",
                        status: "DAXULY",
                        sothers: "PHANCONG"
                    })
                end
                mandoc = Mandoc.where(id: mandoc_id).first
                if !mandoc.nil?
                    mandoc&.mandocuhandles&.update({
                        sread: "CO",
                        status: "DAXULY"
                    })
                    mandoc&.mandocuhandles.where(sothers: "XULY")&.update({
                        sothers: "HUYBOXULY",
                    })
                    mandoc.touch
                    mandoc.save
                end
                arrCheck.each do |check|
                    srole = params[:srole][check]
                    deadline = params[:deadline][check]
                    content = params[:content][check]
                    oMandocuhandles = Mandocuhandle.new
                    oMandocuhandles.mandocdhandle_id = oMandocdhandle.id
                    oMandocuhandles.user_id = check
                    oMandocuhandles.srole = srole
                    oMandocuhandles.deadline = deadline
                    oMandocuhandles.contents = content
                    oMandocuhandles.sothers = "XULY"
                    if srole == "DEBIET"
                        oMandocuhandles.sread = "KHONG"
                        oMandocuhandles.status = "CHUAXULY"
                    elsif srole == "PHOIHOPXL"
                        oMandocuhandles.sread = "KHONG"
                        oMandocuhandles.status = "CHUAXULY"
                    else
                        oMandocuhandles.sread = "KHONG"
                        oMandocuhandles.status = "CHUAXULY"
                    end
                    oMandocuhandles.save
                end
            end
        end

        redirect_to :back, notice: lib_translate("Successfully")
    end

    def user_process
        user_id_assign_final = ""
        id_uhandle = params[:id_uhandle]
        mandoc_id = params[:mandoc_id]
        sread = "CO"
        contents_user = params[:contents]
        status_mandoc = params[:status]
        user_id_assign = params[:department_user]
        media_ids= params[:media_ids] || []
        option_medias = params[:option_media] || []
        list_Trpp = []
        status = "DAXULY"
        # if !contents_user.nil? || contents_user != ""
        #     contents_user =  contents_user.gsub(/\s+/, " ").strip
        # end
        oMandoc = Mandocuhandle.where(id: id_uhandle).first.mandocdhandle.mandoc
        if !oMandoc.nil?

            if status_mandoc == "PENDING"
                oMandoc.update(status: status_mandoc)
            else
                oMandoc.update(status: "INPROGRESS")
                mandoc = Mandoc.where(id: mandoc_id).first
                if !mandoc.nil?
                    mandoc&.mandocuhandles&.update({
                        sread: "CO",
                        status: "DAXULY"
                    })
                    mandoc.touch
                    mandoc.save
                end
                oMandocuhandles = Mandocuhandle.where(id: id_uhandle)
                if !oMandocuhandles.nil?
                    oMandocuhandles.update({
                        sread: sread,
                        status: status
                        })
                        media_ids.each do |id|
                            mandocsfile = Mandocfile.where(id: id)
                            option_medias.each do |option_media|
                                if !mandocsfile.nil?
                                    if option_media.include?(id) && option_media.include?("process")
                                        mandocsfile.update({mandoc_id: mandoc_id, dtype: 'PROCESS'})
                                    elsif option_media.include?(id) && option_media.include?("coordinate")
                                        mandocsfile.update({mandoc_id: mandoc_id, dtype: 'COORDINATE'})
                                    elsif option_media.include?(id) && option_media.include?("reference")
                                        mandocsfile.update({mandoc_id: mandoc_id, dtype: 'REFERENCE'})
                                    elsif option_media.include?(id) && option_media.include?("enact")
                                        mandocsfile.update({mandoc_id: mandoc_id, dtype: 'ENACT'})
                                    end
                                end
                            end
                        end

                end
                # sau khi user xử lí xong, chuyển thông báo lên trưởng phòng ban để xem xét và xử lí văn bản

                user_lead_assign = Mandoc.where(id: mandoc_id).first
                if !user_lead_assign.nil?
                    assign_to = User.where(email: user_lead_assign.signed_by).first

                    if !assign_to.nil?
                        lastDhandleId = Mandocdhandle.where(mandoc_id: oMandoc.id).last
                        if !lastDhandleId.nil?


                            Mandocuhandle.create({
                                mandocdhandle_id: lastDhandleId.id,
                                user_id: assign_to.id,
                                srole: "XULY",
                                deadline: lastDhandleId.deadline,
                                contents: contents_user,
                                sread: "KHONG",
                                status: "CHUAXULY",
                                sothers: "TPXULY"
                            })
                             # UserMailer.mandoc_handle(assign_to.id, get_mediafile_mandoc(oMandoc.id), oMandoc.id, lastDhandleId.department_id, !get_department_from_user_login(session[:user_id]).nil? ? get_department_from_user_login(session[:user_id]).name : "",  ("").strftime("%d/%m/%Y"), contents_user, 'Trưởng/Phó phòng', request.base_url).deliver_later
                            # danh sách trưởng - phó phòng
                            # bỏ ng dc assign_to ra

                            positionjob_ids_list = Positionjob.where("department_id = ? AND (scode LIKE ? OR scode LIKE ?)", lastDhandleId.department_id, "%TRUONG%", "%PHO%")
                            if !positionjob_ids_list.nil?
                                positionjob_ids_list.each do |positionjob|
                                    works = Work.where(positionjob_id: positionjob.id)
                                    if !works.nil?
                                        works.each do |work|
                                            oUser = User.where(id: work.user_id).first
                                            if !oUser.nil?
                                                list_Trpp.push(oUser.id)
                                            end
                                        end
                                    end
                                end
                                list_Trpp.uniq
                                if list_Trpp.include?(assign_to.id)
                                    list_Trpp.delete(assign_to.id)
                                    if !list_Trpp.nil?
                                        list_Trpp.each do |list|
                                            Mandocuhandle.create({
                                                mandocdhandle_id: lastDhandleId.id,
                                                user_id: list,
                                                srole: "PHOIHOPXL",
                                                sread: "KHONG",
                                                deadline: lastDhandleId.deadline,
                                                status: "PHOIHOPXL",
                                                contents: contents_user
                                            })
                                        end
                                    end
                                end
                            end
                        end

                    else
                        lastDhandleId = Mandocdhandle.where(mandoc_id: oMandoc.id).last
                        if !lastDhandleId.nil?
                            Mandocuhandle.create({
                                mandocdhandle_id: lastDhandleId.id,
                                user_id: user_id_assign,
                                srole: "XULY",
                                deadline: lastDhandleId.deadline,
                                contents: contents_user,
                                sread: "KHONG",
                                status: "CHUAXULY",
                                sothers: "TPXULY"
                            })

                            # danh sách trưởng - phó phòng
                            # bỏ ng dc assign_to ra

                            positionjob_ids_list = Positionjob.where("department_id = ? AND (scode LIKE ? OR scode LIKE ?)", lastDhandleId.department_id, "%TRUONG%", "%PHO%")
                            if !positionjob_ids_list.nil?
                                positionjob_ids_list.each do |positionjob|
                                    works = Work.where(positionjob_id: positionjob.id)
                                    if !works.nil?
                                        works.each do |work|
                                            oUser = User.where(id: work.user_id).first
                                            if !oUser.nil?
                                                list_Trpp.push(oUser.id)
                                            end
                                        end
                                    end
                                end
                                list_Trpp.uniq
                            end
                            if list_Trpp.include?(user_id_assign)
                                list_Trpp.delete(user_id_assign)
                                if !list_Trpp.nil?
                                    list_Trpp.each do |list|
                                        Mandocuhandle.create({
                                            mandocdhandle_id: lastDhandleId.id,
                                            user_id: list,
                                            srole: "PHOIHOPXL",
                                            sread: "KHONG",
                                            deadline: lastDhandleId.deadline,
                                            status: "PHOIHOPXL",
                                            contents: contents_user
                                        })
                                    end
                                end
                            end
                        end

                    end
                    oMandocuhandles = Mandocuhandle.where(id: id_uhandle)
                    if !oMandocuhandles.nil?
                        oMandocuhandles.update({
                            sread: "CO",
                            status: "DAXULY"
                            })
                    end
                    media_ids.each do |id|
                        mandocsfile = Mandocfile.where(id: id)
                        if !mandocsfile.nil?
                            mandocsfile.update({mandoc_id: mandoc_id})
                        end
                    end
                end
            end


        end

        redirect_to :back, notice: lib_translate("Successfully")
    end

    def update_read
        @mandocuhandle = Mandocuhandle.where(id: params[:id])
        if @mandocuhandle.update(sread: 'CO')
            render json: @mandocuhandle, status: :ok
        else
            render json: { errors: @mandocuhandle.errors.full_messages }, status: :unprocessable_entity
        end
    end

    def watch_index

    end

    # Buld function upload file mandocs controller
    # @author: Q.Hai + Q.Thai
    # @date: 06/02/2023
    #
    def mandocfile_upload_mediafile
        file = params["file"]
        mandoc_id = params["mandoc_id"]
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
            @data = {
                mandoc_id:mandoc_id,
                id:@mandocsfile.id ,
                file_id:@id_mediafile[:id],
                file_name:@id_mediafile[:name],
                file_owner: @id_mediafile[:owner],
                created_at: @mandocsfile[:created_at].strftime('%H:%M %d/%m/%Y'),
                type: "new-item"
            }
            render json: @data
        else
            render json: "No file!"
        end
    end

    def delete_mandocfile
        id = params[:aid]
        @mandocfile = Mandocfile.where(id: id).first
        @mandocfile.destroy
        redirect_to :back , notice: lib_translate("delete_message")
    end
    # end of function upload file mandocs


    # Buld function BGD assign to departments
    # @author: Dat + Vu
    # @date: 08/02/2023
    #
    def get_department
        @users = []
        positionjob_ids = Positionjob.where("department_id = ? AND (scode LIKE ? OR scode LIKE ?)", params[:department_id], "%TRUONG%", "%PHO%")
        if !positionjob_ids.nil?
            positionjob_ids.each do |positionjob|
                works = Work.where(positionjob_id: positionjob.id)
                if !works.nil?
                    works.each do |work|
                        oUser = User.where(id: work.user_id).first
                        if !oUser.nil?
                            @users.push({
                                first_name: oUser.first_name,
                                last_name: oUser.last_name,
                                id: oUser.id,
                                positionjob_name: positionjob.name,
                                email: oUser.email,
                            })
                        end
                    end
                end
            end
        end
        render json: @users
    end

    def assign_departments_with_user
        mandoc_id = params[:mandoc_id]
        id_uhandle = params[:id_uhandle]
        department_id = params[:department_id_asign]
        department_help_ids = params[:department_help_ids]
        deadline = params[:deadline]
        contents = params[:contents]
        assign_to = params[:department_user] || ""
        type_assign = params[:mandoc_send_type]
        list_Trpp = []
        mandoc_content_department = params[:mandoc_content_department]
        file_urls = get_mediafile_mandoc(mandoc_id)
        department_user_login = !get_department_from_user_login(session[:user_id]).nil? ? get_department_from_user_login(session[:user_id]).name : ""

        # "XULY"
        # "PHOIHOPXL"
        media_ids = params[:media_ids] || []
        option_medias = params[:option_media] || []
        # save media
        media_ids&.uniq.each do |id|
            mandocsfile = Mandocfile.where(id: id)
            option_medias.each do |option_media|
                if !mandocsfile.nil?
                    if option_media.include?(id) && option_media.include?("process")
                        mandocsfile.update({mandoc_id: mandoc_id, dtype: 'PROCESS'})
                    elsif option_media.include?(id) && option_media.include?("coordinate")
                        mandocsfile.update({mandoc_id: mandoc_id, dtype: 'COORDINATE'})
                    elsif option_media.include?(id) && option_media.include?("reference")
                        mandocsfile.update({mandoc_id: mandoc_id, dtype: 'REFERENCE'})
                    elsif option_media.include?(id) && option_media.include?("enact")
                        mandocsfile.update({mandoc_id: mandoc_id, dtype: 'ENACT'})
                    end
                end
            end
        end
        media_ids&.each do |id|
            mandocsfile = Mandocfile.where(id: id)
            if !mandocsfile.nil?
                mandocsfile.update({mandoc_id: mandoc_id})
            end
        end
        # if !contents.nil? || contents != ""
        #     contents =  contents.gsub(/\s+/, " ").strip
        # end
        # save department_id
        new_mandhandle = Mandocdhandle.create({
            mandoc_id: mandoc_id,
            department_id: department_id,
            deadline: deadline,
            contents: contents,
            status: "ACTIVE",
            srole: "XULY"
        })
        # save mandoc content
        mandoc = Mandoc.where(id: mandoc_id).first
        if !mandoc_content_department.nil?
            if !mandoc.nil?
                mandoc.update({
                    contents: mandoc_content_department
                })
            end
        end
        if !mandoc.nil?
            mandoc&.mandocuhandles&.update({
                sread: "CO",
                status: "DAXULY"
            })
            mandoc.touch
            mandoc.save
        end
        oDepartment = Department.where(id: department_id).first
        if !oDepartment.nil?
            Mandocuhandle.create({
                mandocdhandle_id: new_mandhandle.id,
                user_id: assign_to,
                deadline: new_mandhandle.deadline,
                srole: "XULY",
                status: "CHUAXULY",
                sread: "KHONG",
                contents: contents,
                sothers: "THU_KY_HIEU_TRUONG"
            })

            # danh sách trưởng - phó phòng
            # bỏ ng dc assign_to ra

            positionjob_ids_list = Positionjob.where("department_id = ? AND (scode LIKE ? OR scode LIKE ?)", new_mandhandle.department_id, "%TRUONG%", "%PHO%")
            if !positionjob_ids_list.nil? && type_assign != "BLD"
                positionjob_ids_list.each do |positionjob|
                    works = Work.where(positionjob_id: positionjob.id)
                    if !works.nil?
                        works.each do |work|
                            oUser = User.where(id: work.user_id).first
                            if !oUser.nil?
                                list_Trpp.push(oUser.id)
                            end
                        end
                    end
                end
                list_Trpp.uniq
                if list_Trpp.include?(assign_to.to_i)
                    list_Trpp.delete(assign_to.to_i)
                    if !list_Trpp.nil?
                        list_Trpp.each do |list|
                            Mandocuhandle.create({
                                mandocdhandle_id: new_mandhandle.id,
                                user_id: list,
                                srole: "PHOIHOPXL",
                                sread: "KHONG",
                                deadline: new_mandhandle.deadline,
                                status: "PHOIHOPXL",
                                contents: contents
                            })
                        end
                    end
                end

            end
        end

        # save department help if data exists
        if department_help_ids.kind_of?(Array)
            department_help_ids.each do |id|
                list_Trpp_helps = []
                oMandocdhandleHelp = Mandocdhandle.create({
                    mandoc_id: mandoc_id,
                    department_id: id,
                    deadline: deadline,
                    contents: contents,
                    status: "ACTIVE",
                    srole: "PHOIHOPXL"
                })
                oDepartment = Department.where(id: id).first
                if !oDepartment.nil?
                    positionjob_ids_list = Positionjob.where("department_id = ? AND (scode LIKE ? OR scode LIKE ?)", id, "%TRUONG%", "%PHO%")
                    if !positionjob_ids_list.nil?
                        positionjob_ids_list.each do |positionjob|
                            works = Work.where(positionjob_id: positionjob.id)
                            if !works.nil?
                                works.each do |work|
                                    oUser = User.where(id: work.user_id).first
                                    if !oUser.nil?
                                        list_Trpp_helps.push(oUser.id)
                                    end
                                end
                            end
                        end
                        list_Trpp_helps.uniq
                    end
                    if !list_Trpp_helps.nil?
                        list_Trpp_helps.each do |list|
                            logger.info("Thai  #{list}")
                            Mandocuhandle.create({
                                mandocdhandle_id: oMandocdhandleHelp.id,
                                user_id: list,
                                srole: "PHOIHOPXL",
                                sread: "KHONG",
                                deadline: oMandocdhandleHelp.deadline,
                                status: "PHOIHOPXL",
                                contents: contents
                            })
                        end
                    end

                end
            end
        end
        redirect_to :back, notice: lib_translate("Successfully")
    end

    def assign_departments_with_user_bld
        mandoc_id = params[:mandoc_id]
        id_uhandle = params[:id_uhandle]
        department_id = params[:department_id_asign]
        department_help_ids = params[:department_help_ids]
        deadline = params[:deadline]
        contents = params[:contents]
        assign_to = params[:department_user] || ""
        type_assign = params[:mandoc_send_type]
        list_Trpp = []
        mandoc_content_department = params[:mandoc_content_department]
        file_urls = get_mediafile_mandoc(mandoc_id)
        department_user_login = !get_department_from_user_login(session[:user_id]).nil? ? get_department_from_user_login(session[:user_id]).name : ""

        # "XULY"
        # "PHOIHOPXL"
        media_ids = params[:media_ids] || []
        option_medias = params[:option_media] || []
        # save media
        media_ids&.uniq.each do |id|
            mandocsfile = Mandocfile.where(id: id)
            option_medias.each do |option_media|
                if !mandocsfile.nil?
                    if option_media.include?(id) && option_media.include?("process")
                        mandocsfile.update({mandoc_id: mandoc_id, dtype: 'PROCESS'})
                    elsif option_media.include?(id) && option_media.include?("coordinate")
                        mandocsfile.update({mandoc_id: mandoc_id, dtype: 'COORDINATE'})
                    elsif option_media.include?(id) && option_media.include?("reference")
                        mandocsfile.update({mandoc_id: mandoc_id, dtype: 'REFERENCE'})
                    elsif option_media.include?(id) && option_media.include?("enact")
                        mandocsfile.update({mandoc_id: mandoc_id, dtype: 'ENACT'})
                    end
                end
            end
        end
        media_ids&.each do |id|
            mandocsfile = Mandocfile.where(id: id)
            if !mandocsfile.nil?
                mandocsfile.update({mandoc_id: mandoc_id})
            end
        end
        # if !contents.nil? || contents != ""
        #     contents =  contents.gsub(/\s+/, " ").strip
        # end
        # save department_id
        new_mandhandle = Mandocdhandle.create({
            mandoc_id: mandoc_id,
            department_id: department_id,
            deadline: deadline,
            contents: contents,
            status: "ACTIVE",
            srole: "XULY"
        })
        # save mandoc content
        mandoc = Mandoc.where(id: mandoc_id).first

        if !mandoc.nil?
            mandoc&.mandocuhandles&.update({
                sread: "CO",
                status: "DAXULY"
            })
            mandoc.touch
            mandoc.save
        end
        oDepartment = Department.where(id: department_id).first
        if !oDepartment.nil?
            Mandocuhandle.create({
                mandocdhandle_id: new_mandhandle.id,
                user_id: assign_to,
                deadline: new_mandhandle.deadline,
                srole: "XULY",
                status: "CHUAXULY",
                sread: "KHONG",
                contents: contents,
                sothers: "TPXULY",
            })

            # danh sách trưởng - phó phòng
            # bỏ ng dc assign_to ra

            positionjob_ids_list = Positionjob.where("department_id = ? AND (scode LIKE ? OR scode LIKE ?)", new_mandhandle.department_id, "%TRUONG%", "%PHO%")
            if !positionjob_ids_list.nil? && type_assign != "BLD"
                positionjob_ids_list.each do |positionjob|
                    works = Work.where(positionjob_id: positionjob.id)
                    if !works.nil?
                        works.each do |work|
                            oUser = User.where(id: work.user_id).first
                            if !oUser.nil?
                                list_Trpp.push(oUser.id)
                            end
                        end
                    end
                end
                list_Trpp.uniq
                if list_Trpp.include?(assign_to.to_i)
                    list_Trpp.delete(assign_to.to_i)
                    if !list_Trpp.nil?
                        list_Trpp.each do |list|
                            Mandocuhandle.create({
                                mandocdhandle_id: new_mandhandle.id,
                                user_id: list,
                                srole: "PHOIHOPXL",
                                sread: "KHONG",
                                deadline: new_mandhandle.deadline,
                                status: "PHOIHOPXL",
                                contents: contents
                            })
                        end
                    end
                end

            end
        end

        # save department help if data exists
        if department_help_ids.kind_of?(Array)
            department_help_ids.each do |id|
                list_Trpp_helps = []
                oMandocdhandleHelp = Mandocdhandle.create({
                    mandoc_id: mandoc_id,
                    department_id: id,
                    deadline: deadline,
                    contents: contents,
                    status: "ACTIVE",
                    srole: "PHOIHOPXL"
                })
                oDepartment = Department.where(id: id).first
                if !oDepartment.nil?
                    positionjob_ids_list = Positionjob.where("department_id = ? AND (scode LIKE ? OR scode LIKE ?)", id, "%TRUONG%", "%PHO%")
                    if !positionjob_ids_list.nil?
                        positionjob_ids_list.each do |positionjob|
                            works = Work.where(positionjob_id: positionjob.id)
                            if !works.nil?
                                works.each do |work|
                                    oUser = User.where(id: work.user_id).first
                                    if !oUser.nil?
                                        list_Trpp_helps.push(oUser.id)
                                    end
                                end
                            end
                        end
                        list_Trpp_helps.uniq
                    end
                    if !list_Trpp_helps.nil?
                        list_Trpp_helps.each do |list|
                            logger.info("Thai  #{list}")
                            Mandocuhandle.create({
                                mandocdhandle_id: oMandocdhandleHelp.id,
                                user_id: list,
                                srole: "PHOIHOPXL",
                                sread: "KHONG",
                                deadline: oMandocdhandleHelp.deadline,
                                status: "PHOIHOPXL",
                                contents: contents
                            })
                        end
                    end

                end
            end
        end
        redirect_to :back, notice: lib_translate("Successfully")
    end

    def assign_departments
        mandoc_id = params[:mandoc_id]
        id_uhandle = params[:id_uhandle]
        department_id = params[:department_id_asign]
        department_help_ids = params[:department_help_ids]
        deadline = params[:deadline]
        department_user = params[:department_user]
        contents = params[:contents] || params[:contents_VT_PB]
        list_Trpp = []
        mandoc_content_department = params[:mandoc_content_department]
        file_urls = get_mediafile_mandoc(mandoc_id)
        department_user_login = !get_department_from_user_login(session[:user_id]).nil? ? get_department_from_user_login(session[:user_id]).name : ""
        # "XULY"
        # "PHOIHOPXL"
        # if !contents.nil? || contents != ""
        #     contents =  contents.gsub(/\s+/, " ").strip
        # end
        # save department_id
        media_ids = params[:media_ids] || []
        option_medias = params[:option_media] || []
        # save media
        media_ids.each do |id|
            mandocsfile = Mandocfile.where(id: id)
            option_medias.each do |option_media|
                if !mandocsfile.nil?
                    if option_media.include?(id) && option_media.include?("process")
                        mandocsfile.update({mandoc_id: mandoc_id, dtype: 'PROCESS'})
                    elsif option_media.include?(id) && option_media.include?("coordinate")
                        mandocsfile.update({mandoc_id: mandoc_id, dtype: 'COORDINATE'})
                    elsif option_media.include?(id) && option_media.include?("reference")
                        mandocsfile.update({mandoc_id: mandoc_id, dtype: 'REFERENCE'})
                    elsif option_media.include?(id) && option_media.include?("enact")
                        mandocsfile.update({mandoc_id: mandoc_id, dtype: 'ENACT'})
                    end
                end
            end
        end

        media_ids.each do |id|
            mandocsfile = Mandocfile.where(id: id)
            if !mandocsfile.nil?
                mandocsfile.update({mandoc_id: mandoc_id})
            end
        end



        new_mandhandle = Mandocdhandle.create({
            mandoc_id: mandoc_id,
            department_id: department_id,
            deadline: deadline,
            contents: contents,
            status: "ACTIVE",
            srole: "XULY",
        })
        # save mandoc content
        mandoc = Mandoc.where(id: mandoc_id).first
        if !mandoc_content_department.nil?
            if !mandoc.nil?
                mandoc.update({
                    contents: mandoc_content_department
                })
            end
        end
        if !mandoc.nil?
            mandoc&.mandocuhandles&.update({
                sread: "CO",
                status: "DAXULY"
            })
            mandoc.touch
            mandoc.save
        end
        get_user_assign = Mandoc.where(id: mandoc_id).first
        if !department_user.nil? && department_user != ""
            Mandocuhandle.create({
                mandocdhandle_id: new_mandhandle.id,
                user_id: department_user,
                deadline: new_mandhandle.deadline,
                srole: "XULY",
                status: "CHUAXULY",
                sread: "KHONG",
                contents: contents,
                sothers: "TPXULY",
            })
                # danh sách trưởng - phó phòng
            # bỏ ng dc assign_to ra

            positionjob_ids_list = Positionjob.where("department_id = ? AND (scode LIKE ? OR scode LIKE ?)", new_mandhandle.department_id, "%TRUONG%", "%PHO%")
            if !positionjob_ids_list.nil?
                positionjob_ids_list.each do |positionjob|
                    works = Work.where(positionjob_id: positionjob.id)
                    if !works.nil?
                        works.each do |work|
                            oUser = User.where(id: work.user_id).first
                            if !oUser.nil?
                                list_Trpp.push(oUser.id)
                            end
                        end
                    end
                end
                list_Trpp.uniq
            end
            if list_Trpp.include?(department_user)
                list_Trpp.delete(department_user)
                if !list_Trpp.nil?
                    list_Trpp.each do |list|
                        Mandocuhandle.create({
                            mandocdhandle_id: new_mandhandle.id,
                            user_id: list,
                            srole: "PHOIHOPXL",
                            sread: "KHONG",
                            deadline: new_mandhandle.deadline,
                            status: "PHOIHOPXL",
                            contents: contents
                        })
                    end
                end
            end
        elsif !get_user_assign.nil? || !get_user_assign == ""
            assign_to = User.where(email: get_user_assign.signed_by).first
            if !assign_to.nil?
                    Mandocuhandle.create({
                        mandocdhandle_id: new_mandhandle.id,
                        user_id: assign_to.id,
                        deadline: new_mandhandle.deadline,
                        srole: "XULY",
                        status: "CHUAXULY",
                        sread: "KHONG",
                        contents: contents,
                        sothers: "TPXULY",
                    })
                        # danh sách trưởng - phó phòng
                    # bỏ ng dc assign_to ra

                    positionjob_ids_list = Positionjob.where("department_id = ? AND (scode LIKE ? OR scode LIKE ?)", new_mandhandle.department_id, "%TRUONG%", "%PHO%")
                    if !positionjob_ids_list.nil?
                        positionjob_ids_list.each do |positionjob|
                            works = Work.where(positionjob_id: positionjob.id)
                            if !works.nil?
                                works.each do |work|
                                    oUser = User.where(id: work.user_id).first
                                    if !oUser.nil?
                                        list_Trpp.push(oUser.id)
                                    end
                                end
                            end
                        end
                        list_Trpp.uniq
                    end
                    if list_Trpp.include?(assign_to.id)
                        list_Trpp.delete(assign_to.id)
                        if !list_Trpp.nil?
                            list_Trpp.each do |list|
                                Mandocuhandle.create({
                                    mandocdhandle_id: new_mandhandle.id,
                                    user_id: list,
                                    srole: "PHOIHOPXL",
                                    sread: "KHONG",
                                    deadline: new_mandhandle.deadline,
                                    status: "PHOIHOPXL",
                                    contents: contents
                                })
                            end
                        end
                    end
                 # UserMailer.mandoc_handle(assign_to.id, file_urls, mandoc_id, department_id, department_user_login, deadline, contents, "Trưởng/Phó phòng", request.base_url).deliver_later
            end
        end

        # save department help if data exists
        if department_help_ids.kind_of?(Array)
            department_help_ids.each do |id|
                list_Trpp_helps = []
                oMandocdhandleHelp = Mandocdhandle.create({
                    mandoc_id: mandoc_id,
                    department_id: id,
                    deadline: deadline,
                    contents: contents,
                    status: "ACTIVE",
                    srole: "PHOIHOPXL"
                })
                oDepartment = Department.where(id: id).first
                if !oDepartment.nil?
                     # UserMailer.mandoc_handle(assign_to.id, file_urls, mandoc_id, id, department_user_login, deadline, contents, "Trưởng/Phó phòng", request.base_url).deliver_later
                    positionjob_ids_list = Positionjob.where("department_id = ? AND (scode LIKE ? OR scode LIKE ?)", id, "%TRUONG%", "%PHO%")
                    if !positionjob_ids_list.nil?
                        positionjob_ids_list.each do |positionjob|
                            works = Work.where(positionjob_id: positionjob.id)
                            if !works.nil?
                                works.each do |work|
                                    oUser = User.where(id: work.user_id).first
                                    if !oUser.nil?
                                        list_Trpp_helps.push(oUser.id)
                                    end
                                end
                            end
                        end
                        list_Trpp_helps.uniq
                    end
                    if !list_Trpp_helps.nil?
                        list_Trpp_helps.each do |list|
                            Mandocuhandle.create({
                                mandocdhandle_id: oMandocdhandleHelp.id,
                                user_id: list,
                                srole: "PHOIHOPXL",
                                sread: "KHONG",
                                deadline: oMandocdhandleHelp.deadline,
                                status: "PHOIHOPXL",
                                contents: contents
                            })
                        end
                    end

                end
            end
        end
        redirect_to :back, notice: lib_translate("Successfully")
    end

    # Buld function department assign to user of BGD
    # @author: Dat + Vu
    # @date: 08/02/2023
    #
    def assign_leader
        action = params[:assign_leader_type] #mandoc id
        mandoc_id = params[:mandoc_id] #mandoc id
        contents = params[:contents] # contents
        assign_to = params[:assign_to] # id nguoi duoc chon
        department_id = params[:department_id] #department BGD lay tu @department_leader_id
        id_dhandle = params[:id_dhandle]
        list_Trpp = []
        mandoc_contents = params[:mandoc_content_leader]
        # lưu vào mandocdhandle
        # if !contents.nil? || contents != ""
        #     contents =  contents.gsub(/\s+/, " ").strip
        # end
        media_ids = params[:media_ids] || []
        option_medias = params[:option_media] || []
        # save media
        media_ids.each do |id|
            mandocsfile = Mandocfile.where(id: id)
            option_medias.each do |option_media|
                if !mandocsfile.nil?
                    if option_media.include?(id) && option_media.include?("process")
                        mandocsfile.update({mandoc_id: mandoc_id, dtype: 'PROCESS'})
                    elsif option_media.include?(id) && option_media.include?("coordinate")
                        mandocsfile.update({mandoc_id: mandoc_id, dtype: 'COORDINATE'})
                    elsif option_media.include?(id) && option_media.include?("reference")
                        mandocsfile.update({mandoc_id: mandoc_id, dtype: 'REFERENCE'})
                    elsif option_media.include?(id) && option_media.include?("enact")
                        mandocsfile.update({mandoc_id: mandoc_id, dtype: 'ENACT'})
                    end
                end
            end
        end
        mandoc_handle = Mandocdhandle.create({
            mandoc_id: mandoc_id,
            department_id: department_id,
            contents: contents,
            deadline: "",
            status: "ACTIVE",
            srole: "XULY",
        })

        # lưu nhân sự ban lãnh đạo được chỉ định vào, người được chỉ định cụ thể sẽ được xử lý bằng form
        if !mandoc_handle.nil?
            #CẬP NHẬT TRANG THÁI CHO VĂN BẢN
            oMandoc = Mandoc.where(id: mandoc_id).first
            if !oMandoc.nil?
                oMandoc&.mandocuhandles&.update({
                    sread: "CO",
                    status: "DAXULY"
                })
                oMandoc.touch
                oMandoc.save
                sfrom_mandoc = oMandoc.sfrom
                if !sfrom_mandoc.nil?
                    oMandoc.update({
                        status: "INPROGRESS"
                    })
                else
                    oMandoc.update({
                        status: "INPROGRESS",
                        contents: mandoc_contents
                    })
                end
            end

            Mandocuhandle.create({
                mandocdhandle_id: mandoc_handle.id,
                user_id: assign_to,
                deadline: mandoc_handle.deadline,
                srole: "XULY",
                status: "CHUAXULY",
                sread: "KHONG",
                contents: contents,
                sothers: "THU_KY_HIEU_TRUONG"
            })
            # danh sách trưởng - phó phòng
            # bỏ ng dc assign_to ra

            positionjob_ids_list = Positionjob.where("department_id = ? AND (scode LIKE ? OR scode LIKE ?)", mandoc_handle.department_id, "%TRUONG%", "%PHO%")
            if !positionjob_ids_list.nil?
                positionjob_ids_list.each do |positionjob|
                    works = Work.where(positionjob_id: positionjob.id)
                    if !works.nil?
                        works.each do |work|
                            oUser = User.where(id: work.user_id).first
                            if !oUser.nil?
                                list_Trpp.push(oUser.id)
                            end
                        end
                    end
                end
                list_Trpp.uniq
            end
            if list_Trpp.include?(assign_to)
                list_Trpp.delete(assign_to)
                if !list_Trpp.nil?
                    list_Trpp.each do |list|
                        Mandocuhandle.create({
                            mandocdhandle_id: mandoc_handle.id,
                            user_id: list,
                            srole: "PHOIHOPXL",
                            sread: "KHONG",
                            deadline: mandoc_handle.deadline,
                            status: "PHOIHOPXL",
                            contents: contents
                        })
                    end
                end
            end
            media_ids.each do |id|
                mandocsfile = Mandocfile.where(id: id)
                if !mandocsfile.nil?
                    mandocsfile.update({mandoc_id: mandoc_id})
                end
            end
            # Cập nhật tráng thái văn bản đã xử lí, trạng thái đã đọc theo quy trình

        end
        redirect_to :back, notice: lib_translate("Successfully")
    end

    #Phòng ban chuyển văn bản lên Văn thư
    #@author: H.Anh + Hải
    #@date: 04/03/2023
    #

    def assign_handle_department
        action = params[:assign_handle_department]
        mandoc_id = params[:mandoc_id] #mandoc id
        contents = params[:contents] # contents
        deadline = params[:deadline] # deadline
        id_uhandle = params[:id_uhandle] # id_uhandle
        assign_to = [] # id nguoi duoc chon
        list_Trpp = []
        mandoc_contents = params[:mandoc_content_department]
        # if !contents.nil? || contents != ""
        #     contents =  contents.gsub(/\s+/, " ").strip
        # end
        media_ids = params[:media_ids] || []
        option_medias = params[:option_media] || []
        # save media
        media_ids.each do |id|
            mandocsfile = Mandocfile.where(id: id)
            option_medias.each do |option_media|
                if !mandocsfile.nil?
                    if option_media.include?(id) && option_media.include?("process")
                        mandocsfile.update({mandoc_id: mandoc_id, dtype: 'PROCESS'})
                    elsif option_media.include?(id) && option_media.include?("coordinate")
                        mandocsfile.update({mandoc_id: mandoc_id, dtype: 'COORDINATE'})
                    elsif option_media.include?(id) && option_media.include?("reference")
                        mandocsfile.update({mandoc_id: mandoc_id, dtype: 'REFERENCE'})
                    elsif option_media.include?(id) && option_media.include?("enact")
                        mandocsfile.update({mandoc_id: mandoc_id, dtype: 'ENACT'})
                    end
                end
            end
        end
        oUserORG = Uorg.where(user_id: session[:user_id]).first
        if !oUserORG.nil?
            organization_id = oUserORG.organization_id
        end

        oMandoc = Mandoc.where(id: mandoc_id).first
        if !oMandoc.nil?
            oMandoc&.mandocuhandles&.update({
                sread: "CO",
                status: "DAXULY"
            })
            oMandoc.touch
            oMandoc.save
        end
        # Lay ID Don vi theo so do
        department_id = nil
        users_arr = nil
        streams =  Operstream.where(organization_id: organization_id ).all
        streams.each do |e|
            e.stream_id
                stream =  Stream.where(id: e.stream_id).where("scode LIKE '%QLVB-VB-DI%'").first
                # stream = Stream.where("scode = 'QLVB-VB-DI'").first
                if stream.nil?
                    next
                elsif !stream.scode.include?("QLVB-VB-DI")
                    next
                else
                    firstNode = Node.where("stream_id = #{stream.id} AND nfirst = 'YES'").first
                    if !firstNode.nil?
                        department_id = Connect.where("stream_id = #{stream.id} AND nbegin = #{firstNode.department_id}").first.nend
                        if !department_id.nil?
                            positionjob_ids =  Positionjob.where("department_id = #{department_id}").pluck(:id)
                            @works = Work.where(positionjob_id: positionjob_ids ).pluck(:user_id)
                            users_arr = User.select("id").where(id: @works)
                            @arrUserid =  users_arr.ids
                            if !@arrUserid.nil?
                            @users_id = User.where(id: session[:user_id]).first.id
                            @checkDirectorsHandle = @arrUserid.include?(@users_id)
                            end
                        end
                    end
                end

        end
        # lưu vào mandocdhandle
        mandoc_handle = Mandocdhandle.create({
            mandoc_id: mandoc_id,
            department_id: department_id,
            contents: contents,
            deadline: deadline,
            status: "ACTIVE",
            srole: "XULY",
        })

        # lưu nhân sự ban lãnh đạo được chỉ định vào, người được chỉ định cụ thể sẽ được xử lý bằng form
        if !mandoc_handle.nil?
            @works.each do |assignment|
                oUserORG = Uorg.where(user_id: assignment).first
                if !oUserORG.nil?
                    organization_id = oUserORG.organization_id
                end
                oUserORG_login = Uorg.where(user_id: session[:user_id]).first
                if !oUserORG_login.nil?
                    organization_id_login = oUserORG_login.organization_id
                end
                if organization_id == organization_id_login
                    Mandocuhandle.create({
                        mandocdhandle_id: mandoc_handle.id,
                        user_id: assignment,
                        srole: "XULY",
                        sread: "KHONG",
                        deadline: mandoc_handle.deadline,
                        status: "CHUAXULY",
                        contents: contents,
                        sothers: "CHUYENVTXULY",
                    })

                    # danh sách trưởng - phó phòng
                    # bỏ ng dc assign_to ra

                    positionjob_ids_list = Positionjob.where("department_id = ? AND (scode LIKE ? OR scode LIKE ?)", mandoc_handle.department_id, "%TRUONG%", "%PHO%")
                    if !positionjob_ids_list.nil?
                        positionjob_ids_list.each do |positionjob|
                            works = Work.where(positionjob_id: positionjob.id)
                            if !works.nil?
                                works.each do |work|
                                    oUser = User.where(id: work.user_id).first
                                    if !oUser.nil?
                                        list_Trpp.push(oUser.id)
                                    end
                                end
                            end
                        end
                        list_Trpp.uniq
                    end
                    if list_Trpp.include?(assignment)
                        list_Trpp.delete(assignment)
                        if !list_Trpp.nil?
                            list_Trpp.each do |list|
                                Mandocuhandle.create({
                                    mandocdhandle_id: mandoc_handle.id,
                                    user_id: list,
                                    srole: "PHOIHOPXL",
                                    sread: "KHONG",
                                    deadline: mandoc_handle.deadline,
                                    status: "PHOIHOPXL",
                                    contents: contents
                                })
                            end
                        end
                    end
                end
                #CẬP NHẬT TRANG THÁI CHO VĂN BẢN
                mandoc = Mandoc.where(id: mandoc_id).first
                if !mandoc.nil?
                    if mandoc_contents.nil?
                        mandoc_contents = mandoc.contents
                    end
                    mandoc.update({
                        status: "INPROGRESS",
                        contents:mandoc_contents
                    })
                     # UserMailer.mandoc_handle(assignment, get_mediafile_mandoc(mandoc_id), mandoc_id, department_id, !get_department_from_user_login(session[:user_id]).nil? ? get_department_from_user_login(session[:user_id]).name : "",deadline, contents, 'Nhân viên', request.base_url).deliver_later
                end


            end
            media_ids.each do |id|
                mandocsfile = Mandocfile.where(id: id)
                if !mandocsfile.nil?
                    mandocsfile.update({mandoc_id: mandoc_id})
                end
            end



        end

        redirect_to :back, notice: lib_translate("Successfully")
    end

    def assign_handle_department_in
        action = params[:assign_handle_department]
        mandoc_id = params[:mandoc_id] #mandoc id
        contents = params[:contents_in] # contents
        deadline = params[:deadline_in] # deadline
        id_uhandle = params[:id_uhandle] # id_uhandle
        list_Trpp = []
        assign_to = [] # id nguoi duoc chon
        # if !contents.nil? || contents != ""
        #     contents =  contents.gsub(/\s+/, " ").strip
        # end
        # Lay ID Don vi theo so do
        department_id = nil
        users_arr = nil
        oUserORG = Uorg.where(user_id: session[:user_id]).first
        if !oUserORG.nil?
            organization_id = oUserORG.organization_id
        end
        streams =  Operstream.where(organization_id: organization_id ).all
                streams.each do |e|
                e.stream_id

                stream =  Stream.where(id: e.stream_id).where("scode LIKE '%QLVB-VB-TOI%'").first
                # stream = Stream.where("scode = 'QLVB-VB-TOI'").first
                if stream.nil?
                    next
                elsif !stream.scode.include?("QLVB-VB-TOI")
                    next
                else
                    firstNode = Node.where("stream_id = #{stream.id} AND nfirst = 'YES'").first
                    if !firstNode.nil?
                        department_id = Connect.where("stream_id = #{stream.id} AND nbegin = #{firstNode.department_id}").first.nbegin
                        if !department_id.nil?
                            positionjob_ids =  Positionjob.where("department_id = #{department_id}").pluck(:id)
                            @works = Work.where(positionjob_id: positionjob_ids ).pluck(:user_id)
                            users_arr = User.select("id").where(id: @works)
                        end
                    end
                end
                @arrUserid =  users_arr.ids
                if !@arrUserid.nil?
                @users_id = session[:user_id]
                @checkDirectorsHandle = @arrUserid.include?(@users_id)
                end
            end
        # lưu vào mandocdhandle
        if !deadline.nil?
            mandoc_handle = Mandocdhandle.create({
                mandoc_id: mandoc_id,
                department_id: department_id,
                contents: contents,
                deadline: deadline,
                status: "ACTIVE",
                srole: "XULY"
            })
        else
            mandoc_handle = Mandocdhandle.create({
                mandoc_id: mandoc_id,
                department_id: department_id,
                contents: contents,
                deadline: "",
                status: "ACTIVE",
                srole: "XULY"
            })
        end
        # lưu nhân sự ban lãnh đạo được chỉ định vào, người được chỉ định cụ thể sẽ được xử lý bằng form
        if !mandoc_handle.nil?
            @works.each do |assignment|
                oUserORG = Uorg.where(user_id: assignment).first
                if !oUserORG.nil?
                    organization_id = oUserORG.organization_id
                end
                oUserORG_login = Uorg.where(user_id: session[:user_id]).first
                if !oUserORG_login.nil?
                    organization_id_login = oUserORG_login.organization_id
                end
                if organization_id == organization_id_login
                    Mandocuhandle.create({
                        mandocdhandle_id: mandoc_handle.id,
                        user_id: assignment,
                        srole: "XULY",
                        sread: "KHONG",
                        deadline: mandoc_handle.deadline,
                        status: "CHUAXULY",
                        contents: contents
                    })

                    # danh sách trưởng - phó phòng
                    # bỏ ng dc assign_to ra

                    positionjob_ids_list = Positionjob.where("department_id = ? AND (scode LIKE ? OR scode LIKE ?)", mandoc_handle.department_id, "%TRUONG%", "%PHO%")
                    if !positionjob_ids_list.nil?
                        positionjob_ids_list.each do |positionjob|
                            works = Work.where(positionjob_id: positionjob.id)
                            if !works.nil?
                                works.each do |work|
                                    oUser = User.where(id: work.user_id).first
                                    if !oUser.nil?
                                        list_Trpp.push(oUser.id)
                                    end
                                end
                            end
                        end
                        list_Trpp.uniq
                    end
                    if list_Trpp.include?(assignment)
                        list_Trpp.delete(assignment)
                        if !list_Trpp.nil?
                            list_Trpp.each do |list|
                                Mandocuhandle.create({
                                    mandocdhandle_id: mandoc_handle.id,
                                    user_id: list,
                                    srole: "PHOIHOPXL",
                                    sread: "KHONG",
                                    deadline: mandoc_handle.deadline,
                                    status: "PHOIHOPXL",
                                    contents: contents
                                })
                            end
                        end
                    end
                end
                #CẬP NHẬT TRANG THÁI CHO VĂN BẢN
                oMandoc = Mandoc.where(id: mandoc_id).first
                if !oMandoc.nil?
                    oMandoc.update({
                        status: "INPROGRESS"
                    })
                     # UserMailer.mandoc_handle(assignment, get_mediafile_mandoc(mandoc_id), mandoc_id, department_id, !get_department_from_user_login(session[:user_id]).nil? ? get_department_from_user_login(session[:user_id]).name : "", deadline, contents, 'Nhân viên', request.base_url).deliver_later
                end
            end

            oMandocuhandles = Mandocuhandle.where(id: id_uhandle).last
            if !oMandocuhandles.nil?
                oMandocuhandles.update({
                    sread: "CO",
                    status: "DAXULY"
                    })
            end

        end
        redirect_to :back, notice: lib_translate("Successfully")
    end

    # Huy review code 19/09/2023
    def assign_handle_department_tchc
        action = params[:assign_handle_department]
        mandoc_id = params[:mandoc_id] #mandoc id
        contents = params[:contents_in] # contents
        deadline = params[:deadline_in] # deadline
        id_uhandle = params[:id_uhandle] # id_uhandle
        department_id = params[:department_id]
        assign_to = params[:assign_to]# id nguoi duoc chon
        msg = lib_translate("Not_Success")
        # if !contents.nil? || contents != ""
        #     contents =  contents.gsub(/\s+/, " ").strip
        # end
        list_Trpp = []
        # Lay ID Don vi theo so do

        # lưu vào mandocdhandle
        if !deadline.nil?
            mandoc_handle = Mandocdhandle.create({
                mandoc_id: mandoc_id,
                department_id: department_id,
                contents: contents,
                deadline: deadline,
                status: "ACTIVE",
                srole: "XULY"
            })
        else
            mandoc_handle = Mandocdhandle.create({
                mandoc_id: mandoc_id,
                department_id: department_id,
                contents: contents,
                deadline: "",
                status: "ACTIVE",
                srole: "XULY"
            })
        end
        mandoc_handle_last_hd = Mandocdhandle.where(mandoc_id: mandoc_id, department_id: department_id).last
        # lưu nhân sự ban lãnh đạo được chỉ định vào, người được chỉ định cụ thể sẽ được xử lý bằng form
        if !mandoc_handle_last_hd.nil?
            oUserORG = Mandoc.where(id: mandoc_id).first
            oUserORG_login = Uorg.where(user_id: session[:user_id]).first
            if !oUserORG.nil?
                organization_id = oUserORG.organization_id
            end
            if !oUserORG_login.nil?
                organization_id_login = oUserORG_login.organization_id
            end
            if organization_id == organization_id_login
                oMandoc = Mandoc.where(id: mandoc_id).first
                if !oMandoc.nil?
                    oMandoc.update({
                        status: "INPROGRESS"
                    })
                    oMandoc&.mandocuhandles&.update({
                        sread: "CO",
                        status: "DAXULY"
                    })
                    Mandocuhandle.create({
                        mandocdhandle_id: mandoc_handle_last_hd.id,
                        user_id: assign_to,
                        srole: "XULY",
                        sread: "KHONG",
                        deadline: mandoc_handle_last_hd.deadline,
                        status: "CHUAXULY",
                        contents: contents,
                        sothers: "TPXULY",
                    })

                    # danh sách trưởng - phó phòng
                    # bỏ ng dc assign_to ra

                    positionjob_ids_list = Positionjob.where("department_id = ? AND (scode LIKE ? OR scode LIKE ?)", department_id, "%TRUONG%", "%PHO%")
                    if !positionjob_ids_list.nil?
                        positionjob_ids_list.each do |positionjob|
                            works = Work.where(positionjob_id: positionjob.id)
                            if !works.nil?
                                works.each do |work|
                                    oUser = User.where(id: work.user_id).first
                                    if !oUser.nil?
                                        list_Trpp.push(oUser.id)
                                    end
                                end
                            end
                        end
                        list_Trpp.uniq
                        if list_Trpp.include?(assign_to.to_i)
                            list_Trpp.delete(assign_to.to_i)
                            if !list_Trpp.nil?
                                list_Trpp.each do |list|
                                    Mandocuhandle.create({
                                        mandocdhandle_id: mandoc_handle_last_hd.id,
                                        user_id: list,
                                        srole: "PHOIHOPXL",
                                        sread: "KHONG",
                                        deadline: mandoc_handle_last_hd.deadline,
                                        status: "PHOIHOPXL",
                                        contents: contents
                                    })
                                end
                            end
                        end
                    end
                    msg = lib_translate("Successfully")
                end
            end
        end
        redirect_to :back, notice: msg
    end

    def confirm_mandoc
        mandoc_id = params[:mandoc_id]
        id_uhandle = params[:id_uhandle]
        oMandoc = Mandoc.where(id: mandoc_id).first
        if !oMandoc.nil?
            oMandoc.update({
                status: "INACTIVE"
            })
            oMandoc&.mandocuhandles&.update({
                sread: "CO",
                status: "DAXULY"
            })
        end
        redirect_to :back, notice: lib_translate("Successfully")
    end

    def cancel_mandoc
        mandoc_id = params[:mandoc_id]
        id_uhandle = params[:id_uhandle]
        oMandoc = Mandoc.where(id: mandoc_id).first
        if !oMandoc.nil?
            oMandoc.update({
                status: "DELETE"
            })
            oMandoc&.mandocuhandles&.update({
                sread: "CO",
                status: "DAXULY"
            })
        end
        redirect_to :back, notice: lib_translate("Successfully")
    end
    # Get department from user login
    # @author: Huy + H.Anh + Đồng
    # @date: 08/02/2023
    #
    def get_department_from_user_login(user_id)
        oDepartment = nil
        @user = User.where(id: user_id).first
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
        oDepartment
    end

    def get_department_from_userlogin(user_id)
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
    # Get list user in department from user login
    # @author: Huy + H.Anh + Đồng
    # @date: 08/02/2023
    #
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

    # Get list mediafile mandoc from Mandocfile
    # @author: Huy
    # @date: 17/02/2023
    #
    def get_mediafile_mandoc(mandoc_id)
        sql_result = []
        oMandocfiles = Mandocfile.where(mandoc_id: mandoc_id)
        if !oMandocfiles.nil?
            oMandocfiles.each do |mandocfile|
                oMediafiles = Mediafile.where(id: mandocfile.mediafile_id)
                if !oMediafiles.nil?
                    oMediafiles.each do |mediafile|
                        if mediafile.file_size.to_i < 13631488
                            sql_result.append("/data/hrm/" + mediafile.file_name)
                        end
                    end
                end
            end
        end
        sql_result
    end

    # Get list mandoc with user login
    # @author: Hai
    # @date: 16/02/2023
    #
    def get_list_mandocs_with_user_login(idu)
        sql_result=[]
        @user = User.where(id: idu).first
        if !@user.nil?
            id_dhandles = Mandocuhandle.where(user_id: idu).pluck(:mandocdhandle_id)
            if !id_dhandles.nil?
                id_dhandles.each do |id_d|
                    arr_mandocis = Mandocdhandle.where(id: id_d).pluck(:mandoc_id)
                    id_mandoc = Mandoc.where(id: arr_mandocis).where("status != 'INACTIVE'").pluck(:id)
                    if !id_mandoc.nil?
                        id_mandoc.each do |id_m|
                            # list_mandoc = Mandoc.where(id: id_m).first
                            list_mandoc = Mandocdhandle.joins(:mandoc).select("mandocs.*,mandocdhandles.created_at as created_at, mandocdhandles.department_id as department_id,mandocdhandles.contents as dhandle_contents").where("mandocdhandles.mandoc_id = #{id_m}").order(:created_at).last

                            sql_result.append(list_mandoc)
                        end
                    end
                end
            end
            return sql_result.reverse.uniq
        end
    end


    # Delete mandoc is PENDING
    # @author: Hai
    # @date: 27/02/2023
    #
    def destroy
        id = params[:manid]
        @mandoc = Mandoc.where("id = #{id}").first
        @mandoc.destroy
        redirect_to :back , notice: lib_translate("delete_message")
    end

    # Ban hành văn bản đến, gọi từ form ban hành văn bản của văn thư
    # @author: Huy
    # @date: 14/03/2023
    # Cập nhật status => INACTIVE và ngày ban hành là ngày nhấn vào nút ban hành

    def release_docs
        id = params[:mandoc_id]
        mandoc = Mandoc.where(id: id).first
        sNo = params[:release_sno]
        sSymbol = params[:release_symbol]
        effective_date = params[:effective_date]
        received_at = params[:received_at]
        release_mandoc_type = params[:release_mandoc_type]
        select_department = params[:select_release_department]
        department_send_email = params[:department_send_email]
        select_staff = params[:select_release_staff]
        subject_email = params[:subject_email]
        content_email = params[:content_email]
        media_ids = params[:media_ids] || []
        option_medias = params[:option_media] || []
        msg = lib_translate("Successfully")
        oUserORG = Uorg.where(user_id: session[:user_id]).first
        organization_id = ''
        if !oUserORG.nil?
            organization_id = oUserORG.organization_id
        end
        if !mandoc.nil?
            mandoc&.mandocuhandles&.update({
                sread: "CO",
                status: "DAXULY"
            })
            mandoc.touch
            mandoc.save
            man_type = mandoc.stype
            value_sno_out = Mandoc.where(stype: man_type).where("sfrom is null AND YEAR(created_at) = YEAR(CURRENT_DATE())").where(organization_id: organization_id).select(:sno).last
            @count_man_out = value_sno_out&.sno.to_i + 1
            if release_mandoc_type == "incoming"
                mandoc.update({
                    status: "INACTIVE"
                })

                log_history( "Số: #{mandoc.sno} - Ký hiệu: #{mandoc.ssymbol}", mandoc.contents, "Ngày ban hành: #{mandoc.received_at&.strftime("%d/%m/%Y")}"  , "Ngày ban hành: #{mandoc.effective_date&.strftime("%d/%m/%Y")}", @current_user.email)
            elsif release_mandoc_type == "outgoing"
                mandoc_params = {
                    status: "INACTIVE",
                    publish_email_subject: subject_email,
                    publish_email_content: content_email,
                }
                mandoc_params[:effective_date] = effective_date if effective_date.present?
                mandoc_params[:sno] = sNo if sNo.present?
                mandoc_params[:ssymbol] = sSymbol if sSymbol.present?
                mandoc_params[:received_at] = received_at if received_at.present?
                mandoc_params[:publish_to_departments] = mandoc.publish_to_departments.presence ? mandoc.publish_to_departments.to_s.concat(", ", select_department&.join(", ")) : select_department&.join(", ") if select_department.present?
                mandoc_params[:publish_to_staffs] = mandoc.publish_to_staffs.presence ? mandoc.publish_to_staffs.to_s.concat(", ", select_staff&.join(", ")) : select_staff&.join(", ") if select_staff.present?
                mandoc.update(mandoc_params)

                begin
                    arrEmail = []
                    validEmails = []
                    url_files = []
                    url_files_big = []
                    count = 0
                    # Lấy danh sách file của văn bản được ban hành
                    if !media_ids.nil?
                        oMandocfiles = Mandocfile.where(id: media_ids&.uniq)
                        if !oMandocfiles.nil?
                            oMandocfiles.each do |mandocfile|
                                oMediafiles = Mediafile.where(id: mandocfile.mediafile_id)
                                if !oMediafiles.nil?
                                    oMediafiles.each do |mediafile|
                                        if mediafile.file_size.to_i < 23.megabytes
                                          url_files.append("/data/hrm/" + mediafile.file_name)
                                        else
                                              count = count + 1
                                              logger.info "Số lượng #{count} "
                                              if mediafile.file_type.include?("application/pdf")
                                                icon_path = "#{request.base_url}/assets/image/bmtu_pdf.png"
                                                file_type = "pdf"
                                              elsif mediafile.file_type.include?("application/vnd.openxmlformats-officedocument.presentationml.presentation")
                                                icon_path = "#{request.base_url}/assets/image/bmtu_powerpoint.png"
                                                file_type = "powerpoint"
                                              elsif mediafile.file_type.include?("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
                                                icon_path = "#{request.base_url}/assets/image/bmtu_excel.png"
                                                file_type ="excel"
                                              elsif mediafile.file_type.include?("application/vnd.openxmlformats-officedocument.wordprocessingml.document")
                                                icon_path = "#{request.base_url}/assets/image/bmtu_word.png"
                                                file_type = "word"
                                              elsif mediafile.file_type.include?("application/x-zip-compressed") || mediafile.file_type.include?("application/octet-stream")
                                                icon_path = "#{request.base_url}/assets/image/bmtu_zip.png"
                                                file_type = "zip"
                                              else
                                                icon_path = "#{request.base_url}/assets/image/bmtu_file.png"
                                                file_type = "file"
                                              end
                                              url_files_big.append({
                                                :name => mediafile.file_name,
                                                :icon_path => icon_path,
                                                :file_type => file_type,
                                                :file_size => bytes_to_human_size(mediafile.file_size),
                                                :path => "#{request.base_url}/mdata/hrm/#{mediafile.file_name}"
                                              })
                                        end
                                    end
                                end
                            end
                        end
                    end

                    # Lấy danh sách email nhân sự được chọn
                    if select_staff.nil?
                    elsif select_staff.include?('all')
                        if !session[:user_id].nil?
                            arrOrgScode = User.where(id: session[:user_id]).first&.organizations&.pluck(:scode)
                            if arrOrgScode.include?('BMTU')
                                arrEmail += ["allstaffs@bmtuvietnam.com"]
                            end
                            if arrOrgScode.include?('BMU')
                                arrEmail += ["allstaffs@bmtuvietnam.com"]
                            end
                            if arrOrgScode.include?('BUH')
                                arrEmail += ["allstaff@benhvienbmt.com"]
                            end
                        end
                    else
                        email_user = User.where(id: select_staff).pluck(:email)
                        arrEmail += email_user
                    end

                    # Lấy danh sách email đơn vị được chọn
                    if select_department.nil?
                    elsif select_department.include?('all')
                        if !session[:user_id].nil?
                            arrOrgScode = User.where(id: session[:user_id]).first&.organizations&.pluck(:scode)
                            if arrOrgScode.include?('BMTU')
                                arrEmail += ["allstaffs@bmtuvietnam.com"]
                            end
                            if arrOrgScode.include?('BMU')
                                arrEmail += ["allstaffs@bmtuvietnam.com"]
                            end
                            if arrOrgScode.include?('BUH')
                                arrEmail += ["allstaff@benhvienbmt.com"]
                            end
                        end
                    else
                        # lấy danh sách email đơn vị
                        oDepartments = Department.where(id: select_department)
                        oDepartments.each do |department|
                            if !department.email.nil? && department.email != ""
                                arrEmail.push(department.email)
                            else
                                email_user = User.joins(works: :positionjob).where(works: { positionjob_id: Positionjob.where(department_id: department.id) }).pluck(:email)
                                arrEmail += email_user
                            end
                        end
                    end

                    # Kiểm tra email và log danh sách email được gửi
                    arrEmail = arrEmail.uniq
                    logger.info "Email gốc #{arrEmail}"
                    arrEmail.each do |email|
                        if valid_email?(email)
                            logger.info "Email sẽ được gửi đến #{email}"
                            validEmails.push(email)
                        end
                    end
                    logger.info "Email chuẩn bị gửi đến sau khi kiểm tra #{validEmails}"

                    # Tiến hành gửi email đến danh sách email
                    UserMailer.release_mandoc(validEmails, subject_email, content_email, url_files, url_files_big, mandoc, count, department_send_email).deliver_later
                rescue => e
                    msg = e.message
                    logger.info "Lỗi khi gửi email #{e.message}"
                end

                log_history( "Số: #{sNo} - Ký hiệu: #{sSymbol}", mandoc.notes, "Ngày ban hành: #{mandoc.received_at&.strftime("%d/%m/%Y")}"  , "Ngày bắt đầu hiệu lực: #{mandoc.effective_date&.strftime("%d/%m/%Y")}", @current_user.email)
            end
        end
        # save media
        media_ids&.uniq.each do |media_id|
            mandocsfile = Mandocfile.where(id: media_id)
            if !mandocsfile.nil?
                mandocsfile.update({mandoc_id:id , dtype: 'ENACT'})
            end
        end
        redirect_to :back, notice: msg
    end

    def bytes_to_human_size(bytes)
        units = ['Bytes', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB']
        size = bytes.to_f
        unit = 0

        while size >= 1024 && unit < units.length - 1
          size /= 1024
          unit += 1
        end

        format('%.2f %s', size, units[unit])
    end

    def send_email_test
        id = params[:mandoc_id]
        media_ids = params[:media_ids]&.split(",") || []
        email_test = params[:email_test]
        subject_email = params[:subject_email]
        content_email = params[:content_email]
        department_send_email = params[:department_send_email]
        mandoc = Mandoc.where(id: id).first
        UserMailer.release_mandoc_test(email_test, subject_email, content_email, media_ids, mandoc, request.base_url, department_send_email).deliver_later
        render json: { location: "Đã gửi thành công" }
    end

    def valid_email?(email)
        email_regex = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
        return email.match?(email_regex)
    end

    def save_release_docs
        id = params[:mandoc_id]
        mandoc = Mandoc.where(id: id).first
        sNo = params[:release_sno].to_i
        sSymbol = params[:release_symbol]
        oUserORG = Uorg.where(user_id: session[:user_id]).first
        organization_id = ''
        media_ids = params[:media_ids] || []
        option_medias = params[:option_media] || []
        if !oUserORG.nil?
            organization_id = oUserORG.organization_id
        end
        if !mandoc.nil?
            man_type = mandoc.stype
            value_sno_out = Mandoc.where(stype: man_type).where("sfrom is null AND YEAR(created_at) = YEAR(CURRENT_DATE())").where(organization_id: organization_id).select(:sno).last # Retrieve the count from the database based on the selected stype
            @count_man_out = value_sno_out&.sno.to_i + 1
            mandoc_params = {
                sno: sNo,
                ssymbol: sSymbol,
                status: "INACTIVE",
            }
            mandoc.update(mandoc_params)
            dhandle_id =  Mandocdhandle.where(mandoc_id: id).pluck(:id)
            oUhandle =  Mandocuhandle.where(mandocdhandle_id: dhandle_id)
            if !oUhandle.nil?
                oUhandle.update(
                    sread: "CO",
                    status: "DAXULY"
                )
            end
            media_ids.each do |id|
                mandocsfile = Mandocfile.where(id: id)
                option_medias.each do |option_media|
                    if !mandocsfile.nil?
                            mandocsfile.update({mandoc_id: mandoc.id, dtype: 'ENACT'})
                    end
                end
            end
        end
        redirect_to :back, notice: lib_translate("Successfully")
    end

    def find_one
        mandoc_id = params[:mandoc_id]
        func_name = params[:func_name]
        fullname = params[:fullname]
        oMandoc = Mandoc.where(id: mandoc_id).first
        listfiles = []
        # if fullname.nil?
            mandoc_medias = Mandocfile.where(mandoc_id: mandoc_id).order(created_at: :desc)
            mandoc_medias.each do |y|
                listfiles.push({
                  id: y.id,
                  relative_id: y.mandoc_id,
                  file_name: y.mediafile.file_name,
                  created_at: y.created_at.strftime('%H:%M %d/%m/%Y'),
                  dtype: y.dtype,
                  file_owner: y.mediafile.owner
                })
            end
        # else
        #     mandoc_medias =Mandocfile.joins(:mediafile).select('mandocfiles.*').where(mandoc_id: mandoc_id).where("mediafiles.owner LIKE ?", "%#{fullname}%").order(created_at: :desc)
        #     mandoc_medias.each do |y|
        #         listfiles.push({
        #           id: y.id,
        #           relative_id: y.mandoc_id,
        #           file_name: y.mediafile.file_name,
        #           created_at: y.created_at.strftime('%H:%M %d/%m/%Y'),
        #           dtype: y.dtype,
        #           file_owner: y.mediafile.owner
        #         })
        #     end
        # end
        respond_to do |format|
            format.js { render js: "#{func_name}(#{oMandoc.to_json.html_safe},#{listfiles.to_json.html_safe})"}
        end
    end

    def outgoing_export_pdf
        mandoc_id = params[:mandoc_id]
        mandoc = Mandoc.where(id: mandoc_id).first
        scontent_pdf = mandoc&.contents || ""
        filename = mandoc&.notes || ""

        if filename.empty?
            filename =  "Văn bản #{Time.now.strftime("%d-%m-%Y")}"
        end

        pdf = WickedPdf.new.pdf_from_string(scontent_pdf.html_safe,
            encoding: "UTF-8",
            layout:'layouts/pdf/mandoc_layout.html.erb',
            template:'layouts/pdf/mandoc_layout.html.erb',
            margin: { :top => 20, :bottom => 20, :left => 10, :right => 10})
        send_data pdf,  type: 'application/pdf',
        disposition: 'attachment',
        filename:"#{filename}.pdf"
    end

    def search_index
        @mandocbooks = Mandocbook.all
        @mandoctypes = Mandoctype.all
        @mandocpriorities = Mandocpriority.all
        @orgs = Organization.all
    end

    # Tìm kiếm văn bản, gọi từ form remote
    # author: H.Vu
    # last updated: 01/04/2023
    def search_mandoc
      datas_result = []

      # search
      search = params[:search]
      mandoc_stype = params[:mandoc_stype]
      type_book = params[:type_book]
      dt_from = params[:dt_from]
      dt_to = params[:dt_to]
      in_work = params[:in_work]

      # pagin
      page = params[:page]&.to_i
      per_page = params[:per_page] || 10

      search.strip! if search.present?

      begin
        # tổ chức của người dùng
        user_orgs = Uorg.where(user_id: session[:user_id]).pluck(:organization_id)
        # check "van thu" can view
        is_vanthu = is_access(session[:user_id], "MANDOCS-SEARCH","ADM")
        # Permission: can edit
        can_edit = is_access(session[:user_id], "MANDOCS-SEARCH","EDIT")

        mandocs = Mandoc.where("notes LIKE '%#{search}%' OR contents LIKE '%#{search}%' OR ssymbol LIKE '%#{search}%' OR sno LIKE '%#{search}%'")
                        .where(organization_id: user_orgs)
                        .where(status: 'INACTIVE')

        # Loại sổ
        if type_book.present?
          mandocs = mandocs.where("type_book = ?",type_book)
        end

        # Loại văn bản
        mandocs = mandocs.where("stype = ?",mandoc_stype) if mandoc_stype.present?

        # Ngày nhận
        mandocs = mandocs.where("received_at >= ? ",Date.parse(dt_from)) if dt_from.present?

        # ngày kết thúc
        mandocs = mandocs.where("effective_date <= ? ",Date.parse(dt_to)) if dt_to.present?

        if in_work.present?  # con hieu luc
          mandocs = mandocs.where("end_date > current_date OR end_date IS NULL") if in_work == "on"
          mandocs = mandocs.where("end_date IS NOT NULL end_date <= current_date") if in_work == "off"
        end
        
        if !is_vanthu
          uid = session[:user_id]
          dept_id = nil
          user = User.find(uid)
          user.works.each do |work|
              if !work.positionjob.nil? && !work.positionjob.department.nil?
                dept_id = work.positionjob.department.id
              end
          end
            mandocs = mandocs.where("publish_to_staffs LIKE ? OR publish_to_staffs LIKE ? OR publish_to_staffs LIKE ? OR publish_to_staffs LIKE ? OR publish_to_staffs LIKE ?
                            OR publish_to_departments LIKE ? OR publish_to_departments LIKE ? OR publish_to_departments LIKE ? OR publish_to_departments LIKE ? OR publish_to_departments LIKE ?",
                            '%all%',uid, "#{uid},%", "%, #{uid},%", "%, #{uid}%",
                            '%all%',dept_id, "#{dept_id},%", "%, #{dept_id},%", "%, #{dept_id}%")
        end

        # pagin handle
        per_page = 10 if per_page.to_i == 0
        result = pagination_limit_offset(mandocs, per_page.to_i)
        pagin_render = render_pagination_limit_offset('', 10,result.count)

        # query result to array hash
        result.each do |mandoc|
          file_name = mandoc.mandocfile.last&.mediafile&.file_name
          file_path = !file_name.nil? ?  "/mdata/hrm/" + mandoc.mandocfile.last&.mediafile&.file_name : nil
          still_effect = true
          if !mandoc.dchild.nil?
            still_effect = false
          elsif !mandoc.end_date.nil?
            still_effect = mandoc.end_date >= DateTime.now
          end
            datas_result.push({
              id: mandoc.id,
              ssymbol:mandoc.ssymbol,
              received_at: mandoc.received_at&.strftime("%d/%m/%Y") || '',
              effective_date: mandoc.effective_date&.strftime("%d/%m/%Y") || '',
              on_work: still_effect,
              dchild:mandoc.dchild,
              sno:mandoc.sno,
              notes: !mandoc.sfrom.nil? ? mandoc.contents : mandoc.notes,
              file_path: file_path
            })
        end
        # result data
        datas = {
          results: datas_result,
          can_edit:can_edit,
          pagin_items: pagin_render,
          start_index: (session[:per_page] * (page - 1)) + 1
        }

        respond_to do |format|
          format.js { render js: "loadSearchResult(#{datas.to_json.html_safe});console.log(#{params.to_json.html_safe})"}
        end
      rescue StandardError => ex
        respond_to do |format|
          format.js { render js: "onSearchError(#{ex.to_json.html_safe})"}
        end
      end

    end

    def mandoc_un_effect
        mandoc_id = params[:mandoc_id]
        date_expire = params[:date_expire]
        select_dchild = params[:select_dchild]
        dchild = params[:dchild] || ''
        mandoc = Mandoc.where(id: mandoc_id).first
        result = {
            mandoc_id: mandoc_id,
            status: true,
            dchild:dchild,
            msg:lib_translate('Edit_successfully')
        }
        can_edit = is_access(session["user_id"], "MANDOCS-SEARCH","EDIT")
        if !can_edit
            result[:status] = false
            result[:dchild] = ''
            result[:msg] = lib_translate('Unauthorized')
            return;
        end

        if !mandoc.nil?
            if !select_dchild.nil?
                dchild_mandoc = Mandoc.where(id:dchild).first
                if !dchild_mandoc.nil? && !dchild.empty?
                    if dchild != mandoc.ssymbol
                        mandoc.update({
                            dchild: dchild
                        })
                    else
                        result[:status] = false
                        result[:dchild] = ''
                        result[:msg] = lib_translate('Invalid_alt_doc')
                    end
                else
                    result[:status] = false
                    result[:dchild] = ''
                    result[:msg] = lib_translate('Alt_doc_does_not_exist')
                end
            else
                mandoc.update({
                    end_date: date_expire
                })
            end
        else
            result[:status] = false
            result[:msg] = lib_translate('Mandoc_not_exist')
        end

        respond_to do |format|
            format.js { render js: "onUnEffectMandoc(#{result.to_json.html_safe})"}
        end
    end

    def mandoc_select_search
        search = params[:search]
        page = params[:page]&.to_i || 1
        item_page = params[:item_page]&.to_i || 5
        query_with_search = "(CASE WHEN sfrom IS NULL THEN notes LIKE '%#{search}%' ELSE contents LIKE '%#{search}%' END OR sno LIKE '%#{search}%')"
        query_with_status = "AND (dchild IS NULL AND (end_date > current_date || end_date IS NULL))"
        query_with_activate = "AND (status = 'INACTIVE')"
        mandocs = Mandoc.where("#{query_with_search} #{query_with_status} #{query_with_activate}")
                        .limit(item_page).offset(item_page * (page-1))
        total_item_count = Mandoc.where("#{query_with_search} #{query_with_status} #{query_with_activate}").count
        load_more = page * item_page < total_item_count
        datas = {
            results:mandocs,
            pagination: {
                more: load_more
            }
        }
        respond_to do |format|
            format.js { render json: datas}
        end
    end

    #get mandocs status
    def get_mandocs_status_in
        organization_id = ''
        @mandocWithDepartment = get_list_mandocs_with_department(session[:user_id], true)
        oUserORG = Uorg.where(user_id: session[:user_id]).first
        if !oUserORG.nil?
            organization_id = oUserORG.organization_id
        end
        streams = Operstream.where(organization_id: organization_id).all
            if streams.empty?
                redirect_to operstream_index_path(lang: session[:lang]) and return
            else
                streams.each do |e|
                    stream = Stream.where(id: e.stream_id).where("scode LIKE '%QLVB-VB-TOI%'").first
                    if stream.nil?
                        next
                    elsif !stream.scode.include?("QLVB-VB-TOI")
                        next
                    else
                        firstNode = Node.where("stream_id = #{stream.id} AND nfirst = 'YES'").first
                        if !firstNode.nil?
                            @first_name_department = Department.where(id: firstNode.department_id).first&.name
                        end
                    return
                    end
                end
            end
    end

    def get_mandocs_status_out
        @mandocWithDepartmentOut = get_list_mandocs_with_departments(session[:user_id], false)
    end

    def get_mandocs_status_processed
        @mandocWithULogin = get_list_mandocs_with_user_login(session[:user_id])
    end

    def get_list_mandocs_with_departments(idu, check)
        sql_result=[]
        search = params[:search] || ''
        @user = User.where(id: idu).first
        oUhandle = Mandocuhandle.where(user_id: idu).order(created_at: :desc)
        arr_usser_current_mandoc = []
        if !oUhandle.nil?
            oUhandle.each do |manprocess|
                if !manprocess.mandocdhandle.nil?
                    if !manprocess.mandocdhandle.mandoc.nil?
                        mandoc_id = manprocess.mandocdhandle.mandoc.id
                        arr_usser_current_mandoc.push(mandoc_id).uniq
                    end
                end
            end
        end

        if !@user.nil?
            oDepatment = get_department_from_userlogin(idu)
            if !oDepatment.nil?
                oDepatment.each do |department|
                    oDHandles = Mandocdhandle.where(department_id: department.id).order(created_at: :desc)
                    if !oDHandles.nil?

                        oDHandles.each do |id_man|
                            if !id_man.mandoc_id.nil?
                                if check == true
                                    arrMan = Mandoc.where("id = #{id_man.mandoc_id} AND sfrom IS NOT NULL AND status != 'INACTIVE'").first

                                    if  !arrMan.nil? && arr_usser_current_mandoc.include?(arrMan.id)
                                        sql_result.append(arrMan)
                                    end
                                else
                                    arrMan = Mandoc.where("id = #{id_man.mandoc_id} AND sfrom IS NULL AND status != 'INACTIVE'").first
                                    if  !arrMan.nil? && arr_usser_current_mandoc.include?(arrMan.id)
                                        sql_result.append(arrMan)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
        return sql_result.uniq
    end

    def get_list_mandocs_with_department(idu, check)
            sql_result=[]
            search = params[:search] || ''
            @user = User.where(id: idu).first
            oUhandle = Mandocuhandle.where(user_id: idu).order(created_at: :desc)
            arr_usser_current_mandoc = []
            if !oUhandle.nil?
                oUhandle.each do |manprocess|
                    if !manprocess.mandocdhandle.nil?
                        if !manprocess.mandocdhandle.mandoc.nil?
                            mandoc_id = manprocess.mandocdhandle.mandoc.id
                            arr_usser_current_mandoc.push(mandoc_id).uniq
                        end
                    end
                end
            end

            if !@user.nil?
                oDepatment = get_department_from_user_login(idu)
                if !oDepatment.nil?
                    oDHandles = Mandocdhandle.where(department_id: oDepatment.id).order(created_at: :desc)
                    if !oDHandles.nil?

                        oDHandles.each do |id_man|
                            if !id_man.mandoc_id.nil?
                                if check == true
                                    arrMan = Mandoc.where("id = #{id_man.mandoc_id} AND sfrom IS NOT NULL AND status != 'INACTIVE'").first

                                    if  !arrMan.nil? && arr_usser_current_mandoc.include?(arrMan.id)
                                        sql_result.append(arrMan)
                                    end
                                else
                                    arrMan = Mandoc.where("id = #{id_man.mandoc_id} AND sfrom IS NULL AND status != 'INACTIVE'").first
                                    if  !arrMan.nil? && arr_usser_current_mandoc.include?(arrMan.id)
                                        sql_result.append(arrMan)
                                    end
                                end
                            end
                        end
                    end
                end
            end
            return sql_result.uniq
    end

    # Dat ADD 06/09/2023
    def vt_add_comment
            mandoc_id = params[:mandoc_id]
            comments = params[:comment_VT]
            oMandoc = Mandoc.where(id: mandoc_id).first
            msg = lib_translate("Not_Success")
            strTime =  Time.now.strftime("%H:%M:%S %d/%m/%Y")
            strComment =
            "<tr class='row ms-2 me-2'>
                <td style='border-width: 0px 0px 1px 0px;border-color: var(--falcon-badge-soft-info-background-color);' class='ps-3 pe-3 col-2'> #{strTime}  </td>
                <td style='border-width: 0px 0px 1px 0px;border-color: var(--falcon-badge-soft-info-background-color);' class='ps-3 pe-3 col-7'> #{comments} </td>
                <td style='border-width: 0px 0px 1px 0px;border-color: var(--falcon-badge-soft-info-background-color);' class='ps-3 pe-3 col-3'> #{@current_user.last_name} #{current_user.first_name}</td>
            </tr>"

            if !oMandoc.nil?
                strContents = "#{strComment} #{oMandoc.comment}"
                oMandoc.update({
                    comment: strContents,
                })
            msg = lib_translate('Edit_successfully')
            end
            redirect_to :back , notice: msg

    end

end
