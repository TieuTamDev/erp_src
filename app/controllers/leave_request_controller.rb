class LeaveRequestController < ApplicationController
    before_action :authorize
    include AppointmentsHelper
    include AttendsHelper
    include HolidayShared
    before_action -> { prepare_holiday_data(session[:user_id]) }
    def index
        
    end

    def management
        
    end

    
    def history
        
    end
    def datas_leave_request
      user_id = params[:user_id]
    
      page = params[:page].to_i
      per_page = params[:per_page].to_i
      search = params[:search]&.strip || ""
      order_column = params[:order_column] || "created_at"
      order_dir = params[:order_dir] || "desc"
      start_date = params[:start_date] || ""
      end_date = params[:end_date] || ""

      current_year = Date.current.year
      check_buh = Organization.find_by(scode: "BUH")
      # h.a
      # 23/01/2026
      # hiển thị full đơn của người dùng
      if check_buh.present? && current_user&.uorgs&.first&.organization_id == check_buh.id
        holidays = Holiday.where(
          year: [current_year, current_year - 1],
          user_id: user_id
        )

        holpros = Holpro.joins("
                    LEFT JOIN holprosdetails ON holprosdetails.holpros_id = holpros.id
                    LEFT JOIN holtypes ON holtypes.code = holprosdetails.sholtype
                  ")
                  .where(holiday_id: holidays.select(:id))
      else
        holiday = Holiday.find_by(year: current_year, user_id: user_id)
        holpros = Holpro.joins("
                    LEFT JOIN holprosdetails ON holprosdetails.holpros_id = holpros.id
                    LEFT JOIN holtypes ON holtypes.code = holprosdetails.sholtype
                  ")
                  .where(holiday_id: holiday&.id)
                  .distinct
      end

      holpros = holpros.where("holtypes.name LIKE ? OR holprosdetails.details LIKE ?", "%#{search}%", "%#{search}%") if search.present?
      total_count = holpros.count
      holpros = holpros.order("#{order_column} #{order_dir}").offset((page - 1) * per_page).limit(per_page)

      # custom data to show
      holpros = holpros.map do |holpro|
        holprosdetails = holpro.holprosdetails.includes(:holtype).order(:id)
        # Nối chuỗi các name từ Holtype dựa trên sholtype (scode)
        holtype_names = holprosdetails.map { |detail| "<div class='mb-3'>#{detail.holtype&.name}</div>" }.compact.join("")

        holpro.stype = holtype_names.presence
        status_formated = translate_status(holpro.status)
        uhandle_id =  Mandocuhandle.joins(mandocdhandle: :mandoc).where(mandocs: {holpros_id: holpro.id}).first&.id
        holprosdetails = Holprosdetail.where(holpros_id: holpro.id).order(:id).includes(:holtype)

        details_leave = ""
        holprosdetails_data = holprosdetails.map do |detail|
          all_dates = detail.details.to_s.split("$$$").map do |seg|
            Date.strptime(seg.split("-").first, "%d/%m/%Y") rescue nil
          end.compact.uniq.sort

          ranges = []
          all_dates.each do |date|
            if ranges.empty? || ranges.last.last + 1 != date
              ranges << [date]
            else
              ranges.last << date
            end
          end
          
          current_year = Date.today.year
          formatted_ranges = ranges.map do |range|
            from_format = range.first.year == current_year ? '%d/%m' : '%d/%m/%Y'
            to_format   = range.last.year == current_year ? '%d/%m' : '%d/%m/%Y'

            if range.size > 1
              "Từ #{range.first.strftime(from_format)} đến #{range.last.strftime(to_format)}"
            else
              range.first.strftime(from_format)
            end
          end

          details_leave << "<div class='ellipsis mb-3'>#{formatted_ranges.join(", ")}</div>"
          detail.attributes.merge(
            "sholtype_name" => detail.holtype&.name,
          )
        end
        holpro.details = details_leave
        holpro.attributes.merge(holprosdetails: holprosdetails_data, uhandle_id: uhandle_id, status_formated: status_formated)
      end

      holpros = holpros.as_json
      render_button(holpros)

      render json: {
        draw: params[:draw],
        recordsTotal: total_count,
        recordsFiltered: total_count,
        data: holpros,
      }
    end

    def format_info_leave(details)
      
    end

    def render_button(datas)
      datas.each do |data|
        data_encode = Base64.encode64({
          holprosdetails: data["holprosdetails"], 
          uhandle_id: data["uhandle_id"], 
          holpros_id: data["id"],
          stype: data["stype"],
        }.to_json )
        data[:btn] = ""
        if data["status"] == "TEMP"
          # btn edit
          data[:btn] += "<a class='me-2 btn-edit' type='button' onclick='onEditLeaveRequest(this)' data-leave-request='#{data_encode}' data-toggle='tooltip' data-placement='top' title='Cập nhật đơn' data-bs-toggle='modal' data-bs-target='#leaveRequestModal'><span class='fas fa-file-signature text-primary'></span></a>"
        end
        # btn details
        data[:btn] += "
          <a class='me-2 position-relative' type='button' onclick='onShowProcessHandle(`#{data["id"]}`)' data-toggle='tooltip' data-placement='top' title='Xem tiến độ duyệt đơn' data-bs-toggle='modal' data-bs-target='#processHandleLeaveRequest'>
            <span class='fas fa-search fs--2 position-absolute bg-white' style='bottom: 2px;right: -3px;z-index: 10;border-top-left-radius: 5px;border-bottom-left-radius: 5px;padding-top: 2px;padding-left: 2px;'></span>
            <span class='fas fa-file' style='z-index: 1;'></span>
          </a>"
        # btn_remove
        if data["status"] == "TEMP" || data["status"] == "REFUSE"
          data[:btn] += "<a class='ms-2 btn-remove' type='button' onclick='onDeleteLeaveRequest(`#{data["id"]}`)' data-toggle='tooltip' data-placement='top' title='Xóa đơn' data-bs-toggle='modal' data-bs-target='#genericDeleteModal'><span class='fas fa-trash-alt text-danger'></span></a>"
        end
        # btn cancel
        check_time = allow_cancel_leave?(data["id"])
        user_id = find_user_id(data["id"])
        if data["status"] == "DONE" && user_id == session[:user_id]
          # BMU CANCEL
          if check_time && session[:organization].first != "BUH"
            data[:btn] += "<a class='ms-2 btn-remove' type='button' onclick='onCancelLeaveRequest(`#{data["id"]}`)' data-toggle='tooltip' data-placement='top' title='Hủy đơn' data-bs-toggle='modal' data-bs-target='#genericCancelModal'><span class='far fa-times-circle text-danger'></span></a>" 
          end
          # BUH CANCEL
          if check_update_approved_leave(data["id"])
            data[:btn] += "<a class='ms-2 btn-remove' type='button' onclick='onEditLeaveRequest(this, `CANCEL`)' data-leave-request='#{data_encode}' data-toggle='tooltip' data-placement='top' title='Cập nhật đơn đã duyệt' data-bs-toggle='modal' data-bs-target='#leaveRequestModal'><span class='far fa-edit text-warning'></span></a>"
          end
        end

        # BUH CANCEL WHEN LEADER APPROVE YET
        if (data["status"] == "PENDING" || data["status"] == "PROCESSING") && user_id == session[:user_id] && session[:organization].first == "BUH"
          data[:btn] += "<a class='ms-2 btn-remove' type='button' onclick='onCancelLeaveRequest(`#{data["id"]}`)' data-toggle='tooltip' data-placement='top' title='Hủy đơn' data-bs-toggle='modal' data-bs-target='#genericCancelModal'><span class='far fa-times-circle text-danger'></span></a>" 
        end

        # btn print
        if (data["status"] == "CANCEL-DONE" || data["status"] == "DONE") && user_id == session[:user_id]
          data[:btn] += "<a class='ms-2' type='button' onclick='printHolpro(`#{data["id"]}`,`#{session[:organization]}`)' data-toggle='tooltip' data-placement='top' title='In đơn' ><span class='fas fa-print text-warning'></span></a>"
        end
      end
    end

    def allow_cancel_leave?(holpros_id)
      details = Holprosdetail.where(holpros_id: holpros_id)

      min_date = details.flat_map do |h|
        h.details.to_s.split("$$$").map do |d|
          Date.strptime(d.split("-").first, "%d/%m/%Y") rescue nil
        end
      end.compact.min

      now = Time.zone.now
      # Check nil min_date trước khi so sánh
      if min_date.present?
        result = now < min_date.to_time.change(hour: 19)
      else
        result = false
      end
    end
    def check_update_approved_leave(holpros_id)
      details = Holprosdetail.where(holpros_id: holpros_id)
      now = Time.zone.now

      has_valid_day = details.flat_map do |h|
        h.details.to_s.split("$$$").map do |d|
          begin
            date = Date.strptime(d.split("-").first, "%d/%m/%Y")
            date_19h = date.to_time.change(hour: 19)
            now < date_19h
          rescue
            false
          end
        end
      end.any?
    end
    
    def find_user_id(holpros_id)
      holpro = Holpro.find_by(id: holpros_id)
      holiday = Holiday.find_by(id: holpro.holiday_id)
      if holiday.present?
        user_id = holiday.user_id
      else
        user_id = nil
      end
      user_id
    end

    def cancel_leave_request
      holpros_id = params[:holpros_id]
      cancel_reason_leave = params[:cancel_reason_leave]
      holpros = Holpro.where(id: holpros_id)
      
      if holpros.present?
        # update holpro
        holpros.update(status: "CANCEL", note: cancel_reason_leave)

        # find mandoc dhandle uhandle
        madoc = Mandoc.find_by(holpros_id: holpros_id)
        mandocD = Mandocdhandle.where(mandoc_id: madoc.id)
        mandocU = Mandocuhandle.where(mandocdhandle_id: mandocD.pluck(:id))

        mandocU.where(status: "CHUAXULY").update(status: "DAXULY")
        # get user_ids
        user_ids = mandocU.pluck(:user_id).uniq
        list_user_id = user_ids.reject { |id| id == session[:user_id] }

        # current user info 
        user_request = User.where(id: session[:user_id]).first
        full_name = "#{user_request&.last_name} #{user_request&.first_name}"

        #
        content = "Đơn nghỉ phép của nhân sự: <b>#{full_name}</b> - Mã nhân sự: <b>#{user_request&.sid}</b> đã bị hủy. Lý do:<b>#{cancel_reason_leave}</b>"
        create_noti_cancel(content,list_user_id)

        # get days leave
        amount_to_consume = Holprosdetail.where(holpros_id: holpros_id)
        detail_leave = amount_to_consume.select { |detail| detail.sholtype == "NGHI-PHEP" }
        total_leave_revert = detail_leave ? detail_leave.sum { |item| item["itotal"].to_f } : 0

        # refund days leave
        revert_leave(session[:user_id], total_leave_revert, detail_leave.pluck(:details), holpros_id)

        # Update chấm công
        update_scheduleweek(session[:user_id], amount_to_consume.pluck(:details).uniq.join("$$$"), "CANCELED")
        
        flash[:success] = "Hủy đơn thành công!"
      else
        flash[:error] = "Vui lòng kiểm tra lại thông tin"
      end
      redirect_to request.referer
    end

    def create_noti_cancel(content,list_user_id)
      new_notify = Notify.create!(
        title: "Nghỉ phép",
        contents: content,
        receivers: "Hệ thống ERP",
        stype: "LEAVE_REQUEST"
      )
      list_user_id.each do |uid|
        Snotice.create!(
          notify_id: new_notify.id,
          user_id: uid,
          isread: false
        )
        if (user = User.find_by(id: uid))&.email.present?
          UserMailer.send_mail_leave_request(user.email, content).deliver_later
        end
      end
    end

    def check_urgent_leave
      # user_id = session[:user_id]
    
      # current_year = Date.current.year
      # current_month = Date.current.month
    
      # holiday = Holiday.where(year: current_year, user_id: user_id).first
      # leave_days_count = 0
      # if holiday.present?
      #   leave_days_count = holiday.total.to_i / 12 * current_month - holiday.used.to_i
      # end
    
      # format.js { render js: "console.log(#{leave_days_count})" }
    end
    def position_leave
    end
    def staff_leave
    end

    def export_excel
        o_id = Organization.find_by(scode: "BUH")&.id
        list_ids = Department.where(organization_id: o_id).pluck(:id).uniq
        if params[:department_id].present?
          selected_id = params[:department_id].to_i
          list_ids = [selected_id] if list_ids.include?(selected_id)
        end
        list_position = Positionjob.includes(:department).where(department_id: list_ids, status: "ACTIVE")
        p = Axlsx::Package.new
        wb = p.workbook

        styles = wb.styles
        header_style = styles.add_style(
          bg_color: '4F81BD', fg_color: 'FFFFFF', b: true,
          alignment: { horizontal: :center },
          border: { style: :thin, color: '000000' }
        )
        center_style = styles.add_style(
          alignment: { horizontal: :center },
          border: { style: :thin, color: '000000' }
        )
        normal_style = styles.add_style(
          border: { style: :thin, color: '000000' }
        )
      
        wb.add_worksheet(name: "Quản lý code phép") do |sheet|
            sheet.add_row ["STT", "Khoa/phòng" ,"Vị trí công việc", "Code phép", "Ngày nghỉ"],
                            style: [header_style, header_style, header_style, header_style, header_style]
            list_position.each_with_index do |position, index|
                name_depart = position&.department&.name || "Chưa có đơn vị"
                sheet.add_row [
                index + 1,
                name_depart,
                position.name,
                position.scode,
                if position.holno.present?
                  position.holno
                else
                  nil
                end
                ],
                style: [center_style, normal_style, normal_style, normal_style, center_style]
            end
        end
        if params[:department_id].present?
          name = Department.where(id: params[:department_id]).first&.name
          file_name = "Quan_ly_code_phep_phong_#{name}.xlsx"
        else
          file_name = "Quan_ly_code_phep.xlsx"
        end
        xlsx_data = p.to_stream.read
        send_data xlsx_data,
                  filename: file_name,
                  type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    end
    def import_excel
        if params[:file].present? && params[:file].is_a?(ActionDispatch::Http::UploadedFile)
          file = params[:file]
          current_time = Time.current
          current_year = current_time.year
          begin
            excel_datas = read_excel(file, 1)
            errors = []
            excel_datas.each_with_index do |row, index|
              name_depart = row[1].to_s.strip
              scode = row[3].to_s.strip
              leave_days = row[4].to_f
              department = Department.where(name: name_depart).first
              if department.present?
                position = Positionjob.where(department_id: department.id, scode: scode, status: "ACTIVE").first
                if position.present?
                  if position.holno.to_f != leave_days
                    position.update(holno: leave_days)
                    support_update("UPDATE", position.id, leave_days, current_year)
                  end
                else
                errors << "Không tìm thấy vị trí với code: #{scode} (dòng #{index + 2})"
                end
              else
                errors << "Không tìm thấy phòng khoa với tên phòng: #{name_depart} (dòng #{index + 2})"
              end
              
            end
            if errors.empty?
              flash[:success] = "Import thành công!"
            else
              flash[:error] = "Có lỗi khi import:\n#{errors.join("\n")}"
            end
          rescue => e
            flash[:error] = "Đã xảy ra lỗi khi đọc file: #{e.message}"
          end
        else
          flash[:error] = "Vui lòng chọn một file Excel để import!"
        end
        redirect_to request.referer || manager_leave_position_leave_path(lang: session[:lang])
    end
    def update_leave_days
      position = Positionjob.find_by(id: params[:position_id])
      current_time = Time.current
      current_year = current_time.year
      if position.present?
        if params[:action_type] == 'edit'
          position.update(holno: params[:leave_days])
          support_update("UPDATE", position.id, params[:leave_days],current_year)
          flash[:success] = "Cập nhật ngày nghỉ thành công!"
        elsif params[:action_type] == 'delete'
          position.update(holno: nil)
          support_update("DELETE", position.id, params[:leave_days],current_year)
          flash[:success] = "Xóa ngày nghỉ thành công!"
        end
      else
        flash[:error] = "Không tìm thấy vị trí!"
      end
      redirect_to request.referer || manager_leave_position_leave_path(lang: session[:lang])
    end
    def support_update(type, position_id, leave_days,current_year)
      if type == "UPDATE"
        list_user = Work.where(positionjob_id: position_id).pluck(:user_id)
        list_user.each do |user|
          oHol = Holiday.where(user_id: user, year: current_year).first
          if oHol.present?
            Holdetail.where(holiday_id: oHol.id, name: "Phép theo vị trí").first&.update(amount: leave_days)
          end
        end
      else
        list_user = Work.where(positionjob_id: position_id).pluck(:user_id)
        list_user.each do |user|
          oHol = Holiday.where(user_id: user, year: current_year).first
          if oHol.present?
            Holdetail.where(holiday_id: oHol.id, name: "Phép theo vị trí").first&.update(amount: nil)
          end
        end
      end
    end
    def handle_register_leave_request
      user_id           = params[:user_register_id]
      info_user_next    = params[:info_user_next]
      info_user_next    = JSON.parse(info_user_next) if info_user_next.present?
      stype             = params[:stype]
      holpros_id        = params[:holpros_id]
      datas             = params[:datas]
      commit            = params[:commit]
      org               = params[:org]
      uhandle_id        = params[:uhandle_id]
      leave_bgd_flag    = params[:leave_bgd_flag]
      action_submit     = params[:action_submit] || ""
      uid               = stype == "ON-LEAVE" || action_submit == "CANCEL" ? session[:user_id] : user_id
      user_send_notice  = ""
      content           = ""
      msg               = "Đăng ký phép không thành công"
      # create update leave request
      result = create_leave_request(holpros_id, stype, uid, datas, commit, action_submit,leave_bgd_flag)
      uhandle = Mandocuhandle.where(id: uhandle_id).first
      if leave_bgd_flag.present? && result
        user_request = User.where(id: uid).first
        full_name = "#{user_request&.last_name} #{user_request&.first_name}"
        user_send_notice = []
        details = Holprosdetail.where(holpros_id: result[:holpros_id])
        ids = details.map do |detail|
                next unless detail.handover_receiver
                detail.handover_receiver.split("|||").map do |receiver|
                  receiver.split("$$$").first
                end
              end
        ids = ids.flatten.compact.uniq.map(&:to_i)
        dhandle = create_dhandle({
          mandoc_id: result[:mandoc_id],
          department_id: session[:department_id],
          srole: "LEAVE-REQUEST",
          contents: "",
          status: "PENDING", #
        })
        create_uhandle({
          id: nil,
          mandocdhandle_id: dhandle.id,
          user_id: uid,
          srole: "MAIN",
          contents: "",
          status: "DAXULY",
          sread: "NO",
          received_at: Time.now,
        })
        if uid != session[:user_id]
          create_uhandle({
            id: nil,
            mandocdhandle_id: dhandle.id,
            user_id: session[:user_id],
            srole: "MAIN",
            contents: "",
            status: "DAXULY",
            sread: "NO",
            received_at: Time.now,
          })
        end
        ids.each do |user_support|
            Mandocuhandle.create!(
              mandocdhandle_id: dhandle.id,
              user_id: user_support,
              srole: "SUB",
              status: "DAXULY",
              sread: "NO",
              received_at: Time.now,
            )
        end
        content = "Đơn nghỉ của nhân sự: <b>#{full_name}</b> - Mã nhân sự: <b>#{user_request&.sid}</b> tạo thành công"
        ids = ids.flatten.compact.uniq.map(&:to_i)
        user_send_notice = [session[:user_id].to_i] | ids

        create_noti(content, result[:holpros_id], user_send_notice)
        msg = "Đơn nghỉ của nhận sự tạo thành công"
      else
        if result
          # Thái
          # tạo bước xử lý cho người tạo
          if uhandle.nil?
            dhandle_user_register = create_dhandle({
              mandoc_id: result[:mandoc_id],
              department_id: session[:department_id],
              srole: "LEAVE-REQUEST",
              contents: "",
              status: "TEMP"
            })
            uhandle_user_register = create_uhandle({
              id: nil,
              mandocdhandle_id: dhandle_user_register.id,
              user_id: session[:user_id],
              srole: "MAIN",
              contents: "",
              status: "CHUAXULY",
              sread: "NO",
              received_at: Time.now,
              sothers: "TEMP"
            })
          end
    
          if commit != "save"
            # update uhandle register leave request user
            create_uhandle({
              id: uhandle_id == "" || uhandle_id.nil? ? uhandle_user_register.id : uhandle_id,
              status: "DAXULY",
              sread: "YES"
            })
  
            #update 
            mandoc = Mandoc.find(result[:mandoc_id])
            holpro = Holpro.find(mandoc.holpros_id)
            if action_submit != "CANCEL"
              mandoc.update(status: "PENDING")
              holpro.update(status: "PENDING")
            else
              mandoc.update(status: "CANCEL-PENDING")
              holpro.update(status: "CANCEL-PENDING")
            end
  
            # get info user register
            user_request = User.where(id: uid).first
            full_name = "#{user_request&.last_name} #{user_request&.first_name}"
            # Dành cho đăng ký thay
            if stype == "ON-ADDITIONAL-LEAVE" && action_submit != "CANCEL"
              dhandle_approve = create_dhandle({
                  mandoc_id: result[:mandoc_id],
                  department_id: session[:department_id],
                  srole: "LEAVE-REQUEST",
                  contents: "",
                  status: "DAXULY"
              })
              uhandle_approve = create_uhandle({
                  id: nil,
                  mandocdhandle_id: dhandle_approve.id,
                  user_id: session[:user_id],
                  srole: "MAIN",
                  status: "DAXULY",
                  sread: "YES",
                  received_at: Time.now,
                  sothers: "DAXULY"
              })
              # Nếu là bệnh viện thì tạo cho người xử lý tiếp theo
              if org == "BUH"
                # Bên viện hoàn tất
                if info_user_next.present?
                  # create dhandle and uhandle for next user to handle
                  dhandle = create_dhandle({
                    mandoc_id: result[:mandoc_id],
                    department_id: info_user_next["department_id"],
                    srole: "LEAVE-REQUEST",
                    contents: "",
                    status: "PENDING", #
                  })
                  create_uhandle({
                    id: nil,
                    mandocdhandle_id: dhandle.id,
                    user_id: info_user_next["user_id"],
                    srole: "MAIN",
                    contents: "",
                    status: "CHUAXULY",
                    sread: "NO",
                    received_at: Time.now,
                  })
                  # config content and user send notice
                  content = "Đơn nghỉ của nhân sự: <b>#{full_name}</b> - Mã nhân sự: <b>#{user_request&.sid}</b> cần được xử lý"
                  user_send_notice = [info_user_next["user_id"] || ""]
                else
                  # config content and user send notice
                  content = "Đơn nghỉ phép của nhân sự: <b>#{full_name}</b> - Mã nhân sự: <b>#{user_request&.sid}</b> đã được duyệt"
                  # get users id to send notice
                  # get all user in uhandle
                  user_send_notice = get_list_user(mandoc.holpros_id)
                  # get users id in receiver
                  receiver         = holpro.holprosdetails.pluck(:handover_receiver)
                  receiver_ids     = receiver.map { |r| r.split("$$$").first }
    
                  # merge array
                  user_send_notice += receiver_ids
                  user_send_notice += get_users_have_access_handle("", "READ").map { |data| data[:user_id] }
    
                  # Lấy holprosdetails với holtype là NGHI-PHEP và NGHI-CHE-DO
                  details_manager   = holpro.holprosdetails.where(sholtype: ["NGHI-PHEP"])
                  itotal            = details_manager.sum(:itotal)
    
                  # Tính tổng
                  holiday      = Holiday.find_by(id: holpro.holiday_id)
                  holiday.used =  holiday.used.to_f + itotal.to_f
                  holiday.save
                
                  # update status
                  # holpro
                  holpro.update(status: "DONE")
    
                  # holprosdetails
                  holpro.holprosdetails.update(status: "DONE")
                end
              else
                # Bên trường hoàn tất
                if info_user_next.present?
                  dhandle = create_dhandle({
                    mandoc_id: result[:mandoc_id],
                    department_id: info_user_next["department_id"],
                    srole: "LEAVE-REQUEST",
                    contents: "",
                    status: "PENDING", #
                  })
                  create_uhandle({
                    id: nil,
                    mandocdhandle_id: dhandle.id,
                    user_id: info_user_next["user_id"],
                    srole: "MAIN",
                    contents: "",
                    status: "CHUAXULY",
                    sread: "NO",
                    received_at: Time.now,
                  })
                  content = "Đơn nghỉ của nhân sự: <b>#{full_name}</b> - Mã nhân sự: <b>#{user_request&.sid}</b> cần được xử lý"
                  user_send_notice = [info_user_next["user_id"] || ""]
                else
                  # config content and user send notice
                  content = "Đơn nghỉ phép của nhân sự: <b>#{full_name}</b> - Mã nhân sự: <b>#{user_request&.sid}</b> đã được duyệt"
                  # get users id to send notice
                  # get all user in uhandle
                  user_send_notice = get_list_user(mandoc.holpros_id)
                  # get users id in receiver
                  receiver         = holpro.holprosdetails.pluck(:handover_receiver)
                  receiver_ids     = receiver.map { |r| r.split("$$$").first }
    
                  # merge array
                  user_send_notice += receiver_ids
    
                  # Lấy holprosdetails với holtype là NGHI-PHEP và NGHI-CHE-DO
                  details_manager   = holpro.holprosdetails.where(sholtype: ["NGHI-PHEP"])
                  itotal            = details_manager.sum(:itotal)
    
                  # Tính tổng
                  holiday      = Holiday.find_by(id: holpro.holiday_id)
                  holiday.used =  holiday.used.to_f + itotal.to_f
                  holiday.save
                
                  # update status
                  # holpro
                  holpro.update(status: "DONE")
    
                  # holprosdetails
                  holpro.holprosdetails.update(status: "DONE")
                end
              end
            else
              # Dành cho đăng ký đơn bình thường gửi cho người xử lý tiếp theo
              dhandle = create_dhandle({
                mandoc_id: result[:mandoc_id],
                department_id: info_user_next["department_id"],
                srole: "LEAVE-REQUEST",
                contents: "",
                status: action_submit != "CANCEL" ? "PENDING" : "CANCEL-PENDING", #
              })
              create_uhandle({
                id: nil,
                mandocdhandle_id: dhandle.id,
                user_id: info_user_next["user_id"],
                srole: "MAIN",
                contents: "",
                status: "CHUAXULY",
                sread: "NO",
                received_at: Time.now,
              })
  
              content = "Đơn nghỉ của nhân sự: <b>#{full_name}</b> - Mã nhân sự: <b>#{user_request&.sid}</b> cần được xử lý"
              user_send_notice = [info_user_next["user_id"] || ""]
            end
  
            # send email and create notification
            create_noti(content, mandoc.holpros_id, user_send_notice)
          end
          msg = result[:msg]
        end
      end
      redirect_to :back, notice: msg
    end

    def create_uhandle(data)
      uhandle = Mandocuhandle.where(id: data[:id]).first
      if uhandle.present?
        uhandle.update(data)
      else
        Mandocuhandle.create(data)
      end
    end

    def create_dhandle(data)
      mDhandle = Mandocdhandle.create(data)
      mDhandle
    end

    def create_noti(content,holpros_id, list_user_id)
      new_notify = Notify.create!(
        title: "Nghỉ phép",
        contents: content,
        receivers: "Hệ thống ERP",
        stype: "LEAVE_REQUEST"
      )
      list_user_id.each do |uid|
        Snotice.create!(
          notify_id: new_notify.id,
          user_id: uid,
          isread: false
        )
        if (user = User.find_by(id: uid))&.email.present?
          UserMailer.send_mail_leave_request(user.email, content).deliver_later
        end
      end
    end
    
    def create_leave_request(holpros_id, stype, user_id, datas, commit, action_submit, leave_bgd_flag)
      datas = JSON.parse(datas) if datas.present?
      msg = "Tạo yêu cầu nghỉ không thành công!"

      current_year = Date.current.year
      holiday = Holiday.where(year: current_year, user_id: user_id).first
      totalLeave = 0
      data_return = false
      holprosdetails_id_updated = []
      if holiday.present?
        holpro = Holpro.where(id: holpros_id).first
        if holpro.present?
          mandoc = Mandoc.find_by(holpros_id: holpro.id)
          # Cập nhật thông tin phép
          datas.each do |data|
            # Cộng tổng ngày nghỉ
            totalLeave += data["itotal"].to_f
            data["holpros_id"] = holpro.id

            holdetail = Holprosdetail.where(id: data["id"]).first

            if holdetail.nil?
              holdetail = Holprosdetail.create(data)
            else
              if action_submit == "CANCEL"
                # Tạo mhistory lưu thông tin nghỉ phép thay đổi
                handle_cancel(holdetail,data)
              else
                holdetail.update(data)
              end
            end
            holprosdetails_id_updated.push(holdetail.id)
          end
          if action_submit == "CANCEL" 
            mandoc = Mandoc.create({holpros_id: holpro.id, status: "CANCEL"})
            # Tạo bước hủy của người đăng nhập
            dhandle_user_register = create_dhandle({
              mandoc_id: mandoc.id,
              department_id: session[:department_id],
              srole: "LEAVE-REQUEST",
              contents: "",
              status: "CANCEL-TEMP"
            })
            uhandle_user_register = create_uhandle({
              id: nil,
              mandocdhandle_id: dhandle_user_register.id,
              user_id: session[:user_id],
              srole: "MAIN",
              contents: "",
              status: "DAXULY",
              sread: "YES",
              received_at: Time.now,
              sothers: "CANCEL-TEMP"
            })
            if leave_bgd_flag.present?
              mandoc.update(status: "CANCEL-PENDING")
              o_mandoc_cancel = Mandoc.where(holpros_id: holpro.id, status: "CANCEL-PENDING").first
              list_hpdetail = Holprosdetail.where(holpros_id: holpro.id)
              total_changed_days_phep = 0.0
              total_changed_days = 0.0
              removed_dates = []
              if list_hpdetail.present?
                list_hpdetail.each do |detail|
                  original_total = detail.itotal.to_f

                  history = Mhistory.where(stable: "holprosdetails$$$#{detail.id}", srowid: "details")
                                    .order(updated_at: :desc)
                                    .first
                  next unless history.present?

                  f_days = (history.fvalue || "").split("$$$")
                  t_days = (history.tvalue || "").split("$$$")

                  # Convert thành hash { "date" => "type" }
                  f_hash = f_days.map { |d| d.split("-") }.to_h
                  t_hash = t_days.map { |d| d.split("-") }.to_h

                  changes = []

                  # duyệt qua tất cả ngày xuất hiện trong f hoặc t
                  (f_hash.keys | t_hash.keys).each do |date|
                    f_type = f_hash[date]
                    t_type = t_hash[date]

                    if f_type && t_type
                      # nếu khác nhau thì thêm phần bù còn lại
                      if f_type != t_type
                        if f_type == "ALL" && t_type == "AM"
                          changes << "#{date}-PM"
                        elsif f_type == "ALL" && t_type == "PM"
                          changes << "#{date}-AM"
                        else
                          changes << "#{date}-#{t_type}"
                        end
                      end
                    elsif f_type && !t_type
                      # bị xóa đi => lấy nguyên bản f
                      changes << "#{date}-#{f_type}"
                    elsif !f_type && t_type
                      # mới thêm => lấy nguyên bản t
                      changes << "#{date}-#{t_type}"
                    end
                  end

                  result = changes.join("$$$")

                  to_map = ->(arr) {
                    arr.each_with_object({}) do |s, h|
                      date_str, session = s.split("-", 2)
                      h[date_str] = (session || "ALL").upcase
                    end
                  }

                  weight = ->(sess) {
                    case sess
                    when "ALL" then 1.0
                    when "AM", "PM" then 0.5
                    else 0.0
                    end
                  }

                  f_map = to_map.call(f_days)
                  t_map = to_map.call(t_days)

                  changed_days = 0.0

                  # Trường hợp hủy toàn bộ (tvalue blank)
                  if history.tvalue.blank?
                    f_days.each do |d|
                      sess = d.split("-").last
                      changed_days += weight.call(sess)
                    end
                    removed_dates.concat(f_days)
                    detail.update!(itotal: 0, details:"")
                  else
                    # Trường hợp hủy 1 phần (so sánh f vs t)
                    (f_map.keys | t_map.keys).each do |date_str|
                      f_sess = f_map[date_str]
                      t_sess = t_map[date_str]

                      f_w = weight.call(f_sess)
                      t_w = weight.call(t_sess)

                      if f_w > t_w
                        delta = f_w - t_w
                        changed_days += delta

                        if detail.sholtype == "NGHI-PHEP"
                          if t_sess.nil?
                            removed_dates << "#{date_str}-#{f_sess}"
                          elsif f_sess == "ALL" && t_sess == "AM"
                            removed_dates << "#{date_str}-PM"
                          elsif f_sess == "ALL" && t_sess == "PM"
                            removed_dates << "#{date_str}-AM"
                          else
                            removed_dates << "#{date_str}-PARTIAL"
                          end
                        end
                      end
                    end
                    calculate_itotal = original_total - changed_days
                    detail.update!(itotal: calculate_itotal, details: history.tvalue)
                  end
                  update_scheduleweek(user_id, result, "CANCELED")
                  total_changed_days += changed_days
                  if detail.sholtype == "NGHI-PHEP"
                    total_changed_days_phep += changed_days
                  end
                end
              end
              holpro.update!(dttotal: holpro.dttotal.to_f - total_changed_days)
              holiday = Holiday.find_by(user_id: holpro.holiday.user_id, year: Time.zone.today.year)
              if holiday.present?
                holiday.update!(used: holiday.used.to_f - total_changed_days_phep)
                removed_dates.uniq!
                withdraw_used_days(holiday, total_changed_days_phep, removed_dates)
              end
              Mandocuhandle.where(mandocdhandle_id: Mandocdhandle.where(mandoc_id: o_mandoc_cancel&.id).pluck(:id)).update_all(status: "DAXULY")
              holpro.update!(status: "CANCEL-DONE")
            end
          
          end 
          msg = "Cập nhật yêu cầu nghỉ thành công!"
          holprodetails_delete = Holprosdetail.where.not(id: holprosdetails_id_updated).where(holpros_id: holpros_id).destroy_all
        else
          # Tạo mới thông tin phép
          if leave_bgd_flag.present?
            status = "DONE"
          else
            status = "TEMP"            
          end
          holpro = Holpro.create({
            stype: stype,     
            dtcreated: Time.now,         
            status: status,
            holiday_id: holiday.id,
          })
          datas.each do |data|
            totalLeave += data["itotal"].to_f
            data["holpros_id"] = holpro.id
            holprosdetails = Holprosdetail.create(data)
          end
          mandoc = Mandoc.create({holpros_id: holpro.id, status: status})
          msg = "Tạo yêu cầu nghỉ thành công!"
        end
        if action_submit != "CANCEL"
          holpro.update(dttotal: totalLeave.to_f != totalLeave.to_i ? totalLeave.to_f  : totalLeave.to_i)
        end

        if commit != "save" && action_submit != "CANCEL"
          amount_to_consume = Holprosdetail.where(holpros_id: holpro.id, sholtype: ["NGHI-PHEP", "NGHI-CHE-DO"])
          details = amount_to_consume.pluck(:details)
          itotal = amount_to_consume.sum(:itotal)
          consume_leave(user_id, itotal, details)
        end
        data_return = { msg: msg, mandoc_id: mandoc.id, holpro_id: holpro.id }
      end
      data_return
    end
    def withdraw_used_days(holiday, delta_remove, removed_dates)
      return if holiday.blank? || delta_remove.to_f <= 0 || removed_dates.blank?

      delta_remove = delta_remove.to_f
      holdetail_map = holiday.holdetails.index_by(&:stype)

      ton, tham_nien, vi_tri = holdetail_map.values_at("TON", "THAM-NIEN", "VI-TRI")
      ton_deadline = ton&.dtdeadline&.to_date

      # Trọng số theo session
      weight_of = ->(token) do
        sess = token.to_s.split("-", 2)[1].to_s.upcase
        case sess
        when "", "ALL" then 1.0
        when "AM", "PM" then 0.5
        else 0.5 # PARTIAL/khác xem như nửa ngày
        end
      end

      entries = removed_dates.map do |dstr|
        d = dstr.to_s.split("-", 2)[0].strip
        date = (Date.strptime(d, "%d/%m/%Y") rescue nil)
        { date: date, weight: weight_of.call(dstr) }
      end

      total_weight = entries.sum { |e| e[:weight] }
      return if total_weight <= 0.0

      delta = [delta_remove, total_weight].min

      # Chia thành 2 giỏ: <= deadline (cho TỒN) và > deadline (không cho TỒN)
      if ton_deadline
        before_entries, after_entries = entries.partition { |e| e[:date] && e[:date] <= ton_deadline }
      else
        before_entries, after_entries = entries, []
      end

      w_before = before_entries.sum { |e| e[:weight] }
      w_after  = after_entries.sum  { |e| e[:weight] }

      delta_before = [delta, w_before].min
      delta_after  = [delta - delta_before, w_after].min

      withdraw = ->(source, amount) do
        amt = amount.to_f
        return 0.0 unless source.present? && amt > 0.0
        avail = source.used.to_f
        taken = [avail, amt].min
        if taken > 0
          source.update!(used: (avail - taken).round(3))
        end
        taken
      end

      # Phần <= deadline: TỒN -> THÂM-NIÊN -> VỊ-TRÍ
      remain = delta_before
      remain -= withdraw.call(ton,       remain)
      remain -= withdraw.call(tham_nien, remain)
      remain -= withdraw.call(vi_tri,    remain)

      # Phần > deadline: THÂM-NIÊN -> VỊ-TRÍ (không TỒN)
      remain = delta_after
      remain -= withdraw.call(tham_nien, remain)
      remain -= withdraw.call(vi_tri,    remain)
    end
    # Tạo Mhistory dữ liệu nghỉ phép thay đổi
    def handle_cancel(holdetail, data)
      fields_to_check = %w[details itotal dtto dtfrom]

      fields_to_check.each do |field|
        old_value = holdetail.send(field)
        new_value = data[field]

        # Bạn có thể cần convert về cùng kiểu để so sánh cho chắc (ví dụ to_s)
        if old_value.to_s != new_value.to_s
          Mhistory.create(
            stable: "#{holdetail.class.table_name}$$$#{holdetail.id}",
            srowid: field,
            fvalue: old_value,
            tvalue: new_value,
            owner: session[:user_fullname],
          )
        end
      end
    end 

    def consume_leave(user_id, amount_to_consume, details)
      holiday = Holiday.find_by(user_id: user_id, year: Date.current.year)
      return false unless holiday
      holdetails = Holdetail.where(
        holiday_id: holiday.id,
        name: ["Phép tồn", "Phép thâm niên", "Phép theo vị trí", "HE"]
      ).index_by(&:name)

      return false if holdetails.blank?

      remain     = holdetails["Phép tồn"]
      seniority  = holdetails["Phép thâm niên"]
      position   = holdetails["Phép theo vị trí"]
      summer     = holdetails["HE"]

      used_remain    = remain&.used.to_f || 0
      used_seniority = seniority&.used.to_f || 0
      used_position  = position&.used.to_f || 0
      used_summer    = summer&.used.to_f || 0

      amount_remain    = remain&.amount.to_f || 0
      amount_seniority = seniority&.amount.to_f || 0

      remaining = amount_to_consume.to_f

      if holiday.holpros.count == 1
        remain.update(note: used_remain) if used_remain != 0
        seniority.update(note: used_seniority) if used_seniority != 0
        position.update(note: used_position) if used_position != 0
      end

      
      ActiveRecord::Base.transaction do
        valid_ton_days = valid_remain_days(details, remain&.dtdeadline)
        # 1. Trừ Phép tồn (không vượt amount và còn hạn)
        if valid_ton_days > 0
          available_remain = [amount_remain - used_remain, 0].max
          to_use = [remaining, valid_ton_days, available_remain].min
          remain.used = format_used(used_remain + to_use)
          remain.save!
          remaining -= to_use
        end
        #2. Trừ Phép theo mùa hè (nếu là BMU hoặc BMTU)
        uorg = Uorg.joins(:organization).where(user_id: user_id).first
        if !uorg.nil?
          if uorg.organization.scode == "BMU" || uorg.organization.scode == "BMTU"
             if summer
              available_summer = [amount_summer - used_summer, 0].max
              to_use = [remaining, available_summer].min
              summer.used = format_used(used_summer + to_use)
              summer.save!
              remaining -= to_use
            end
          end
        end
        # 3. Trừ Phép thâm niên (không vượt amount)
        if seniority
          available_seniority = [amount_seniority - used_seniority, 0].max
          to_use = [remaining, available_seniority].min
          seniority.used = format_used(used_seniority + to_use)
          seniority.save!
          remaining -= to_use
        end
        # 4. Trừ Phép theo vị trí (được phép vượt amount)
        if position && remaining > 0
          position.used = format_used(used_position + remaining)
          position.save!
          remaining = 0
        end
      end
      true
    end

    def valid_remain_days(details, dtdeadline)
      valid_ton_days = 0.0
      deadline_date = dtdeadline.present? ? Date.parse(dtdeadline.to_s) : nil

      if deadline_date
        details.each do |detail_str|
          entries = detail_str.split("$$$")
          entries.each do |entry|
            date_str, part = entry.split("-")
            begin
              date = Date.strptime(date_str.strip, "%d/%m/%Y")
              next unless date <= deadline_date

              valid_ton_days += case part&.strip
                                when "ALL" then 1.0
                                when "AM", "PM" then 0.5
                                else 0.0
                                end
            rescue ArgumentError
              next
            end
          end
        end
      end
      valid_ton_days
    end

    def format_used(value)
      value % 1 == 0 ? value.to_i : value.round(2)
    end
    
    def delete_leave_request
      begin
        holpros_id = params[:holpros_id]
        holpro = Holpro.where(id: holpros_id).first
        if !holpro.nil?
          holiday = Holiday.where(id: holpro.holiday_id).first
          amount_to_consume = Holprosdetail.where(holpros_id: holpro.id, sholtype: ["NGHI-PHEP", "NGHI-CHE-DO"])
          details = amount_to_consume.pluck(:details)
          holpro.destroy
        end
        redirect_to :back, notice: "Xóa đơn nghỉ thành công!"
      rescue Exception => e
        redirect_to :back, alert: "Xóa đơn nghỉ không thành công!" + e.inspect
      end
    end

    def revert_leave(user_id, amount_to_remove, details,holpros_id)
      holiday = Holiday.find_by(user_id: user_id, year: Date.current.year)
      return false unless holiday

      holdetails = Holdetail.where(
        holiday_id: holiday.id,
        name: ["Phép tồn", "Phép thâm niên", "Phép theo vị trí"]
      ).index_by(&:name)

      return false if holdetails.blank?

      remain     = holdetails["Phép tồn"]
      seniority  = holdetails["Phép thâm niên"]
      position   = holdetails["Phép theo vị trí"]

      used_remain    = remain&.used.to_f || 0
      used_remain_current    = remain&.note.to_f || 0
      used_seniority = seniority&.used.to_f || 0
      used_position  = position&.used.to_f || 0
      amount_remain  = remain&.amount.to_f || 0

      ton_deadline      = remain&.dtdeadline&.strftime("%d/%m/%Y")
      ton_deadline_date = Date.strptime(ton_deadline, "%d/%m/%Y") rescue nil
      # --- Tách ngày trước & sau deadline ---
      deadline_date = remain&.dtdeadline&.to_date

      dates_before, dates_after = [], []
      holpros_da_duyet   = Holpro.where(holiday_id: holiday.id, status: ["DONE", "CANCEL-DONE"]).where.not(id: holpros_id)
      holpros_ids        = holpros_da_duyet.pluck(:id)
      extra_holpros_ids = Holpro.joins(:holprosdetails)
                            .where(holiday_id: holiday.id)
                            .where(holprosdetails: { sholtype: ["NGHI-PHEP", "NGHI-CHE-DO"], status: "DONE" })
                            .where.not(id: holpros_ids)
                            .distinct
                            .pluck(:id)
      all_holpros_ids = holpros_ids + extra_holpros_ids
      holpros_details    = Holprosdetail.where(holpros_id: all_holpros_ids, sholtype: ["NGHI-PHEP", "NGHI-CHE-DO"])


      all_leave_dates = holpros_details.map(&:details).compact.flat_map { |d| d.split('$$$') }.map do |item|
        date_part, session = item.split('-').map(&:strip)
        date = Date.strptime(date_part, '%d/%m/%Y') rescue nil
        next nil unless date
        weight = case session&.upcase
                when 'ALL', nil then 1.0
                when 'AM', 'PM'  then 0.5
                else 0
                end
        [date, weight]
      end.compact

      leave_dates_before_deadline = all_leave_dates.select { |date, _| date <= ton_deadline_date }
      phep_ton_da_dung_thuc_te    = leave_dates_before_deadline.sum { |_, weight| weight }
      details.each do |detail_str|
        detail_str.split("$$$").each do |entry|
          date_str, part = entry.split("-")
          begin
            date = Date.strptime(date_str.strip, "%d/%m/%Y")
            duration = case part&.strip
                      when "ALL" then 1.0
                      when "AM", "PM" then 0.5
                      else 0.0
                      end
            if deadline_date && date <= deadline_date
              dates_before << duration
            else
              dates_after << duration
            end
          rescue ArgumentError
            next
          end
        end
      end

      total_before = dates_before.sum
      total_after  = dates_after.sum
      skip_restore_remain = used_remain_current == amount_remain || (used_remain_current + phep_ton_da_dung_thuc_te) >= amount_remain

      ActiveRecord::Base.transaction do
        remaining_before = total_before
        remaining_after  = total_after

        # =====================================================
        # 1. Trả lại phần <= deadline
        # =====================================================
        if remaining_before > 0
          restore_from_seniority_first =
            (seniority&.used.to_f > 0) || (position&.used.to_f > 0)

          if restore_from_seniority_first
            # --- THÂM NIÊN ---
            if seniority && seniority.used.to_f > 0 && remaining_before > 0
              to_restore = [remaining_before, seniority.used.to_f].min
              seniority.update!(used: seniority.used.to_f - to_restore)
              remaining_before -= to_restore
            end

            # --- VỊ TRÍ ---
            if position && position.used.to_f > 0 && remaining_before > 0
              to_restore = [remaining_before, position.used.to_f].min
              position.update!(used: position.used.to_f - to_restore)
              remaining_before -= to_restore
            end

            # --- PHÉP TỒN ---
            if remain && remain.used.to_f > 0 && remaining_before > 0 && !skip_restore_remain
              to_restore = [remaining_before, remain.used.to_f].min
              remain.update!(used: remain.used.to_f - to_restore)
              remaining_before -= to_restore
            end

          else
            # Logic cũ: TỒN → THÂM NIÊN → VỊ TRÍ

            if remain && remain.used.to_f > 0 && remaining_before > 0 && !skip_restore_remain
              to_restore = [remaining_before, remain.used.to_f].min
              remain.update!(used: remain.used.to_f - to_restore)
              remaining_before -= to_restore
            end

            if seniority && seniority.used.to_f > 0 && remaining_before > 0
              to_restore = [remaining_before, seniority.used.to_f].min
              seniority.update!(used: seniority.used.to_f - to_restore)
              remaining_before -= to_restore
            end

            if position && position.used.to_f > 0 && remaining_before > 0
              to_restore = [remaining_before, position.used.to_f].min
              position.update!(used: position.used.to_f - to_restore)
              remaining_before -= to_restore
            end
          end
        end

        # =====================================================
        # 2. Trả lại phần > deadline
        # =====================================================

        # THÂM NIÊN
        if seniority && seniority.used.to_f > 0 && remaining_after > 0
          to_restore = [remaining_after, seniority.used.to_f].min
          seniority.update!(used: seniority.used.to_f - to_restore)
          remaining_after -= to_restore
        end

        # VỊ TRÍ
        if position && position.used.to_f > 0 && remaining_after > 0
          to_restore = [remaining_after, position.used.to_f].min
          position.update!(used: position.used.to_f - to_restore)
          remaining_after -= to_restore
        end

        # PHÉP TỒN
        if remain && remain.used.to_f > 0 && remaining_after > 0
          to_restore = [remaining_after, remain.used.to_f].min
          remain.update!(used: remain.used.to_f - to_restore)
          remaining_after -= to_restore
        end
      end

    end

    def delete_detail
      holdetail_id = params[:holdetail_id]
      holdetail = Holprosdetail.where(id: holdetail_id).first
      if !holdetail.nil?
        holdetails_current = Holprosdetail.where(holpros_id: holdetail.holpros_id)
        if holdetails_current.size == 1
          
        else
          
        end
      end
    end
    # h.a
    # 23/01/2026
    # update: check ngày nghỉ trong tất cả đơn
    def dates_leaved
      current_year = Date.current.year
      user_id = session[:user_id]

      holidays = Holiday.where(
        year: [current_year, current_year - 1],
        user_id: user_id
      )

      holpros = Holpro.where(holiday_id: holidays.pluck(:id)).where.not(status: ["REFUSE", "CANCEL"])

      holprosdetails = Holprosdetail.where(holpros_id: holpros.pluck(:id))

      dates = holprosdetails.pluck(:details).flat_map do |item|
        item.to_s.split('$$$').map do |part|
          date_str, session = part.split('-', 2)

          begin
            date = Date.strptime(date_str, '%d/%m/%Y')
            date.year == current_year ? [date_str, session] : nil
          rescue ArgumentError
            nil
          end
        end.compact
      end
      render json: dates
    end

    def process_handle
      holpros_id = params[:holpros_id]
      holpros = Holpro.find_by(id: holpros_id)
      holdetails = holpros.holprosdetails
      holiday = Holiday.find_by(id: holpros.holiday_id)
      user = holiday.user
      full_name = "#{user.last_name} #{user.first_name}"
      holdetails = holdetails.map do |detail|
        holtype = Holtype.where(code: detail.sholtype).first
        issued_place = detail.issued_place&.split("$$$") || []
        if issued_place.length != 1
          nationality = Nationality.where(scode: issued_place[0]).first
          nationality_name = nationality&.name
          region_type = issued_place[1]
        else
          region_type = issued_place[0]
          nationality_name = ""
        end
        detail.attributes.merge(
          region_type: region_type,
          issued_place: nationality_name,
          holstype: holtype&.name,
          note: detail.note.gsub("\n", "<br>").html_safe ,
          full_name: full_name,
        )
      end

      mandocs = Mandoc.joins(mandocdhandles: :mandocuhandles)
                      .where(holpros_id: holpros_id)
                      .where.not(mandocuhandles: {srole: "SUB"})
					            .select("
                        mandocdhandles.department_id, 
                        mandocdhandles.srole AS dhandle_srole, 
                        mandocdhandles.status AS dhandle_status, 
                        mandocuhandles.user_id, 
                        mandocuhandles.srole AS mandocuhandles_srole, 
                        mandocuhandles.updated_at as mandocuhandles_updated_at, 
                        mandocuhandles.status AS uhandle_status, 
                        mandocuhandles.mandocdhandle_id,
                        mandocs.status as mandoc_status,
                        mandocs.id as mandoc_id
                      ")
                      .group_by(&:mandoc_id)

      process_handle = mandocs.map do |mandoc_id, rows|
        index = 0
        {
          id: mandoc_id,
          status: rows.first.mandoc_status,
          process_handle: rows.map { |data|
            index += 1
            department = Department.find_by(id: data.department_id)
            user = User.find_by(id: data.user_id)
            work = Work.where(user_id: data.user_id, stask_id: nil, gtask_id: nil).where.not(positionjob_id: nil).first
            title_step_process =
            if data.mandoc_status&.include?("CANCEL")
              index == 1 ? "Đăng ký hủy đơn" : "Phê duyệt"
            else
              index == 1 ? "Đăng ký đơn" : "Phê duyệt"
            end

            {
              title_step_process: title_step_process, 
              department_name: department&.name,
              uhandle_status: data.uhandle_status,
              users: user ? [{user_name: "#{user.last_name} #{user.first_name}", position_name: work&.positionjob&.name}] : [],
              updated_at: data.mandocuhandles_updated_at.in_time_zone('Asia/Ho_Chi_Minh').strftime("%d/%m/%Y - %H:%M"),
            }
          }
        }
      end
      render json: {
        holdetails: holdetails,
        process_handle: process_handle,
        holpros: holpros
      }
    end

    def fetchStaffForWorkflow
      user_id = params[:user_id].present? ? params[:user_id] : session[:user_id]
      stype = params[:stype]
      leader_roles = ["trưởng","trưởng", "phó", "giám đốc", "hiệu", "chánh", "chủ tịch", "phụ trách"]

      next_user_to_handle = []
      users_have_access = []
      department_id = ""
      check_bgd = false
      if (session[:organization] & ["BMU", "BMTU"]).any?
        department_ids = handle_in_bmu(user_id)[:department_ids]
        users_have_access = handle_in_bmu(user_id)[:users_have_access]
        send_to = nil
      else
        department_ids = handle_in_buh(user_id)[:department_ids]
        users_have_access = handle_in_buh(user_id)[:users_have_access]
        send_to = handle_in_buh(user_id)[:send_to]
      end
      
      next_user_to_handle = Work.left_outer_joins({positionjob: :department}, :user)
                              .where("positionjobs.name LIKE ? OR positionjobs.name LIKE ? OR positionjobs.name LIKE ? OR positionjobs.name LIKE ? OR positionjobs.name LIKE ?", "%trưởng%", "%phó%", "%giám đốc%", "%chủ tịch%", "chánh")
                              .where(positionjobs: {department_id: department_ids})
                              .where.not("users.status = ? OR users.staff_status = ?", "INACTIVE", "Nghỉ việc")
                              .pluck("positionjobs.department_id", "positionjobs.name",  "departments.name as department_name", "works.user_id", "CONCAT(users.last_name, ' ', users.first_name) as name").uniq
                              .map { |department_id, position_name, department_name, user_id, name| { department_id: department_id, position_name: position_name, department_name: department_name, user_id: user_id, name: name } }
    
      next_user_to_handle = next_user_to_handle + users_have_access
      
      next_user_to_handle = next_user_to_handle.flatten.reject(&:empty?)
      
      if stype == "ON-LEAVE"
        next_user_to_handle = next_user_to_handle.uniq.reject { |user| user[:user_id] == session[:user_id] }
      else
        next_user_to_handle = next_user_to_handle.uniq
      end
      render json: {users: next_user_to_handle.flatten, send_to: send_to}
    end
    # end
    def handle_in_buh(user_id)
      users_have_access = []
      department_ids = []
      send_to = nil
      leader_roles = ["trưởng","trưởng", "phó", "giám đốc", "hiệu", "chánh", "chủ tịch", "phụ trách"]

      # lấy danh sách positionjob_id và department_id của users
      positionjob_department_ids = get_positionjob_department_ids_of_user(user_id)[:valid].uniq
      positionjob_department_ids.each do |data|

        department = Department.find_by(id: data[1])

        position_job = Positionjob.find_by(id: data[0])
        
        # Kiểm tra đơn vị có lãnh đạo không?
        check_have_leader = get_users_have_access_handle(data[1])

        # Kiểm tra đơn vị nhân sự có quyền duyệt phép hay không 
        is_leader = check_permission_approve_leave(user_id).present?

        # 
        parent_id = department.parents
        parent = Department.find_by(id: parent_id)
        if parent.present? && parent.status == "1"
          # lấy parent gần nhất với status active
          valid_parent_id = find_valid_parent_id_recursive(parent.id)
        else
          # Lấy parent hiện tại
          valid_parent_id = parent_id
        end

        # Kiểm tra nhân sự có trong danh sách này không? Nếu có trong danh sách quyền mặc định là lãnh đạo phòng
        if is_leader.present?
          if valid_parent_id.nil? || valid_parent_id == ""
            # Đối với đơn vị không có đơn vị cha
            case department.faculty
            when "BGD(BUH)"
              is_director = check_permission_director(user_id)
              if is_director
                # mặc định nếu là ban giám đốc thì submit luôn check client
              else
                # gửi cho giám đốc
                # users_have_access << get_users_have_access_handle(department.id, "ADM", "LEAVE-BGD")
                # kiểm tra theo vị trí 
                nextStepData = stream_connect_by_status("DUYET-PHEP-BUH", "TCHC-APPROVE")
                users_have_access << get_users_have_access_handle(nextStepData.first[:next_department_id], "READ")
                send_to = "TCHC"
              end
            when "PTCHC(BUH)"
              # Nếu là phòng TC hành chỉnh thì gửi cho ban giám đốc
              nextStepData = stream_connect_by_status("DUYET-PHEP-BUH", "BOARD-APPROVE")
              department_ids << nextStepData.first[:next_department_id]
            else 
              # Nếu là trưởng phòng đơn vị thì gửi cho trưởng/phó TCHC và nhân sự có quyền
              nextStepData = stream_connect_by_status("DUYET-PHEP-BUH")
              # department_ids << nextStepData.first[:next_department_id]
              users_have_access << get_users_have_access_handle(nextStepData.first[:next_department_id], "READ")
              send_to = "TCHC"
            end
          else
            # Tìm đơn vị cha
            # department_ids << valid_parent_id.to_i
            users_have_access << get_users_have_access_handle(valid_parent_id.to_i)
          end
        else
          if check_have_leader.present?
            # Đối với nhân sự thì gửi cho trưởng/phó đơn vị
            # department_ids << department.id
            # Lấy nhân sự có quyền
            users_have_access << get_users_have_access_handle(department.id)
          elsif !valid_parent_id.nil? || valid_parent_id != ""
            # Tìm đơn vị cha
            # department_ids << valid_parent_id.to_i
            users_have_access << get_users_have_access_handle(valid_parent_id.to_i)
          end
        end
      end
      {department_ids: department_ids, users_have_access: users_have_access, send_to: send_to}
    end

    def find_valid_parent_id_recursive(parent_id, seen_ids = [])
      return "" if parent_id.nil?
      return "" if seen_ids.include?(parent_id)

      seen_ids << parent_id

      parent = Department.find_by(id: parent_id)
      return "" if parent.nil?

      return parent.id if parent.status != "1"

      find_valid_parent_id_recursive(parent.parents, seen_ids)
    end



    def user_in_bgd?(user_id)
      # Lấy tất cả positionjob_id của user
      positionjob_ids = Work.where(user_id: user_id)
                            .where.not(positionjob_id: nil)
                            .pluck(:positionjob_id)

      # Lấy tất cả department_id từ positionjob
      department_ids = Positionjob.where(id: positionjob_ids)
                                  .pluck(:department_id)

      # Tìm phòng ban có faculty == "BGD(BUH)"
      bgd_department = Department.where(id: department_ids, faculty: "BGD(BUH)").first

      # Trả về [boolean, department_id hoặc nil]
      [bgd_department.present?, bgd_department&.id]
    end


    def handle_in_bmu(user_id)
      users_have_access = []
      department_ids = []
      leader_roles = ["trưởng","trưởng", "phó", "giám đốc", "hiệu", "chánh", "chủ tịch", "phụ trách"]

      positionjob_department_ids = get_positionjob_department_ids_of_user(user_id)[:valid].uniq

      positionjob_department_ids.each do |data|
        department = Department.find_by(id: data[1])

        position_job = Positionjob.find_by(id: data[0])
  
        # Kiểm tra đơn vị có lãnh đạo không?
        has_leader_role = check_have_leader(department.id, leader_roles)
        # 
        normalized_name = position_job.name.downcase.unicode_normalize(:nfkc)

        # Kiểm tra người tạo có phải là phó phòng?
        check_pho = normalized_name.include?("phó".unicode_normalize(:nfkc))
  
        # Kiểm tra người tạo có phải là trưởng phòng?
        # check_leader = leader_roles.any? { |item| normalized_name.include?(item.unicode_normalize(:nfkc)) }
        check_leader = leader_roles.any? do |item|
          normalized_item = item.downcase.unicode_normalize(:nfkc)
          normalized_name.include?(normalized_item) && !normalized_name.include?("phó trưởng") && !normalized_name.include?("phó chánh")
        end

        parent_id = department.parents
        parent = Department.find_by(id: parent_id)
        if parent.present? && parent.status == "1"
          # lấy parent gần nhất với status active
          valid_parent_id = find_valid_parent_id_recursive(parent.id)
        else
          # Lấy parent hiện tại
          valid_parent_id = parent_id
        end
        # check là trưởng phòng và không phải leader
        if !check_leader
          if !has_leader_role
            # Không có lãnh đạo
            if valid_parent_id.nil? || valid_parent_id == ""
              # nếu không có leader và không có parent
              nextStepData = stream_connect_by_status("DUYET-PHEP-BMU", "BOARD-APPROVE")
              department_ids << nextStepData.first[:next_department_id]
            else
              # bộ phận không có leader
              # Tìm đơn vị cha
              department_ids << valid_parent_id.to_i
            end
          else
            # có lãnh đạo
            base_query = Work.joins({positionjob: :department}, :user)
                                    .where(positionjobs: {department_id: position_job.department_id})
                                    .where.not("users.status = ? OR users.staff_status = ?", "INACTIVE", "Nghỉ việc")
  
            # nếu là phó phòng
            if check_pho
              base_query = base_query.where("positionjobs.name LIKE :truong OR positionjobs.name LIKE :chanh", truong: "%trưởng%", chanh: "%chánh%")
                                      .where.not("positionjobs.name LIKE :pho_truong OR positionjobs.name LIKE :pho_chanh", pho_truong: "%phó trưởng%", pho_chanh: "%phó chánh%")
              if !base_query.present?
                # Không có trưởng đơn vị gửi cho ban giám hiệu
                nextStepData = stream_connect_by_status("DUYET-PHEP-BMU", "BOARD-APPROVE")
                department_ids << nextStepData.first[:next_department_id]
                base_query = []
              end
            end
  
            # Nếu không phải là leader
            base_query = base_query.where("positionjobs.name LIKE ? OR positionjobs.name LIKE ? OR positionjobs.name LIKE ? OR positionjobs.name LIKE ?", "%trưởng%", "%phó%", "%giám đốc%", "%chánh%") if !check_leader && base_query.present?
  
            # Lấy thông tin users
            users_have_access << base_query.pluck("positionjobs.department_id", "positionjobs.name", "departments.name as department_name", "works.user_id", "CONCAT(users.last_name, ' ', users.first_name) as name")
                                          .map { |department_id, position_name, department_name, user_id, name| { department_id: department_id, position_name: position_name, department_name: department_name, user_id: user_id, name: name } }
          end
        else
          # nếu không có parent
          if valid_parent_id.nil? || valid_parent_id == ""
            # nếu là hiệu trưởng
            check_principal = normalized_name == "hiệu trưởng".unicode_normalize(:nfkc)
            if check_principal
              nextStepData = stream_connect_by_status("NGHI-PHEP-HIEU-TRUONG", "APPROVE")
              department_ids << nextStepData.map { |item| item[:next_department_id] || item["next_department_id"] }
            else
              # Nếu là trưởng phòng thì gửi cho ban giám hiệu
              nextStepData = stream_connect_by_status("DUYET-PHEP-BMU", "BOARD-APPROVE")
              department_ids << nextStepData.first[:next_department_id]
            end
          else
            # bộ phận không có leader
            # Tìm đơn vị cha
            department_ids << valid_parent_id.to_i
          end
        end
      end

      {department_ids: department_ids, users_have_access: users_have_access.flatten.uniq}
    end

    def check_have_leader(department_id, leader_roles)
      # lấy danh sách vị trí công việc của đơn vị
      works = Work.joins(:positionjob).where(positionjobs: {department_id: department_id})

      # Lấy tên các vị trí công việc của đơn vị
      all_position_jobs = Positionjob.where(id: works.pluck(:positionjob_id)).pluck(:name)

      # Kiểm tra đơn vị có lãnh đạo không?
      has_leader_role = all_position_jobs.any? { |name| leader_roles.any? { |item| name.downcase.unicode_normalize(:nfkc).include?(item.unicode_normalize(:nfkc)) } }
    end

    def get_users_on_leave
      day_leaved = params[:day_leaved] || []
      render json: find_user_ids_by_detail_dates(day_leaved)
    end
    def find_user_ids_by_detail_dates(target_dates)
      patterns = target_dates.map { |date| "%#{date}%" }

      # Lọc trước bằng SQL
      filtered_details = Holprosdetail
        .includes(holpro: :holiday)
        .where(
          patterns
            .map { |pattern| "details LIKE ?" }
            .join(' OR '),
          *patterns
        )

      # Sau đó kiểm tra kỹ lại trong Ruby
      user_ids = []

      filtered_details.each do |detail|
        dates_in_detail = detail.details.split('$$$').map { |d| d.split('-').first }

        if (dates_in_detail & target_dates).any?
          user_ids << detail.holpro.holiday.user_id
        end
      end

      user_ids.uniq
    end
    def find_user_ids_by_detail_dates(target_dates)
      patterns = target_dates.map { |date| "%#{date}%" }

      # Lọc trước bằng SQL
      filtered_details = Holprosdetail
        .includes(holpro: :holiday)
        .where(
          patterns
            .map { |pattern| "details LIKE ?" }
            .join(' OR '),
          *patterns
        )

      # Sau đó kiểm tra kỹ lại trong Ruby
      user_ids = []

      filtered_details.each do |detail|
        dates_in_detail = detail.details.split('$$$').map { |d| d.split('-').first }

        if (dates_in_detail & target_dates).any?
          user_ids << detail.holpro.holiday.user_id
        end
      end

      user_ids.uniq
    end

    def get_days_leave
      user_id = params[:user_id]
      user_current = session[:user_id]
      if user_id.present?
        invalid_department_ids = get_positionjob_department_ids_of_user(user_id)[:invalid]
        department_invalid_ids = Department.get_all_related_departments(invalid_department_ids).uniq
        users_handover = Work.joins({positionjob: :department}, :user)
                              .where(positionjobs: { department_id: department_invalid_ids })
                              .where.not("users.status = ? OR users.staff_status = ?", "INACTIVE", "Nghỉ việc")
                              .pluck("positionjobs.department_id", "positionjobs.name", "departments.name as department_name", "works.user_id", "CONCAT(users.last_name, ' ', users.first_name) as name").uniq
                              .map { |department_id, position_name, department_name, user_id, name| { department_id: department_id, position_name: position_name, department_name: department_name, user_id: user_id, name: name } }

        works = Work.left_outer_joins(positionjob: :department).where(user_id: user_id).where.not(positionjob_id: nil).select("positionjobs.name as pname, departments.faculty as dfaculty")
        current_year = Date.current.year
        holiday = Holiday.where(year: current_year, user_id: user_id).first
        if !holiday.nil?
          holdetails = Holdetail.where(holiday_id: holiday&.id).index_by(&:name)
          
          remain     = holdetails["Phép tồn"]
          seniority  = holdetails["Phép thâm niên"]
          position   = holdetails["Phép theo vị trí"]
          summer   = holdetails["Phép hè"]
    
          total_amount = [seniority, position, summer].compact.sum { |h| h.amount.to_f }
          total_used   = [seniority, position, summer].compact.sum { |h| h.used.to_f }
          if remain.nil?
            remain_amount = 0
          else
            remain_amount = remain.amount.to_f - remain.used.to_f
          end
          total_leave = total_amount - total_used
    
          holpros = Holpro.where(holiday_id: holiday&.id).where.not(status: ["REFUSE", "CANCEL"])
          holprosdetails = Holprosdetail.where(holpros_id: holpros.pluck(:id))
          day_leaved = holprosdetails.pluck(:details)
          dates = holprosdetails.pluck(:details).flat_map do |item|
            item.split('$$$')
            .map { |part| part.split('-') }
          end
          check_per_bgd = Work.joins(stask: { accesses: :resource })
                                    .where(
                                      resources: { scode: "LEAVE-BGD" },
                                      works:     { user_id: [user_id, user_current] },
                                      accesses:  { permision: "ADM" }
                                    )
                                    .exists?
          render json: { total_leave: total_leave, remain_amount: remain_amount, dtdeadline: remain&.dtdeadline&.strftime("%d/%m/%Y") || "", days_leaved: dates, works: works, is_leader_buh: check_permission_approve_leave(user_id).present?, check_per_bgd: check_per_bgd, users_handover: users_handover}
        end
      end
    end

    def translate_status(status)
      case status
      when "TEMP"
          return "<div class='alert alert-secondary m-0 p-0 col-12 text-center fw-medium'>Lưu nháp</div>"
      when "PENDING"
          return "<div class='alert alert-warning m-0 p-0 col-12 text-center fw-medium'>Chờ xử lý</div>"
      when "PROCESSING"
          return "<div class='alert alert-warning m-0 p-0 col-12 text-center fw-medium'>Chờ xử lý</div>"
      when "DONE"
          return "<div class='alert alert-success m-0 p-0 col-12 text-center fw-medium'>Hoàn tất đơn</div>"
      when "REFUSE"
          return "<div class='alert alert-danger m-0 p-0 col-12 text-center fw-medium'>Từ chối</div>"
      when "CANCEL"
          return "<div class='alert alert-secondary m-0 p-0 col-12 text-center fw-medium'>Hủy</div>"
      when "CANCEL-TEMP"
          return "<div class='alert alert-secondary m-0 p-0 col-12 text-center fw-medium'>Lưu nháp</div>"
      when "CANCEL-PENDING"
          return "<div class='alert alert-warning m-0 p-0 col-12 text-center fw-medium'>Chờ xử lý hủy</div>"
      when "CANCEL-PROCESSING"
          return "<div class='alert alert-warning m-0 p-0 col-12 text-center fw-medium'>Chờ xử lý hủy</div>"
      when "CANCEL-DONE"
          return "<div class='alert alert-success m-0 p-0 col-12 text-center fw-medium'>Hoàn tất đơn hủy</div>"
      when "CANCEL-REFUSE"
          return "<div class='alert alert-danger m-0 p-0 col-12 text-center fw-medium'>Từ chối hủy</div>"
      else
          return status
      end
    end
    def get_list_user(holpros_id)
      oMandoc = Mandoc.find_by(holpros_id: holpros_id)
      return [] unless oMandoc
      list_Dhandle = Mandocdhandle.where(mandoc_id: oMandoc.id).pluck(:id)
      return [] if list_Dhandle.empty?
      Mandocuhandle.where(mandocdhandle_id: list_Dhandle).pluck(:user_id).uniq
    end
    def generated_leave_request
      holpro_id = 211
      holpro = Holpro.where(id: holpro_id).first
      data = []
      organization = session[:organization]
      department_name = session[:department_name]
      if !holpro.nil?
        holiday = Holiday.where(id: holpro.holiday_id).first
        user = User.joins(works: :positionjob)
                  .where(id: session[:user_id])
                  .where("works.positionjob_id IS NOT NULL")
                  .select("users.*, positionjobs.name")
                  .first
        
        holdetails = holpro.holprosdetails
        data = {user: user, holdetails: holdetails, organization: organization, department_name: department_name}
      end
      template = "don_xin_nghi_phep.html.erb"
      pdf_html = ActionController::Base.new.render_to_string(
        template: "templates/#{template}",
        locals: {
          :data => data,
        }
      )
      margin = { top: 10, bottom: 10, left: 10, right: 10 }
      pdf = WickedPdf.new.pdf_from_string(pdf_html,
        encoding: "UTF-8",
        margin: margin,
        page_size: 'A4',
        orientation: 'Portrait'
      )
      send_data pdf,  type: 'application/pdf',
                      disposition: 'attachment',
                      filename:"pdf_#{Time.now.strftime("%d%m%Y")}.pdf"
    end
end