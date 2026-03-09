  class HoltempsController < ApplicationController
      before_action :authorize
      before_action :set_holtemp, only: [:edit, :update, :destroy]
    
      def index
        @holtemps = Holtemp.all
        @holtemp = Holtemp.new

      end
    
      def new
        @holtemp = Holtemp.new
        user_id = session[:user_id]
        org_ids = Uorg.where(user_id: user_id).pluck(:organization_id)
        @departments = Department.where(organization_id: org_ids).index_by(&:id)
      
        render partial: 'form', locals: { holtemp: @holtemp, departments: @departments }
      end
      
      def create
        # Tìm bản ghi đã tồn tại
        existing = Holtemp.find_by(title: holtemp_params[:title], dept: holtemp_params[:dept])

        if existing
          # Nếu tồn tại, cập nhật valid_to về ngày hiện tại
          existing.update(valid_to: holtemp_params[:valid_to])
          respond_to do |format|
            format.html { redirect_to holtemps_path, notice: 'Biểu mẫu phép đã tồn tại. Đã cập nhật ngày kết thúc.' }
            format.js { render json: existing, status: :ok }
          end
        else
          @holtemp = Holtemp.new(holtemp_params)
          if @holtemp.save
            respond_to do |format|
              format.html { redirect_to holtemps_path, notice: 'Biểu mẫu phép đã được thêm.' }
              format.js { render json: @holtemp, status: :created }
            end
          else
            render :new
          end
        end

      end
    
      def edit
        @holtemp = Holtemp.find(params[:id])
        user_id = session[:user_id]
        org_ids = Uorg.where(user_id: user_id).pluck(:organization_id)
        @departments = Department.where(organization_id: org_ids).index_by(&:id)
      
        render partial: 'form', locals: { holtemp: @holtemp, departments: @departments }
      end
      
        
    
      def update
        if @holtemp.update(holtemp_params)
          respond_to do |format|
            format.html { redirect_to holtemps_path, notice: 'Biểu mẫu phép đã được cập nhật.' }
            format.js { render json: @holtemp, status: :ok }
          end
        else
          render :edit
        end
      end
    
      def destroy
        @holtemp.destroy
        redirect_to holtemps_path, notice: 'Xóa biểu mẫu phép thành công'
      end
    
      private
    
      def set_holtemp
        @holtemp = Holtemp.find(params[:id])
      end
    
      def holtemp_params
        params.require(:holtemp).permit(:title, :content, :valid_from, :valid_to, :dept, :status, :note)
      end
  end
    