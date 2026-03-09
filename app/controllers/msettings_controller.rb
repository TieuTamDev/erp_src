class MsettingsController < ApplicationController
  before_action :authorize
  before_action :set_msetting, only: [:edit, :update, :destroy]

  def index
    @msettings = Msetting.order(created_at: :desc)
  end

  def new
    @msetting = Msetting.new
    respond_to do |format|
      format.js
    end
  end

  def edit
    respond_to do |format|
      format.js
    end
  end

  def create
    @msetting = Msetting.new(msetting_params)
    
    respond_to do |format|
      if @msetting.save
        flash[:notice] = "Lưu thành công"
        format.js { render js: "window.location = '#{msettings_path(lang: session[:lang])}'" }
      else
        flash.now[:alert] = "Lưu không thành công"
        format.js { render :new }
      end
    end
  end

  def update
    respond_to do |format|
      if @msetting.update(msetting_params)
        flash.now[:notice] = "Cập nhật thành công"
        format.js { render js: "window.location = '#{msettings_path(lang: session[:lang])}'" }
      else
        flash.now[:alert] = "Lưu không thành công"
        format.js { render :new }
      end
    end
  end

  def destroy
    @msetting = Msetting.find(params[:id])
    @msetting.destroy
    @msettings = Msetting.order(created_at: :desc)
    respond_to do |format|
      flash.now[:notice] = "Xóa thành công"
      format.html { redirect_to msettings_path }
    end
  end

  def get_settings
    page = params[:page].to_i
    per_page = params[:per_page].to_i
    search = params[:search]&.strip || ""
    order_column = params[:order_column] || "created_at"
    order_dir = params[:order_dir] || "desc"

    msettings = Msetting.all
    if search.present?
      stype_keys = Msetting::STYPES.select { |_k, v| v.downcase.include?(search.downcase) }.keys
      msettings = msettings.where("stype IN (:stype_keys) OR svalue LIKE :q OR name LIKE :q", stype_keys: stype_keys, q: "%#{search}%")
    end
    total_count = msettings.count
    msettings = msettings.order("#{order_column} #{order_dir}").offset((page - 1) * per_page).limit(per_page)
    msettings = msettings.map do |ms|
      # ms.stype = Msetting::STYPES[ms.stype]
      # ms.valid_from = ms.valid_from.strftime("%d/%m/%Y")
      # ms.valid_to = ms.valid_to.strftime("%d/%m/%Y")
      # ms.attributes.merge(button: )
      {
        id: ms.id,
        name: ms.name,
        scode: ms.scode,
        stype: Msetting::STYPES[ms.stype],
        svalue: ms.svalue,
        valid_from: ms.valid_from&.strftime("%d/%m/%Y"),
        valid_to: ms.valid_to&.strftime("%d/%m/%Y"),
        button: render_buttons(ms.as_json)
      }
    end
    render json: {
      draw: params[:draw],
      recordsTotal: total_count,
      recordsFiltered: total_count,
      data: msettings,
    }
  end

  private

  def set_msetting
    @msetting = Msetting.find(params[:id])
  end

  def msetting_params
    params.require(:msetting).permit(:stype, :name, :scode, :svalue, :valid_from, :valid_to)
  end

  def render_buttons(setting)
    setting[:button] = ""
    # setting[:button] += "<button class='btn btn-sm btn-outline-primary btn-edit-msetting me-3' data-edit-url='#{@ERP_PATH}msettings/#{setting["id"]}/edit'>Sửa</button>"
    if is_access(session["user_id"], "MSETTINGS", "EDIT")
    setting[:button] += "<a class='btn btn-sm btn-outline-primary me-3' data-remote='true' href='#{@ERP_PATH}msettings/#{setting["id"]}/edit'>Sửa</a>"
    end
    if is_access(session["user_id"], "MSETTINGS", "DEL")
      setting[:button] += "<a data-confirm='Bạn có chắc muốn xoá #{setting["name"]}?' class='btn btn-outline-danger btn-sm' rel='nofollow' data-method='delete' href='#{@ERP_PATH}msettings/#{setting["id"]}'>Xoá</a>"
    end
  end
end