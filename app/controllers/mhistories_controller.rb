class MhistoriesController < ApplicationController
    before_action :authorize
    def index 
        search = params[:search] || ''
        sql = Mhistory.where("concat(srowid, ' ', stable) LIKE ? OR owner LIKE ? OR fvalue LIKE ? OR tvalue LIKE ?", "%#{search}%", "%#{search}%", "%#{search}%", "%#{search}%")
        @allmhistories = pagination_limit_offset(sql, 10)
    end 
end