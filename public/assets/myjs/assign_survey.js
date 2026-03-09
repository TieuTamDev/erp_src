document.addEventListener("DOMContentLoaded", function () {
    // Style hiện có
    const style = document.createElement('style');
    style.innerHTML = `
      .card .row {
        align-items: center;
      }
      .date-picker-container {
        display: flex;
        align-items: center;
        gap: 15px;
      }
      .date-picker-item {
        display: flex;
        align-items: center;
      }
      .date-picker-item label {
        min-width: 120px;
        margin-bottom: 0;
      }
      .date-picker-item input {
        width: 150px;
      }
    `;
    document.head.appendChild(style);

    let select_department = $("#departments").select2({
      dropdownParent: $('#publish-modal'),
      placeholder: "Chọn phòng ban ...",
      width: '100%',
      allowClear: true,
      minimumResultsForSearch: 1,
      templateSelection: function (data) {
        return data.text;
      }
    });
    select_department.trigger('change');

    let select_user = $("#users").select2({
      dropdownParent: $('#publish-modal'),
      placeholder: "Chọn nhân sự ...",
      width: '100%',
      allowClear: true,
      minimumResultsForSearch: 1,
      templateSelection: function (data) {
        return data.text;
      }
    });
    select_user.trigger('change');

  
    // Sự kiện nút "Xuất bản" để mở modal
    const publishBtn = document.getElementById('publish-btn');
    if (publishBtn) {
      publishBtn.addEventListener('click', function () {
        $('#publish-modal').modal('show');
      });
    }
  
    // Sự kiện nút "Đồng ý" trong modal
    const confirmPublishBtn = document.getElementById('confirm-publish');
    if (confirmPublishBtn) {
      confirmPublishBtn.addEventListener('click', publishSurvey);
    }

    function loadSurvey(surveyId) {
      if (!surveyId) {
        document.querySelector('.survey-preview').innerHTML = '<p>Chọn một khảo sát để xem chi tiết.</p>';
        return;
      }
      showLoadding(true);
      fetch(`${root_path}survey/load_assign_survey?survey_id=${surveyId}`, {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        }
      })
      .then(response => response.json())
      .then(data => {
        showLoadding(false);
        if (data.success) {
          const surveyData = data.survey_data;
          let html = ``;
          surveyData.groups.forEach((group, index) => {
            html += `
              <div style="background:#5797EA; width: 100px; color: #333333; padding: 10px; align-items: center; display: flex; border-radius: 10px 10px 0px 0px; justify-content: center;">
                Phần ${index + 1}/${surveyData.groups.length}
              </div>
              <div class="mb-4 group-section card card-body">
                <h5 class="mb-3">${group.name || 'Nhóm câu hỏi'}</h5>
                <div class="row mb-3">
                  <div class="col-6"></div>
                  <div class="col-6 options-shared" style="display: flex; justify-content: space-between; align-items: center; height: 40px;">
                    ${group.options.map(option => `
                      <div class="form-check form-check-inline" style="margin: 0; text-align: center; flex: 1;">
                        <label class="form-check-label">${option.content}</label>
                      </div>
                    `).join('')}
                  </div>
                </div>
                <div class="questions-container" id="group-${group.id}">
                  ${group.questions.map(question => `
                    <div class="card mb-3 p-3" style="background: #F4F7F8;">
                      <div class="row" style="align-items: center;">
                        <div class="col-6">
                          <p class="mb-0">${question.content}</p>
                        </div>
                        <div class="col-6 options-container" style="display: flex; justify-content: space-between; align-items: center; height: 40px; padding-left: 15px;">
                          ${question.option_ids.map(option_id => `
                            <div class="form-check-inline" style="margin: 0; text-align: center; flex: 1;">
                              <input class="form-check-input" type="radio" name="question-${question.id}" value="${option_id}" id="option-${option_id}"
                                style="border: 1px solid #5272E9; margin-left: 40px; margin-top: 0; pointer-events: none;" disabled>
                            </div>
                          `).join('')}
                        </div>
                      </div>
                    </div>
                  `).join('')}
                </div>
                <div class="mt-3">
                  <label for="note-${group.id}" class="form-label">Ý kiến khác:</label>
                  <textarea class="form-control" id="note-${group.id}" rows="3" placeholder="Nhập ý kiến của bạn (nếu có)" readonly></textarea>
                </div>
              </div>
            `;
          });
          document.querySelector('.survey-preview').innerHTML = html;
        } else {
          document.querySelector('.survey-preview').innerHTML = '<p>Có lỗi xảy ra khi tải khảo sát.</p>';
        }
      })
      .catch(error => {
        console.error('Load survey error:', error);
        document.querySelector('.survey-preview').innerHTML = '<p>Có lỗi xảy ra khi tải khảo sát.</p>';
      });
    }
  
    // Load khảo sát khi trang load (nếu có survey_id mặc định)
    const surveySelect = document.getElementById('survey_select');
    if (surveySelect) {
      loadSurvey(surveySelect.value); // Load khảo sát đầu tiên nếu có
    }
  
    // Load khảo sát khi select thay đổi
    surveySelect.addEventListener('change', function () {
      loadSurvey(this.value);
    });


    const startDateInput = document.getElementById('start-date');
    const endDateInput = document.getElementById('end-date');
    const errorMessage = document.getElementById('date-error');

    // Ngày hôm nay
    const today = new Date();
    today.setHours(0, 0, 0, 0); // Đặt giờ về 0 để so sánh chính xác ngày

    // Hàm hiển thị thông báo lỗi
    function showError(message) {
      errorMessage.textContent = message;
      errorMessage.style.display = 'block';
      $('#btn-publish-modal').prop('disabled', true);
    }

    [startDateInput, endDateInput].forEach(input => {
      input.onkeydown = function (event) {
        event.preventDefault(); // Ngăn nhập phím
      };
      input.onpaste = function (event) {
        event.preventDefault(); // Ngăn paste
      };
    });

    // Hàm ẩn thông báo lỗi
    function clearError() {
      errorMessage.textContent = '';
      errorMessage.style.display = 'none';
      $('#btn-publish-modal').prop('disabled', false);
    }

    // Validation cho start-date
    startDateInput.addEventListener('change', function () {
      const startDate = new Date(startDateInput.value);
      startDate.setHours(0, 0, 0, 0);

      // Kiểm tra start-date >= today
      if (startDate < today) {
        showError('Ngày bắt đầu phải lớn hơn hoặc bằng ngày hôm nay.');
        startDateInput.value = today.toISOString().split('T')[0]; // Reset về ngày hôm nay
        return;
      }

      // Kiểm tra end-date >= start-date
      const endDate = new Date(endDateInput.value);
      endDate.setHours(0, 0, 0, 0);
      if (endDate < startDate) {
        showError('Ngày kết thúc phải lớn hơn hoặc bằng ngày bắt đầu.');
        return;
      }

      clearError();
    });

    // Validation cho end-date
    endDateInput.addEventListener('change', function () {
      const startDate = new Date(startDateInput.value);
      startDate.setHours(0, 0, 0, 0);
      const endDate = new Date(endDateInput.value);
      endDate.setHours(0, 0, 0, 0);

      // Kiểm tra end-date >= start-date
      if (endDate < startDate) {
        showError('Ngày kết thúc phải lớn hơn hoặc bằng ngày bắt đầu.');
        return;
      }

      clearError();
    });
});
  
  function publishSurvey() {
    const appointmentsId = document.getElementById('appointments-id').value;
    const startDate = document.getElementById('start-date').value;
    const endDate = document.getElementById('end-date').value;
    const survey_id = $('#survey_select').val() ;
    const mandocuhandle_id = $('#mandocuhandle_id').val() ;
    const departments = $('#departments').val() || [];
    const users = $('#users').val() || [];
  
    if (!startDate || !endDate || (departments.length === 0 && users.length === 0)) {
      alert('Vui lòng nhập đầy đủ thời hạn đánh giá và chọn ít nhất một phòng ban hoặc nhân sự!');
      return;
    }
    showLoadding(true);
    fetch(root_path + 'survey/publish_survey', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({
        appointments_id: appointmentsId,
        start_date: startDate,
        end_date: endDate,
        departments: departments,
        users: users,
        survey_id: survey_id,
        mandocuhandle_id: mandocuhandle_id
      })
    })
    .then(response => response.json())
    .then(data => {
      showLoadding(false);
      if (data.success) {
        alert('Đã xuất bản khảo sát thành công!');
        $('#publish-modal').modal('hide');
        $(document).ready(function() {
        window.location.replace(appointment_path);
      });
      } else {
        alert('Lỗi: ' + (data.errors || 'Không thể xuất bản'));
      }
    })
    .catch(error => {
      console.error('Publish error:', error);
      alert('Có lỗi xảy ra khi xuất bản!');
    });
  }