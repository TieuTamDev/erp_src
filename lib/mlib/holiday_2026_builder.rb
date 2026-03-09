class Holiday2026Builder
  def nam_hien_tai
    Date.current.year
  end

  def nam_cu
    nam_hien_tai - 1
  end


  # ==============================
  # ENTRY POINT
  # ==============================
  def run_buil_holiday
    bat_dau = Time.current
    logs = []

    organization = Organization.find_by(scode: "BUH")
    raise "Organization BUH not found" unless organization

    users = User.joins(:uorgs)
                .where(uorgs: { organization_id: organization.id })
                .where(status: "ACTIVE")
                .distinct

    users.find_each do |user|
      holiday_2025 = Holiday.find_by(user_id: user.id, year: nam_cu)
      next unless holiday_2025
      next if Holiday.exists?(user_id: user.id, year: nam_hien_tai)

      department = fetch_leaf_departments_by_user(user.id)&.first
      next unless department

      ket_qua = tinh_toan(user, department.id)
      next unless ket_qua

      create_holiday(user.id, ket_qua[:holdetails])

      logs << {
        user_id: user.id
      }
    end

    {
      bat_dau: bat_dau,
      ket_thuc: Time.current,
      tong_user: logs.size,
      tong_time: Time.current - bat_dau
    }
    puts "The total processing time of the run_buil_holiday function is: #{Time.current - bat_dau}s"
  end
  # ==============================
  # CORE LOGIC
  # ==============================
  def tinh_toan(user, department_id)
    holiday_2025 = Holiday.find_by(user_id: user.id, year: nam_cu)
    return nil unless holiday_2025

    # ============================
    # PHÉP NĂM 2025 (KHÔNG TÍNH TON)
    # ============================
    so_phep_nam_2025 =
      Holdetail.where(holiday_id: holiday_2025.id)
              .where.not(stype: "TON")
              .sum(:amount)
              .to_f

    phep_da_dung = phep_da_dung_thuc_te(holiday_2025)
    chenhlech = so_phep_nam_2025 - phep_da_dung

    # ============================
    # PHÉP ĐĂNG KÝ SỚM 2026
    # ============================
    phep_som = phep_som_2026_tu_nam_cu(holiday_2025)

    # ============================
    # PHÉP ÂM 2025
    # ============================
    phep_am = chenhlech < 0 ? chenhlech.abs : 0

    # ============================
    # PHÉP GỐC
    # ============================
    phep_ton_goc = chenhlech > 0 ? chenhlech : 0

    phep_vi_tri_goc =
      Positionjob.where(
        id: Work.where(user_id: user.id)
                .where.not(positionjob_id: nil)
                .pluck(:positionjob_id),
        department_id: department_id
      ).first&.holno.to_f || 0

    # ============================
    # TÍNH USED CHUẨN
    # ============================
    used_ton = [phep_som, phep_ton_goc].min
    vuot_ton = [phep_som - phep_ton_goc, 0].max

    used_vi_tri = phep_am + vuot_ton
    phep_tham_nien_goc = tinh_tham_nien_user(user.id)
    # ============================
    # BUILD HOLDDETAIL
    # ============================
    {
      holdetails: [
        {
          name: "Phép tồn",
          stype: "TON",
          amount: phep_ton_goc,
          used: used_ton,
          dtdeadline: Date.new(nam_hien_tai, 3, 31)
        },
        {
          name: "Phép thâm niên",
          stype: "THAM-NIEN",
          amount: phep_tham_nien_goc,
        },
        {
          name: "Phép vị trí",
          stype: "VI-TRI",
          amount: phep_vi_tri_goc,
          used: used_vi_tri,
        }
      ]
    }
  end
  def tinh_tham_nien_user(user_id)
    milestones = [5, 10, 15, 20, 25, 30]
    today = Date.current

    # Lấy organization BUH
    organization = Organization.find_by(scode: "BUH")
    return 0 unless organization

    # Chỉ user ACTIVE
    return 0 unless User.joins(:uorgs)
                        .where(id: user_id, status: "ACTIVE")
                        .where(uorgs: { organization_id: organization.id })
                        .exists?

    # Các mốc ngày chính xác
    target_dates = milestones.map do |m|
      Date.new(today.year - m, today.month, today.day)
    end

    conditions = target_dates.map { "(dtfrom >= ? AND dtfrom <= ?)" }.join(" OR ")
    values = target_dates.flat_map { |d| [d.beginning_of_day, d.end_of_day] }

    contracts = Contract.where(user_id: user_id)
                        .where(conditions, *values)
                        .joins("INNER JOIN contracttypes c ON c.name = contracts.name")
                        .where("c.is_seniority = ?", "YES")

    return 0 if contracts.empty?

    dt = contracts.first.dtfrom.to_date
    years = ((today - dt).to_i / 365).floor

    milestone_x(years) || 0
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


  # ==============================
  # CREATE DB
  # ==============================
  def create_holiday(user_id, holdetails)
    return if Holiday.exists?(user_id: user_id, year: nam_hien_tai)

    Holiday.transaction do
      # ============================
      # CREATE HOLIDAY (used = 0 tạm)
      # ============================
      holiday = Holiday.create!(
        user_id: user_id,
        year: nam_hien_tai,
        total: holdetails.sum { |h| h[:amount] },
        used: 0
      )

      total_used = 0.0

      # ============================
      # CREATE HOLDDETAIL
      # ============================
      holdetails.each do |h|
        used_value = h[:used].to_f   # 👈 lấy used theo từng loại
        total_used += used_value

        Holdetail.create!(
          holiday_id: holiday.id,
          name: h[:name],
          stype: h[:stype],
          amount: h[:amount],
          used: used_value,
          dtdeadline: h[:dtdeadline]
        )
      end

      # ============================
      # UPDATE HOLIDAY.USED
      # ============================
      holiday.update!(used: total_used)
    end
  end


  # ==============================
  # HELPERS
  # ==============================
  def tach_ngay_nghi(details)
    details.to_s.split("$$$").map do |item|
      d, buoi = item.split("-").map(&:strip)
      date = Date.strptime(d, "%d/%m/%Y")
      so_ngay = buoi.nil? || buoi.upcase == "ALL" ? 1.0 : 0.5
      [date, so_ngay]
    rescue
      nil
    end.compact
  end

  def fetch_leaf_departments_by_user(user_id)
    positionjob_ids = Work.where(user_id: user_id)
                          .where.not(positionjob_id: nil)
                          .pluck(:positionjob_id)

    department_ids = Positionjob.where(id: positionjob_ids).pluck(:department_id)
    departments = Department.where(id: department_ids, status: "0")
                              .where.not(parents: [nil, ""])

    if departments.present?
      parent_ids = departments.map(&:parents).compact.map(&:to_i)
      departments.reject { |d| parent_ids.include?(d.id) }
    else
      Department.where(id: department_ids, status: "0").limit(1)
    end
  end

  def phep_chua_duyet(holiday)
    holpro_ids = Holpro.where(holiday_id: holiday.id)
                        .where.not(status: %w[DONE CANCEL-DONE])
                        .pluck(:id)

    Holprosdetail.where(
      holpros_id: holpro_ids,
      sholtype: %w[NGHI-PHEP NGHI-CHE-DO]
    ).flat_map { |d| tach_ngay_nghi(d.details) }
      .sum { |_, w| w }
  end

  def phep_da_dung_thuc_te(holiday)
    tong_used = Holdetail.where(holiday_id: holiday.id)
                          .where.not(stype: "TON")
                          .sum(:used)
                          .to_f

    ket_qua = tong_used - phep_chua_duyet(holiday)
    ket_qua.negative? ? 0 : ket_qua
  end

  def phep_som_2026_tu_nam_cu(holiday_2025)
    holpro_ids = Holpro.where(
      holiday_id: holiday_2025.id,
      status: %w[DONE CANCEL-DONE]
    ).pluck(:id)

    Holprosdetail.where(
      holpros_id: holpro_ids,
      sholtype: %w[NGHI-PHEP NGHI-CHE-DO]
    ).flat_map { |d| tach_ngay_nghi(d.details) }
      .select { |date, _| date.year == nam_hien_tai }
      .sum { |_, w| w }
  end

  # ==============================
  # BUILD HOLDDETAIL
  # ==============================
  def build_phep_ton(amount)
    {
      name: "Phép tồn",
      stype: "TON",
      amount: amount,
      used: 0,
      note: nil,
      dtdeadline: Date.new(nam_hien_tai, 3, 31)
    }
  end

  def build_phep_tham_nien(amount)
    {
      name: "Phép thâm niên",
      stype: "THAM-NIEN",
      amount: amount,
      used: 0,
      note: nil,
      dtdeadline: nil
    }
  end

  def build_phep_vi_tri(amount)
    {
      name: "Phép vị trí",
      stype: "VI-TRI",
      amount: amount,
      used: 0,
      note: nil,
      dtdeadline: nil
    }
  end
end
