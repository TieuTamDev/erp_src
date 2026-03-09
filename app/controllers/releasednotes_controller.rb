class ReleasednotesController < ApplicationController
    before_action :authorize    
# Thai 02/06/2023
    def index 
        @releasednotes = Releasednote.all.order("dtrelease DESC, created_at DESC")
        @releasednote = Releasednote.new   
    end

    def update
        id = params[:id]
        name = params[:name]
        authors = params[:authors]
        dtrelease = params[:dtrelease]
        contents = params[:contents]
        msg = lib_translate("Not_Success")

        if id != ''
            released_note = Releasednote.where(id: id).first
            if  !released_note.nil?
                released_note.update({
                    name: name,
                    authors: authors,
                    dtrelease: dtrelease,
                    contents: contents
                })
                msg = lib_translate("Update_successfully")
            end
        else
            released_note = Releasednote.create({
                name: name,
                authors: authors,
                dtrelease: dtrelease,
                contents: contents
            })
            msg = lib_translate("Create_successfully")
        end
        redirect_to releasednotes_index_path(lang: session[:lang],page: session[:page], per_page: session[:per_page], search: session[:search]), notice: msg
    end      
    def del
        id = params[:id]
        released_note = Releasednote.where(id: id).first
        if !released_note.nil?
            released_note.destroy
        end
    end
end
  
 
