class HoltypesController < ApplicationController
    before_action :set_holtype, only: [:edit, :update, :destroy]
    
    def index
        @holtypes = Holtype.all
        @holtype = Holtype.new
    end
  
    def new
        @holtype = Holtype.new
        @holtemps = Holtemp.all

        render partial: 'form', locals: { holtype: @holtype }
    end
  
    def edit
        @holtemps = Holtemp.all
        render partial: 'form', locals: { holtype: @holtype }
    end
    def create
        @holtype = Holtype.new(holtype_params)
        @holtype.valid? # để gọi before_validation và sinh code từ name

        if Holtype.exists?(code: @holtype.code)
            @holtemps = Holtemp.all
            redirect_to holtypes_path, notice: "Loại phép với mã '#{@holtype.code}' đã tồn tại."
        elsif @holtype.save
            redirect_to holtypes_path, notice: 'Thêm loại phép thành công.'
        else
            @holtemps = Holtemp.all
            render partial: 'form', locals: { holtype: @holtype }
        end
    end


    def update
        holtype_params_filtered = holtype_params.except(:code)
        @holtype.assign_attributes(holtype_params_filtered)
        @holtype.valid?
        if Holtype.where(code: @holtype.code).where.not(id: @holtype.id).exists?
            @holtemps = Holtemp.all
            redirect_to holtypes_path, notice: "Loại phép với mã '#{@holtype.code}' đã tồn tại."
        elsif @holtype.update(holtype_params_filtered)
            redirect_to holtypes_path, notice: 'Cập nhật loại phép thành công.'
        else
            @holtemps = Holtemp.all
            render partial: 'form', locals: { holtype: @holtype }
        end
    end



  
    def destroy
        @holtype.destroy
        redirect_to holtypes_path, notice: 'Xóa thành công.'
    end

    def details_holtype
        @holtype = Holtypedetail.find_by(holtype_id: params[:id_holtype])
        @holtype_id = params[:id_holtype]
    end
    
    def save_holtype
        holtype_id = params[:holtype_id]
        imax = params[:imax].to_i

        holtypedetail = Holtypedetail.find_or_initialize_by(holtype_id: holtype_id)
        holtypedetail.imax = imax

        if holtypedetail.save
            render json: { status: "ok" }
        else
            render json: { status: "error" }, status: 422
        end
    end




    private
  
    def set_holtype
        @holtype = Holtype.find(params[:id])
    end
  
    def holtype_params
        params.require(:holtype).permit(:name, :code, :note, :status, :sholtemp)
    end
    
    def normalize_code(code)
        code.to_s.strip.upcase.squeeze(" ")
    end

end
  