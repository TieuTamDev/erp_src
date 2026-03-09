class ExportUserDataController < ApplicationController
  require 'axlsx'

  def export_excel
      user_ids = params[:user_ids] || []
      @users = User.where(id: 10053)

      require 'axlsx'
      require 'date'

      p = Axlsx::Package.new
      wb = p.workbook

      wb.add_worksheet(name: "All") do |sheet|
        # Dòng 1: Tiêu đề chính
        sheet.add_row [
          "STT", "Mã nhân sự", "Tình trạng nhân sự", "Phân loại nhân sự", "Dạng Hợp tác", "Họ và tên", "Ngày sinh",
          "Đơn vị chủ quản", "Đơn vị trực thuộc", "Chức vụ/chức danh", "Công việc kiêm nhiệm", "Quê quán", "Nơi sinh",
          "Quốc tịch", "Dân tộc", "Tôn giáo", "Giới tính", "Số Định danh", "Ngày cấp", "Nơi cấp", "Ngày hết hạn",
          "Số CMND", "Ngày cấp", "Nơi cấp", "Địa chỉ thường trú", "Địa chỉ liên hệ", "Số điện thoại",
          "Số điện thoại khẩn cấp", "Người liên hệ khẩn cấp", "Tình trạng hôn nhân", "Email cá nhân", "Email nội bộ",
          "Mã hóa trình độ chuyên môn", "Mã hóa chức danh/chức vụ", "Chuyên ngành đào tạo", "Cơ sở đào tạo",
          "Năm tốt nghiệp", "Xếp loại tốt nghiệp", "Hình thức đào tạo", "Danh hiệu", "Học hàm", "Chứng chỉ ngoại ngữ",
          "Chứng chỉ tin học", "Chứng chỉ giảng dạy", "Số Chứng Chỉ/ Giấy phép Hành Nghề",
          "Ngày cấp Chứng Chỉ/ Giấy phép Hành Nghề", "Ngày hết hạn Chứng Chỉ/ Giấy phép Hành Nghề", "Đơn vị cấp",
          "Phạm vi hoạt động", "Quyết định mở rộng phạm vi hoạt động", "Trung cấp", "", "", "", "",
          "Cao đẳng", "", "", "", "", "Đại học", "", "", "", "", "Thạc sĩ/CKI", "", "", "", "",
          "Tiến sĩ/CKII", "", "", "", "", "Học toàn thời gian nước ngoài", "Học bán thời gian nước ngoài",
          "Các quyết định công nhận chức danh nghề nghiệp", "Ngày bắt đầu làm việc", "Ngày kết thúc làm việc",
          "số VB chấm dứt HĐ"
        ]

        # Dòng 2: Tiêu đề chi tiết và merge ô hợp đồng
        row2 = [
          nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
          nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil,
          nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil, "Chuyên ngành", "Xếp loại",
          "Trường đào tạo", "Hình thức đào tạo", "Năm tốt nghiệp", "Chuyên ngành", "Xếp loại", "Trường đào tạo",
          "Hình thức đào tạo", "Năm tốt nghiệp", "Chuyên ngành", "Xếp loại", "Trường đào tạo", "Hình thức đào tạo",
          "Năm tốt nghiệp", "Thạc sĩ/CKI", "Chuyên ngành", "Trường đào tạo", "Hình thức đào tạo", "Năm tốt nghiệp",
          "Tiến sĩ/CKII", "Chuyên ngành", "Trường đào tạo", "Hình thức đào tạo", "Năm tốt nghiệp", nil, nil,
          "HỢP ĐỒNG CỘNG TÁC VIÊN", "Mã HĐ", "Ngày bắt đầu", "Thời hạn HĐ", "Ngày kết thúc",
          "HỢP ĐỒNG CỐ VẤN", "Mã HĐ", "Ngày bắt đầu", "Thời hạn HĐ", "Ngày kết thúc",
          "HỢP ĐỒNG HỢP TÁC/THỈNH GIẢNG", "Mã HĐ", "Ngày bắt đầu", "Thời hạn HĐ", "Ngày kết thúc",
          "HỢP ĐỒNG TẬP NGHỀ/HỌC VIỆC", "Mã HĐ", "Ngày bắt đầu", "Thời hạn HĐ", "Ngày kết thúc",
          "HỢP ĐỒNG THỬ VIỆC", "Mã HĐ", "Ngày bắt đầu", "Thời hạn HĐ", "Ngày kết thúc",
          "HỢP ĐỒNG LAO ĐỘNG CÓ XÁC ĐỊNH", "Mã HĐ", "Ngày bắt đầu", "Thời hạn HĐ", "Ngày kết thúc",
          "HỢP ĐỒNG LAO ĐỘNG CÓ XÁC ĐỊNH", "Mã HĐ", "Ngày bắt đầu", "Thời hạn HĐ", "Ngày kết thúc",
          "HỢP ĐỒNG KHÔNG XÁC ĐỊNH", "Mã HĐ", "Ngày bắt đầu", "Thời hạn HĐ", "Ngày kết thúc",
          "HỢP ĐỒNG KHÁC (TÍNH THÂM NIÊN)", "Mã HĐ", "Ngày bắt đầu", "Thời hạn HĐ", "Ngày kết thúc",
          "Mã Số BHXH", "Mã Số Thuế", "Số Tài Khoản BIDV", "Ngân Hàng - Chi Nhánh", "Số TK ngân hàng khác",
          "Ngân Hàng khác", "Chi Nhánh ngân hàng khác", "Ngày vào đảng", "Dự bị", "Chính thức", "Độ tuổi"
        ]
        sheet.add_row row2

        # Merge ô hợp đồng và ngày vào đảng
        sheet.merge_cells("BJ1:BN1") # HỢP ĐỒNG CỘNG TÁC VIÊN
        sheet.merge_cells("BO1:BS1") # HỢP ĐỒNG CỐ VẤN
        sheet.merge_cells("BT1:BX1") # HỢP ĐỒNG HỢP TÁC/THỈNH GIẢNG
        sheet.merge_cells("BY1:CC1") # HỢP ĐỒNG TẬP NGHỀ/HỌC VIỆC
        sheet.merge_cells("CD1:CH1") # HỢP ĐỒNG THỬ VIỆC
        sheet.merge_cells("CI1:CM1") # HỢP ĐỒNG LAO ĐỘNG CÓ XÁC ĐỊNH
        sheet.merge_cells("CN1:CQ1") # HỢP ĐỒNG LAO ĐỘNG CÓ XÁC ĐỊNH
        sheet.merge_cells("CR1:CV1") # HỢP ĐỒNG KHÔNG XÁC ĐỊNH
        sheet.merge_cells("CW1:DA1") # HỢP ĐỒNG KHÁC (TÍNH THÂM NIÊN)
        sheet.merge_cells("DB1:DD1") # Ngày vào đảng (giới hạn đến DD theo file mẫu)

        # Dữ liệu người dùng
        @users.each_with_index do |user, index|
          full_name = [user.last_name, user.first_name].compact.join(" ")
          gender = case user.gender
                  when "0" then "Nam"
                  when "1" then "Nữ"
                  when "2" then "Khác"
                  else "---"
                  end
          marriage = user.marriage == "Married" ? "Kết hôn" : "Độc thân"
          phone = [user.phone, user.mobile].compact.reject(&:empty?).join(", ") rescue "---"
          age = Date.today.year - user.birthday.year rescue "---"
          age -= 1 if Date.today < user.birthday.next_year(age).to_date rescue "---"

          org = user.uorgs.joins(:organization).pluck("organizations.name").join(", ") rescue "---"
          direct_depts = user.works.joins(positionjob: :department)
                            .where(departments: { is_virtual: [nil, ""] })
                            .pluck("departments.name").join(", ") rescue "---"
          positions = user.works.joins(positionjob: :department)
                        .where(departments: { is_virtual: [nil, ""] })
                        .pluck("positionjobs.name").join(", ") rescue "---"
          concurrent_jobs = user.works.joins(positionjob: :department)
                              .where.not(departments: { is_virtual: [nil, ""] })
                              .pluck("positionjobs.name").join(", ") rescue "---"

          cccd = user.identities.find_by(stype: "CCCD") || {}
          cmnd = user.identities.find_by(stype: "CMND") || {}
          # Lấy địa chỉ từ bảng addresses
          permanent_address = user.addresses.find_by(stype: "Thường Trú")
          permanent_address = [permanent_address&.no, permanent_address&.street, permanent_address&.ward,
                            permanent_address&.district, permanent_address&.city, permanent_address&.province,
                            permanent_address&.country].compact.reject(&:empty?).join(", ") rescue "---"
          temporary_address = user.addresses.find_by(stype: "Tạm Trú")
          temporary_address = [temporary_address&.no, temporary_address&.street, temporary_address&.ward,
                            temporary_address&.district, temporary_address&.city, temporary_address&.province,
                            temporary_address&.country].compact.reject(&:empty?).join(", ") rescue "---"

          contract_types = {
            "hợpđồngcộngtácviên" => ["BJ", "HỢP ĐỒNG CỘNG TÁC VIÊN"],
            "hợpđồngcốvấn" => ["BO", "HỢP ĐỒNG CỐ VẤN"],
            "hợpđồnghợptác" => ["BT", "HỢP ĐỒNG HỢP TÁC/THỈNH GIẢNG"],
            "hợpđồngtậpnghề" => ["BY", "HỢP ĐỒNG TẬP NGHỀ/HỌC VIỆC"],
            "hợpđồngthửviệc" => ["CD", "HỢP ĐỒNG THỬ VIỆC"],
            "hđlđcóthờihạn" => ["CI", "HỢP ĐỒNG LAO ĐỒNG CÓ XÁC ĐỊNH"],
            "hđlđkhôngxácđịnhthờihạn" => ["CR", "HỢP ĐỒNG KHÔNG XÁC ĐỊNH"],
            "hợpđồngkhác" => ["CW", "HỢP ĐỒNG KHÁC (TÍNH THÂM NIÊN)"]
          }
          contract_data = {}
          user.contracts.each do |contract|
            normalized_name = contract.name.downcase.gsub(/\s+/, "").strip
            key = contract_types.keys.find { |k| normalized_name.include?(k) }
            if key
              col = contract_types[key][0]
              contract_data[col] = [
                "-", # Mã HĐ
                contract.dtfrom&.strftime("%Y-%m-%d") || "---",
                contract.issued_place || "---",
                contract.dtto&.strftime("%Y-%m-%d") || "---"
              ]
            end
          end

          bidv = user.banks.find_by(ba_name: "BIDV") || {}
          other_bank = user.banks.where.not(ba_name: "BIDV").first || {}

          row = [
            index + 1, user.sid || "---", user.staff_status || "---", user.staff_type || "---", "-",
            full_name, user.birthday&.strftime("%Y-%m-%d") || "---", org, direct_depts, positions,
            concurrent_jobs, user.place_of_birth || "---", user.m_place_of_birth || "---", user.nationality || "---",
            user.ethnic || "---", user.religion || "---", gender, cccd.name || "---", cccd.issued_date&.strftime("%Y-%m-%d") || "---",
            cccd.issued_place || "---", cccd.issued_expired&.strftime("%Y-%m-%d") || "---", cmnd.name || "---",
            cmnd.issued_date&.strftime("%Y-%m-%d") || "---", cmnd.issued_place || "---", permanent_address,
            temporary_address, phone, "---", "---", marriage, user.email1 || "---", user.email || "---", "-",
            "-", "-", "-", "-", "-", "-", "-", "-", "-", "-", "-", "-", "-", "-", "-", "-", "-", "-", "-", "-",
            "-", "-", "-", "-", "-", "-", "-", "-", "-", "-", "-", "-", "-", "-", "-", user.created_at&.strftime("%Y-%m-%d") || "---",
            user.termination_date&.strftime("%Y-%m-%d") || "---", "-"
          ]

          # Thêm dữ liệu hợp đồng
          contract_cols = ("BJ".."DA").to_a[0..44] # Giới hạn đến DA, khớp với file mẫu
          contract_data.each_with_index do |(col, data), idx|
            start_col = contract_cols.index(col)
            row[start_col..(start_col + 3)] = data if start_col && start_col + 3 < contract_cols.length
          end

          row += [
            user.insurance_no || "---", user.taxid || "---", bidv.ba_number || "---", bidv.branch || "---",
            other_bank.ba_number || "---", other_bank.ba_name || "---", other_bank.branch || "---", "-", "-", "-",
            age # Đặt độ tuổi ở cột CD (vị trí 88)
          ]

          # Điền các cột còn lại bằng nil để khớp số lượng cột (121 cột)
          row += [nil] * (121 - row.length) if row.length < 121

          sheet.add_row row
        end
      end

      # Xuất file Excel
      temp_file = Tempfile.new(["employee_data", ".xlsx"])
      p.serialize(temp_file.path)
      send_file temp_file.path, filename: "employee_data_#{Date.today.strftime('%Y%m%d')}.xlsx", disposition: 'attachment'
      temp_file.close
  end



end
