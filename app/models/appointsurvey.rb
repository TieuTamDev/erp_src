class Appointsurvey < ApplicationRecord
  belongs_to :appointment
  belongs_to :user
  has_many :surveyrecords , dependent: :destroy

  # Chức năng: Lấy thông tin tổng hợp về phiếu khảo sát, bao gồm tổng số, tham dự, vắng mặt, duyệt, từ chối, chưa xử lý và phần trăm tham dự.
  # Người xây dựng: Lê Ngọc Huy
  # Đầu vào: Không có tham số trực tiếp, hàm sử dụng dữ liệu từ bảng appointsurveys và các bảng liên quan (users, works, positionjobs).
  # Ghi chú: Hàm trả về một mảng các hash chứa thông tin phân loại theo tên chức vụ (positionjob_name).
  def self.get_info_evaluation(positionjob_id = nil)
    appointsurveys = select("appointsurveys.*, positionjobs.name as positionjob_name, CONCAT(users.last_name,' ', users.first_name) as user_name, users.sid, users.id as user_id")
                      .joins(user: [works: :positionjob])

    appointsurveys = appointsurveys.where(positionjobs: {id: positionjob_id}) if positionjob_id.present?

    appointsurveys = appointsurveys.group('appointsurveys.id').group_by(&:positionjob_name)

    result = appointsurveys.each_with_object([]) do |(positionjob_name, surveys), arr|
      total = surveys.size
      attend = surveys.count(&:dtfinished)
      attend_ratio = ((attend.to_f / total) * 100).round

      arr << {
        positionjob_name: positionjob_name,
        total: total,
        attend: attend,
        attend_ratio: attend_ratio,
        approves: {
          total: surveys.count { |survey| survey.result == 'approved' },
          users: surveys.select { |survey| survey.result == 'approved' }.map {|s| { id: s.id, sid: s.sid, user_id: s.user_id, user_name: s.user_name, note: s.note }}
        },
        rejects: {
          total: surveys.count { |survey| survey.result == 'rejected' },
          users: surveys.select { |survey| survey.result == 'rejected' }.map {|s| { id: s.id, sid: s.sid, user_id: s.user_id, user_name: s.user_name , note: s.note }}
        },
        pendings: {
          total: total - attend,
          users: surveys.select { |survey| survey.dtfinished.nil? || survey.result.nil? }.map {|s| { id: s.id, sid: s.sid, user_id: s.user_id, user_name: s.user_name, note: s.note }}
        },
      }
    end
  end

  # Chức năng: Lấy danh sách tên các phòng ban (departments) liên quan đến các phiếu khảo sát, loại bỏ trùng lặp.
  # Người xây dựng: Lê Ngọc Huy
  # Đầu vào: Không có tham số trực tiếp, hàm sử dụng dữ liệu từ bảng appointsurveys và các bảng liên quan (users, works, positionjobs, departments).
  # Ghi chú: Hàm trả về một mảng các tên phòng ban duy nhất.
  def self.get_departments_name
    select("departments.name as department_name").joins(user: [works: [positionjob: :department]]).pluck('departments.name')&.uniq
  end

  # Chức năng: Đếm số lượng phòng ban đã hoàn thành khảo sát (tất cả phiếu có dtfinished) và trả về kết quả dạng "x/y".
  # Người xây dựng: Lê Ngọc Huy
  # Đầu vào: Không có tham số trực tiếp, hàm sử dụng dữ liệu từ bảng appointsurveys và các bảng liên quan (users, works, positionjobs, departments).
  # Ghi chú:
  #   - x: Số phòng ban mà tất cả phiếu khảo sát đã hoàn thành (dtfinished không nil).
  #   - y: Tổng số phòng ban.
  def self.count_departments_complete
    # Lấy dữ liệu từ query ban đầu và nhóm theo department_name
    appointsurveys = select("appointsurveys.*, departments.name as department_name")
      .joins(user: [works: [positionjob: :department]])
      .group_by(&:department_name)

    # Tổng số phòng ban
    total_departments = appointsurveys.keys.count

    # Đếm số phòng ban mà tất cả item có dtfinished khác nil
    departments_with_all_dtfinished = appointsurveys.count do |department_name, surveys|
      surveys.all? { |survey| survey.dtfinished.present? }
    end

    result = "#{departments_with_all_dtfinished}/#{total_departments}"
  end

  # Chức năng: Lấy danh sách tên các nhân sự (users) liên quan đến các phiếu khảo sát, loại bỏ trùng lặp.
  # Người xây dựng: Lê Ngọc Huy
  # Đầu vào: Không có tham số trực tiếp, hàm sử dụng dữ liệu từ bảng appointsurveys.
  # Ghi chú: Hàm trả về một mảng các tên nhân sự duy nhất.
  def self.get_users_name
    select("CONCAT(users.last_name, " ", users.first_name) as full_name").joins(:user).pluck("CONCAT(users.last_name, ' ', users.first_name)")&.uniq
  end

  # Chức năng: Đếm số lượng nhân sự đã hoàn thành khảo sát (tất cả phiếu có dtfinished) và trả về kết quả dạng "x/y".
  # Người xây dựng: Lê Ngọc Huy
  # Đầu vào: Không có tham số trực tiếp, hàm sử dụng dữ liệu từ bảng appointsurveys.
  # Ghi chú:
  #   - x: Số nhân sự mà tất cả phiếu khảo sát đã hoàn thành (dtfinished không nil).
  #   - y: Tổng số nhân sự.
  def self.count_users_complete
    # Lấy dữ liệu từ query ban đầu và nhóm theo full_name
    appointsurveys = select("appointsurveys.*, CONCAT(users.last_name,' ', users.first_name) as full_name")
      .joins(:user)
      .group_by(&:full_name)

    # Tổng số nhân sự
    total_users = appointsurveys.keys.count

    # Đếm số nhân sự mà tất cả item có dtfinished khác nil
    users_with_all_dtfinished = appointsurveys.count do |full_name, surveys|
      surveys.all? { |survey| survey.dtfinished.present? }
    end

    result = "#{users_with_all_dtfinished}/#{total_users}"
  end
end
