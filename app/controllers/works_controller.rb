class WorksController < ApplicationController
  include WorksHelper
  include ApplicationHelper

  before_action :authorize

  def index
    @tab_names = TAB_NAMES.dup
    @current_tab = params[:tab] || @tab_names[:works]

    @tab_counts = {}
    TAB_CONFIGS.each do |tab_key, config|
      if config[:stype]
        @tab_counts[tab_key] = config[:table].where(stype: config[:stype], is_root: nil).count
      else
        @tab_counts[tab_key] = config[:table].where(is_root: nil).count
      end
    end

    if @current_tab == @tab_names[:works]
      search = params[:search].to_s.strip || ''
      
      # Lấy tất cả các chức năng (FUNCTIONS) và không phụ thuộc vào parent nào
      sql = Tfunction.where(stype: FUNCTIONS_KEYS[:FUNCTIONS], parent: nil, is_root: nil)
                           .where("name LIKE ? OR scode LIKE ?", "%#{search}%", "%#{search}%")
                           .order('created_at DESC')

      @functions = pagination_limit_offset(sql, 10)
      
      return false
    end

    if @current_tab == @tab_names[:functions]
      search = params[:search].to_s.strip || ''
      sql = Tfunction.where(stype: FUNCTIONS_KEYS[:FUNCTIONS], parent: nil, is_root: nil)
                     .where("name LIKE ? OR scode LIKE ?", "%#{search}%", "%#{search}%")
                     .order('created_at DESC')
      @tfunctions = pagination_limit_offset(sql, 10)

      return false
    end

    if @current_tab == @tab_names[:dueties]
      search = params[:search].to_s.strip || ''
      sql = Tfunction.where(stype: FUNCTIONS_KEYS[:DUETIES], is_root: nil)
                     .where("tfunctions.name LIKE ? OR tfunctions.scode LIKE ?", "%#{search}%", "%#{search}%")
                     .order('tfunctions.created_at DESC')
      @dueties = pagination_limit_offset(sql, 10)
      return false
    end

    if @current_tab == @tab_names[:tasks]
      search = params[:search].to_s.strip || ''
      @tasks = Stask.where("name LIKE ? OR scode LIKE ?", "%#{search}%", "%#{search}%")
                 .where(is_root: nil)
                 .order('created_at DESC')
      @tasks.each do |task|
        task.files =
          Taskdoc.where(stask_id: task.id).map do |doc|
            file_name = doc.mediafile&.file_name.to_s
            file_type = doc.mediafile&.file_type.to_s
            {
              doc_id:doc.id,
              file_name: doc.mediafile.file_name,
              file_type: doc.mediafile.file_type,
              file_size: doc.mediafile.file_size
            }
          end
      end
      
      @tasks = pagination_limit_offset(@tasks, 10)

      return false
    end

    if @current_tab == @tab_names[:gtasks]
      search = params[:search].to_s.strip || ''
      sql = Gtask.where('name LIKE ?', "%#{search}%")
                 .order('created_at DESC')
      @gtasks = pagination_limit_offset(sql, 10)

      return false
    end
  end

  def update_users_into_work
    pj_id = params[:positionjob_id]
    pj_id_old = params[:positionjob_id_old]
    department_id = params[:department_id]
    amount = params[:amount]
    users_id = params[:users_id]
    type = params[:type]
    msg = "Thêm không thành công"
    # remove positonjob if they differance
    # positionjob = Positionjob.where(id: pj_id_old).first
    # if !positionjob.nil? && pj_id_old != pj_id
    #   positionjob.destroy
    # end
    
    id = pj_id.nil? ? pj_id_old : pj_id
    positionjob = Positionjob.where(id: id).first
    if !positionjob.nil?
      # clone if is_root == nil
      # get positonjob_id to create new
      if positionjob.is_root.nil? && type != "edit"
        new_pj = positionjob.dup
        new_pj.is_root = positionjob.id
        new_pj.scode = "#{positionjob.scode}-CLONE"
        new_pj.department_id = department_id
        new_pj.amount = amount
        if new_pj.save
          positionjob_id = new_pj.id
        end

        # if positionjob.department_id.present?
        #   Work.where(positionjob_id: positionjob.id).destroy_all
        #   positionjob.update(department_id: nil)
        # end
        msg = "Thêm vị trí công việc thành công"
      else
        positionjob.update(amount: amount)
        positionjob_id = positionjob.id
        msg = "Cập nhật vị trí công việc thành công"
      end
      # destroy works with positonjob id 
      Work.where(positionjob_id: positionjob_id).destroy_all

      # cập nhật leader - deputy cho đơn vị khi gán vị trí trưởng phòng hoặc phó phòng
      oPositionjob = Positionjob.find_by(id: positionjob_id)
      if !oPositionjob.nil?
        if oPositionjob.scode.include?("TRUONG")
          oDepartment = Department.find_by(id: department_id)
          if !oDepartment.nil?
            oUsser = User.where(id: users_id).first
            if !oUsser.nil?
              oDepartment.update({
                leader: oUsser.email
              })
            end
          end
        end

        if oPositionjob.scode.include?("PHO")
          oDepartment = Department.find_by(id: department_id)
          if !oDepartment.nil?
            oUsers = User.where(id: users_id)
            if !oUsers.empty?
              # Lấy danh sách email từ users
              new_emails = oUsers.pluck(:email).compact
              
              # Lấy danh sách email hiện tại từ deputy
              current_emails = []
              if oDepartment.deputy.present?
                begin
                  # Parse JSON string thành array
                  current_emails = JSON.parse(oDepartment.deputy)
                rescue JSON::ParserError
                  # Nếu không parse được
                  current_emails = [oDepartment.deputy]
                end
              end
              
              # Merge và loại bỏ duplicate
              all_emails = (current_emails + new_emails).uniq
              
              # Convert array thành JSON
              deputy_json = all_emails.to_json
              
              oDepartment.update({
                deputy: deputy_json
              })
            end
          end
        end
      end

      # create new works
      if users_id.present?
        users_id.each do |id|
          Work.create({user_id: id, positionjob_id: positionjob_id})
        end
        updateUsersPermissionChange(users_id)
      end
    end
    redirect_to :back, notice: msg
  end

  def delete
    positionjob_id = params[:positionjob_id]
    department_id = params[:department_id]
    position = Positionjob.where(id: positionjob_id).first
    msg = "Không thể xóa vị trí công việc này vì nó đang được sử dụng"

    if !position.nil?
      if position.is_root.nil?
        position.update(department_id: nil)
        position.works.destroy_all
      else
        position.destroy
      end
      msg = "Xóa vị trí công việc thành công"
    end
    redirect_to :back, notice: msg
  end
end
