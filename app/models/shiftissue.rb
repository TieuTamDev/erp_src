class Shiftissue < ApplicationRecord
  belongs_to :shiftselection

  #Xử lý trạng thái chuyển sang APPROVED
  after_update :process_compensatory_leave, if: :saved_change_to_status?

  private
  def process_compensatory_leave
    if stype == 'COMPENSATORY-LEAVE'
      ApplicationController.helpers.process_compensatory_leave(self, status)
    end
  end
end
