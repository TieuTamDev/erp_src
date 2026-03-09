# Khoa Nguyen - 2025/03/29
# Quản lý status của appointments
module AppointmentStatusManagement
    extend ActiveSupport::Concern

    included do
      # Biên của các steps

      STEPS = {
        1 => { name: 'Tạo đề xuất yêu cầu bổ nhiệm', status: 'created' },
        2 => { name: 'Bổ sung thông tin cá nhân bổ nhiệm', status: 'propose_creation' }, # Bổ sung thông tin cá nhân bổ nhiệm
        3 => { name: 'Duyệt đề xuất', status: 'department_propose' }, # Duyệt đề xuất
        4 => { name: 'Phê duyệt chủ trương', status: 'principal_propose' }, # duyệt chủ trương.
        5 => { name: 'Chỉ định nội dung đánh giá 360', status: 'evaluation_preparation' }, # Tạo khảo sát.
        6 => { name: 'Thực hiện đánh giá tín nhiệm', status: 'evaluation' }, # thực hiện khảo sát.
        7 => { name: 'Lập tờ trình bổ nhiệm', status: 'proposal_creation' }, # Lập tờ trình bổ nhiệm.
        8 => { name: 'Phê duyệt tờ trình', status: 'department_approval' }, # Duyệt tờ trình.
        9 => { name: 'Phê duyệt bổ nhiệm', status: 'principal_approval' } # Duyệt bổ nhiệm.
      }

      # STEPS = {
      #   1 => { name: 'Tạo đề xuất yêu cầu bổ nhiệm', status: 'created' },
      #   2 => { name: 'Lập tờ trình bổ nhiệm', status: 'proposal_creation' }, # Bổ sung thông tin cá nhân bổ nhiệm.
      #   3 => { name: 'Phê duyệt chủ trương', status: 'department_approval' }, # cấp trưởng.
      #   4 => { name: 'Phê duyệt chủ trương', status: 'principal_approval' }, # cấp ban giám hiệu / ban giám đốc.
      #   5 => { name: 'Chỉ định nội dung đánh giá 360', status: 'evaluation_preparation' },
      #   6 => { name: 'Thực hiện đánh giá tín nhiệm', status: 'evaluation' },
      #   7 => { name: 'Tổng hợp báo cáo', status: 'evaluation_summary' },
      #   # 7 Lập Tờ trình.
      #   # 8 Duyệt tờ trình cấp phòng. evaluation_summary.
      #   8 => { name: 'Phê duyệt', status: 'final_approval' } # evaluation_summary.
      # }

      # Kết quả trạng thái
      RESULTS = {
        created: 'Tạo mới',
        updated: 'Cập nhật',
        assign: 'Trình duyệt',
        pending: 'Chờ xử lý',
        approved: 'Phê duyệt',
        rejected: 'Từ chối',
        finished: 'Duyệt',
        stoped: 'Từ chối',
        probation: 'Thử thách',
      }.freeze

      #  buttons style
      RESULT_STYLES = {
        created: 'btn btn-primary',
        updated: 'btn btn-info',
        assign: 'btn btn-warning',
        pending: 'btn btn-warning',
        approved: 'btn btn-success',
        rejected: 'btn btn-danger',
        finished: 'btn btn-success',
        stoped: 'btn btn-danger',
        probation: 'btn btn-warning',
      }.freeze

      #  text color
      RESULT_COLORS = {
        created: 'badges-primary',
        updated: 'badges-info',
        assign: 'badges-warning',
        pending: 'badges-warning',
        approved: 'badges-success',
        rejected: 'badges-danger',
        finished: 'badges-success',
        stoped: 'badges-danger',
        probation: 'badges-warning',
      }.freeze

      STYPE = {
        BO_NHIEM: 'Bổ nhiệm',
        MIEN_NHIEM: 'Miễn nhiệm'
      }

      validates :status, inclusion: { in: STEPS.map { |_, step| step[:status] } }, allow_nil: true

      # Scope để tìm appointments theo trạng thái
      scope :at_step, ->(step_number) { where(status: STEPS[step_number][:status]) }

      # Scope đề tim appointments theo kết quả
      scope :with_result, ->(result) { where(result: result) }

      # Callback
      before_create :set_initial_status
    end

    # Get step hiện tại dựa vào status
    def current_step_number
      STEPS.find { |_, step| step[:status] == status }&.first
    end

    # Lấy thông tin bước hiện tại
    def current_step_info
      step_number = current_step_number
      step_number ? STEPS[step_number] : nil
    end

    def at_step?(step_number)
      current_step_number == step_number
    end

    # Chuyển sang bước tiếp theo
    def next_step!
      next_step_number = current_step_number + 1
      if STEPS.key?(next_step_number)
        update(status: STEPS[next_step_number][:status])
        true
      else
        false
      end
    end

    # Từ chối và quay lại bước trước
    def previous_step!
      prev_step_number = current_step_number - 1
      if STEPS.key?(prev_step_number)
        update(status: STEPS[prev_step_number][:status])
        true
      else
        false
      end
    end

    def go_to_step!(step_number)
      if STEPS.key?(step_number)
        update(status: STEPS[step_number][:status])
        true
      else
        false
      end
    end

    # Xử lý phê duyệt ở bước hiện tại
    def approve!
      case current_step_number
      when 2 # Trưởng đơn vị phê duyệt
        update(result: RESULTS[:approved])
        next_step!
      when 4 # Phê duyệt cấp phòng
        update(result: RESULTS[:approved])
        next_step!
      when 5 # Phê duyệt chủ trương từ ban giám hiệu
        update(result: RESULTS[:approved])
        next_step!
      when 10 # Phê duyệt cuối cùng
        update(result: RESULTS[:approved])
        next_step!
      else
        next_step!
      end
    end

    # Xử lý từ chối ở bước hiện tại
    def reject!
      case current_step_number
      when 2 # Trưởng đơn vị từ chối
        update(result: RESULTS[:rejected])
        go_to_step!(1) # Trả về người tạo đề xuất
      when 4 # Phòng TCHC từ chối
        update(result: RESULTS[:rejected])
        go_to_step!(3) # Trả về nhân viên TCHC
      when 5 # Ban giám hiệu từ chối
        update(result: RESULTS[:rejected])
        go_to_step!(4) # Trả về phòng TCHC
      when 10 # Từ chối ở bước phê duyệt cuối
        update(result: RESULTS[:rejected])
      else
        update(result: RESULTS[:rejected])
      end
    end

    def set_probation_period!(months)
      return false unless current_step_number == 10

      probation_end_date = Date.today + months.months
      update(
        result: RESULTS[:probation],
        note: [note, "Thử thách: #{months} tháng đến ngày #{probation_end_date.strftime('%d/%m/%Y')}"].compact.join("\n")
      )
      true
    end

    # Check if appointment is approved
    def approved?
      result == RESULTS[:approved]
    end

    # Check if appointment is rejected
    def rejected?
      result == RESULTS[:rejected]
    end

    # Check if appointment is pending
    def pending?
      result == RESULTS[:pending]
    end

    # Check if appointment is on probation
    def on_probation?
      result == RESULTS[:probation]
    end

    def status_text
      step_info = current_step_info
      return "Không xác định" unless step_info

      "Bước #{current_step_number}: #{step_info[:name]}"
    end

    # Get action cho bước hiện tại
    def available_actions
      case current_step_number
      when 1
        ["Gửi cho trưởng đơn vị"]
      when 2
        ["Phê duyệt", "Từ chối"]
      when 3
        ["Lập tờ trình", "Gửi cho trưởng phòng TCHC"]
      when 4
        ["Phê duyệt", "Từ chối"]
      when 5
        ["Phê duyệt", "Từ chối"]
      when 6
        ["Soạn thảo nội dung đánh giá", "Chỉ định người đánh giá"]
      when 7
        ["Thực hiện đánh giá"]
      when 8
        ["Tổng hợp thông tin đánh giá"]
      when 9
        ["Gửi báo cáo tín nhiệm"]
      when 10
        ["Phê duyệt", "Thử thách 3 tháng", "Thử thách 6 tháng", "Thử thách 1 năm", "Từ chối"]
      when 11
        ["Soạn thảo Quyết định"]
      when 12
        ["Ký duyệt"]
      when 13
        ["Ban hành"]
      when 14
        ["Đã lưu trữ"]
      else
        []
      end
    end

    private

    # Set trạng thái bạn đầu cho appointment
    def set_initial_status
      self.status ||= STEPS[1][:status]
      self.result ||= RESULTS[:created]
    end
end
