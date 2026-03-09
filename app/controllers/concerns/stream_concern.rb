module StreamConcern extend ActiveSupport::Concern

  def stream_connect_by_status(scode,status = nil,result = nil)
    connects = Connect.select("connects.forms,connects.status, connects.idenfity,de.scode as department_scode,de.name as department_name,de.id as department_id")
                      .joins(:stream)
                      .joins("LEFT JOIN departments as de ON de.id = connects.nend")
                      .where("streams.scode LIKE :scode", scode: "%#{scode}%")
                      # .joins("INNER JOIN operstreams ON operstreams.stream_id = streams.id")
                      # .where(operstreams: { organization_id: org_id})

    next_connects = nil
    if status.nil? || status.empty?
      next_connects = connects.select{|connect| connect&.idenfity&.include?("1-")}
    else
      next_connects = if result.nil?
                        connects.select{|connect| connect.status == status}
                      else
                        connects.select{|connect| connect.status == status && connect.idenfity.split("-")[1] == result}
                      end
    end
    next_connects.map do |connect|
      idenfity = connect.idenfity.split("-")
      step = idenfity[1] == "rejected" ? -1 : 1
      next_step = idenfity[0].to_i + step
      next_connect = connects.select{|connect| connect&.idenfity&.include?("#{next_step}-")}.first
      {
        forms: connect.forms,
        status: connect.status,
        result: idenfity[1],
        next_department_scode: connect.department_scode,
        next_department_name: connect.department_name,
        next_department_id: connect.department_id,
        next_status: next_connect&.status
      }
    end
  end

  def stream_last_connect(scode)
    Connect.select("connects.forms,connects.status, connects.idenfity,de.scode as department_scode,de.name as department_name,de.id as department_id")
    .joins(:stream)
    .joins("LEFT JOIN departments as de ON de.id = connects.nend")
    .where(streams:{scode: scode}).order("connects.idenfity DESC").first
    
  end



end