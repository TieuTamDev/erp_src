class SettingHolidaysController < ApplicationController
    before_action :authorize
    skip_before_action :verify_authenticity_token

    def index
      redirect_to login_path, alert: "Vui lòng đăng nhập để tiếp tục." and return if current_user.nil?

      # Pagination
      per_page = [(params[:per_page] || 25).to_i, 1].max
      page = [(params[:page] || 1).to_i, 1].max
      offset = (page - 1) * per_page

      current_year = Date.today.year
      previous_year = current_year - 1

      search = params[:search].to_s.strip.downcase
      @uorg_scode = params[:uorg_scode].presence || current_user.uorgs.first&.organization&.scode || "BMU"

      # Phòng ban theo uorg_scode
      case @uorg_scode
      when "BMU", "BMTU"
        @departments_bmu = Department.where(organization_id: Organization.where(scode: ["BMU", "BMTU"]).select(:id)).where.not(name: "Quản lý ERP")
        default_holpositionjob = 12
      when "BUH"
        @departments_buh = Department.where(organization_id: Organization.where(scode: "BUH").select(:id), parents: nil).where.not(name: "Quản lý ERP")
      end

      # Lấy organization ids
      organization_ids = if ["BMU", "BMTU"].include?(@uorg_scode)
        Organization.where(scode: ["BMU", "BMTU"]).pluck(:id)
      else
        Organization.where(scode: @uorg_scode).pluck(:id)
      end

      # Sort logic
      sortable_columns = %w[user_sid user_fullname department_name positionjob_name hol_positionjob hol_seniority hol_summer hol_exist total_holiday used_holiday]
      order_by = params[:order_by].presence_in(sortable_columns) || 'user_fullname'
      direction = params[:direction].to_s.downcase == 'desc' ? 'DESC' : 'ASC'

      # Build query
      base_users = User.with_basic_work
                      .by_organization_ids(organization_ids)
                      .active_cohuu
                      .search_by_sid_or_name(search)

      if params[:department_bmu].present? && ["BMU", "BMTU"].include?(@uorg_scode)
        base_users = base_users.by_department(params[:department_bmu])
        
      elsif params[:department_buh].present? && @uorg_scode == "BUH"
        department_id = params[:department_buh].to_i
        department = Department.find(department_id)
        if department.parents.nil?
          all_dept_ids = get_subtree_ids(department_id)
          base_users = base_users.where(positionjobs: { department_id: all_dept_ids })
        else
          base_users = base_users.by_department(department_id)
        end
      end


      if ["BMU", "BMTU"].include?(@uorg_scode)
         @results_bmu = base_users
        .where.not("departments.name = ?", "Quản lý ERP")
        .select(
          'users.id AS user_id',
          'users.sid AS user_sid',
          "CONCAT(users.last_name, ' ', users.first_name) AS user_fullname",
          'departments.name AS department_name',
          'positionjobs.name AS positionjob_name',
          'positionjobs.department_id AS department_id',
          'positionjobs.holno AS hol_positionjob',
          'users.created_at AS created_at'
        )
        .group('users.id')
        .limit(per_page)
        .offset(offset)
      elsif @uorg_scode == "BUH"
         @results_bmu = base_users
        .where.not("departments.name = ?", "Quản lý ERP")
        .select(
          'users.id AS user_id',
          'users.sid AS user_sid',
          "CONCAT(users.last_name, ' ', users.first_name) AS user_fullname",
          'departments.name AS department_name',
          'positionjobs.name AS positionjob_name',
          'positionjobs.department_id AS department_id',
          'positionjobs.holno AS hol_positionjob',
          'users.created_at AS created_at'
        )
        .group('users.id')
        .limit(per_page)
        .offset(offset)
      end
      # Pagination + Sort
     

      # Tổng số bản ghi (cho phân trang)
      @results_bmu_total = base_users.count
      @total_pages = (@results_bmu_total.to_f / per_page).ceil
      @page = page
      @per_page = per_page

      # Lấy dữ liệu Holiday, Hợp đồng, Holdetail
      user_ids = @results_bmu.map { |u| u['user_id'] }

      holidays_data = Holiday.where(user_id: user_ids, year: [current_year, previous_year])
                            .select(:id, :user_id, :year, :total, :used)
                            .group_by { |h| [h.user_id, h.year] }

      contracts_data = Contract.joins("INNER JOIN contracttypes ON contracts.name = contracttypes.name")
                              .select('contracts.user_id, MIN(contracts.dtfrom) AS earliest_from')
                              .where(user_id: user_ids)
                              .where("contracttypes.is_seniority LIKE ?", "%YES%")
                              .where(contracttypes: { status: 'ACTIVE' })
                              .group('contracts.user_id')
                              .to_a
                              .map { |c| [c.user_id, c.earliest_from] }.to_h

      holiday_ids = holidays_data.values.flatten.map(&:id)
      holdetails_data = holiday_ids.any? ? Holdetail.where(holiday_id: holiday_ids).group_by(&:holiday_id) : {}

      # Kết hợp dữ liệu
      @results_bmu = @results_bmu.to_a.map do |user|
        next unless user['positionjob_name'].present?

        current_holiday = Holiday.where(user_id: user['user_id'], year: current_year).last
        previous_holiday = Holiday.where(user_id: user['user_id'], year: previous_year).last

        earliest_contract_date = contracts_data[user['user_id']]
        hol_seniority = if earliest_contract_date
          begin
            (current_year - Date.parse(earliest_contract_date.to_s).year) / 5
          rescue
            0
          end
        else
          0
        end

        current_holdetails = holdetails_data[current_holiday&.id] || []
        holdetail_map = current_holdetails.each_with_object({}) do |d, hash|
          hash[d.name] = {
            value: d.amount,
            deadline: d&.dtdeadline&.strftime("%d/%m/%Y"),
            id: d.id
          }
        end

        actual_holno, worked_months_to_end, worked_months_to_now, check_tnlv = calculate_actual_holno(user['user_id'], user['department_id'])

        # Kiểm tra xem có thuộc BUH hay không
        is_buh = Department.where(id: user['department_id'])
                          .joins(:organization)
                          .where(organizations: { scode: 'BUH' }).exists?

        if is_buh == true
          check_seniority = check_seniority(user['user_id']) 
          if holdetail_map.dig("Phép theo vị trí", :value).to_f != actual_holno.to_f && check_seniority == false
            hol_positionjob = actual_holno
            check_value = true
          else
            holno = Positionjob.where(
                      id: Work.where(user_id: user['user_id']).where.not(positionjob_id: nil).pluck(:positionjob_id),
                      department_id: user['department_id']
                    ).first&.holno.to_f || 0
            hol_positionjob = holdetail_map.dig("Phép theo vị trí", :value) || holno
            check_value = false
          end
        else
          hol_positionjob = holdetail_map.dig("Phép theo vị trí", :value) || default_holpositionjob
          check_value = false
        end

        deadline_exist = holdetail_map.dig("Phép tồn", :deadline) || "31/03/#{current_year}"
        effective_hol_exist = begin
          deadline_date = Date.strptime(deadline_exist, "%d/%m/%Y")
          deadline_date >= Date.today ? holdetail_map.dig("Phép tồn", :value).to_f : 0
        rescue
          0
        end

        total_holiday = [
          hol_positionjob.to_f,
          holdetail_map.dig("Phép thâm niên", :value).to_f || hol_seniority,
          holdetail_map.dig("Phép hè", :value).to_f,
          effective_hol_exist
        ].sum

        check_contract = contracts_data[user['user_id']]

        if check_contract.present?
          hol_positionjob_value = hol_positionjob&.to_f
          hol_seniority_value = holdetail_map.dig("Phép thâm niên", :value)&.to_f || hol_seniority&.to_f
          hol_summer_value = holdetail_map.dig("Phép hè", :value)&.to_f
          hol_exist_value = holdetail_map.dig("Phép tồn", :value)&.to_f
          if is_buh == true
            leave_data = calculate_leave_used(user['user_id'])
            so_phep_nam               = leave_data[:so_phep_nam]
            phep_ton_da_dung_thuc_te  = leave_data[:phep_ton_da_dung_thuc_te]
            phep_da_dung_thuc_te      = leave_data[:phep_da_dung_thuc_te]
            remain_holiday_value      = leave_data[:remain_holiday_value]

            total_holiday_value = so_phep_nam
            used_holiday_value  = phep_da_dung_thuc_te
            used_holiday_fvalue = phep_ton_da_dung_thuc_te
            department_name = fetch_position_and_department_name(user['user_id'])
          else
            department_name = user['department_name']
            total_holiday_value = current_holiday&.total&.to_f || total_holiday&.to_f
            used_holiday_value = current_holiday&.used&.to_f || 0
            remain_holiday_value = total_holiday_value - used_holiday_value
          end
        else
          hol_positionjob_value = 0.0
          hol_seniority_value = 0.0
          hol_summer_value = 0.0
          hol_exist_value = 0.0
          total_holiday_value = 0.0
          used_holiday_value = 0.0
          used_holiday_fvalue = 0.0
          remain_holiday_value = 0.0
          if is_buh == true
            department_name = fetch_position_and_department_name(user['user_id'])
          else
            department_name = user['department_name']
          end
        end

        {
          user_id: user['user_id'],
          user_sid: user['user_sid'],
          user_fullname: user['user_fullname'],
          department_name: department_name,
          positionjob_name: user['positionjob_name'],
          hol_positionjob: hol_positionjob_value,
          hol_positionjob_id: holdetail_map.dig("Phép theo vị trí", :id),
          hol_seniority: hol_seniority_value,
          hol_seniority_id: holdetail_map.dig("Phép thâm niên", :id),
          hol_summer: hol_summer_value,
          hol_summer_id: holdetail_map.dig("Phép hè", :id),
          hol_exist: hol_exist_value,
          hol_exist_id: holdetail_map.dig("Phép tồn", :id),
          deadline_exist: deadline_exist,
          check_value: check_value,
          total_holiday: total_holiday_value,
          used_holiday: used_holiday_value,
          used_fholiday: used_holiday_fvalue,
          remain_holiday: remain_holiday_value,
          id_curent_holiday: current_holiday&.id,
          check_contract: check_contract
        }
      end.compact

      sortable_columns = %w[
        user_sid user_fullname department_name positionjob_name
        hol_positionjob hol_seniority hol_summer hol_exist total_holiday used_holiday used_fholiday remain_holiday
      ]

      order_by = params[:order_by].presence_in(sortable_columns) || 'user_fullname'
      direction = params[:direction].to_s.downcase == 'desc' ? 'desc' : 'asc'

      @results_bmu = @results_bmu.sort_by do |u|
        value = u[order_by.to_sym]

        # Ép kiểu rõ ràng
        if %w[hol_positionjob hol_seniority hol_summer hol_exist total_holiday used_holiday used_fholiday remain_holiday].include?(order_by)
          value.to_f
        elsif value.is_a?(String)
          value.downcase
        else
          value.to_s.downcase
        end
      end

      @results_bmu.reverse! if direction == 'desc'
   
    end

    # H.anh
    # Bổ sung Hàm Cập nhật ngày nghỉ của nhân sự đi làm chưa đủ 1 năm/ nhân sự nghỉ việc có thời gian
    # 29/10/2025
    def calculate_leave_used(user_id)
      holiday = Holiday.find_by(user_id: user_id, year: Time.current.year)
      return default_result unless holiday

      # Gom Holdetail thành hash cho nhanh
      holdetails = Holdetail.where(holiday_id: holiday.id).index_by(&:name)

      ton           = holdetails["Phép tồn"]
      tham_nien     = holdetails["Phép thâm niên"]
      vi_tri        = holdetails["Phép theo vị trí"]

      so_phep_ton        = ton&.amount.to_f
      so_phep_ton_used   = ton&.used.to_f
      phep_tham_nien     = tham_nien&.amount.to_f
      phep_tham_nien_used= tham_nien&.used.to_f
      phep_vi_tri        = vi_tri&.amount.to_f
      phep_vi_tri_used   = vi_tri&.used.to_f

      current_phep   = vi_tri&.note.to_f + tham_nien&.note.to_f
      current_ton   = ton&.note.to_f

      ton_deadline_date  = ton&.dtdeadline&.to_date
      return default_result unless ton_deadline_date

      # Tổng số phép năm
      so_phep_nam = if Time.current.to_date <= ton_deadline_date
                      so_phep_ton + phep_tham_nien + phep_vi_tri
                    else
                      phep_tham_nien + phep_vi_tri
                    end

      # 1. Lấy tất cả Holpro DONE hoặc CANCEL-DONE
      holpros_ids = Holpro.where(
        holiday_id: holiday.id,
        status: ["DONE", "CANCEL-DONE"]
      ).pluck(:id)

      # 2. Lấy thêm các đơn có detail DONE hợp lệ
      extra_holpros_ids = Holpro.joins(:holprosdetails)
                                .where(holiday_id: holiday.id)
                                .where(holprosdetails: { sholtype: ["NGHI-PHEP", "NGHI-CHE-DO"], status: "DONE" })
                                .where.not(id: holpros_ids)
                                .distinct
                                .pluck(:id)

      all_holpros_ids = holpros_ids + extra_holpros_ids

      # 3. Lấy chi tiết đơn phép
      holpros_details = Holprosdetail.where(
        holpros_id: all_holpros_ids,
        sholtype: ["NGHI-PHEP", "NGHI-CHE-DO"]
      )

      # Hàm parse details thành mảng [date, weight]
      parse_dates = ->(details) do
        details.to_s.split('$$$').map do |item|
          date_part, session = item.split('-').map(&:strip)
          begin
            date = Date.strptime(date_part, '%d/%m/%Y')
            weight = session&.upcase == 'ALL' || session.nil? ? 1.0 : 0.5
            [date, weight]
          rescue ArgumentError
            nil
          end
        end.compact
      end
      # Loại trừ các đơn chưa duyệt hoặc bị từ chối
      holpros_ids_not = Holpro.where(holiday_id: holiday.id).where.not(id: all_holpros_ids).pluck(:id)
      holpros_details_not = Holprosdetail.where(
        holpros_id: holpros_ids_not,
        sholtype: ["NGHI-PHEP", "NGHI-CHE-DO"]
      )

      if holpros_details.present?
        all_leave_dates = holpros_details.flat_map { |d| parse_dates.call(d.details) }
        phep_ton_da_dung_thuc_te = all_leave_dates.select { |date, _| date <= ton_deadline_date }.sum { |_, w| w }
        if (so_phep_ton_used + current_ton - phep_ton_da_dung_thuc_te)  < so_phep_ton
          phep_da_dung_thuc_te     = all_leave_dates.select { |date, _| date > ton_deadline_date }.sum { |_, w| w }
          final_ton  = current_ton + phep_ton_da_dung_thuc_te
          final_phep = current_phep +  phep_da_dung_thuc_te
        else
          final_ton = so_phep_ton_used
          final_phep = holiday.used&.to_f - final_ton
        end
      elsif holpros_details_not.present? && holpros_details.empty?
        final_ton  = current_ton
        final_phep = current_phep
      else
        # Nếu chưa có đơn nào → fallback DB
        final_ton  = so_phep_ton_used
        final_phep = phep_vi_tri_used + phep_tham_nien_used
      end

      # Tính remain
      remain_holiday_value = if Time.current.to_date <= ton_deadline_date
                              so_phep_nam - (final_ton + final_phep)
                            else
                              so_phep_nam - final_phep
                            end

      {
        so_phep_nam: so_phep_nam,
        phep_ton_da_dung_thuc_te: final_ton,
        phep_da_dung_thuc_te: final_phep,
        remain_holiday_value: remain_holiday_value
      }
    end
    def check_seniority(user_id)
      # Lấy danh sách các ngày dtfrom từ các hợp đồng hợp lệ
      contract_dates = Contract.joins("INNER JOIN contracttypes ON contracts.name = contracttypes.name")
                              .where(user_id: user_id)
                              .where("contracttypes.is_seniority LIKE ?", "%YES%")
                              .where(contracttypes: { status: 'ACTIVE' })
                              .pluck(:dtfrom)

      return false if contract_dates.blank?

      # Lấy năm nhỏ nhất
      earliest_year = contract_dates.map(&:year).min
      current_year  = Date.current.year

      earliest_year < current_year
    end

    def default_result
      { phep_ton_da_dung_thuc_te: 0, phep_da_dung_thuc_te: 0, so_phep_nam: 0, remain_holiday_value: 0 }
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
          check_tnlv = "row_1"
          worked_months_to_end = 12
          worked_months_to_now = 12
          actual_holno = holno
        elsif user.termination_date.present? && user.termination_date&.year == year
          check_tnlv = "row_2"
          worked_months_to_now = calculate_months_with_15_rule(start_date, today, false)
          worked_months_to_end = calculate_months_with_15_rule(start_date, user.termination_date, true)
          actual_holno = (holno * worked_months_to_now / 12.0).round
        else
          check_tnlv = "row_3"
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
    def fetch_leaf_departments_by_user(user_id)
      positionjob_ids = Work.where(user_id: user_id)
                            .where.not(positionjob_id: nil)
                            .pluck(:positionjob_id)

      department_ids = Positionjob.where(id: positionjob_ids).pluck(:department_id)

      departments = Department.where(id: department_ids).where.not(parents: [nil, ""])

      if departments.present?
        parent_ids = departments.map(&:parents).compact.map(&:to_i)
        departments.reject { |dept| parent_ids.include?(dept.id) }
      else
        Department.where(id: department_ids).limit(1)
      end
    end
    def fetch_position_and_department_name(user_id)
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
        department_name = parent_department.name
      else
        department_name = child_name
      end
      department_name
    end
    def get_subtree_ids(dept_id)
      ids = [dept_id]
      queue = [dept_id]

      while queue.any?
        current_id = queue.shift
        child_ids = Department.where(parents: current_id).pluck(:id)
        ids.concat(child_ids)
        queue.concat(child_ids)
      end

      ids.uniq
    end

    TITLE_TO_STYPE = {
      "Phép tồn"  => "TON",
      "Phép TN"   => "THAM-NIEN",
      "Phép VTCV" => "VI-TRI"
    }
    
    def update_holiday_detail
      hol_positionjob = params[:hol_positionjob]
      hol_seniority = params[:hol_seniority]
      hol_exist = params[:hol_exist]
      deadline_exist = params[:deadline_exist]

      total_holiday = params[:total_holiday]
      used_holiday = params[:used_holiday]
      id_curent_holiday = params[:id_curent_holiday]
      user_id = params[:user_id]

      if id_curent_holiday.present?
        oHoliday = Holiday.where(id: id_curent_holiday).first
        if oHoliday.present?
          oHoliday.update(
            total: total_holiday,
            used: used_holiday
          )

          # holdetail
          oHolpositionjob = Holdetail.where(holiday_id: oHoliday&.id, stype: "VI-TRI").first
          if oHolpositionjob.present?
            oHolpositionjob.update({
              amount: hol_positionjob
            })
          else
            Holdetail.create({
              holiday_id: oHoliday&.id,
              name: "Phép theo vị trí",
              amount: hol_positionjob,
              stype: "VI-TRI"
            })
          end

          oHolseniority = Holdetail.where(holiday_id: oHoliday&.id, stype: "THAM-NIEN").first
          if oHolseniority.present?
            oHolseniority.update({
              amount: hol_seniority
            })
          else
            Holdetail.create({
              holiday_id: oHoliday&.id,
              name: "Phép thâm niên",
              amount: hol_seniority,
              stype: "THAM-NIEN"
            })
          end

          oHolexist = Holdetail.where(holiday_id: oHoliday&.id, stype: "TON").first
          if oHolexist.present?
            oHolexist.update({
              amount: hol_exist,
              dtdeadline: Date.strptime(deadline_exist, "%d/%m/%Y")&.in_time_zone("Asia/Ho_Chi_Minh")&.iso8601
            })
          else
            Holdetail.create({
              holiday_id: oHoliday&.id,
              name: "Phép tồn",
              amount: hol_exist,
              stype: "TON",
              dtdeadline: Date.strptime(deadline_exist, "%d/%m/%Y")&.in_time_zone("Asia/Ho_Chi_Minh")&.iso8601
            })
          end
          render json: { status: "ok" }
        end
      else
        # Dùng cho nút lưu
        oHolidayNew = Holiday.create({
          user_id: user_id,
          total: total_holiday,
          used: used_holiday,
          year: Date.today.year
        })

        if oHolidayNew.present?
          # xóa bản ghi nếu tồn tại
          listHoldetail = Holdetail.where(holiday_id: oHolidayNew&.id)
          if listHoldetail.present?
              listHoldetail.destroy_all
          end

          oHolpositionjobNew = Holdetail.create({
            holiday_id: oHolidayNew&.id,
            name: "Phép theo vị trí",
            amount: hol_positionjob,
            stype: "VI-TRI"
          })
        
          oHolseniorityNew = Holdetail.create({
            holiday_id: oHolidayNew&.id,
            name: "Phép thâm niên",
            amount: hol_seniority,
            stype: "THAM-NIEN"
          })
        
          oHolexistNew = Holdetail.create({
            holiday_id: oHolidayNew&.id,
            name: "Phép tồn",
            amount: hol_exist,
            stype: "TON",
            dtdeadline: Date.strptime(deadline_exist, "%d/%m/%Y")&.in_time_zone("Asia/Ho_Chi_Minh")&.iso8601
          })
          
          render json: { status: "ok" }
        end
      end
    end

    # BIỂU MẪU IMPORT NGÀY NGHỈ NHÂN SỰ
    # 23/07/2025
    # Author: Q.Hai
    # TODO: SETTING HOLIDAY
    def download_template_bmu
        file_path = Rails.root.join('public', 'assets', 'lib', 'ERP_BMU_CauHinhNgayNghi.xlsx')
        send_file(file_path, disposition: 'attachment')
    end

     def download_template_buh
        file_path = Rails.root.join('public', 'assets', 'lib', 'ERP_BUH_CauHinhNgayNghi.xlsx')
        send_file(file_path, disposition: 'attachment')
    end

    def update_imports
        datas = []
        updateds = []
        errors = []
        valids = []
        trans_empty = lib_translate("Empty")
        if !params[:datas].nil?
          datas = JSON.parse(params[:datas])
        end
    end

    # xuất excel theo năm
    def export_data_holiday_year
      uorg_code = params[:uorg_code]
      holtype_year_export = params[:holtype_year_export]
      year_export = params[:year_export]
      datas = []

      if uorg_code.present?
        oUsers = User.with_basic_work
            .active_cohuu
            .joins(uorgs: :organization)
            .select(
              'users.*',
              'organizations.scode AS organization_scode',
              'positionjobs.name AS name_positionjob',
              'positionjobs.scode AS code_hol',
              'departments.name AS name_department',
              'departments.id AS id_department'
            )
            .where(organizations: { scode: uorg_code })

        oUsers.each_with_index do |user, index|
          name_positionjob = user&.name_positionjob || ""
          code_hol = user&.code_hol || ""
          name_department = user&.name_department || ""
          id_department = user&.id_department || ""
          
          # Khởi tạo mảng số ngày nghỉ
          monthly_leave_days = Array.new(12, 0.0)

          # Lấy thông tin phép nghỉ của nhân sự trong năm
          oHoliday = Holiday.find_by(user_id: user.id, year: year_export)

          # Tổng số ngày phép và đã dùng
          total = (oHoliday&.holdetails&.sum(:amount).presence || oHoliday&.total).to_f
          used  = oHoliday&.used.to_f
          conlai = total - used
          # Khởi tạo giá trị mặc định
          phep_ton = 0.0
          han_phep_ton = ""
          phep_ton_da_dung = 0.0
          phep_thamnien = 0.0

          if oHoliday
            holdetails = oHoliday.holdetails.index_by(&:stype)
            phep_ton       = holdetails['TON']&.amount.to_f
            han_phep_ton       = holdetails['TON']&.dtdeadline&.strftime('%d/%m/%Y')
            phep_ton_da_dung       = holdetails['TON']&.used.to_f
            phep_thamnien  = holdetails['THAM-NIEN']&.amount.to_f
          end
     
          phep_thang = phep_duoc_sd_theo_thang(user.id, Time.current.month, id_department) || "0"


          # Lấy số ngày nghỉ phép theo tháng
          monthly_leave_days = parse_holiday_details(user.id, year_export.to_i, holtype_year_export)
          count_date = monthly_leave_days.sum.to_f

          # Đảm bảo monthly_leave_days có đúng 12 phần tử kiểu Float
          monthly_leave_days = Array.new(12, 0.0) unless monthly_leave_days.is_a?(Array) && monthly_leave_days.length == 12

          # lấy số ngày đã nghỉ
          used_date = 0.0
          if used >= count_date
            used_date = used
          else
            used_date = count_date
          end

          if name_department.present?
            if holtype_year_export === "NGHI-PHEP"
              if uorg_code != "BUH"
                # loại phép
                datas.push([
                  user.sid || "",
                  user.staff_status || "",
                  "#{user.last_name || ''} #{user.first_name || ''}".strip,
                  name_department, 
                  code_hol, #Code phép
                  get_earliest_contract_date(user), # THỜI GIAN BẮT ĐẦU LÀM VIỆC (String)
                  get_signed_contract_date(user), # Ngày ký hợp đồng
                  user.termination_date || "", #Ngày nghỉ việc
                  phep_ton, #Số ngày phép tồn
                  total - phep_ton, # Ngày phép năm (Float)
                  phep_thamnien, #Số ngày phép thâm niên
                  *monthly_leave_days, # 12 cột cho các tháng (Float)
                  used_date, #Số ngày phép đã nghỉ
                  conlai, #Số ngày phép còn lại trong năm
                  conlai > 0 ? "CÒN PHÉP" : "HẾT PHÉP" 
                ])
              else
                datas.push([
                  user.sid || "",
                  user.staff_status || "",
                  "#{user.last_name || ''} #{user.first_name || ''}".strip,
                  name_department, 
                  code_hol, #Code phép
                  get_earliest_contract_date(user), # THỜI GIAN BẮT ĐẦU LÀM VIỆC (String)
                  get_signed_contract_date(user), # Ngày ký hợp đồng
                  user.termination_date || "", #Ngày nghỉ việc
                  phep_ton, #Số ngày phép tồn
                  han_phep_ton, #Hạn phép tồn
                  total - phep_ton, # Ngày phép năm (Float)
                  phep_thamnien, #Số ngày phép thâm niên
                  *monthly_leave_days, # 12 cột cho các tháng (Float)
                  phep_ton_da_dung, #Số ngày tồn đã nghỉ
                  used_date - phep_ton_da_dung, #Số ngày phép đã nghỉ
                  total - phep_ton - (used_date - phep_ton_da_dung), #Số ngày phép còn lại trong năm
                  phep_thang, #Số ngày phép còn lại đến tháng hiện tại
                  total - phep_ton - (used_date - phep_ton_da_dung) > 0 ? "CÒN PHÉP" : "HẾT PHÉP" 
                ])
              end
            else
              # các loại khác
              datas.push([
                user.sid || "",
                user.staff_status || "",
                "#{user.last_name || ''} #{user.first_name || ''}".strip,
                name_department, 
                get_earliest_contract_date(user), # THỜI GIAN BẮT ĐẦU LÀM VIỆC (String)
                get_signed_contract_date(user), # Ngày ký hợp đồng
                user.termination_date || "", #Ngày nghỉ việc
                *monthly_leave_days, # 12 cột cho các tháng (Float)
                used_date #Số ngày phép đã nghỉ
              ])
            end
          end
        end

        # Tạo excel package
        if holtype_year_export == "NGHI-PHEP"
          name_file = "DANH SÁCH THEO DÕI NGÀY PHÉP NĂM #{year_export}"
          pre_year = year_export.to_i - 1
          workbook = export_excel_year(datas, year_export, pre_year, name_file, holtype_year_export, uorg_code)
          file_name = "Danh sách theo dõi ngày phép năm #{year_export}.xlsx"
        end

        if holtype_year_export == "NGHI-KHONG-LUONG"
          name_file = "DANH SÁCH THEO DÕI NGÀY NGHỈ KHÔNG LƯƠNG NĂM #{year_export}"
          pre_year = year_export.to_i - 1
          workbook = export_excel_year(datas, year_export, pre_year, name_file, holtype_year_export, uorg_code)
          file_name = "Danh sách theo dõi ngày nghỉ không lương năm #{year_export}.xlsx"
        end

        if holtype_year_export == "NGHI-CDHH"
          name_file = "DANH SÁCH THEO DÕI NGÀY NGHỈ CHẾ ĐỘ (HIẾU HỶ) NĂM #{year_export}"
          pre_year = year_export.to_i - 1
          workbook = export_excel_year(datas, year_export, pre_year, name_file, holtype_year_export, uorg_code)
          file_name = "Danh sách theo dõi ngày nghỉ chế độ (hiếu hỷ) năm #{year_export}.xlsx"
        end

        if holtype_year_export == "NGHI-CHE-DO-BAO-HIEM-XA-HOI"
          name_file = "DANH SÁCH THEO DÕI NGÀY NGHỈ HƯỞNG BHXH NĂM #{year_export}"
          pre_year = year_export.to_i - 1
          workbook = export_excel_year(datas, year_export, pre_year, name_file, holtype_year_export, uorg_code)
          file_name = "Danh sách theo dõi ngày nghỉ hưởng BHXH năm #{year_export}.xlsx"
        end
        
        ## Gửi data để tải xuống
        send_data   workbook.to_stream.read,
                filename: file_name,
                type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                disposition: 'attachment'
      end
    end

    # Biểu mẫu excel năm
    def export_excel_year(datas, year, pre_year, name_file, holtype_year_export, uorg_code)
      package = Axlsx::Package.new
      workbook = package.workbook
      year = year
      sheet = workbook.add_worksheet(name: 'Sheet1')
      cols_left_style = workbook.styles.add_style(font_name:"Times",bg_color: "",border: { style: :thin, color: '00000000'},alignment: {horizontal: :left ,vertical: :center, wrap_text: true},sz: 12)
      cols_center_style = workbook.styles.add_style(font_name:"Times",bg_color: "",border: { style: :thin, color: '00000000'},alignment: {horizontal: :center ,vertical: :center},sz: 12)
      signed_style = workbook.styles.add_style(font_name:"Times",sz: 14, alignment: {horizontal: :center ,vertical: :center}, b: true)
      
      custom_header_export_excel_year(workbook, sheet, year, pre_year, name_file, uorg_code, holtype_year_export)

      datas.each_with_index do |row, index|
          new_row = [index + 1] + row
          added_row = sheet.add_row(new_row, style: cols_center_style)
          row_index = added_row.row_index
          sheet.rows[row_index].cells[3].style = cols_left_style
          sheet.rows[row_index].cells[4].style = cols_left_style
      end
      
      sheet.add_row()
      if uorg_code === "BUH"
        signed_bgh = "BAN GIÁM ĐỐC"
        signed_tchc = "P.TCHCQT"
      else
        signed_bgh = "BAN GIÁM HIỆU"
        signed_tchc = "P.TCHC"
      end
      signed_create = "NGƯỜI LẬP"

      if holtype_year_export === "NGHI-PHEP"
          signed_row = sheet.add_row(["",signed_bgh,"","","","","","","","",signed_tchc,"","","","","","","","","","","",signed_create],height:20, style:signed_style)
      else
        signed_row = sheet.add_row(["",signed_bgh,"","","","",signed_tchc,"","","","","","","","","",signed_create],height:20, style:signed_style)
      end

      if signed_row
          signed_row_index = signed_row.row_index + 1 # +1 vì Excel đếm từ 1, không phải 0
          if holtype_year_export === "NGHI-PHEP"
              # Merge các ô cho các chữ ký
              sheet.merge_cells("B#{signed_row_index}:C#{signed_row_index}")
              sheet.merge_cells("K#{signed_row_index}:N#{signed_row_index}")
              sheet.merge_cells("W#{signed_row_index}:X#{signed_row_index}")
          else
            # Merge các ô cho các chữ ký
            sheet.merge_cells("B#{signed_row_index}:C#{signed_row_index}")
            sheet.merge_cells("G#{signed_row_index}:I#{signed_row_index}")
            sheet.merge_cells("Q#{signed_row_index}:S#{signed_row_index}")
          end
      else
        Rails.logger.error "Failed to add signature row"
      end
      if holtype_year_export === "NGHI-PHEP"
        # Độ rộng cột (18 cột: A to S)
        if uorg_code === "BUH"
          sheet.column_widths 7, 15, 15, 25, 30, 25, 15, 15, 15, 15, 15, 15, 15, *[7] * 12, 15, 15, 15, 20, 10
        else
          sheet.column_widths 7, 15, 15, 25, 30, 25, 15, 15, 15, 15, 15, 15, *[7] * 12, 15, 15, 10
        end
        package
      else
        # Độ rộng cột (18 cột: A to S)
        sheet.column_widths 7, 15, 15, 25, 30, 25, 15, 15, *[7] * 12, 15
        package
      end
    end

    def custom_header_export_excel_year(workbook, sheet, year, pre_year, name_file, uorg_code, holtype_year_export)
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
      if uorg_code === "BUH"
        org_name = "TRƯỜNG ĐẠI HỌC Y DƯỢC BUÔN MA THUỘT"
        department_name = "BỆNH VIỆN ĐẠI HỌC Y DƯỢC BUÔN MA THUỘT"
      else
        org_name = "BỘ GIÁO DỤC VÀ ĐÀO TẠO"
        department_name = "TRƯỜNG ĐẠI HỌC Y DƯỢC BUÔN MA THUỘT"
      end
      chxhcnvn = "CỘNG HÒA XÃ HỘI CHỦ NGHĨA VIỆT NAM"
      dltdhp = "Độc lập - Tự do - Hạnh phúc"
      table_name = name_file

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

      if holtype_year_export === "NGHI-PHEP"
        if uorg_code == "BUH"
          added_row = sheet.add_row([
          "STT",
          "MSNV",
          "TÌNH TRẠNG LÀM VIỆC",
          "HỌ VÀ TÊN",
          "ĐƠN VỊ",
          "MÃ CODE PHÉP",
          "THỜI GIAN BẮT ĐẦU LÀM VIỆC", 
          "NGÀY KÝ HỢP ĐỒNG LAO ĐỘNG",
          "NGÀY NGHỈ VIỆC",
          "SỐ NGÀY PHÉP TỒN NĂM #{pre_year}",
          "HẠN PHÉP TỒN",
          "SỐ NGÀY PHÉP NĂM #{year}",
          "SỐ NGÀY PHÉP THÂM NIÊN",
          *(1..12).map { |month| "Tháng #{month}" }, 
          "SỐ PHÉP TỒN ĐÃ SỬ DỤNG", 
          "SỐ NGÀY PHÉP NĂM ĐÃ SỬ DỤNG", 
          "SỐ NGÀY PHÉP CÒN LẠI TRONG NĂM", 
          "SỐ NGÀY PHÉP CÒN LẠI ĐẾN THÁNG HIỆN TẠI",
          "Ghi chú"
          ], height: 70, style: cols_center_style)
        else
          added_row = sheet.add_row([
          "STT",
          "MSNV",
          "TÌNH TRẠNG LÀM VIỆC",
          "HỌ VÀ TÊN",
          "ĐƠN VỊ",
          "MÃ CODE PHÉP",
          "THỜI GIAN BẮT ĐẦU LÀM VIỆC", 
          "NGÀY KÝ HỢP ĐỒNG LAO ĐỘNG",
          "NGÀY NGHỈ VIỆC",
          "SỐ NGÀY PHÉP TỒN NĂM #{pre_year}",
          "SỐ NGÀY PHÉP NĂM #{year}",
          "SỐ NGÀY PHÉP THÂM NIÊN",
          *(1..12).map { |month| "Tháng #{month}" }, 
          "SỐ NGÀY PHÉP ĐÃ NGHỈ", 
          "SỐ NGÀY PHÉP CÒN LẠI TRONG NĂM", 
          "Ghi chú"
          ], height: 70, style: cols_center_style)
        end
        row_index = added_row.row_index
      else
        added_row = sheet.add_row([
          "STT",
          "MSNV",
          "TÌNH TRẠNG LÀM VIỆC",
          "HỌ VÀ TÊN",
          "ĐƠN VỊ",
          "THỜI GIAN BẮT ĐẦU LÀM VIỆC", 
          "NGÀY KÝ HỢP ĐỒNG LAO ĐỘNG",
          "NGÀY NGHỈ VIỆC",
          *(1..12).map { |month| "Tháng #{month}" }, 
          "SỐ NGÀY ĐÃ NGHỈ"
          ], height: 70, style: cols_center_style)
        row_index = added_row.row_index
      end
    end

    # xuất excel theo tháng
    def export_data_holiday_month
      uorg_code = params[:stype_uorg]
      year_export = params[:year_month_export]
      month_export = params[:month_export]
      datas = []

      if uorg_code.present?
        pre_year = year_export.to_i - 1
        oUsers = User.with_basic_work
            .active_cohuu
            .joins(uorgs: :organization)
            .select(
              'users.*',
              'organizations.scode AS organization_scode',
              'positionjobs.name AS name_positionjob',
              'positionjobs.scode AS code_hol',
              'departments.name AS name_department',
              'departments.id AS id_department'
            )
            .where(organizations: { scode: uorg_code })

        oUsers.each_with_index do |user, index|
          name_positionjob = user&.name_positionjob || ""
          code_hol = user&.code_hol || ""
          name_department = user&.name_department || ""
          id_department = user&.id_department || ""
          
          
          # Lấy thông tin nghỉ chi tiết
          data = parse_holiday_details_month(user.id, year_export.to_i, month_export.to_i)
          
          if name_department.present?
            datas.push([
                user.sid || "",
                "#{user.last_name || ''} #{user.first_name || ''}".strip,
                name_department, 
                get_earliest_contract_date(user),
                data[:phep_ton], # phép tồn
                data[:phep_nam], # phép năm
                *data[:leave_days],
                data[:tong_phep],
                "" # ghi chú
            ])
          end
        end

        # Tạo excel package
        
        workbook = export_excel_holiday_month(datas, year_export, pre_year, month_export)
        file_name = "Danh sách theo dõi phép tháng #{month_export} năm #{year_export}.xlsx"
        
        ## Gửi data để tải xuống
        send_data   workbook.to_stream.read,
                filename: file_name,
                type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                disposition: 'attachment'
      end
    end
    
    # Biểu mẫu xuất báo cáo theo tháng
    def export_excel_holiday_month(datas, year, pre_year, month)
      package = Axlsx::Package.new
      workbook = package.workbook
      year = year
      month = month
      pre_year = pre_year
      
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
      
      custom_header_export_excel_holiday_month(workbook, sheet, year, pre_year, month)
      
      datas.each_with_index do |row, index|
          new_row = [index + 1] + row
          added_row = sheet.add_row(new_row, style: cols_center_style)
          row_index = added_row.row_index
          sheet.rows[row_index].cells[2].style = cols_left_style
          sheet.rows[row_index].cells[3].style = cols_left_style
      end

      sheet.add_row()

      # Độ rộng cột (18 cột: A to S)
      sheet.column_widths 7, 15, 30, 30, 20, 10, 12, *[5] * 31, 15, 20
      package
    end

    def custom_header_export_excel_holiday_month(workbook, sheet, year, pre_year, month)
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

      # Tiêu đề
      sheet.add_row([org_name,"","","","","","","","","","","","","","","","","","","","","","","","","",chxhcnvn],height:15, style:org_name_style)
      sheet.merge_cells("A1:D1")
      sheet.merge_cells("AA1:AN1")
      
      sheet.add_row([department_name,"","","","","","","","","","","","","","","","","","","","","","","","","",dltdhp],height:15, style:department_name_style)
      sheet.merge_cells("A2:D2")
      sheet.merge_cells("AA2:AN2")

      # Tên bảng
      table_name = "DANH SÁCH THEO DÕI NGÀY PHÉP THÁNG #{month}/#{year}"
      sheet.add_row([table_name],height: 40, style: horizontal_center)
      sheet.merge_cells("A3:AN3")

      sheet.add_row()

      sheet.add_row(["STT","MSNV","HỌ VÀ TÊN","ĐƠN VỊ","THỜI GIAN BẮT ĐẦU LÀM VIỆC","PHÉP TỒN #{pre_year}","NGÀY PHÉP #{year}",*(1..31).map { |day| day.to_s },"TỔNG CỘNG","GHI CHÚ"], height: 35, style: cols_center_style)
    
      # Tạo mảng thứ cho 31 ngày
      days_of_week = (1..31).map do |day|
        day > count_date ? "-" : day_of_week(year.to_i, month.to_i, day)
      end

      # Thêm hàng tiêu đề
      added_row = sheet.add_row(
        ["", "", "", "", "", "", ""] + days_of_week + ["", ""],
        height: 35,
        style: cols_center_style
      )

      sheet.merge_cells("A5:A6")
      sheet.merge_cells("B5:B6")
      sheet.merge_cells("C5:C6")
      sheet.merge_cells("D5:D6")
      sheet.merge_cells("E5:E6")
      sheet.merge_cells("F5:F6")
      sheet.merge_cells("G5:G6")
      sheet.merge_cells("AM5:AM6")
      sheet.merge_cells("AN5:AN6")
      row_index = added_row.row_index
    end

    # xuất excel theo ngày
    def export_data_holiday_date
      uorg_code = params[:stype_uorg]
      date_export = params[:date_export]
      datas = []

      if uorg_code.present?
        oUsers = User.with_basic_work
            .active_cohuu
            .joins(uorgs: :organization)
            .select(
              'users.*',
              'organizations.scode AS organization_scode',
              'positionjobs.name AS name_positionjob',
              'positionjobs.scode AS code_hol',
              'departments.name AS name_department',
              'departments.id AS id_department'
            )
            .where(organizations: { scode: uorg_code })

        oUsers.each_with_index do |user, index|
          name_positionjob = user&.name_positionjob || ""
          code_hol = user&.code_hol || ""
          name_department = user&.name_department || ""
          id_department = user&.id_department || ""
          
          
          # Lấy thông tin nghỉ chi tiết
          data = parse_holiday_details_by_date(user.id, date_export)

          if name_department.present? && data[:details].present?
            data[:details].each do |d|
              datas.push([
                user.sid || "",
                "#{user.last_name || ''} #{user.first_name || ''}".strip,
                name_department,
                get_name_holtype(d[:sholtype])&.name,
                d[:place_before_hol],
                d[:note],
                format_handover_receivers(d[:handover_receiver])
              ])
            end
          end
        end

        # Tạo excel package
        
        workbook = export_excel_holiday_date(datas, date_export)
        file_name = "Danh sách nghỉ ngày #{date_export}.xlsx"
        
        ## Gửi data để tải xuống
        send_data   workbook.to_stream.read,
                filename: file_name,
                type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                disposition: 'attachment'
      end
    end
    
    # Biểu mẫu xuất báo cáo theo ngày
    def export_excel_holiday_date(datas, date_export)
      package = Axlsx::Package.new
      workbook = package.workbook
      date_export = date_export
      
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
      
      custom_header_export_excel_holiday_date(workbook, sheet, date_export)
      
      datas.each_with_index do |row, index|
          new_row = [index + 1] + row
          added_row = sheet.add_row(new_row, style: cols_center_style)
          row_index = added_row.row_index
          sheet.rows[row_index].cells[2].style = cols_left_style
          sheet.rows[row_index].cells[3].style = cols_left_style
          sheet.rows[row_index].cells[5].style = cols_left_style
          sheet.rows[row_index].cells[6].style = cols_left_style
          sheet.rows[row_index].cells[7].style = cols_left_style
      end

      sheet.add_row()

      # Độ rộng cột 
      sheet.column_widths 7, 15, 30, 30, 20, 30, 30, 30
      package
    end

    def custom_header_export_excel_holiday_date(workbook, sheet, date_export)
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

      # Tiêu đề
      sheet.add_row([org_name,"","","","",chxhcnvn],height:15, style:org_name_style)
      sheet.merge_cells("A1:D1")
      sheet.merge_cells("F1:H1")
      
      sheet.add_row([department_name,"","","","",dltdhp],height:15, style:department_name_style)
      sheet.merge_cells("A2:D2")
      sheet.merge_cells("F2:H2")

      # Tên bảng
      table_name = "DANH SÁCH NGHỈ NGÀY #{date_export}"
      sheet.add_row([table_name],height: 40, style: horizontal_center)
      sheet.merge_cells("A3:H3")

      sheet.add_row(["STT","MSNV","HỌ VÀ TÊN","ĐƠN VỊ","LOẠI NGHỈ","ĐỊA ĐIỂM NGHỈ","LÝ DO NGHỈ","NGƯỜI NHẬN BÀN GIAO (NẾU CÓ)"], height: 35, style: cols_center_style)
    end

    # xuất excel theo NHÂN VIÊN
    def export_data_holiday_user
      uorg_code = params[:stype_uorg]
      year_export = params[:year_user_export]
      user_sid_export = params[:user_sid_export]
      datas = []

      if uorg_code.present?
        pre_year = year_export.to_i - 1

        # Lấy user
        user = User.with_basic_work
                  .active_cohuu
                  .joins(uorgs: :organization)
                  .select(
                    'users.*',
                    'organizations.scode AS organization_scode',
                    'positionjobs.name AS name_positionjob',
                    'positionjobs.scode AS code_hol',
                    'departments.name AS name_department'
                  )
                  .where(organizations: { scode: uorg_code })
                  .find_by(sid: user_sid_export)

        return unless user

        fullname = "#{user.last_name} #{user.first_name}".strip
        department_name = user.name_department || ""

        # Khởi tạo 12 tháng rỗng
        months_data = (1..12).map do |m|
          {
            month: m,
            loai_phep: "-",
            so_ngay_nghi: "-",
            thoi_gian_nghi: "-",
            dia_diem: "-",
            ly_do: "-",
            nguoi_ban_giao: "-",
            phep_con_lai: "-"
          }
        end

        # Lấy holiday record
        holiday_record = Holiday.find_by(user_id: user.id, year: year_export)
        phep_con_lai = holiday_record&.holdetails&.where(stype: "TON")&.first&.amount

        # Lấy dữ liệu phép trong năm
        holpros = Holpro.joins(:holprosdetails, :holiday)
                        .where(holiday_id: holiday_record&.id)
                        .where(status: ["DONE", "CANCEL-DONE"])
                        .select(
                          'holprosdetails.details',
                          'holprosdetails.sholtype',
                          'holprosdetails.place_before_hol',
                          'holprosdetails.note',
                          'holprosdetails.handover_receiver'
                        )

        holpros.each do |hp|
          next unless hp.details.present?

          # Gom tất cả các ngày trong details
          hp.details.split('$$$').each do |entry|
            date_str, period = entry.split('-')
            next unless date_str && period

            begin
              date = Date.strptime(date_str, '%d/%m/%Y')
            rescue
              next
            end

            next unless date.year == year_export.to_i
            month_index = date.month - 1

            # Nếu tháng chưa có loại phép thì gán
            months_data[month_index][:loai_phep] = get_name_holtype(hp.sholtype)&.name
            months_data[month_index][:dia_diem] = hp.place_before_hol
            months_data[month_index][:ly_do] = hp.note
            months_data[month_index][:nguoi_ban_giao] = format_handover_receivers(hp.handover_receiver)
            months_data[month_index][:phep_con_lai] = phep_con_lai

            # Cộng số ngày nghỉ
            days = (period == 'ALL') ? 1.0 : 0.5
            if months_data[month_index][:so_ngay_nghi] == "-" || months_data[month_index][:so_ngay_nghi].nil?
              months_data[month_index][:so_ngay_nghi] = 0.0
            end
            months_data[month_index][:so_ngay_nghi] = months_data[month_index][:so_ngay_nghi].to_f + days

            # Thêm thời gian nghỉ
            if months_data[month_index][:thoi_gian_nghi] == "-" || months_data[month_index][:thoi_gian_nghi].nil?
              months_data[month_index][:thoi_gian_nghi] = "#{date_str}-#{period}"
            else
              months_data[month_index][:thoi_gian_nghi] += ", #{date_str}-#{period}"
            end
          end
        end

        # Chuyển sang mảng datas để export
        months_data.each do |mdata|
          datas << [
            mdata[:month],
            mdata[:loai_phep],
            mdata[:so_ngay_nghi],
            format_leave_details(mdata[:thoi_gian_nghi]),
            mdata[:dia_diem],
            mdata[:ly_do],
            mdata[:nguoi_ban_giao],
            mdata[:phep_con_lai]
          ]
        end
        ton_phep = ""
        tong_phep = ""
        da_nghi = ""

        # Xuất excel
        workbook = export_excel_holiday_user(datas, year_export, pre_year, fullname, user.sid, department_name, ton_phep, tong_phep, da_nghi )
        file_name = "Thong_tin_nghi_#{user_sid_export}_#{year_export}.xlsx"

        send_data workbook.to_stream.read,
                  filename: file_name,
                  type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                  disposition: 'attachment'
      end
    end

    
    # Biểu mẫu xuất báo cáo theo ngày
    def export_excel_holiday_user(datas, year_export, pre_year, fullname, sid, department_name, ton_phep, tong_phep, da_nghi)
      package = Axlsx::Package.new
      workbook = package.workbook
      year_export = year_export
      pre_year = pre_year
      fullname = fullname
      sid = sid
      department_name = department_name
      ton_phep = ton_phep
      tong_phep = tong_phep
      da_nghi = da_nghi
      
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
      
      custom_header_export_excel_holiday_user(workbook, sheet, year_export, pre_year, fullname, sid, department_name, ton_phep, tong_phep, da_nghi)
      
      (1..12).each do |month|
        # Tìm dữ liệu của tháng
        row_data = datas.find { |r| r[0] == month }

        # Nếu không có dữ liệu thì gán mặc định toàn "-"
        row_data ||= [month, "-", "-", "-", "-", "-", "-", "-"]

        # Thêm hàng vào sheet
        added_row = sheet.add_row(row_data, style: cols_center_style)
        r = added_row.row_index
      end

      sheet.add_row()

      # Độ rộng cột 
      sheet.column_widths 25, 25, 30, 30, 30, 30, 30, 30
      package
    end

    def custom_header_export_excel_holiday_user(workbook, sheet, year_export, pre_year, fullname, sid, department_name, ton_phep, tong_phep, da_nghi)
      # Style
      default_font = workbook.styles.add_style(font_name:"Times", sz: 12, b: true)
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

      # Tiêu đề
      sheet.add_row([org_name,"","","","",chxhcnvn],height:15, style:org_name_style)
      sheet.merge_cells("A1:D1")
      sheet.merge_cells("F1:H1")
      
      sheet.add_row([department_name,"","","","",dltdhp],height:15, style:department_name_style)
      sheet.merge_cells("A2:D2")
      sheet.merge_cells("F2:H2")

      # Tên bảng
      table_name = "THÔNG TIN PHÉP NĂM #{year_export}"
      sheet.add_row([table_name],height: 40, style: horizontal_center)
      sheet.merge_cells("A3:H3")

      sheet.add_row(["","HỌ VÀ TÊN",fullname&.upcase,"","","NGÀY PHÉP TỒN NĂM #{pre_year}",ton_phep],height:35, style:default_font)
      sheet.add_row(["","MSNV",sid&.upcase,"","","NGÀY PHÉP NĂM #{year_export}",tong_phep],height:35, style:default_font)
      sheet.add_row(["","ĐƠN VỊ",department_name&.upcase,"","","NGÀY PHÉP NĂM ĐÃ NGHỈ",da_nghi],height:35, style:default_font)

      sheet.merge_cells("C4:D4")
      sheet.merge_cells("C6:D6")
      
      sheet.add_row(["THÁNG","LOẠI ĐƠN","SỐ NGÀY NGHỈ","THỜI GIAN NGHỈ","ĐỊA ĐIỂM","LÝ DO","NGƯỜI NHẬN BÀN GIAO (NẾU CÓ)","NGÀY PHÉP NĂM CÒN LẠI"], height: 35, style: cols_center_style)
    end
    

    # Xuất excel đơn theo loại phép đi nước ngoài
    def export_data_holiday_country
      uorg_code = params[:stype_uorg]
      year_export = params[:year_country_export]
      holtype_export = params[:holtype_country_export]
      issued_place = "OUT-COUNTRY"

      datas = []

      if uorg_code.present?
        if holtype_export.present?
          holpros = Holpro.joins(holiday: { user: { uorgs: :organization } })
                .includes(:holiday, :holprosdetails, holiday: :user)
                .where(holprosdetails: {sholtype: holtype_export, issued_place: issued_place})
                .where(holidays: { year: year_export })
                .where(organizations: { scode: uorg_code })
        else
          holpros = Holpro.joins(holiday: { user: { uorgs: :organization } })
                .includes(:holiday, :holprosdetails, holiday: :user)
                .where(holprosdetails: {issued_place: issued_place})
                .where(holidays: { year: year_export })
                .where(organizations: { scode: uorg_code })
        end

        holpros.each do |holpro|
          oHoliday = Holiday.where(id: holpro&.holiday_id).first
          oUser = User.where(id: oHoliday&.user_id).first
          name_department = get_latest_department_name(oUser&.id)
          if name_department.present?
            holpro.holprosdetails.map do |detail|
              datas.push([
                "#{oUser&.last_name} #{oUser&.first_name}",
                oUser&.gender == "0" ? "Nam" : "Nữ",
                "Nhân viên/Giảng viên",
                get_full_address(oUser.id),
                format_leave_details(detail.details), 
                detail&.note,
                get_full_address(oUser.id),
                holpro&.note || ""
              ])
            end
          end
        end
        name_holtype = get_name_holtype(holtype_export)&.name
        
        # Tạo excel package
        if holtype_export == ""
          name_file = "DANH SÁCH NGHỈ ĐI NƯỚC NGOÀI NĂM #{year_export}"
          workbook = export_excel_with_country(datas, year_export, name_file, holtype_export, uorg_code)
          file_name = "Danh sách nghỉ đi nước ngoài năm #{year_export}.xlsx"
        end

        if holtype_export == "NGHI-PHEP"
          name_file = "DANH SÁCH NGHỈ PHÉP ĐI NƯỚC NGOÀI NĂM #{year_export}"
          workbook = export_excel_with_country(datas, year_export, name_file, holtype_export, uorg_code)
          file_name = "Danh sách nghỉ phép đi nước ngoài năm #{year_export}.xlsx"
        end

        if holtype_export == "NGHI-KHONG-LUONG"
          name_file = "DANH SÁCH NGHỈ KHÔNG LƯƠNG ĐI NƯỚC NGOÀI NĂM #{year_export}"
          workbook = export_excel_with_country(datas, year_export, name_file, holtype_export, uorg_code)
          file_name = "Danh sách nghỉ không lương đi nước ngoài năm #{year_export}.xlsx"
        end

        if holtype_export == "NGHI-CDHH"
          name_file = "DANH SÁCH NGHỈ CHẾ ĐỘ (HIẾU HỶ) ĐI NƯỚC NGOÀI NĂM #{year_export}"
          workbook = export_excel_with_country(datas, year_export, name_file, holtype_export, uorg_code)
          file_name = "Danh sách nghỉ chế độ (hiếu hỷ) đi nước ngoài năm #{year_export}.xlsx"
        end

        if holtype_export == "NGHI-CHE-DO-BAO-HIEM-XA-HOI"
          name_file = "DANH SÁCH NGHỈ HƯỞNG BHXH ĐI NƯỚC NGOÀI NĂM #{year_export}"
          workbook = export_excel_with_country(datas, year_export, name_file, holtype_export, uorg_code)
          file_name = "Danh sách nghỉ hưởng BHXH đi nước ngoài năm #{year_export}.xlsx"
        end
        
        ## Gửi data để tải xuống
        send_data   workbook.to_stream.read,
                filename: file_name,
                type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                disposition: 'attachment'
      else
        render plain: "Thiếu mã đơn vị (uorg_code)", status: :bad_request
      end
    end

    # Biểu mẫu excel theo nước ngoài
    def export_excel_with_country(datas, year, name_file, holtype_export, uorg_code)
      package = Axlsx::Package.new
      workbook = package.workbook
      year = year
      sheet = workbook.add_worksheet(name: 'Sheet1')
      cols_left_style = workbook.styles.add_style(font_name:"Times",bg_color: "",border: { style: :thin, color: '00000000'},alignment: {horizontal: :left ,vertical: :center, wrap_text: true},sz: 12)
      cols_center_style = workbook.styles.add_style(font_name:"Times",bg_color: "",border: { style: :thin, color: '00000000'},alignment: {horizontal: :center ,vertical: :center},sz: 12)
      signed_style = workbook.styles.add_style(font_name:"Times",sz: 14, alignment: {horizontal: :center ,vertical: :center}, b: true)
      row_count_style = workbook.styles.add_style(
        font_name: "Times",
        sz: 11,
        alignment: { horizontal: :center, vertical: :center },
        b: false,    # In đậm (bold)
        i: true     # In nghiêng (italic)
      )
      
      custom_header_export_excel_with_country(workbook, sheet, year, name_file, uorg_code)

      datas.each_with_index do |row, index|
          new_row = [index + 1] + row
          added_row = sheet.add_row(new_row, style: cols_center_style)
          row_index = added_row.row_index
          sheet.rows[row_index].cells[1].style = cols_left_style
          sheet.rows[row_index].cells[4].style = cols_left_style
          sheet.rows[row_index].cells[6].style = cols_left_style
          sheet.rows[row_index].cells[7].style = cols_left_style
          sheet.rows[row_index].cells[8].style = cols_left_style
      end
      
      sheet.add_row()

      count_datas = "(Danh sách trên bao gồm: #{datas&.count} lượt đi)"

      count_row = sheet.add_row(["",count_datas],height:20, style:row_count_style)

      count_row_index = count_row.row_index + 1
      sheet.merge_cells("B#{count_row_index}:C#{count_row_index}")
      
      # Độ rộng cột
      sheet.column_widths 7, 25, 15, 30, 20, 20, 20, 30, 30, 25, 30
      package
      
    end

    def custom_header_export_excel_with_country(workbook, sheet, year, name_file, uorg_code)
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
      if uorg_code === "BUH"
        org_name = "TRƯỜNG ĐẠI HỌC Y DƯỢC BUÔN MA THUỘT"
        department_name = "BỆNH VIỆN ĐẠI HỌC Y DƯỢC BUÔN MA THUỘT"
      else
        org_name = "BỘ GIÁO DỤC VÀ ĐÀO TẠO"
        department_name = "TRƯỜNG ĐẠI HỌC Y DƯỢC BUÔN MA THUỘT"
      end
      chxhcnvn = "CỘNG HÒA XÃ HỘI CHỦ NGHĨA VIỆT NAM"
      dltdhp = "Độc lập - Tự do - Hạnh phúc"
      table_name = name_file

      # Tiêu đề
      sheet.add_row([org_name,"","","","","",chxhcnvn],height:15, style:org_name_style)
      sheet.merge_cells("A1:D1")
      sheet.merge_cells("G1:I1")
      
      added_row = sheet.add_row([department_name,"","","","","",dltdhp],height:15, style:department_name_style)
      row_index = added_row.row_index
      
      sheet.merge_cells("A2:D2")
      sheet.merge_cells("G2:I2")

      # Tên bảng
      sheet.add_row([table_name],height: 30, style: horizontal_center)
      sheet.merge_cells("A3:I3")

      added_row = sheet.add_row([
        "STT",
        "HỌ VÀ TÊN",
        "GIỚI TÍNH",
        "NGHỀ NGHIỆP", 
        "CHỖ Ở TRƯỚC KHI XUẤT CẢNH",
        "THỜI GIAN Ở NƯỚC NGOÀI",
        "MỤC ĐÍCH ĐI NƯỚC NGOÀI",
        "CHỖ Ở SAU KHI VỀ NƯỚC",
        "GHI CHÚ",        
        ], height: 40, style: cols_center_style)
      row_index = added_row.row_index
    end

    def get_full_address(user_id)
      address = Address.find_by(user_id: user_id, status: "ACTIVE", stype: "Thường Trú")
      return "" unless address

      parts = [address.no, address.street, address.ward, address.district, address.province]
      parts.compact.reject(&:blank?).join(", ")
    end

    # Xuất excel theo trạng thái đơn
    def export_data_holiday_status
      uorg_code = params[:stype_uorg]
      year_export = params[:year_status_export]
      status_export = params[:status_export]
      datas = []

      

      if uorg_code.present?
        if status_export == "PENDING"
          holpros = Holpro.joins(holiday: { user: { uorgs: :organization } })
                .includes(:holiday, :holprosdetails, holiday: :user)
                .where(status: ["PENDING", "CANCEL-PENDING"])
                .where(holidays: { year: year_export })
                .where(organizations: { scode: uorg_code })
        else
          holpros = Holpro.joins(holiday: { user: { uorgs: :organization } })
                .includes(:holiday, :holprosdetails, holiday: :user)
                .where(status: status_export)
                .where(holidays: { year: year_export })
                .where(organizations: { scode: uorg_code })
        end
        
        holpros.each do |holpro|
          oHoliday = Holiday.where(id: holpro&.holiday_id).first
          oUser = User.where(id: oHoliday&.user_id).first
          name_department = get_latest_department_name(oUser&.id)
          if name_department.present?
            holpro.holprosdetails.map do |detail|
              datas.push([
                oUser&.sid,
                "#{oUser&.last_name} #{oUser&.first_name}",
                name_department || "",
                get_name_holtype(detail&.sholtype)&.name,
                detail&.itotal&.to_f,
                format_leave_details(detail.details), 
                detail&.place_before_hol,
                detail&.note,
                format_handover_receivers(detail&.handover_receiver),
                holpro&.note || ""
              ])
            end
          end
        end

        arr_status = [
          {scode: "DONE", name: "Đã duyệt", named: "đã duyệt", nameu: "ĐÃ DUYỆT"},
          {scode: "PENDING", name: "Chờ duyệt", named: "chờ duyệt", nameu: "CHỜ DUYỆT"},
          {scode: "TEMP", name: "Lưu nháp", named: "lưu nháp", nameu: "LƯU NHÁP"},
          {scode: "PROCESSING", name: "Đang xử lý đơn", named: "đang xử lý đơn", nameu: "ĐANG XỬ LÝ ĐƠN"},
          {scode: "CANCEL", name: "Đơn bị hủy", named: "đơn bị hủy", nameu: "ĐƠN BỊ HỦY"},
          {scode: "CANCEL-DONE", name: "Đã duyệt(điều chỉnh)", named: "đã duyệt(điều chỉnh)", nameu: "ĐÃ DUYỆT (ĐIỀU CHỈNH)"},
          {scode: "REFUSE", name: "Đơn từ chối", named: "đơn từ chối", nameu: "ĐƠN TỪ CHỐI"}
        ]
        
        name_status = find_status(arr_status, status_export)[:named]
        name_status_u = find_status(arr_status, status_export)[:nameu]
        name_file = "DANH SÁCH ĐĂNG KÝ #{find_status(arr_status, status_export)[:nameu]} NĂM #{year_export}"
        
        # Tạo excel package
        workbook = export_excel_with_status(datas, year_export, name_status, name_status_u, name_file, uorg_code)
        file_name = "Danh sách đăng ký #{name_status} năm #{year_export}.xlsx"
        
        ## Gửi data để tải xuống
        send_data   workbook.to_stream.read,
                filename: file_name,
                type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                disposition: 'attachment'
      else
        render plain: "Thiếu mã đơn vị (uorg_code)", status: :bad_request
      end
    end

    # Biểu mẫu excel theo loại đơn
    def export_excel_with_status(datas, year, name_status, name_status_u, name_file, uorg_code)
      package = Axlsx::Package.new
      workbook = package.workbook
      year = year
      sheet = workbook.add_worksheet(name: 'Sheet1')
      cols_left_style = workbook.styles.add_style(font_name:"Times",bg_color: "",border: { style: :thin, color: '00000000'},alignment: {horizontal: :left ,vertical: :center, wrap_text: true},sz: 12)
      cols_center_style = workbook.styles.add_style(font_name:"Times",bg_color: "",border: { style: :thin, color: '00000000'},alignment: {horizontal: :center ,vertical: :center},sz: 12)
      signed_style = workbook.styles.add_style(font_name:"Times",sz: 14, alignment: {horizontal: :center ,vertical: :center}, b: true)
      
      custom_header_export_excel_with_status(workbook, sheet, year, name_status, name_status_u, name_file, uorg_code)

      datas.each_with_index do |row, index|
          new_row = [index + 1] + row
          added_row = sheet.add_row(new_row, style: cols_center_style)
          row_index = added_row.row_index
          sheet.rows[row_index].cells[2].style = cols_left_style
          sheet.rows[row_index].cells[3].style = cols_left_style
          sheet.rows[row_index].cells[7].style = cols_left_style
          sheet.rows[row_index].cells[8].style = cols_left_style
          sheet.rows[row_index].cells[9].style = cols_left_style
          sheet.rows[row_index].cells[10].style = cols_left_style
      end
      
      sheet.add_row()
      
      # Độ rộng cột
      sheet.column_widths 7, 15, 25, 30, 20, 20, 20, 30, 30, 25, 30
      package
      
    end

    def custom_header_export_excel_with_status(workbook, sheet, year, name_status, name_status_u, name_file, uorg_code)
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
      if uorg_code === "BUH"
        org_name = "TRƯỜNG ĐẠI HỌC Y DƯỢC BUÔN MA THUỘT"
        department_name = "BỆNH VIỆN ĐẠI HỌC Y DƯỢC BUÔN MA THUỘT"
      else
        org_name = "BỘ GIÁO DỤC VÀ ĐÀO TẠO"
        department_name = "TRƯỜNG ĐẠI HỌC Y DƯỢC BUÔN MA THUỘT"
      end
      chxhcnvn = "CỘNG HÒA XÃ HỘI CHỦ NGHĨA VIỆT NAM"
      dltdhp = "Độc lập - Tự do - Hạnh phúc"
      table_name = name_file

      # Tiêu đề
      sheet.add_row([org_name,"","","","","","","",chxhcnvn],height:15, style:org_name_style)
      sheet.merge_cells("A1:D1")
      sheet.merge_cells("I1:K1")
      
      added_row = sheet.add_row([department_name,"","","","","","","",dltdhp],height:15, style:department_name_style)
      row_index = added_row.row_index
      
      sheet.merge_cells("A2:D2")
      sheet.merge_cells("I2:K2")

      # Tên bảng
      sheet.add_row([table_name],height: 30, style: horizontal_center)
      sheet.merge_cells("A3:K3")

      added_row = sheet.add_row([
        "STT",
        "MSNV",
        "HỌ VÀ TÊN",
        "ĐƠN VỊ",
        "LOẠI NGHỈ", 
        "SỐ NGÀY NGHỈ",
        "THỜI GIAN NGHỈ",
        "ĐỊA ĐIỂM NGHỈ",
        "LÍ DO NGHỈ",
        "NGƯỜI NHẬN BÀN GIAO (NẾU CÓ)",
        "LÝ DO #{name_status_u}",        
        ], height: 40, style: cols_center_style)
      row_index = added_row.row_index
    end

    # xuất excel bảng chấm công
    def export_data_timesheet
      uorg_code = params[:uorg_code]
      year_export_month = params[:year_timesheet_export]
      month_export_month = params[:month_timesheet_export]
      datas = []

      if uorg_code.present?
        oUsers = User.with_basic_work
            .active_cohuu
            .joins(uorgs: :organization)
            .select(
              'users.*',
              'organizations.scode AS organization_scode',
              'positionjobs.name AS name_positionjob',
              'positionjobs.scode AS code_hol',
              'departments.name AS name_department',
              'departments.id AS id_department'
            )
            .where(organizations: { scode: uorg_code })

        oUsers.each_with_index do |user, index|
          name_positionjob = user&.name_positionjob || ""
          code_hol = user&.code_hol || ""
          name_department = user&.name_department || ""
          id_department = user&.id_department || ""
          
          # Lấy thông tin nghỉ chi tiết
          data = parse_holiday_details_date(user.id, year_export_month.to_i, month_export_month.to_i)
          
          if name_department.present?
            datas.push([
                user.sid || "",
                "#{user.last_name || ''} #{user.first_name || ''}".strip,
                name_department, 
                name_positionjob,
                get_earliest_contract_date(user),
                user.termination_date || "", #Ngày nghỉ việc
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

        # Tạo excel package
        # Tạo excel package
        workbook = export_excel_timesheet(datas, year_export_month, month_export_month)
        file_name = "Bảng chấm công tháng #{month_export_month} năm #{year_export_month}.xlsx"
        
        ## Gửi data để tải xuống
        send_data   workbook.to_stream.read,
                filename: file_name,
                type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
                disposition: 'attachment'
      end
    end
    
    # Biểu mẫu bảng chấm công
    def export_excel_timesheet(datas, year, month)
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
      
      custom_header_export_excel_timesheet(workbook, sheet, year, month)
      
      datas.each_with_index do |row, index|
          new_row = [index + 1] + row
          added_row = sheet.add_row(new_row, style: cols_center_style)
          row_index = added_row.row_index
          sheet.rows[row_index].cells[2].style = cols_left_style
          sheet.rows[row_index].cells[3].style = cols_left_style
          sheet.rows[row_index].cells[4].style = cols_left_style
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
      sheet.column_widths 7, 15, 25, 30, 25, 20, 20, *[5] * 31, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15
      package
    end

    def custom_header_export_excel_timesheet(workbook, sheet, year, month)
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

    # Các hàm hỗ trợ xuất excel datas
    def get_latest_department_name(user_id)
      user = User.find_by(id: user_id)
      return nil unless user

      latest_work = Work
        .joins(positionjob: :department)
        .where(user_id: user.id)
        .where.not(positionjob_id: nil)
        .where.not(positionjobs: { name: nil, department_id: nil })
        .where.not(departments: { name: 'Quản lý ERP' })
        .where(departments: { is_virtual: nil, parents: nil })
        .first

      latest_work&.positionjob&.department&.name
    end

    def format_leave_details(details)
      session_mapping = {
        "ALL" => "Cả ngày",
        "AM"  => "Buổi sáng",
        "PM"  => "Buổi chiều"
      }

      items = details.to_s.split('$$$').map do |item|
        date_part, session = item.split('-')
        next unless date_part

        label = session_mapping[session&.upcase.to_s.strip] || 'Không xác định'
        "#{date_part.strip} (#{label})"
      end.compact

      items.join("\n") # xuống dòng giữa các dòng
    end

    def find_status(arr_status, value)
      arr_status.find do |item|
        item.values.map(&:to_s).include?(value.to_s)
      end
    end

    def format_handover_receivers(raw)
      return "" if raw.blank?

      # Tách từng người
      people = raw.split("|||").map do |entry|
        parts = entry.split("$$$")
        parts[1].to_s.strip # Lấy tên
      end.compact

      return "" if people.empty?

      # Thêm dấu phẩy cho người đầu tiên nếu nhiều hơn 1 người
      if people.length > 1
        people[0..-2].map { |p| "#{p}," }.push(people.last).join("\n")
      else
        people.first.to_s
      end
    end

    # Hàm lấy tên loại phép
    def get_name_holtype(scode)
      return nil unless Holtype.where(code: scode).first # Trả về nil không tồn tại
      name_holtype = Holtype.where(code: scode).select(:name).first
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

    # Hàm lấy ngày kí hợp đồng
    def get_signed_contract_date(user)

      return nil unless User.where(id: user).first # Trả về nil nếu user không tồn tại
      earliest_contract = Contract.where(user_id: user)
                                .order(:dtfrom)
                                .select(:issued_date)
                                .first
      earliest_contract&.issued_date&.strftime('%d/%m/%Y') || "Không có dữ liệu"
    end

    # Hàm lấy ngày nghỉ phép từng tháng
    def parse_holiday_details(user_id, year, holtype)
      monthly_leave_days = Array.new(12, 0.0)
      oHoliday = Holiday.where(user_id: user_id, year: year).first
      holpros = Holpro.joins(:holprosdetails, :holiday)
                      .where(holiday_id: oHoliday&.id)
                      .where("holpros.status IN (?)", ["DONE", "CANCEL-DONE"])
                      .select('holprosdetails.details', 'holprosdetails.sholtype','holpros.status')

      # Xử lý dữ liệu
      holpros.each do |holpro|
        next unless holpro.details.present? && holpro.sholtype == holtype
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
      leave_days = Array.new(31, nil)

      # Gán giá trị mặc định
      (1..count_date).each do |day|
        date = Date.new(year.to_i, month.to_i, day)
        leave_days[day - 1] = date.sunday? ? "-" : "X"
      end
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

      holpros = Holpro.joins(:holprosdetails, :holiday)
                      .where(holidays: { id: oHoliday.id })
                      .where("holpros.status IN (?)", ["DONE", "CANCEL-DONE"])
                      .select('holprosdetails.details', 'holprosdetails.sholtype','holpros.status')

      nc_chuan = count_days_excluding_sundays(year.to_i, month.to_i)

      leave_counts = {
        'NGHI-PHEP' => 0.0,
        'NGHI-BU' => 0.0,
        'DI-HOC' => 0.0,
        'NGHI-CDHH' => 0.0,
        'NGHI-LE' => 0.0,
        'HOC-VIEC' => 0.0,
        'NGHI-KHONG-LUONG' => 0.0,
        'NGHI-CHE-DO-BAO-HIEM-XA-HOI' => 0.0,
        'THAI-SAN' => 0.0
      }
      nc_tong_types = ['NGHI-KHONG-LUONG', 'NGHI-CHE-DO-BAO-HIEM-XA-HOI', 'HOC-VIEC', 'THAI-SAN']

      # Gom dữ liệu nghỉ theo ngày
      holpros.each do |holpro|
        next unless holpro.details.present? && holpro.sholtype.present?

        holpro.details.split('$$$').each do |entry|
          date_str, period = entry.split('-')
          next unless date_str && period

          begin
            date = Date.strptime(date_str, '%d/%m/%Y')
            next unless date.year == year && date.month == month

            day_index = date.day - 1
            next unless day_index >= 0 && day_index < count_date

            # Lưu nhiều bản ghi cho cùng 1 ngày
            leave_days[day_index] = [] if leave_days[day_index].is_a?(String) || leave_days[day_index].nil?
            leave_days[day_index] << { type: holpro.sholtype, period: period }

            # Tính số ngày nghỉ
            days = period == 'ALL' ? 1.0 : 0.5
            leave_counts[holpro.sholtype] += days if leave_counts.key?(holpro.sholtype)

          rescue ArgumentError => e
            Rails.logger.error "Invalid date format in details: #{date_str}, error: #{e.message}"
            next
          end
        end
      end

      # Chuyển đổi dữ liệu gom được thành ký hiệu hiển thị
      leave_days.map!.with_index do |val, _idx|
        if val.is_a?(Array)
          # Sắp xếp theo period để xác định sáng trước chiều
          sorted = val.sort_by do |v|
            case v[:period]
            when 'AM'  then 1
            when 'PM'  then 2
            when 'ALL' then 0
            else 9
            end
          end

          labels = sorted.map do |entry|
            type   = entry[:type]
            period = entry[:period]

            case type
            when 'NGHI-PHEP'
              if period == 'ALL' then 'P'
              elsif period == 'AM' then 'P/X'
              else 'X/P' end
            when 'NGHI-BU'
              if period == 'ALL' then 'NB'
              elsif period == 'AM' then 'NB/X'
              else 'X/NB' end
            when 'DI-HOC'
              if period == 'ALL' then 'DH'
              elsif period == 'AM' then 'DH/X'
              else 'X/DH' end
            when 'NGHI-CDHH'
              period == 'ALL' ? 'CD' : 'CD/KL'
            when 'NGHI-LE'
              if period == 'ALL' then 'LT'
              elsif period == 'AM' then 'LT/X'
              else 'X/LT' end
            when 'HOC-VIEC'
              if period == 'ALL' then 'HV'
              elsif period == 'AM' then 'HV/X'
              else 'X/HV' end
            when 'NGHI-KHONG-LUONG'
              if period == 'ALL' then 'KL'
              elsif period == 'AM' then 'KL/X'
              else 'X/KL' end
            when 'NGHI-CHE-DO-BAO-HIEM-XA-HOI'
              if period == 'ALL' then 'BH'
              elsif period == 'AM' then 'BH/X'
              else 'X/BH' end
            when 'THAI-SAN'
              if period == 'ALL' then 'TS'
              elsif period == 'AM' then 'TS/X'
              else 'X/TS' end
            else
              'X'
            end
          end

          # Áp dụng quy tắc gộp đặc biệt (trừ khi có tiền tố X/, giữ nguyên thứ tự)
          if labels.size == 2 && labels.none? { |lbl| lbl.start_with?('X/') }
            a, b = labels
            return_case = case [a.gsub(/^X\//, ''), b.gsub(/^X\//, '')]
            when ['P', 'KL'] then a.include?('P') ? 'P/KL' : 'KL/P'
            when ['KL', 'P'] then a.include?('KL') ? 'KL/P' : 'P/KL'
            when ['P', 'BH'] then a.include?('P') ? 'P/BH' : 'BH/P'
            when ['BH', 'P'] then a.include?('BH') ? 'BH/P' : 'P/BH'
            when ['KL', 'BH'] then a.include?('KL') ? 'KL/BH' : 'BH/KL'
            when ['BH', 'KL'] then a.include?('BH') ? 'BH/KL' : 'KL/BH'
            else
              "#{a}, #{b}"
            end
            return_case
          else
            labels.join(', ')
          end
        else
          val
        end
      end

      leave_count = nc_tong_types.sum { |type| leave_counts[type] }
      nc_tong = nc_chuan - leave_count

      {
        leave_days: leave_days,
        nc_tong: nc_tong,
        nghi_phep: leave_counts['NGHI-PHEP'],
        nghi_bu: leave_counts['NGHI-BU'],
        di_hoc: leave_counts['DI-HOC'],
        nghi_che_do: leave_counts['NGHI-CDHH'],
        nghi_le_tet: leave_counts['NGHI-LE'],
        hoc_viec: leave_counts['HOC-VIEC'],
        khong_luong: leave_counts['NGHI-KHONG-LUONG'],
        che_do_bhxh: leave_counts['NGHI-CHE-DO-BAO-HIEM-XA-HOI'],
        thai_san: leave_counts['THAI-SAN']
      }
    end





    # Hàm lấy chi tiết nghỉ làm thống kê nghỉ theo tháng
    def parse_holiday_details_month(user_id, year, month)
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
        tong_phep: "0.0",
        
      } unless oHoliday

      # Truy vấn Holpro với INNER JOIN và chọn cả sholtype
      holpros = Holpro.joins(:holprosdetails, :holiday)
                      .where(holidays: { id: oHoliday.id })
                      .where("holpros.status IN (?)", ["DONE", "CANCEL-DONE"])
                      .where("holprosdetails.sholtype = ?", 'NGHI-PHEP')
                      .select('holprosdetails.details', 'holprosdetails.sholtype','holpros.status')

      # Tính nc_chuan
      nc_chuan = count_days_excluding_sundays(year.to_i, month.to_i)
      
      # Đếm số ngày nghỉ cho từng loại
      leave_counts = {
        'NGHI-PHEP' => 0.0,
        'NGHI-BU' => 0.0,
        'DI-HOC' => 0.0,
        'NGHI-CDHH' => 0.0,
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

            leave_days[day_index] = period == 'ALL' ? 'P' : 'X/P'
          rescue ArgumentError => e
            Rails.logger.error "Invalid date format in details: #{date_str}, error: #{e.message}"
            next
          end
        end
      end

      # Trả về kết quả
      {
        leave_days: leave_days,
        count_leave_days: leave_days&.sum&.to_f,
        tong_phep: leave_counts['NGHI-PHEP'],
        phep_ton: oHoliday&.holdetails&.where(stype: "TON").first&.amount,
        phep_nam: oHoliday.total
      }
    end

    # Hàm lấy chi tiết nghỉ làm thống kê nghỉ theo tháng
    def parse_holiday_details_by_date(user_id, date_export)
      begin
        date = Date.strptime(date_export, "%d/%m/%Y")
      rescue ArgumentError
        return { error: "Ngày không hợp lệ" }
      end

      formatted_date_vn = "Ngày #{date.day} tháng #{date.month} năm #{date.year}"
      date_str = date.strftime("%d/%m/%Y")
      year = date.year

      oHoliday = Holiday.find_by(user_id: user_id, year: year)
      return { error: "Không có thông tin phép năm", formatted_date: formatted_date_vn } unless oHoliday

      holpros = Holpro.joins(:holprosdetails)
                      .where(holiday_id: oHoliday.id)
                      .where("holpros.status IN (?)", ["DONE", "CANCEL-DONE"])
                      .select('holprosdetails.details', 'holprosdetails.sholtype', 'holprosdetails.place_before_hol', 'holprosdetails.note', 'holprosdetails.handover_receiver')

      result = []

      holpros.each do |holpro|
        next unless holpro.details.present?

        details = holpro.details.split('$$$')
        match = details.any? do |entry|
          entry_date, _period = entry.split('-')
          entry_date&.strip == date_str
        end

        if match
          result << {
            sholtype: holpro.sholtype,
            place_before_hol: holpro.place_before_hol || "",
            note: holpro.note || "",
            handover_receiver: holpro.handover_receiver || ""
          }
        end
      end

      {
        formatted_date: formatted_date_vn,
        details: result.presence || []
      }
    end

    # Hàm để lấy thông tin nghỉ phép theo tháng của nhân sự
    def parse_holiday_details_user(year, user_id)
      details = []
      oHoliday = Holiday.where(user_id: user_id, year: year).first
      return { details: details } unless oHoliday

      # Truy vấn Holpro với INNER JOIN và chọn cả sholtype
      holpros = Holpro.joins(:holprosdetails, :holiday)
                      .where(holiday_id: oHoliday.id)
                      .where("holpros.status IN (?)", ["DONE", "CANCEL-DONE"])
                      .select('holprosdetails.details', 'holprosdetails.sholtype', 'holprosdetails.place_before_hol', 'holprosdetails.note', 'holprosdetails.handover_receiver')

      # Xử lý từng chi tiết
      holpros.each do |holpro|
        next unless holpro.details.present?

        holpro.details.split('$$$').each do |entry|
          date_str, period = entry.split('-')
          next unless date_str && period

          begin
            date = Date.strptime(date_str, '%d/%m/%Y')

            # Đưa vào mảng dữ liệu cho tháng
            details.push({
              date: date.strftime("%d/%m/%Y"),
              sholtype: holpro.sholtype,
              place_before_hol: holpro.place_before_hol,
              note: holpro.note,
              handover_receiver: holpro.handover_receiver
            })
          rescue ArgumentError => e
            Rails.logger.error "Invalid date format in details: #{date_str}, error: #{e.message}"
            next
          end
        end
      end

      { details: details }
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

    # Hàm lấy số ngày nghỉ tính đến tháng hiện tại
    def custom_round_with_half_keep(number)
      return 0 if number.nil?
      number = number.to_f
      int_part = number.to_i
      decimal = number - int_part

      if decimal == 0.5
        number.round(1) # hoặc return number nếu muốn giữ nguyên .5
      else
        number.round
      end
    end

    def phep_duoc_sd_theo_thang(user_id, current_month, department_user_id)
      holiday = Holiday.find_by(user_id: user_id, year: Time.current.year)
      return 0.0 unless holiday

      holdetails = Holdetail.where(holiday_id: holiday.id)

      vi_tri           = holdetails.find { |h| h.name == "Phép theo vị trí" }&.amount.to_f
      tham_niem        = holdetails.find { |h| h.name == "Phép thâm niên" }&.amount.to_f
      so_phep_ton      = holdetails.find { |h| h.name == "Phép tồn" }&.amount.to_f
      phep_ton_da_dung = holdetails.find { |h| h.name == "Phép tồn" }&.used.to_f
      current_phep      = holdetails.find { |h| h.name == "Phép theo vị trí" }&.note.to_f + holdetails.find { |h| h.name == "Phép thâm niên" }&.note.to_f
      current_ton       = holdetails.find { |h| h.name == "Phép tồn" }&.note.to_f
      ton_deadline_str  = holdetails.find { |h| h.name == "Phép tồn" }&.dtdeadline&.strftime("%d/%m/%Y")
      ton_deadline_date = begin
        Date.strptime(ton_deadline_str, "%d/%m/%Y") if ton_deadline_str.present?
      rescue
        nil
      end

      # Đơn đã duyệt
      holpros_ids     = Holpro.where(holiday_id: holiday.id, status: ["DONE", "CANCEL-DONE"]).pluck(:id)
      holpros_details = Holprosdetail.where(holpros_id: holpros_ids, sholtype: ["NGHI-PHEP", "NGHI-CHE-DO"])

      parse_details = lambda do |rows|
        rows.map(&:details).compact.flat_map { |d| d.split('$$$') }.map do |item|
          date_part, session = item.split('-').map(&:strip)
          date = (Date.strptime(date_part, '%d/%m/%Y') rescue nil)
          next nil unless date
          weight = case session&.upcase
                  when 'ALL', nil then 1.0
                  when 'AM', 'PM'  then 0.5
                  else 0
                  end
          [date, weight]
        end.compact

      end

      all_leave_dates = parse_details.call(holpros_details)

      if ton_deadline_date
        before_deadline = all_leave_dates.select { |date, _| date <= ton_deadline_date }
        after_deadline  = all_leave_dates.select { |date, _| date >  ton_deadline_date }
      else
        before_deadline = []
        after_deadline  = all_leave_dates
      end

      phep_ton_da_dung_thuc_te = before_deadline.sum { |_, w| w }
      phep_ton_da_dung_thuc_te    += current_phep

      phep_da_dung_thuc_te     = after_deadline.sum  { |_, w| w }
      phep_da_dung_thuc_te        += current_ton
      # Nếu dùng phần "trong hạn" vượt quá số phép tồn thì phần vượt chuyển sang "sau hạn"
      if phep_ton_da_dung_thuc_te > so_phep_ton
        phep_da_dung_thuc_te += (phep_ton_da_dung_thuc_te - so_phep_ton)
        phep_ton_da_dung_thuc_te = so_phep_ton
      end

      actual_holno, worked_months_to_now, worked_months_to_end, check_tnlv =
        calculate_actual_holno_sup(user_id, department_user_id)

      actual        = (actual_holno != vi_tri ? actual_holno : vi_tri)
      so_phep_tong  = actual + tham_niem
      co_so_duoc_sd = if check_tnlv
                        custom_round(so_phep_tong / 12.0 * current_month)
                      else
                        custom_round((so_phep_tong / worked_months_to_end.to_f) * worked_months_to_now)
                      end

      phep_duoc_sd = co_so_duoc_sd - phep_da_dung_thuc_te
      custom_round_with_half_keep(phep_duoc_sd)
    end

    def calculate_actual_holno_sup(user_id, department_id)
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
end  