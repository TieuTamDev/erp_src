class Role_function
	def roles_client(client_id)
		client = Client.find(client_id)
		if(client.nil?)
			return []
		else
			if(client.mtype == MConst::CLIENT_ADMIN_SYSTEM)
				return Role.where("client_id = #{client_id}").where.not(:id => roles_system().map(&:id))
			else
				return Role.joins(:client).where("client_id = #{client_id} and clients.clientcreator_id is not null").where.not(:id => roles_system().map(&:id))
			end
		end
	end

	def roles_system()
		query = "name = '#{MConst::CLIENT_ADMIN_SYSTEM}' or name = '#{MConst::CLIENT_BUSINESS}' or name = '#{MConst::CLIENT_RESELLER}'"
		return Role.joins(:client).where("clients.clientcreator_id is null").where(query)
	end

	def check_role(role_name, client_id)
		client = Client.find(client_id)
		role = Role.joins(:client).where("client_id = #{client_id} and clients.clientcreator_id is null").where("name = '#{role_name}'").first
		if(!client.nil?)
			if(client.clientcreator_id.nil? && !role.nil? && (role_name.upcase == (MConst::CLIENT_ADMIN_SYSTEM).upcase || role_name.upcase == (MConst::CLIENT_BUSINESS).upcase || role_name.upcase == (MConst::CLIENT_RESELLER).upcase))
				return true
			else
				return false
			end
		else
			return false
		end
	end
end

public
def get_roles_client(client_id)
	role_function = Role_function.new
	return role_function.roles_client(client_id)
end

def get_roles_system()
	role_function = Role_function.new
	return role_function.roles_system()
end

def is_reserved_role(role_name, client_id)
	role_function = Role_function.new
	return role_function.check_role(role_name, client_id)
end