class TbarchivelevelsController < ApplicationController
  before_action :authorize
    # Huy review 03/03/2023
    
  def index

    search = params[:search] || ''
    sql = Tbarchivelevel.where("name LIKE ? OR scode LIKE ? OR status LIKE ?", "%#{search}%", "%#{search}%", "%#{search}%")
    @tbarchivelevels = pagination_limit_offset(sql, 10)
    @tbarchivelevel = Tbarchivelevel.new

  end
  def update
    id = params[:tbarchivelevel_id]
    name = params[:tbarchivelevel_name_add].squish
    strScode = params[:tbarchivelevel_scode_add].squish
    strStatus = params[:tbarchivelevel_status_add].squish
    msg = lib_translate("Not_Success")
    if id == ''
        addTbarchivelevel = Tbarchivelevel.new
        addTbarchivelevel.name = name
        addTbarchivelevel.scode = strScode
        addTbarchivelevel.status = strStatus
        addTbarchivelevel.save
        msg = lib_translate("Create_successfully")
    else
        addTbarchivelevel = Tbarchivelevel.where(id: id).first
        if !addTbarchivelevel.nil?
          addTbarchivelevel.update(
              {
              name: name,
              scode: strScode,
              status: strStatus
              }
          )

          change_column_value = addTbarchivelevel.previous_changes
          change_column_name = addTbarchivelevel.previous_changes.keys
          if change_column_name  != ""
            for changed_column in change_column_name do
                if changed_column != "updated_at"
                  fvalue = change_column_value[changed_column][0]
                  tvalue = change_column_value[changed_column][1]
                  log_history(Tbarchivelevel, changed_column, fvalue ,tvalue, @current_user.email)
                end
              end
            end
            msg = lib_translate("Update_successfully")
        end
    end
    redirect_to tbarchivelevels_index_path(lang: session[:lang],page: session[:page], per_page: session[:per_page], search: session[:search]), notice: msg
  end

  def del
    id = params[:id]
    msg = lib_translate("Not_Success")
    delTbarchivelevel = Tbarchivelevel.where(id: id).first
    if !delTbarchivelevel.nil?
      delTbarchivelevel.destroy
      log_history(Tbarchivelevel, "Xóa", delTbarchivelevel.name , "Đã xóa khỏi hệ thống", @current_user.email)
      msg = lib_translate("Delete_successfully")
    end
    redirect_to tbarchivelevels_index_path(lang: session[:lang],page: session[:page], per_page: session[:per_page], search: session[:search]), notice: msg
  end
end
