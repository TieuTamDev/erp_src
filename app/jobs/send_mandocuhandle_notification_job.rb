class SendMandocuhandleNotificationJob < ApplicationJob
  queue_as :default

  def perform(mandocuhandle_id)
    mandocuhandle = Mandocuhandle.includes(mandoc: :appointment).find_by(id: mandocuhandle_id)
    mandoc = mandocuhandle&.mandoc
    return unless mandoc && mandoc.appointment_id.present?

    # Tạo Notify
    notify = Notify.create(
      title: title_notification(mandoc),
      contents: content_notification(mandoc, mandocuhandle),
      receivers: "Hệ thống ERP",
      stype: stype_notification(mandoc)
    )

    return unless notify
    Snotice.create(
      notify_id: notify.id,
      user_id: mandocuhandle.user_id,
      isread: false,
      username: id_handle(mandoc)
    )
  end

  private

  def title_notification(mandoc)
    case
    when mandoc.appointment_id.present? then I18n.t("appointment.#{mandoc.appointment.stype}", default: mandoc.appointment.stype).capitalize
    else "Văn bản"
    end
  end

  def stype_notification(mandoc)
    case
    when mandoc.appointment_id.present? then mandoc.appointment.stype
    else "MANDOC"
    end
  end

  def content_notification(mandoc, mandocuhandle)
    if mandoc.appointment&.title
      "#{mandoc.appointment.title} đã tới bước #{I18n.t("appointment.status.#{mandocuhandle.status}", default: mandocuhandle.status)}. Thầy/Cô vui lòng xử lý bước tiếp theo"
    elsif mandoc.contents
      mandoc.contents
    else
      mandoc.notes
    end
  end

  def id_handle(mandoc)
    case
    when mandoc.appointment_id.present? then mandoc.appointment_id
    else mandoc.id
    end
  end
end
