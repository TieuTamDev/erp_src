class MaintainController < ApplicationController
    before_action :authorize
    # Huy review 03/03/2023
    def index
        @maintains = Maintenance.new
        @Hismaintenances = Hismaintenance.new
        @Maintenance = Maintenance.all 
        oMaintains = Maintenance.where(app: Hismaintenance&.last&.app).last
        
        @period = ""
        @opentiming = ""
        @oips = ""
        @status = ""
        if !oMaintains.nil?
            @period = oMaintains.period
            @opentiming = oMaintains.opentiming
            @oips = oMaintains.oips
            @status = oMaintains.status
            @app = Hismaintenance.last.app
        end
        search = params[:search] || ''
        sql = Hismaintenance.where("app LIKE ? OR period LIKE ? OR oips LIKE ? OR opentiming LIKE ?", "%#{search}%", "%#{search}%", "%#{search}%", "%#{search}%")
        @Hismaintenances = pagination_limit_offset(sql, 10)
    end

    def update
        maintenanceApp = params[:maintenanceApp]
        maintenance_period = params[:maintenance_period]
        maintenance_openning = params[:maintenance_openning]
        maintenance_ips = params[:maintenance_ips]
        maintenance_status = params[:maintenance_status_add]
        msg = lib_translate("Not_Success")
        oMaintenance = Maintenance.where(app: maintenanceApp).first
        
        if oMaintenance.nil?
            oMaintenance = Maintenance.new 
            oMaintenance.app = maintenanceApp
            oMaintenance.period = maintenance_period
            oMaintenance.oips = maintenance_ips
            oMaintenance.opentiming = maintenance_openning
            oMaintenance.status = maintenance_status
            oMaintenance.save 

            oHismaintenances = Hismaintenance.new 
            oHismaintenances.app = maintenanceApp
            oHismaintenances.period = maintenance_period
            oHismaintenances.oips = maintenance_ips
            oHismaintenances.opentiming = maintenance_openning 
            oHismaintenances.save 
            msg = lib_translate("Create_successfully")
        else 
            if !oMaintenance.nil?
                oMaintenance.update({ period: maintenance_period, oips: maintenance_ips, opentiming: maintenance_openning, status: maintenance_status})
                #Save updated  history (Đạt)
                    change_column_value = oMaintenance.previous_changes
                    change_column_name = oMaintenance.previous_changes.keys
                    if change_column_name  != ""
                        for changed_column in change_column_name do 
                            if changed_column != "updated_at"
                                fvalue = change_column_value[changed_column][0]
                                tvalue = change_column_value[changed_column][1]
                            log_history(Maintenance, changed_column, fvalue ,tvalue, @current_user.email)                        
                            end
                        end  
                    end   
                oHismaintenances = Hismaintenance.new 
                oHismaintenances.app = maintenanceApp
                oHismaintenances.period = maintenance_period
                oHismaintenances.oips = maintenance_ips
                oHismaintenances.opentiming = maintenance_openning 
                oHismaintenances.save 
                msg = lib_translate("Update_successfully")
            end
            

        end
        redirect_to maintain_index_path(lang: session[:lang],page: session[:page], per_page: session[:per_page], search: session[:search]), notice: msg
    end

end