class AttendMailer < ApplicationMailer
  default from: "Hệ thống ERP BMU <no-reply@bmtuvietnam.com>"

  def attend_mailer(email, mmodule)
    @mmodule_name = mmodule[:name]
    @room_names = mmodule[:room_names]
    @time_schedule = mmodule[:time_schedule]

    bcc_emails = [
        'lnhuy@bmtuvietnam.com',
        'ntpvy@bmtuvietnam.com'
    ]
    
    mail(
        to: email,
        bcc: bcc_emails,
        subject: "THÔNG BÁO THỜI GIAN LỊCH GIẢNG #{@mmodule_name} TẠI PHÒNG #{@room_names} SẮP KẾT THÚC",
        template_name: 'attend_mailer'
    )
  end

  def late_checkin_mailer(user, mmodule)
    @mmodule_name = mmodule[:name]
    @room_names = mmodule[:room_names]
    @time_schedule = mmodule[:time_schedule]
    @current_time = mmodule[:current_time]

    @full_name = user[:full_name]
    @user_email = user[:user_email]
    @user_sid = user[:user_sid]

    bcc_emails = [
        'lnhuy@bmtuvietnam.com',
        'ntpvy@bmtuvietnam.com'
    ]
    
    mail(
        to: @user_email,
        bcc: bcc_emails,
        subject: "CẢNH BÁO GIẢNG VIÊN #{@full_name.upcase} ĐIỂM DANH MUỘN TẠI PHÒNG #{@room_names.upcase} VÀO NGÀY #{mmodule[:date_now]}",
        template_name: 'late_checkin_mailer'
    )
  end

  def not_checkout_mailer(user, mmodule, current_time)
    @mmodule_name = mmodule[:name]
    @room_names = mmodule[:room_names]
    @time_schedule = mmodule[:time_schedule]
    @current_time = current_time

    @full_name = user[:full_name]
    @user_email = user[:user_email]
    @user_sid = user[:user_sid]

    bcc_emails = [
        'lnhuy@bmtuvietnam.com',
        'ntpvy@bmtuvietnam.com'
    ]
    
    mail(
        to: @user_email,
        bcc: bcc_emails,
        subject: "CẢNH BÁO GIẢNG VIÊN #{@full_name.upcase} CHƯA CHECKOUT BUỔI HỌC TẠI PHÒNG #{@room_names.upcase} VÀO NGÀY #{mmodule[:date_now]}",
        template_name: 'not_checkout_mailer'
    )
  end
end
