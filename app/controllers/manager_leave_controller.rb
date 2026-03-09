class ManagerLeaveController < ApplicationController
    before_action :authorize
    include StreamConcern
    include AttendsHelper
    def position_leave
        scode_uorg = session[:organization]
        return (@positions = []; @count = 0; @total_pages = 0) if scode_uorg.blank?
      
        o_id = Organization.find_by(scode: scode_uorg)&.id
        list_ids = Department.where(organization_id: o_id).pluck(:id).uniq
      
        @departments = Department.where(organization_id: o_id)

        @query = params[:q].to_s.strip
        selected_department_id = params[:department_id].presence
        filtered_department_ids = selected_department_id ? [selected_department_id.to_i] : list_ids

        base_scope = Positionjob.includes(:department)
                                .where(department_id: filtered_department_ids)
                                .yield_self do |scope|
                                  if @query.present?
                                    scope.where("LOWER(name) LIKE :k OR LOWER(scode) LIKE :k", k: "%#{@query.downcase}%")
                                  else
                                    scope
                                  end
                                end


        @per_page = params[:per_page].to_i > 0 ? params[:per_page].to_i : 10
        @page = params[:page].to_i > 0 ? params[:page].to_i : 1
        @total_count = base_scope.count
        @total_pages = (@total_count / @per_page.to_f).ceil
        offset = (@page - 1) * @per_page
        @positions = base_scope.order(:name).offset(offset).limit(@per_page)
    end
       
    def staff_leave
        scode_uorg = session[:organization]
      
        if scode_uorg.blank?
          @leave_data = []
          @count_current = 0
          @total_pages = 0
          @list_department = []
          return
        end
      
        organization = Organization.find_by(scode: scode_uorg)
        return (@leave_data = []; @count_current = 0; @total_pages = 0; @list_department = []) if organization.nil?
      
        list_user = Uorg.joins(:user)
                        .where(organization_id: organization.id)
                        .where.not(user_id: nil)
                        .where(users: { status: "ACTIVE" })
                        .pluck(:user_id)
      
        department_id = params[:department]
        if department_id.present?
          department_obj = Department.find_by(id: department_id)
          if department_obj
            list_user = list_user.select do |user_id|
              Work.joins(positionjob: :department)
                  .where(user_id: user_id, positionjobs: { department_id: department_obj.id })
                  .exists?
            end
          end
        end
      
        @list_department = Department.where(organization_id: organization.id)
      
        @leave_data = []
        current_year = Time.current.year
        count_current = 0
        running_index = 1
      
        list_user.each do |user_id|
          data, needs_count = get_leave_data_by_user_id(user_id, running_index, current_year, "VIEW")
          next unless data.present?
      
          work = Work.includes(positionjob: :department)
                     .where(user_id: user_id)
                     .where.not(positionjob_id: nil)
                     .first
      
          data[:department_name] = work&.positionjob&.department&.name
          data[:position_name] = work&.positionjob&.name
      
          @leave_data << data
          running_index += 1
          count_current += 1 if needs_count
        end
      
        @count_current = count_current
      
        # Search
        if params[:search].present?
          keyword = params[:search].strip.downcase
          @leave_data = @leave_data.select do |item|
            item[:code].to_s.downcase.include?(keyword) ||
            item[:full_name].to_s.downcase.include?(keyword)
          end
        end
      
        # Pagination
        @per_page = params[:per_page].to_i.positive? ? params[:per_page].to_i : 10
        @page = params[:page].to_i.positive? ? params[:page].to_i : 1
        @total_pages = (@leave_data.size / @per_page.to_f).ceil
        @leave_data = @leave_data.slice((@page - 1) * @per_page, @per_page) || []
      end
      
    def save_all_leave_data
        begin
            scode_uorg = session[:organization] || "BUH"
            org = Organization.find_by(scode: scode_uorg)        
            uorgs = Uorg.joins(:user)
                        .where(organization_id: org.id)
                        .where.not(user_id: nil)
                        .where(users: { status: "ACTIVE" })
            user_ids = uorgs.pluck(:user_id)
            current_year = Time.current.year
            han_su_dung_date = Date.strptime("31/03/#{current_year}", "%d/%m/%Y")
            today = Date.today
        
            # Sử dụng xử lý theo nhóm
            ActiveRecord::Base.transaction do
                user_ids.in_groups_of(100, false) do |batch_user_ids|
                    users = User.where(id: batch_user_ids).index_by(&:id)
                    contracts = Contract.where(user_id: batch_user_ids).group_by(&:user_id)
                    works = Work.where(user_id: batch_user_ids).where.not(positionjob_id: nil).includes(:positionjob)
                    positions_by_user = works.index_by(&:user_id)
                    holidays_last = Holiday.where(user_id: batch_user_ids, year: current_year - 1).index_by(&:user_id)
                    holpros = Holpro.where(holiday_id: holidays_last.values.map(&:id), sholtype: "PHEP").group_by(&:holiday_id)
            
                    batch_user_ids.each do |user_id|
                        user = users[user_id]
                        next unless user
                
                        valid_contracts = (contracts[user_id] || []).reject { |c| c.name.to_s.downcase.include?("tập nghề") || c.name.to_s.downcase.include?("thử việc") }
                        start_year = valid_contracts.min_by { |c| c.dtfrom || Time.now }&.dtfrom&.year
                        next if start_year.nil?
                
                        diff_years = current_year - start_year
                        bien_tham_nien = tinh_moc_theo_doi(diff_years)
                
                        position = positions_by_user[user_id]&.positionjob
                        next unless position
                        bien_cong_viec = position.holno.to_i
                
                        holiday_last = holidays_last[user_id]
                        total_used = 0
                        if holiday_last
                            holpro_list = holpros[holiday_last.id] || []
                            total_used = holpro_list.map { |h| h.dttotal.to_f }.sum
                        end
                        bien_phep_ton = [bien_cong_viec - total_used, 0].max
                
                        phep_ton_duoc_tinh = today <= han_su_dung_date ? bien_phep_ton : 0
                        tong_phep = bien_cong_viec + bien_tham_nien + phep_ton_duoc_tinh
                        tong_phep = tong_phep % 1 == 0 ? tong_phep.to_i : tong_phep
                        existing_holiday = Holiday.find_by(user_id: user_id, year: current_year.to_s)
                        next if existing_holiday
                        # Tạo Holiday
                        holiday = Holiday.create!(
                            user_id: user_id,
                            year: current_year.to_s,
                            status: "ACTIVE",
                            total: tong_phep
                        )
                        [
                            ["Phép theo vị trí", bien_cong_viec, nil],
                            ["Phép thâm niên", bien_tham_nien, nil],
                            ["Phép tồn", bien_phep_ton, han_su_dung_date]
                        ].each do |name, amount, deadline|
                            next if amount.to_f <= 0
                            Holdetail.create!(
                                holiday_id: holiday.id,
                                name: name,
                                amount: amount,
                                dtdeadline: deadline
                            )
                        end
                    end
                end
            end
            flash[:success] = "Đã lưu dữ liệu thành công"
            redirect_to :back
        rescue => e
          flash[:error] = "Đã xảy ra lỗi khi lưu: #{e.message}"
          redirect_to :back
        end
    end
    def create_leave
        user_id = params[:user_id]
        phep_cv = params[:phep_cv].to_f
        phep_tn = params[:phep_tn].to_f
        phep_ton = params[:phep_ton].to_f
        han_sd_str = params[:han_sd]
        parsed_date = Date.strptime(han_sd_str, "%d/%m/%Y")
        tong_phep = phep_cv + phep_tn
        tong_phep += phep_ton if han_sd_str.present? && parsed_date >= Date.today
        begin

                holiday = Holiday.create!(
                    user_id: user_id,
                    year: Time.current.year.to_s,
                    status: "ACTIVE",
                    total: tong_phep
                )
                [
                    ["Phép theo vị trí", phep_cv, nil],
                    ["Phép thâm niên", phep_tn, nil],
                    ["Phép tồn", phep_ton, parsed_date]
                ].each do |name, amount, deadline|
                    next if amount.to_f < 0
                    Holdetail.create!(
                        holiday_id: holiday.id,
                        name: name,
                        amount: amount,
                        dtdeadline: deadline
                    )
                end
            flash[:success] = "Tạo đơn thành công cho nhân sự!"
        rescue => e
          flash[:error] = "Đã xảy ra lỗi: #{e.message}"
        end
        redirect_to :back
    end
    def update_leave
        user_id = params[:user_id]
        han_su_dung = params[:han_su_dung]
        current_year = Time.current.year
        begin
            parsed_date = Date.strptime(han_su_dung, "%d/%m/%Y")
            holiday = Holiday.where(user_id: user_id, year: current_year).first
            if holiday
                holdetail = Holdetail.where(holiday_id: holiday.id, name:"Phép tồn").first
                holdetail&.update!(dtdeadline: parsed_date)

                holdetails = Holdetail.where(holiday_id: holiday.id)
                total = calc_leave_total_by_details(holdetails)
                holiday.update!(total: total)

                flash[:success] = "Cập nhật thành công"
            else
                flash[:error] = "Nhân sự chưa có quản lý phép năm"
            end
        rescue => e
          flash[:error] = "Đã xảy ra lỗi khi cập nhật: #{e.message}"
        end
        redirect_to :back
    end
    def calc_leave_total_by_details(holdetails)
        total = 0
        today = Date.today
      
        holdetails.each do |detail|
          if detail.dtdeadline.present?
            total += detail.amount.to_f if detail.dtdeadline >= today
          else
            total += detail.amount.to_f
          end
        end
        total
    end
    
    # start phần xử lý phép
      def management
        current_tab = params[:current_tab]
        @data = []
        @data_tab_2 = []
        @data_tab_3 = []
        @depart = nil
        @faculty = nil
        @check_button = nil
        per_page = (params[:per_page] || 10).to_i
        page = (params[:page] || 1).to_i
        offset = (page - 1) * per_page
        status_search = params[:status]
        from_date, to_date = parse_daterange(params[:start_date], params[:end_date])
        if from_date.nil? && to_date.nil?
          today = Date.today
          from_date = today - 3.days
          to_date = today + 4.days
        end

        @departments = Department.where(organization_id: Organization.find_by(scode: "BUH")&.id, status: "0")
        if current_tab == "tab_1" || current_tab.blank?
          list_uhan = Mandocuhandle.joins(mandoc: :holpro).where(user_id: session[:user_id], status: "CHUAXULY" ).where.not(holpros: { id: nil }).where.not(holpros: { status: ["TEMP", "CANCEL"] })
          departments = fetch_leaf_departments_by_user(session[:user_id])

          oUserORG = Uorg.find_by(user_id: session[:user_id])
          organization_id = oUserORG.organization_id
          streams = Stream.joins("INNER JOIN operstreams ON operstreams.stream_id = streams.id")
                            .where(operstreams: { organization_id: organization_id })
                            .where("streams.scode LIKE ?", "%DUYET-PHEP-BUH%").first
          stream_id = streams&.id
          check_button = "none"
          if departments.present? && stream_id.present?
            department = departments.first
            if department&.parents.present?
              depart = department.parents
              faculty = department.faculty
            else
              exit_node = Node.where(stream_id:stream_id).where(department_id: department.id).first
              if exit_node.present?
                department_id = department.id
                faculty = department.faculty
                scode = "BOARD-APPROVE"
                check_button ="FINAL_HANDLE"
              else
                first_node = Node.where(stream_id: stream_id, nfirst: "YES").first
                department_id = first_node.department_id
                faculty = department.faculty
                scode = "HR-APPROVED"
                check_button ="FIRST_HANDLE"
              end
              result = stream_connect_by_status("DUYET-PHEP-BUH", scode)
              depart = result&.first&.dig(:next_department_id)
            end
            @depart = depart
            @faculty = faculty
            @check_button = check_button
          end
          raw_data = []
          list_uhan.each do |item|
            mandocdhandle = Mandocdhandle.find_by(id: item.mandocdhandle_id)
            mandoc = Mandoc.find_by(id: mandocdhandle&.mandoc_id)
            holpro = Holpro.find_by(id: mandoc&.holpros_id)
            
            holiday = Holiday.find_by(id: holpro&.holiday_id)
            details = get_leave_details(mandoc&.holpros_id)
            user_id = holiday&.user_id
            full_name, sid = get_user_info(user_id)
            full_name_handler, _ = get_user_info(session[:user_id])
            status =  if item.status == "CHUAXULY"
                        "Chưa xử lý"
                      else
                        "Đã xử lý"
                      end
            department_user = fetch_leaf_departments_by_user(user_id)
            department = department_user.first
            department_name = department&.name
            department_id = department&.id
            raw_data.push(
              user_id: user_id,
              uhandle_id: item.id,
              holpros_id: mandoc&.holpros_id,
              sender: full_name, 
              handler: full_name_handler, 
              department: department_name,
              department_id: department_id,
              time: time_ago_in_custom_format(item.created_at),
              sender_sid: sid,
              status: status,
              details: details,
              note: item.notes
              )
          end
          if params[:search].present?
            keyword = params[:search].strip.downcase
            raw_data.select! do |record|
              record[:sender].to_s.downcase.include?(keyword) ||
              record[:sender_sid].to_s.downcase.include?(keyword)
            end
          end

          if params[:department_id].present?
            raw_data.select! do |record|
              record[:department_id].to_s == params[:department_id].to_s
            end
          end
          @total_items = raw_data.size
          @total_pages = (@total_items / per_page.to_f).ceil
          @page = page
          @per_page = per_page
          @data = raw_data.slice(offset, per_page)
        elsif current_tab == "tab_2"
          department_user = fetch_leaf_departments_by_user(session[:user_id])
          status_search   = params[:status]
          department      = department_user.first
          department_id   = department&.id

          all_department_ids = fetch_all_related_department_ids([department_id])

          list_user = Work
            .where(positionjob_id: Positionjob.where(department_id: all_department_ids).pluck(:id))
            .pluck(:user_id)
            .uniq

          raw_data_tab_2 = []

          list_user.each do |user|
            full_name, sid = get_user_info(user)
            positionjob_name, department_name = fetch_position_and_department_name(user)

            # ✅ FIX 1: KHÔNG cố định theo năm hiện tại
            holidays = Holiday.where(user_id: user)
            next if holidays.blank?

            list_hols = Holpro
              .where(holiday_id: holidays.pluck(:id))
              .where.not(status: "TEMP")

            status_map = {
              "PROCESSING" => ["PROCESSING", "CANCEL-PENDING"],
              "DONE"       => ["DONE", "CANCEL-DONE"]
            }

            if status_search.present?
              statuses = status_map[status_search] || [status_search]
              list_hols = list_hols.where(status: statuses)
            end

            # ✅ FIX 2: group_by thay vì index_by
            details_map = Holprosdetail
              .where(holpros_id: list_hols.pluck(:id))
              .group_by(&:holpros_id)

            # ✅ FIX 3: filter ngày chỉ dựa trên details
            if from_date.present? && to_date.present?
              list_hols = list_hols.select do |hol|
                hol_details = details_map[hol.id]
                next false if hol_details.blank?

                hol_details.any? do |detail|
                  detail_overlap_range?(detail, from_date, to_date)
                end
              end
            end

            next if list_hols.blank?

            list_hols.each do |hol|
              raw_data_tab_2 << {
                holpros_id: hol.id,
                user_id: user,
                uhandle_id: hol.holiday.user_id,
                positionjob: positionjob_name,
                department: department_name,
                sender: full_name,
                sender_sid: sid,
                details: get_leave_details(hol.id),
                status: support_status(hol.status),
                created_at: hol.created_at
              }
            end
          end

          # 🔍 Search theo keyword
          if params[:search].present?
            keyword = params[:search].strip.downcase
            raw_data_tab_2.select! do |record|
              record[:sender].to_s.downcase.include?(keyword) ||
              record[:sender_sid].to_s.downcase.include?(keyword)
            end
          end

          # 📄 Sort + paginate
          raw_data_tab_2.sort_by! { |record| -record[:created_at].to_i }

          @total_items = raw_data_tab_2.size
          @total_pages = (@total_items / per_page.to_f).ceil
          @page        = page
          @per_page    = per_page
          @data_tab_2  = raw_data_tab_2.slice(offset, per_page)


        else
          raw_data_tab_3 = []
          idDs = Mandocuhandle.joins(mandoc: :holpro).where(user_id: session[:user_id], srole: "SUB" ).where.not(holpros: { id: nil }).pluck(:mandocdhandle_id)
          idMs = Mandocdhandle.where(id: idDs ).pluck(:mandoc_id)
          idHs = Mandoc.where(id: idMs).pluck(:holpros_id)
          status_search = params[:status]
          list_hols = Holpro.where(id: idHs).where.not(status: "TEMP")
          status_map = {
                "PROCESSING" => ["PROCESSING", "CANCEL-PENDING"],
                "DONE"       => ["DONE", "CANCEL-DONE"]
              }

          if status_search.present?
            statuses = status_map[status_search] || [status_search]
            list_hols = list_hols.where(status: statuses)
          end
          if list_hols.present?
            details_map = Holprosdetail.where(holpros_id: list_hols.pluck(:id)).index_by(&:holpros_id)
            if from_date && to_date
              list_hols = list_hols.select do |hol|
                hol_detail = details_map[hol.id]
                next false unless hol_detail.present?

                dates_in_detail = extract_dates_from_details_date_range(hol_detail.details)

                dates_in_detail.any? { |d| d >= from_date && d <= to_date }
              end
            end
            list_hols.each do |hol|
              oHol = Holiday.where(id: hol.holiday_id, year: Time.current.year).first
              if oHol.present?
                full_name, sid = get_user_info(oHol.user_id)
                positionjob_name, department_name = fetch_position_and_department_name(oHol.user_id)
                details = get_leave_details(hol.id)
                raw_data_tab_3.push(
                  holpros_id: hol.id,
                  user_id: oHol.user_id,
                  uhandle_id: oHol.user_id,
                  positionjob: positionjob_name,
                  department: department_name,
                  sender: full_name,
                  sender_sid: sid,
                  details: details,
                  status: support_status(hol.status),
                  created_at: hol.created_at
                  )
              end
            end
          end
          if params[:search].present?
            keyword = params[:search].strip.downcase
            raw_data_tab_3.select! do |record|
              record[:sender].to_s.downcase.include?(keyword) ||
              record[:sender_sid].to_s.downcase.include?(keyword)
            end
          end
          raw_data_tab_3.sort_by! { |record| -record[:created_at].to_i }
          @total_items = raw_data_tab_3.size
          @total_pages = (@total_items / per_page.to_f).ceil
          @page = page
          @per_page = per_page
          @data_tab_3 = raw_data_tab_3.slice(offset, per_page)
        end
      end
      def get_leave_details(holpros_id)
        holpros = Holpro.find_by(id: holpros_id)
        return [] unless holpros
        holpros_details = Holprosdetail.where(holpros_id: holpros.id)
        label_map = {
          "NGHI-PHEP" => "Nghỉ phép",
          "NGHI-KHONG-LUONG" => "Nghỉ không lương",
          "NGHI-CHE-DO-BAO-HIEM-XA-HOI" => "Nghỉ BHXH",
          "NGHI-CDHH" => "Nghỉ chế độ (Hiếu/Hỷ)"
        }
        grouped_by_type = holpros_details.group_by(&:sholtype)

        grouped_by_type.map do |stype, records|
          all_dates = records.flat_map do |record|
            record.details.to_s.split("$$$").map do |seg|
              Date.strptime(seg.split("-").first, "%d/%m/%Y") rescue nil
            end
          end.compact.uniq.sort
          ranges = []
          all_dates.each do |date|
            if ranges.empty? || ranges.last.last + 1 != date
              ranges << [date]
            else
              ranges.last << date
            end
          end
          formatted_ranges = ranges.map do |range|
            if range.size > 1
              "Từ #{range.first.strftime('%d/%m/%Y')} đến #{range.last.strftime('%d/%m/%Y')}"
            else
              range.first.strftime('%d/%m/%Y')
            end
          end
          {
            leave_type: label_map[stype] || stype.to_s.titleize,
            days: formatted_ranges
          }
        end
      end

      def support_status(status)
        change_status = if status == "PENDING"
            "Chưa xử lý"
          elsif status == "PROCESSING"
            "Đang xử lý"
          elsif status == "DONE"
            "Đã duyệt"
          elsif status == "CANCEL"
            "Đã hủy"
          elsif status == "CANCEL-PENDING"
            "Đơn đang điều chỉnh"
          elsif status == "CANCEL-DONE"
            "Đã duyệt(điều chỉnh)"
          else
            "Đơn bị từ chối"
        end
      end
      def extract_dates_from_details_date_range(details)
        return [] if details.blank?

        details.split('$$$').map do |item|
          date_str = item.split('-').first&.strip
          begin
            Date.strptime(date_str, "%d/%m/%Y")
          rescue
            nil
          end
        end.compact
      end
      def parse_daterange(start_str, end_str)
        return [nil, nil] if start_str.blank? || end_str.blank?
        begin
          from_date = Date.strptime(start_str, "%d/%m/%Y")
          to_date = Date.strptime(end_str, "%d/%m/%Y")
        rescue ArgumentError
          return [nil, nil]
        end

        [from_date, to_date]
      end
      def detail_overlap_range?(detail, from_date, to_date)
        extract_dates_from_details_date_range(detail.details).any? do |d|
          d >= from_date && d <= to_date
        end
      end

      def insurance_handover
        per_page = (params[:per_page] || 10).to_i
        page = (params[:page] || 1).to_i
        offset = (page - 1) * per_page

        org_filter = if (session[:organization] & ["BMU", "BMTU"]).any?
                      "BMU"
                    else
                      "BUH"
                    end
        user_ids = if org_filter == "BMU"
                      uorgs = Uorg.joins(:organization)
                                  .where("organizations.scode = ?", "BMU")
                                  .pluck(:user_id)
                      multi_uorg_users = Uorg.group(:user_id).having("COUNT(*) > 1").pluck(:user_id)
                      (uorgs + multi_uorg_users).uniq
                    else
                      Uorg.joins(:organization)
                          .where("organizations.scode = ?", "BUH")
                          .pluck(:user_id)
                    end
        scode_uorg = session[:organization]
        o_id = Organization.find_by(scode: scode_uorg)&.id
        @departments = Department.where(organization_id: o_id)
        # Tổng số bản ghi
        total_count = Holpro.joins(:holprosdetails)
                            .joins(holiday: :user)
                            .where(holidays: { user_id: user_ids })
                            .where(status: "DONE")
                            .where("holprosdetails.sholtype = ?", "NGHI-CHE-DO-BAO-HIEM-XA-HOI")
                            .distinct
                            .count

        @total_pages = (total_count / per_page.to_f).ceil
        @page = page
        @per_page = per_page

        @raw_data = Holpro.joins(:holprosdetails)
                          .joins(holiday: :user)
                          .where(holidays: { user_id: user_ids })
                          .where(status: "DONE")
                          .where("holprosdetails.sholtype = ? ", "NGHI-CHE-DO-BAO-HIEM-XA-HOI")
                          .select(
                            "holpros.id AS holpro_id",
                            "holpros.status AS holpro_status",
                            "holprosdetails.id AS detail_id",
                            "holprosdetails.details AS detail_details",
                            "holprosdetails.status AS detail_status",
                            "holprosdetails.note AS detail_note",
                            "users.id AS user_id",
                            "users.sid AS user_sid",
                            "users.first_name AS user_first_name",
                            "users.last_name AS user_last_name"
                          )
                          .distinct
                          .limit(per_page)
                          .offset(offset)
        if params[:department_id].present?
          dep_id = params[:department_id].to_i
          @raw_data = @raw_data.select do |row|
            fetch_leaf_departments_by_user(row.user_id).map(&:id).include?(dep_id)
          end
        end


        if params[:keyword].present?
          keyword = "%#{params[:keyword].strip.downcase}%"
          @raw_data = @raw_data.where("LOWER(users.sid) LIKE ? OR LOWER(CONCAT(users.last_name, ' ', users.first_name)) LIKE ?", keyword, keyword)
        end
        @data = @raw_data.map do |item|
          full_name = "#{item.user_last_name} #{item.user_first_name}"
          position_name, department_name = fetch_position_and_department_by_user(item.user_id)
          parsed_details = parse_leave_details(item.detail_details)
          json_details = parse_leave_details_json(item.detail_details, item.detail_id)
          holpro_status = if item.holpro_status == "EDIT"
            "Đang chỉnh sửa"
          else
            "Đã duyệt"
          end
          if item.holpro_status == "EDIT"
            check_button = true
          else
            check_button = false
          end
          mhis_all = Mhistory.where(stable: "Holprosdetail$$$#{item.detail_id}$$$CHANGE")
          his_button = mhis_all.exists?
          change_logs = []
          change_all = []

          if his_button && %w[EDIT DONE].include?(item.holpro_status)
            change_all = mhis_all.order(created_at: :desc).map do |c|
              {
                key: c.srowid,
                from: c.fvalue,
                to: c.tvalue,
                by: c.owner,
                cre: c.created_at&.strftime("%d/%m/%Y")
              }
            end

            # Lấy những bản ghi có thời điểm gần nhất
            last_time = mhis_all.maximum(:created_at)
            last_changes = mhis_all.where(created_at: last_time)

            change_logs = last_changes.map do |c|
              {
                key: c.srowid,
                from: c.fvalue,
                to: c.tvalue,
                by: c.owner,
                cre: c.created_at&.strftime("%d/%m/%Y")
              }
            end
          end

          mHis = Mhistory.where(stable: "Holprosdetail$$$#{item.detail_id}$$$CHANGE")
          his_button = false
          change_logs = []

          if mHis.exists? && %w[EDIT DONE].include?(item.holpro_status)
            his_button = true

            if item.holpro_status == "EDIT"
              last_time = mHis.maximum(:created_at)
              filtered_logs = mHis.where(created_at: last_time)
            else
              filtered_logs = mHis
            end

            change_logs = filtered_logs.order(created_at: :desc).map do |c|
              {
                key: c.srowid,
                from: c.fvalue,
                to: c.tvalue,
                by: c.owner,
                cre: c.created_at&.strftime("%d/%m/%Y")
              }
            end
          end

          OpenStruct.new(
            sid: item.user_sid,
            full_name: full_name,
            position_name: position_name,
            department_name: department_name,
            detail_id: item.detail_id,
            detail_status: item.detail_status,
            detail_note: item.detail_note,
            detail_details: parsed_details,
            detail_details_json: json_details,
            holpro_id: item.holpro_id,
            holpro_status: holpro_status,
            check_button: check_button,
            his_button: his_button,
            change_logs: change_logs,
            change_all: change_all
          )
        end
      end

      def submit_leave_changes
        changes = params[:changes] || []
        hol_id = params[:hol_id]
        reason = params[:reason]
        user_email = session[:user_email_login] || "unknown"

        detail_groups = changes.group_by { |c| c[:detail_id] }

        mhistory_records = []
        affected_details = {}

        # Ghi nhận thay đổi và gom lại chi tiết bị tác động
        detail_groups.each do |detail_id, grouped_changes|
          detail_id_int = detail_id.to_i
          old_detail = Holprosdetail.find_by(id: detail_id_int)
          next unless old_detail

          old_items = parse_details_string_to_map(old_detail.details.to_s)
          affected_details[detail_id_int] = old_detail

          grouped_changes.each do |change|
            change_dates = change[:change_date].to_s.split("$$$")
            new_types = change[:type_change].to_s.split("$$$")

            change_dates.each_with_index do |date_shift, idx|
              key = date_shift
              new_type = new_types[idx]
              old_type = old_items[key] || "NGHI-CHE-DO-BAO-HIEM-XA-HOI"

              next if old_type == new_type

              mhistory_records << Mhistory.new(
                stable: "Holprosdetail$$$#{detail_id}$$$CHANGE",
                srowid: key,
                fvalue: old_type,
                tvalue: new_type,
                owner: user_email,
                created_at: Time.zone.now,
                updated_at: Time.zone.now
              )
            end
          end
        end

        Mhistory.transaction do
          mhistory_records.each(&:save!)
          affected_details.each do |detail_id, old_detail|
            approve_change(detail_id, reason)
          end
          if hol_id.present?
            holpro = Holpro.where(id: hol_id).first
            if holpro.present?
              holpro.update(status: "DONE")
              stype_label_map = {
                "NGHI-CHE-DO-BAO-HIEM-XA-HOI" => "nghỉ BHXH",
                "NGHI-PHEP" => "Nghỉ phép",
                "NGHI-KHONG-LUONG" => "Nghỉ không lương"
              }
              grouped_changes = mhistory_records.group_by(&:tvalue)

              change_lines = grouped_changes.map do |tval, records|
                label = stype_label_map[tval] || tval.titleize
                days = records.map(&:srowid).map { |d| Date.strptime(d, "%d/%m/%Y") rescue nil }.compact.sort
                formatted_days = days.map { |d| d.strftime("%d/%m") }.join(", ")
                "Điều chỉnh ngày #{formatted_days} thành #{label}"
              end
              if change_lines.any?
                content = <<~TEXT
                  Nội dung điều chỉnh:
                  #{change_lines.join("\n")}
                TEXT
              else
                content = "Không có điều chỉnh cụ thể được ghi nhận."
              end

              new_notify = Notify.create!(
                title: "Điều chỉnh nghỉ BHXH",
                contents: content,
                receivers: "Hệ thống ERP",
                stype: "LEAVE_REQUEST"
              )
              uid = holpro.holiday.user_id
              Snotice.create!(
                notify_id: new_notify.id,
                user_id: uid,
                isread: false
              )
              Snotice.create!(
                notify_id: new_notify.id,
                user_id: session[:user_id],
                isread: false
              )
              if (user = User.find_by(id: uid))&.email.present?
                UserMailer.send_mail_leave_change(user.email, content).deliver_later
              end
            end
          end
        end
        
        render json: { status: "ok", message: "Đã lưu và xử lý điều chỉnh thành công" }

      rescue => e
        render json: {
          status: "error",
          message: e.message,
          error_class: e.class.name,
          backtrace: e.backtrace[0..5],
          params: params.to_unsafe_h.slice(:hol_id, :changes),
          context: "submit_leave_changes"
        }, status: 500
      end


      # def process_leave_action
      #   detail_id = params[:holdetail_id]
      #   action = params[:action_type]
      #   oHoldetail = Holprosdetail.where(id: detail_id).first
      #   case action
      #   when "approve"
      #     approve_change(detail_id)
      #     msg = "Điều chỉnh đơn thành công"
      #   when "cancel"
      #     # có thể thêm logic cancel nếu cần
      #     msg = "Hủy điều chỉnh đơn thành công"
      #   else
      #     msg = "Không rõ hành động"
      #   end
      #   if oHoldetail.present?
      #     oHoldetail.update(result: "CHANGE_TYPE")
      #     oHol = Holpro.where(id: oHoldetail.holpros_id).first&.update(status: "DONE")
      #     mandoc = Mandoc.where(holpros_id: oHoldetail.holpros_id, status: "ACCEPTANCE").first
      #     newDhan = Mandocdhandle.where(mandoc_id: mandoc.id,srole: "ACCEPTANCE-REQUEST" ).first
      #     Mandocuhandle.where(mandocdhandle_id: newDhan&.id, user_id: session[:user_id],srole: "ACCEPTANCE-REQUEST").first&.update(status: "DAXULY")
      #   end
      # end


      def shift_value(shift)
        case shift
        when "ALL" then 1.0
        when "AM", "PM" then 0.5
        else 0.0
        end
      end

      def calculate_itotal(details_arr)
        details_arr.sum do |item|
          shift = item.split("-")[1]
          shift_value(shift)
        end
      end

      def approve_change(detail_id, reason)
        old_detail = Holprosdetail.find_by(id: detail_id)
        return unless old_detail

        all_dates = old_detail.details.to_s.split("$$$")
        histories = Mhistory.where(stable: "Holprosdetail$$$#{detail_id}$$$CHANGE")
        return if histories.blank?

        changed_map = histories.group_by(&:tvalue)
        changed_dates = histories.map(&:srowid)
        unchanged_dates = all_dates - changed_dates

        # Cập nhật bản ghi cũ nếu vẫn còn ngày chưa bị thay đổi
        if unchanged_dates.empty?
          old_detail.destroy
        else
          new_itotal = calculate_itotal(unchanged_dates)
          old_detail.update!(
            details: unchanged_dates.join("$$$"),
            itotal: new_itotal
          )
        end

        # Gộp tất cả các ngày có cùng loại nghỉ thành 1 Holprosdetail
        changed_map.each do |new_type, logs|
          new_dates = logs.map(&:srowid).uniq
          new_dates.sort_by! { |d| Date.strptime(d.split("-").first, "%d/%m/%Y") }

          # Tìm bản ghi đã tồn tại (cùng loại nghỉ + cùng hồ sơ nghỉ)
          existing_detail = Holprosdetail.where(
            holpros_id: old_detail.holpros_id,
            sholtype: new_type,
            result: "CHANGE_TYPE"
          ).first

          if existing_detail

            old_dates = existing_detail.details.to_s.split("$$$")
            merged_dates = (old_dates + new_dates).uniq.sort_by { |d| Date.strptime(d.split("-").first, "%d/%m/%Y") }

            before_total = existing_detail.itotal.to_f
            after_total = calculate_itotal(merged_dates)

            existing_detail.update!(
              details: merged_dates.join("$$$"),
              itotal: calculate_itotal(merged_dates),
              updated_at: Time.zone.now
            )
          else
            before_total = 0
            after_total = calculate_itotal(new_dates)
            Holprosdetail.create!(
              holpros_id: old_detail.holpros_id,
              sholtype: new_type,
              stype: old_detail.stype,
              details: new_dates.join("$$$"),
              itotal: calculate_itotal(new_dates),
              note: reason,
              result: "CHANGE_TYPE",
              handover_receiver: old_detail.handover_receiver,
              issued_place: old_detail.issued_place,
              issued_national: old_detail.issued_national,
              place_before_hol: old_detail.place_before_hol,
              created_at: Time.zone.now,
              updated_at: Time.zone.now
            )
          end
          if new_type == "NGHI-PHEP"
            holiday = Holiday.find_by(user_id: old_detail.holpro.holiday.user_id, year: Time.zone.today.year)

            if holiday.present?
              delta_used = after_total - before_total
              if delta_used != 0
                holiday.update!(used: holiday.used.to_f + delta_used)

                # ✅ Phân bổ vào từng dòng Holdetail theo ngày
                allocate_used_days(holiday, delta_used, new_dates)
              end
            end
          end
        end
      end
      def allocate_used_days(holiday, delta_used, used_dates)
        return if holiday.nil? || delta_used.to_f <= 0 || used_dates.blank?

        holdetail_map = holiday.holdetails.index_by(&:stype)

        ton = holdetail_map["TON"]
        tham_nien = holdetail_map["THAM-NIEN"]
        vi_tri = holdetail_map["VI-TRI"]

        ton_deadline = ton&.dtdeadline&.to_date

        dates_before_deadline, dates_after_deadline = used_dates.partition do |dstr|
          date = Date.strptime(dstr.split("-").first.strip, "%d/%m/%Y") rescue nil
          ton_deadline && date && date <= ton_deadline
        end

        total_dates = dates_before_deadline.size + dates_after_deadline.size
        return if total_dates == 0

        # Tỷ lệ phân chia theo số ngày thực tế
        ratio = delta_used / total_dates.to_f
        delta_before = dates_before_deadline.size * ratio
        delta_after = dates_after_deadline.size * ratio

        # Phân bổ
        distribute_to_sources(ton, tham_nien, vi_tri, delta_before, %w[TON THAM-NIEN VI-TRI])
        distribute_to_sources(nil, tham_nien, vi_tri, delta_after, %w[THAM-NIEN VI-TRI])
      end

      def distribute_to_sources(ton, tham_nien, vi_tri, amount, priority)
        remaining = amount.to_f
        source_map = {
          "TON" => ton,
          "THAM-NIEN" => tham_nien,
          "VI-TRI" => vi_tri
        }

        priority.each do |stype|
          break if remaining <= 0
          source = source_map[stype]
          next unless source

          available = source.amount.to_f - source.used.to_f
          if available > 0
            used_now = [available, remaining].min
            source.update!(used: source.used.to_f + used_now)
            remaining -= used_now
          end
        end

        # Nếu vẫn còn dư và có VI-TRI trong danh sách ưu tiên
        if remaining > 0 && priority.include?("VI-TRI") && vi_tri
          vi_tri.update!(used: vi_tri.used.to_f + remaining)
        end
      end

      def get_user_info(user_id)
        oUser = User.where(id: user_id).first
        full_name = ""
        sid = ""
        if oUser.present?
          full_name = "#{oUser.last_name} #{oUser.first_name}"
          sid = oUser.sid
        end
        [full_name, sid]
      end
      def time_ago_in_custom_format(time)
        return '' if time.nil?

        seconds_diff = Time.current - time

        days = (seconds_diff / 1.day).to_i
        hours = ((seconds_diff % 1.day) / 1.hour).to_i
        minutes = ((seconds_diff % 1.hour) / 1.minute).to_i

        if days > 0
          "#{days} ngày #{hours} giờ"
        elsif hours > 0
          minutes > 0 ? "#{hours} giờ #{minutes} phút" : "#{hours} giờ"
        else
          "#{minutes} phút"
        end
      end
      def get_user_handle
        depart = params[:next_department_id]
        user_register = params[:user_register]
        holpros_id = params[:holpros_id]
        oholpro = Holpro.find_by(id: holpros_id)
        if oholpro.status == "CANCEL"
          @result_user = {}
        else
          department_user = fetch_leaf_departments_by_user(session[:user_id])

          department_user_register = fetch_leaf_departments_by_user(user_register)

          common_departments = department_user & department_user_register
          oDepartment = if common_departments.present?
                          common_departments.first
                        elsif department_user.size == 1
                          department_user.first
                        else
                          nil
                        end

          if oDepartment.present?
            if depart != oDepartment.id
              next_oDepartment = Department.where(id: oDepartment.parents&.to_i, status: "0").first&.id
              next_oDepartment ||= depart
            else
              next_oDepartment = depart
            end
          elsif department_user_register.first&.faculty == "BGD(BUH)"
            deparment_buh = Department.where(faculty: "PTCHC(BUH)").first
            next_oDepartment = deparment_buh.id
          else
            next_oDepartment = depart
          end
          # --- xử lý lấy user_ids ---
          if oDepartment.present? && oDepartment.parents.present?
            target_department = oDepartment.parents
          else
            target_department = next_oDepartment
          end
          # user thuộc phòng ban target_department
          current_user_ids = Work.where(
            positionjob_id: Positionjob.where(department_id: target_department).pluck(:id)
          ).pluck(:user_id)
          # user có quyền APPROVE-REQUEST
          check_depart = Department.where(id: target_department, status: "0").first
          if check_depart.present? && check_depart.faculty == "PTCHC(BUH)"
            list_user_ids = Work.joins(stask: [accesses: :resource])
                                .where(resources: { scode: "APPROVE-REQUEST" })
                                .where(accesses: { permision: "READ" })
                                .pluck(:user_id)
          else
            list_user_ids = Work.joins(stask: [accesses: :resource])
                              .where(resources: { scode: "APPROVE-REQUEST" })
                              .where(accesses: { permision: "ADM" })
                              .where.not(user_id: user_register)
                              .pluck(:user_id)
          end

          # giao giữa 2 nhóm
          user_ids = current_user_ids & list_user_ids
          data_user = User.where(id: user_ids, staff_status: ["Đang làm việc", "DANG-LAM-VIEC"])
                          .select(:id, :last_name, :first_name, :email, :sid)
          @result_user = data_user
          # .reject do |user|
          #   today = Date.current
          #   oHol = Holiday.find_by(user_id: user.id, year: Time.current.year)
          #   next false unless oHol
          #   oHolpros = Holpro.where(holiday_id: oHol.id).last
          #   next false unless oHolpros
          #   created_hour = oHolpros.dtcreated&.hour || 0
          #   details = Holprosdetail.where(holpros_id: oHolpros.id)
          #   details.any? do |d|
          #     next false if d.details.blank?
          #     entries = d.details.split("$$$")
          #     entries.any? do |entry|
          #       date_str, time_part = entry.split("-")
          #       entry_date = Date.strptime(date_str, "%d/%m/%Y") rescue nil
          #       next false unless entry_date == today
          #       case time_part
          #       when "ALL"
          #         true
          #       when "AM"
          #         created_hour < 12
          #       when "PM"
          #         current_hour >= 12
          #       else
          #         false
          #       end
          #     end
          #   end
          # end
        end
      end

    # end
    def export_holiday_2026_preview
      nam_cu = 2025
      nam_hien_tai = 2026

      managing_org_code = params[:managing_org_code]
      organization = Organization.find_by(scode: managing_org_code)
      raise "Organization not found" unless organization

      users = User.joins(:uorgs)
                  .where(uorgs: { organization_id: organization.id })
                  .where(status: "ACTIVE")
                  .distinct

      data = []

      users.each do |user|
        holiday_2025 = Holiday.find_by(user_id: user.id, year: nam_cu)
        next unless holiday_2025

        # ============================
        # PHÒNG BAN
        # ============================
        positionjob_ids = Work.where(user_id: user.id)
                              .where.not(positionjob_id: nil)
                              .pluck(:positionjob_id)

        department_ids = Positionjob.where(id: positionjob_ids).pluck(:department_id)
        departments = Department.where(id: department_ids, status: "0")

        department =
          if departments.present?
            parent_ids = departments.map(&:parents).compact.map(&:to_i)
            departments.reject { |d| parent_ids.include?(d.id) }.first
          end

        next unless department

        # ============================
        # PHÉP NĂM 2025 (GỐC)
        # ============================
        vi_tri = Holdetail.find_by(holiday_id: holiday_2025.id, stype: "VI-TRI")
        tham_nien = Holdetail.find_by(holiday_id: holiday_2025.id, stype: "THAM-NIEN")
        ton = Holdetail.find_by(holiday_id: holiday_2025.id, stype: "TON")

        total_2025 =
          vi_tri&.amount.to_f +
          tham_nien&.amount.to_f

        used_2025 =
          vi_tri&.used.to_f +
          tham_nien&.used.to_f

        # ============================
        # PHÉP CHƯA DUYỆT (PENDING / TEMP / PROCESSING)
        # ============================
        holpro_ids_pending = Holpro.where(holiday_id: holiday_2025.id)
                                  .where.not(status: %w[DONE CANCEL-DONE CANCEL REFUSE])
                                  .pluck(:id)

        pending_2025 = Holprosdetail.where(
          holpros_id: holpro_ids_pending,
          sholtype: %w[NGHI-PHEP NGHI-CHE-DO]
        ).sum do |d|
          d.details.to_s.split("$$$").sum do |item|
            date_str, buoi = item.split("-").map(&:strip)
            date = Date.strptime(date_str, "%d/%m/%Y") rescue nil
            next 0 unless date&.year == nam_cu
            buoi.nil? || buoi.upcase == "ALL" ? 1.0 : 0.5
          end
        end

        # ============================
        # PHÉP ĐĂNG KÝ SỚM 2026 (DONE)
        # ============================
        holpro_ids_done = Holpro.where(
          holiday_id: holiday_2025.id,
          status: %w[DONE CANCEL-DONE]
        ).pluck(:id)

        early_2026 = Holprosdetail.where(
          holpros_id: holpro_ids_done,
          sholtype: %w[NGHI-PHEP NGHI-CHE-DO]
        ).sum do |d|
          d.details.to_s.split("$$$").sum do |item|
            date_str, buoi = item.split("-").map(&:strip)
            date = Date.strptime(date_str, "%d/%m/%Y") rescue nil
            next 0 unless date&.year == nam_hien_tai
            buoi.nil? || buoi.upcase == "ALL" ? 1.0 : 0.5
          end
        end

        # ============================
        # TRẠNG THÁI PHÉP 2025
        # ============================
        occupied_2025 = used_2025 + pending_2025
        remain_2025 = total_2025 - occupied_2025

        trang_thai =
          if remain_2025 > 0
            "CÒN"
          elsif remain_2025 == 0
            "HẾT"
          else
            "ÂM"
          end

        phep_am_2025 = remain_2025 < 0 ? remain_2025.abs : 0
        phep_ton_goc = remain_2025 > 0 ? remain_2025 : 0

        phep_vi_tri_goc = if managing_org_code == "BUH"
          Positionjob.where(id: positionjob_ids, department_id: department.id)
                    .first&.holno.to_f || 0
        else
          12
        end

        # ============================
        # PHÂN BỔ 2026
        # ============================
        used_ton = [early_2026, phep_ton_goc].min
        vuot_ton = [early_2026 - phep_ton_goc, 0].max

        ton_thuc_te = phep_ton_goc - used_ton
        vi_tri_thuc_te = phep_vi_tri_goc - phep_am_2025 - vuot_ton

        data << {
          user_name: "#{user.last_name} #{user.first_name}",
          user_sid: user.sid,
          trang_thai_2025: trang_thai,
          so_phep_nam_2025: total_2025,
          phep_da_dung_2025: used_2025,
          phep_chua_duyet_2025: pending_2025,
          phep_dang_ky_som: early_2026,
          phep_am_2025: phep_am_2025,
          phep_ton_goc: phep_ton_goc,
          phep_vi_tri_goc: phep_vi_tri_goc,
          ton_thuc_te: ton_thuc_te,
          vi_tri_thuc_te: vi_tri_thuc_te
        }
      end
      package = Axlsx::Package.new
      wb = package.workbook
      wb.add_worksheet(name: "Preview 2026") do |sheet|
        sheet.add_row ["Lưu ý: số liệu bao gồm phép đã dùng + phép đang giữ chỗ"]
        sheet.merge_cells("A1:L1")
        sheet.add_row [
          "Họ & tên",
          "Mã NV",
          "Trạng thái 2025",
          "Phép năm 2025",
          "Đã dùng 2025",
          "Chưa duyệt 2025",
          "Phép sớm 2026",
          "Phép âm 2025",
          "Phép tồn gốc",
          "Phép vị trí gốc",
          "Phép tồn tạo",
          "Phép vị trí tạo"
        ]
        data.each do |r|
          sheet.add_row [
            r[:user_name],
            r[:user_sid],
            r[:trang_thai_2025],
            r[:so_phep_nam_2025],
            r[:phep_da_dung_2025],
            r[:phep_chua_duyet_2025],
            r[:phep_dang_ky_som],
            r[:phep_am_2025],
            r[:phep_ton_goc],
            r[:phep_vi_tri_goc],
            r[:ton_thuc_te],
            r[:vi_tri_thuc_te]
          ]
        end
      end
      send_data package.to_stream.read,
                filename: "holiday_2026_preview_#{managing_org_code}.xlsx",
                type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    end

    #  start phần xử lý lấy thông tin chi tiết của 1 đơn phép
      def holprosdetails
        holpros_id = params[:holpros_id]
        user_id = params[:user_id]
        current_time = Time.current
        current_year = current_time.year
        current_month = current_time.month

        @data_result = {}
        @data_info = {}
        notes = nil
        list_hpdetail = Holprosdetail.where(holpros_id: holpros_id)
        o_mandoc = Mandoc.where(holpros_id: holpros_id).where.not(status: "CANCEL-PENDING").first

        # Lấy Mandoc có trạng thái CANCEL-PENDING nếu có
        o_mandoc_cancel = Mandoc.where(holpros_id: holpros_id, status: "CANCEL-PENDING").first

        department_user_curent = fetch_leaf_departments_by_user(session[:user_id])
        department_current = department_user_curent.first
        check_faculty = department_current&.faculty == "PTCHC(BUH)"
        
        department_user = fetch_leaf_departments_by_user(user_id)
        department = department_user.first
        department_user_name = department&.name
        department_user_id = department&.id

        # Lấy đúng Work gắn với positionjob thuộc về department_user
        work = Work.includes(:positionjob)
                  .where(user_id: user_id)
                  .where.not(positionjob_id: nil)
                  .detect { |w| w.positionjob&.department_id == department_user_id }

        positionjob = work&.positionjob
        position_code = positionjob&.scode.to_s.upcase
        @array_cancel = list_array_cancel(list_hpdetail)
        @check_holprosdetails = o_mandoc_cancel.present?
        theo_doi = false
        bien_phong = false
        if check_faculty == true
          check_code = position_code.match?(/TRUONG|PHO/)
          check_per = Work.joins(stask: { accesses: :resource })
                                    .where(
                                      resources: { scode: "APPROVE-REQUEST" },
                                      works:     { user_id: user_id },
                                      accesses:  { permision: "ADM" }
                                    )
                                    .exists?
          if check_code == true || check_per == true
            theo_doi = true
          end                     
          if department&.parents.present?
            theo_doi = false
          end
          bien_phong = true
        end
        
        if (session[:organization] & ["BMU", "BMTU"]).any?
          if department_current&.parents.present?
            theo_doi = true
          else
            theo_doi = false
          end
          check_per = Work.joins(stask: { accesses: :resource })
                                    .where(
                                      resources: { scode: "APPROVE-REQUEST-CVP" },
                                      works:     { user_id: session[:user_id] },
                                      accesses:  { permision: "ADM" }
                                    )
                                    .exists?
          if check_per == true
            theo_doi = false
          end
          bien_phong = true
        end
        @theo_doi = theo_doi
        @bien_phong = bien_phong

        full_name, sid = get_user_info(user_id)
        
        if (session[:organization] & ["BMU", "BMTU"]).any?
          organization = "BMU"
        else
          organization = "BUH"
        end
        # Xử lý phép theo tháng nếu là tab_1 hoặc tab mặc định
        if params[:current_tab].in?([nil,"", "tab_1"]) && organization == "BUH"
          @data_result = calculate_leave_data(user_id, holpros_id, current_month, department_user_id)
        end

        # Timeline xử lý
        mandocdhandle_ids = Mandocdhandle.where(mandoc_id: o_mandoc&.id).pluck(:id)
        min_ids_per_user = Mandocuhandle.where(mandocdhandle_id: mandocdhandle_ids).where.not(srole: "SUB")
        records = Mandocuhandle.where(id: min_ids_per_user.pluck(:id)).includes(:user)
        @timeline_data = build_timeline_data(records)
        @timeline_data_cancel = []
        @check_holprosdetails = false
        if o_mandoc_cancel.present?
          @check_holprosdetails = true
          mandocdhandle_cancel_ids = Mandocdhandle.where(mandoc_id: o_mandoc_cancel.id).pluck(:id)
          mandocuhandles_cancel = Mandocuhandle.where(mandocdhandle_id: mandocdhandle_cancel_ids).includes(:user).where.not(srole: "SUB")
          @timeline_data_cancel = build_timeline_data(mandocuhandles_cancel)
        end
        # Chi tiết từng dòng nghỉ
        @result = build_holpros_detail_data(list_hpdetail)
        oHol = Holpro.where(id: holpros_id).first
        type_temp = nil
        if oHol.present? 
          if oHol.status == "REFUSE"
            type_temp = "Từ chối"
            notes = oHol.note
          elsif oHol.status == "DONE"
            type_temp = "Đã duyệt"
          elsif oHol.status == "CANCEL"
            type_temp = "Đã hủy"
            notes = oHol.note
          else
            type_temp = "Đang xử lý"
          end
        end
        o_mandoc_cancel = Mandoc.where(holpros_id: holpros_id, status: "CANCEL-PENDING").first
        note_cancel = nil
        if o_mandoc_cancel.present?
          note_cancel = oHol.note
        end
        oholpro = Holpro.find_by(id: holpros_id)
        if oholpro.status == "CANCEL"
          @data_info = {}
        else
          @data_info = {
            full_name: "#{sid} - #{full_name}",
            department_name: department_user_name,
            note: notes,
            note_cancel: note_cancel,
            type_temp: type_temp,
            dttotal: (val = oHol.dttotal.to_f) % 1 == 0 ? val.to_i : val
          }
        end
        respond_to do |format|
          format.js
        end
      end
      def calculate_leave_data(user_id, holpros_id, current_month, department_user_id)
        holiday = Holiday.find_by(user_id: user_id, year: Time.current.year)
        return {} unless holiday

        # holiday_old = Holiday.find_by(user_id: user_id, year: Time.current.year - 1)
        # if holiday_old.present?
        #   extra_old_ids = Holpro.joins(:holprosdetails)
        #                         .where(holiday_id: holiday_old.id)
        #                         .where(holprosdetails: { sholtype: ["NGHI-PHEP", "NGHI-CHE-DO"], status: "DONE" })
        #                         .distinct
        #                         .pluck(:id)
        #   holpros_details_old    = Holprosdetail.where(holpros_id: extra_old_ids, sholtype: ["NGHI-PHEP", "NGHI-CHE-DO"])
        #   all_leave_dates_old = holpros_details_old.map(&:details).compact.flat_map { |d| d.split('$$$') }.map do |item|
        #     date_part, session = item.split('-').map(&:strip)
        #     date = Date.strptime(date_part, '%d/%m/%Y') rescue nil
        #     next nil unless date
        #     weight = case session&.upcase
        #             when 'ALL', nil then 1.0
        #             when 'AM', 'PM'  then 0.5
        #             else 0
        #             end
        #     [date, weight]
        #   end.compact
        #   nam_hien_tai = Time.current.year
        #   tong_ngay_nghi_cu =
        #     all_leave_dates_old
        #       .select { |date, _| date.year == nam_hien_tai }
        #       .sum { |_, weight| weight }
        # end

        holdetails = Holdetail.where(holiday_id: holiday.id)

        vi_tri            = holdetails.find { |h| h.name == "Phép theo vị trí" }&.amount.to_f
        tham_niem         = holdetails.find { |h| h.name == "Phép thâm niên" }&.amount.to_f
        so_phep_ton       = holdetails.find { |h| h.name == "Phép tồn" }&.amount.to_f
        vi_tri_used       = holdetails.find { |h| h.name == "Phép theo vị trí" }&.used.to_f
        tham_niem_used    = holdetails.find { |h| h.name == "Phép thâm niên" }&.used.to_f
        phep_ton_da_dung  = holdetails.find { |h| h.name == "Phép tồn" }&.used.to_f
        ton_deadline      = holdetails.find { |h| h.name == "Phép tồn" }&.dtdeadline&.strftime("%d/%m/%Y")
        current_phep      = holdetails.find { |h| h.name == "Phép theo vị trí" }&.note.to_f + holdetails.find { |h| h.name == "Phép thâm niên" }&.note.to_f
        current_ton       = holdetails.find { |h| h.name == "Phép tồn" }&.note.to_f
        ton_deadline_date = Date.strptime(ton_deadline, "%d/%m/%Y") rescue nil

        # --- Đơn đã duyệt ---
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
        phep_ton_da_dung_thuc_te    += current_ton
        leave_dates_after_deadline  = all_leave_dates.select { |date, _| date > ton_deadline_date }
        phep_da_dung_thuc_te        = leave_dates_after_deadline.sum { |_, weight| weight }
        phep_da_dung_thuc_te        += current_phep

        # if holiday_old.present?
        #   phep_da_dung_thuc_te      += tong_ngay_nghi_cu 
        # end
        # --- Phép đang đăng ký ---
        details_in_current = Holprosdetail.where(holpros_id: holpros_id, sholtype: ["NGHI-PHEP", "NGHI-CHE-DO"])
        so_phep_dang_ky     = details_in_current.sum(:itotal).to_f

        # Phân loại ngày nghỉ trong đơn hiện tại
        current_leave_days = details_in_current.map(&:details).compact.flat_map { |d| d.split('$$$') }.map do |item|
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
        
        # Chia ngày nghỉ hiện tại thành 2 nhóm
        current_before_deadline = current_leave_days.select { |date, _| date <= ton_deadline_date }
        current_after_deadline  = current_leave_days.select { |date, _| date > ton_deadline_date }

        tong_trong_han  = current_before_deadline.sum { |_, w| w }
        tong_ngoai_han  = current_after_deadline.sum { |_, w| w }

        # # các loại phép còn lại
        # all_holpros_ids_not = all_holpros_ids + holpros_id
        # holpros_ids_not = Holpro.where(holiday_id: holiday.id).where.not(id: all_holpros_ids_not).pluck(:id)
        # holpros_details_not = Holprosdetail.where(
        #   holpros_id: holpros_ids_not,
        #   sholtype: ["NGHI-PHEP", "NGHI-CHE-DO"]
        # )
        # all_leave_dates_not = holpros_details_not.flat_map { |d| parse_dates.call(d.details) }

        # phep_ton_da_dung_thuc_te_not = all_leave_dates_not.select { |date, _| date <= ton_deadline_date }.sum { |_, w| w }

        # phep_da_dung_thuc_te_not     = all_leave_dates_not.select { |date, _| date > ton_deadline_date }.sum { |_, w| w }
        
        # Kiểm tra nếu tất cả ngày đều nằm trong trước hạn phép tồn
        con_lai_phep_ton = if current_after_deadline.empty?
          # Nếu tất cả ngày trong đơn đều trước deadline
          if so_phep_ton >= phep_ton_da_dung
            # phần còn lại = so_phep_ton - (phép_ton_đã_dùng - số ngày của đơn này nằm trong hạn)
            so_phep_ton - phep_ton_da_dung_thuc_te - tong_trong_han
          else
            0
          end
        else
          # Một phần ngày nằm sau deadline → phép tồn chỉ trừ phần trước deadline
          if so_phep_ton >= phep_ton_da_dung
            so_phep_ton - phep_ton_da_dung_thuc_te
          else
            0
          end
        end
        if con_lai_phep_ton < 0 
          con_lai_phep_ton = so_phep_ton
        end
        if phep_ton_da_dung_thuc_te > so_phep_ton

          phep_ton_da_dung_thuc_te_used = phep_ton_da_dung_thuc_te

          phep_ton_da_dung_thuc_te = so_phep_ton

          phep_da_dung_thuc_te += phep_ton_da_dung_thuc_te_used - so_phep_ton
        end
        if tong_trong_han == 0 && tong_ngoai_han > 0
          con_lai_phep_ton = 0
        end
        actual_holno, worked_months_to_now, worked_months_to_end, check_tnlv = calculate_actual_holno(user_id, department_user_id)
        # 15/11/2025
        # cập nhật số phép tổng theo số năm làm việc của nhân sự
        # H.anh
        if check_tnlv == true
          so_phep_tong =  vi_tri + tham_niem
          phep_duoc_sd = custom_round(so_phep_tong / 12 * current_month) - phep_da_dung_thuc_te
        else
          so_phep_tong =  actual_holno
          phep_duoc_sd = custom_round( (so_phep_tong / worked_months_to_end.to_f) *  worked_months_to_now) - phep_da_dung_thuc_te
        end
        if ton_deadline_date && Date.current <= ton_deadline_date && phep_ton_da_dung_thuc_te < so_phep_ton
          check_ton = true
        else
          check_ton = false
        end
        total_ton = so_phep_ton - phep_ton_da_dung_thuc_te
        phep_sd_thang = custom_round_with_half_keep(phep_duoc_sd)
        {
          so_phep_nam: so_phep_tong,
          total_ton: total_ton,
          phep_ton: so_phep_ton,
          thoi_gian_sd: ton_deadline,
          phep_da_dung: phep_da_dung_thuc_te,
          check_ton: check_ton,
          phep_ton_da_sd: phep_ton_da_dung_thuc_te,
          phep_duoc_sd_theo_thang: phep_sd_thang,
          phep_duoc_ung_theo_thang: phep_sd_thang < 0 ? 0 : custom_round((so_phep_tong - phep_da_dung_thuc_te) * 0.25),
          tong_used: so_phep_dang_ky,
          thang_hien_tai: Time.current.month,
          con_lai_phep_ton: custom_round(con_lai_phep_ton)
        }
      end

      def list_array_cancel(list_hpdetail)
        array_cancel = []
        list_hpdetail.group_by(&:sholtype).each do |sholtype_code, grouped_details|
          all_changes = []
          grouped_details.each do |hp|
            oMhis = Mhistory.find_by(stable: "holprosdetails$$$#{hp.id}", srowid: "details")
            next unless oMhis.present?
            from_hash = (oMhis.fvalue || "").split("$$$").map { |v| v.split("-") }.to_h
            to_hash   = (oMhis.tvalue || "").split("$$$").map { |v| v.split("-") }.to_h
            cancelled_dates = from_hash.keys - to_hash.keys
            if cancelled_dates.any?
              sorted_dates = cancelled_dates.map { |d| Date.strptime(d, "%d/%m/%Y") rescue nil }.compact.sort
              grouped = sorted_dates.chunk_while { |prev, curr| curr == prev + 1 }.to_a
              grouped.each do |group|
                if group.length == 1
                  all_changes << "Hủy ngày #{group.first.strftime('%d/%m/%Y')}"
                else
                  all_changes << "Hủy từ ngày #{group.first.strftime('%d/%m/%Y')} đến #{group.last.strftime('%d/%m/%Y')}"
                end
              end
            end
            from_hash.each do |day, fval|
              tval = to_hash[day]
              next unless tval && fval != tval

              text_change =
                case tval
                when "AM" then "nghỉ buổi sáng"
                when "PM" then "nghỉ buổi chiều"
                when "ALL" then "nghỉ cả ngày"
                else "nghỉ #{tval}"
                end
              all_changes << "Ngày #{day} chuyển thành #{text_change}"
            end
          end
          next if all_changes.empty?
          oHoltype = Holtype.find_by(code: sholtype_code)
          name_type = oHoltype&.name || "Không xác định"
          array_cancel << {
            code_sholtype: sholtype_code,
            sholtype: name_type,
            changes: all_changes
          }
        end
        array_cancel
      end

      def calculate_actual_holno(user_id, department_id)
        user = User.find_by(id: user_id)
        return 0, 0, 0 unless user

        contracts = Contract.where(user_id: user_id)
        seniority_contracts = contracts.select do |contract|
          ctype = Contracttype.find_by(name: contract.name)
          ctype&.is_seniority&.include?("YES") && contract.dtfrom.present?
        end

        sorted_contracts = seniority_contracts.sort_by(&:dtfrom)

        holno = Positionjob.where(
          id: Work.where(user_id: user_id).where.not(positionjob_id: nil).pluck(:positionjob_id),
          department_id: department_id
        ).first&.holno.to_f || 0

        # Mặc định là cả năm hiện tại
        today = Time.zone.today
        year = today.year
        start_date = Date.new(year, 1, 1)
        end_date = Date.new(year, 12, 31)

        # Nếu có hợp đồng trong năm thì lấy ngày bắt đầu làm việc
        if sorted_contracts.any?
          contract_start = sorted_contracts.first.dtfrom.to_date
          start_date = contract_start if contract_start.year <= year
        end
        if start_date.year < year
          check_tnlv = true
          worked_months_to_end = 12
          worked_months_to_now = 12
          actual_holno = holno
        elsif user.termination_date.present? && user.termination_date&.year == year
          check_tnlv = false
          worked_months_to_now = calculate_months_with_15_rule(start_date, today, false)
          worked_months_to_end = calculate_months_with_15_rule(start_date, user.termination_date, true)
          actual_holno = (holno * worked_months_to_now / 12.0).round
        else
          check_tnlv = false
          worked_months_to_now = calculate_months_with_15_rule(start_date, today, false)
          worked_months_to_end = calculate_months_with_15_rule(start_date, end_date, false)
          actual_holno = (holno / 12.0 * worked_months_to_end ).round
        end

        return actual_holno, worked_months_to_now, worked_months_to_end, check_tnlv
      end

      def calculate_months_with_15_rule(start_date, end_date, check)
        return 0 if start_date > end_date

        months = 0
        current = start_date
        # Tháng đầu tiên
        if start_date.day <= 15
          months += 1
        end
        # Tháng kế tiếp đến tháng của end_date (trừ tháng đầu)
        first_full_month = start_date.next_month.beginning_of_month

        while first_full_month <= end_date.beginning_of_month
          months += 1
          first_full_month = first_full_month.next_month
        end
        # Áp dụng trừ tháng cuối nếu check == true và nghỉ trước/đúng ngày 15
        if check && end_date.day <= 15
          months -= 1
        end

        months
      end


      def build_timeline_data(records)
        current_user_id = session[:user_id]
        records.map.with_index do |record, index|
          is_current_user = record.user_id == current_user_id
          note_display = is_current_user && record.notes.present? ? record.notes : nil

          {
            time: record.updated_at.strftime("%d/%m/%Y %H:%M"),
            status: map_status(record.status),
            user: "#{record.user&.last_name} #{record.user&.first_name}",
            first: index == 0,
            last: index == records.length - 1,
            handled: record.status == "DAXULY",
            user_position: support_posi_name(record.user_id),
            note: note_display
          }
        end
      end

      def build_holpros_detail_data(details)
        details.map do |item|
          country, place = item.issued_place&.include?("$$$") ? item.issued_place.split("$$$") : [nil, item.issued_place]
          {
            id: item.id,
            sholtype: supprot_name(item.sholtype),
            dtfrom: item.dtfrom,
            dtto: item.dtto,
            handover_receiver: item.handover_receiver,
            place_before_hol: item.place_before_hol,
            note: item.note,
            details: item.details,
            issued_place: place,
            country: Nationality.find_by(scode: country)&.name || country
          }
        end
      end
      def custom_round(value)
        if value >= 0
          integer_part = value.to_i
          decimal_part = value - integer_part

          if decimal_part < 0.5
            integer_part
          else
            integer_part + 1
          end
        else
          integer_part = value.to_i
          decimal_part = value - integer_part

          if decimal_part.abs < 0.5
            integer_part
          else
            integer_part - 1
          end
        end
      end
      def custom_round_with_half_keep(value)
        return value if (value % 1).abs == 0.5

        if value >= 0
          integer_part = value.to_i
          decimal_part = value - integer_part

          decimal_part < 0.5 ? integer_part : integer_part + 1
        else
          integer_part = value.to_i
          decimal_part = value - integer_part

          decimal_part.abs < 0.5 ? integer_part : integer_part - 1
        end
      end

      def map_status(status)
        case status
        when "DAXULY"
          "Đã xử lý"
        when "CHUAXULY"
          "Đang chờ xử lý"
        else
          "Không xác định"
        end
      end
      def support_posi_name(user_id)
        Work.where(user_id: user_id).where.not(positionjob_id: nil).first&.positionjob&.name
      end
      def supprot_name(sholtype)
          Holtype.where(code: sholtype).first&.name || sholtype
      end
    # end
    def refuse_leave
      holpros_id = params[:holpros_id]
      user_id = params[:user_id]
      note = params[:note]
      oholpro = Holpro.find_by(id: holpros_id)
      if oholpro.status == "CANCEL"
        flash[:error] = "Đơn đã bị hủy"
      else
        o_mandoc_cancel = Mandoc.where(holpros_id: holpros_id, status: "CANCEL-PENDING").first
        oUser = User.where(id: user_id).first
        full_name = ""
        sid = ""
        if oUser.present?
          full_name = "#{oUser.last_name} #{oUser.first_name}"
          sid = oUser.sid
        end
        list_user_id = get_list_user(holpros_id)
        if o_mandoc_cancel.present?
          Holpro.find(holpros_id).update(status: "CANCEL-DONE",note: note)
          Mandocuhandle.where(mandocdhandle_id: Mandocdhandle.where(mandoc_id: o_mandoc_cancel.id).last&.id, user_id: session[:user_id]).update_all(status: "DAXULY", updated_at: Time.current)
          content = "Đơn điều chỉnh của nhân sự: <b>#{full_name}</b> - Mã nhân sự: <b>#{sid}</b> đã bị hủy, Lý do: #{note}"
        else
          Holpro.find(holpros_id).update(status: "REFUSE", note: note)
          Holprosdetail.where(holpros_id: holpros_id).update_all(status: "REFUSE")
          Mandocuhandle.where(mandocdhandle_id: Mandocdhandle.where(mandoc_id: Mandoc.find_by(holpros_id: holpros_id).id).last&.id,  user_id: session[:user_id]).update_all(status: "DAXULY", updated_at: Time.current)
  
          amount_to_consume = Holprosdetail.where(holpros_id: holpros_id, sholtype: ["NGHI-PHEP","NGHI-CHE-DO"])
          revert_leave(user_id, amount_to_consume.sum(:itotal), amount_to_consume.pluck(:details),holpros_id)
          content = "Đơn nghỉ của nhân sự: <b>#{full_name}</b> - Mã nhân sự: <b>#{sid}</b> đã bị hủy, Lý do: #{note}"
        end
        create_noti(content,holpros_id,list_user_id,true)
        flash[:success] = "Đã hủy đơn của nhân sự!"
      end
      redirect_to :back
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

    def handle_leave
      holpros_id = params[:holpros_id]
      user_handle = params[:user_handle]
      uhandle_id = params[:uhandle_id]
      next_department_id = params[:next_department_id]
      user_id = params[:user_id]
      note = params[:note]

      holpro = Holpro.find_by(id: holpros_id)
      unless holpro
        flash[:error] = "Không tìm thấy thông tin đơn cần xử lý."
        redirect_back(fallback_location: root_path) and return
      end
      if holpro.status == "CANCEL"
        flash[:error] = "Đơn đã bị hủy."
        redirect_back(fallback_location: root_path) and return
      end
      holpro.update!(status: "PROCESSING")

      last_Uhandle = Mandocuhandle.find_by(id: uhandle_id)
      unless last_Uhandle
        flash[:error] = "Không tìm thấy thông tin xử lý gần nhất."
        redirect_back(fallback_location: root_path) and return
      end

      if last_Uhandle.status == "DAXULY"
        flash[:error] = "Đơn đã được xử lý."
        redirect_back(fallback_location: root_path) and return
      end

      last_Dhandle = Mandocdhandle.find_by(id: last_Uhandle.mandocdhandle_id)
      unless last_Dhandle
        flash[:error] = "Không tìm thấy phòng ban xử lý gần nhất."
        redirect_back(fallback_location: root_path) and return
      end

      begin
        ActiveRecord::Base.transaction do
          oUser = User.find_by(id: user_id)
          full_name = oUser.present? ? "#{oUser.last_name} #{oUser.first_name}" : ""
          sid = oUser&.sid

          details = Holprosdetail.where(holpros_id: holpros_id)
          ids = details.map do |detail|
            next unless detail.handover_receiver
            detail.handover_receiver.split("|||").map { |receiver| receiver.split("$$$").first }
          end
          ids = ids.flatten.compact.uniq.map(&:to_i)

          ids.each do |user_support|
            exists = Mandocuhandle.exists?(
              user_id: user_support,
              srole: "SUB",
              mandocdhandle_id: last_Uhandle.mandocdhandle_id
            )
            unless exists
              Mandocuhandle.create!(
                mandocdhandle_id: last_Uhandle.mandocdhandle_id,
                user_id: user_support,
                srole: "SUB",
                status: "DAXULY"
              )
            end
          end

          last_Uhandle.update!(status: "DAXULY")
          last_Dhandle.update!(status: "DAXULY")

          new_Dhandle = Mandocdhandle.create!(
            mandoc_id: last_Dhandle.mandoc_id,
            department_id: next_department_id,
            srole: "LEAVE-REQUEST",
            status: "CHUAXULY"
          )

          Mandocuhandle.create!(
            mandocdhandle_id: new_Dhandle.id,
            user_id: user_handle,
            srole: "MAIN",
            status: "CHUAXULY",
            notes: note
          )

          content = "Đơn nghỉ phép của nhân sự: <b>#{full_name}</b> - Mã nhân sự: <b>#{sid}</b> cần được xử lý"
          create_noti(content, holpros_id, Array(user_handle))
        end

        flash[:success] = "Đã chuyển đơn nghỉ phép thành công!"
        redirect_back(fallback_location: root_path)
      rescue ActiveRecord::RecordInvalid => e
        flash[:error] = "Lỗi xử lý dữ liệu: #{e.message}"
        redirect_back(fallback_location: root_path)
      rescue => e
        flash[:error] = "Đã xảy ra lỗi không mong muốn: #{e.message}"
        redirect_back(fallback_location: root_path)
      end
    end

    
    def approve_leave
      holpros_id = params[:holpros_id]
      uhandle_id = params[:uhandle_id]
      user_id    = params[:user_id]
      holpro = Holpro.find_by(id: holpros_id)
      unless holpro
        flash[:error] = "Không tìm thấy thông tin đơn cần xử lý."
        redirect_to :back and return
      end
      if holpro.status == "CANCEL"
        flash[:error] = "Đơn đã bị hủy."
        redirect_back(fallback_location: root_path) and return
      end
      last_Uhandle = Mandocuhandle.find_by(id: uhandle_id)
      unless last_Uhandle
        flash[:error] = "Không tìm thấy thông tin xử lý gần nhất."
        redirect_to :back and return
      end

      if last_Uhandle.status == "DAXULY"
        flash[:error] = "Đơn đã được xử lý."
        redirect_to :back and return
      end
      begin
        ActiveRecord::Base.transaction do
          # === Lấy thông tin nhân sự ===
          oUser = User.find_by(id: user_id)
          full_name = oUser.present? ? "#{oUser.last_name} #{oUser.first_name}" : ""
          sid       = oUser.present? ? oUser.sid : ""
          
          # === Lấy Mandoc chính và Mandoc Cancel (nếu có) ===
          madoc = Mandoc.where(holpros_id: holpros_id).where.not(status: "CANCEL-PENDING").first
          o_mandoc_cancel = Mandoc.find_by(holpros_id: holpros_id, status: "CANCEL-PENDING")

          
          # === Nếu đơn ở trạng thái CANCEL-PENDING (điều chỉnh) ===
          if o_mandoc_cancel.present?
            holpro.update!(status: "CANCEL-DONE")
            list_hpdetail = Holprosdetail.where(holpros_id: holpros_id)
            total_changed_days_phep = 0.0
            total_changed_days      = 0.0
            removed_dates           = []
            if list_hpdetail.present?
              list_hpdetail.each do |detail|
                original_total = detail.itotal.to_f
                history = Mhistory.where(stable: "holprosdetails$$$#{detail.id}", srowid: "details")
                                  .order(updated_at: :desc)
                                  .first
                next unless history.present?

                f_days = (history.fvalue || "").split("$$$")
                t_days = (history.tvalue || "").split("$$$")

                # Map để lấy ngày và loại buổi
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

                # === Nếu tvalue blank → hủy toàn bộ ===
                if history.tvalue.blank?
                  f_days.each do |d|
                    sess = d.split("-").last
                    changed_days += weight.call(sess)
                  end
                  removed_dates.concat(f_days)
                  detail.update!(itotal: 0, details: "")
                else
                  # === Hủy 1 phần so sánh f vs t ===
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
                result = help_caculation_change_day(f_days, t_days)
                update_scheduleweek(user_id, result, "CANCELED")
                total_changed_days += changed_days
                total_changed_days_phep += changed_days if detail.sholtype == "NGHI-PHEP"
              end
            end
            holpro.update!(dttotal: holpro.dttotal.to_f - total_changed_days)
            # === Cập nhật lại holiday.used ===
            holiday = Holiday.find_by(user_id: holpro.holiday.user_id, year: Time.zone.today.year)
            if holiday.present?
              holiday.update!(used: holiday.used.to_f - total_changed_days_phep)
              removed_dates.uniq!
              withdraw_used_days(holiday, total_changed_days_phep, removed_dates, holpros_id)
            end
            last_Uhandle.update!(status: "DAXULY")
            success = "Đã duyệt điều chỉnh thành công!"
            content = "Đơn điều chỉnh của nhân sự: <b>#{full_name}</b> - Mã nhân sự: <b>#{sid}</b> đã được duyệt"
            list_user_id = get_list_user(holpros_id)

            create_noti(content, holpros_id, list_user_id, true)
          else
            # === Trường hợp duyệt đơn nghỉ bình thường ===
            list_mand = Mandocdhandle.where(mandoc_id: madoc.id).pluck(:id)
            check_sub_exit = Mandocuhandle.where(mandocdhandle_id: list_mand, srole: "SUB").exists?
            details = Holprosdetail.where(holpros_id: holpros_id)
            ids = details.map do |detail|
              next unless detail.handover_receiver
              detail.handover_receiver.split("|||").map { |r| r.split("$$$").first }
            end.flatten.compact.uniq.map(&:to_i)
            details.each { |item| update_scheduleweek(user_id, item.details, "APPROVED") }
            unless check_sub_exit
              id_dau_tien = list_mand.first
              ids.each do |user_support|
                Mandocuhandle.find_or_create_by!(
                  mandocdhandle_id: id_dau_tien,
                  user_id: user_support,
                  srole: "SUB"
                ) do |m|
                  m.status = "DAXULY"
                end
              end
            end

            details.update_all(status: "DONE")
            holpro.update!(status: "DONE")
            last_Uhandle.update!(status: "DAXULY")

            last_Dhandle = Mandocdhandle.find_by(id: last_Uhandle.mandocdhandle_id)
            unless last_Dhandle
              flash[:error] = "Không tìm thấy phòng ban xử lý gần nhất."
              redirect_to :back and return
            end
            last_Dhandle.update!(status: "DAXULY")
            leave_text = parse_leave_details_for_holpro(details)
           
            

            itotal = Holprosdetail.where(holpros_id: holpros_id, sholtype: ["NGHI-PHEP","NGHI-CHE-DO"]).sum(:itotal).to_f
            oHoliday = Holiday.find_by(id: holpro.holiday_id)
            if oHoliday.present? && itotal > 0
              total_used = oHoliday.used.to_f + itotal
              oHoliday.update(used: total_used)
            end
            success = "Đã duyệt đơn nghỉ thành công!"
            content = "Đơn nghỉ của nhân sự: <b>#{full_name}</b> - Mã nhân sự: <b>#{sid}</b> đã được duyệt.<br>
                    Tổng thời gian nghỉ: <b>#{details.sum(:itotal).to_f}</b> ngày.<br>
                    Thời gian nghỉ:<br>
                    #{leave_text}"
            content_sub = "Đơn nghỉ của nhân sự: <b>#{full_name}</b> - Mã nhân sự: <b>#{sid}</b> đã được duyệt.<br>
                        Trong thời gian nhân sự này nghỉ, bạn là người nhận bàn giao và hỗ trợ công việc, Tổng thời gian nghỉ: <b>#{details.sum(:itotal).to_f}</b> ngày.<br>
                        Thời gian nghỉ:<br>
                        #{leave_text}"
            list_user_id = get_list_user(holpros_id)
            ids = Array(ids)
            list_user_id = Array(list_user_id)

            ids.uniq!
            list_user_id.uniq!

            ids_support      = ids
            ids_non_support  = list_user_id - ids
            create_noti(content,     holpros_id, ids_non_support, true)
            create_noti(content_sub, holpros_id, ids_support,     true)
          end
          flash[:success] = success
        end
      rescue ActiveRecord::RecordInvalid => e
        flash[:error] = "Lỗi xử lý dữ liệu: #{e.message}"
        redirect_to :back and return
      rescue => e
        flash[:error] = "Đã xảy ra lỗi không mong muốn: #{e.message}"
        redirect_to :back and return
      else
        redirect_to :back
      end
    end
    def help_caculation_change_day(f_days, t_days)
      f_days_arr = (f_days || []).reject(&:blank?)
      t_days_arr = (t_days || []).reject(&:blank?)

      to_map = ->(arr) {
        arr.each_with_object({}) do |s, h|
          next if s.blank?
          date_str, session = s.split("-", 2)
          h[date_str] = (session || "ALL").upcase
        end
      }

      weight = ->(sess) {
        case (sess || "").upcase
        when "ALL" then 1.0
        when "AM", "PM" then 0.5
        else 0.0
        end
      }

      f_map = to_map.call(f_days_arr)
      t_map = to_map.call(t_days_arr)

      removed_for_detail = []

      if t_days_arr.empty?
        removed_for_detail.concat(f_days_arr)
      else
        (f_map.keys | t_map.keys).each do |date_str|
          f_sess = f_map[date_str]
          t_sess = t_map[date_str]

          f_w = weight.call(f_sess)
          t_w = weight.call(t_sess)

          next unless f_w > t_w

          if t_sess.nil?
            removed_for_detail << "#{date_str}-#{f_sess}"
          elsif f_sess == "ALL" && t_sess == "AM"
            removed_for_detail << "#{date_str}-PM"
          elsif f_sess == "ALL" && t_sess == "PM"
            removed_for_detail << "#{date_str}-AM"
          elsif f_sess == "AM" && (t_sess.nil? || t_sess == "")
            removed_for_detail << "#{date_str}-AM"
          elsif f_sess == "PM" && (t_sess.nil? || t_sess == "")
            removed_for_detail << "#{date_str}-PM"
          else
            removed_for_detail << "#{date_str}-PARTIAL"
          end
        end
      end

      result = removed_for_detail.join("$$$")
      return result
    end

    def withdraw_used_days(holiday, delta_remove, removed_dates, holpros_id)
      return if holiday.blank? || delta_remove.to_f <= 0 || removed_dates.blank?

      delta_remove = delta_remove.to_f
      holdetail_map = holiday.holdetails.index_by(&:stype)
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
      ton, tham_nien, vi_tri = holdetail_map.values_at("TON", "THAM-NIEN", "VI-TRI")
      ton_deadline = ton&.dtdeadline&.to_date
      amount_remain       = ton&.amount.to_f
      used_remain_current = ton&.note.to_f

      ton_deadline_change      = ton&.dtdeadline&.strftime("%d/%m/%Y")
      ton_deadline_date = Date.strptime(ton_deadline_change, "%d/%m/%Y") rescue nil
      leave_dates_before_deadline = all_leave_dates.select { |date, _| date <= ton_deadline_date }
      phep_ton_da_dung_thuc_te    = leave_dates_before_deadline.sum { |_, weight| weight }
      
      
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
      skip_restore_remain = (used_remain_current == amount_remain || (used_remain_current + phep_ton_da_dung_thuc_te) >= amount_remain)
      removed_before_deadline = before_entries.any?
      allow_restore_from_ton = removed_before_deadline && !skip_restore_remain

      # Phần <= deadline: TỒN -> THÂM-NIÊN -> VỊ-TRÍ
      remain = delta_before

      tham_nien_used = tham_nien&.used.to_f
      vi_tri_used    = vi_tri&.used.to_f

      restore_from_others_first = (tham_nien_used > 0 || vi_tri_used > 0)

      if restore_from_others_first
        remain -= withdraw.call(tham_nien, remain)
        remain -= withdraw.call(vi_tri, remain)
        if allow_restore_from_ton
          remain -= withdraw.call(ton, remain)
        end
      else
        if allow_restore_from_ton
          remain -= withdraw.call(ton, remain)
        end

        remain -= withdraw.call(tham_nien, remain)
        remain -= withdraw.call(vi_tri, remain)
      end

      # Phần > deadline: THÂM-NIÊN -> VỊ-TRÍ (không TỒN)
      remain = delta_after
      remain -= withdraw.call(tham_nien, remain)
      remain -= withdraw.call(vi_tri,    remain)
    end


    def get_list_user(holpros_id)
      oMandoc = Mandoc.where(holpros_id: holpros_id)
      return [] unless oMandoc
      list_Dhandle = Mandocdhandle.where(mandoc_id: oMandoc.pluck(:id)).pluck(:id)
      return [] if list_Dhandle.empty?
      Mandocuhandle.where(mandocdhandle_id: list_Dhandle).pluck(:user_id).uniq
    end
    def create_noti(content, holpros_id, list_user_id, is_finish = false)
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
          isread: false,
          status: is_finish ? "FINISH" : nil,
        )
        if (user = User.find_by(id: uid))&.email.present?
          UserMailer.send_mail_leave_request(user.email, content).deliver_later
        end
      end
    end
    def history
      current_year = Time.current.year
      all_hol = Holiday.where(year: current_year)
      Holprosdetail.last
      @data = []
      all_hol.each do |hol|
        full_name, sid = get_user_info(hol.user_id)
        holpros = Holpro.where(holiday_id: hol.id).where.not(status: "TEMP")
        holpros.each do |item|
          @data.push(
            user_id: hol.user_id,
            sid: sid,
            full_name: full_name,
            holiday_id: hol.id,
            holpro_id: item.id
          )
        end
      end
    end

    # 03/12/2025
    def seniority
      organization = Organization.find_by(scode: "BUH")
      users = User.joins(:uorgs)
                  .where(uorgs: { organization_id: organization.id })
                  .where(status: "ACTIVE")
                  .distinct
      user_ids = users.pluck(:id)
      contracttypes = Contracttype.all.index_by(&:name)
      contracts = Contract.where(user_id: user_ids)
                          .where.not(dtfrom: nil)
      contracts_by_user = contracts
      .select { |contract|
        ctype = contracttypes[contract.name]
        ctype&.is_seniority&.include?("YES")
      }
      .group_by(&:user_id)

      @result = []
      contracts_by_user.each do |user_id, user_contracts|
          earliest = user_contracts.min_by(&:dtfrom)&.dtfrom
          next unless earliest
          formatted_dtfrom = earliest.strftime("%d/%m/%Y")
          years = ((Date.today - earliest.to_date) / 365).floor
          x = milestone_x(years)
          next unless x
          user = User.find_by(id: user_id)
          sid = user.sid
          full_name = "#{user.last_name} #{user.first_name}"
          positionjob_name, department_name = fetch_position_and_department_name_full(user_id)
          @result << { user_id: user_id, sid: sid, full_name: full_name, years: years, x: x, dtfrom: formatted_dtfrom, positionjob_name: positionjob_name, department_name: department_name}
      end
    end
    def milestone_x(years)
      milestones = [5, 10, 15, 20, 25, 30]
      return nil if years < 5

      milestones.each_with_index do |m, i|
        next_m = milestones[i + 1]
        return i + 1 if next_m.nil? && years >= m
        return i + 1 if years >= m && years < next_m
      end
      nil
    end
    def fetch_position_and_department_name_full(user_id)
        department_user = fetch_leaf_departments_by_user(user_id)
        return [nil, nil] if department_user.blank?

        department = department_user.first
        return [nil, nil] if department.nil?

        # lưu lại tên của department con đầu tiên
        child_name = department.name  

        # tìm department gốc (cha cao nhất có parents = nil)
        parent_department = department
        while parent_department&.parents.present?
          parent_department = Department.find_by(id: parent_department.parents)
        end

        # nếu có cha gốc thì format "cha - con", nếu không thì chỉ lấy tên hiện tại
        if parent_department && parent_department.id != department.id
          department_name = "#{parent_department.name} - #{child_name}"
        else
          department_name = child_name
        end

        # tìm lại positionjob_name dựa theo department của user
        work = Work.includes(:positionjob)
                  .where(user_id: user_id)
                  .where.not(positionjob_id: nil)
                  .detect { |w| w.positionjob&.department_id == department.id }

        positionjob_name = work&.positionjob&.name

        [positionjob_name, department_name]
    end
    def export_excel
      p = Axlsx::Package.new
      wb = p.workbook

      # holtypes = Holtype.where(status: "ACTIVE").pluck(:name)
      if session[:organization] == "BMU" || session[:organization] == "BMTU"
        name = "Trường"
      else
        name = "Bệnh viện"
      end
      styles = wb.styles
      header_style = styles.add_style(
        bg_color: '4F81BD', fg_color: 'FFFFFF', b: true,
        alignment: { horizontal: :center },
        border: { style: :thin, color: '000000' }
      )
      example_style = styles.add_style(
        fg_color: 'FF0000',
        i: true,
        u: true,
        alignment: { wrap_text: true },
        border: { style: :thin, color: '000000' }
      )
     note_style = styles.add_style(
        fg_color: 'FF0000',
        b: true,
        alignment: { horizontal: :center, vertical: :center, wrap_text: true },
        bg_color: 'FFFFCC',
        sz: 11
      )
      
      # Sheet chính
      wb.add_worksheet(name: "Quản lý phép cũ #{name}") do |sheet|
        # Dòng cảnh báo
        sheet.add_row ["", "", "", "", "",
              "Lưu ý: Vui lòng không để trống các dữ liệu có dấu *", "", ""],
              style: [nil, nil, nil, nil, nil, note_style, note_style, note_style],
              height: 15
        sheet.merge_cells("F1:H1")

        sheet.column_widths 8, 15, 20, 15, 22, 20, 22, 22  # 9 cột: A -> H

        # sheet.add_row ["STT", "Nhân sự làm đơn(Mã NV)", "Loại đơn", "Chi tiết thời gian nghỉ", "Lý do nghỉ", "Địa điểm", "Người nhận bàn giao(Mã NV)", "Người duyệt cuối(Mã NV)"],
        #               style: Array.new(8, header_style)
        
        # sheet.add_row ["x", "BUHxxx", "Nghỉ phép", "15/05/2025-ALL, 16/05/2025-AM, 17/05/2025-AM", "Ốm - Địa chỉ nghỉ", "trong nước hoặc\nnước ngoài - Hoa kỳ", "BUHyyyyhoặc\nBUHyyyy||BUHaaaa(2 người)", "BUHzzzz"],
        #               style: Array.new(8, example_style)
        
        sheet.add_row ["Mã nhân sự (*)", "Họ và tên", "Khoa phòng", "Phép theo vị trí công việc (*)", "Phép thâm niên (*)", "Tồn 2024 (*)", "Hạn dùng phép tồn (*)", "Đã dùng tồn (*)", "Đã dùng phép năm (*)"],
                      style: Array.new(9, header_style)
        # sheet.add_data_validation("C4:C200", {
        #   type: :list,
        #   formula1: "'Seed2'!$A$2:$A$#{holtypes.size + 1}",
        #   showDropDown: false,
        #   showErrorMessage: true,
        #   errorTitle: "Giá trị không hợp lệ",
        #   error: "Vui lòng chọn từ danh sách loại đơn."
        # })
      end

      # Sheet phụ Seed2
      # wb.add_worksheet(name: "Seed2", state: :hidden) do |seed|
      #   seed.add_row ["Loại đơn"]
      #   holtypes.each { |name| seed.add_row [name] }
      # end

      xlsx_data = p.to_stream.read
      send_data xlsx_data,
                filename: "Quan_ly_phep_cu.xlsx",
                type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
    end
    def import_excel
      errors = []
      success_count = 0
      duplicate_count = 0
      test_data = []
      current_year = Time.current.year
      if (session[:organization] & ["BMU", "BMTU"]).any?
        name = "Trường"
        organization = "BMU"
      else
        name = "Bệnh viện"
        organization = "BUH"
      end
      respond_to do |format|
        if params[:file].present? && params[:file].is_a?(ActionDispatch::Http::UploadedFile)
          begin
            file = params[:file]
            excel_datas = read_excel(file, 2)
            
            ActiveRecord::Base.transaction do
              excel_datas.each_with_index do |row, index|
                begin
                  user = find_user(row[0], index, organization)
                  # h.anh
                  # Cập nhật xóa các giá trị cũ trước khi import
                  # 16/07/2025
                  # oldHol = Holiday.where(user_id: user.id)
                  # hol_ids = oldHol.pluck(:id)
                  # allHol = Holpro.where(holiday_id: hol_ids)

                  # if allHol.blank?
                  #   Holdetail.where(holiday_id: hol_ids).delete_all
                  #   oldHol.delete_all
                  # end
                  
                  current_holiday = Holiday.where(user_id: user.id, year: current_year.to_s).first
                  if organization == "BUH"
                    holiday = Holiday.find_or_create_by(user_id: user.id, year: current_year.to_s)
                    required_columns = [3, 4, 5, 6, 7, 8]
                    missing_columns = required_columns.select { |col| row[col].blank? }
  
                    if missing_columns.any?
                      raise "Dữ liệu thiếu ở các cột: #{missing_columns.map { |c| (c + 1).to_s }.join(', ')}"
                    end
                    phep_cv = row[3].to_f
                    phep_tn = row[4].to_f
                    phep_ton = row[5].to_f
                    raw_date = row[6]
                    parsed_date =
                      case raw_date
                      when Date, DateTime
                        raw_date.to_date
                      when String
                        Date.strptime(raw_date.strip, "%d/%m/%Y") rescue nil
                      else
                        nil
                      end

                    ton_da_sd = row[7].to_f
                    nam_da_sd = row[8].to_f
                    if ton_da_sd >= 0
                      used_ton = ton_da_sd
                    else
                      used_ton = phep_ton + ton_da_sd.abs
                    end
                    # Xử lý phép tồn trước
                    holdetail_ton = Holdetail.where(holiday_id: holiday.id, name: "Phép tồn", stype: "TON").first
                    if holdetail_ton.present?
                       holdetail_ton.update!(
                          amount: phep_ton,
                          dtdeadline: parsed_date,
                          used: used_ton,
                          note: used_ton
                        )
                    else
                      Holdetail.create(
                        holiday_id: holiday.id,
                        name: "Phép tồn",
                        stype: "TON",
                        amount: phep_ton,
                        dtdeadline: parsed_date,
                        used: used_ton,
                        note: used_ton
                      )
                    end
                    today = Date.today
  
                    total = if parsed_date.present? && today <= parsed_date
                      phep_cv + phep_tn + phep_ton
                    else
                      phep_cv + phep_tn
                    end
  
                    total_used = used_ton + nam_da_sd
  
                    holiday.update(used: total_used, total: total)
                    # Xử lý phép thâm niên và phép theo vị trí
                    used_remaining = nam_da_sd
  
                    # Xử lý phép thâm niên trước
                    used_tn = [used_remaining, phep_tn].min
                    used_remaining -= used_tn
  
                    holdetail_tn = Holdetail.where(holiday_id: holiday.id,name: "Phép thâm niên", stype: "THAM-NIEN").first
                    if holdetail_tn.present?
                       holdetail_tn.update!(
                          amount: phep_tn,
                          dtdeadline: nil,
                          used: used_tn,
                          note: used_tn
                        )
                    else
                      Holdetail.create(
                        holiday_id: holiday.id,
                        name: "Phép thâm niên",
                        stype: "THAM-NIEN",
                        amount: phep_tn,
                        dtdeadline: nil,
                        used: used_tn,
                        note: used_tn
                      )
                    end
                    # Sau đó xử lý phép theo vị trí
                    used_cv = [used_remaining, phep_cv].min
                    holdetail_vt = Holdetail.where( holiday_id: holiday.id, name: "Phép theo vị trí", stype: "VI-TRI" ).first
                    if holdetail_vt.present?
                       holdetail_vt.update!(
                          amount: phep_cv,
                          dtdeadline: nil,
                          used: used_cv,
                          note: used_cv
                        )
                    else
                      Holdetail.create(
                        holiday_id: holiday.id,
                        name: "Phép theo vị trí",
                        stype: "VI-TRI",
                        amount: phep_cv,
                        dtdeadline: nil,
                        used: used_cv,
                        note: used_cv
                      )
                    end
                  elsif current_holiday.nil?
                    holiday = Holiday.create!(user_id: user.id, year: current_year.to_s)
                    required_columns = [3, 4, 5, 6, 7, 8]
                    missing_columns = required_columns.select { |col| row[col].blank? }
  
                    if missing_columns.any?
                      raise "Dữ liệu thiếu ở các cột: #{missing_columns.map { |c| (c + 1).to_s }.join(', ')}"
                    end
                    phep_cv = row[3].to_f
                    phep_tn = row[4].to_f
                    phep_ton = row[5].to_f
                    raw_date = row[6]
                    parsed_date =
                      case raw_date
                      when Date, DateTime
                        raw_date.to_date
                      when String
                        Date.strptime(raw_date.strip, "%d/%m/%Y") rescue nil
                      else
                        nil
                      end

                    ton_da_sd = row[7].to_f
                    nam_da_sd = row[8].to_f
                    if ton_da_sd >= 0
                      used_ton = ton_da_sd
                    else
                      used_ton = phep_ton + ton_da_sd.abs
                    end
                    # Xử lý phép tồn trước
                    holdetail_ton = Holdetail.where(holiday_id: holiday.id, name: "Phép tồn", stype: "TON").first
                    if holdetail_ton.present?
                       holdetail_ton.update!(
                          amount: phep_ton,
                          dtdeadline: parsed_date,
                          used: used_ton,
                          note: used_ton
                        )
                    else
                      Holdetail.create(
                        holiday_id: holiday.id,
                        name: "Phép tồn",
                        stype: "TON",
                        amount: phep_ton,
                        dtdeadline: parsed_date,
                        used: used_ton,
                        note: used_ton
                      )
                    end
                    today = Date.today
  
                    total = if parsed_date.present? && today <= parsed_date
                      phep_cv + phep_tn + phep_ton
                    else
                      phep_cv + phep_tn
                    end
  
                    total_used = used_ton + nam_da_sd
  
                    holiday.update(used: total_used, total: total)
                    # Xử lý phép thâm niên và phép theo vị trí
                    used_remaining = nam_da_sd
  
                    # Xử lý phép thâm niên trước
                    used_tn = [used_remaining, phep_tn].min
                    used_remaining -= used_tn
  
                    holdetail_tn = Holdetail.where(holiday_id: holiday.id,name: "Phép thâm niên", stype: "THAM-NIEN").first
                    if holdetail_tn.present?
                       holdetail_tn.update!(
                          amount: phep_tn,
                          dtdeadline: nil,
                          used: used_tn,
                          note: used_tn
                        )
                    else
                      Holdetail.create(
                        holiday_id: holiday.id,
                        name: "Phép thâm niên",
                        stype: "THAM-NIEN",
                        amount: phep_tn,
                        dtdeadline: nil,
                        used: used_tn,
                        note: used_tn
                      )
                    end
                    # Sau đó xử lý phép theo vị trí
                    used_cv = [used_remaining, phep_cv].min
                    holdetail_vt = Holdetail.where( holiday_id: holiday.id, name: "Phép theo vị trí", stype: "VI-TRI" ).first
                    if holdetail_vt.present?
                       holdetail_vt.update!(
                          amount: phep_cv,
                          dtdeadline: nil,
                          used: used_cv,
                          note: used_cv
                        )
                    else
                      Holdetail.create(
                        holiday_id: holiday.id,
                        name: "Phép theo vị trí",
                        stype: "VI-TRI",
                        amount: phep_cv,
                        dtdeadline: nil,
                        used: used_cv,
                        note: used_cv
                      )
                    end
                  end
                  success_count += 1
                rescue => e
                  Rails.logger.error "❌ Lỗi dòng #{index + 3}: #{e.message}"
                  errors << "Dòng #{index + 4}: #{e.message}"
                  # Không raise rollback ở đây để tiếp tục thu thập lỗi các dòng khác
                end
              end

              if errors.any?
                raise ActiveRecord::Rollback
              end
            end
            if errors.empty?
              summary_msg = "📥 Import thành công!<br>Số dòng thành công: #{success_count}"
              format.json { render json: { msg: summary_msg, success_count: success_count, duplicate_count: nil } }
              format.js { render js: "pushSuccess(#{ { msg: summary_msg }.to_json })" }
            else
              err_msg = errors.join("\\n")
              format.json { render json: { msg: "⚠️ Import thất bại:\n#{errors.join("\n")}" }, status: :unprocessable_entity }
              format.js { render js: "pushError(#{ { msg: "⚠️ Import thất bại:\\n#{err_msg}" }.to_json })" }
            end

          rescue StandardError => e
            format.json { render json: { msg: "❌ Lỗi khi xử lý file: #{e.message}" }, status: :unprocessable_entity }
            format.js { render js: "pushError(#{ { msg: "❌ Lỗi khi xử lý file: #{e.message}" }.to_json })" }
          end
        else
          format.json { render json: { msg: "❌ File không hợp lệ hoặc chưa chọn file." }, status: :unprocessable_entity }
          format.js { render js: "pushError(#{ { msg: "❌ File không hợp lệ hoặc chưa chọn file." }.to_json })" }
        end
      end
      rescue => e
      render json: { msg: "❌ Lỗi hệ thống: #{e.message}" }, status: :internal_server_error
    end


    def find_user(sid_cell, index, organization)
      sid = sid_cell.to_s.strip
      user = User.find_by(sid: sid)
      raise "Không tìm thấy người dùng với SID '#{sid}' " unless user
      uorg_scode = get_user_org_code(user)
      uorg_scode_final = if ["BMU", "BMTU"].include?(uorg_scode)
                        "BMU"
                      else
                        "BUH"
                      end
      if organization != uorg_scode_final
        raise "Người dùng với SID '#{sid}' không trùng đơn vị chủ quản"
      end
      user
    end
    def create_mandoc_handles(mandoc, user_roles)
      # Tạo danh sách user_id theo thứ tự xuất hiện đầu tiên, nhưng không loại trùng trong group role
      ordered_user_ids = []
      seen_user_ids = Set.new
      user_roles.each do |r|
        uid = r[:user_id]
        next if uid.blank?
        unless seen_user_ids.include?(uid)
          ordered_user_ids << uid
          seen_user_ids << uid
        end
      end

      # Gộp các srole_uhandle theo user_id
      grouped_roles = user_roles.group_by { |r| r[:user_id] }

      ordered_user_ids.each do |user_id|
        department = fetch_leaf_departments_by_user(user_id)
        dhandle = Mandocdhandle.create!(
          mandoc_id: mandoc.id,
          department_id: department&.id,
          srole: "LEAVE-REQUEST",
          status: "DAXULY"
        )

        created_sroles = Set.new
        grouped_roles[user_id].each do |role|
          srole = role[:srole_uhandle]
          next if created_sroles.include?(srole)
          Mandocuhandle.create!(
            mandocdhandle_id: dhandle.id,
            user_id: user_id,
            srole: srole,
            status: "DAXULY"
          )
          created_sroles << srole
        end
      end
    end

    def resolve_user_chain(sid_string, only_id, organization, index)
      if sid_string.to_s.strip.blank?
        raise "Trường Người nhận bàn giao(Mã NV)/Người duyệt cuối(Mã NV) không được để trống"
      end
      sids = sid_string.to_s.strip.split('||').map(&:strip)
      users = sids.map do |sid|
        user = User.find_by(sid: sid)
        raise "Không tìm thấy người dùng với SID '#{sid}'" unless user
        uorg_scode = get_user_org_code(user)
        if organization != uorg_scode
          raise "Người dùng với SID '#{sid}' không trùng đơn vị chủ quản"
        end
        user
      end
      return users.map(&:id) if only_id

      # Nếu chỉ 1 user, trả chuỗi theo format
      if users.size == 1
        "#{users.first.id}$$$#{users.first.last_name} #{users.first.first_name}"
      else
        # Nhiều user thì nối bằng '||'
        users.map { |u| "#{u.id}$$$#{u.last_name} #{u.first_name}" }.join('|||')
      end
    end
    def get_user_org_code(user)
      uorgs = Uorg.includes(:organization).where(user_id: user.id)
      if uorgs.count > 1
        return "BMU"
      elsif uorgs.count == 1
        return uorgs.first&.organization&.scode
      else
        return nil
      end
    end


    def resolve_holtype_code(name, index)
      holtype_code = Holtype.find_by(name: name.to_s.strip)&.code
      raise "Không tìm thấy mã loại đơn cho '#{name}' tại dòng #{index + 4}" unless holtype_code
      holtype_code
    end

    def parse_date_range(date_range_str, index)
      range = date_range_str.to_s.strip.split("-")

      if range.length == 2
        dtfrom_str, dtto_str = range
      elsif range.length == 1
        dtfrom_str = dtto_str = range[0]
      else
        raise "Định dạng ngày không hợp lệ tại dòng #{index + 4}"
      end

      [
        Date.strptime(dtfrom_str.strip, "%d/%m/%Y"),
        Date.strptime(dtto_str.strip, "%d/%m/%Y")
      ]
    rescue => e
      raise "Định dạng ngày không hợp lệ tại dòng #{index + 4}: #{e.message}"
    end


    def parse_issued_place(place_str)
      return nil if place_str.blank?

      place_str = place_str.strip.downcase

      if place_str == "trong nước"
        "IN-COUNTRY"
      elsif place_str.start_with?("nước ngoài -")
        country = place_str.sub("nước ngoài -", "").strip
        country_slug = remove_vietnamese_accents(country).upcase.gsub(/\s+/, "-")
        "#{country_slug}$$$OUT-COUNTRY"
      else
        nil
      end
    end


    


    def process_detail_times(detail_str)
      dttotal = 0.0
      details = detail_str.split(',').map do |entry|
        part = entry.strip.split('-')
        time_part = part[1]&.upcase
        case time_part
        when "ALL" then dttotal += 1.0
        when "AM", "PM" then dttotal += 0.5
        else Rails.logger.error("❌ Không xác định được thời gian nghỉ trong: #{entry}")
        end
        entry.strip # ✅ trả về entry để map hoạt động đúng
      end.join('$$$')
      [details, dttotal]
    end
    def extract_dates_from_details(details)
      details.split('$$$').map do |entry|
        date_str = entry.strip.split('-').first
        Date.parse(date_str) rescue nil
      end.compact
    end

    def manager_holiday
        # Đảm bảo người dùng đã đăng nhập
        if current_user.nil?
            redirect_to login_path, alert: "Vui lòng đăng nhập để tiếp tục."
            return
        end
        @holtypes = Holtype.where(status: "ACTIVE")

        # Đảm bảo page và per_page hợp lệ
        per_page = (params[:per_page] || 25).to_i
        per_page = [per_page, 1].max
        page = (params[:page] || 1).to_i
        page = [page, 1].max
        offset = (page - 1) * per_page

        # Xử lý tìm kiếm và tổ chức (uorg_scode)
        search = params[:search]&.strip&.downcase || ''
        @results = []

        # Lấy uorg_scode từ params hoặc mặc định từ tài khoản đăng nhập
        if params[:uorg_scode].present?
            @uorg_scode = params[:uorg_scode]
        else
            uorgs = current_user.uorgs
            @count_uorg = uorgs&.count || 0
            if uorgs.size > 1
            @uorg_scode = "BMU"
            else
            @uorg_scode = uorgs.first&.organization&.scode || "BMU"
            end
        end
        # Truy vấn cơ bản để tính tổng số bản ghi (không dùng group)
        base_query = Holpro.joins("INNER JOIN holidays ON holidays.id = holpros.holiday_id")
                            .joins("INNER JOIN users ON users.id = holidays.user_id")
                            .joins("INNER JOIN holprosdetails ON holprosdetails.holpros_id = holpros.id")
                            .joins("INNER JOIN mandocs ON mandocs.holpros_id = holpros.id")
                            .joins("INNER JOIN mandocdhandles ON mandocdhandles.mandoc_id = mandocs.id")
                            .joins("INNER JOIN mandocuhandles ON mandocuhandles.mandocdhandle_id = mandocdhandles.id")
                            .joins("LEFT JOIN uorgs ON uorgs.user_id = users.id")
                            .joins("LEFT JOIN works ON works.user_id = users.id")
                            .joins("LEFT JOIN positionjobs ON positionjobs.id = works.positionjob_id")
                            .joins("LEFT JOIN departments ON departments.id = positionjobs.department_id")
                            .where("LOWER(users.sid) LIKE :search OR LOWER(CONCAT(users.last_name, ' ', users.first_name)) LIKE :search", search: "%#{search}%")
                            .where.not("departments.name = 'Quản lý ERP'")
                            .where.not('holpros.status = "TEMP"')

        # Lấy danh sách departments dựa trên uorg_scode
        case @uorg_scode
        when "BUH"
            @departments_buh = Department.where(organization_id: Organization.where(scode: "BUH").select(:id), parents: [nil , ""]).where.not(name: "Quản lý ERP")
            base_query = base_query.where(uorgs: { organization_id: Organization.where(scode: "BUH").select(:id) }).distinct
        when "BMU"
            @departments_bmu = Department.where(organization_id: Organization.where(scode: ["BMU", "BMTU"]).select(:id)).where.not(name: "Quản lý ERP")
            base_query = base_query.where(uorgs: { organization_id: Organization.where(scode: ["BMU", "BMTU"]).select(:id) }).distinct
        when "BMTU"
            @departments_bmu = Department.where(organization_id: Organization.where(scode: ["BMU", "BMTU"]).select(:id)).where.not(name: "Quản lý ERP")
            base_query = base_query.where(uorgs: { organization_id: Organization.where(scode: ["BMU", "BMTU"]).select(:id) }).distinct
        end


        # Lọc theo department nếu có tham số
        if params[:department_bmu].present? && (@uorg_scode == "BMU" || @uorg_scode == "BMTU")
            base_query = base_query.where("positionjobs.department_id = ?", params[:department_bmu].to_i)
            .where("LOWER(users.sid) LIKE :search OR LOWER(CONCAT(users.last_name, ' ', users.first_name)) LIKE :search", search: "%#{search}%")
        elsif params[:department_buh].present? && @uorg_scode == "BUH"
            all_dept_ids = fetch_all_related_department_ids([params[:department_buh].to_i])

            base_query = base_query.where(positionjobs: { department_id: all_dept_ids })
               .where("LOWER(users.sid) LIKE :search OR LOWER(CONCAT(users.last_name, ' ', users.first_name)) LIKE :search", search: "%#{search}%")

        end

        # Lọc theo issued_place từ holprosdetails
        issued_place_filter = nil
        if params[:country_bmu].present? && (@uorg_scode == "BMU" || @uorg_scode == "BMTU")
            issued_place_filter = params[:country_bmu] == "IN-COUNTRY" ? "IN-COUNTRY" : "OUT-COUNTRY"
        elsif params[:country_buh].present? && @uorg_scode == "BUH"
            issued_place_filter = params[:country_buh] == "IN-COUNTRY" ? "IN-COUNTRY" : "OUT-COUNTRY"
        end

        if issued_place_filter
            base_query = base_query.where("holprosdetails.issued_place LIKE ?", "%#{issued_place_filter}%" )
            .where("LOWER(users.sid) LIKE :search OR LOWER(CONCAT(users.last_name, ' ', users.first_name)) LIKE :search", search: "%#{search}%")
        end
        if params[:status].present?
          if params[:status] == "PENDING"
            # xử lý riêng cho PENDING
            base_query = base_query.where("holpros.status = ? OR holpros.status = ?", "PENDING", "CANCEL-PENDING").where("LOWER(users.sid) LIKE :search OR LOWER(CONCAT(users.last_name, ' ', users.first_name)) LIKE :search", search: "%#{search}%")
            # hoặc logic tùy bạn muốn
          else
            base_query = base_query.where("holpros.status = ?", params[:status]).where("LOWER(users.sid) LIKE :search OR LOWER(CONCAT(users.last_name, ' ', users.first_name)) LIKE :search", search: "%#{search}%")
          end
        end

        # Lọc theo loại phép
        holtype_filter = nil
        if params[:holtype_bmu].present? && (@uorg_scode == "BMU" || @uorg_scode == "BMTU")
            holtype_filter = params[:holtype_bmu]
        elsif params[:holtype_buh].present? && @uorg_scode == "BUH"
            holtype_filter = params[:holtype_buh]
        end

        if holtype_filter
            base_query = base_query.where(holprosdetails: { sholtype: holtype_filter })
            .where("LOWER(users.sid) LIKE :search OR LOWER(CONCAT(users.last_name, ' ', users.first_name)) LIKE :search", search: "%#{search}%")
        end

        # Lọc theo thời gian (date_range)
        date_range_filter = nil
        if params[:date_range_bmu].present? && (@uorg_scode == "BMU" || @uorg_scode == "BMTU")
            date_range_filter = params[:date_range_bmu]
        elsif params[:date_range_buh].present? && @uorg_scode == "BUH"
            date_range_filter = params[:date_range_buh]
        end

        if date_range_filter
            start_date, end_date = date_range_filter.split(" - ")
            start_date = Date.parse(start_date) rescue nil
            end_date = Date.parse(end_date) rescue nil
            if start_date && end_date
            base_query = base_query.where("holpros.dtfrom >= ? AND holpros.dtto <= ?", start_date, end_date)
            end
        end

        # Tổng số bản ghi (dùng base_query mà không group)
        @results_total = base_query.count

        # Truy vấn chính với group để lấy dữ liệu
        query = base_query.group("holpros.id")

        # Tổng số trang
        @total_pages = (@results_total.to_f / per_page).ceil

        # Truy vấn dữ liệu chính với phân trang
        raw_results = query.select(
          'holpros.id AS holpro_id',
          'holpros.note AS note',
          'holidays.id AS holiday_id',
          'users.id AS user_id',
          'users.sid AS user_sid',
          "CONCAT(users.last_name, ' ', users.first_name) AS user_fullname",
          'positionjobs.name AS positionjob_name',
          'holpros.dttotal AS holiday_total_days',
          'holpros.status AS holiday_status',
          'holpros.dtfrom AS holiday_from',
          'holpros.dtto AS holiday_to',
          'holprosdetails.issued_place AS issued_place',
          'mandocuhandles.user_id AS approver_user_id'
        ).order('holpros.created_at DESC')
        .limit(per_page)
        .offset(offset)

        @results = raw_results.map do |row|
          {
            'holpro_id'          => row.holpro_id,
            'note'               => row.note,
            'holiday_id'         => row.holiday_id,
            'user_id'            => row.user_id,
            'user_sid'           => row.user_sid,
            'user_fullname'      => row.user_fullname,
            'positionjob_name'   => row.positionjob_name,
            'holiday_total_days' => row.holiday_total_days,
            'holiday_status'     => row.holiday_status,
            'holiday_from'       => row.holiday_from,
            'holiday_to'         => row.holiday_to,
            'issued_place'       => row.issued_place,
            'approver_user_id'   => row.approver_user_id,
            # đây là hàm mới lấy tên phòng ban cha
            'department_name'    => fetch_position_and_root_department(row.user_id),
            'details_holpros'    => format_holiday_details_by_holpro(row.holpro_id)

          }
        end


        # Lấy tất cả holpro_ids từ kết quả
        holpro_ids = @results.map { |holpro| holpro['holpro_id'] }.compact.uniq

        # 1. Truy vấn chi tiết phép từ bảng holprosdetails
        @holprosdetails_data = if holpro_ids.present?
                                Holprosdetail.where(holpros_id: holpro_ids)
                                            .select(:id, :holpros_id, :sholtype, :dtfrom, :dtto, :handover_receiver, :issued_place, :place_before_hol, :issued_national, :note, :details)
                                else
                                []
                                end

        # 2. Lấy chuỗi tên loại phép từ holprosdetails và holtypes
        sholtypes = @holprosdetails_data.pluck(:sholtype).uniq
        holtypes_data = Holtype.where(code: sholtypes).select(:code, :name).to_a
        @holtypes_map = holtypes_data.each_with_object({}) { |holtype, hash| hash[holtype.code] = holtype.name }

        # Khởi tạo hash để lưu kết quả
        @holpro_types = {}
        @holpro_locations = {}
        @holpro_handover_names = {}

        if @holprosdetails_data.present?
            # Nhóm dữ liệu theo holpro_id để xử lý @holpro_types
            grouped_data = @holprosdetails_data.group_by(&:holpros_id)

            grouped_data.each do |holpro_id, details|
                # Xử lý @holpro_types: nối các type_name cho cùng holpro_id
                type_names = details.map { |detail| @holtypes_map[detail.sholtype] || "Không xác định" }.uniq.compact
                @holpro_types[holpro_id] = type_names.join(", ")

                # Xử lý @holpro_locations và @holpro_handover_names cho từng holprosdetails
                details.each do |detail|
                    holprosdetails_id = detail.id

                    # Phân tích issued_place để lấy scode quốc gia
                    if  detail.issued_place != "IN-COUNTRY"
                        scode = detail.issued_place&.split('$$$')&.first
                        # Truy vấn bảng Nationality để lấy tên quốc gia
                        nationality = Nationality.find_by(scode: scode)
                        location_name = nationality&.name || "Nước ngoài không xác định"
                        @holpro_locations[holprosdetails_id] = location_name
                    else
                        @holpro_locations[holprosdetails_id] = ""
                    end

                    # Xử lý handover_receiver để lấy danh sách người nhận bàn giao
                    handover_names = []
                    handover_receiver = detail.handover_receiver
                    if handover_receiver.present?
                        # Trích xuất danh sách user_id từ handover_receiver
                        receiver_ids = handover_receiver.split('|||').map do |receiver|
                            user_id = receiver.split('$$$').first
                            user_id.to_i if user_id.present? && user_id.match?(/\d+/)
                        end.compact

                        # Nếu có user_id, lấy thông tin từ bảng User
                        if receiver_ids.present?
                            users = User.where(id: receiver_ids).select(:id, :sid, :last_name, :first_name)
                            users.each do |user|
                                full_name = "#{user.last_name} #{user.first_name}".strip.presence || "Không xác định"
                                sid = user.sid.presence || "Không xác định"
                                formatted_name = "#{full_name} (#{sid})"
                                handover_names << formatted_name
                            end
                        end
                    end
                    @holpro_handover_names[holprosdetails_id] = handover_names.join(", ") || "Không có người nhận bàn giao"
                end
            end
        end

        # 3. Truy vấn người duyệt phép từ mandocuhandles và users
        @holpro_approvers = {}

        if holpro_ids.present?
            # Lấy danh sách mandoc_ids và liên kết với Holpro để lấy user_id của người tạo
            mandoc_ids = Mandoc.where(holpros_id: holpro_ids).select(:id, :holpros_id, :status).group_by(&:holpros_id)

            # Lấy thông tin user_id của người tạo đơn từ Holpro và Holidays
            creator_user_ids = Holpro.where(id: holpro_ids)
                                    .joins(:holiday)
                                    .pluck(:id, 'holidays.user_id')
                                    .to_h
            if mandoc_ids.present?
                mandoc_ids.each do |holpros_id, mandocs|
                    mandoc = mandocs.first
                    next unless mandoc

                    # Lấy user_id của người tạo đơn cho holpro_id này
                    creator_user_id = creator_user_ids[holpros_id.to_i]

                    approver_data = Mandocdhandle.joins("INNER JOIN mandocuhandles ON mandocuhandles.mandocdhandle_id = mandocdhandles.id")
                                                .joins("INNER JOIN users ON users.id = mandocuhandles.user_id")
                                                .where(mandoc_id: mandoc.id)
                                                .where.not("mandocuhandles.srole = 'SUB'")
                                                .where.not("mandocuhandles.user_id = ?", creator_user_id) # Loại trừ người tạo
                                                .select("mandocdhandles.id, mandocuhandles.id AS mandocuhandle_id, CONCAT(users.last_name, ' ', users.first_name) AS approver_name, mandocuhandles.updated_at")
                                                .distinct
                                                .order("mandocdhandles.id DESC, mandocuhandles.id DESC")
                                                .limit(1) # Lấy người duyệt đầu tiên
                                                .to_a

                    # Nếu có dữ liệu, lấy thông tin người duyệt; nếu không, gán giá trị mặc định
                    if approver_data.present?
                        @holpro_approvers[holpros_id] = approver_data.map { |data| { name: data.approver_name, updated_at: data.updated_at } }
                    else
                        @holpro_approvers[holpros_id] = [{ name: "Không có người duyệt", updated_at: nil }]
                    end
                end
            end
        else
            @holpro_approvers = {}
        end

        # 4. Lấy chi tiết quá trình xử lý cho modal, bao gồm chức vụ
        @mandoc_details = {}
        @mandoc_details_cancel = {}

        if mandoc_ids.present?
          mandoc_ids.each do |holpros_id, mandocs|
            mandoc = mandocs.select { |m| m.status != "CANCEL-PENDING" }.first
            mandoc_cancel = mandocs.select { |m| m.status == "CANCEL-PENDING" }.first

            next unless mandoc

            @mandoc_details[holpros_id] = Mandocdhandle
              .with_main_handler_info
              .where(mandoc_id: mandoc.id)
              .uniq(&:handler_name)

            if mandoc_cancel
              @mandoc_details_cancel[holpros_id] = Mandocdhandle
                .with_main_handler_info
                .where(mandoc_id: mandoc_cancel.id)
                .uniq(&:handler_name)
            end
          end
        end


        # 5. Lấy tên quốc gia

        # Lưu page và per_page để sử dụng trong view
        @page = page
        @per_page = per_page
    end

    # In đơn
    def generated_leave_request
      holpro_id = params[:holpro_id]
      holpro = Holpro.where(id: holpro_id).first
      data = []
      if !holpro.nil?
        holiday = Holiday.where(id: holpro.holiday_id).first
        user = User.where(id: holiday.user_id).first
        oAddressUser = Address.where(user_id: user&.id, stype: "Thường Trú", status: "ACTIVE").last
        address_parts = [
          oAddressUser&.no,
          oAddressUser&.street,
          oAddressUser&.ward,
          oAddressUser&.district,
          oAddressUser&.city,
          oAddressUser&.province,
          oAddressUser&.country
        ]

        full_address = address_parts.compact.reject(&:blank?).join(", ")

        oWork = Work.where(user_id: holiday.user_id)
                  .where("positionjob_id IS NOT NULL")
                  .first

        oPositionjob = Positionjob.where(id: oWork&.positionjob_id).first
        position_name = oPositionjob&.name || ""

        # department_name = Department.where(id: oPositionjob&.department_id).first&.name || ""
        department_name = fetch_position_and_root_department(user&.id) || ""

        organization = []
        oUorgs = Uorg.where(user_id: holiday.user_id)
        if oUorgs.present?
          oUorgs.each do |oUorg|
            oOgnization = Organization.where(id: oUorg&.organization_id).first
            if oOgnization.present?
              organization.push(oOgnization&.scode)
            end
          end
        end

        holdetails = holpro.holprosdetails

        date_created = holpro&.created_at&.strftime("ngày %d tháng %m năm %Y") || "ngày ... tháng ... năm ..."

        data = {user: user, holdetails: holdetails, positionjob: position_name, organization: organization, department_name: department_name, date_created: date_created, dttotal: holpro.dttotal, address: full_address}
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
    def format_holiday_details_by_holpro(holpro_id)
      # Lấy toàn bộ details của holprosdetails
      details_strings = Holprosdetail.where(holpros_id: holpro_id).pluck(:details).compact

      # Ghép tất cả details thành một mảng item "ngày-buổi"
      all_items = []
      details_strings.each do |detail_str|
        next if detail_str.blank?
        detail_str.split('$$$').each do |item|
          date_str, session = item.split('-')
          date = Date.strptime(date_str, '%d/%m/%Y') rescue nil
          all_items << [date, session] if date
        end
      end

      return "" if all_items.blank?

      # Sắp xếp theo ngày
      all_items.sort_by! { |d, _| d }

      results = []
      temp_range = [] # chứa các ngày ALL liên tiếp

      all_items.each_with_index do |(date, session), index|
        if session == 'ALL'
          if temp_range.empty?
            temp_range << date
          else
            # kiểm tra liên tiếp
            if (date - temp_range.last).to_i == 1
              temp_range << date
            else
              # đóng range cũ
              results << format_range(temp_range)
              temp_range = [date]
            end
          end
        else
          # đóng range cũ trước đó nếu có
          unless temp_range.empty?
            results << format_range(temp_range)
            temp_range = []
          end
          # add ngày buổi sáng/chiều riêng
          buoi = session == 'AM' ? 'buổi sáng' : 'buổi chiều'
          results << "#{date.strftime('%d/%m/%Y')}(#{buoi})"
        end

        # cuối vòng lặp
        if index == all_items.size - 1 && temp_range.any?
          results << format_range(temp_range)
        end
      end

      results.join(', ')
    end

    def format_range(range_dates)
      return "" if range_dates.blank?
      if range_dates.size == 1
        "ngày #{range_dates.first.strftime('%d/%m/%Y')}"
      else
        "từ #{range_dates.first.strftime('%d/%m/%Y')} đến #{range_dates.last.strftime('%d/%m/%Y')}"
      end
    end

    # xuất excel theo mẫu
    def export_holiday
      stype_uorg = params[:stype_uorg]
      stype_export = params[:stype_export]

      
      year_export_year = params[:year_export_year]
      datas_year = []
      
      year_export_month = params[:year_export_month]
      month_export_month = params[:month_export_month]
      datas_month = []

      if stype_uorg.present?
        oUsers = User.joins(uorgs: :organization).select("users.*, organizations.scode AS organization_scode").where(organizations: { scode: stype_uorg })
        oUsers.each_with_index do |user, index|
          name_positionjob = ""
          name_department = ""
          oWork = Work.where(user_id: user.id).where.not(positionjob_id: nil).first
          if oWork.present?
            oPositionjob =  Positionjob.where(id: oWork&.positionjob_id).first
            if oPositionjob.present?
              oDepartment = Department.where(id: oPositionjob.department_id).first
              if oDepartment.present?
                name_positionjob = oPositionjob&.name
                name_department = oDepartment&.name
              end
            end
          end
          
          
          if stype_export == "year"
            # Khởi tạo mảng số ngày nghỉ
            monthly_leave_days = Array.new(12, 0.0)
            # Lấy ngày nghỉ theo năm
            oHoliday = Holiday.where(user_id: user&.id, year: year_export_year).first

            total = oHoliday&.total&.to_f || 0.0 # Mặc định 0.0 nếu nil
            used = oHoliday&.used&.to_f || 0.0   # Mặc định 0.0 nếu nil
            conlai = total - used

            # Lấy số ngày nghỉ theo tháng
            monthly_leave_days = parse_holiday_details(user.id, year_export_year.to_i)
            # Đảm bảo monthly_leave_days có đúng 12 phần tử kiểu Float
            monthly_leave_days = Array.new(12, 0.0) unless monthly_leave_days.is_a?(Array) && monthly_leave_days.length == 12
            if name_department.present?
              datas_year.push([
                user.sid || "",
                "#{user.last_name || ''} #{user.first_name || ''}".strip,
                name_department, 
                get_earliest_contract_date(user), # THỜI GIAN BẮT ĐẦU LÀM VIỆC (String)
                total, # Ngày phép năm (Float)
                *monthly_leave_days, # 12 cột cho các tháng (Float)
                used, 
                conlai, 
                conlai > 0 ? "CÒN PHÉP" : "HẾT PHÉP" 
              ])
            end
          else
            # Lấy thông tin nghỉ chi tiết
            data = parse_holiday_details_date(user.id, year_export_month.to_i, month_export_month.to_i)
            
            if name_department.present?
              datas_month.push([
                  user.sid || "",
                  "#{user.last_name || ''} #{user.first_name || ''}".strip,
                  name_department, 
                  name_positionjob,
                  get_earliest_contract_date(user),
                  "", # Ngày nghỉ việc
                  *data[:leave_days],
                  count_days_excluding_sundays(year_export_month.to_i, month_export_month.to_i), #NC CHUẨN TRONG THÁNG
                  data[:nc_tong],
                  data[:nghi_phep],
                  data[:nghi_bu],
                  data[:di_hoc],
                  data[:nghi_che_do],
                  data[:nghi_le_tet],
                  data[:hoc_viec],
                  data[:khong_luong],
                  data[:che_do_bhxh],
                  data[:thai_san]
              ])
            end
          end
        end

        # Tạo excel package
        if stype_export == "year"
          workbook = export_excel_year(datas_year, year_export_year)
          file_name = "Danh sách theo dõi ngày phép năm #{year_export_year}.xlsx"
        else
          workbook = export_excel_month(datas_month, year_export_month, month_export_month)
          file_name = "Bảng chấm công tháng #{month_export_month} năm #{year_export_month}.xlsx"
        end
        
        ## Gửi data để tải xuống
        send_data   workbook.to_stream.read,
                filename: file_name,
                type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                disposition: 'attachment'
      end
    end

    # Biểu mẫu excel
    def export_excel_year(datas, year)
      package = Axlsx::Package.new
      workbook = package.workbook
      year = year
      sheet = workbook.add_worksheet(name: 'Sheet1')
      cols_left_style = workbook.styles.add_style(font_name:"Times",bg_color: "",border: { style: :thin, color: '00000000'},alignment: {horizontal: :left ,vertical: :center, wrap_text: true},sz: 12)
      cols_center_style = workbook.styles.add_style(font_name:"Times",bg_color: "",border: { style: :thin, color: '00000000'},alignment: {horizontal: :center ,vertical: :center},sz: 12)
      signed_style = workbook.styles.add_style(font_name:"Times",sz: 14, alignment: {horizontal: :center ,vertical: :center}, b: true)
      
      custom_header_export_excel_year(workbook, sheet, year)
      
      datas.each_with_index do |row, index|
          new_row = [index] + row
          added_row = sheet.add_row(new_row, style: cols_center_style)
          row_index = added_row.row_index
          sheet.rows[row_index].cells[2].style = cols_left_style
          sheet.rows[row_index].cells[3].style = cols_left_style
      end

      sheet.add_row()

      signed_bgh = "BAN GIÁM HIỆU"
      signed_tchc = "P.TCHC"
      signed_create = "NGƯỜI LẬP"
      signed_row = sheet.add_row(["",signed_bgh,"","","","",signed_tchc,"","","","","","","",signed_create],height:20, style:signed_style)
      
      
      # Xác định chỉ số dòng của hàng ký tên
      if signed_row
        # Xác định chỉ số dòng của hàng ký tên
          signed_row_index = signed_row.row_index + 1 # +1 vì Excel đếm từ 1, không phải 0
          # Merge các ô cho các chữ ký
          sheet.merge_cells("B#{signed_row_index}:D#{signed_row_index}") # Merge BAN GIÁM HIỆU
          sheet.merge_cells("G#{signed_row_index}:N#{signed_row_index}") # Merge cho P.TCHC
          sheet.merge_cells("O#{signed_row_index}:U#{signed_row_index}") # Merge cho NGƯỜI LẬP
      else
        Rails.logger.error "Failed to add signature row"
      end

      # Độ rộng cột (18 cột: A to S)
      sheet.column_widths 7, 15, 25, 30, 15, 12, *[7] * 12, 10, 10
      package
    end

    def custom_header_export_excel_year(workbook, sheet, year)
      # Style
      default_font = workbook.styles.add_style(font_name:"Times",sz: 12)
      org_name_style = workbook.styles.add_style(font_name:"Times",sz: 12, alignment: {horizontal: :center ,vertical: :center})
      department_name_style = workbook.styles.add_style(font_name:"Times",sz: 12, alignment: {horizontal: :center ,vertical: :center}, b: true)
      horizontal_center = workbook.styles.add_style(font_name:"Times",alignment: {horizontal: :center ,vertical: :center},sz: 16, b: true)
      title_css = workbook.styles.add_style(font_name:"Times",border: { style: :thin, color: '00000000'},alignment: {horizontal: :center ,vertical: :center},sz: 12, b: true)
      cols_left_style = workbook.styles.add_style(font_name:"Times",bg_color: "",fg_color: '305496',border: { style: :thin, color: '00000000'},alignment: {horizontal: :left ,vertical: :center},sz: 12, b: true)
      cols_center_style = workbook.styles.add_style(font_name:"Times",bg_color: "",fg_color: '305496',border: { style: :thin, color: '00000000'},alignment: {horizontal: :center ,vertical: :center, wrap_text: true},sz: 12, b: true)
      b = workbook.styles.add_style(font_name:"Times",alignment: {horizontal: :left ,vertical: :center},sz: 12, b: true)
      
      # datas
      org_name = "BỘ GIÁO DỤC VÀ ĐÀO TẠO"
      department_name = "TRƯỜNG ĐẠI HỌC Y DƯỢC BUÔN MA THUỘT"
      chxhcnvn = "CỘNG HÒA XÃ HỘI CHỦ NGHĨA VIỆT NAM"
      dltdhp = "Độc lập - Tự do - Hạnh phúc"
      table_name = "DANH SÁCH THEO DÕI NGÀY PHÉP NĂM #{year}"

      # Tiêu đề
      sheet.add_row([org_name,"","","","","","",chxhcnvn],height:15, style:org_name_style)
      sheet.merge_cells("A1:G1")
      sheet.merge_cells("H1:U1")
      
      added_row = sheet.add_row([department_name,"","","","","","",dltdhp],height:15, style:department_name_style)
      row_index = added_row.row_index
      
      sheet.merge_cells("A2:G2")
      sheet.merge_cells("H2:U2")

      # Tên bảng
      sheet.add_row([table_name],height: 30, style: horizontal_center)
      sheet.merge_cells("A3:U3")

      added_row = sheet.add_row(["STT","MSNV","HỌ VÀ TÊN","ĐƠN VỊ","THỜI GIAN BẮT ĐẦU LÀM VIỆC", "Ngày phép #{year}", *(1..12).map { |month| "Tháng #{month}" }, "Đã nghỉ", "Còn lại", "Ghi chú"], height: 50, style: cols_center_style)
      row_index = added_row.row_index
      sheet.rows[row_index].cells[2].style = cols_left_style
      sheet.rows[row_index].cells[3].style = cols_left_style
    end

    # Biểu mẫu bảng chấm công
    def export_excel_month(datas, year, month)
      package = Axlsx::Package.new
      workbook = package.workbook
      year = year
      month = month
      
      sheet = workbook.add_worksheet(name: 'Sheet1')
      cols_left_style = workbook.styles.add_style(font_name:"Times",bg_color: "",border: { style: :thin, color: '00000000'},alignment: {horizontal: :left ,vertical: :center, wrap_text: true},sz: 12)
      cols_center_style = workbook.styles.add_style(font_name:"Times",bg_color: "",border: { style: :thin, color: '00000000'},alignment: {horizontal: :center ,vertical: :center},sz: 12)
      signed_style = workbook.styles.add_style(font_name:"Times",sz: 14, alignment: {horizontal: :center ,vertical: :center}, b: true)
      department_name_style = workbook.styles.add_style(font_name:"Times",sz: 12, alignment: {horizontal: :center ,vertical: :center}, b: true)

     
      style_i_center = workbook.styles.add_style(
        font_name: "Times",
        alignment: { horizontal: :center, vertical: :center },
        sz: 11,
        b: false,
        i: true
      )

      style_i_left = workbook.styles.add_style(
        font_name: "Times",
        alignment: { horizontal: :left ,vertical: :center},
        sz: 11,
        b: false,
        i: true
      )

      note_center_underline_bold = workbook.styles.add_style(
        font_name: "Times",
        alignment: { horizontal: :left ,vertical: :center},
        sz: 14,
        b: true,
        u: true,
        i: true
      )
      
      custom_header_export_excel_month(workbook, sheet, year, month)
      
      datas.each_with_index do |row, index|
          new_row = [index + 1] + row
          added_row = sheet.add_row(new_row, style: cols_center_style)
          row_index = added_row.row_index
          sheet.rows[row_index].cells[3].style = cols_left_style
          sheet.rows[row_index].cells[4].style = cols_left_style
          sheet.rows[row_index].cells[5].style = cols_left_style
      end

      
      sheet.add_row()

      date_signed_row = sheet.add_row([""] * 43 + [format_current_date], height: 20, style: style_i_center)
      # Xác định chỉ số dòng
      if date_signed_row
        # Xác định chỉ số dòng của hàng ký tên
          date_signed_row_index = date_signed_row.row_index + 1 # +1 vì Excel đếm từ 1, không phải 0
          # Merge các ô cho các chữ ký
          sheet.merge_cells("AR#{date_signed_row_index}:AW#{date_signed_row_index}") # Merge BAN GIÁM HIỆU
      else
        Rails.logger.error "Failed to add signature row"
      end

      user_signed_row = sheet.add_row([""] * 43 + ["NGƯỜI LẬP"], height: 20, style: department_name_style)
      # Xác định chỉ số dòng
      if user_signed_row
        # Xác định chỉ số dòng của hàng ký tên
          user_signed_row_index = user_signed_row.row_index + 1 # +1 vì Excel đếm từ 1, không phải 0
          # Merge các ô cho các chữ ký
          sheet.merge_cells("AR#{user_signed_row_index}:AW#{user_signed_row_index}") # Merge BAN GIÁM HIỆU
      else
        Rails.logger.error "Failed to add signature row"
      end

      # Thêm 6 dòng trống
      sheet.add_row()
      sheet.add_row()
      sheet.add_row()
      sheet.add_row()
      sheet.add_row()
      sheet.add_row()

      # Dòng ghi chú
      note_title = sheet.add_row(["Ghi chú:"],height: 20, style: note_center_underline_bold)
      # Xác định chỉ số dòng
      if note_title
        # Xác định chỉ số dòng của hàng ký tên
          note_title_index = note_title.row_index + 1 # +1 vì Excel đếm từ 1, không phải 0
          # Merge các ô cho các chữ ký
          sheet.merge_cells("A#{note_title_index}:B#{note_title_index}") # Merge 
      else
        Rails.logger.error "Failed to add signature row"
      end

      note_title_line1 = sheet.add_row([""] + ["- Ngày công đi làm: X"] + [""] * 3 + ["- Học việc: HV"] + [""] * 9 + ["- Nghỉ thai sản: TS"],height: 16, style: style_i_left)
      # Xác định chỉ số dòng
      if note_title_line1
        # Xác định chỉ số dòng của hàng ký tên
          note_title_line1_index = note_title_line1.row_index + 1 # +1 vì Excel đếm từ 1, không phải 0
          # Merge các ô cho các chữ ký
          sheet.merge_cells("B#{note_title_line1_index}:D#{note_title_line1_index}") # Merge 
          sheet.merge_cells("F#{note_title_line1_index}:K#{note_title_line1_index}") # Merge 
          sheet.merge_cells("P#{note_title_line1_index}:I#{note_title_line1_index}") # Merge 
      else
        Rails.logger.error "Failed to add signature row"
      end

      note_title_line2 = sheet.add_row([""] + ["- Đi làm 1/2 ngày + nghỉ phép 1/2 ngày: X/P"] + [""] * 3 + ["- Đi công tác, đào tạo: CT"] + [""] * 9 + ["- Nghỉ hưởng lương (tang chế, cưới): CD"],height: 16, style: style_i_left)
      # Xác định chỉ số dòng
      if note_title_line2
        # Xác định chỉ số dòng của hàng ký tên
          note_title_line2_index = note_title_line2.row_index + 1 # +1 vì Excel đếm từ 1, không phải 0
          # Merge các ô cho các chữ ký
          sheet.merge_cells("B#{note_title_line2_index}:D#{note_title_line2_index}") # Merge 
          sheet.merge_cells("F#{note_title_line2_index}:K#{note_title_line2_index}") # Merge 
          sheet.merge_cells("P#{note_title_line2_index}:I#{note_title_line2_index}") # Merge 
      else
        Rails.logger.error "Failed to add signature row"
      end
      
      note_title_line3 = sheet.add_row([""] + ["- Đi làm 1/2 ngày + nghỉ bù 1/2 ngày: X/NB"] + [""] * 3 + ["- Đi công tác, đào tạo buổi 1/2 ngày + nghỉ không lương 1/2 ngày: H/KL"] + [""] * 9 + ["- Nghỉ chế độ 1/2 ngày + nghỉ không lương 1/2 ngày: CD/KL"],height: 16, style: style_i_left)
      # Xác định chỉ số dòng
      if note_title_line3
        # Xác định chỉ số dòng của hàng ký tên
          note_title_line3_index = note_title_line3.row_index + 1 # +1 vì Excel đếm từ 1, không phải 0
          # Merge các ô cho các chữ ký
          sheet.merge_cells("B#{note_title_line3_index}:D#{note_title_line3_index}") # Merge 
          sheet.merge_cells("F#{note_title_line3_index}:K#{note_title_line3_index}") # Merge 
          sheet.merge_cells("P#{note_title_line3_index}:I#{note_title_line3_index}") # Merge 
      else
        Rails.logger.error "Failed to add signature row"
      end
      
      note_title_line4 = sheet.add_row([""] + ["- Đi làm 1/2 ngày + nghỉ chế độ 1/2 ngày: X/CD"] + [""] * 3 + ["- Ca làm việc 24h ngày thường (Ca hành chính + trực đêm): X/T"] + [""] * 9 + ["- Nghỉ hưởng BHXH (bản thân ốm,con ốm..): BH"],height: 16, style: style_i_left)
      # Xác định chỉ số dòng
      if note_title_line4
        # Xác định chỉ số dòng của hàng ký tên
          note_title_line4_index = note_title_line4.row_index + 1 # +1 vì Excel đếm từ 1, không phải 0
          # Merge các ô cho các chữ ký
          sheet.merge_cells("B#{note_title_line4_index}:D#{note_title_line4_index}") # Merge 
          sheet.merge_cells("F#{note_title_line4_index}:K#{note_title_line4_index}") # Merge 
          sheet.merge_cells("P#{note_title_line4_index}:I#{note_title_line4_index}") # Merge 
      else
        Rails.logger.error "Failed to add signature row"
      end
      
      note_title_line5 = sheet.add_row([""] + ["- Đi làm 1/2 ngày + nghỉ không lương 1/2 ngày: X/KL"] + [""] * 3 + ["- Đi làm 1/2 ngày + nghỉ lễ 1/2 ngày: X/L"] + [""] * 9 + ["- Nghỉ hưởng BHXH 1/2 ngày (bản thân ốm, con ốm) + 1/2 ngày nghỉ không lương: BH/KL"],height: 16, style: style_i_left)
      # Xác định chỉ số dòng
      if note_title_line5
        # Xác định chỉ số dòng của hàng ký tên
          note_title_line5_index = note_title_line5.row_index + 1 # +1 vì Excel đếm từ 1, không phải 0
          # Merge các ô cho các chữ ký
          sheet.merge_cells("B#{note_title_line5_index}:D#{note_title_line5_index}") # Merge 
          sheet.merge_cells("F#{note_title_line5_index}:K#{note_title_line5_index}") # Merge 
          sheet.merge_cells("P#{note_title_line5_index}:I#{note_title_line5_index}") # Merge 
      else
        Rails.logger.error "Failed to add signature row"
      end
      
      note_title_line6 = sheet.add_row([""] + ["- Đi làm 1/2 ngày + Đi công tác, đào tạo 1/2 ngày: X/H"],height: 16, style: style_i_left)
      # Xác định chỉ số dòng
      if note_title_line6
        # Xác định chỉ số dòng của hàng ký tên
          note_title_line6_index = note_title_line6.row_index + 1 # +1 vì Excel đếm từ 1, không phải 0
          # Merge các ô cho các chữ ký
          sheet.merge_cells("B#{note_title_line6_index}:D#{note_title_line6_index}") # Merge 
          sheet.merge_cells("F#{note_title_line6_index}:K#{note_title_line6_index}") # Merge 
          sheet.merge_cells("P#{note_title_line6_index}:I#{note_title_line6_index}") # Merge 
      else
        Rails.logger.error "Failed to add signature row"
      end


      # Độ rộng cột (18 cột: A to S)
      sheet.column_widths 7, 15, 25, 25, 25, 20, 20, *[5] * 31, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15
      package
    end

    def custom_header_export_excel_month(workbook, sheet, year, month)
      count_date = days_in_month(year, month)
      # Style
      default_font = workbook.styles.add_style(font_name:"Times",sz: 12)
      org_name_style = workbook.styles.add_style(font_name:"Times",sz: 12, alignment: {horizontal: :center ,vertical: :center})
      horizontal_center = workbook.styles.add_style(font_name:"Times",alignment: {horizontal: :center ,vertical: :center},sz: 16, b: true)
      horizontal_center_time = workbook.styles.add_style(font_name:"Times",alignment: {horizontal: :center ,vertical: :center},sz: 14, b: true)
      title_css = workbook.styles.add_style(font_name:"Times",border: { style: :thin, color: '00000000'},alignment: {horizontal: :center ,vertical: :center},sz: 12, b: true)
      cols_left_style = workbook.styles.add_style(font_name:"Times",bg_color: "",fg_color: '305496',border: { style: :thin, color: '00000000'},alignment: {horizontal: :left ,vertical: :center},sz: 12, b: true)
      cols_center_style = workbook.styles.add_style(font_name:"Times",bg_color: "",fg_color: '305496',border: { style: :thin, color: '00000000'},alignment: {horizontal: :center ,vertical: :center, wrap_text: true},sz: 12, b: true)
      department_name_style = workbook.styles.add_style(font_name:"Times",sz: 12, alignment: {horizontal: :center ,vertical: :center}, b: true)
      b = workbook.styles.add_style(font_name:"Times",alignment: {horizontal: :left ,vertical: :center},sz: 12, b: true)

      # datas
      org_name = "BỘ GIÁO DỤC VÀ ĐÀO TẠO"
      department_name = "TRƯỜNG ĐẠI HỌC Y DƯỢC BUÔN MA THUỘT"
      chxhcnvn = "CỘNG HÒA XÃ HỘI CHỦ NGHĨA VIỆT NAM"
      dltdhp = "Độc lập - Tự do - Hạnh phúc"
      table_name = "BẢNG CHẤM CÔNG THÁNG #{month} NĂM #{year}"
      start_time = "Ngày bắt đầu tính công:"
      end_time = "Ngày kết thúc tính công:"
      start_date = Date.new(year&.to_i, month&.to_i, 1).strftime('%d/%m/%Y')
      end_date = Date.new(year&.to_i, month&.to_i, -1).strftime('%d/%m/%Y')

      # Tiêu đề
      sheet.add_row([org_name,"","","","","","","","","","","","","","","","","","","","",chxhcnvn],height:15, style:org_name_style)
      sheet.merge_cells("A1:U1")
      sheet.merge_cells("V1:AL1")
      
      sheet.add_row([department_name,"","","","","","","","","","","","","","","","","","","","",dltdhp],height:15, style:department_name_style)
      sheet.merge_cells("A2:U2")
      sheet.merge_cells("V2:AL2")

      sheet.add_row()
      sheet.add_row()

      # Tên bảng
      sheet.add_row(["","","","","","","","","","",table_name],height: 30, style: horizontal_center)
      sheet.merge_cells("K5:Y5")
      sheet.add_row(["","","","","","","","","","",start_time,"","","","","","","","",start_date],height: 30, style: horizontal_center_time)
      sheet.merge_cells("K6:S6")
      sheet.merge_cells("T6:W6")
      sheet.add_row(["","","","","","","","","","",end_time,"","","","","","","","",end_date],height: 30, style: horizontal_center_time)
      sheet.merge_cells("K7:S7")
      sheet.merge_cells("T7:W7")

      sheet.add_row()

      sheet.add_row(["STT","Mã nhân viên","Họ và tên","Đơn vị","Chức vụ","Ngày vào làm","Ngày nghỉ việc",*(1..31).map { |day| day.to_s },"NC chuẩn trong tháng","NC Tổng","NC HƯỞNG LƯƠNG","","","","","NC KHÔNG HƯỞNG LƯƠNG","","",""], height: 20, style: cols_center_style)
    
      # Tạo mảng thứ cho 31 ngày
      days_of_week = (1..31).map do |day|
        day > count_date ? "-" : day_of_week(year.to_i, month.to_i, day)
      end

      # Thêm hàng tiêu đề
      added_row = sheet.add_row(
        ["", "", "", "", "", "", ""] + days_of_week + ["", "", "NC nghỉ phép", "NC nghỉ bù", "NC đi học", "NC nghỉ chế độ", "NC nghỉ Lễ, Tết", "NC học việc", "NC nghỉ không lương", "NC nghỉ hưởng BHXH", "NC nghỉ thai sản"],
        height: 40,
        style: cols_center_style
      )

      sheet.merge_cells("A9:A10")
      sheet.merge_cells("B9:B10")
      sheet.merge_cells("C9:C10")
      sheet.merge_cells("D9:D10")
      sheet.merge_cells("E9:E10")
      sheet.merge_cells("F9:F10")
      sheet.merge_cells("G9:G10")
      sheet.merge_cells("AM9:AM10")
      sheet.merge_cells("AN9:AN10")
      sheet.merge_cells("AO9:AS9")
      sheet.merge_cells("AT9:AW9")
      row_index = added_row.row_index
      sheet.rows[row_index].cells[2].style = cols_left_style
      sheet.rows[row_index].cells[3].style = cols_left_style
      sheet.rows[row_index].cells[4].style = cols_left_style
    end

    
    # Hàm trả về thời giam làm việc bắt đầu
    # đầu vào là id nhân sự
    # trả về ngày, nếu không có giá trị sẽ hiển thị "Không có dữ liệu"
    # author: Hai (27/05/2025)
    def get_earliest_contract_date(user)

      return nil unless User.where(id: user).first # Trả về nil nếu user không tồn tại
      earliest_contract = Contract.where(user_id: user)
                                .order(:dtfrom)
                                .select(:dtfrom)
                                .first
      earliest_contract&.dtfrom&.strftime('%d/%m/%Y') || "Không có dữ liệu"
    end

    # Hàm lấy ngày nghỉ từng tháng
    def parse_holiday_details(user_id, year)
      monthly_leave_days = Array.new(12, 0.0)
      oHoliday = Holiday.where(user_id: user_id, year: year).first
      holpros = Holpro.joins(:holprosdetails, :holiday)
                      .where(holiday_id: oHoliday&.id)
                      .where("holpros.status = ?",'DONE')
                      .select('holprosdetails.details', 'holprosdetails.sholtype','holpros.status')

      # Xử lý dữ liệu
      holpros.each do |holpro|
        next unless holpro.details.present? && holpro.sholtype == 'NGHI-PHEP' || holpro.sholtype == 'NGHI-HE' || holpro.sholtype == 'NGHI-BU' || holpro.sholtype == 'DI-HOC' || holpro.sholtype == 'NGHI-CHE-DO'  || holpro.sholtype == 'LE-TET'
        holpro.details.split('$$$').each do |entry|
          date_str, period = entry.split('-')
          next unless date_str && period

          begin
            date = Date.strptime(date_str, '%d/%m/%Y')
            next unless date.year == year

            days = period == 'ALL' ? 1.0 : 0.5
            month_index = date.month - 1
            monthly_leave_days[month_index] += days
          rescue ArgumentError => e
            Rails.logger.error "Invalid date format in details: #{date_str}, error: #{e.message}"
            next
          end
        end
      end

      monthly_leave_days
    end

    # Hàm trả về số ngày trong tháng của năm
    def days_in_month(year, month)
      # Kiểm tra đầu vào hợp lệ
      return 0 unless (1..12).include?(month.to_i) && year.to_i.positive?

      # Tính số ngày tối đa của tháng trong năm
      Date.new(year.to_i, month.to_i, -1).day
    end

    def day_of_week(year, month, day)
      return "-" unless (1..31).include?(day)
      begin
        date = Date.new(year, month, day)
        case date.wday
        when 0 then "CN" # Chủ Nhật
        when 1 then "T2" # Thứ Hai
        when 2 then "T3" # Thứ Ba
        when 3 then "T4" # Thứ Tư
        when 4 then "T5" # Thứ Năm
        when 5 then "T6" # Thứ Sáu
        when 6 then "T7" # Thứ Bảy
        end
      rescue ArgumentError
        "-" # Trả về "-" nếu ngày không hợp lệ (ví dụ: ngày 31 trong tháng 04)
      end
    end

    # Hàm lấy chi tiết nghỉ làm bảng chấm công
    def parse_holiday_details_date(user_id, year, month)
      count_date = days_in_month(year, month)
      leave_days = Array.new(31, nil) # Khởi tạo mảng với nil thay vì "X" để xử lý sau

      # Gán giá trị mặc định dựa trên ngày trong tháng
      (1..count_date).each do |day|
        date = Date.new(year.to_i, month.to_i, day)
        leave_days[day - 1] = date.sunday? ? "-" : "X" # Nếu Chủ nhật thì "-", còn lại "X"
      end

      # Gán "-" cho các ngày vượt quá count_date
      (count_date...31).each { |i| leave_days[i] = "-" } if count_date < 31

      oHoliday = Holiday.where(user_id: user_id, year: year).first
      return {
        leave_days: leave_days,
        nc_tong: "-",
        nghi_phep: "-",
        nghi_bu: "-",
        di_hoc: "-",
        nghi_che_do: "-",
        nghi_le_tet: "-",
        hoc_viec: "-",
        khong_luong: "-",
        che_do_bhxh: "-",
        thai_san: "-"
      } unless oHoliday

      # Truy vấn Holpro với INNER JOIN và chọn cả sholtype
      holpros = Holpro.joins(:holprosdetails, :holiday)
                      .where(holidays: { id: oHoliday.id })
                      .where("holpros.status = ?",'DONE')
                      .select('holprosdetails.details', 'holprosdetails.sholtype','holpros.status')

      # Tính nc_chuan
      nc_chuan = count_days_excluding_sundays(year.to_i, month.to_i)
      
      # Đếm số ngày nghỉ cho từng loại
      leave_counts = {
        'NGHI-PHEP' => 0.0,
        'NGHI-BU' => 0.0,
        'DI-HOC' => 0.0,
        'NGHI-CHE-DO' => 0.0,
        'NGHI-LE' => 0.0,
        'HOC-VIEC' => 0.0,
        'NGHI-KHONG-LUONG' => 0.0,
        'NGHI-CHE-DO-BAO-HIEM-XA-HOI' => 0.0,
        'THAI-SAN' => 0.0
      }
      nc_tong_types = ['NGHI-KHONG-LUONG', 'NGHI-CHE-DO-BAO-HIEM-XA-HOI', 'HOC-VIEC', 'THAI-SAN']

      holpros.each do |holpro|
        next unless holpro.details.present? && holpro.sholtype.present?

        holpro.details.split('$$$').each do |entry|
          date_str, period = entry.split('-')
          next unless date_str && period

          begin
            date = Date.strptime(date_str, '%d/%m/%Y')
            next unless date.year == year && date.month == month # Chỉ lấy tháng được chọn

            day_index = date.day - 1
            next unless day_index >= 0 && day_index < count_date

            # Tính số ngày nghỉ
            days = period == 'ALL' ? 1.0 : 0.5
            leave_counts[holpro.sholtype] += days if leave_counts.key?(holpro.sholtype)

            # Xác định trạng thái chấm công, ghi đè giá trị mặc định
            case holpro.sholtype
            when 'NGHI-PHEP'
              leave_days[day_index] = period == 'ALL' ? 'P' : 'X/P'
            when 'NGHI-HE'
              leave_days[day_index] = period == 'ALL' ? 'P' : 'X/P'
            when 'NGHI-BU'
              leave_days[day_index] = period == 'ALL' ? 'NB' : 'X/NB'
            when 'DI-HOC'
              leave_days[day_index] = period == 'ALL' ? 'DH' : 'X/DH'
            when 'NGHI-CHE-DO'
              leave_days[day_index] = period == 'ALL' ? 'CD' : 'CD/KL'
            when 'NGHI-LE'
              leave_days[day_index] = period == 'ALL' ? 'LT' : 'X/LT'
            when 'HOC-VIEC'
              leave_days[day_index] = period == 'ALL' ? 'HV' : 'X/HV'
            when 'NGHI-KHONG-LUONG'
              leave_days[day_index] = period == 'ALL' ? 'KL' : 'X/KL'
            when 'NGHI-CHE-DO-BAO-HIEM-XA-HOI'
              leave_days[day_index] = period == 'ALL' ? 'BH' : 'BH/KL'
            when 'THAI-SAN'
              leave_days[day_index] = period == 'ALL' ? 'TS' : 'X/TS'
            end
          rescue ArgumentError => e
            Rails.logger.error "Invalid date format in details: #{date_str}, error: #{e.message}"
            next
          end
        end
      end

      # Tính leave_count
      leave_count = nc_tong_types.sum { |type| leave_counts[type] }
      nc_tong = nc_chuan - leave_count

      # Trả về kết quả
      {
        leave_days: leave_days,
        nc_tong: nc_tong,
        nghi_phep: leave_counts['NGHI-PHEP'],
        nghi_bu: leave_counts['NGHI-BU'],
        di_hoc: leave_counts['DI-HOC'],
        nghi_che_do: leave_counts['NGHI-CHE-DO'],
        nghi_le_tet: leave_counts['NGHI-LE'],
        hoc_viec: leave_counts['HOC-VIEC'],
        khong_luong: leave_counts['NGHI-KHONG-LUONG'],
        che_do_bhxh: leave_counts['NGHI-CHE-DO-BAO-HIEM-XA-HOI'],
        thai_san: leave_counts['THAI-SAN']
      }
    end

    # Hàm chuyển ngày hiện tại thành định dạng Ngày ... tháng ... năm ....
    def format_current_date
      # Lấy ngày hiện tại
      current_date = Date.today
      
      # Định dạng ngày, tháng, năm
      day = current_date.day.to_s.rjust(2, '0') # Đảm bảo 2 chữ số (VD: 05)
      month = current_date.month.to_s.rjust(2, '0') # Đảm bảo 2 chữ số (VD: 05)
      year = current_date.year
      
      # Trả về chuỗi định dạng
      "Ngày #{day} tháng #{month} năm #{year}"
    end

    # Hàm lấy số ngày công chuẩn đã trừ chủ nhật
    def count_days_excluding_sundays(year, month)
      # Kiểm tra đầu vào hợp lệ
      return 0 unless (1..12).include?(month.to_i) && year.to_i.positive?

      begin
        # Tính tổng số ngày trong tháng
        total_days = Date.new(year, month, -1).day
        
        # Đếm số ngày Chủ Nhật
        sundays = 0
        (1..total_days).each do |day|
          date = Date.new(year, month, day)
          sundays += 1 if date.wday == 0 # wday == 0 là Chủ Nhật
        end

        # Trả về số ngày trừ đi Chủ Nhật
        total_days - sundays
      rescue ArgumentError => e
        Rails.logger.error "Invalid date: #{e.message}"
        0
      end
    end
    # bổ sung ngày 24/07/2025
    # lấy phòng ban cuối cùng của nhân sự
    def fetch_leaf_departments_by_user(user_id)
      positionjob_ids = Work.where(user_id: user_id)
                            .where.not(positionjob_id: nil)
                            .pluck(:positionjob_id)

      department_ids = Positionjob.where(id: positionjob_ids).pluck(:department_id)
      # h.anh
      # update: chỉ lấy theo vị trí các phòng ban đang hoạt động
      # 21/10/2025
      departments = Department.where(id: department_ids, status: "0").where.not(parents: [nil, ""])

      if departments.present?
        parent_ids = departments.map(&:parents).compact.map(&:to_i)
        departments.reject { |dept| parent_ids.include?(dept.id) }
      else
        Department.where(id: department_ids, status: "0").limit(1)
      end
    end
    # Hàm lấy tất cả các department con theo cây
    def fetch_all_related_department_ids(root_ids)
      # 1️⃣ Tìm tất cả gốc liên quan đến các root_ids truyền vào
      root_parents = Department.where(id: root_ids).pluck(:parents)

      # 2️⃣ Nếu có cha, thì lặp lên đến khi gặp gốc thật sự (parents = nil hoặc 0)
      current_parents = root_parents.compact
      while current_parents.any?
        next_parents = Department.where(id: current_parents).pluck(:parents).compact
        break if next_parents.empty?
        current_parents = next_parents
      end

      # 3️⃣ Gốc thật sự (root của cây)
      top_level_ids = Department.where(id: current_parents.presence || root_ids).pluck(:id)

      # 4️⃣ Duyệt toàn bộ con từ gốc
      fetch_all_sub_department_ids(top_level_ids)
    end

    def fetch_all_sub_department_ids(root_ids)
      all_ids = root_ids.dup
      queue = root_ids.dup

      while queue.any?
        current_id = queue.shift
        children = Department.where(parents: current_id, status: "0").pluck(:id)
        queue.concat(children)
        all_ids.concat(children)
      end
      all_ids.uniq
    end
    def fetch_position_and_department_name(user_id)
      department_user = fetch_leaf_departments_by_user(user_id)
      return [nil, nil] if department_user.nil?
      department = department_user.first
      department_id = department.id
      department_name = department.name

      work = Work.includes(:positionjob)
                .where(user_id: user_id)
                .where.not(positionjob_id: nil)
                .detect { |w| w.positionjob&.department_id == department_id }

      positionjob_name = work&.positionjob&.name

      [positionjob_name, department_name]
    end
    def fetch_position_and_department_by_user(user_id)
      work = Work.where(user_id: user_id).where.not(positionjob_id: nil).first
      return [nil, nil] unless work

      position = work.positionjob
      department = position&.department
      return [nil, nil] unless department

      # Tìm các phòng ban leaf
      departments = Department.where(id: position.department_id, status: "0").where.not(parents: [nil, ""])

      if departments.present?
        parent_ids = departments.map(&:parents).compact.map(&:to_i)
        leaf_departments = departments.reject { |dept| parent_ids.include?(dept.id) }
        selected_department = leaf_departments.first || departments.first
      else
        selected_department = Department.find_by(id: position.department_id)
      end

      [position&.name, selected_department&.name]
    end
    def fetch_position_and_root_department(user_id)
      # Lấy tất cả positionjob_id của user
      positionjob_ids = Work.where(user_id: user_id)
                            .where.not(positionjob_id: nil)
                            .pluck(:positionjob_id)

      return [nil, nil] if positionjob_ids.blank?

      # Lấy department_id từ positionjob
      department_ids = Positionjob.where(id: positionjob_ids).pluck(:department_id)

      return [nil, nil] if department_ids.blank?

      # Lấy department theo id
      departments = Department.where(id: department_ids, status: "0")

      # Ưu tiên department con
      parent_ids = departments.map(&:parents).compact.map(&:to_i)
      leaf_departments = departments.reject { |dept| parent_ids.include?(dept.id) }
      department = leaf_departments.first || departments.first
      return [nil, nil] if department.nil?

      # Tìm department cha cao nhất (root department)
      parent_department = department
      while parent_department&.parents.present?
        parent_department = Department.find_by(id: parent_department.parents)
      end
      department_name = parent_department&.name

      department_name
    end
    def parse_leave_details(detail_str)
      return "" if detail_str.blank?

      parts = detail_str.split("$$$")

      details = parts.map do |p|
        next unless p =~ %r{\d{2}/\d{2}/\d{4}-(ALL|AM|PM)}
        date_str, shift = p.split("-")

        parsed_date = begin
          Date.strptime(date_str.strip, "%d/%m/%Y")
        rescue
          nil
        end

        {
          date: parsed_date,
          shift: shift&.strip
        }
      end.compact

      return "" if details.empty?

      details = details.sort_by { |d| d[:date] }

      # Gom các chuỗi ngày liên tiếp (chỉ nếu shift là ALL)
      groups = []
      current_group = []

      details.each_with_index do |d, i|
        if d[:shift] != "ALL"
          groups << [d] # buổi AM/PM thì tách riêng từng dòng
          next
        end

        if current_group.empty?
          current_group << d
        else
          last_date = current_group.last[:date]
          if (d[:date] - last_date).to_i == 1
            current_group << d
          else
            groups << current_group
            current_group = [d]
          end
        end
      end

      groups << current_group unless current_group.empty?

      # Tạo kết quả đầu ra
      result = groups.map do |group|
        if group.size >= 3 && group.all? { |g| g[:shift] == "ALL" }
              first = group.first[:date].strftime("%d/%m/%Y")
              last = group.last[:date].strftime("%d/%m/%Y")
              "Từ ngày #{first} đến #{last}"
            else
              group.map do |d|
                shift_text =
                  case d[:shift]
                  when "ALL" then "(cả ngày)"
                  when "AM" then "(buổi sáng)"
                  when "PM" then "(buổi chiều)"
                  else ""
                  end
                "#{d[:date].strftime('%d/%m/%Y')} #{shift_text}"
              end.join("<br>")
            end
          end

      result.join("<br>")
    end

    def parse_leave_details_json(detail_str, detail_id = nil)
      return [] if detail_str.blank?

      parts = detail_str.split("$$$")

      parts.map do |p|
        next unless p =~ %r{\d{2}/\d{2}/\d{4}-(ALL|AM|PM)}
        date_str, shift = p.split("-")

        parsed_date = begin
          Date.strptime(date_str.strip, "%d/%m/%Y").strftime("%d/%m/%Y")
        rescue
          nil
        end

        next unless parsed_date

        {
          date: parsed_date,
          shift: shift&.strip,
          detail_id: detail_id # 👈 gán ở đây
        }
      end.compact
    end
    def parse_details_string_to_map(details_str)
      return {} if details_str.blank?

      details_str.split("$$$").map do |item|
        if item =~ %r{\d{2}/\d{2}/\d{4}-(ALL|AM|PM)}
          [item, "NGHI-CHE-DO-BAO-HIEM-XA-HOI"]
        else
          nil
        end
      end.compact.to_h
    end
    def parse_detail_string(detail_str)
      return [] if detail_str.blank?

      detail_str.split("$$$").map do |p|
        next unless p =~ %r{\d{2}/\d{2}/\d{4}-(ALL|AM|PM)}
        date_str, shift = p.split("-")

        date = begin
          Date.strptime(date_str.strip, "%d/%m/%Y")
        rescue
          nil
        end

        next unless date

        { date: date, shift: shift }
      end.compact
    end
    def parse_leave_details_for_holpro(details)
      return "" if details.blank?

      label_map = {
        "NGHI-PHEP" => "Nghỉ phép",
        "NGHI-KHONG-LUONG" => "Nghỉ không lương",
        "NGHI-CHE-DO-BAO-HIEM-XA-HOI" => "Nghỉ BHXH",
        "NGHI-CDHH" => "Nghỉ chế độ (Hiếu/Hỷ)"
      }

      grouped = details.group_by(&:sholtype)
      results = []

      grouped.each do |sholtype, items|
        label = label_map[sholtype] || sholtype

        all_days = items.flat_map { |d| parse_detail_string(d.details) }
        next if all_days.empty?

        # ==========================
        # GROUP THEO SHIFT
        # ==========================
        days_by_shift = all_days.group_by { |d| d[:shift] }

        parts = []

        days_by_shift.each do |shift, days|
          dates = days.map { |d| d[:date] }.sort

          # ==========================
          # TÁCH RANGE NGÀY LIỀN KỀ
          # ==========================
          ranges = []
          start_date = dates.first
          prev_date  = dates.first

          dates[1..-1].to_a.each do |current|
            if current == prev_date + 1
              prev_date = current
            else
              ranges << [start_date, prev_date]
              start_date = current
              prev_date  = current
            end
          end

          ranges << [start_date, prev_date]

          # ==========================
          # FORMAT OUTPUT
          # ==========================
          shift_text =
            case shift
            when "ALL" then "cả ngày"
            when "AM"  then "buổi sáng"
            when "PM"  then "buổi chiều"
            else shift
            end

          ranges.each do |from, to|
            if from == to
              parts << "#{from.strftime('%d/%m/%Y')} (#{shift_text})"
            else
              parts << "#{from.strftime('%d/%m/%Y')} – #{to.strftime('%d/%m/%Y')} (#{shift_text})"
            end
          end
        end

        results << "#{label}: #{parts.join(', ')}"
      end

      results.join("<br>")
    end

end


