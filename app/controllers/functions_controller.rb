class FunctionsController < ApplicationController
    before_action :authorize
    #Hai 7/4/2023
    def index
        search = params[:search] || ''
        sql = Function.where("sname LIKE ? OR scode LIKE ? OR status LIKE ?", "%#{search}%", "%#{search}%", "%#{search}%")
        @functions = pagination_limit_offset(sql, 10)
    end
    
      def update
        id = params[:function_id]
        pName = params[:function_sname]
        pScode = params[:function_scode]
        pStatus = params[:sel_status]
        msg = lib_translate("Not_Success")
    
        if id == ""
          function = Function.new
          function.id = id
          function.sname = pName
          function.scode = pScode
          function.status = pStatus
          function.save
          msg = lib_translate("Create_successfully")
        else
          oFunction = Function.where("id = #{id}").first
          msg = lib_translate("Not_Success")
          if !oFunction.nil?
            oFunction.update({sname: pName, scode: pScode, status: pStatus})
            
            change_column_value = oFunction.previous_changes
            change_column_name = oFunction.previous_changes.keys
            if change_column_name  != ""
                for changed_column in change_column_name do 
                    if changed_column != "updated_at"
                      fvalue = change_column_value[changed_column][0]
                      tvalue = change_column_value[changed_column][1]            
                      log_history(Function, changed_column, fvalue ,tvalue, @current_user.email)
                    end
                end  
            end  
            msg = lib_translate("Update_successfully")
          end
        end
        redirect_to functions_index_path(lang: session[:lang],page: session[:page], per_page: session[:per_page], search: session[:search]), notice: msg
      end
    
      def del
        function_id = params[:id]
        function = Function.where("id = #{function_id}").first
        msg = lib_translate("Not_Success")
        if !function.nil?
          function.destroy
          log_history(Function, "Xóa", function.sname , "Đã xóa khỏi hệ thống", @current_user.email)
          msg = lib_translate("Delete_successfully")
        end 
        redirect_to functions_index_path(lang: session[:lang],page: session[:page], per_page: session[:per_page], search: session[:search]), notice: msg
      end
end