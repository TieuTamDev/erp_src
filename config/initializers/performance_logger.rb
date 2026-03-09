ActiveSupport::Notifications.subscribe "process_action.action_controller" do |name, start, finish, id, payload|
  controller_name = payload[:controller]
  action_name = payload[:action]
  session = payload[:session]
  path = payload[:path]

  if !controller_name.nil? &&
    controller_name&.strip() != "" &&
    controller_name != "DevErrorsController" && 
    action_name != "not_found_method" &&
    action_name != "handle_standard_error"

    # Mylog.create({
    #   userid: session["user_id"],
    #   user_name: session["user_fullname"],
    #   user_email: session["user_email_login"],
    #   spath: path,
    #   saction_name: "#{controller_name}##{action_name}",
    #   dtstart: start,
    #   dtend: finish,
    #   note: (finish - start).abs,
    # })
    
  end
end