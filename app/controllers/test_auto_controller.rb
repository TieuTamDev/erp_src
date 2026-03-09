require 'net/http'
require 'uri'
class TestAutoController < ApplicationController
  def index


    # list url in system
    # urls_all_test = Rails.application.routes.routes.map do |route|
    #   "https://capp.bmtu.edu.vn/mywork" + route.path.spec.to_s.gsub(/\(\.:format\)/, '') + "?lang=vi" if route.verb.match(/GET/)
    # end.compact


    # url test
    urls_all = [
      "https://capp.bmtu.edu.vn/mywork/tmpcontracts/index?lang=vi",
      "https://capp.bmtu.edu.vn/mywork/payslips/index?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/sbenefits/index?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/mhistories/index?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/tbbenefits/index?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/tbarchivetypes/index?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/tbarchivelevels/index?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/tbdepartmenttypes/index?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/tbhospitals/index?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/regulation/index?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/positionjobs/index?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/permissions/index?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/permission/check_unique_per?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/resources/index?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/departments/index?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/users/index?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/disciplines/index?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/stasks/index?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/dashboards/index?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/notifies/index?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/maintain/index?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/notifies/index?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/dashboards/index?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/dashboards/personnelbymonth?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/get_function_data?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/landingpage?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/login?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/logout?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/forgotpw?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/maintenance?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/resetpwd?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/user/profile?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/user/details?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/user/details/contract/pdf?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/user/check_unique_sid?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/user/check_unique_username?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/user/check_unique_email?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/user/check_username_exists?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/user/check_positionjob_exists?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/user/check_phone_exists?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/user/checkOrg?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/user/show_select?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/user/export_users?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/user/benefit/details?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/user/archive/details?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/user/contract/preview?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/user/holiday/details?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/user/apply/details?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/user/check_unique_iden?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/user/identity/details?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/user/address/details?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/user/archive/details?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/department/details?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/department/checkuserorg?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/positionjob/update_responsible?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/positionjob/ckDub?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/positionjob/hrlist_index?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/resource/required?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/discipline/details?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/stask/edit?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/department/streams?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/appoints/index?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/nationality/index?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/organization/index?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/religions/index?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/ethnic/index?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/contracttime/index?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/tbusertype/index?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/tbuserstatus/index?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/academicrank/index?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/contracttype/index?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/departmenttype/index?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/functions/index?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/sbenefits/get_selected_users?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/notpermission?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/mandocs/incoming/index?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/mandocs/incoming/find_one?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/mandocs/get_department?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/mandocs/outgoing/index?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/mandocs/outgoing/find_one?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/mandocs/outgoing/export?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/mandocs/process/index?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/mandocs/process/find_one?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/mandocs/process/export?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/mandoc_count?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/mandocs/watch/index?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/mandocs/search/index?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/mandocs/search/search_mandoc?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/mandocs/select_search_mandoc?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/mandocbook/index?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/mandocbook/get_all?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/mandocbook/check_duplicate?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/mandoctype/index?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/mandoctype/get_all?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/mandoctype/check_duplicate?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/mandocpriority/index?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/mandocpriority/check_duplicate?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/mandocpriority/get_all?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/mandoc_outgoing/outgoing_index?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/mandocfroms/index?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/mandocfroms/get_all?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/mandocfroms/check_duplicate?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/user/iframe_user?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/mandocs/:id/update_read?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/mandocs?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/mandocs/new?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/mandocs/:id/edit?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/mandocs/:id?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/mandocs/destroy?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/forms/index?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/released_mandocs/incoming/index?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/released_mandocs/incoming/find_one?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/released_mandocs/get_users_by_department?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/released_mandocs?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/released_mandocs/new?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/released_mandocs/:id/edit?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/released_mandocs/:id?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/released_mandocs/outgoing/index?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/released_mandocs/outgoing/find_one?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/acchists/index?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/operstream/index?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/organizations?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/streams?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/operstream/get_all_functions?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/operstream/get_all_organizations?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/operstream/get_all_streams?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/calendar/index?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/releasednotes/index?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/documents/index?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/documents/history?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/documents/history?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/documents/erp?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/tools/edit_word?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/tools/spreadsheet?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/test_auto/index?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/test_auto/result?lang=vi",
      # "https://capp.bmtu.edu.vn/mywork/?lang=vi"

    ]
    # cookie = login_and_get_cookie
    @results = []
    # threads = urls_all.map do |url|
    #   # Thread.new do
    #   #   # result = check_url(url, cookie)
    #   #   # @results.push(result)
    #   # end
    # end

    # @results = urls_all.each do |url|
    #   check_url(url, cookie)
    # end
    threads.each(&:join)
    render json: { results: @results}
  end

  # def login_and_get_cookie
  #   Rails.logger.info("Đang thực hiện đăng nhập để lấy cookie")
  #   uri = URI('https://capp.bmtu.edu.vn/mywork/login?lang=vi')
  #   response = Net::HTTP.post_form(uri, { 'email_txt' => 'admin1@gmail.com', 'password_txt' => 'Hrm@2023' })
  #   cookie = response['set-cookie']
  #   Rails.logger.info("Cookie nhận được: #{cookie}") # Ghi lại cookie để kiểm tra
  #   return cookie
  # end

  # def check_url(url, cookie)
  #   uri = URI.parse(url) # Sử dụng trực tiếp URL thay vì ghép chuỗi
  #   # Tạo yêu cầu GET với cookie
  #   request = Net::HTTP::Get.new(uri)
  #   request['Cookie'] = cookie
  #   begin
  #     response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: (uri.scheme == 'https')) do |http|
  #       http.request(request)
  #     end
  #     # Kiểm tra phản hồi và trả về kết quả
  #     { url: url, code: response.code, status: response.is_a?(Net::HTTPSuccess) ? "Accessible" : "Error" }
  #   rescue => e
  #     # Xử lý trường hợp yêu cầu thất bại
  #     { url: url, code: 'Error', status: e.message }
  #   end
  # end

end
