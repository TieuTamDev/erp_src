class UserMailer < ApplicationMailer
    default 'Content-Transfer-Encoding' => '8bit'
    def send_email(username)
        @oUser = User.where("username = '#{username}'").first
        @expired = DateTime.now + 1
      if !@oUser.nil?
        mail(from: "Hệ Thống ERP <erp@bmtuvietnam.com>", to: @oUser.email, subject: "Đổi lại mật khẩu",template_name: "reset_email")
        return
      end
    end

    def send_OTP_email(email, strOTP)
      @strOTP = strOTP
      @oUser = User.where("email = '#{email}'").first
      if !@oUser.nil?
        mail(from: "Hệ Thống ERP <erp@bmtuvietnam.com>", to: @oUser.email, subject: "Mã xác minh",template_name: "send_OTP")
        return
      end
    end

    def mandoc_handle(user, file_urls, mandoc_id, receiving_unit_id, sending_unit, deadline, note, positionjob, base_url)
        @oUser_id = User.where(id: user).first
        @oUser_email = User.where(email: user).first
        if !@oUser_id.nil? || !@oUser_email.nil?
          # # Đính kèm file của mandoc max size 10 MB
          if !file_urls.blank?
            file_urls.each do |file_url|
                attachments[file_url.split('/').last] = {
                  mime_type: 'application/json',
                  content: File.read(file_url),
                  max_size: 25.megabytes
                }  
            end
          end
          # # Đính kèm file của mandoc max size 10 MB

          # Lấy thông tin mandoc
          @data = {}
          oMandoc = Mandoc.where(id: mandoc_id).first
          if !oMandoc.nil?
            @data = @data.merge({
              :contents => oMandoc.contents,      # Nội dung văn bản
              :created_at => oMandoc.created_at,      # Ngày soạn
              :received_at => oMandoc.received_at,      # Ngày nhận
              :sfrom => oMandoc.sfrom,      # Nơi gửi
              :spriority => oMandoc.spriority,      # Độ khẩn
              :stype => oMandoc.stype,      # Loại văn bản
              :sno => oMandoc.sno,      # Số văn bản
              :symbol => oMandoc.ssymbol,      # Ký hiệu văn bản
              :notes => oMandoc.notes,      # Ghi chú văn bản
            })
            department_id = Node.where(nfirst: "YES").first.department_id
            if !department_id.nil?
              department_name = Department.where(id: department_id).first.name 
              if !department_name.nil? 
                @data = @data.merge({
                  :create_unit => oMandoc.mdepartment != nil ? oMandoc.mdepartment : department_name,      # Đơn vị tạo
                  :create_unit_vt => oMandoc.mdepartment != nil ? oMandoc.mdepartment.gsub(/[^A-ZAĂÂBCDĐEÊFGHIJKLMNOÔƠPQRSTUƯVXY-]/, '').insert(1, ".") : department_name.gsub(/[^A-ZAĂÂBCDĐEÊFGHIJKLMNOÔƠPQRSTUƯVXY-]/, '').insert(1, "."),      # Đơn vị tạo viết tắt
                })
              end
            end
          end
          # Lấy thông tin mandoc

          # Lấy thông tin đơn vị
          oDepartment = Department.where(id: receiving_unit_id).first
          if !oDepartment.nil?
            @data = @data.merge({
              :receiving_unit => oDepartment.name,      # Đơn vị tiếp nhận
              :positionjob => positionjob,      # Đơn vị tiếp nhận
            })
          end
          @data = @data.merge({ 
            :sending_unit => sending_unit,      # Đơn vị gửi
            :deadline => deadline,      # Hạn xử lý
            :note => note,    # Nội dung xử lý của đơn vị gửi
            :base_url => base_url    # Link xử lý
          })
          # Lấy thông tin đơn vị

          sSubject = "[#{@data[:create_unit_vt] != nil && @data[:create_unit_vt] != '' ? @data[:create_unit_vt] : ''}]: #{@data[:stype] != nil && @data[:stype] != '' ? @data[:stype] : ''} #{@data[:sno] != nil && @data[:sno] != '' ? 'số '+ @data[:sno] : ''} về việc #{@data[:notes] != nil && @data[:notes] != '' ? @data[:notes] : ''}"
          if !@oUser_id.nil?
            mail(from: "Hệ Thống ERP <erp@bmtuvietnam.com>", to: @oUser_id.email, subject: sSubject,template_name: "mandoc_handle")
          end
          if !@oUser_email.nil?
            mail(from: "Hệ Thống ERP <erp@bmtuvietnam.com>", to: @oUser_email.email, subject: sSubject,template_name: "mandoc_handle")
          end
        end
    end

    ##
      # @author: Lê Ngọc Huy
      # @date: 20/05/2023
      # This Ruby function sends an email with specified content and attachments to a list of users and departments based on their IDs.
    ##
    def release_mandoc(arrEmail, subject, content, url_files, url_files_big, oMandoc, count, department_send_email)
      @data = {}
      if !url_files.blank?
        url_files.each do |url_file|
            attachments[url_file.split('/').last] = {
              mime_type: 'application/json',
              content: File.read(url_file),
              max_size: 24.megabytes
            }  
        end
      end

      @data = @data.merge({ 
        :content => content,     
        :file_urls => url_files_big,
        :count => count
      })
  
      mail(from: "#{department_send_email} <erp@bmtuvietnam.com>",to: arrEmail, subject: subject, template_name: "release_mandoc")
    end
    
    def release_mandoc_test(email, subject, content, file_urls, oMandoc, path, department_send_email)
      url_files = []
      url_files_big = []
      @data = {}
      count = 0
      if !file_urls.nil?
        oMandocfiles = Mandocfile.where(id: file_urls)
        if !oMandocfiles.nil? 
            oMandocfiles.each do |mandocfile|
                oMediafiles = Mediafile.where(id: mandocfile.mediafile_id)
                if !oMediafiles.nil?
                    oMediafiles.each do |mediafile|
                        if mediafile.file_size.to_i < 23.megabytes
                          url_files.append("/data/hrm/" + mediafile.file_name)
                        else
                          count = count + 1
                          if mediafile.file_type.include?("application/pdf")
                            icon_path = "#{path}/assets/image/bmtu_pdf.png"
                            file_type = "pdf"
                          elsif mediafile.file_type.include?("application/vnd.openxmlformats-officedocument.presentationml.presentation")
                            icon_path = "#{path}/assets/image/bmtu_powerpoint.png"
                            file_type = "powerpoint"
                          elsif mediafile.file_type.include?("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet")
                            icon_path = "#{path}/assets/image/bmtu_excel.png"
                            file_type ="excel"
                          elsif mediafile.file_type.include?("application/vnd.openxmlformats-officedocument.wordprocessingml.document")
                            icon_path = "#{path}/assets/image/bmtu_word.png"
                            file_type = "word"
                          elsif mediafile.file_type.include?("application/x-zip-compressed") || mediafile.file_type.include?("application/octet-stream")
                            icon_path = "#{path}/assets/image/bmtu_zip.png"
                            file_type = "zip"
                          else
                            icon_path = "#{path}/assets/image/bmtu_file.png"
                            file_type = "file"
                          end                          
                          url_files_big.append({
                            :name => mediafile.file_name,
                            :icon_path => icon_path,
                            :file_type => file_type,
                            :file_size => "12 MB",
                            :path => "#{path}/mdata/hrm/#{mediafile.file_name}"
                          })
                        end
                    end 
                end 
            end
        end
      end

      if !url_files.blank?
        url_files.each do |url_file|
            attachments[url_file.split('/').last] = {
              mime_type: 'application/json',
              content: File.read(url_file),
              max_size: 24.megabytes
            }  
        end
      end

      @data = @data.merge({ 
        :content => content,     
        :file_urls => url_files_big,
        :count => count
      })
      logger.info "Listing attachments #{email}"
      mail(from: "#{department_send_email} <erp@bmtuvietnam.com>", to: email, subject: subject, template_name: "release_mandoc")
    end

    def send_mail_leave_request(email, content)
      return if email.blank?

      @content = content
      bcc_emails = ["ntpvy@bmtuvietnam.com"]

      mail(
        from: "Hệ Thống ERP <erp@bmtuvietnam.com>",
        to: email,
        bcc: bcc_emails,
        subject: "Thông báo duyệt phép",
        template_name: "send_leave_request"
      )
    end
    def send_mail_leave_change(email, content)
      return if email.blank?

      @content = content
      bcc_emails = ["ntpvy@bmtuvietnam.com"]

      mail(
        from: "Hệ Thống ERP <erp@bmtuvietnam.com>",
        to: email,
        bcc: bcc_emails,
        subject: "Thông báo điều chỉnh phép BHXH",
        template_name: "send_leave_changes"
      )
    end

    def send_email_reject_shiftselection(user_id,data)
      @content = data
      user = User.find(user_id)
      email = user.email
      @content[:user_full_name] = "#{user.last_name} #{user.first_name}"
      bcc_emails = ["ntpvy@bmtuvietnam.com"]
      mail(
        from: "Hệ Thống ERP <erp@bmtuvietnam.com>",
        to: "ntpvy@bmtuvietnam.com",
        bcc: bcc_emails,
        subject: "Thông báo duyệt kế hoạch tuần",
        template_name: "reject_shiftselection"
      )
    end

    # Method để gửi email đơn giản qua API - TRONGLQ
    def send_simple_email(to_email, subject, content, from_email = nil, cc_emails = nil, bcc_emails = nil)
      @content = content
      
      mail_options = {
        from: from_email || "Hệ Thống ERP <erp@bmtuvietnam.com>",
        to: to_email,
        subject: subject,
        body: content
      }
      
      mail_options[:cc] = cc_emails if cc_emails && cc_emails.any?
      mail_options[:bcc] = bcc_emails if bcc_emails && bcc_emails.any?
      
      mail(mail_options)
    end

end
