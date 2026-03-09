class ApplicationController < ActionController::Base

  # Controller Helper for create image captcha
  include SimpleCaptcha::ControllerHelpers
  include RemoteNotificationHelper
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  # protect_from_forgery with: :null_session, only: Proc.new { |c| c.request.format.json? }
  before_action :default_data, :set_locale, :check_user_login, :get_notices_count
  before_action do
    if Rails.env.production?
      uid = session[:user_id]
      if session[:_cache_uid] != uid
        session[:_cache_uid] = uid
        session.delete(:user_info)
      end

      if session[:user_info].present?
        @user_info = session[:user_info]
      else
        raw = User.get_info_user(uid)
        @user_info = raw.respond_to?(:as_json) ? raw.as_json : raw
        session[:user_info] = @user_info
      end
    end
  end

  # The function get notices count and get new after 10 minutes
  # @author: Dat Le
  # @date: 22/09/2025
  def get_notices_count
    user_id = session[:user_id]
    return unless user_id.present?
    return if request.xhr? || request.format.turbo_stream? || request.path.start_with?('/assets')

    now        = Time.current.to_i
    cached_at  = session[:notices_cached].to_i
    in_window  = cached_at.positive? && (now - cached_at) < 10*60

    if in_window && session.key?(:notices_count)
      @notices_count = session[:notices_count].to_i
      return
    end

    # Hết hạn hoặc chưa có session → query data
    @notices_count = Snotice.joins(:notify)
            .where("snotices.user_id = ? AND (snotices.isread IS NULL OR snotices.isread = ?)", user_id, false)
            .where(created_at: 1.week.ago..Time.current)
            .count

    session[:notices_count] = @notices_count.to_i
    session[:notices_cached] = now
  rescue => e
    Rails.logger.info("[get_notices_count] #{e.class}: #{e.message}")
    @notices_count = session[:notices_count].to_i if session.key?(:notices_count)
  end

  # errors handle
  rescue_from StandardError, with: :handle_standard_error if Rails.env.production? #line: 1114

  def check_user_login
    if request.cookies['_msbmtu_ses'].nil?
      if request.xhr? || request.format.json? || request.format.js?
        render json: { logged_in: false, login_url: "#{@ERP_PATH}landingpage?lang=vi" }, status: :unauthorized
      else
        redirect_to "#{@ERP_PATH}landingpage?lang=vi"
      end
    end
  end

  def default_data
    if Rails.env.development?
      @ERP_PATH = request.base_url + "/mywork/"
      @CSVC_PATH = request.base_url + "/masset/"
      @BUH_CSVC_PATH = request.base_url + "/hasset/"
      @PMDT_PATH = request.base_url + "/sftraining/"
    elsif Rails.env.production?
      @ERP_PATH = request.base_url + "/"
      @CSVC_PATH = request.base_url + "/masset/"
      @BUH_CSVC_PATH = request.base_url + "/hasset/"
      @PMDT_PATH = request.base_url + "/sftraining/"
    end
    @ROOT_PATH = request.base_url + root_path
  end

  before_action do
    # Load list permissions
    stream = Stream.where("scode = 'CO-CAU-TO-CHUC'").first
    if !stream.nil?
      @aPermissionUser = [{"resource"=>"NO-PERMISSION", "url"=>"", "permission"=>"ADM"}]
      if  session[:user_id]
        @aPermissionUser = get_user_permission(session[:user_id], stream.id)
        if is_access(session[:user_id], "SFTRAINING","READ")
            session[:per_sftraining] = true
        end
        if is_access(session[:user_id], "ASSETS","READ")
            session[:per_assets] = true
        end
      else

      end
    end
  end

  def sendOTP(email, otp)
    UserMailer.send_OTP_email(email, otp).deliver!
  end

  # The `call_api` function makes an HTTPS GET request to a specified URL and returns the response as a parsed JSON hash.
  # Args:
  #   path: The `path` parameter is a string that represents the URL path to the API endpoint you want to call. It should include the protocol (e.g., "https://") and any necessary query parameters.
  def call_api(path)
    current_url = request.base_url + request.path
    url = URI.parse(path)
    https = Net::HTTP.new(url.host, url.port)
    https.use_ssl = true
    request = Net::HTTP::Get.new(url)
    request['X-Controller-Action'] = "#{current_url}"
    response = https.request(request)
    response_hash = JSON.parse(response.read_body.gsub('=>', ':'))

    response_hash
  end
  helper_method :call_api

  # check permission update
  # author: H.vu
  before_action do
      user_id = session[:user_id_login]

      user = User.where(id:user_id).first
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
            # logout user
            reset_session
            redirect_to logout_path
          end
        end
      end
  end
  # before_action :check_user_permission, only: [:index]

  ##
  # If the user has not specified a language, use the language that was previously set. If there is no
  # previous language, use Vietnamese
  # @author: Huy
  # Returns:
  #   The return value of the last statement in the method.
  def set_locale
    lang = params[:lang]
    if params[:lang].nil? || params[:lang] == ''
      lang = if session[:lang] == '' || session[:lang].nil?
               'vi'
             else
               session[:lang]
             end

    end

    session[:lang] = lang
    return unless %w[vi en].include?(lang)

    I18n.locale = lang
  end
  # Get last Mandocdhandle by department
  # @author: Vu
  # @date: 28/02/2023
  # Description: Use department id and type document find last Mandocdhandle
  # input: department_id, type
  # output: array last Mandocdhandle
  def get_last_dhandle_by_department(department_id,type)
      # get list dhandle by department
      mandocs = nil
      if type == "INCOMING"
          mandocs = Mandoc.where("sfrom IS NOT NULL", status: "INPROGRESS")
      elsif type == "OUTGOING"
          mandocs = Mandoc.where("sfrom IS NULL", status: "INPROGRESS")
      else
          mandocs = Mandoc.where(status: "INPROGRESS")
      end
      allHandle = []
      if !mandocs.nil?
        mandocs.each do |mandoc|
            dhandle = Mandocdhandle.joins(:mandoc).select("mandocs.*,mandocdhandles.created_at as created_at, mandocdhandles.department_id as department_id,mandocdhandles.contents as dhandle_contents").where("mandocdhandles.mandoc_id = #{mandoc.id} AND mandocdhandles.srole = 'XULY'").order(:created_at).last
            dhandle_ph = Mandocdhandle.where("srole = 'PHOIHOPXL' AND mandoc_id = #{mandoc.id} AND department_id = #{department_id}").order(:created_at).last

            if !dhandle.nil?
              if dhandle.department_id == department_id
                  if type == "PROCESS"
                      allHandle.push(dhandle)
                  else
                      allHandle.push(mandoc)
                  end
              end
            end
            if !dhandle_ph.nil?
                allHandle.push(mandoc)
            end
        end
      end
      allHandle
  end
  helper_method :get_last_dhandle_by_department

  # Get Department from user
  # @author: Vu
  # @date: 28/02/2023
  # Description: Find department of logged in user
  # input: user_id
  # output: department of logged in user
  def get_department_from_user_login(user_id)
      oDepartment = []
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
  helper_method :get_department_from_user_login
  # Get count Mandocdhandle by department
  # @author: Vu + Thai
  # @date: 28/02/2023
  # Description: rely function get_last_dhandle_by_department and get count of Mandocdhandle with status INPROGRESS
  # input: department_id, type
  # output: number of Mandocdhandle with status INPROGRESS
  def get_count_dhandle_by_department(department_id, type)
    mandocs = get_last_dhandle_by_department(department_id, type)
    count = 0

    mandocs.each do |mandoc|
      if mandoc.status == "INPROGRESS" || mandoc.status == "ACTIVE" || mandoc.status == "RECEIVE"
         count = count + 1
      end
    end
    count
  end
  helper_method :get_count_dhandle_by_department

  # HOANG ANH
  protect_from_forgery with: :exception

  ##
  # If the user is logged in, then set the current user to the user in the database with the id stored
  # in the session cookie
  def current_user
    # Look up the current user based on user_id in the session cookie:
    if !session[:user_id].nil?
      oUser = User.where(id: session[:user_id]).first
      if !oUser.nil?
        @current_user = oUser
      else
        session[:intended_url] = request.url
        redirect_to landingpage_path(lang: session[:lang])
      end
    else
      session[:intended_url] = request.url
      redirect_to landingpage_path(lang: session[:lang])
    end

  end
  helper_method :current_user

  ##
  # If the user is logged in, do nothing. If the user is not logged in, save the current URL in the
  # session and redirect to the login page
  #
  # Returns:
  #   The current_user object.
  def authorize

    oMaintance = Maintenance.where(app: "ERP").first
    if !oMaintance.nil?
        ip = request.remote_ip
        arr_ip = oMaintance.oips.split(",").map(&:strip)
        if oMaintance.status == "YES" && !arr_ip.include?(ip)
            redirect_to maintenance_path(lang: session[:lang])
        else
          return if current_user
          session[:intended_url] = request.url
          redirect_to landingpage_path(lang: session[:lang]), alert: lib_translate('You_must_be_logged_in_to_access_this_page') if current_user.nil?
        end
    else
      return if current_user
      session[:intended_url] = request.url
      redirect_to landingpage_path(lang: session[:lang]), alert: lib_translate('You_must_be_logged_in_to_access_this_page') if current_user.nil?
    end
  end

    # Check user permissions function based on user_id in backend
  # @author: Huy + Đồng + Đạt + Thái
  # @date: 31/01/2023
  # Desc:
  # Check user permissions from array of function get_user_permission, that user has that permissions or not. If they have that permission, allow them to reverse access and redirect them to the 404 page
  #
  def check_user_permission
    if !@aPermissionUser.nil?
      action = params[:action]
      url = (request.env["PATH_INFO"]).split("/")
      url.pop
      url = url.join("-").upcase()
      # url = request.base_url + request.env["SCRIPT_NAME"] + url
      # checkPermision = false
      # @aPermissionUser.each do |per|
      #     if (per["url"] == url && lib_translate(action) == per["permission"]) || (per["url"] == url && "ADM" == per["permission"])
      #         checkPermision = true
      #     end
      # end
      # if !checkPermision
      #   if lib_translate(action) == "EDIT" || lib_translate(action) == "DEL"
      #     redirect_to(session[:last_url], alert: lib_translate("Your_account_does_not_have_access_to_this_function"))
      #     return
      #   else
      #     redirect_to notpermission_path(lang: session[:lang])
      #     return
      #   end
      # else
      #   session[:last_url] = request.url
      # end
      url
    end
  end
  helper_method :check_user_permission

  ## Check user is allowed or not
  # @author: Huy + Đạt + Đồng + Thái
  # @date: 12/01/2023
  # @Input : Id of User, Property, Permission
  # @Output: True if allowing, otherwise is False
  def is_access(user_id,property,permission)
    if @aPermissionUser.blank?
      return false
    end
    if !@aPermissionUser.blank?
      checkPermision = false
      @aPermissionUser.each do |per|
          if (per["resource"] == property && permission == per["permission"]) || (per["resource"] == property && "ADM" == per["permission"])
              checkPermision = true
          end
      end
      return checkPermision
    end
  end
  helper_method :is_access

  ##
  # It takes a string, and returns a translated string if it exists, otherwise it returns the original
  # string
  ## @author: Huy
  # Args:
  #   value: The value to be translated.
  def lib_translate(value)
    if !value.nil?
      I18n.t("#{value}", default: "#{value}")
    end
  end
  helper_method :lib_translate

  ##
  # It takes a file, uploads it to the server, and returns the ID of the file
  ## @author: Huy
  # Args:
  #   file: The file that was uploaded.
  def upload_mediafile(file)
    original_file_name = file.original_filename
    session[:size_file] = file.size
    # Upload Image File
    file_type = file.content_type
    file_new = Mediafile.new({
                               file_name: original_file_name,
                               file_size: session[:size_file],
                               file_type: file_type,
                               status: 'ACTIVE'
                             })
    file_new.save

    @file_name = file_new.file_name
    @arrfilename = @file_name.split('.')

    @extension = @arrfilename[@arrfilename.length - 1]

    folder_path = '/data/hrm/'
    path_new_file = folder_path + 'HRM_MFILE_' + file_new.id.to_s + ".#{@extension}"
    name_file_new = 'HRM_MFILE_' + file_new.id.to_s + ".#{@extension}"

    FileUtils.mkdir_p(folder_path) unless File.exist?(folder_path)

    FileUtils.mv(file.tempfile, path_new_file)
    FileUtils.chmod_R 0o755, path_new_file

    @MediafileUpdate = Mediafile.where("id= #{file_new.id}")
    @MediafileUpdate.update({
                              file_name: name_file_new
                            })

    file_new.id
  end

  ##
  # It takes a file, uploads it to the server, and returns a JSON object with the file's information
  ## @author: Huy
  # Args:
  #   file: The file object that was uploaded.
  #
  # Returns:
  #   The return value is a hash with the following keys:
  def upload_document(file)
    original_file_name = file.original_filename
    session[:size_file] = file.size
    last_name_owner = User.where("id = #{session[:user_id]}").first.last_name
    first_name_owner = User.where("id = #{session[:user_id]}").first.first_name
    # Upload Image File
    file_type = file.content_type
    file_new = Mediafile.new({
                              file_name: original_file_name,
                              file_size: session[:size_file],
                              file_type: file_type,
                              status: 'ACTIVE',
                              note: "",
                              owner: "#{last_name_owner} #{first_name_owner}"
                            })
    file_new.save

    @file_name = file_new.file_name
    @arrfilename = @file_name.split('.')
    @extension = @arrfilename[@arrfilename.length - 1]
    @mediafilename = remove_vietnamese_accents(@arrfilename[@arrfilename.length - 2].gsub(" ", "-").gsub("---", "-").gsub("--", "-").upcase)
    folder_path = '/data/hrm/'
    name_file_new = remove_vietnamese_accents('HRM-' + @mediafilename + '-' + file_new.id.to_s + ".#{@extension}")
    path_new_file = folder_path + name_file_new

    FileUtils.mkdir_p(folder_path) unless File.exist?(folder_path)

    FileUtils.mv(file.tempfile, path_new_file)
    FileUtils.chmod_R 0o755, path_new_file

    @MediafileUpdate = Mediafile.where("id= #{file_new.id}").first
    @MediafileUpdate.update({
                              file_name: name_file_new
                            })

    return {
      :id => file_new.id,
      :name => name_file_new,
      :status => file_new.status,
      :note => file_new.note,
      :owner => file_new.owner
    }
  end

  def upload_document_api(file)
    original_file_name = file[:filename]

    # Upload Image File
    file_type = file[:type]
    file_new = Mediafile.new({
                              file_name: original_file_name,
                              file_type: file_type,
                              status: 'ACTIVE',
                              note: "",
                            })
    file_new.save

    @file_name = file_new.file_name
    @arrfilename = @file_name.split('.')
    @extension = @arrfilename.last
    @mediafilename = remove_vietnamese_accents(@arrfilename[0...-1].join('.').gsub(" ", "-").gsub("---", "-").gsub("--", "-").upcase)
    folder_path = '/data/hrm/'
    name_file_new = remove_vietnamese_accents("HRM-#{@mediafilename}-#{file_new.id}.#{@extension}")
    path_new_file = "#{folder_path}#{name_file_new}"

    FileUtils.mkdir_p(folder_path) unless File.exist?(folder_path)
    FileUtils.mv(file[:tempfile].path, path_new_file)
    FileUtils.chmod_R 0o755, path_new_file

    @MediafileUpdate = Mediafile.find(file_new.id)
    @MediafileUpdate.update(file_name: name_file_new)

    {
      id: file_new.id,
      name: name_file_new,
    }
  end

  # Xóa một tập tin từ cơ sở dữ liệu và xóa tập tin từ hrm / dữ liệu
  # @author: Huy
  # @param id - ID của tệp được xóa
  def delete_mediadile(id)
    if !id.nil?
      oMediafile = Mediafile.where(id: id).first
      if !oMediafile.nil?
        file_path = "/data/hrm/#{oMediafile.file_name}"
        oMediafile.destroy
        if File.exist?(file_path)
          File.delete(file_path)
        end
      end
    end
  end

  ## Get user permissions based on user_id
  # @author: Hai + Huy
  # @date: 12/01/2023
  # Permissions from:
  #   1. Private tasks
  #   2. Position jobs
  #   3. Department
  #   4. Folowchart
  # input: user_id, folowchart
  # output: user permissions
  #

  def get_user_permission(user_id, folowchart)
    result = []
    arrConnects = []
    oUser = User.where("id = #{user_id}").first
    oCnnects = Connect.where("stream_id = #{folowchart}")
    if oUser.nil?
      return result
    end

    # 1. Private tasks
    oTasks = oUser.stasks
    if !oTasks.nil?
      oTasks.each do |oTask|
        oAccesses = oTask.accesses
        if !oAccesses.nil? && oTask.status == "ACTIVE"
          oAccesses.each do |oAccess|
            result.append({
              "resource" => "#{oAccess.resource.scode}", "url" => "#{oAccess.resource.url}" ,"permission" => "#{oAccess.permision}"
            })
          end
        end
      end
    end

    # 2. Position jobs & Department
    oWorks = oUser.works
    if !oWorks.nil?
      oWorks.each do |oWork|
        oPositionjob = oWork.positionjob
        if !oPositionjob.nil?

          # 2.1. Position jobs
          oTasks = oPositionjob.stasks
          if !oTasks.nil?
            oTasks.each do |oTask|
              oAccesses = oTask.accesses
              if !oAccesses.nil? && oTask.status == "ACTIVE"
                oAccesses.each do |oAccess|
                  result.append({
                    "resource" => "#{oAccess.resource.scode}", "url" => "#{oAccess.resource.url}" ,"permission" => "#{oAccess.permision}"
                  })
                end
              end
            end
          end

          # 2.2. Department
          odepartment = oPositionjob.department
          if !odepartment.nil? && (oPositionjob.scode.include?("TRUONG") || oPositionjob.scode.include?("PHO") || oPositionjob.scode.include?("GIAM-DOC") || oPositionjob.scode.include?("CHU-TICH"))
            @department_id = odepartment.id
            oPositionjobs = odepartment.positionjobs
            if !oPositionjobs.nil?
              oPositionjobs.each do |oPositionjob|
                oTasks = oPositionjob.stasks
                if !oTasks.nil?
                  oTasks.each do |oTask|
                    oAccesses = oTask.accesses
                    if !oAccesses.nil? && oTask.status == "ACTIVE"
                      oAccesses.each do |oAccess|
                        result.append({
                          "resource" => "#{oAccess.resource.scode}", "url" => "#{oAccess.resource.url}" ,"permission" => "#{oAccess.permision}"
                        })
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end

    # 3. Folowchart
    if !oCnnects.nil?
      oCnnects.each do |oCnnects|
        arrConnects.push({
          :start_id => oCnnects.nbegin,
          :end_id => oCnnects.nend
        })
      end
      nodes_hash = {}
      arrConnects.each do |arrConnect|
        start_id = arrConnect[:start_id]
        end_id = arrConnect[:end_id]
        nodes_hash[start_id] = { childs: [], parents: [] } if nodes_hash[start_id].nil? && !start_id.strip.empty?
        nodes_hash[end_id] = { childs: [], parents: [] } if nodes_hash[end_id].nil? && !end_id.strip.empty?
        nodes_hash[start_id][:childs].push(end_id) if nodes_hash[start_id].nil? != true && end_id.strip.empty? != true
        nodes_hash[end_id][:parents].push(start_id) if nodes_hash[end_id].nil? != true && start_id.strip.empty? != true
      end
      store = []
      node_dig_down(nodes_hash, store, @department_id.to_s, true)
      store.delete_if { |node| node == @department_id.to_s }
      if !store.nil?
        for department_id in store do
          oPositionjobs = Positionjob.where(department_id: department_id.to_i)
          if !oPositionjobs.nil?
            oPositionjobs.each do |oPositionjob|
              oTasks = oPositionjob.stasks
              if !oTasks.nil?
                oTasks.each do |oTask|
                  oAccesses = oTask.accesses
                  if !oAccesses.nil? && oTask.status == "ACTIVE"
                    oAccesses.each do |oAccess|
                      result.append({
                        "resource" => "#{oAccess.resource.scode}", "url" => "#{oAccess.resource.url}" ,"permission" => "#{oAccess.permision}"
                      })
                    end
                  end
                end
              end
            end
          end
        end
      end
    end

    return result.uniq
  end

  # Get the list of department belonging to the department
  # @author: Hai + Huy + Vu
  # @date: 12/01/2023
  # Description: Use recursion to find subunits of a unit
  # input: nodes_hash, store, node_id, b_childs
  # output: array department id
  #
  def node_dig_down(nodes_hash, store, node_id, b_childs)
    return if store.include?(node_id)
    store.push(node_id)
    if !nodes_hash[node_id].nil?
      nodes_hash[node_id][:childs].each do |child|
        node_dig_down(nodes_hash, store, child, b_childs)
      end
    else
        return
    end
  end

  ##
  # It takes a table name, a row id, a field name, a from value, a to value, and an owner, and saves a
  # history record
  # @author: Đạt
  # @date: 10/01/2023
  # Args:
  #   stable: the table name
  #   scol: the id of the row in the table that was changed
  #   fvalue: The value before the change
  #   tvalue: The value that the field is being changed to.
  #   owner: the user who made the change
  def log_history(stable, scol, fvalue, tvalue, owner)
    oHistory = Mhistory.new
    oHistory.stable = stable
    oHistory.srowid = scol
    oHistory.fvalue = fvalue
    oHistory.tvalue = tvalue
    oHistory.owner = owner
    oHistory.save
  end

  # Get list of next departments
  # @author: Q.Hai
  # @date: 30/01/2023
  # @input: department id
  # @output: array of departments
  #
  def get_next_departments(department_id)
    result = []
    # if department_id = NIL return result
    if department_id.nil?
        return result
    end
    oNode = Node.where(:department_id => department_id.to_i).first
    if !oNode.nil?
        oStreamId = oNode.stream_id
        if !oStreamId.nil?
            oConnects = Connect.where(:stream_id => oStreamId.to_i)
            if !oConnects.nil?
            oConnects.each do |oConnect|
                oDepartment = Department.where("id = #{oConnect.nend} AND id != #{department_id}").first
                if !oDepartment.nil?
                result.append({
                    "id" => "#{oDepartment.id}","name" => "#{oDepartment.name}"
                })
                end
            end
                return result
            end
        end
    end
  end

  # Get list of previous departments
  # @author: Q.Hai
  # @date: 30/01/2023
  # @input: department id
  # @output: array of departments
  #
  def get_previous_departments(department_id)
    result = []
    # if department_id = NIL return result
    if department_id.nil?
        return result
    end
    oNode = Node.where(:department_id => department_id.to_i).first
    if !oNode.nil?
        oStreamId = oNode.stream_id
        if !oStreamId.nil?
            oConnects = Connect.where(:stream_id => oStreamId.to_i)
            if !oConnects.nil?
            oConnects.each do |oConnect|
                oDepartment = Department.where("id = #{oConnect.nbegin} AND id != #{department_id}").first
                if !oDepartment.nil?
                result.append({
                    "id" => "#{oDepartment.id}","name" => "#{oDepartment.name}"
                })
                end
            end
                return result
            end
        end
    end
  end

  # Convert excel file to array data
  # @author: Vu
  # @date: 13/02/2023
  # @input: file
  # @output: array result
  def read_excel(file,header_index)
    spreadsheet = open_spreadsheet(file)
    header = spreadsheet.row(header_index)
    result = []
    ((header_index + 1)..spreadsheet.last_row).each do |i|
        row = spreadsheet.row(i)
        result.push(row)
    end
    result
  end

  # Get Roo class by excel file type
  # @author: Vu
  # @date: 13/02/2023
  # @input: file
  # @output: Roo class
  def open_spreadsheet(file)
    case File.extname(file.original_filename)
        when ".csv" then Roo::CSV.new(file.path)
        when ".xls" then Roo::Excel.new(file.path)
        when ".xlsx" then Roo::Excelx.new(file.path)
        else raise "Unknown file type: #{file.original_filename}"
    end
  end

  # Check valid email
  # @author: Vu
  # @date: 14/02/2023
  # @input: string
  # @output: boolean
  def is_valid_email?(email)
    check = email =~ /\A([a-z0-9_\.]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
    check == 0
  end

  VIETNAMESE_MAP = {
    "á" => "a", "à" => "a", "ả" => "a", "ã" => "a", "ạ" => "a",
    "ă" => "a", "ắ" => "a", "ằ" => "a", "ẳ" => "a", "ẵ" => "a", "ặ" => "a",
    "â" => "a", "ấ" => "a", "ầ" => "a", "ẩ" => "a", "ẫ" => "a", "ậ" => "a",
    "đ" => "d",
    "é" => "e", "è" => "e", "ẻ" => "e", "ẽ" => "e", "ẹ" => "e",
    "ê" => "e", "ế" => "e", "ề" => "e", "ể" => "e", "ễ" => "e", "ệ" => "e",
    "í" => "i", "ì" => "i", "ỉ" => "i", "ĩ" => "i", "ị" => "i",
    "ó" => "o", "ò" => "o", "ỏ" => "o", "õ" => "o", "ọ" => "o",
    "ô" => "o", "ố" => "o", "ồ" => "o", "ổ" => "o", "ỗ" => "o", "ộ" => "o",
    "ơ" => "o", "ớ" => "o", "ờ" => "o", "ở" => "o", "ỡ" => "o", "ợ" => "o",
    "ú" => "u", "ù" => "u", "ủ" => "u", "ũ" => "u", "ụ" => "u",
    "ư" => "u", "ứ" => "u", "ừ" => "u", "ử" => "u", "ữ" => "u", "ự" => "u",
    "ý" => "y", "ỳ" => "y", "ỷ" => "y", "ỹ" => "y", "ỵ" => "y", "Á" => "A",
    "À" => "A", "Ả" => "A", "Ã" => "A", "Ạ" => "A",
    "Ă" => "A", "Ắ" => "A", "Ằ" => "A", "Ẳ" => "A", "Ẵ" => "A", "Ặ" => "A",
    "Â" => "A", "Ấ" => "A", "Ầ" => "A", "Ẩ" => "A", "Ẫ" => "A", "Ậ" => "A",
    "Đ" => "D",
    "É" => "E", "È" => "E", "Ẻ" => "E", "Ẽ" => "E", "Ẹ" => "E",
    "Ê" => "E", "Ế" => "E", "Ề" => "E", "Ể" => "E", "Ễ" => "E", "Ệ" => "E",
    "Í" => "I", "Ì" => "I", "Ỉ" => "I", "Ĩ" => "I", "Ị" => "I",
    "Ó" => "O", "Ò" => "O", "Ỏ" => "O", "Õ" => "O", "Ọ" => "O",
    "Ô" => "O", "Ố" => "O", "Ồ" => "O", "Ổ" => "O", "Ỗ" => "O", "Ộ" => "O",
    "Ơ" => "O", "Ớ" => "O", "Ờ" => "O", "Ở" => "O", "Ỡ" => "O", "Ợ" => "O",
    "Ú" => "U", "Ù" => "U", "Ủ" => "U", "Ũ" => "U", "Ụ" => "U",
    "Ư" => "U", "Ứ" => "U", "Ừ" => "U", "Ử" => "U", "Ữ" => "U", "Ự" => "U",
    "Ý" => "Y", "Ỳ" => "Y", "Ỷ" => "Y", "Ỹ" => "Y", "Ỵ" => "Y"
  }
  # Function to convert Vietnamese to English without accents
  # @author: Huy
  # @date: 14/02/2023
  # @input: string
  # @output: string
  def remove_vietnamese_accents(str)
    str.gsub(/[#{VIETNAMESE_MAP.keys.join}]/, VIETNAMESE_MAP)
  end

  ##
  # It gets the list of mandocs with the user login
  def get_list_mandocs_with_user_login(idu)
    result=[]
    @user = User.where(id: idu).first
    if !@user.nil?
        id_dhandles = Mandocuhandle.where(user_id: idu).pluck(:mandocdhandle_id)
        if !id_dhandles.nil?
            id_dhandles.each do |id_d|
                id_mandoc = Mandocdhandle.where(id: id_d).pluck(:mandoc_id)
                if !id_mandoc.nil?
                    id_mandoc.each do |id_m|
                        list_mandoc = Mandoc.where(id: id_m).first
                        result.append(list_mandoc)
                    end
                end
            end
        end
        return result.reverse.uniq
      end
  end
  helper_method :get_list_mandocs_with_user_login

  ##
  # The above function is used to paginate data.
  # @author: Huy
  # @date: 02/03/2023
  # Args:
  #   object: the model you want to paginate
  #   str_query: the query string to filter the data
  #   default_per_page: the default number of records to display per page
  #
  # Returns:
  #   The return value of the last line of the method.
  def pagination_limit_offset(sql, default_per_page, config = nil)
    per_page = params[:per_page]&.to_i || default_per_page # số bản ghi hiển thị trên mỗi trang
    page = params[:page]&.to_i || 1 # trang hiện tại, nếu không có thì mặc định là trang đầu tiên
    search = params[:search] || ''

    # tính offset tương ứng với trang hiện tại
    offset = (page - 1) * per_page
    # lấy dữ liệu từ database với limit và offset tương ứng
    if config.nil?
      @total_records = sql.count
    else
      @total_records = sql.size
    end
    total_pages = (@total_records.to_f / per_page.to_f).ceil

    # lưu các biến vào session để sử dụng cho phân trang
    session[:per_page] = per_page
    session[:page] = page
    session[:search] = search
    session[:total_pages] = total_pages
    if config.nil?
      return sql.order(created_at: :desc).limit(per_page).offset(offset)
    else
      return sql.limit(per_page).offset(offset)
    end
  end

  # Pagin for complex queries: joins, group,...
  def limit_offset_query(sql)
    per_page = params[:per_page]&.to_i || 10
    page = params[:page]&.to_i || 1

    offset = (page - 1) * per_page

    @total_records = sql.map(&:attributes).size
    total_pages = (@total_records.to_f / per_page.to_f).ceil

    session[:per_page] = per_page
    session[:page] = page
    session[:total_pages] = total_pages

    sql.limit(per_page).offset(offset)

  end

  ##
  # It takes a path, a number of pages, and a number of records per page, and returns a pagination bar
  # @author: Huy
  # @date: 02/03/2023
  # Args:
  #   path: The path to the page you want to paginate.
  #   num_page: The number of records to show per page.
  def render_pagination_limit_offset(path, num_page, count)
    pagin_render = ""
    pagin_render << "<div class='d-flex justify-content-between align-items-center'>"
    pagin_render << "<div class='info fs--1 page_pagination_bottom' >"
    pagin_render << ""
    pagin_render << "</div>"
    pagin_render << "<div class='dataTables_paginate paging_simple_numbers d-flex align-items-center' >"
    if session[:total_pages] != "" && !session[:total_pages].nil?
      if session[:total_pages] > 1
        pagin_render << ""
        pagin_render << ""

        pagin_render << "<ul class='pagination pagination-sm m-0'>"
            if session[:page].to_i > 1
              pagin_render << "<li class='paginate_button page-item'><a class='page-link' data-page='#{session[:page].to_i - 1}' href='#{path}&amp;page=#{session[:page].to_i - 1}'>#{lib_translate('Previous')}</a></li>"
            end
            1.upto(session[:total_pages]) do |page|
              if page == session[:page].to_i
                if page > 1
                  if page > 2
                    pagin_render << "<li class='paginate_button page-item'><a class='page-link' data-page='1' href='#{path}&amp;page=1'>1</a></li>"
                  end
                  if page > 3
                    pagin_render << "<li class='paginate_button page-item'><a class='page-link' data-page='2' href='#{path}&amp;page=2'>2</a></li>"
                  end
                  if page > 4
                    pagin_render << "<li class='paginate_button page-item page-link'>...</li>"
                  end
                  pagin_render << "<li class='paginate_button page-item'><a class='page-link' data-page='#{session[:page].to_i - 1}' href='#{path}&amp;page=#{session[:page].to_i - 1}'>#{page - 1}</a></li>"
                end
                pagin_render << "<li class='paginate_button page-item active'><a class='page-link' data-page='#{page}' href='#{path}&amp;page=#{page}'>#{page}</a></li>"
                if page < session[:total_pages]
                  pagin_render << "<li class='paginate_button page-item'><a class='page-link' data-page='#{session[:page].to_i + 1}' href='#{path}&amp;page=#{session[:page].to_i + 1}'>#{page + 1}</a></li>"
                  if page < session[:total_pages] - 3
                    pagin_render << "<li class='paginate_button page-item page-link'>...</li>"
                  end
                  if page < session[:total_pages] - 2
                    pagin_render << "<li class='paginate_button page-item'><a class='page-link' data-page='#{session[:total_pages].to_i - 1}' href='#{path}&amp;page=#{session[:total_pages] - 1}'>#{session[:total_pages] - 1}</a></li>"
                  end
                  if page < session[:total_pages] - 1
                    pagin_render << "<li class='paginate_button page-item'><a class='page-link' data-page='#{session[:total_pages]}' href='#{path}&amp;page=#{session[:total_pages]}'>#{session[:total_pages]}</a></li>"
                  end
                end
              end
            end
            if session[:page].to_i < session[:total_pages]
              pagin_render << "<li class='paginate_button page-item'><a class='page-link' data-page='#{session[:page].to_i + 1}' href='#{path}&amp;page=#{session[:page].to_i + 1}'>#{lib_translate('Next')}</a></li>"
            end
        pagin_render << "</ul>"
      else
        pagin_render << "<ul class='pagination pagination-sm m-0'>"
        pagin_render << "<li class='paginate_button page-item active'><a class='page-link' data-page='1' href='#{path}&amp;page=1'>1</a></li>"
        pagin_render << "</ul>"
      end
    end
    pagin_render << "<div class='dataTables_length ms-2' id='positonjob_table_length'>"
    pagin_render << "<div class='btn-group'>"
    pagin_render << "<button class='btn btn-sm btn-outline-primary dropdown-toggle' style='border-color: var(--falcon-bg-navbar-glass);' type='button' data-bs-toggle='dropdown' aria-haspopup='true' aria-expanded='false'>#{session[:per_page]}</button>"
    pagin_render << "<div class='dropdown-menu'> "
    pagin_render << "<a class='dropdown-item' data-limit='#{10}' href='#{path}&amp;per_page=#{num_page}'>#{num_page}</a>"
    pagin_render << "<a class='dropdown-item' data-limit='#{25}' href='#{path}&amp;per_page=#{num_page + 15}'>#{num_page + 15}</a>"
    pagin_render << "<a class='dropdown-item' data-limit='#{50}' href='#{path}&amp;per_page=#{num_page + 40}'>#{num_page + 40}</a>"
    pagin_render << "</div>"
    pagin_render << "</div>"
    pagin_render << "</div>"
    pagin_render << "</div>"
    pagin_render << "<div class='info'  style='width: 5%;'>"
    pagin_render << "</div>"
    pagin_render << "</div>"
  end
  helper_method :render_pagination_limit_offset

  # render pagination with remote call
  def render_pagination_style_1(func_name,cur_page,total_pages, per_page)

    cur_page = cur_page.to_i
    total_pages = total_pages.to_i
    per_page = per_page.to_i

    buttons = ""
    if total_pages > 1
      (1..total_pages).each do |page|
        if page == cur_page
          if page > 1
            if page > 2
              buttons << "<li class='page-item'><a class='page-link' data-page='1' style=\"cursor: pointer;\" onclick='#{func_name}(1)'>1</a></li>"
            end
            if page > 3
              buttons << "<li class='page-item'><a class='page-link' data-page='2' style=\"cursor: pointer;\" onclick='#{func_name}(2)'>2</a></li>"
            end
            if page > 4
              buttons << "<li class='page-item page-link' style='pointer-events: none;'>...</li>"
            end
            buttons << "<li class='page-item'><a class='page-link' style=\"cursor: pointer;\" data-page='#{cur_page - 1}' onclick='#{func_name}(#{cur_page - 1})'>#{page - 1}</a></li>"
          end
          buttons << "<li class='page-item active' style='pointer-events: none;'><div class='page-link' data-page='#{page}' onclick='#'>#{page}</div></li>"
          if page < total_pages
            buttons << "<li class='page-item'><a class='page-link' style=\"cursor: pointer;\" data-page='#{cur_page + 1}' onclick='#{func_name}(#{cur_page + 1})'>#{page + 1}</a></li>"
            if page < total_pages - 3
              buttons << "<li class='page-item page-link' style='pointer-events: none;'>...</li>"
            end
            if page < total_pages - 2
              buttons << "<li class='page-item'><a class='page-link' style=\"cursor: pointer;\" data-page='#{total_pages.to_i - 1}' onclick='#{func_name}(#{total_pages - 1})'>#{total_pages - 1}</a></li>"
            end
            if page < total_pages - 1
              buttons << "<li class='page-item'><a class='page-link' style=\"cursor: pointer;\" data-page='#{total_pages}' onclick='#{func_name}(#{total_pages})'>#{total_pages}</a></li>"
            end
          end
        end
      end
        buttons << "<li class='page-item ms-3 #{'disabled' if cur_page <= 1}'><a class='page-link' data-page='#{cur_page - 1}' style=\"cursor: pointer;\" onclick='#{func_name}(#{cur_page - 1})'><span class='fas fa-angle-left'></span></a></li>"
        buttons << "<li class='page-item #{'disabled' if cur_page >= total_pages}'><a class='page-link' data-page='#{cur_page + 1}' style=\"cursor: pointer;\" onclick='#{func_name}(#{cur_page + 1})'><span class='fas fa-angle-right'></span></a></li>"
    else
      buttons = "<li class='page-item active' style='pointer-events: none;'><div class='page-link' data-page='1'>1</div></li>"
    end

    pagin_render = """
                    <div class='d-flex align-items-center'>
                      <ul class='pagination pagination-sm m-0' data-total='#{total_pages}'>
                        #{buttons}
                      </ul>
                    </div>
                  """
  end
  helper_method :render_pagination_style_1

  ##
  # A function that helps to render the search form in the table.
  # @author: Huy
  # @date: 02/03/2023
  # Args:
  #   path: the path to the controller action that will handle the search
  def render_search_pagination(path)
    search_render = ""
    search_render << "<div class='top mt-2 mb-2'>"
    search_render << "<div id='positonjob_table_filter' class='dataTables_filter' style='display: flex;flex-direction: row-reverse;'>"
    search_render << "<form class='d-flex' action='#{path}' accept-charset='UTF-8' method='get' style='width: 30%;'><input name='utf8' type='hidden' value='✓'>"
    search_render << "<input type='text' name='search' id='search_user' value='#{params[:search]}' placeholder='#{lib_translate('Search')}' class='form-control form-control-sm'>"
    search_render << "<input class='d-none' name='lang' value='vi'><input type='submit' hidden>"
    search_render << "</form>"
    search_render << "</div>"
    search_render << "</div>"
  end
  helper_method :render_search_pagination

  # Get list token default
  # @author: Vu
  # @date: 06/03/2023
  # @output: string - value
  # @return: array object
  # @note: format from tinymce plugin token
  def get_token_list

    user_tokens = {
      text:"Nhân viên",
      items:[
        {text:"Họ và tên",value:"USER_FULLNAME"},
        {text:"Quốc tịch",value:"USER_NATIONALITY"},
        {text:"Ngày sinh [dd/mm/yyyy]",value:"USER_BIRTHDAY"},
        {text:"Giới tính",value:"USER_GENDER"},
        {text:"CCCD/CMND",value:"USER_IDENTITY"},
        {text:"Nơi cấp CCCD/CMND",value:"USER_IDENTITY_ISSUED_BY"},
        {text:"Ngày cấp CCCD/CMND",value:"USER_IDENTITY_ISSUED_DATE"},
        {text:"SĐT",value:"USER_PHONE"},
        {text:"Email",value:"USER_EMAIL"},
        {text:"Địa chỉ thường trú",value:"USER_ADDRESS"},
        {text:"Địa chỉ tạm trú",value:"USER_ADDRESS2"},
        {text:"Trình độ",value:"USER_ACAMEDICRANK"},
        # {text:"Chuyên ngành",value:"USER_SPECIALIZE"},
        {text:"Đơn vị công tác",value:"USER_DEPARTMENT"},
        {text:"Chức danh",value:"USER_JOBTITLE"}
      ]
    }

    organization_tokens = {
      text:"Tổ chức",
      items:[
        {text:"Tên",value:"ORG_NAME"},
        {text:"Địa chỉ",value:"ORG_PLACE"},
      ]
    }

    contract_tokens = {
      text:"Hợp đồng",
      items:[
        {text:"Ngày bắt đầu [d/m/y]",value:"CONTRACT_DTFROM"},
        {text:"Ngày bắt đầu [ngày d tháng m năm y]",value:"CONTRACT_DTFROM2"},
        {text:"Ngày kết thúc",value:"CONTRACT_DTTO"},
        {text:"Thời hạn",value:"CONTRACT_MAX_DATE"},
        {text:"Mức lương",value:"CONTRACT_SALARY"},
      ]
    }

    [user_tokens, contract_tokens,organization_tokens]

  end

  # Get all token default value
  # @author: Vu
  # @date: 13/02/2023
  # @input: contract_id: id contract
  # @output: array hash
  def get_contract_token_value(contract_id)

    contract = Contract.where("id = #{contract_id}").first
    if contract.nil?
      return []
    end

    user = User.where("id = #{contract.user_id}").first
    if user.nil?
      return []
    end

    tokens = []
    #### USER
    # Họ tên
    tokens.push({name:"USER_FULLNAME",value:"#{user.last_name} #{user.first_name}"})
    # quốc tịch

    tokens.push({name:"USER_NATIONALITY",value:"#{user.nationality}"})
    # Ngày sinh: dd/mm/yyy
    tokens.push({name:"USER_BIRTHDAY",value:"#{user.birthday.strftime('%d/%m/%Y')}"})
    # Giới tính
    tokens.push({name:"USER_GENDER",value:"#{user.gender == '0' ? 'Nam' : user.gender == '1' ? 'Nữ' : 'Khác'}"})
    # CCCD/CMND
    identity = Identity.where("user_id = #{user.id} AND stype = 'CCCD'").first
    tokens.push({name:"USER_IDENTITY",value: identity.nil? ? "" : identity.name})
    # Nơi cấp CCCD/CMND
    tokens.push({name:"USER_IDENTITY_ISSUED_BY",value:identity.nil? ? "" : identity.issued_by})
    # Ngày cấp CCCD/CMND
    tokens.push({name:"USER_IDENTITY_ISSUED_DATE",value:identity.nil? ? "" : identity.issued_date.strftime("%d/%m/%Y")})
    # SĐT
    tokens.push({name:"USER_PHONE",value:"#{user.mobile}"})
    # Email
    tokens.push({name:"USER_EMAIL",value:"#{user.email}"})
    # Địa chỉ thường trú
    addresses = Address.where("user_id = #{user.id} AND status = 'ACTIVE'")
    addr = addresses.detect{ |address| address.stype == 'Thường Trú' }
    addr = addr.nil? ? "" : "#{addr.no} #{addr.street} #{addr.ward} #{addr.district} #{addr.city} #{addr.province}"
    tokens.push({name:"USER_ADDRESS",value:addr})
    # Địa chỉ tạm trú
    addr = addresses.detect{ |address| address.stype != 'Thường Trú' }
    addr = addr.nil? ? "" : "#{addr.no} #{addr.street} #{addr.ward} #{addr.district} #{addr.city} #{addr.province}"
    tokens.push({name:"USER_ADDRESS2",value:addr})
    # Trình độ
    tokens.push({name:"USER_ACAMEDICRANK",value:"#{user.academic_rank}"})
    # # Chuyên ngành
    # {name:"USER_SPECIALIZE",value:""}
    department = ""
    job_name = ""
    works = user.works
    works.each do |work|
        if !work.positionjob.nil? && !work.positionjob.department.nil?
          department = work.positionjob.department.name
          job_name = work.positionjob.name
        end
    end
    # Đơn vị công tác
    tokens.push({name:"USER_DEPARTMENT",value:department})
    # Chức danh
    tokens.push({name:"USER_JOBTITLE",value:department})

    ###### Hợp đồng
    # Ngày ký: dd/mm/yyyy
    tokens.push({name:"CONTRACT_DTFROM",value:contract.dtfrom&.strftime("%d/%m/%Y")})
    # Ngày ký: Ngày dd tháng mm Năm yyyy
    tokens.push({name:"CONTRACT_DTFROM2",value:contract.dtfrom&.strftime("Ngày %d tháng %m năm %Y")})
    # Ngày hết hạn
    tokens.push({name:"CONTRACT_DTTO",value:contract.dtto&.strftime("%d/%m/%Y")})
    # Thời hạn
    tokens.push({name:"CONTRACT_MAX_DATE",value:contract&.issued_place})
    # Lương cơ bản
    num_groups = contract.base_salary.to_s.chars.to_a.reverse.each_slice(3)
    num_groups = num_groups.map(&:join).join('.').reverse
    tokens.push({name:"CONTRACT_SALARY",value:"#{num_groups}"})

    ###### Tổ chức
    userOrg = nil
    uorg = Uorg.where("user_id = #{user.id}").first
    if !uorg.nil?
      userOrg = Organization.where("id = #{uorg.organization_id}").first
    end

    # Tên tổ chức
    tokens.push({name:"ORG_NAME",value: userOrg.nil? ? "": userOrg.name})
    # # địa chỉ
    tokens.push({name:"ORG_PLACE",value:"Số 298 Hà Huy Tập, Phường Tân An, Tp. Buôn Ma Thuột, Tỉnh Đắk Lắk"})
  end

  helper_method :get_token_list
  helper_method :get_default_token_value

  # It takes user_id, dlogin, dlogout, location, browser, device, os
  # Account history
  # @author: Thai
  # @date: 06/04/2023
  # Args:
  #   user_id: references user id login or logout
  #   dlogin: date time when user login or logout
  #   dlogout: date time when user login or logout
  #   location: Ip address when user login or logout
  #   browser: Name Browser when user login or logout
  #   device: Name device when user login or logout
  #   os: Name os when user login or logout
  def account_history(dlogin, dlogout, location, browser, device, user_id, os)
    Acchist.create({
      dlogin: dlogin,
      dlogout: dlogout,
      location: location,
      browser: browser,
      device: device,
      user_id: user_id,
      os: os
    })
  end

  # Lấy IP chính xác nhất
  def get_best_ip
    # Thử các cách theo thứ tự ưu tiên
    ip = request.env['HTTP_X_FORWARDED_FOR']&.split(',')&.first&.strip ||
         request.env['HTTP_X_REAL_IP'] ||
         request.env['HTTP_X_FORWARDED'] ||
         request.env['HTTP_X_CLUSTER_CLIENT_IP'] ||
         request.env['HTTP_FORWARDED_FOR'] ||
         request.env['HTTP_FORWARDED'] ||
         request.ip ||
         request.remote_addr

    # Validate IP format
    if ip && ip.match?(/^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$/)
      ip
    else
      '127.0.0.1'  # Fallback
    end
  end

  # Update user permission status to logout all systems
  # @author: H.Vu
  # @date: 28/07/2023
  # @input: user_ids - array user id
  # @output:
  def updateUsersPermissionChange(user_ids)
    isvalid = []
    # erp
    isvalid[0] = "YES"
    # sft
    isvalid[1] = "YES"
    # masset
    isvalid[2] = "YES"
    # hasset
    isvalid[3] = "YES"
    User.where(id:user_ids).update_all(isvalid: isvalid.join("||"))
  end

  def handle_standard_error exception

    position = exception&.backtrace&.take(5)&.join(",")&.to_json&.html_safe&.gsub("\`","")
    message = exception&.message&.gsub("\`","")
    @code = 200
    case exception.class
    when ActiveRecord::RecordNotFound
      @code = 404
    when ActiveRecord::RecordInvalid
      @code = 422
    when ActionController::ParameterMissing
      @code = 400
    else
      @code = 500
    end

    err = Errlog.create({
      msg: message,
      msgdetails: position,
      surl: request.fullpath,
      owner: "#{session[:user_id]}/#{session[:user_fullname]}",
      dtaccess: DateTime.now,
    })
    session[:last_path] = request.fullpath
    respond_to do |format|
      format.html { render template: 'errlogs/standard_error', status: :internal_server_error, layout: false }
      format.js { render js: "showAlert('Lỗi không xác định','danger')"}
    end
  end

  def not_found_method
    if !request.path.ends_with?('.js.map') && !request.path.ends_with?('.css.map') && !request.path.ends_with?('.scss.css')
      detail = "Not Found [#{request.method}] #{request.fullpath}"
      err = Errlog.create({
        msg: "Routing Error",
        msgdetails: detail,
        surl: request.fullpath,
        owner: "#{session[:user_id]}/#{session[:user_fullname]}",
        dtaccess: DateTime.now,
      })
      @code = 404
      session[:last_path] =  request.fullpath
      respond_to do |format|
        format.html { render template: 'errlogs/standard_error', status: :internal_server_error, layout: false }
        format.js { render js: "showAlert('Không tìm thấy tài nguyên','danger')"}
      end
    end
  end
  def get_leave_data_by_user_id(user_id, index = nil, current_year, type)
    user = User.find_by(id: user_id)
    return if user.nil?

    start_year = eligible_contract_start_year(user_id)
    return if start_year.nil?
    diff_years = current_year - start_year
    bien_tham_nien = tinh_moc_theo_doi(diff_years)

    position = get_user_position(user_id)
    return [nil, false] unless position
    bien_cong_viec = position.holno.to_i

    total_phep = total_leave_taken_last_year(user_id, current_year - 1)
    bien_phep_ton = calculate_leave_remaining(bien_cong_viec, total_phep)

    tong_phep, needs_count, han_su_dung = calculate_total_leave(user_id, current_year, bien_cong_viec, bien_tham_nien, bien_phep_ton, type)

    data = build_leave_data(user, index, bien_cong_viec, bien_tham_nien, bien_phep_ton, tong_phep, current_year, han_su_dung)

    [data, needs_count]
  end

  # Kiểm tra hợp đồng
  def eligible_contract_start_year(user_id)
      contracts = Contract.where(user_id: user_id)
      valid_contracts = contracts.reject { |c| c.name.to_s.downcase.include?("tập nghề") || c.name.to_s.downcase.include?("thử việc") }
      earliest_contract = valid_contracts.min_by { |c| c.dtfrom || Time.now }
      earliest_contract&.dtfrom&.year
  end
  # kiểm tra vị trí
  def get_user_position(user_id)
      Work.where(user_id: user_id).where.not(positionjob_id: nil).first&.positionjob
  end
  # Tính phép đã sử dụng
  def total_leave_taken_last_year(user_id, year)
      holiday = Holiday.find_by(user_id: user_id, year: year)
      return 0 unless holiday
      Holpro.where(holiday_id: holiday.id, sholtype: "PHEP").pluck(:dttotal).compact.map(&:to_f).sum
  end
  # Tính phép tồn
  def calculate_leave_remaining(bien_cong_viec, total_phep)
      raw = [bien_cong_viec - total_phep, 0].max
      raw % 1 == 0 ? raw.to_i : raw
  end
  # Tổng số phép năm nay + đánh dấu đếm
  def calculate_total_leave(user_id, current_year, bien_cong_viec, bien_tham_nien, bien_phep_ton, type)
      holiday = Holiday.find_by(user_id: user_id, year: current_year)
      han_su_dung_date = Date.strptime("31/03/#{current_year}", "%d/%m/%Y")
      today = Date.today
      tong_phep = 0
      needs_count = false
      han_su_dung = "31/03/#{current_year}"
      if type == "SAVE"
          phep_ton_duoc_tinh = today <= han_su_dung_date ? bien_phep_ton.to_f : 0
          raw_total = bien_cong_viec + bien_tham_nien + phep_ton_duoc_tinh
          tong_phep = raw_total % 1 == 0 ? raw_total.to_i : raw_total
      else
          holiday = Holiday.find_by(user_id: user_id, year: current_year)
          if holiday.nil? || holiday.total.blank?
              needs_count = true
          else
              tong_phep = holiday.total.to_f
              tong_phep = tong_phep.floor == tong_phep ? tong_phep.to_i : tong_phep

              holdetail = Holdetail.where(holiday_id: holiday.id, name:"Phép tồn").first
              han_su_dung = holdetail&.dtdeadline&.strftime("%d/%m/%Y")
          end
      end
      [tong_phep, needs_count, han_su_dung]
  end
  #  Tạo dữ liệu hiển thị
  def build_leave_data(user, index, bien_cong_viec, bien_tham_nien, bien_phep_ton, tong_phep, current_year, han_su_dung)
      {
        stt: index,
        user_id: user.id,
        code: user.sid,
        full_name: "#{user.last_name} #{user.first_name}",
        dob: user.birthday&.strftime("%d/%m/%Y") || "",
        cong_viec: bien_cong_viec,
        tham_nien: bien_tham_nien,
        phep_ton: bien_phep_ton,
        han_su_dung: han_su_dung,
        tong_phep: tong_phep
      }
  end

  def tinh_moc_theo_doi(diff_years)
      case diff_years
      when 0...5 then 0
      when 5...10 then 1
      when 10...15 then 2
      when 15...20 then 3
      when 20...25 then 4
      when 25...30 then 5
      when 30...35 then 6
      when 35...40 then 7
      when 40...45 then 8
      when 45...50 then 9
      when 50...55 then 10
      when 55...60 then 11
      else
        diff_years >= 60 ? 12 : 0
      end
  end

  # Hàm cảnh báo phép
  def alert_holpros_approval_pending
    datas = []
    oHolpros = Holpro.where.not(status: ["TEMP", "DONE", "CANCEL-DONE"])

    oHolpros.each do |holpro|
      # Người tạo đơn (người gửi)
      holiday = Holiday.find_by(id: holpro.holiday_id)
      creator = User.find_by(id: holiday&.user_id)
      creator_name = [creator&.last_name, creator&.first_name].compact.join(" ")

      # Thông tin chi tiết đơn nghỉ phép
      details = Holprosdetail.where(holpros_id: holpro.id).map do |detail|
        {
          sholtype: get_name_holtype(detail.sholtype)&.name || "",
          details: format_leave_details(detail.details),
          place: detail&.issued_place == "IN-COUNTRY" ? "Trong nước" : "Nước ngoài",
          address: detail.place_before_hol,
          handover_receiver: format_handover_receivers(detail.handover_receiver),
          notes: detail.note
        }
      end

      # Người duyệt đơn
      mandoc = Mandoc.find_by(holpros_id: holpro.id)
      next unless mandoc

      mandocdhandle = Mandocdhandle.where(mandoc_id: mandoc.id).last
      next unless mandocdhandle

      mandocuhandles = Mandocuhandle.where(mandocdhandle_id: mandocdhandle.id, status: "CHUAXULY")
      if mandocuhandles.present?
        mandocuhandles.each do |uh|
          approver = User.find_by(id: uh.user_id)
          approver_name = [approver&.last_name, approver&.first_name].compact.join(" ")

          # Gom nhóm theo approver_id
          existing = datas.find { |d| d[:user_signed][:id] == approver&.id }

          if existing
            # Đã có user_signed → push thêm record mới
            existing[:records] << {
              holpro_id: holpro.id,
              total: holpro&.dttotal,
              status: find_status(holpro&.status)&.dig(:name) || "",
              date_uhandle: uh&.created_at&.strftime('%d/%m/%Y %H:%M'),
              user_sender: {
                id: creator&.id,
                sid: creator&.sid,
                name: creator_name,
                email: creator&.email,
                name_positionjob: get_work(creator&.id)&.name_positionjob || "",
                name_department: get_work(creator&.id)&.name_department || "",
                uorg_code: get_uorg_codes(creator&.id)
              },
              details: details
            }
          else
            # Chưa có → tạo mới nhóm
            datas << {
              user_signed: {
                id: approver&.id,
                name: approver_name,
                email: approver&.email,
                name_positionjob: get_work(approver&.id)&.name_positionjob || "",
                name_department: get_work(approver&.id)&.name_department || "",
                uorg_code: get_uorg_codes(approver&.id)
              },
              records: [
                {
                  holpro_id: holpro.id,
                  total: holpro&.dttotal,
                  status: find_status(holpro&.status)&.dig(:name) || "",
                  date_uhandle: uh&.created_at&.strftime('%d/%m/%Y %H:%M'),
                  user_sender: {
                    id: creator&.id,
                    sid: creator&.sid,
                    name: creator_name,
                    email: creator&.email,
                    name_positionjob: get_work(creator&.id)&.name_positionjob || "",
                    name_department: get_work(creator&.id)&.name_department || "",
                    uorg_code: get_uorg_codes(creator&.id)
                  },
                  details: details
                }
              ]
            }
          end
        end
      end
    end


    if datas.length > 0
      datas.each do |data|
        HolidayMailer.alert_holpros_approval_pending(data).deliver_now
      end
    end

  end

  def find_status(value)
    case value.to_s
    when "DONE", "Đã duyệt", "đã duyệt", "ĐÃ DUYỆT"
      {scode: "DONE", name: "Đã duyệt", named: "đã duyệt", nameu: "ĐÃ DUYỆT"}
    when "PENDING", "Chờ duyệt", "chờ duyệt", "CHỜ DUYỆT"
      {scode: "PENDING", name: "Chờ duyệt", named: "chờ duyệt", nameu: "CHỜ DUYỆT"}
    when "TEMP", "Lưu nháp", "lưu nháp", "LƯU NHÁP"
      {scode: "TEMP", name: "Lưu nháp", named: "lưu nháp", nameu: "LƯU NHÁP"}
    when "PROCESSING", "Đang xử lý đơn", "đang xử lý đơn", "ĐANG XỬ LÝ ĐƠN"
      {scode: "PROCESSING", name: "Đang xử lý đơn", named: "đang xử lý đơn", nameu: "ĐANG XỬ LÝ ĐƠN"}
    when "CANCEL", "Đơn bị hủy", "đơn bị hủy", "ĐƠN BỊ HỦY"
      {scode: "CANCEL", name: "Đơn bị hủy", named: "đơn bị hủy", nameu: "ĐƠN BỊ HỦY"}
    when "CANCEL-DONE", "Đã duyệt(điều chỉnh)", "đã duyệt(điều chỉnh)", "ĐÃ DUYỆT (ĐIỀU CHỈNH)"
      {scode: "CANCEL-DONE", name: "Đã duyệt(điều chỉnh)", named: "đã duyệt(điều chỉnh)", nameu: "ĐÃ DUYỆT (ĐIỀU CHỈNH)"}
    when "REFUSE", "Đơn từ chối", "đơn từ chối", "ĐƠN TỪ CHỐI"
      {scode: "REFUSE", name: "Đơn từ chối", named: "đơn từ chối", nameu: "ĐƠN TỪ CHỐI"}
    else
      nil
    end
  end
  def get_uorg_codes(user_id)
    return [] if user_id.blank?

    Organization.where(
      id: Uorg.where(user_id: user_id).select(:organization_id)
    ).pluck(:scode).compact
  end

  def get_name_holtype(scode)
    return nil unless Holtype.where(code: scode).first # Trả về nil không tồn tại
    name_holtype = Holtype.where(code: scode).select(:name).first
  end

  def format_handover_receivers(raw)
    return "" if raw.blank?

    # Tách từng người
    people = raw.split("|||").map do |entry|
      parts = entry.split("$$$")
      parts[1].to_s.strip # Lấy tên
    end.compact

    return "" if people.empty?

    # Thêm dấu phẩy cho người đầu tiên nếu nhiều hơn 1 người
    if people.length > 1
      people[0..-2].map { |p| "#{p}," }.push(people.last).join("\n")
    else
      people.first.to_s
    end
  end

  def format_leave_details(details)
    session_mapping = {
      "ALL" => "Cả ngày",
      "AM"  => "Buổi sáng",
      "PM"  => "Buổi chiều"
    }

    items = details.to_s.split('$$$').map do |item|
      date_part, session = item.split('-')
      next unless date_part

      label = session_mapping[session&.upcase.to_s.strip] || 'Không xác định'
      "#{date_part.strip} (#{label})"
    end.compact

    items.join("\n") # xuống dòng giữa các dòng
  end

  def get_work(user_id)
    return nil unless User.where(id: user_id).first # Trả về nil không tồn tại
    record = User.with_basic_work
              .active_cohuu
              .select(
                'positionjobs.name AS name_positionjob',
                'departments.name AS name_department',
              ).where("users.id = ?", user_id).first
  end
end
