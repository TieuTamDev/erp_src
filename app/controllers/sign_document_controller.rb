class SignDocumentController < ApplicationController
  skip_before_action :verify_authenticity_token, only: :load_signdoc
  before_action :check_folder
  include SigndocConcern
  def index

  end

  def update_sign
      success = false
      signdoc_id = params[:signdoc_id]
      s_signs = params[:signs]
      signs = JSON.parse(s_signs)
      signed_by = session[:user_id_login]
      datas = []
      msg = ""
      begin
        signs.each do|sign|
          Sign.create({
            signdoc_id:signdoc_id,
            nopage:sign["nopage"],
            signatureid:sign["signatureid"],
            signature_path:sign["signature_path"],
            swidth:sign["swidth"],
            sheight:sign["sheight"],
            px:sign["px"],
            py:sign["py"],
            signed_by:signed_by,
            signer_fn:session[:user_fullname]
          })
        end
        success = true
      rescue => exception
        position = exception.backtrace.to_json.html_safe.gsub("\`","")
        message = exception.message.gsub("\`","")
        msg = "#{message} #{position}"
        success = false
      end
      respond_to do |format|
        format.js { render js: "onSignUpdate(#{success.to_json.html_safe},#{signdoc_id},'#{msg}'); onSignDone(#{success.to_json.html_safe});"}
      end
  end

  def check_sign_exits
    signdoc_id = params[:signdoc_id]
    signed_by = session[:user_id_login]
    sigdoc = Signdoc.find_by(id: signdoc_id)
    b_exits = false
    if !sigdoc.nil?
      sign = Sign.where(signdoc_id: signdoc_id,signed_by:signed_by).first
      b_exits = !sign.nil?
    end
    respond_to do |format| 
      format.js { render js: "#{b_exits}"}
    end
  end

  # load template: sign + data
  def load_signdoc
    signdoc_id = params[:signdoc_id]
    data = {}
    begin
      signdoc =  Signdoc.where(id: signdoc_id).first
      signs = []
      if !signdoc.nil?
        template = signdoc.tmp_file
        signs = Sign.where(signdoc_id: signdoc.id)
      else
        raise "Not found"
      end
      template = "proposal_creation.html.erb"
      pdf = generate_pdf_file(template,signs,signdoc_id,data)
      send_data pdf,  type: 'application/pdf',
                      disposition: 'attachment',
                      filename:"pdf_#{Time.now.strftime("%d%m%Y")}.pdf"
    rescue => exception
      position = exception.backtrace
      message = exception.message
      respond_to do |format|
        format.js   { render json: { error: exception.message,position: position }, status: 500 }
      end
    end
  end

end