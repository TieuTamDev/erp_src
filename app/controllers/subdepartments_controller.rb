class SubdepartmentsController < ApplicationController
    include DepartmentsHelper
    before_action :authorize
    before_action :set_subdepartment, only: [:show, :edit, :update, :destroy]

    def new
        @subdepartment = Department.new
        
        respond_to do |format|
            format.html
            format.js
        end
    end
    
    def create
        department_id = params[:department_id]
        original_department = Department.find(department_id)
        @subdepartment = Department.new(subdepartment_params)
        @subdepartment.parents = department_id
        @subdepartment.organization_id = original_department&.organization_id
        @subdepartment.is_virtual = 'YES'
        # @subdepartment.leader = params[:leader]
        # @subdepartment.deputy = params[:deputy]
        @subdepartment.status = 0
        
        respond_to do |format|
            if @subdepartment.save
                flash[:notice] = 'Thêm nhóm thành công!'
                format.js { render js: "window.location = '#{departments_department_details_path(lang: session[:lang], department_id: department_id, tab: TAB_NAMES[:subdepartments])}'" }
            else
                flash[:alert] = 'Thêm nhóm thất bại!'
                format.js { render :new }
            end
        end
    end
    
    def show
        respond_to do |format|
            format.html
            format.js
        end
    end
    
    def edit
        selected_subdepartment = Department.find(params[:id])
        @selected_leader = selected_subdepartment.leader
        @selected_deputy = selected_subdepartment.deputy
        respond_to do |format|
            format.html
            format.js
        end
    end
    
    def update
        respond_to do |format|
            original_department_id = params[:department_id]
            original_department = Department.find(original_department_id)
            # @subdepartment.leader = params[:leader]
            # @subdepartment.deputy = params[:deputy]
            @subdepartment.organization_id = original_department&.organization_id
            @subdepartment.is_virtual = 'YES'
            if @subdepartment.update(subdepartment_params)
                flash[:notice] = 'Cập nhật nhóm thành công!'
                format.js { render js: "window.location = '#{departments_department_details_path(lang: session[:lang], department_id: original_department_id, tab: TAB_NAMES[:subdepartments])}'" }
            else
                flash[:alert] = 'Cập nhật nhóm thất bại!'
                format.js { render :edit }
            end
        end
    end
    
    def destroy
        original_department_id = params[:department_id]
        @subdepartment.destroy
        flash[:notice] = 'Nhóm đã được xóa thành công!'
        render js: "window.location = '#{departments_department_details_path(lang: session[:lang], department_id: original_department_id, tab: TAB_NAMES[:subdepartments])}'"
    end

    def get_users
      search = params[:search]&.strip
      department_id = params[:department_id]
      root_department = find_root_department(department_id)

      users = User.select(:id, :last_name, :first_name, :email, :sid)
                  .select("positionjobs.name as pos_name")
                  .joins(works: [positionjob: :department])
                  .where(departments: {id: root_department.id})
                  .where.not(users: {status: 'INACTIVE'})
                  .order("CONCAT(users.last_name,' ', users.first_name) ASC").distinct

      if search.present?
        users = users.where("LOWER(CONCAT(users.last_name,' ', users.first_name)) LIKE ? OR users.sid LIKE ?",
          "%#{search&.downcase}%",
          "%#{search}%")
      end

      results = []
      results = users
      
      render json: { items: results }
    end

    def users
        department_id = params[:id]
        
        users = User.joins("JOIN works ON works.user_id = users.id")
                    .joins("JOIN positionjobs ON positionjobs.id = works.positionjob_id")
                    .joins("JOIN departments ON departments.id = positionjobs.department_id")
                    .where("departments.id = ?", department_id)
                    .distinct
                    .select("users.id, users.email, users.first_name, users.last_name")

        
        respond_to do |format|
            format.json { 
                render json: { 
                    users: users.as_json(only: [:id, :email, :first_name, :last_name]),
                    total_count: users.count
                } 
            }
        end
    rescue => e
        respond_to do |format|
            format.json { 
                render json: { 
                    error: 'Có lỗi xảy ra khi tải danh sách nhân sự', 
                    message: e.message 
                }, status: :internal_server_error 
            }
        end
    end

    private
    
    def set_subdepartment
        @subdepartment = Department.find(params[:id])
    rescue ActiveRecord::RecordNotFound
        respond_to do |format|
            format.html { redirect_to subdepartments_path, alert: "Không tìm thấy nhóm" }
            format.js { render js: "alert('Không tìm thấy nhóm');" }
        end
    end

    def subdepartment_params
        params.require(:department).permit(:name, :name_en, :scode, :amount, :note)
    end

    def find_root_department(department_id)
        department = Department.find(department_id)
        
        while department.parents.present?
            department = Department.find(department.parents)
        end
        
        department
    end
end
