class Log_activity
	def create_accesshistory(session, request)
            accesshistory = Accesshistory.new
    if(!session[:user_id].nil?)
      user = User.find(session[:user_id])
      if !user.nil?
            accesshistory.iuser = user.id.to_s + "_" + user.user_name
      end
    elsif(session[:user_id].nil? && session[:client_id])
      client = Client.find(session[:client_id])
      if !client.nil?
        accesshistory.iuser = client.id.to_s + "_" + client.username
      end
    end
    user_agent = request.env['HTTP_USER_AGENT']
    
            access_type = Accesstype.where("name = '#{MConst::ACCESS_TYPE_BROWSER}'").first
            accesshistory.accesstype_id = access_type.nil? ? nil : access_type.id
            accesshistory.islive = "true"

            if(user_agent.to_s.include? MConst::BROWSER_CHROME)
              browser = Browser.where("name = '#{MConst::BROWSER_CHROME}'").first
              accesshistory.browser_id = browser.nil? ? nil : browser.id
            elsif(user_agent.to_s.include? "Firefox")
              browser = Browser.where("name = '#{MConst::BROWSER_FIRE_FOX}'").first
              accesshistory.browser_id = browser.nil? ? nil : browser.id
            elsif(user_agent.to_s.include? "Internetexplorer")
              browser = Browser.where("name = '#{MConst::BROWSER_INTERNET_EXPLORER}'").first
              accesshistory.browser_id = browser.nil? ? nil : browser.id
            elsif(user_agent.to_s.include? MConst::BROWSER_SAFARI)
              browser = Browser.where("name = '#{MConst::BROWSER_SAFARI}'").first
              accesshistory.browser_id = browser.nil? ? nil : browser.id
            elsif(user_agent.to_s.include? MConst::BROWSER_UC)
              browser = Browser.where("name = '#{MConst::BROWSER_UC}'").first
              accesshistory.browser_id = browser.nil? ? nil : browser.id
            elsif(user_agent.to_s.include? "Androidbrowser")
              browser = Browser.where("name = '#{MConst::BROWSER_ANDROID}'").first
              accesshistory.browser_id = browser.nil? ? nil : browser.id
            elsif(user_agent.to_s.include? MConst::BROWSER_EDGE)
              browser = Browser.where("name = '#{MConst::BROWSER_EDGE}'").first
              accesshistory.browser_id = browser.nil? ? nil : browser.id
            elsif(user_agent.to_s.include? "Operamini")
              browser = Browser.where("name = '#{MConst::BROWSER_OPERA_MINI}'").first
              accesshistory.browser_id = browser.nil? ? nil : browser.id
            end
            
            if(user_agent.to_s.include? MConst::OS_WINDOWS_PHONE)
              os = Operatingsystem.where("name = '#{MConst::OS_WINDOWS_PHONE}'").first
              accesshistory.operatingsystem_id = os.nil? ? nil : os.id
            elsif(user_agent.to_s.include? MConst::OS_WINDOWS)
              os = Operatingsystem.where("name = '#{MConst::OS_WINDOWS}'").first
              accesshistory.operatingsystem_id = os.nil? ? nil : os.id
            elsif(user_agent.to_s.include? MConst::OS_ANDROID)
              os = Operatingsystem.where("name = '#{MConst::OS_ANDROID}'").first
              accesshistory.operatingsystem_id = os.nil? ? nil : os.id
            elsif(user_agent.to_s.include? MConst::OS_LINUX)
              os = Operatingsystem.where("name = '#{MConst::OS_LINUX}'").first
              accesshistory.operatingsystem_id = os.nil? ? nil : os.id
            elsif(user_agent.to_s.include? "Mac OS")
              os = Operatingsystem.where("name = '#{MConst::OS_IOS}'").first
              accesshistory.operatingsystem_id = os.nil? ? nil : os.id
            elsif(user_agent.to_s.include? MConst::OS_MACINTOSH)
              os = Operatingsystem.where("name = '#{MConst::OS_MACINTOSH}'").first
              accesshistory.operatingsystem_id = os.nil? ? nil : os.id
            elsif(user_agent.to_s.include? MConst::OS_CHROME)
              os = Operatingsystem.where("name = '#{MConst::OS_CHROME}'").first
              accesshistory.operatingsystem_id = os.nil? ? nil : os.id
            end

            if((user_agent.to_s.include? MConst::OS_ANDROID) || (user_agent.to_s.include? MConst::OS_WINDOWS_PHONE))
              device = Device.where("name = '#{MConst::DEVICE_MOBILE}'").first
              accesshistory.device_id = device.nil? ? nil : device.id
            else
              device = Device.where("name = '#{MConst::DEVICE_DESKTOP}'").first
              accesshistory.device_id = device.nil? ? nil : device.id
            end
            accesshistory.mdatetime = Time.now
            accesshistory.imapplication = @app.nil? ? nil : @app.id.to_s + "_" + @app.name

            ip_address = request.env['action_dispatch.remote_ip'].to_s
            ip = ip_address.split('.')
            integer_ip = 16777216 * (ip[0].to_f) + 65536 * (ip[1].to_f) + 256 * (ip[2].to_f) + (ip[3].to_f)
            geoip = Geoip.where("begin_ip_num <= #{integer_ip} and end_ip_num >= #{integer_ip}").first
            location = ip_address
            time_value = 0
            if(!geoip.nil?)
              location += " (#{geoip.country_name})"
              accesshistory.mtimezone = geoip.mtimezone
            end
            accesshistory.location = location
            accesshistory.save
            return accesshistory.id
	end

	def create_mactivity(accesshistory, action, application, instance)
		if !accesshistory.to_s.empty?
			mactivity = Mactivity.new()
			mactivity.maction = action
			mactivity.mdatetime = Time.now
			mactivity.iinstance = instance.to_s.empty? ? "" : instance
			mactivity.imapplication = application.to_s.empty? ? "" : application
			mactivity.accesshistory_id = accesshistory
			mactivity.save
		end
  end

  def add_activity(accessid, path,action,platform,instance, result,resource)
    if !accessid.to_s.empty?
      mactivity = Mactivity.new()
      mactivity.maction = action
      mactivity.mdatetime = Time.now
      mactivity.iinstance = instance.to_s.empty? ? "" : instance
      mactivity.imapplication = platform.to_s.empty? ? "" : platform
      mactivity.accesshistory_id = accessid
      mactivity.path = path
      mactivity.result = result
      mactivity.resource = resource
      mactivity.save
    end
  end



	def show_datetime_log(time, timezone)
	    time_value = 0
	    if(!timezone.nil?)
	      if(timezone.include? "+")
	        time_value = time.to_i + timezone.split("+")[1].to_i*3600
	      elsif (timezone.include? "-")
	        time_value = time.to_i - timezone.split("+")[1].to_i*3600
	      end
	    else
	      time_value = time.to_i
	    end
	    temp = Time.now.to_i - time.to_i
	    if(temp < 3600)
	      if(temp < 0)
	        temp = 0
	      end
	      time_show = Time.at(time_value).strftime("%I:%M %P") + " (#{temp/60} minutes ago)"
	    elsif(temp < 43200)
	      time_show = Time.at(time_value).strftime("%I:%M %P") + " (#{temp/3600} hours ago)"
	    elsif(temp < 86400)
	      time_show = Time.at(time_value).strftime("%b %d") + " (#{temp/3600} hours ago)"
	    else
	      if(temp < 2592000)
	        time_show = Time.at(time_value).strftime("%b %d") + " (#{temp/86400} days ago)"
	      elsif(temp < 31536000)
	        time_show = Time.at(time_value).strftime("%b %d") + " (#{temp/2592000} months ago)"
	      else
	        time_show = Time.at(time_value).strftime("%Y %b") + " (#{temp/2592000} years ago)"
	      end
	    end  
	    return time_show
	end
end

public
  def create_log_history(user, request)
    log_activity = Log_activity.new
    log_activity.create_accesshistory(user, request)
  end

  def create_log_activity(session, action, application = "", instance = "")
    log_activity = Log_activity.new
    accesshistory = session[:accesshistory]
    log_activity.create_mactivity(accesshistory, action, application, instance)
  end

  def add_activity(accessid, path,action,platform = "",instance = "",result,resource)
    objActivity = Log_activity.new
    objActivity.add_activity(accessid,path,action,platform,instance,result,resource)
  end


  def create_log_activity_api(accesshistory, action, app_root)
    instance = Instance.where("app_root = '#{app_root}'").first
    mapp = instance.nil? ? "" : instance.product.mapplication.id.to_s + "_" + instance.product.mapplication.name
    minstance = instance.nil? ? "" : instance.id.to_s + "_" + instance.name
    log_activity = Log_activity.new
    log_activity.create_mactivity(accesshistory, action, mapp, minstance)
  end