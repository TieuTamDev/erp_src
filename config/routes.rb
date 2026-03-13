Rails.application.routes.draw do

  get 'tmpcontracts/index'
  post 'tmpcontracts/update'
  get 'tmpcontracts/find_one'

  get 'payslips/index'

  get 'sbenefits/index'

  get 'mhistories/index'

  get 'tbbenefits/index'

  get 'tbarchivetypes/index'

  get 'tbarchivelevels/index'

  get 'tbdepartmenttypes/index'

  get 'tbhospitals/index'

  get 'regulation/index'

  get 'positionjobs/index'

  get 'permissions/index'

  get '/permission/check_unique_per' => "permissions#check_unique_per"

  get 'resources/index'

  get 'departments/index'
  
  # TODO: department manager
  get 'departments/department_list' => "departments#department_list"
  get 'departments/get_department_childs' => "departments#get_department_childs"
  get 'departments/department_details' => "departments#department_details"
  post 'departments/department_details' => "departments#department_details"
  get 'departments/get_department_by_stype' => "departments#get_department_by_stype"
  get 'departments/get_positionjob_users' => "departments#get_positionjob_users"
  get 'departments/export_excel' => 'departments#export_excel'
  get 'departments/get_datas_of_positionjobs' => 'departments#get_datas_of_positionjobs'
  post 'departments/:department_id/add_function_into_department', to: 'departments#add_function_into_department', as: 'add_function_into_department'
  get 'departments/get_stasks' => 'departments#get_stasks'
  get 'departments/get_stasks_of_user' => 'departments#get_stasks_of_user'
  get 'departments/get_gtasks' => 'departments#get_gtasks'
  post 'departments/add_stasks_into_user' => "departments#add_stasks_into_user"
  get 'departments/assign_stasks' => 'departments#assign_stasks'
  get 'departments/fetch_by_organization', to: 'departments#fetch_by_organization'
  post 'departments/add_user_positionjob', to: 'departments#add_user_positionjob'
  get 'departments/get_users', to: 'departments#get_users'

  get 'users/index'

  get 'disciplines/index'

  get 'stasks/index'

  get 'dashboards/index'

  get 'notifies/index'# HAI 03/08/2023
  get 'notifies/show' => "notifies#show"
  get 'notifies/render_modal/:snotices_id' => "notifies#render_modal"
  get 'notifies/show' => "notifies#show"

  # Maintain (Dat 22/02/2023)
  get 'maintain/index'

  get 'notifies/index' => "notifies#index" # HAI 03/08/2023
  post 'notifies/update_isread_snotify' => "notifies#update_isread_snotify"# HAI 03/08/2023

  post '/options_table' => 'dashboards#options_table' # Huy 28/12/2022

  get 'dashboards/index' => "dashboards#index"
  post 'dashboards/update_isread_snotify' => "dashboards#update_isread_snotify"# HAI 03/08/2023
  get 'dashboards/personnelbymonth' => "dashboards#personnelbymonth"

  get 'dashboards/list_user_leave' => "dashboards#list_user_leave"

  root 'dashboards#index'

  get '/get_function_data', to: 'operstream#get_function_data'

  #dong 7/4/2023
  get '/landingpage' => "sessions#landingpage"
  post '/redirect_to_erp' => "sessions#redirect_to_erp"
  post '/redirect_to_straining' => "sessions#redirect_to_straining"
  post '/redirect_to_assets' => "sessions#redirect_to_assets"
  post '/redirect_to_nha_khoa' => "sessions#redirect_to_nha_khoa"
  post '/redirect_to_da_lieu' => "sessions#redirect_to_da_lieu"
  post '/redirect_to_tham_my' => "sessions#redirect_to_tham_my"
  post '/redirect_to_sam_viet_han' => "sessions#redirect_to_sam_viet_han"
  post '/redirect_to_vien_nghien_cuu' => "sessions#redirect_to_vien_nghien_cuu"

  get '/login' => "sessions#new" # HAI
  post '/login' => "sessions#create" # HAI
  post '/login_two_auth/:id' => "sessions#two_auth"
  get '/logout' => 'sessions#del' #Hai sua lai
  delete '/logout' => 'sessions#del' #Hai sua lai

  # Forgot Password
  get '/forgotpw' => "sessions#forgotpw"
  post '/forgotpw_info' => "sessions#forgotpw_info"


  # Maintain notifications (22/02/2023)
  get '/maintenance' => "sessions#maintenance"

  # Reset Password
  get '/resetpwd' => 'sessions#resetpwd'
  post '/resetpwd_update' => 'sessions#resetpwd_update'

  # Users
  get '/user/profile' => "users#profile" # DAT
  get '/user/edit' => "users#edit"
  post '/user/update' => "users#update"
  post '/user/avatar/update' => "users#update_avatar"
  get '/user/del' => "users#del"
  delete '/user/del' => "users#del"
  get '/user/details' => "users#details"
  get '/user/details/contract/pdf' => 'users#contract_pdf' # VU: 06/01/2023
  get '/user/check_unique_sid' => "users#check_unique_sid"
  get '/user/check_unique_username' => "users#check_unique_username"
  get '/user/check_unique_email' => "users#check_unique_email"
  get '/user/check_username_exists' => "users#check_username_exists"
  get '/user/check_positionjob_exists' => "users#check_positionjob_exists"
  get '/user/check_phone_exists' => "users#check_phone_exists"
  post '/user/adoc_upload_mediafile' => "users#adoc_upload_mediafile"
  delete '/user/adoc_del' => "users#adoc_del"
  get '/user/adoc_del' => "users#adoc_del"
  get '/user/checkOrg' => "users#checkOrg"
  post '/user/import_users' => "users#import_users"
  post '/user/update_imports' => "users#update_imports"

  get '/user/show_select' => "users#show_select"
  post '/user/change_password' => 'users#change_password'
  get '/user/export_users' => 'users#export_users'


   # Benefit
  get '/user/benefit/edit' => "users#benefit_edit"
  post '/user/benefit/update' => "users#benefit_update"
  post '/user/benefit/upload' => "users#benefit_upload_mediafile"
  delete '/user/benefit/del' => "users#benefit_del"
  get '/user/benefit/details' => "users#benefit_details"
  post '/user/benefit/chart_benefit' => 'users#chart_benefit' # Huy 28/12/2022
    # archive
  get '/user/archive/edit' => "users#archive_edit"
  post '/user/archive/update' => "users#archive_update"
  post '/user/archive/upload' => "users#archive_upload_mediafile"
  get '/user/archive/del' => "users#archive_del"
  get '/user/archive/details' => "users#archive_details"

    # review
  get '/user/review/edit' => "users#review_edit"
  post '/user/review/update' => "users#review_update"
  post '/user/review/upload' => "users#review_upload_mediafile"
  get '/user/review/del' => "users#review_del"
  delete '/user/review/del' => "users#review_del"
  post '/user/review/details' => "users#review_details"

    # contract
  get '/user/contract/edit' => "users#contract_edit"
  post '/user/contract/update' => "users#contract_update"
  post '/user/contract/upload' => "users#contract_upload_mediafile"
  get '/user/contract/del' => "users#contract_del"
  delete '/user/contract/del' => "users#contract_del"
  get '/user/contract/preview' => "users#contract_preview"
  post '/user/contract/review/update' => "users#contract_preview_update"

    # holiday
  get '/user/holiday/edit' => "users#holiday_edit"
  post '/user/holiday/update' => "users#holiday_update"
  post '/user/holiday/upload' => "users#holiday_upload_mediafile"
  delete '/user/holiday/del' => "users#holiday_del"
  get '/user/holiday/details' => "users#holiday_details"

    # work
  get '/user/work/edit' => "users#work_edit"
  get '/user/work/edit_status' => "users#work_edit_status"
  post '/user/work/update' => "users#work_update"
  delete '/user/work/del' => "users#work_del"

    # apply
  get '/user/apply/edit' => "users#apply_edit"
  post '/user/apply/update' => "users#apply_update"
  post '/user/apply/upload' => "users#apply_upload_mediafile"
  get '/user/apply/del' => "users#apply_del"
  get '/user/apply/details' => "users#apply_details"

    # identity
  get '/user/check_unique_iden' => "users#check_unique_iden"
  get '/user/identity/edit' => "users#identity_edit"
  post '/user/identity/update' => "users#identity_update"
  post '/user/identity/upload' => "users#identity_upload_mediafile"
  delete '/user/identity/del' => "users#identity_del"
  get '/user/identity/del' => "users#identity_del"
  get '/user/identity/details' => "users#identity_details"

    # address
  get '/user/address/edit' => "users#address_edit"
  post '/user/address/update' => "users#address_update"
  post '/user/address/update_user' => "users#address_update_user"
  post '/user/address/upload' => "users#address_upload_mediafile"
  delete '/user/address/del' => "users#address_del"
  get '/user/address/del' => "users#address_del"
  get '/user/address/details' => "users#address_details"

    # social
    post '/user/social/update' => "users#social_update"
    delete '/user/social/del' => "users#social_del"
    get '/user/social/del' => "users#social_del"

  # archive #LNQ.Thai
  get '/user/archive/edit' => "users#archive_edit"
  post '/user/archive/update' => "users#archive_update"
  post '/user/archive/upload' => "users#archive_upload_mediafile"
  delete '/user/archive/del' => "users#archive_del"
  get '/user/archive/details' => "users#archive_details"

  #Tbarchivetype & Tbarchivelevel LNQ.Thai
  post '/tbarchivetypes/update' => 'tbarchivetypes#update'
  delete '/tbarchivetypes/del' => "tbarchivetypes#del"
  get '/tbarchivetypes/del' => "tbarchivetypes#del"

  post '/tbarchivelevels/update' => 'tbarchivelevels#update'
  delete '/tbarchivelevels/del' => "tbarchivelevels#del"
  get '/tbarchivelevels/del' => "tbarchivelevels#del"

  # work_history => LNQ.Thai
  post '/user/work_history_update' => 'users#work_history_update'
  delete '/user/work_history_del' => "users#work_history_del"
  get '/user/work_history_del' => "users#work_history_del"

    # Bank => TP.Dong
  post '/user/bank_update' => "users#bank_update"
  delete '/user/bank_del' => "users#bank_del"
  get '/user/bank_del' => "users#bank_del"

  # Education => HT.Dat
  post '/user/education_update' => "users#education_update"
  delete '/user/education_del' => "users#education_del"
  get '/user/education_del' => "users#education_del"

  # Relative => HT.Dat
  post '/user/relative_update' => "users#relative_update"
  delete '/user/relative_del' => "users#relative_del"
  get '/user/relative_del' => "users#relative_del"
  post '/user/relative_upload' => "users#relative_upload_mediafile"
  get '/user/relative/edit' => "users#relative_edit"
  post 'user/update_2fa_status' => "users#update_2fa_status"
