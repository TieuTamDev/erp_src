$(document).ready(function () {
  function setDefaultValue(selectId, url, formatItem) {
    $.ajax({
      url: url,
      type: "GET",
      data: { page: 1 },
      success: function (data) {
        if (data.items.length > 0) {
          let selectedItem = null;
          selectedItem = selectedItem || data.items[0];
  
          let displayText = formatItem ? formatItem(selectedItem) : selectedItem.name;
          let newOption = new Option(displayText, selectedItem.id, true, true);
          $(selectId).append(newOption).trigger('change');
        }
      },
      error: function (xhr, status, error) {
      }
    });
  };
  
  $("#department").on("change", function () {
    let departmentId = $(this).val();
  
    if (departmentId) {
      // Thêm biến flag để đánh dấu đang reset
      window.isResetting = true;

      // Xóa tất cả các option hiện tại và reset placeholder
      $('#position').val(null).empty().trigger('change');
      $('#appointee').val(null).empty().trigger('change');
      
      // Xóa thông báo lỗi nếu có
      toggleError($('#position'), true, '');
      toggleError($('#appointee'), true, '');
      
      // Reset flag
      window.isResetting = false;
    }
  });

  $("#appointee").on("change",()=>{
    if(apoint_stype == "MIEN_NHIEM"){
        $('#position').val(null).empty().trigger('change');
    }
  });

  $('#department, #appointee, #position').select2({
    width: '100%',
    placeholder: "Vui lòng chọn...",
    allowClear: true
  });

  $('#appointee, #position, #department, #priority, #manager').on('change', function() {
    const $this = $(this);
    if ($this.val()) {
      toggleError($this, true, '');
    }
  });

  $('#expected_appointment_date').on('change', function() {
    if ($(this).val()) {
      toggleError($(this), true, '');
    }
  });

  // Hàm validate input
  function validateField(field, value) {
    const validations = {
        priority: () => value && value !== '',
        new_dept: () => value && value !== '',
        user_id: () => value && value !== '',
        new_position: () => value && value !== '',
        user_handle_id: () => value && value !== ''
    };

    return validations[field] ? validations[field]() : true;
  }

  // Hàm hiển thị/thu gọn lỗi
  function toggleError(input, isValid, message) {
    const $input = $(input);
    const $parent = $input.closest('.mb-3');
    const $select2Container = $parent.find('.select2-container');

    $parent.find('.error-container').remove();
    if (!isValid) {
        if ($select2Container.length > 0) {
            $select2Container.after(`<div class="error-container"><div class="invalid-feedback d-block">${message}</div></div>`);
            $input.addClass('is-invalid');
            $select2Container.addClass('is-invalid');
        } else {
            $input.after(`<div class="error-container"><div class="invalid-feedback d-block">${message}</div></div>`);
            $input.addClass('is-invalid');
        }
    } else {
        $input.removeClass('is-invalid');
        if ($select2Container.length > 0) {
            $select2Container.removeClass('is-invalid');
        }
    }
  }

  $('#submitAppointment input, #submitAppointment select').on('focus', function() {
    $(this).addClass('was-touched');
  });

  // Xử lý validate
  $('#submitAppointment input, #submitAppointment select').on('input change', function() {
    const $this = $(this);
    if (!$this.hasClass('was-touched')) return;
    const fieldName = $this.attr('name');
    const value = $this.val();

    let isValid, errorMessage;
    switch(fieldName) {
        case 'priority':
            isValid = validateField('priority', value);
            errorMessage = 'Vui lòng chọn độ khẩn';
            break;
        case 'new_dept':
            isValid = validateField('new_dept', value);
            errorMessage = 'Vui lòng chọn đơn vị';
            break;
        case 'user_id':
            isValid = validateField('user_id', value);
            errorMessage = `Vui lòng chọn cá nhân ${stypeText}`;
            break;
        case 'new_position':
            isValid = validateField('new_position', value);
            errorMessage = 'Vui lòng chọn vị trí';
            break;
        case 'user_handle_id':
            isValid = validateField('user_handle_id', value);
            errorMessage = 'Vui lòng chọn người xử lý';
            break;
        case 'expected_appointment_date':
          isValid = validateField('expected_appointment_date', value);
          errorMessage = 'Vui lòng chọn thời gian dự kiến';
          break;
        default:
          isValid = true;
    }

    toggleError(this, isValid, errorMessage);
  });

  // Xử lý submit
  window.clickSubmitAppointProcess = function(status, results, next_department_id, next_department_scode) {
    const $form = $('#submitAppointment');
    const $appointeeName = $('#appointee option:selected').text();
    const $positionName = $('#position option:selected').text();
    const $departmentName = $('#department option:selected').text();
    const $button = document.querySelector('button.created');
    const originalText = $button.innerHTML;
  
    $('#appointee_name').val($appointeeName);
    $('#position_name').val($positionName);
    $('#department_name').val($departmentName);
  
    if (!validateForm()) {
      return false;
    }
  
    // Disable và đổi nội dung nút
    $button.disabled = true;
    $button.innerHTML = `<span class="spinner-border spinner-border-sm me-1" role="status" aria-hidden="true"></span>Đang xử lý...`;
  
    showLoading(true);
  
    const csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content');
  
    fetch($form.attr('action'), {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'X-Requested-With': 'XMLHttpRequest',
        'X-CSRF-Token': csrfToken
      },
      body: new URLSearchParams($form.serialize())
    })
    .then(response => {
      if (!response.ok) {
        throw new Error('Lỗi mạng hoặc máy chủ');
      }
      return response.json();
    })
    .then(data => {
      showLoading(false);
      if (data.success) {
        showFlash('success', data.message);
        setTimeout(() => {
          window.location = data.redirect_url || window.location.href;
        }, 1000);
      } else {
        showFlash('danger', Array.isArray(data.errors) ? data.errors.join(', ') : data.errors);
        $button.disabled = false;
        $button.innerHTML = originalText;
      }
    })
    .catch(error => {
      showLoading(false);
      showFlash('danger', 'Đã xảy ra lỗi khi xử lý yêu cầu');
      $button.disabled = false;
      $button.innerHTML = originalText;
    });
  
    return false;
  };  

  function validateForm() {
    const $form = $('#submitAppointment');
    let isValid = true;
    
    // Xóa tất cả thông báo lỗi cũ
    $form.find('.invalid-feedback').remove();
    $form.find('.error-container').remove();
    $form.find('.is-invalid').removeClass('is-invalid');
    $form.find('.select2-container').removeClass('is-invalid');

    let requiredFields = {
        'priority': 'Vui lòng chọn độ khẩn',
        'new_dept': 'Vui lòng chọn đơn vị',
        'user_id': `Vui lòng chọn cá nhân ${stypeText}`,
        'new_position': 'Vui lòng chọn vị trí',
        'user_handle_id': 'Vui lòng chọn người xử lý',
        'expected_appointment_date': `Vui lòng chọn thời gian dự kiến ${stypeText}`,
        'note': `Vui lòng nhập lý do`
    };

    if(apoint_stype == "MIEN_NHIEM"){
      delete requiredFields.expected_appointment_date;
    }

    Object.keys(requiredFields).forEach(fieldName => {
        const $field = $form.find(`[name="${fieldName}"]`);
        const value = $field.val();
        
        if (!value || value.trim() === '') {
            isValid = false;
            const errorMessage = requiredFields[fieldName];

            $field.addClass('is-invalid');

            if ($field.hasClass('select2-hidden-accessible')) {
                const $select2Container = $field.next('.select2-container');
                $select2Container.addClass('is-invalid');
                $select2Container.after(`<div class="error-container"><div class="fst-italic invalid-feedback d-block">${errorMessage}</div></div>`);
            } else {
                $field.after(`<div class="error-container"><div class="fst-italic invalid-feedback d-block">${errorMessage}</div></div>`);
            }
        }
    });
    
    return isValid;
  }

  $('#department').select2({
    theme: 'bootstrap-5',
    language: {
      searching: function () {
        return 'Đang tìm kiếm...';
      }
    },
    placeholder: 'Chọn đơn vị',
    ajax: {
      url: `${root_path}/appointments/get_departments`,
      data: function (params) {
        return {
          search: params.term
        };
      },
      processResults: function (data) {
        let results = data.items.map(function (item) {
          return { id: item.id, text: item.name };
        });

        return {
          results: results
        };
      }
    }
  });

  const newOption = new Option(currentDepartmentName, currentDepartmentId, true, true);
  $('#department').append(newOption).trigger('change');

  // position ajax
  $('#position').select2({
    theme: 'bootstrap-5',
    language: {
      searching: function () {
        return 'Đang tìm kiếm...';
      },
      loadingMore: function () {
        return 'Đang tải...';
      }
    },
    placeholder: `Chọn vị trí ${stypeText}`,
    ajax: {
        delay: 1000,
        url: function (params) {
            if(apoint_stype == "MIEN_NHIEM"){
                return `${root_path}/appointments/get_user_positions`;
            }else{

            }
            return `${root_path}/appointments/get_positions`;

        },
        data: function (params) {
            if(apoint_stype == "MIEN_NHIEM"){
                return {
                    department_id: $("#department").val(),
                    user_id: $("#appointee").val(),
                };
            }else{
                return {
                    search: params.term,
                    department_id: $("#department").val()
                };
            }
        },
        processResults: function (data) {
            let results = data.items.map(function (item) {
            let option = { id: item.id, text: item.name };
            if (editPositionId && item.id == editPositionId) {
                    option.selected = true;
                }
                return option;
            });

            return { results: results};
        }
    }
  });

  $('#position').on('select2:open', function (e) {
    $('#position').data('select2').results.clear();
  });

  $('#appointee').select2({
    theme: 'bootstrap-5',
    language: {
      searching: function () {
        return 'Đang tìm kiếm...';
      },
      loadingMore: function () {
        return 'Đang tải...';
      }
    },
    placeholder: `Chọn người đề xuất ${stypeText}`,
    ajax: {
      delay: 1000,
      url: `${root_path}/appointments/get_users`,
      data: function (params) {
        return {
          search: params.term,
          department_id: $("#department").val()
        };
      },
      processResults: function (data) {
        let results = data.items.map(function (item) {
          let option = { id: item.id, text: `${item.last_name} ${item.first_name} (${item.sid})` };
          if (editAppointeeId && item.id == editAppointeeId) {
            option.selected = true;
          }
          return option;
        });

        return {
          results: results
        };
      }
    }
  });

  $('#manager').select2({
    theme: 'bootstrap-5',
    language: {
      searching: function () {
        return 'Đang tìm kiếm...';
      },
      loadingMore: function () {
        return 'Đang tải...';
      }
    },
    placeholder: 'Chọn người xử lý',
    ajax: {
      delay: 1000,
      url: `${root_path}/appointments/get_managers`,
      data: function (params) {
        return {
          search: params.term,
          department_id: nextDepartmentId,
          department_head: true
        };
      },
      processResults: function (data) {
        let results = data.items.map(function (item) {
          let option = { id: item.id, text: `${item.last_name} ${item.first_name} (${item.sid})` };
          if (editManagerId && item.id == editManagerId) {
            option.selected = true;
          }
          return option;
        });

        return {
          results: results
        };
      }
    }
  });

  $('#priority').select2({
    theme: 'bootstrap-5',
    language: {
      searching: function () {
        return 'Đang tìm kiếm...';
      },
      loadingMore: function () {
        return 'Đang tải...';
      }
    },
    placeholder: 'Chọn độ khẩn',
    ajax: {
      delay: 1000,
      url: `${root_path}/appointments/get_priorities`,
      data: function (params) {
        return {
          search: params.term
        };
      },
      processResults: function (data) {
        let results = data.items.map(function (item) {
          let option = { id: item.scode, text: item.name };
          return option;
        });

        return {
          results: results
        };
      }
    }
  });
});

function showFlash(type, message) {
  let alertClass = type === 'success' ? 'alert-success' : 'alert-danger';
  let flashHtml = `
    <div class="alert_show alert ${alertClass} alert-dismissible fade show" role="alert">
      <span class="me-5">${message}</span>
      <button class="btn-close" type="button" data-bs-dismiss="alert" aria-label="Close"></button>
    </div>
  `;

  $('.alert_show').remove();
  $('body').prepend(flashHtml);

  setTimeout(function() {
    $(".alert_show").fadeOut();
  }, 5000);
}

function showLoading(bShow) {
  if(bShow) {
      $("#loading_handle").css("display", "flex");
  } else {
      $("#loading_handle").css("display", "none");
  }
};