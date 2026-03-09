class AcchistsController < ApplicationController
    def index
        search = params[:search] || ''
        sql = Acchist.joins(:user).where("DATE_FORMAT(DATE_ADD(dlogin, INTERVAL 7 HOUR), '%d/%m/%Y') LIKE ? OR DATE_FORMAT(DATE_ADD(dlogout, INTERVAL 7 HOUR), '%d/%m/%Y') LIKE ? OR concat(last_name,' ',first_name) LIKE ? OR sid = ? OR location LIKE ? OR browser LIKE ? OR device LIKE ? OR os LIKE ? ", "%#{search}%", "%#{search}%", "%#{search}%", "#{search}", "%#{search}%", "%#{search}%", "%#{search}%", "%#{search}%")
        @acchists = pagination_limit_offset(sql, 10)
    end
end
    