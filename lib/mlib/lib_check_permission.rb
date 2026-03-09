class Check_permission
	def check_type(userId,userType, path, type)
		if(userType == MConst::CLIENT_ADMIN_SYSTEM)
			# Login by admin
			return true
		else
			if(!userId.to_s.empty?)
				# Login by user 
				user = User.find(userId)
				if(!user.nil?)
					user.roles.each do |role|						
						if(accessright_accept(role, path, type) == true)
							return true
						end
					end
					return false
				else
					return false
				end
			else
				# Login by client
				# Find the root user
				oRoot = Client.where("clientcreator_id is NULL").first
				role = oRoot.roles.where("name = '#{userType}'").first
				return accessright_accept(role, path, type)
			end
		end
	end

	def accessright_accept(role, path, type)
		if(!role.nil? && role.status == MConst::STATE_RUNNING)
			role.permissions.each do |permission|
				if (permission.path.upcase == path.upcase && permission.status == MConst::STATE_RUNNING)
					permission.accessrights.each do |accessright|
						if(accessright.name.upcase == type.upcase && accessright.value == true)
							return true
						end
					end
				end
			end
			return false
		else
			return false
		end
	end
end

public

'''
		userType : ADMIN SYSTEM/BUSINESS/RESELLER/USER
		userId : User Id
		path   : Path
		type   :
'''

def check_permission_type(userId,userType, path, type)
	check_permission = Check_permission.new()
	check_permission.check_type(userId,userType, path, type)
end

def check_permission(userId,userType,path,accessType)
	return check_permission_type(userId,userType,path,accessType)
end

def does_accessright(user_id,is_client,feature,access_type,app_name)
	if !is_client.nil? && is_client == MConst::CLIENT_ADMIN_SYSTEM
		return true
	end
	oUser = User.where("id = #{user_id}").first
	if oUser.nil?
		return false
	end
	oApp = Mapplication.where("name = '#{app_name}'").first
	if oApp.nil?
		return false
	end

	if feature.nil?
		return false
	end

	oUser.groups.each do |oGroup|
		oGroup.roles.each do |oRole|
			oRole.permissions("where mapplication_id = #{oApp.id}").each do |oPermission|
				if (!oPermission.path.nil? && oPermission.path.upcase == feature.upcase && oPermission.mapplication_id.to_s == oApp.id.to_s)
					oPermission.accessrights.each do |oAR|
						if((oAR.name.upcase == access_type.upcase && oAR.value == true) || (oAR.name.upcase == "ADMIN" && oAR.value == true))
							return true
						end

						if access_type.upcase == "VIEW" || access_type.upcase == "READ"
							if oAR.value == true
								return true
							end
						end
					end
				end
			end
		end
	end
	return false


end


def does_accessright_children(user_id,is_client,parent_navi,access_type,app_name)


	if parent_navi.subordinates.count == 0
		return false
	else
		parent_navi.subordinates.each do |oNavi|
			if (does_accessright(user_id,is_client, oNavi.feature,access_type,app_name))
				return true
			end
		end
        return false
	end

end



def does_application_accessright(user_id, is_client,app_name)
	if !is_client.nil? && is_client == MConst::CLIENT_ADMIN_SYSTEM
		return true
	end
	oUser = User.where("id = #{user_id}").first
	if oUser.nil?
		return false
	end
	oApp = Mapplication.where("name = '#{app_name}'").first
	if oApp.nil?
		return false
	end

	oUser.groups.each do |oGroup|
		oGroup.roles.each do |oRole|
			oRole.permissions.where("mapplication_id = #{oApp.id}").each do |oPermission|
				oPermission.accessrights.each do |oAR|
					if(oAR.value == true)
						return true
					end
				end
		end
	end
	end
	return false
end


def valid_user_time(user_name)
	ihour = DateTime.now.strftime("%H").to_i
	iminute = DateTime.now.strftime("%M").to_i
	oTimeaccess = Timeaccess.where("user_name = '#{user_name}'").first
	if oTimeaccess.nil?
		return true
	end
	userFHour = oTimeaccess.tfrom.strftime("%H").to_i
	userFMinute = oTimeaccess.tfrom.strftime("%M").to_i

	userTHour = oTimeaccess.tto.strftime("%H").to_i
	userTMinute = oTimeaccess.tto.strftime("%M").to_i

	if ihour > userFHour &&  ihour < userTHour
		return true
	end

	if userFHour != userTHour
		if ihour == userFHour && iminute >= userFMinute
			return true
		end

		if ihour == userTHour && iminute <= userTMinute
			return true
		end
	else
		if  iminute >= userFMinute && iminute <= userTMinute
			return true
		end

	end



	return  false

end

def valid_user_ip(user_name,ip)
	oIpaccess = Ipaccess.where("username = '#{user_name}'").first
	if !oIpaccess.nil?
		oIpaccess1 = Ipaccess.where("username = '#{user_name}' AND ip = '#{ip}'").first
		if !oIpaccess1.nil?
			return true
		end
		return false
	end
	return true
end