class DocumentsController < ApplicationController
    before_action :authorize
    def index
        search = params[:search] || ''
        sql = Mydoc.where("app LIKE ?", "%#{search}%")
        @mydocs = pagination_limit_offset(sql, 10)
    end

    def update
        id = params[:id]
        txt_app = params[:app]&.strip
        txt_meta = params[:meta]
        txt_contents = params[:contents]
        full_name = ""
        user = User.select("CONCAT(last_name, ' ', first_name) AS full_name").where(id: session[:user_id]).first
        if user
            full_name = user.full_name
        end
        msg = lib_translate('Not_success')
        if !id.nil? && id != ""
            update_mydoc = Mydoc.where(id: id).first
            old_content = update_mydoc&.content
            old_meta = update_mydoc&.meta
            if !update_mydoc.nil?
                update_mydoc.update({
                    app: txt_app,
                    meta: txt_meta,
                    content: txt_contents,
                })
                if txt_meta != old_meta
                    new_mydochis = Mydochi.create({
                        mydoc_id: id,
                        fvalue: old_meta,
                        tovalue: txt_meta,
                        sfield: "META",
                        owner: full_name
                    })
                elsif txt_contents != old_content
                    new_mydochis = Mydochi.create({
                        mydoc_id: id,
                        fvalue: old_content,
                        tovalue: txt_contents,
                        sfield: "CONTENTS",
                        owner: full_name
                    })
                end
                msg = lib_translate('Success')
            end
        else
            new_mydoc = Mydoc.create({
                app: txt_app,
                meta: txt_meta,
                content: txt_contents,
            })
            msg = lib_translate('Success')
        end
        redirect_to documents_index_path(lang: session[:lang],page: session[:page], per_page: session[:per_page], search: session[:search]), notice: msg

    end

    def del
        id = params[:id]
        msg = lib_translate('Not_success')
        if !id.nil? && id != ""
            del_mydoc = Mydoc.where(id: id).first
            if !del_mydoc.nil?
                del_mydoc.destroy
                msg = lib_translate('Success')
            end
        end
        redirect_to documents_index_path(lang: session[:lang],page: session[:page], per_page: session[:per_page], search: session[:search]), notice: msg
    end

    def history
        id = params[:iddoc]
        session[:iddoc] = id
        search = params[:search] || ''
        @get_app = ""
        @get_app = Mydoc.where(id: id).first&.app
        sql=[]
        if !id.nil? && id != ""
            sql = Mydochi.where(mydoc_id: id).where("sfield LIKE ?", "%#{search}%")
        end
        @mydochis = pagination_limit_offset(sql, 10)
    end

    def erp
        oContent = Mydoc.where(app: "ERP").first
        if !oContent.nil?
            @oContent = oContent
        end
    end

    def check_app
        app = params[:check_app]&.strip
        app_exists = Mydoc.exists?(app: app.to_s)
    
        @exists = app_exists
        respond_to do |format|
            format.js # Đây là format cho template JS
        end
    end
end