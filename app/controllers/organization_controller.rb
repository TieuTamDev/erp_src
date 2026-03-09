class OrganizationController < ApplicationController
    before_action :authorize
    # Huy review 03/03/2023
    def index
        @organization =Organization.new
        search = params[:search] || ''
        sql = Organization.where("name LIKE ? OR scode LIKE ? OR status LIKE ?", "%#{search}%", "%#{search}%", "%#{search}%")
        @organizations = pagination_limit_offset(sql, 10)

    end

    def update
        id = params[:organization_id]
        name = params[:organization_name_add].squish
        strScode = params[:organization_scode_add].squish
        strStatus = params[:organization_status_add].squish
        msg = lib_translate("Not_Success")
        if id == ''
            oOrganization = Organization.new
            oOrganization.name = name
            oOrganization.scode = strScode
            oOrganization.status = strStatus
            oOrganization.save
            msg = lib_translate("Create_successfully")

        else
            oOrganization = Organization.where(id: id).first
            if !oOrganization.nil?
                oOrganization.update(
                    {
                    name: name,
                    scode: strScode,
                    status: strStatus
                    }
                )

                change_column_value = oOrganization.previous_changes
                change_column_name = oOrganization.previous_changes.keys
                if change_column_name  != ""
                    for changed_column in change_column_name do
                        if changed_column != "updated_at"
                            fvalue = change_column_value[changed_column][0]
                            tvalue = change_column_value[changed_column][1]
                            log_history(Organization, changed_column, fvalue ,tvalue, @current_user.email)
                        end
                    end
                end
                msg = lib_translate("Update_successfully")
            end
        end
        redirect_to organization_index_path(lang: session[:lang],page: session[:page], per_page: session[:per_page], search: session[:search]), notice: msg
    end

    def del
        id = params[:id]
        msg = lib_translate("Not_Success")
        delOrganization = Organization.where(id: id).first
        if !delOrganization.nil?
            delOrganization.destroy
            log_history(Organization, "Xóa", delOrganization.name , "Đã xóa khỏi hệ thống", @current_user.email)
            msg = lib_translate("Delete_successfully")
        end
        redirect_to organization_index_path(lang: session[:lang],page: session[:page], per_page: session[:per_page], search: session[:search]), notice: msg
    end
end
