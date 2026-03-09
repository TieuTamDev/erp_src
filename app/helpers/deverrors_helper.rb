module DeverrorsHelper
  def is_access_dev_log(property,permission)
    return false if @aPermissionUser.blank?
    checkPermision = false
    @aPermissionUser.each do |per|
        if (per["resource"] == property && permission == per["permission"]) || (per["resource"] == property && "ADM" == per["permission"])
          checkPermision = true
          break
        end
    end
    return checkPermision
  end

end