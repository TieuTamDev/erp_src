# app/mailers/system_mailer.rb
class SystemMailer < ApplicationMailer
    def sys_email(emails, title, content)
      mail(to: emails, subject: title,
           body: content, content_type: 'text/plain; charset=UTF-8')
    end
  end
  