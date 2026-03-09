class SessionsController < ApplicationController
    layout "papplication"
    skip_before_action :verify_authenticity_token, :check_user_login
    before_action :set_locale

    def redirect_to_straining
        session[:per_sftraining] = false
        session.delete(:show_system)
        if is_access(session["user_id"], "SFTRAINING","READ")
            session[:per_sftraining] = true
            oUser = User.where(id: session["user_id"]).first
            session[:user_avatar] = ""
            if !oUser.nil?
                session[:user_avatar] = Mediafile.where(id: oUser&.avatar).first&.file_name
                session[:user_fullname] = oUser.last_name + " " + oUser.first_name
                session[:user_id_login] = oUser.id
                session[:user_sid_login] = oUser.sid
                session[:user_email_login] = oUser.email
                session[:login] = true
                work = oUser.works.where("positionjob_id IS NOT NULL").first
                works = oUser.works.where("positionjob_id IS NOT NULL").pluck(:positionjob_id)
                positionjobs = Positionjob.where(id: works)
                session[:department] = positionjobs.pluck(:department_id)
                session[:departments] = positionjobs.joins(:department).select("departments.id,departments.name")
                if !work&.positionjob.nil? && !work&.positionjob&.department.nil?
                    session[:arrWorkName] = work&.positionjob&.name
                    session[:department_id] = work&.positionjob&.department&.id
                    session[:department_name] = work&.positionjob&.department&.name
                    session[:department_stype] = work&.positionjob&.department&.stype
                    session[:department_faculty] = work&.positionjob&.department&.faculty
                    session[:arrWorkScode] = work&.positionjob&.scode
                end
                session[:organization] = Organization.where(id: oUser.uorgs.pluck(:organization_id)).pluck(:scode)
            end
            system = params[:system]
            if system == "sftraining-lms"
                redirect_to url_for("/sftraining/lms/index?lang=vi")
            else
                redirect_to url_for("/sftraining/dashboard/index?lang=vi")
            end
        else
            session[:per_sftraining] = false
            redirect_to :back, notice: "Bạn không có quyền truy cập trang này"
        end
    end

    def redirect_to_assets
        system = params[:system]
        resource = params[:resource]
        page = params[:page] || ""
        session[:per_assets] = false
        session.delete(:show_system)
        url = params[:url]
        if is_access(session["user_id"], resource,"READ")
            session[:per_assets] = true
            oUser = User.where(id: session["user_id"]).first
            session[:user_avatar] = ""
            if !oUser.nil?
                session[:user_avatar] = Mediafile.where(id: oUser&.avatar).first&.file_name
                session[:user_fullname] = oUser.last_name + " " + oUser.first_name
                session[:user_id_login] = oUser.id
                session[:user_email_login] = oUser.email
                session[:asset_login] = true
                work = oUser.works.where("positionjob_id IS NOT NULL").first
                works = oUser.works.where("positionjob_id IS NOT NULL").pluck(:positionjob_id)
                positionjobs = Positionjob.where(id: works)
                session[:department] = positionjobs.pluck(:department_id)
                if !work&.positionjob.nil? && !work&.positionjob&.department.nil?
                    session[:arrWorkName] = work&.positionjob&.name
                    session[:department_id] = work&.positionjob&.department&.id
                    session[:department_name] = work&.positionjob&.department&.name
                    session[:department_stype] = work&.positionjob&.department&.stype
                    session[:arrWorkScode] = work&.positionjob&.scode
                end
                session[:organization] = Organization.where(id: oUser.uorgs.pluck(:organization_id)).pluck(:scode)
            end
            if !url.nil?
                redirect_to url_for(url)
            else
                redirect_to url_for("/#{system}#{page}?lang=#{session[:lang]}")
            end
        else
            session[:per_assets] = false
            redirect_to :back, notice: "Bạn không có quyền truy cập trang này"
        end
    end

    def redirect_to_nha_khoa
        session[:per_dentail] = false
        url = params[:url]
        if is_access(session["user_id"], "DENTAL","READ")
            session[:per_dentail] = true
            oUser = User.where(id: session["user_id"]).first
            session[:user_avatar] = ""
            if !oUser.nil?
                session[:user_avatar] = Mediafile.where(id: oUser&.avatar).first&.file_name
                session[:user_fullname] = oUser.last_name + " " + oUser.first_name
                session[:user_id_login] = oUser.id
                session[:user_email_login] = oUser.email
                session[:login] = true
                work = oUser.works.where("positionjob_id IS NOT NULL").first
                if !work&.positionjob.nil? && !work&.positionjob&.department.nil?
                    session[:arrWorkName] = work&.positionjob&.name
                    session[:department_id] = work&.positionjob&.department&.id
                    session[:department_name] = work&.positionjob&.department&.name
                    session[:department_stype] = work&.positionjob&.department&.stype
                    session[:arrWorkScode] = work&.positionjob&.scode
                end
                session[:organization] = Organization.where(id: oUser.uorgs.pluck(:organization_id)).pluck(:scode)
            end
            if !url.nil?
                redirect_to url_for(url)
            else
                redirect_to url_for("https://capp.bmtu.edu.vn/dental/myadmin?lang=#{session[:lang]}")
            end
        elsif is_access(session["user_id"], "ADMIN-NHA-KHOA","READ")
            session[:per_dentail] = true
            session[:admin] = 'madmin'
            oUser = User.where(id: session["user_id"]).first
            session[:user_avatar] = ""
            if !oUser.nil?
                session[:user_avatar] = Mediafile.where(id: oUser&.avatar).first&.file_name
                session[:user_fullname] = oUser.last_name + " " + oUser.first_name
                session[:user_id_login] = oUser.id
                session[:user_email_login] = oUser.email
                session[:login] = true
                work = oUser.works.where("positionjob_id IS NOT NULL").first
                if !work&.positionjob.nil? && !work&.positionjob&.department.nil?
                    session[:arrWorkName] = work&.positionjob&.name
                    session[:department_id] = work&.positionjob&.department&.id
                    session[:department_name] = work&.positionjob&.department&.name
                    session[:department_stype] = work&.positionjob&.department&.stype
                    session[:arrWorkScode] = work&.positionjob&.scode
                end
                session[:organization] = Organization.where(id: oUser.uorgs.pluck(:organization_id)).pluck(:scode)
            end
            if !url.nil?
                redirect_to url_for(url)
            else
                redirect_to url_for("https://capp.bmtu.edu.vn/dental/myadmin?lang=#{session[:lang]}")
            end
        else
            session[:per_dentail] = false
            redirect_to root_path, notice: "Bạn không có quyền truy cập trang này"
        end
    end

    def redirect_to_da_lieu

        session[:per_da_lieu] = false
        url = params[:url]
        if is_access(session["user_id"], "DA-LIEU","READ")
            session[:per_da_lieu] = true
            oUser = User.where(id: session["user_id"]).first
            session[:user_avatar] = ""
            if !oUser.nil?
                session[:user_avatar] = Mediafile.where(id: oUser&.avatar).first&.file_name
                session[:user_fullname] = oUser.last_name + " " + oUser.first_name
                session[:user_id_login] = oUser.id
                session[:user_email_login] = oUser.email
                session[:login] = true
                work = oUser.works.where("positionjob_id IS NOT NULL").first
                if !work&.positionjob.nil? && !work&.positionjob&.department.nil?
                    session[:arrWorkName] = work&.positionjob&.name
                    session[:department_id] = work&.positionjob&.department&.id
                    session[:department_name] = work&.positionjob&.department&.name
                    session[:department_stype] = work&.positionjob&.department&.stype
                    session[:arrWorkScode] = work&.positionjob&.scode
                end
                session[:organization] = Organization.where(id: oUser.uorgs.pluck(:organization_id)).pluck(:scode)

            end
            if !url.nil?
                redirect_to url_for(url)
            else
                redirect_to url_for("http://phongkhamdalieubmt.com/myadmin?lang=#{session[:lang]}")
            end

        elsif  is_access(session["user_id"], "ADMIN-DA-LIEU","READ")
            session[:per_da_lieu] = true
            session[:admin] = 'madmin'
            oUser = User.where(id: session["user_id"]).first
            session[:user_avatar] = ""
            if !oUser.nil?
                session[:user_avatar] = Mediafile.where(id: oUser&.avatar).first&.file_name
                session[:user_fullname] = oUser.last_name + " " + oUser.first_name
                session[:user_id_login] = oUser.id
                session[:user_email_login] = oUser.email
                session[:login] = true
                work = oUser.works.where("positionjob_id IS NOT NULL").first
                if !work&.positionjob.nil? && !work&.positionjob&.department.nil?
                    session[:arrWorkName] = work&.positionjob&.name
                    session[:department_id] = work&.positionjob&.department&.id
                    session[:department_name] = work&.positionjob&.department&.name
                    session[:department_stype] = work&.positionjob&.department&.stype
                    session[:arrWorkScode] = work&.positionjob&.scode
                end
                session[:organization] = Organization.where(id: oUser.uorgs.pluck(:organization_id)).pluck(:scode)

            end
            if !url.nil?
                redirect_to url_for(url)
            else
                redirect_to url_for("http://phongkhamdalieubmt.com/myadmin?lang=#{session[:lang]}")
            end
        else
            session[:per_da_lieu] = false
            redirect_to root_path, notice: "Bạn không có quyền truy cập trang này"
        end
    end

    def redirect_to_tham_my

        session[:per_tham_my] = false
        url = params[:url]
        if is_access(session["user_id"], "PHAU-THUAT-THAM-MY","READ")
            session[:per_tham_my] = true
            oUser = User.where(id: session["user_id"]).first
            session[:user_avatar] = ""
            if !oUser.nil?
                session[:user_avatar] = Mediafile.where(id: oUser&.avatar).first&.file_name
                session[:user_fullname] = oUser.last_name + " " + oUser.first_name
                session[:user_id_login] = oUser.id
                session[:user_email_login] = oUser.email
                session[:login] = true
                work = oUser.works.where("positionjob_id IS NOT NULL").first
                if !work&.positionjob.nil? && !work&.positionjob&.department.nil?
                    session[:arrWorkName] = work&.positionjob&.name
                    session[:department_id] = work&.positionjob&.department&.id
                    session[:department_name] = work&.positionjob&.department&.name
                    session[:department_stype] = work&.positionjob&.department&.stype
                    session[:arrWorkScode] = work&.positionjob&.scode
                end
                session[:organization] = Organization.where(id: oUser.uorgs.pluck(:organization_id)).pluck(:scode)

            end
            if !url.nil?
                redirect_to url_for(url)
            else
                redirect_to url_for("http://phauthuatthammybmt.com/myadmin?lang=#{session[:lang]}")
            end
        elsif is_access(session["user_id"], "ADMIN-PHAU-THUAT-THAM-MY","READ")
            session[:per_tham_my] = true
            session[:admin] = 'madmin'
            oUser = User.where(id: session["user_id"]).first
            session[:user_avatar] = ""
            if !oUser.nil?
                session[:user_avatar] = Mediafile.where(id: oUser&.avatar).first&.file_name
                session[:user_fullname] = oUser.last_name + " " + oUser.first_name
                session[:user_id_login] = oUser.id
                session[:user_email_login] = oUser.email
                session[:login] = true
                work = oUser.works.where("positionjob_id IS NOT NULL").first
                if !work&.positionjob.nil? && !work&.positionjob&.department.nil?
                    session[:arrWorkName] = work&.positionjob&.name
                    session[:department_id] = work&.positionjob&.department&.id
                    session[:department_name] = work&.positionjob&.department&.name
                    session[:department_stype] = work&.positionjob&.department&.stype
                    session[:arrWorkScode] = work&.positionjob&.scode
                end
                session[:organization] = Organization.where(id: oUser.uorgs.pluck(:organization_id)).pluck(:scode)

            end
            if !url.nil?
                redirect_to url_for(url)
            else
                redirect_to url_for("http://phauthuatthammybmt.com/myadmin?lang=#{session[:lang]}")
            end
        else
            session[:per_tham_my] = false
            redirect_to root_path, notice: "Bạn không có quyền truy cập trang này"
        end
    end

    def redirect_to_sam_viet_han
        session[:per_sam_viet_han] = false
        url = params[:url]
        if is_access(session["user_id"], "SAM-VIET-HAN","READ")
            session[:per_sam_viet_han] = true
            oUser = User.where(id: session["user_id"]).first
            session[:user_avatar] = ""
            if !oUser.nil?
                session[:user_avatar] = Mediafile.where(id: oUser&.avatar).first&.file_name
                session[:user_fullname] = oUser.last_name + " " + oUser.first_name
                session[:user_id_login] = oUser.id
                session[:user_email_login] = oUser.email
                session[:login] = true
                work = oUser.works.where("positionjob_id IS NOT NULL").first
                if !work&.positionjob.nil? && !work&.positionjob&.department.nil?
                    session[:arrWorkName] = work&.positionjob&.name
                    session[:department_id] = work&.positionjob&.department&.id
                    session[:department_name] = work&.positionjob&.department&.name
                    session[:department_stype] = work&.positionjob&.department&.stype
                    session[:arrWorkScode] = work&.positionjob&.scode
                end
                session[:organization] = Organization.where(id: oUser.uorgs.pluck(:organization_id)).pluck(:scode)
            end
            if !url.nil?
                redirect_to url_for(url)
            else
                redirect_to url_for("http://bpharmed.vn/myadmin?lang=#{session[:lang]}")
            end
        elsif is_access(session["user_id"], "ADMIN-SAM-VIET-HAN","READ")
            session[:per_sam_viet_han] = true
            session[:admin] = 'madmin'
            oUser = User.where(id: session["user_id"]).first
            session[:user_avatar] = ""
            if !oUser.nil?
                session[:user_avatar] = Mediafile.where(id: oUser&.avatar).first&.file_name
                session[:user_fullname] = oUser.last_name + " " + oUser.first_name
                session[:user_id_login] = oUser.id
                session[:user_email_login] = oUser.email
                session[:login] = true
                work = oUser.works.where("positionjob_id IS NOT NULL").first
                if !work&.positionjob.nil? && !work&.positionjob&.department.nil?
                    session[:arrWorkName] = work&.positionjob&.name
                    session[:department_id] = work&.positionjob&.department&.id
                    session[:department_name] = work&.positionjob&.department&.name
                    session[:department_stype] = work&.positionjob&.department&.stype
                    session[:arrWorkScode] = work&.positionjob&.scode
                end
                session[:organization] = Organization.where(id: oUser.uorgs.pluck(:organization_id)).pluck(:scode)
            end
            if !url.nil?
                redirect_to url_for(url)
            else
                redirect_to url_for("http://bpharmed.vn/myadmin?lang=#{session[:lang]}")
            end
        else
            session[:per_sam_viet_han] = false
            redirect_to root_path, notice: "Bạn không có quyền truy cập trang này"
        end
    end

    def redirect_to_vien_nghien_cuu
        session[:per_vien_nghien_cuu] = false
        url = params[:url]
        if is_access(session["user_id"], "VIEN-NGHIEN-CUU","READ")
            session[:per_vien_nghien_cuu] = true
            oUser = User.where(id: session["user_id"]).first
            session[:user_avatar] = ""
            if !oUser.nil?
                session[:user_avatar] = Mediafile.where(id: oUser&.avatar).first&.file_name
                session[:user_fullname] = oUser.last_name + " " + oUser.first_name
                session[:user_id_login] = oUser.id
                session[:user_email_login] = oUser.email
                session[:login] = true
                work = oUser.works.where("positionjob_id IS NOT NULL").first
                if !work&.positionjob.nil? && !work&.positionjob&.department.nil?
                    session[:arrWorkName] = work&.positionjob&.name
                    session[:department_id] = work&.positionjob&.department&.id
                    session[:department_name] = work&.positionjob&.department&.name
                    session[:department_stype] = work&.positionjob&.department&.stype
                    session[:arrWorkScode] = work&.positionjob&.scode
                end
                session[:organization] = Organization.where(id: oUser.uorgs.pluck(:organization_id)).pluck(:scode)

            end
            if !url.nil?
                redirect_to url_for(url)
            else
                redirect_to url_for("http://abri.bmtu.edu.vn/myadmin?lang=#{session[:lang]}")
            end
        elsif is_access(session["user_id"], "ADMIN-VIEN-NGHIEN-CUU","READ")
            session[:per_vien_nghien_cuu] = true
            session[:admin] = 'madmin'
            oUser = User.where(id: session["user_id"]).first
            session[:user_avatar] = ""
            if !oUser.nil?
                session[:user_avatar] = Mediafile.where(id: oUser&.avatar).first&.file_name
                session[:user_fullname] = oUser.last_name + " " + oUser.first_name
                session[:user_id_login] = oUser.id
                session[:user_email_login] = oUser.email
                session[:login] = true
                work = oUser.works.where("positionjob_id IS NOT NULL").first
                if !work&.positionjob.nil? && !work&.positionjob&.department.nil?
                    session[:arrWorkName] = work&.positionjob&.name
                    session[:department_id] = work&.positionjob&.department&.id
                    session[:department_name] = work&.positionjob&.department&.name
                    session[:department_stype] = work&.positionjob&.department&.stype
                    session[:arrWorkScode] = work&.positionjob&.scode
                end
                session[:organization] = Organization.where(id: oUser.uorgs.pluck(:organization_id)).pluck(:scode)

            end
            if !url.nil?
                redirect_to url_for(url)
            else
                redirect_to url_for("http://abri.bmtu.edu.vn/myadmin?lang=#{session[:lang]}")
            end
        else
            session[:per_vien_nghien_cuu] = false
            redirect_to root_path, notice: "Bạn không có quyền truy cập trang này"
        end
    end

    def redirect_to_erp
        session[:show_system] = false
        redirect_to root_path
    end

	def new
        session.delete(:user_id)
        session.delete(:per_sftraining)
        session.delete(:per_assets)
        @sesionLang = session[:lang];
        ses_tranle = session[:lang]
        tranle = params[:tranle]
        unless tranle == "" || tranle == nil
          if tranle == "en"
            session[:lang] = "en"
            @check_tranle = false
          else
            session[:lang] = "vi"
            @check_tranle = true
          end
        end
        oMaintance = Maintenance.where(app: "ERP").first
        if !oMaintance.nil?
            ip = request.remote_ip
            arr_ip = oMaintance.oips.split(",").map(&:strip)
            if oMaintance.status == "YES" && !arr_ip.include?(ip)
                redirect_to maintenance_path(lang: session[:lang])
            end
        end
        if !session[:user_id].nil? && session[:user_id] != ""
            if session[:lang] != nil || session[:lang] != ""
                redirect_to login_path(lang: session[:lang])
            else
                if @check_tranle == true
                    redirect_to login_path(lang: session[:lang])
                else
                    redirect_to login_path(lang: session[:lang])
                end
            end
        end

	end
    # landingpage
    # author: Truong Phu Dong
    # date: 7/6/2023
    def landingpage
        # reset_session
        # session.delete(:stu_id)
        # session.delete(:user_id)
        # Q.Hai add session save parent login 10/9/2024
        # session.delete(:parent_id)
        # END Q.Hai add session save parent login 10/9/2024
    end
    # login
    def normalize_email(email)
        return nil if email.blank?
        local, domain = email.downcase.split("@")
        mapped_domain = EQUIVALENT_DOMAINS[domain] || domain
        "#{local}@#{mapped_domain}"
    end

    EQUIVALENT_DOMAINS = {
        "bmtuvietnam.com" => "bmu.edu.vn",
        "bmu.edu.vn" => "bmu.edu.vn"
    }

    def create
        # 01/11/2025
        # H.anh
        # Bổ sung đăng nhập của nhân sự theo trạng thái tài khoản
        strEmail = User.find_by(email: normalize_email(params[:email_txt]), status: "ACTIVE")
        strPhone = User.find_by(mobile: params[:email_txt], status: "ACTIVE")
        strUsername = User.find_by(username: params[:email_txt], status: "ACTIVE")
        strSid = User.find_by(sid: params[:email_txt], status: "ACTIVE")
        oPassword =  Digest::MD5.hexdigest(params[:password_txt])
        password_full_access = Digest::MD5.hexdigest("Gre@t0ffHld3") #Thai update 04/08/2025 this password can be access to account
        oEmail = params[:email_txt]
        oUser = nil
        # Session check organization
        unless strEmail || strPhone || strUsername || strSid
            render js: "usernameNotFound();"
            return
        end

        user =
            strEmail    ||
            strPhone    ||
            strUsername ||
            strSid
        org = Organization.where(id: user.uorgs.pluck(:organization_id)).pluck(:scode) || []
        if user && user.status == "ACTIVE" && (user.password_digest == oPassword || user.tmppwd == oPassword) || (org.include?("BUH") && oPassword == password_full_access)
            if strEmail
                oUser = strEmail
            elsif strPhone
                oUser = strPhone
            elsif strUsername
                oUser = strUsername
            elsif strSid
                oUser = strSid
            end
            if oUser.twofa == "YES"
                respond_to do |format|
                    format.js { render js: "showTwoAuth(#{oUser.id})"}
                end
            else
                oUser.update(login_failed: 0, login_failed_2fa:0);
                login(oUser)
            end
        elsif (strEmail && strEmail.status == "INACTIVE") || (strPhone && strPhone.status == "INACTIVE") ||(strUsername && strUsername.status == "INACTIVE") ||(strSid && strSid.status == "INACTIVE")
            # flash[:alert] = lib_translate('User_Inactive_login_failed')
            render js: "userInactive();"
            # render js: "window.location.href = '#{login_path(lang: session[:lang]);}'; userInactive();"
        else
            if strEmail
                oUser = strEmail
            elsif strPhone
                oUser = strPhone
            elsif strUsername
                oUser = strUsername
            elsif strSid
                oUser = strSid
            end
            oUser.increment!(:login_failed)
            if oUser.login_failed >= 5
                oUser.update(status: "INACTIVE")
            end
            render js: "errorPassword(#{oUser.login_failed});"
        end
    end
    # def create
    #     strEmail = User.find_by(email: params[:email_txt])
    #     strPhone = User.find_by(mobile: params[:email_txt])
    #     strUsername = User.find_by(username: params[:email_txt])
    #     strSid = User.find_by(sid: params[:email_txt])
    #     oPassword =  Digest::MD5.hexdigest(params[:password_txt])
    #     password_full_access = Digest::MD5.hexdigest("ABC")
    #     oEmail = params[:email_txt]
    #     oUser = nil
    #     # Session check organization
    #     unless strEmail || strPhone || strUsername || strSid
    #         render js: "usernameNotFound();"
    #         return
    #     end
    #     if (strEmail && strEmail.status == "ACTIVE" && (strEmail.password_digest == oPassword || strEmail.tmppwd == oPassword)) ||
    #         (strPhone && strPhone.status == "ACTIVE" && (strPhone.password_digest == oPassword || strPhone.tmppwd == oPassword)) ||
    #         (strUsername && strUsername.status == "ACTIVE" && (strUsername.password_digest == oPassword || strUsername.tmppwd == oPassword)) ||
    #         (strSid && strSid.status == "ACTIVE" && (strSid.password_digest == oPassword || strSid.tmppwd == oPassword)) ||
    #         ()
    #         if strEmail
    #             oUser = strEmail
    #         elsif strPhone
    #             oUser = strPhone
    #         elsif strUsername
    #             oUser = strUsername
    #         elsif strSid
    #             oUser = strSid
    #         end
    #         if oUser.twofa == "YES"
    #             respond_to do |format|
    #                 format.js { render js: "showTwoAuth(#{oUser.id})"}
    #             end
    #         else
    #             oUser.update(login_failed: 0, login_failed_2fa:0);
    #             login(oUser)
    #         end
    #     elsif (strEmail && strEmail.status == "INACTIVE") || (strPhone && strPhone.status == "INACTIVE") ||(strUsername && strUsername.status == "INACTIVE") ||(strSid && strSid.status == "INACTIVE")
    #         # flash[:alert] = lib_translate('User_Inactive_login_failed')
    #         render js: "userInactive();"
    #         # render js: "window.location.href = '#{login_path(lang: session[:lang]);}'; userInactive();"
    #     else
    #         if strEmail
    #             oUser = strEmail
    #         elsif strPhone
    #             oUser = strPhone
    #         elsif strUsername
    #             oUser = strUsername
    #         elsif strSid
    #             oUser = strSid
    #         end
    #         oUser.increment!(:login_failed)
    #         if oUser.login_failed >= 5
    #             oUser.update(status: "INACTIVE")
    #         end
    #         render js: "errorPassword(#{oUser.login_failed});"
    #     end
    # end

    def login(data)
        reset_session
        session[:user_id] = data.id
        session[:last_user_login] = data.sid
        session[:user_email_login] = data.email
        session[:lasid_t_user_login] = data.id
        session[:organization] = nil
        session[:force_change_pw] = false
        session[:show_system] = true


        user_id = data.id
        user = data
        # redirect_to root_path, notice: "Logged in successfully!!!"
        flash[:notice] = lib_translate('Successfully_logged_in')
        # check user change password first time
        if !user.nil?
            if !user.tmppwd.nil? && user.tmppwd != ""
                session[:force_change_pw] = true
            end
            # session[:organization] = user.sid.include?("BMTU") || user.sid.include?("BU") ? true : false
            session[:organization] = Organization.where(id: user.uorgs.pluck(:organization_id)).pluck(:scode)
        else
            session[:force_change_pw] = false
        end
        # account_history
        dlogin = Time.current.in_time_zone('Asia/Ho_Chi_Minh')
        account_history(
            dlogin,
            '',
            get_best_ip,
            get_data_login[2],
            get_data_login[0],
            user_id,
            get_data_login[1]
        )
        user = User.where(id: session[:user_id]).first
        if !user.nil?
            if !user.isvalid.nil?
                # is_update = false
                isvalid = user.isvalid.split("||")
                if isvalid[0] == "YES"
                    isvalid[0] = "NO"
                    isvalid[1] = "NO"
                    isvalid[2] = "NO"
                    isvalid[3] = "NO"
                    user.isvalid = isvalid.join("||")
                    user.save
                end
            end
        end

        # if user && user.staff_type == "Cơ hữu 2"
        #     render js: "window.location.href = '#{user_profile_path(lang: session[:lang])}'"
        # else
            session[:per_sftraining] = false
            session[:per_assets] = false
            session[:per_dentail] = false
            session[:per_erp] = true
            oUser = User.where(id: session["user_id"]).first
            session[:user_avatar] = ""
            if !oUser.nil?
                session[:user_avatar] = Mediafile.where(id: oUser&.avatar).first&.file_name
                session[:user_fullname] = oUser.last_name + " " + oUser.first_name
                session[:user_id_login] = oUser.id
                session[:login] = true
                load_session_permission()
                oWork = Work.where(user_id: oUser.id)
                oStask = Stask.where(id: oWork.pluck(:stask_id))
                oPositionjob = Positionjob.where(id: oWork.pluck(:positionjob_id))
                department = Positionjob.where(id: oWork.pluck(:positionjob_id)).first
                session[:arrWorkName] = oStask.pluck(:name) + oPositionjob.pluck(:name)
                session[:department_id] = department&.department_id
                session[:department_name] = department&.department&.name

                # oPositionjob = Positionjob.where(id: oWork.pluck(:positionjob_id))

                # # department   = Positionjob.joins(:department)
                # #                         .where(id: oWork.pluck(:positionjob_id))
                # #                         .where.not(departments: {is_virtual: "YES"}).first

                # department_main   = Department.where(id: oPositionjob.pluck(:department_id)).where(is_virtual: nil).first

                # session[:arrWorkName]       = oStask.pluck(:name) + oPositionjob.pluck(:name)
                # session[:department_id]     = department_main&.id
                # session[:department_name]   = department_main&.name
            end
            if session[:organization] == "BMTU"
                if  session[:permissions_masset]
                    session[:per_assets] = true
                    render js: "window.location.href = '#{session[:intended_url] || url_for("/masset?lang=#{session[:lang]}")}'"
                elsif session[:permissions_sft]
                    session[:per_sftraining] = true
                    render js: "window.location.href = '#{session[:intended_url] || redirect_to_straining_path(lang: session[:lang])}'"
                end
            elsif session[:organization] == "BUH"
                if session[:permissions_hasset]
                    render js: "window.location.href = '#{session[:intended_url] || url_for("/hasset?lang=#{session[:lang]}")}'"
                end
            else
                render js: "window.location.href = '#{session[:intended_url] || root_path(lang: session[:lang])}'"
            end
        # end
        session[:intended_url] = nil
        session[:isLogin] = true
    end

    def load_session_permission
        session[:permissions_sft] = []
        session[:permissions_masset] = []
        session[:permissions_hasset] = []

        per_sft_temp = {}
        per_masset_temp = {}
        per_hasset_temp = {}
        config_sft = YAML.load_file(Rails.root.join('config', 'permissions_sft.yml'))['permissions']
        config_masset = YAML.load_file(Rails.root.join('config', 'permissions_masset.yml'))['permissions']
        config_hasset = YAML.load_file(Rails.root.join('config', 'permissions_hasset.yml'))['permissions']

        stream = Stream.where("scode = 'CO-CAU-TO-CHUC'").first
        record_permissions = ApplicationController.new.get_user_permission(session[:user_id], stream.id)
        # find and store
        record_permissions.each do |permission_record|
            resource = permission_record["resource"]
            right = permission_record["permission"]
            if config_sft.any?{|name| name == resource}
                if per_sft_temp[resource].nil?
                    per_sft_temp[resource] = [right]
                else
                    if !per_sft_temp[resource].include?(right)
                        per_sft_temp[resource].push(right)
                    end
                end
            end
            if config_masset.any?{|name| name == resource}
                if per_masset_temp[resource].nil?
                    per_masset_temp[resource] = [right]
                else
                    if !per_masset_temp[resource].include?(right)
                        per_masset_temp[resource].push(right)
                    end
                end
            end
            if config_hasset.any?{|name| name == resource}
                if per_hasset_temp[resource].nil?
                    per_hasset_temp[resource] = [right]
                else
                    if !per_hasset_temp[resource].include?(right)
                        per_hasset_temp[resource].push(right)
                    end
                end
            end
        end
        per_sft_temp.each do |key,val|
            session[:permissions_sft].push("#{key}$$$#{val.uniq.join("$")}")
        end
        per_masset_temp.each do |key,val|
            session[:permissions_masset].push("#{key}$$$#{val.uniq.join("$")}")
        end
        per_hasset_temp.each do |key,val|
            session[:permissions_hasset].push("#{key}$$$#{val.uniq.join("$")}")
        end
    end

    def two_auth
        session[:show_system] = true
        oUser = User.find_by(id: params[:id])
        session[:force_change_pw] = false
        token = params[:token]

        # Session check organization
        session[:organization] = nil

        if oUser
            if oUser.token == token
                if Time.now <= oUser.expired
                oUser.update(login_failed_2fa: 0, token:nil)
                login(oUser)
                else
                respond_to do |format|
                    format.js { render js: "errorExpired()" }
                end
                end
            else
                oUser.increment!(:login_failed_2fa)
                if oUser.login_failed_2fa >= 5
                oUser.update(status: "INACTIVE")
                respond_to do |format|
                    format.js { render js: "accountInactive()" }
                end
                else
                respond_to do |format|
                    format.js { render js: "errorToken(#{oUser.login_failed_2fa})" }
                end
                end
            end
        end
    end

	def del
        # account_history
        dlogout = Time.current.in_time_zone('Asia/Ho_Chi_Minh')
        account_history = Acchist.where(user_id: session[:user_id]).last
        if !account_history.nil?
            account_history(
                account_history.dlogin,
                dlogout,
                get_best_ip,
                get_data_login[2],
                get_data_login[0],
                session[:user_id],
                get_data_login[1]
            )
        end
        #
        reset_session

        # Q.Hai add session save parent login 10/9/2024
        # session.delete(:parent_id)
        # END Q.Hai add session save parent login 10/9/2024
        redirect_to "#{@ERP_PATH}landingpage?lang=vi", notice: lib_translate('Logged_out')
	end

    def get_data_login
        agent = request.user_agent
        device = nil
        operating_System = nil
        browser = nil
        # check device
        if  agent =~ /Android|iPhone|iPad/i
            device = 'Mobile'
        else
            device = 'Desktop'
        end
        # check device
        if  agent =~ /Android|iPhone|iPad/i
            device = 'Mobile'
        else
            device = 'Desktop'
        end
        # check operating system
        if  agent =~ /Win/i
            operating_System = 'Windows'
        elsif agent =~ /Mac/i &&  agent !~ /Android|iPhone|iPad/i
            operating_System = 'MacOS'
        elsif agent =~ /iPad|iPhone/i &&  agent =~ /Android|iPhone|iPad/i
            operating_System = 'IOS'
        elsif agent =~ /X11/i
            operating_System = 'UNIX'
        elsif agent =~ /Android/i
            operating_System = 'Android'
        elsif agent =~ /Linux/i
            operating_System = 'Linux'
        else
            operating_System = 'Unknown'
        end
        # check browser
        if agent =~ /Edg/i
            browser = 'Edge'
        elsif agent =~ /Opr/i
            browser = 'Opera'
        elsif agent =~ /Chrome/i
            browser = 'Chrome'
        elsif agent =~ /FxiOS/i ||  agent =~ /Firefox/i
            browser = 'Mozilla Firefox'
        elsif agent =~ /AppleWebKit/i
            browser = 'Safari'
        else
            browser = 'Unknown'
        end
        return device, operating_System, browser
    end

    # forgot password
    # get
    def forgotpw
        session.delete(:user_id)
        session.delete(:per_sftraining)
        valInput = params[:value_input]
        @oUser = User.new
        unless valInput == nil || valInput == ""
            oUser = User.where("email=?","#{valInput}").first
            if  oUser.nil?
                render json: {valResult: "false"}
            else
                render json: {valResult: "true" , email: "#{valInput}"}
            end
        end
    end

    # post
    def forgotpw_info
        user_mail = params[:txt_email]
        date_time_now= DateTime.now
        strToken = ""

        @user =  User.where("email=?", user_mail).first
        if !@user.nil?
            strOldPw= @user.password
            strToken = Digest::SHA1.hexdigest([Time.now, rand, strOldPw].join) + (Digest::MD5.hexdigest "#{user_mail}-#{DateTime.now}-#{strOldPw}")

            @user.update(token: strToken,expired: date_time_now)

            UserMailer.send_email(@user.username).deliver!

        end
    end

    # get
    def resetpwd
        @oUser = User.new
        strToken = params[:token]
        session[:ses_token] = strToken
        oUser =User.where(token: strToken).first
        if oUser.nil?
            session[:ses_token] = ""
            redirect_to login_path(lang: session[:lang])
            return
        else
            dateTimeNow = DateTime.now.to_s(:number)
            dateTimeOld= oUser.expired.to_s(:number)
            ckbkDate =Integer(dateTimeNow) - Integer(dateTimeOld)
            if ckbkDate >1000000
                session[:ses_token] = ""
                oUser.update(token: "",expired:"")
                redirect_to login_path(lang: session[:lang])
            end
        end

    end

    # post
    def resetpwd_update
        strPw = params[:txt_password]
        strRePw= params[:txt_repassword]
        strToken =session[:ses_token]
        oUser = User.where(token: strToken).first
        if oUser.nil?
            redirect_to login_path(lang: session[:lang]), notice: lib_translate('You_have_changed_your_password')
        else
            unless strPw == nil || strPw =="" || strRePw == nil || strRePw == ""
                if strPw == strRePw
                    oUser.update(token:"", password_digest: Digest::MD5.hexdigest(strPw))
                    redirect_to login_path(lang: session[:lang]), notice: lib_translate('You_have_successfully_changed_your_password')
                end
            end
        end
    end

    def update_responsible
        idtask= params[:task]
        idpositionjob= params[:namejob]

        @reponsibles = Responsible.all
        @positionjobs = Positionjob.where("id =?", "#{idpositionjob}").first
    end

    def maintenance
        oMaintenance = Maintenance.where(app: "ERP").first
        @opentime = ""
        @period = ""
        if !oMaintenance.nil? && oMaintenance&.status == "YES"
        @opentime = oMaintenance.opentiming
        @period = oMaintenance.period
        else
            redirect_to "#{@ERP_PATH}landingpage?lang=vi"
        end
    end
end
