class OperstreamController < ApplicationController
    before_action :authorize

    def index
        @functions = Function.all
        @organizations = []
        @streams = []

        @organizations_update = Organization.all
        @streams_update = Stream.all

        idFunction = params[:function_id]
        if idFunction.nil?
            @operstreams = Operstream.all
        else
            @operstreams = Operstream.where(function_id: idFunction)
        end
    end

    def update_operstream
        id = params[:operstream_id]
        idFunction = params[:function_id]
        idOrganization = params[:organization_id]
        idStream = params[:stream_id]
        valid_from = params[:valid_from]
        valid_to = params[:valid_to]
        msg = lib_translate("Not_Success")
        if !id.nil? && id != ""
            uOperstream = Operstream.where(id: id).first
            if !uOperstream.nil?
                uOperstream.update({
                    function_id: idFunction,
                    organization_id: idOrganization,
                    stream_id:  idStream,
                    valid_from:  valid_from,
                    valid_to:  valid_to
                })
                msg = lib_translate('Success')
            end
        else
            Operstream.create({
                function_id: idFunction,
                organization_id: idOrganization,
                stream_id:  idStream,
                valid_from:  valid_from,
                valid_to:  valid_to
            })
            msg = lib_translate('Success')
        end
        session[:current_function] = idFunction
        redirect_to operstream_index_path(lang: session[:lang]), notice: msg
    end
    def delete
        id = params[:id]
        msg = lib_translate('Not_success')
        if !id.nil?
            oOperstream = Operstream.where(id: id).first
            if !oOperstream.nil?
                oOperstream.destroy
                msg = lib_translate('Success')
            end
        end
        redirect_to operstream_index_path(lang: session[:lang]), notice: msg
    end
    def organizations
        if !params[:function_id].nil?
            @organizations = Organization.all
        else
            @organizations = []
        end
        render json: @organizations
    end
    
    def streams
        if !params[:function_id].nil?
            @streams = Stream.all
        else
            @streams = []
        end
        render json: @streams
    end

    def get_operlist
        function_id = params[:function_id]
        operstream_id = params[:operstream_id]
        @oOperstream = ""
        @oOperstreamUpdate = ""    
        @action = ""
        

        if !function_id.nil? && function_id != ""
            @oOperstream = Operstream.where(function_id: function_id)    
            @action = "ADD"            
        else
            @oOperstream = Operstream.all    
        end

        if !operstream_id.nil? && operstream_id != ""
            @oOperstreamUpdate = Operstream.where(id: operstream_id).first
            @action = "UPDATE"           
        end
    end
    def check_exists
        function_id = params[:function_id]
        organization_id = params[:organization_id]
        stream_id = params[:stream_id]
        valid_to = params[:valid_to]
        msg = lib_translate("Not_Success")
        exists = Operstream.where(function_id: function_id,organization_id: organization_id, stream_id: stream_id).where("DATE_FORMAT(DATE_ADD(valid_to, INTERVAL 7 HOUR), '%d/%m/%Y') = ?",valid_to).exists?
      
        render json: { exists: exists } 
    end
    def get_all_functions
        datas_function = Function.select("id,sname")
        respond_to do |format|
            format.js { render js: "reloadFunction(#{datas_function.to_json.html_safe})"}
        end
    end
    def get_all_organizations
        datas_organization = Organization.select("id,name")
        respond_to do |format|
            format.js { render js: "reloadOrganization(#{datas_organization.to_json.html_safe})"}
        end
    end
    def get_all_streams
        datas_stream = Stream.select("id,name")
        respond_to do |format|
            format.js { render js: "reloadStream(#{datas_stream.to_json.html_safe})"}
        end
    end
end