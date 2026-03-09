class HolidayMailer < ApplicationMailer
    default from: "Hệ thống ERP <no-reply@bmtuvietnam.com>",
        :return_path => 'ERPbmtu@bmtuvietnam.com@bmtuvietnam.com@bmtuvietnam.com',
        :reply_to => 'no-reply@bmtuvietnam.com'
    default 'Content-Transfer-Encoding' => '8bit'
  
    def alert_holpros_approval_pending(data)

            email = data[:user_signed][:email]
            codes = data[:user_signed][:uorg_code] || []

            bcc_mails = []
            uorg_code = []

            if codes.include?("BUH")
                bcc_mails += ["ntpvy@bmtuvietnam.com", "hxhanh@bmtuvietnam.com", "uyenndt@benhvienbmt.com", "thaoltp93@benhvienbmt.com"]
                # bcc_mails += ["ntpvy@bmtuvietnam.com", "hxhanh@bmtuvietnam.com", "dqhai@bmtuvietnam.com"]
                uorg_code += ["BUH"]
            end

            if codes.include?("BMTU")
                bcc_mails += ["ntpvy@bmtuvietnam.com", "dqhai@bmtuvietnam.com", "ntmlinh@bmtuvietnam.com", "ntploan@bmtuvietnam.com"]
                # bcc_mails += ["ntpvy@bmtuvietnam.com", "dqhai@bmtuvietnam.com", "hxhanh@bmtuvietnam.com"]
                uorg_code += ["BMTU"]
            end

            if codes.include?("BMU")
                bcc_mails += ["ntpvy@bmtuvietnam.com", "dqhai@bmtuvietnam.com", "ntmlinh@bmtuvietnam.com", "ntploan@bmtuvietnam.com"]
                # bcc_mails += ["ntpvy@bmtuvietnam.com", "dqhai@bmtuvietnam.com", "hxhanh@bmtuvietnam.com"]
                uorg_code += ["BMU"]
            end

            # loại trùng email nếu có
            bcc_mails.uniq!
            uorg_code.uniq!

            @datas = data[:records]
            @uorg_code = uorg_code

            mail(to: email, bcc: bcc_mails, subject: '⚠️Cảnh báo: Đơn xin nghỉ của nhân sự chưa được duyệt')
        
    end

    def notifi_holpro(email, message)
        bcc_mails = ["ntpvy@bmtuvietnam.com", "uyenndt@benhvienbmt.com"]
        @message = message
        mail(
            to: email,
            bcc: bcc_mails,
            subject: "⚠️Cảnh báo: Đơn xin nghỉ của nhân sự chưa được duyệt"
        )
    end
    
  end