class Holpro
    def holiday_user
        tomorrow = Date.current + 1.day
        tomorrow_str = tomorrow.strftime("%d/%m/%Y")

        user_ids_tomorrow = Holprosdetail.joins(holpro: :holiday)
                                            .where("holprosdetails.details LIKE ?", "%#{tomorrow_str}%")
                                            .pluck("holidays.user_id")
                                            .uniq
        organization = Organization.find_by(scode: "BUH")

        buh_user_ids = User.joins(:uorgs)
                            .where(id: user_ids_tomorrow)
                            .where(uorgs: { organization_id: organization.id })
                            .pluck(:id)
        buh_details = Holprosdetail.joins(holpro: :holiday)
                                    .where("holprosdetails.details LIKE ?", "%#{tomorrow_str}%")
                                    .where(holidays: { user_id: buh_user_ids }).pluck(:holpros_id).uniq
        list_mandoc = Mandoc.where(holpros_id: buh_details)
        list_dhandle = Mandocdhandle.where(mandoc_id: list_mandoc).pluck(:id).uniq
        records = Mandocuhandle
            .joins(mandocdhandle: { mandoc: { holpro: :holiday } })
            .where(mandocdhandle_id: list_dhandle, status: "CHUAXULY", srole: "MAIN")
            .select("mandocuhandles.user_id AS approver_id, holidays.user_id AS holiday_user_id")

        # Gom theo người duyệt (approver_id)
        grouped = records.group_by(&:approver_id)

        grouped.each do |approver_id, recs|
            # Lấy danh sách holiday_user_id duy nhất
            holiday_user_ids = recs.map(&:holiday_user_id).uniq
            users_info = User.where(id: holiday_user_ids).pluck(:id, :first_name, :last_name, :sid)
            detail_lines = users_info.map do |id, fname, lname, sid|
                "Nhân sự: #{fname} #{lname} (Mã: #{sid})"
            end
            approver_email = User.find_by(id: approver_id)&.email
            if approver_email.present?
                HolidayMailer.notifi_holpro(
                approver_email,
                detail_lines.join("<br>")
                ).deliver_now
            end
            holiday_user_ids.each do |uid|
                user_email = User.find_by(id: uid)&.email
                next if user_email.blank?

                HolidayMailer.notifi_holpro(
                user_email,
                "Đơn của bạn chưa được xử lý"
                ).deliver_now
            end
        end

    end
end