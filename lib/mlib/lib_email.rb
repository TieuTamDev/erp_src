require 'mail'
class Email_Utils
	def mail_reset_pass(mail_from, mail_to, subject, first_name, last_name, link_path)
		## Send mail
      	body_html = "<div align='center' style='width:100%'>
	    <table border='0' cellspacing='0' cellpadding='0' style='background:white; margin:0 auto'>
	      <tr>
	        <td width='580' colspan='3' style='width:435 pt'>
	          <div style='text-align: center; font-size: 25px; font-weight: bolder; border-bottom: solid 1px #ccc;'>
	            <span style='color: #1868B2;'>Chocitokyo</span>
	          </div>
	        </td>
	      </tr>
	      <tr>
	        <td colspan='3' style='padding: 10px;'>
	          <b>
	            <span style='color:#27983C'>Password Reset Request</span>
	          </b>
	        </td>
	      </tr>
	      <tr>
	        <td width='560' valign='top' style='padding: 10px;'>
	          <span style='font-size:10.0pt'>Dear #{first_name} #{last_name},<br><br>
	            We appreciate the opportunity to serve your online needs. We wanted to let you know that we received your request to reset your password. For security reasons we prefer not to make the change on your behalf. To change the password, please follow the link below: <br><br>
	            <a href='#{link_path}' target='_blank'>#{link_path}</a>
	            <br><br>If you believe someone requested this change without your consent, please contact us at <a href='https://www.chocitokyo.net' target='_blank'>https://www.chocitokyo.net</a>. <br><br>
	            Thank you for choosing Chocitokyo. If you have any questions or need assistance, please contact us at <a href='https://www.chocitokyo.net' target='_blank'>https://www.chocitokyo.net</a>. <br><br>
	            Sincerely,<br><br>
	            Chocitokyo® Customer Support<br>
	          </span>
	        </td>
	        <td width='10'></td>
	      </tr>
	      <tr>
	        <td style='padding: 10px;'>
	          <span style='font-size:10.0pt;'>Please do not reply to this email. Replying to this email will not secure your services.</span>
	        </td>
	      </tr>
	    </table>
	   </div>"
  
      mail = Mail.new do
          from     mail_from
          to       mail_to
          subject  subject
      end
      html_part = Mail::Part.new do
          content_type 'text/html; charset=UTF-8'
          body body_html
      end
      mail.html_part = html_part
      mail.delivery_method :sendmail
      mail.deliver
    ## End
	end
end