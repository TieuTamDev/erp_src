class Seniority
  def seniority_update
    # Lấy organization và users active
    organization = Organization.find_by(scode: "BUH")
    return unless organization
    active_user_ids = User.joins(:uorgs)
                          .where(uorgs: { organization_id: organization.id })
                          .where(status: "ACTIVE")
                          .distinct
                          .pluck(:id)
    return if active_user_ids.empty?
    milestones = [5, 10, 15, 20, 25, 30]
    today = Date.current
    # Tạo các ngày target chính xác
    target_dates = milestones.map { |m| Date.new(today.year - m, today.month, today.day) }
    # Tạo điều kiện WHERE bằng cách so sánh khoảng ngày
    conditions = target_dates.map { |d| "(dtfrom >= ? AND dtfrom <= ?)" }.join(" OR ")
    values = target_dates.flat_map { |d| [d.beginning_of_day, d.end_of_day] }
    # Lấy các hợp đồng milestone thuộc user active
    milestone_contracts = Contract.where(conditions, *values)
                                  .where(user_id: active_user_ids)
    return if milestone_contracts.empty?
    ctype_map = Contracttype.all.index_by(&:name)
    # Chỉ giữ hợp đồng có tính thâm niên
    milestone_contracts = milestone_contracts.joins("INNER JOIN contracttypes c ON c.name = contracts.name")
                                         .where("c.is_seniority = ?", "YES")
    return if milestone_contracts.empty?
    # Nhóm theo user
    contracts_by_user = milestone_contracts.group_by(&:user_id)
    contracts_by_user.each do |user_id, contracts|
      # Lấy contract milestone đầu tiên (tất cả cùng ngày)
      dt = contracts.first.dtfrom.to_date

      # Tính số năm thâm niên chính xác (theo ngày)
      years = ((today - dt).to_i / 365).floor
      x = milestone_x(years)
      next unless x

      # Lấy Holiday trong năm hiện tại
      hol = Holiday.where(user_id: user_id, year: today.year).first
      next unless hol

      # Lấy Holdetail thâm niên
      hdetail = Holdetail.where(holiday_id: hol.id, stype: "THAM-NIEN").first
      next unless hdetail

      current_amount = hdetail.amount.to_i

      # Nếu amount >= x thì bỏ qua
      next if current_amount >= x

      # Phần chênh lệch
      y = x - current_amount
      # Update Holdetail
      hdetail.update(amount: x)
      # Update tổng phép Holiday
      hol.update(total: hol.total.to_i + y)
    end
  end

  # Hàm tính mốc x dựa trên số năm
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

end