# Singnature
post '/singnature/upload_file' => 'users#upload_file'
post '/singnature/change' => 'users#singnature_change'
post '/singnature/create' => 'users#singnature_create'
post '/singnature/update/:id' => 'users#singnature_update'
delete '/singnature/remove_file' => 'users#remove_file'

    # departments
  get '/department/edit' => "departments#edit"
  post '/department/update' => "departments#update"
  post '/department/upload' => "departments#departments_upload_mediafile"
  get '/department/del' => "departments#del"
  delete '/department/del' => "departments#del"
  get '/department/details' => "departments#details"
  get '/department/checkuserorg' => "departments#check_user_org"




  post 'department/docucment' => "departments#ddoc_update"
  post '/department/upload_file_processing' => "departments#upload_file_processing"


    # permission
  get '/permission/edit' => "permissions#edit"
  post '/permission/update' => "permissions#update"
  get '/permission/del' => "permissions#del"
  delete '/permission/del' => "permissions#del"


  # position job
  get '/positionjob/edit' => "positionjobs#edit"
  post '/positionjob/update' => "positionjobs#update"
  get '/positionjob/del' => "positionjobs#del"
  delete '/positionjob/del' => "positionjobs#del"
  get '/positionjob/update_responsible' => 'positionjobs#update_responsible'
  post '/positionjob/info_assign' => 'positionjobs#info_assign'
  get '/positionjob/ckDub' => 'positionjobs#ckDub'
  get '/positionjob/hrlist_index' => 'positionjobs#hrlist_index' #Hai sua lai

  get '/positionjob/authority_level' => 'positionjobs#authority_level'
  post '/positionjob/authority_level' => 'positionjobs#authority_level'
  post '/positionjob/authority_level_create' => 'positionjobs#authority_level_create'
  resources :positionjobs
    # regulation
  get '/regulations/edit' => "regulation#edit"
  post '/regulations/handle_sql' => "regulation#handle_sql"
  get '/regulations/del' => "regulation#del"

    # resources
  get '/resource/edit' => "resources#edit"
  post '/resource/update' => "resources#update"
  get '/resource/del' => "resources#del"
  delete '/resource/del' => "resources#del"
  get '/resource/required' => "resources#required"

    # disciplines
  get '/discipline/edit' => "disciplines#edit"
  post '/discipline/update' => "disciplines#update"
  post '/discipline/upload' => "disciplines#discipline_upload_mediafile"
  get '/discipline/del' => "disciplines#del"
  delete '/discipline/del' => "disciplines#del"
  get '/discipline/details' => "disciplines#details"

    # stasks
  get '/stask/edit' => "stasks#edit"
  get '/stask/del_work' => "stasks#del_work"
  delete '/stask/del_work' => "stasks#del_work"
  post '/stask/del_user_asign' => "stasks#del_user_asign"
  post '/stask/update' => "stasks#update"
  post '/stask/access/update' => "stasks#access_update"
  post '/stask/asign_stask_user' => "stasks#asign_stask_user"
  post '/stask/list_user_asign_stask' => "stasks#list_user_asign_stask"
  get '/stask/access/del' => "stasks#access_del"
  delete '/stask/access/del' => "stasks#access_del"
  get '/stask/del' => "stasks#del"
  delete '/stask/del' => "stasks#del"


  # streams
  get '/department/streams' => "departments#streams" #VU
  get '/department/streams/edit' => "departments#streams_edit" #VU
  post '/department/streams/update' => "departments#streams_update" #VU
  delete '/department/streams/delete' => "departments#streams_delete" #VU

  # appoints
  get '/appoints/index' => "appoints#index"
  get '/appoints/edit' => "appoints#edit"
  post '/appoints/update' => "appoints#update"
  delete '/appoints/del' => "appoints#del"
  get '/appoints/del' => "appoints#del"
  post 'appoints/import_excel', to: 'appoints#import_excel', as: 'import_excel_appoints'

  # nationality huy 22/12/2022
  get '/nationality/index' => "nationality#index"
  post '/nationality/update' => "nationality#update"
  delete '/nationality/del' => "nationality#del"
  get '/nationality/del' => "nationality#del"

  # organization Thai
  get '/organization/index' => "organization#index"
  post '/organization/update' => "organization#update"
  delete '/organization/del' => "organization#del"
  get '/organization/del' => "organization#del"

  # religion
  get '/religions/index' => "religions#index"
  post '/religions/update' => "religions#update"
  get '/religions/del' => "religions#del"
  delete '/religions/del' => "religions#del"

  # education
  get '/education/edit' => "education#edit"
  post '/education/update' => "education#update"
  delete '/education/del' => "education#del"
  get '/education/del' => "education#del"

  # ethnic hai 22/12/2022
  get '/ethnic/index' => "ethnics#index"
  post '/ethnic/update' => "ethnics#update"
  delete '/ethnic/del' => "ethnics#del"
  get '/ethnic/del' => "ethnics#del"
  post '/user/import_user_contract' => "users#import_user_contract"
  get '/user/download_template_import_contract' => "users#download_template_import_contract"
  get '/user/download_template_import_user' => "users#download_template_import_user"



  # contracttime hai 26/12/2022
  get '/contracttime/index' => "contracttimes#index"
  post '/contracttime/update' => "contracttimes#update"
  delete '/contracttime/del' => "contracttimes#del"
  get '/contracttime/del' => "contracttimes#del"

  # tbusertype hai 27/12/2022
  get '/tbusertype/index' => "tbusertypes#index"
  post '/tbusertype/update' => "tbusertypes#update"
  delete '/tbusertype/del' => "tbusertypes#del"
  get '/tbusertype/del' => "tbusertypes#del"

    # tbuserstatus hai 27/12/2022
  get '/tbuserstatus/index' => "tbuserstatuss#index"
  post '/tbuserstatus/update' => "tbuserstatuss#update"
  delete '/tbuserstatus/del' => "tbuserstatuss#del"
  get '/tbuserstatus/del' => "tbuserstatuss#del"

  #academic rank H-Anh 22/12/2022
  get '/academicrank/index' => "academicranks#index"
  post '/academicrank/update' => "academicranks#update"
  delete '/academicrank/del' => "academicranks#del"
  get '/academicrank/del' => "academicranks#del"

  get '/contracttype/index' => "contracttypes#index"
  post '/contracttype/update' => "contracttypes#update"
  delete '/contracttype/del' => "contracttypes#del"
  get '/contracttype/del' => "contracttypes#del"

  #departmenttype H-Anh 22/12/2022
  get '/departmenttype/index' => "departmenttypes#index"
  post '/departmenttype/update' => "departmenttypes#update"
  delete '/departmenttype/del' => "departmenttypes#del"
  get '/departmenttype/del' => "departmenttypes#del"

  #function Hai 07/04/2023
  get '/functions/index' => "functions#index"
  post '/functions/update' => "functions#update"
  delete '/functions/del' => "functions#del"
  get '/functions/del' => "functions#del"


  # Tbhospital Đạt 28/12/2022
  post '/tbhospitals/update' => "tbhospitals#update"
  delete '/tbhospitals/del' => "tbhospitals#del"
  get '/tbhospitals/del' => "tbhospitals#del"

  # Tbdepartmenttype Đồng 28/12/2022

  post '/tbdepartmenttypes/update' => "tbdepartmenttypes#update"
  delete '/tbdepartmenttypes/del' => "tbdepartmenttypes#del"
  get '/tbdepartmenttypes/del' => "tbdepartmenttypes#del"

  # tbbenefits Dong 4/1/2023
  post '/tbbenefits/update' => "tbbenefits#update"
  delete '/tbbenefits/del' => "tbbenefits#del"
  get '/tbbenefits/del' => "tbbenefits#del"

  # Sbenefit Đạt 06/01/2023
  post '/sbenefits/update' => "sbenefits#update"
  post '/sbenefits/update_benefit_last_year' => "sbenefits#update_benefit_last_year"
  delete '/sbenefits/del' => "sbenefits#del"
  get '/sbenefits/del' => "sbenefits#del"
  post '/sbenefits/add_multiply_benefits' => "sbenefits#add_multiply_benefits"
  get '/sbenefits/get_selected_users' => "sbenefits#get_selected_users"



  # no reponse
  get '/notpermission' => "layoutresponse#no_response_page"

  #Document to
  get '/mandocs/incoming/index' => "mandocs#incoming_index"
  post '/mandocs/incoming/update' => "mandocs#incoming_update"
  post '/mandocs/incoming/upload' => "mandocs#mandocfile_upload_mediafile"
  delete '/mandocs/incoming/del' => "mandocs#delete_mandocfile_incoming"
  get '/mandocs/incoming/del' => "mandocs#delete_mandocfile_incoming"
  post '/mandocs/assign_leader' => "mandocs#assign_leader"
  post '/mandocs/assign_handle_department' => "mandocs#assign_handle_department"
  post '/mandocs/assign_handle_department_in' => "mandocs#assign_handle_department_in"
  post '/mandocs/assign_handle_department_tchc' => "mandocs#assign_handle_department_tchc"
  post '/mandocs/release_docs' => "mandocs#release_docs"
  post '/mandocs/save_release_docs' => "mandocs#save_release_docs"
  get '/mandocs/incoming/find_one' => "mandocs#find_one"
  post '/mandocs/incoming/get_mandocs_status_in' => "mandocs#get_mandocs_status_in"
  delete '/mandocs/del' => "mandocs#del"
  get '/mandocs/del' => "mandocs#del"
  get '/mandocs/del_after_handle' => "mandocs#del_after_handle"
  delete '/mandocs/del_after_handle' => "mandocs#del_after_handle"
  get '/mandocs/get_department' => "mandocs#get_department"
  post '/mandocs/confirm_mandoc' => "mandocs#confirm_mandoc"
  post '/mandocs/cancel_mandoc' => "mandocs#cancel_mandoc"
  post '/mandocs/send_email_test' => "mandocs#send_email_test"


  #Documents go
  get '/mandocs/outgoing/index' => "mandocs#outgoing_index"
  post '/mandocs/outgoing/update' => "mandocs#outgoing_update"
  post '/mandocs/outgoing/edit' => "mandocs#outgoing_edit"
  post '/mandocs/outgoing/edit_handle' => "mandocs#outgoing_edit_handle"
  post '/mandocs/outgoing/change_read' => "mandocs#outgoing_change_read"
  post '/mandocs/outgoing/upload' => "mandocs#mandocfile_upload_mediafile"
  delete '/mandocs/outgoing/del' => "mandocs#delete_mandocfile_outgoing"
  get '/mandocs/outgoing/del' => "mandocs#delete_mandocfile_outgoing"
  get '/mandocs/outgoing/find_one' => "mandocs#find_one"
  get '/mandocs/outgoing/export' => "mandocs#outgoing_export_pdf"
  post '/mandocs/incoming/get_mandocs_status_out' => "mandocs#get_mandocs_status_out"
  post '/mandocs/get_list_users_with_depatment' => "mandocs#get_list_users_with_depatment"
  post '/mandocs/check_duplicate_symboll' => "mandocs#check_duplicate_symboll"
  post '/mandocs/vt_add_comment' => "mandocs#vt_add_comment"


  #Document to be processed
  get '/mandocs/process/index' => "mandocs#process_index"
  post '/mandocs/process/update' => "mandocs#process_update"
  post '/mandocs/process/assign_users' => "mandocs#assign_users_process"
  post '/mandocs/process/user_process' => "mandocs#user_process"
  post '/mandocs/process/assign_departments' => "mandocs#assign_departments"
  post '/mandocs/process/assign_departments_with_user' => "mandocs#assign_departments_with_user"
  post '/mandocs/process/assign_departments_with_user_bld' => "mandocs#assign_departments_with_user_bld"
  get '/mandocs/process/find_one' => "mandocs#find_one"
  get '/mandocs/process/export' => "mandocs#outgoing_export_pdf"
  post '/mandocs/incoming/get_mandocs_status_processed' => "mandocs#get_mandocs_status_processed"
  get '/mandoc_count', to: 'mandocs#mandoc_count', as: 'mandoc_count'
  #Document to follow
  get '/mandocs/watch/index' => "mandocs#watch_index"

  #Search mandoc
  get '/mandocs/search/index' => "mandocs#search_index"
  get '/mandocs/search/search_mandoc' => "mandocs#search_mandoc"
  put '/mandocs/search/mandoc_un_effect' => 'mandocs#mandoc_un_effect'
  get '/mandocs/select_search_mandoc' => 'mandocs#mandoc_select_search'


  #Mandocbook
  get '/mandocbook/index' => "mandocbook#index"
  post '/mandocbook/update' => "mandocbook#update"
  delete '/mandocbook/del' => "mandocbook#del"
  get '/mandocbook/del' => "mandocbook#del"
  get '/mandocbook/get_all' => "mandocbook#get_all"
  get '/mandocbook/check_duplicate' => "mandocbook#check_duplicate"


  #mandoctype
  get '/mandoctype/index' => "mandoctype#index"
  post '/mandoctype/update' => "mandoctype#update"
  delete '/mandoctype/del' => "mandoctype#del"
  get '/mandoctype/del' => "mandoctype#del"
  get '/mandoctype/get_all' => "mandoctype#get_all"
  get '/mandoctype/check_duplicate' => "mandoctype#check_duplicate"


  #mandocpriority
  get '/mandocpriority/index' => "mandocpriority#index"
  post '/mandocpriority/update' => "mandocpriority#update"
  delete '/mandocpriority/del' => "mandocpriority#del"
  get '/mandocpriority/del' => "mandocpriority#del"
  get '/mandocpriority/check_duplicate' => "mandocpriority#check_duplicate"


  post '/mandocs/process/upload' => "mandocs#mandocfile_upload_mediafile"
  delete '/mandocs/process/del' => "mandocs#delete_mandocfile"
  get '/mandocs/process/del' => "mandocs#delete_mandocfile"
  get '/mandocpriority/get_all' => "mandocpriority#get_all"

  #test
  get '/mandoc_outgoing/outgoing_index' => "mandoc_outgoing#outgoing_index"
  post '/mandoc_outgoing/outgoing_update' => "mandoc_outgoing#outgoing_update"

  #mandocfroms
  get '/mandocfroms/index' => "mandocfroms#index"
  post '/mandocfroms/update' => "mandocfroms#update"
  delete '/mandocfroms/del' => "mandocfroms#del"
  get '/mandocfroms/del' => "mandocfroms#del"
  get '/mandocfroms/get_all' => "mandocfroms#get_all"
  get '/mandocfroms/check_duplicate' => "mandocfroms#check_duplicate"

  #Maintain update
  post '/maintain/update' => "maintain#update"

  #Iframe
  get '/user/iframe_user' => "users#iframe_user"

  resources :mandocs do
    member do
      put :update_read
      get :update_read
    end
  end


  #mandoc pending
  delete '/mandocs/destroy' => "mandocs#destroy" # Hai 27/2/2023
  get '/mandocs/destroy' => "mandocs#destroy"  # Hai 27/2/2023

  # Table Form (Dat 08/03/2023 )
  get '/forms/index' => "forms#index"
  post '/forms/update' => "forms#update"
  delete '/forms/del' => "forms#del"
  get '/forms/del' => "forms#del"

  #released mandoc
  get '/released_mandocs/incoming/index' => "released_mandocs#incoming_index"
  post '/released_mandocs/incoming_update' => "released_mandocs#incoming_update"
  post '/released_mandocs/outgoing_update' => "released_mandocs#outgoing_update"
  get '/released_mandocs/incoming/find_one' => "released_mandocs#find_one"
  post '/released_mandocs/import_mandoc' => "released_mandocs#import_mandoc"
  post '/released_mandocs/incoming/upload' => "released_mandocs#mandocfile_upload_mediafile"
  post '/released_mandocs/incoming/mandoc_save_mandocmedia' => "released_mandocs#mandoc_save_mandocmedia"
  delete '/released_mandocs/incoming/del' => "released_mandocs#delete_mandocfile"
  get '/released_mandocs/incoming/del' => "released_mandocs#delete_mandocfile"
  delete '/released_mandocs/outgoing/del_mandoc_release_out' => "released_mandocs#del_mandoc_release_out"
  post '/released_mandocs/upload_file_tinymce' => "released_mandocs#upload_file_tinymce"



  resources :released_mandocs do
    collection do
      get 'get_users_by_department'
    end
  end


  get '/released_mandocs/outgoing/index' => "released_mandocs#outgoing_index"
  post '/released_mandocs/import_mandoc_out' => "released_mandocs#import_mandoc_out"
  post '/released_mandocs/outgoing/upload' => "released_mandocs#mandocfile_upload_mediafile"
  post '/released_mandocs/outgoing/upload_new' => "released_mandocs#mandocfile_upload_mediafile_new"
  get '/released_mandocs/outgoing/find_one' => "released_mandocs#find_one"
  post '/released_mandocs/outgoing/mandoc_save_mandocmedia' => "released_mandocs#mandoc_save_mandocmedia"
  post '/released_mandocs/remove_mediafile' => "released_mandocs#remove_mediafile"
  delete '/released_mandocs/outgoing/del' => "released_mandocs#delete_mandocfile_out"
  get '/released_mandocs/outgoing/del' => "released_mandocs#delete_mandocfile_out"

  # Account History
  get '/acchists/index' => "acchists#index"

  # operstream
  get '/operstream/index' => "operstream#index"
  post '/operstream/update' => "operstream#update_operstream"
  get '/organizations', to: 'operstream#organizations'
  get '/streams', to: 'operstream#streams'
  post '/operstream/get_operlist' => "operstream#get_operlist"
  get '/operstream/delete' => "operstream#delete"
  delete '/operstream/delete' => "operstream#delete"
  post '/check_operstream_exists', to: 'operstream#check_exists'
  get '/operstream/get_all_functions' => "operstream#get_all_functions"
  get '/operstream/get_all_organizations' => "operstream#get_all_organizations"
  get '/operstream/get_all_streams' => "operstream#get_all_streams"

  get '/calendar/index' => "calendar#index"

  # released notes (Thai 02/06/2023)
  get 'releasednotes/index' => 'releasednotes#index'
  post 'releasednotes/update' => 'releasednotes#update'

  # H-anh 13/09/2023
  get 'documents/index' => "documents#index"
  get 'documents/history' => "documents#history"
  get 'documents/history' => "documents#history"
  get 'documents/erp' => "documents#erp"

  post 'documents/check_app' => "documents#check_app"
  post 'documents/update' => "documents#update"
  delete 'documents/del' => "documents#del"
  get 'documents/del' => "documents#del"

  get 'tools/edit_word' => "tools#edit_word"
  get 'tools/spreadsheet' => "tools#spreadsheet"

  # test automation
  get 'test_auto/index' => "test_auto#index"
  post 'test_auto/run_tests' => "test_auto#run_tests"

  # Dat survey
  get 'survey/index' => "survey#index"
  get 'survey/detail' => "survey#detail"
  post 'survey/update_survey' => "survey#update_survey"
  post 'survey/update_detail' => "survey#update_detail"
  get 'survey/del' => "survey#del"
  delete 'survey/del' => "survey#del"
  get 'survey/answer/:appointsurvey_id', to: 'survey#answer', as: :survey_answer
  post 'survey/load_survey', to: 'survey#load_survey'
  get 'survey/load_assign_survey', to: 'survey#load_assign_survey'
  post 'survey/submit_answer', to: 'survey#submit_answer'
  post 'survey/submit_all_answers', to: 'survey#submit_all_answers'
  get 'survey/assign_survey' => 'survey#assign_survey', as: :assign_survey # Hiển thị view index
  post 'survey/publish_survey' => 'survey#publish_survey' # Xử lý submit



  # Dat survey
  get 'gsurveys/index' => "gsurveys#index"
  post 'gsurveys/update' => "gsurveys#update"
  get 'gsurveys/del' => "gsurveys#del"
  delete 'gsurveys/del' => "gsurveys#del"

  # Khoa Nguyen
  resources :appointments do
    member do
      patch 'approve'
      patch 'reject'
      patch 'set_probation'
      patch 'next_step'
      patch 'previous_step'
      patch 'go_to_step'
      get 'load_signdoc'
    end
    
    collection do
      get 'pending_approvals'
      get 'by_step/:step', to: 'appointments#by_step', as: 'by_step'
      get 'render_form/:status', to: 'appointments#render_form', as: 'render_form'
      get 'get_priorities', to: 'appointments#get_priorities', as: 'get_priorities'
      get 'get_departments', to: 'appointments#get_departments', as: 'get_departments'
      get 'get_positions', to: 'appointments#get_positions', as: 'get_positions'
      get 'get_user_positions', to: 'appointments#get_user_positions', as: 'get_user_positions'
      get 'get_users', to: 'appointments#get_users', as: 'get_users'
      get 'get_managers', to: 'appointments#get_managers', as: 'get_managers'
      post 'update_appointment', to: 'proposal_creations#update_appointment'
      post 'assign_submit', to: 'proposal_creations#assign_submit'
    end

    resources :proposal_creations, only: [:index, :new, :create, :edit, :update] do
      collection do
        post :proposal_submit
        post :department_approval_submit
      end
    end

    resources :evaluation_summary do
      collection do
        get :detail 
        get :export_summary_report
      end
    end
  end
  get 'works/index' => "works#index"
  post 'works/index' => "works#index"
  post 'works/update_users_into_work' => "works#update_users_into_work"
  delete 'works/delete' => 'works#delete'

  resources :tfunctions
  resources :dueties
  resources :gtasks do
    member do
      get 'assign_stasks'
      patch 'update_stasks'
      patch 'unassign_stask'
    end
  end
  resources :tasks do
    collection do
      get 'get_duties'
      get 'get_functions'
    end
  end

  resources :subdepartments do
    member do
      get 'assign_users'
      patch 'update_users'
      patch 'unassign_user'
      get :users
    end
    collection do
      get 'get_users', to: 'subdepartments#get_users', as: 'get_users'
    end
  end

  # sign document
  get 'sign_document/load_signdoc' => 'sign_document#load_signdoc'
  post 'sign_document/update_sign' => 'sign_document#update_sign'
  get 'sign_document/get_user_sign' => 'sign_document#get_user_sign'
  get 'sign_document/check_sign_exits' => 'sign_document#check_sign_exits'

  # H.anh + Thái + Huy
  get 'leave_request/index' => "leave_request#index"
  get 'leave_request/history' => "leave_request#history"
  get 'leave_request/position_leave' => "leave_request#position_leave"
  get 'leave_request/dates_leaved', to: 'leave_request#dates_leaved'
  get 'leave_request/generated_leave_request', to: 'leave_request#generated_leave_request'
  get 'leave_request/get_users_on_leave', to: 'leave_request#get_users_on_leave'
  get 'leave_request/get_days_leave', to: 'leave_request#get_days_leave'

  get 'leave_request/staff_leave' => "leave_request#staff_leave"
  get 'leave_request/export_excel', to: 'leave_request#export_excel'
  get 'leave_request/datas_leave_request' => "leave_request#datas_leave_request"
  get 'leave_request/check_urgent_leave' => "leave_request#check_urgent_leave"
  get 'leave_request/fetchStaffForWorkflow' => "leave_request#fetchStaffForWorkflow"
  get 'leave_request/process_handle' => 'leave_request#process_handle'
  post 'leave_request/import_excel', to: 'leave_request#import_excel', as: 'import_excel_leave_request'
  post 'leave_request/update_leave_days', to: 'leave_request#update_leave_days', as: 'update_leave_days'
  post 'leave_request/handle_register_leave_request' => 'leave_request#handle_register_leave_request'
  delete 'leave_request/delete_leave_request' => 'leave_request#delete_leave_request'
  delete 'leave_request/delete_detail' => 'leave_request#delete_detail'
  post 'leave_request/cancel_leave_request' => 'leave_request#cancel_leave_request'

  get 'manager_leave/staff_leave' => "manager_leave#staff_leave"
  get 'manager_leave/export_excel', to: 'manager_leave#export_excel'
  post 'manager_leave/import_excel', to: 'manager_leave#import_excel', as: 'import_excel_manager_leave'

  get 'manager_leave/history' => "manager_leave#history"
  get 'manager_leave/position_leave', to: 'manager_leave#position_leave'
  post 'manager_leave/save_all_leave_data', to: 'manager_leave#save_all_leave_data', as: :save_all_leave_data
  post 'manager_leave/update_leave', to: 'manager_leave#update_leave', as: :update_leave
  post 'manager_leave/create_leave', to: 'manager_leave#create_leave', as: :create_leave

  get 'manager_leave/management' => "manager_leave#management"

  get 'manager_leave/seniority' => "manager_leave#seniority"
  get 'manager_leave/management' => "manager_leave#management"

  get 'manager_leave/insurance_handover' => "manager_leave#insurance_handover"

  get 'manager_leave/holprosdetails', to: 'manager_leave#holprosdetails', as: 'manager_leave_holprosdetails'
  get 'manager_leave/get_user_handle', to: 'manager_leave#get_user_handle', as: 'manager_leave_get_user_handle'
  post 'manager_leave/refuse_leave', to: 'manager_leave#refuse_leave', as: 'manager_leave_refuse_leave'
  post 'manager_leave/handle_leave', to: 'manager_leave#handle_leave', as: 'manager_leave_handle_leave'
  post 'manager_leave/approve_leave', to: 'manager_leave#approve_leave', as: 'manager_leave_approve_leave'
  post "manager_leave/submit_leave_changes", to: "manager_leave#submit_leave_changes", as: 'manager_leave_change'
  post "manager_leave/process_leave_action", to: "manager_leave#process_leave_action", as: 'manager_leave_action'
  get "manager_leave/holiday_2026_preview", to: "manager_leave#export_holiday_2026_preview", as: :manager_leave_holiday_2026_preview
  get "manager_leave/review_ton", to: "manager_leave#review_ton", as: :manager_leave_review_ton

  #Q.HAI 08/05/2025
  # holiday BMU
  get '/setting_holidays/index' => "setting_holidays#index"
  post '/setting_holidays/update_holiday_detail' => "setting_holidays#update_holiday_detail"
  
  get '/setting_holidays/manager_holiday' => "setting_holidays#manager_holiday"
  get '/setting_holidays/details' => "setting_holidays#details"
  
  get '/manager_leave/manager_holiday' => "manager_leave#manager_holiday"

  get '/manager_leave/export_holiday' => 'manager_leave#export_holiday'
  get 'manager_leave/generated_leave_request', to: 'manager_leave#generated_leave_request'

  # Setting holidays
  # Lấy mẫu import
  get '/setting_holidays/download_template_bmu' => "setting_holidays#download_template_bmu"
  get '/setting_holidays/download_template_buh' => "setting_holidays#download_template_buh"

  # Action import
  post '/setting_holidays/update_imports' => "setting_holidays#update_imports"

  # Xuất báo cáo theo các loại biểu mẫu 29/7/2025
  # Báo cáo theo năm
  get '/setting_holidays/export_data_holiday_year' => 'setting_holidays#export_data_holiday_year'
  # Bảng chấm công
  get '/setting_holidays/export_data_timesheet' => 'setting_holidays#export_data_timesheet'
  # Theo tháng
  get '/setting_holidays/export_data_holiday_month' => 'setting_holidays#export_data_holiday_month'
  # Theo ngày
  get '/setting_holidays/export_data_holiday_date' => 'setting_holidays#export_data_holiday_date'
  # Theo nhân sự
  get '/setting_holidays/export_data_holiday_user' => 'setting_holidays#export_data_holiday_user'
  # Trong/Ngoài nước
  get '/setting_holidays/export_data_holiday_country' => 'setting_holidays#export_data_holiday_country'
  # Theo trạng thái đơn
  get '/setting_holidays/export_data_holiday_status' => 'setting_holidays#export_data_holiday_status'
  get 'holtypes/details_holtype', to: 'holtypes#details_holtype', as: :details_holtype_holtypes
  post 'holtypes/save_holtype', to: 'holtypes#save_holtype'


  resources :holtemps, only: [:index, :new,:create, :edit, :update, :destroy] do 
    collection do
    end
  end
  resources :holtypes, only: [:index, :new,:create, :edit, :update, :destroy] do 
    collection do
    end
  end
  mount Mapi::Root => '/api'

  # Chấm công nhân viên
  resources :attends, only: [:index] do
    collection do
      get :process_attend
      get :management
      get :get_process_attend
      get :get_attend_details
      post :save_attend_request
      get :get_data_request_attend
      get :fetch_all_attends_in_month
      get :get_image_evidence
      post :approve_request
      post :reject_request
      get :export_excel
      get :get_data_date_attend
    end
  end
  # Ca làm việc
  get '/workshifts/index' => "workshifts#index"
  post '/workshifts/update' => "workshifts#update"
  delete '/workshifts/destroy' => "workshifts#destroy"
  get '/workshifts/destroy' => "workshifts#destroy"
  get '/workshifts/get_all_workshifts' => "workshifts#get_all_workshifts"
  get '/workshifts/get_all_managers' => "workshifts#get_all_managers"
  get '/workshifts/room_configuration' => "workshifts#room_configuration"
  get '/workshifts/get_all_users' => 'workshifts#get_all_users'
  patch '/workshifts/:id/update_sroom_users' => 'workshifts#update_sroom_users'
  get '/workshifts/get_shiftselection_detail' => 'workshifts#get_shiftselection_detail'
  post '/workshifts/update_attend' => 'workshifts#update_attend'
  get '/workshifts/export_excel' => 'workshifts#export_excel'
  get '/scheduleweeks/get_scheduleweeks' => "scheduleweeks#get_scheduleweeks"
  post '/scheduleweeks/save_scheduleweeks' => "scheduleweeks#save_scheduleweeks"
  get '/shiftselections/process_workshifts' => "shiftselections#process_workshifts"
  get '/shiftselections/get_workshifts' => "shiftselections#get_workshifts"
  post '/shiftselections/update_shiflselections' => "shiftselections#update_shiflselections"
  post '/user/upload_image' => "users#upload_image"
  get '/shiftselections/process_workshifts_of_departments' => "shiftselections#process_workshifts_of_departments"
  get '/shiftselections/get_workshifts_of_department' => "shiftselections#get_workshifts_of_department"


  # Duyệt ca
  post 'shiftissues/update_shiftissue' => "shiftissues#update_shiftissue"
  
  # Xuất excel data user (dat 23/07/2025)
  get 'export_user_data/export_excel', to: 'export_user_data#export_excel'

  #msettings (Thai 08/08/2025)
  Rails.application.routes.draw do
    resources :msettings, only: [:index, :new, :edit, :create, :update, :destroy] do
      collection do
        get :list          # /msettings/list -> trả partial bảng
        get :get_settings  # /msettings/get_settings -> action tùy chỉnh
      end
    end
  end
 


  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
  get '/dev_errors', to: 'dev_errors#index'
  # match '*unmatched', to: 'application#not_found_method', via: :all
end
