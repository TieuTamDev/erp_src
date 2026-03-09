$(document).ready(function () {
    // Xử lý lấy chi tiết chấm công trong ngày
    $('.attend-detail-btn').on('click', function (e) {
        showLoadding(true);
        e.preventDefault();
        const workdate = $(this).attr('data-workdate');
        $('#attendDetailsModalLabel').html('Chi tiết chấm công ngày ' + workdate)
        $('#attendDetailsModalLabel').attr("data-workdate", workdate);
        const ids = $(this).data('shiftselection-ids');
        $.ajax({
            type: 'GET',
            url: workshifts_get_shiftselection_detail_path,
            data: { ids: ids },
            dataType: 'JSON',
            success: function (response) {
                appendAttendData(response);
                showLoadding(false);
                $('#attendDetailsModal').modal('show');
            },
            error: function (xhr) {
                try {
                    const res = JSON.parse(xhr.responseText);
                    pushError(res);
                } catch (e) {
                    showAlert('Lỗi không xác định!', 'danger');
                }
            }
        });
    });

    // Xử lý show modal xuất thống kê
    $('#export-excel').on('click', function (e) {
        let modal = $('#exportModal');
        modal.modal('show');
    });

    // Khi chọn radio, hiển thị form input
    $('.export-type-radio').on('change', function () {
        $('#export-form-section').removeClass('d-none');
        const selected = $(this).val();
        if (selected === 'attends' || selected === 'detail_attends') {
            $('#export-filters-wrapper').removeClass('d-none');
            init_user_export_select();
        } else {
            $('#export-filters-wrapper').addClass('d-none');
        }
    });

    // Re-init user select khi đổi phòng ban
    $(document).on('change', '#department_select', function () {
        init_user_export_select();
    });

    $('#exportModal').on('shown.bs.modal', function () {
        init_user_export_select();
        init_department_select();
    });

    // Xử lý xuất báo cáo
    // @author: trong.lq
    // @date: 24/01/2026
    // Cập nhật logic xác định department_id: user có quyền EDIT dùng user_department_id_for_export (từ helper), fallback về session_department_id
    $('#export-btn').on('click', function () {
        const exportType = $('input[name="export_type"]:checked').val();
        if (!exportType) {
            showAlert('Vui lòng chọn loại báo cáo!', 'warning');
            return;
        }
        const year = $('#year_export_month_select').val();
        const month = $('#month_export_month_select').val();
        let department;
        if (permission_add_attend === "true" || permission_adm_attend === "true") {
            department = $('#department_select').val();
        } else if (permission_edit_attend === "true") {
            department = session_department_id;
        } else {
            department = $('#department_select').val(); // hoặc session_department_id tùy rule
        }

        const user_id = $('#user_export_select').val();

        $('#exportModal').modal('hide');

        let paramsData = {
            export_type: exportType,
            year: year,
            month: month
        };
        if (exportType === 'attends' || exportType === 'detail_attends') {
            paramsData.department_id = department;
            paramsData.user_id = user_id;
        }
        const params = $.param(paramsData);

        window.location.href = `${base_url_path}workshifts/export_excel?${params}`;
    });

    var attendanceSelectDate = $("#attendance_select_date");
    if (attendanceSelectDate.length > 0) {
        var dateVal = attendanceSelectDate.val();
        var range = attendanceSelectDate.attr('data-range');
        var start = range === 'date' ? moment() : moment().startOf('month');
        var end = range === 'date' ? moment() : moment().endOf('month');

        if (dateVal && dateVal.includes(" - ")) {
            var parts = dateVal.split(" - ");
            start = moment(parts[0], "DD/MM/YYYY");
            end = moment(parts[1], "DD/MM/YYYY");
        }

        attendanceSelectDate.daterangepicker({
            showDropdowns: true,
            alwaysShowCalendars: true,
            startDate: start,
            endDate: end,
            ranges: {
                'Hôm nay': [moment(), moment()],
                'Tháng này': [moment().startOf('month'), moment().endOf('month')],
                'Mọi lúc': [moment().subtract(100, 'year'), moment()]
            },
            locale: {
                direction: "ltr",
                format: 'DD/MM/YYYY',
                separator: " - ",
                applyLabel: "Xác nhận",
                cancelLabel: "Đóng",
                weekLabel: "W",
                customRangeLabel: "Tùy chọn",
                daysOfWeek: ["CN", "Hai", "Ba", "Tư", "Năm", "Sáu", "Bảy"],
                monthNames: ["T1", "T2", "T3", "T4", "T5", "T6", "T7", "T8", "T9", "T10", "T11", "T12"],
                firstDay: 1
            }
        });
    }

    function init_user_export_select() {
        const user_select = $("#user_export_select");
        const PER_PAGE = 10;

        // @author: trong.lq
        // @date: 24/01/2026
        // Xác định department_id: user có quyền EDIT dùng user_department_id_for_export (từ helper), fallback về session_department_id
        let department_id;
        if (permission_add_attend === "true" || permission_adm_attend === "true") {
            department_id = $('#department_select').val();
        } else if (permission_edit_attend === "true") {
            department_id = session_department_id;
        } else {
            department_id = $('#department_select').val(); // hoặc session_department_id tùy rule
        }

        if (user_select.data("select2")) {
            user_select.select2("destroy");
            user_select.empty();
        }

        const allOption = new Option("Tất cả", "", true, true);
        user_select.append(allOption);

        user_select.select2({
            placeholder: "Chọn nhân viên",
            theme: "bootstrap-5",
            width: "100%",
            allowClear: true,
            dropdownParent: $('#exportModal .modal-content'),
            ajax: {
                delay: 150,
                transport: function (params, success, failure) {
                    const term = params.data?.term || "";
                    const page = params.data?.page || 1;

                    $.ajax({
                        url: gon.erp_path_users_erp,
                        type: 'GET',
                        data: {
                            search: term || "",
                            page: page || 1,
                            per_page: PER_PAGE,
                            is_paginate: true,
                            department_id: department_id
                        }
                    }).then(success).catch(failure);
                },
                processResults: function (response, params) {
                    params.page = params.page || 1;
                    const rows = (response && response.datas) ? response.datas : [];
                    const results = rows.map(item => ({
                        id: item.id,
                        text: item.name,
                        avatar: item.avatar || null,
                        department_name: item.department_name,
                        positionjob_name: item.positionjob_name
                    }));

                    return {
                        results,
                        pagination: { more: !!response?.load_more }
                    };
                },
                cache: true
            },

            templateResult: (state) => {
                if (!state.id) return state.text;
                const position = state.positionjob_name ? ` (${state.positionjob_name})` : "";
                const department = state.department_name ? `<span class="d-block fs--1 text-600"><i>${state.department_name}</i></span>` : "";
                const $state = $(`
                  <span class="d-flex align-items-center">
                    <span>
                      <span><span class="fw-bold">${state.text || ""}</span>${position}</span>
                      ${department}
                    </span>
                  </span>
                `);
                return $state;
            },

            templateSelection: (state) => {
                if (!state || !state.id) return "Tất cả";
                return state.text || state.id;
            }
        });
    }

    function init_department_select() {
        const el = $('#department_select');
        if (!el.length) return;

        if (el.data('select2')) {
            el.select2('destroy');
        }
        el.select2({
            placeholder: "Tất cả phòng ban",
            theme: "bootstrap-5",
            width: "100%",
            allowClear: true,
            dropdownParent: $('#exportModal .modal-content')
        });
    }
});

$('#attendDetailsModal').off('hidden.bs.modal.att').on('hidden.bs.modal.att', function () {
    $('#detailAttends').empty();
    $('#detailShiftIssues').empty();
});

function appendAttendData(response) {
    /* header   ───────────────────────── */
    const userId = response.id;
    $('#userImage').attr('src', response.user_image || image_url_no_avatar_path);
    $('#fullName').text(response.user_name + ' (' + response.user_id + ')');
    $('#departmentName').text(response.department_name);
    $('#positionJobName').text(response.position_job);

    /* shiftselection  ───────────── */
    response.shifts.forEach(s => {
        const off = String(s.is_day_off || '').toUpperCase();
        const offLabelMap = { 'OFF': 'Nghỉ', 'HOLIDAY': 'Nghỉ lễ', 'ON-LEAVE': 'Nghỉ phép', 'TEACHING-SCHEDULE': 'Lịch giảng dạy' };

        if (offLabelMap[off]) {
            const card = $(`
              <div class="border rounded detail-shift card mb-3"
                   data-user-id="${userId}"
                   data-shiftselection-id="${s.shiftselection_id}"
                   data-id="${s.id}"
                   data-start="${s.start}" data-end="${s.end}">
                <div class="card-header text-dark d-flex justify-content-between">
                  <div class="text-label">
                    <strong>${s.label}: </strong>
                    <span>${offLabelMap[off]}</span>
                  </div>
                </div>
              </div>
            `);
            $('#detailAttends').append(card);
            return;
        }
        const clsIn  = gt(s.checkin, addMinutesStr(s.start, 15))   ? 'text-danger' : 'text-dark';
        const clsOut = gt(addMinutesStr(s.end, -15), s.checkout)   ? 'text-danger' : 'text-dark';
        const updateIn  = permission_edit_attend === "true"
            ? `<a class="text-primary ms-1 me-2 edit-time d-flex align-items-center" data-io="in"><i class="fas fa-pencil-alt"></i></a>` : ``;
        const updateOut = permission_edit_attend === "true"
            ? `<a class="text-primary ms-1 me-2 edit-time d-flex align-items-center" data-io="out"><i class="fas fa-pencil-alt"></i></a>` : ``;
        const textLabel = s.is_day_off === 'WORK-TRIP' ? `<div class="text-label"><strong>${s.label}: </strong><span>Đi công tác</span></div>`
            : `<div class="text-label"><strong>${s.label}: </strong><span>${s.start} – ${s.end}</span></div>`;
        const textLocation = s.is_day_off === 'WORK-TRIP' ? ``
            : `<div class="text-label text-dark mb-1 mt-0"><span>${s.location}</span></div>`;
        const card = $(`
        <div class="border rounded detail-shift card mb-3"
             data-user-id="${userId}"
             data-shiftselection-id="${s.shiftselection_id}"
             data-id="${s.id}"
             data-start="${s.start}" data-end="${s.end}">
          <div class="card-header text-dark d-flex justify-content-between">
            ${textLabel}
            <a class="nav-link ms-3 me-2" data-bs-toggle="collapse"
               href="#collapse-attends-${s.code}" role="button" aria-expanded="true"
               aria-controls="collapse-attends-${s.code}"
               onclick="clickCollapseAttends(this, '${s.code}')">
              <span class="fas fa-caret-down" id="collapse-icon-attend-${s.code}"></span>
            </a>
          </div>
          <div class="collapse show card-body row g-2 pt-0" id="collapse-attends-${s.code}">
            ${textLocation}
            <div class="col-6 text-center">
              <img class="img-fluid border rounded w-100 mb-2" src="${s.checkin_img || image_url_no_avatar_path}">
              <div class="d-flex justify-content-center">
                <span class="time-text me-1 d-flex align-items-center">Giờ vào: </span>
                <span class="time-text me-1 ${clsIn}" data-io="in">${s.checkin || '-'}</span>
                ${updateIn}
                <button class="btn btn-sm btn-primary save-time d-none" data-io="in">Lưu</button>
              </div>
            </div>
            <div class="col-6 text-center">
              <img class="img-fluid border rounded w-100 mb-2" src="${s.checkout_img || image_url_no_avatar_path}">
              <div class="d-flex justify-content-center">
                <span class="time-text me-1 d-flex align-items-center">Giờ ra: </span>
                <span class="time-text me-1 ${clsOut}" data-io="out">${s.checkout || '-'}</span>
                ${updateOut}
                <button class="btn btn-sm btn-primary save-time d-none" data-io="out">Lưu</button>
              </div>
            </div>
          </div>
        </div>
      `);

        $('#detailAttends').append(card);
    });

    /* shiftissue  ─────────────── */
    response.issues.forEach(i=>{
        let timeHTML   = '';
        let extraHTML  = '';
        let stype = i.stype.toLowerCase()
        switch (i.stype) {
            case 'LATE-CHECK-IN':
            case 'EARLY-CHECK-OUT':
            case 'ADDITIONAL-CHECK-OUT':
            case 'ADDITIONAL-CHECK-IN':
                timeHTML = `<span class="me-1">Thời gian: <strong class="text-dark">${i.time || '-'}</strong></span>`;
                break;

            case 'SHIFT-CHANGE': {
                extraHTML = `
                <span class="me-1">Đổi ca với: <strong class="text-dark">${i.to_user || '-'}</strong></span>
                <span class="me-1">Ngày cần đổi: <strong class="text-dark">${i.to_date}</strong></span>
                <span class="me-1">Ca cần đổi: <strong class="text-dark">${i.to_workshift}</strong></span>`;
                break;
            }

            case 'UPDATE-SHIFT': {
                extraHTML = `<span class="me-1">Thời gian thay đổi: <strong class="text-dark">${i.time_changed}</strong></span>`;
                break;
            }
        }

        $('#detailShiftIssues').append(`
          <div class="border rounded card mb-3">
            <div class="card-header d-flex justify-content-between">
                <div class="text-label">
                    <strong class="me-1">${mapStype(i.stype)}</strong>
                    ${i.status ? `<span class="badges ${mapStatusClass(i.status)}">${mapStatus(i.status)}</span>` : ''}
                </div>
                <a class="nav-link ms-3 me-2" data-bs-toggle="collapse" href="#collapse-shiftissue-${stype}-${i.id}" role="button" aria-expanded="true" aria-controls="collapse-shiftissue-${stype}-${i.id}" onclick="clickCollapseShiftIssues(this, '${stype}', '${i.id}')">
                    <span class="fas fa-caret-down" id="collapse-icon-shiftissue-${stype}-${i.id}"></span>
                </a>
            </div>
            <div class="collapse show card-body pt-0" id="collapse-shiftissue-${stype}-${i.id}">
              <div class="d-flex">
                  <div class="col-8 d-flex flex-column">
                   <span class="me-1">Người xử lý: <strong class="text-dark">${i.approved_by || '-'}</strong></span>
                   <span class="me-1">Ca hiện tại: <strong class="text-dark">${i.current_workshift}</strong></span>
                   ${timeHTML}
                   ${extraHTML}
                   <span class="me-1">Lý do: <strong class="text-dark">${i.reason}</strong></span>
                  </div>
                  <div class="col-4">
                    <img class="img-fluid border rounded w-100" src="${i.pic || image_url_no_avatar_path}">
                  </div>
              </div>
            </div>
          </div>`);
    });
    bindTimeEvents();

}

function bindTimeEvents(){
    $(document).off('click', '.edit-time').on('click', '.edit-time', function () {
        const io   = $(this).data('io');
        const card = $(this).closest('.card');
        const span = card.find(`.time-text[data-io=${io}]`);

        if (span.length) {
            const cur = span.text().trim().replace('-', '');
            span.replaceWith(`<input type="text"
                               class="form-control me-1 time-input text-center"
                               data-io="${io}" value="${cur}" style="max-width: 90px;">`);
            flatpickr(card.find(`.time-input[data-io=${io}]`)[0], {
                enableTime: true, noCalendar: true, time_24hr: true,
                dateFormat: 'H:i', defaultDate: cur, minuteIncrement: 1, static: true,
                appendTo: $('#attendDetailsModal')[0], scrollInput: false
            });
            card.find(`.save-time[data-io=${io}]`).removeClass('d-none');
        } else {
            const inp = card.find(`.time-input[data-io=${io}]`);
            const val = inp.val() || '-';
            const start = card.data('start'),
                  end   = card.data('end');
            const cls = io === 'in'
                ? (val !== '-' && val > addMinutesStr(start, 15) ? 'text-danger' : 'text-dark')
                : (val !== '-' && val < addMinutesStr(end, -15) ? 'text-danger' : 'text-dark');
            inp.replaceWith(`<span class="time-text me-1 ${cls}" data-io="${io}">${val}</span>`);
            card.find(`.save-time[data-io=${io}]`).addClass('d-none');
        }
    });

    $(document).off('click', '.save-time').on('click', '.save-time', function () {
        const io   = $(this).data('io');
        const card = $(this).closest('.card');
        const id   = card.attr('data-id');
        const shiftselectionId   = card.data('shiftselection-id');
        const userId   = card.data('user-id');
        const val  = card.find(`.time-input[data-io=${io}]`).val();
        const work_date = $('#attendDetailsModalLabel').attr('data-workdate')

        $.ajax({
            url : workshifts_update_attend_path,
            type: 'POST',
            headers: { 'X-CSRF-Token': $('meta[name="csrf-token"]').attr('content') },
            data: { attend_id: id || "", shiftselection_id: shiftselectionId, user_id: userId, field: io, value: val, work_date: work_date},
            success: (response) => {
                card.find(`.edit-time[data-io=${io}]`).click();
                if (card.attr("data-id") != null) {
                    card.attr("data-id", response.attend_id);
                }
                showAlert('Cập nhật thành công!', 'success');
            },
            error: () => showAlert('Có lỗi xảy ra khi lưu!', 'danger')
        });
    });
}

function mapStatus(status) {
    switch (status) {
        case 'APPROVED': return 'Đã phê duyệt';
        case 'PENDING': return 'Chờ phê duyệt';
        case 'REJECTED': return 'Từ chối';
        default: return '';
    }
}

function mapStype(stype) {
    switch (stype) {
        case 'LATE-CHECK-IN': return 'Đi trễ';
        case 'EARLY-CHECK-OUT': return 'Về sớm';
        case 'ADDITIONAL-CHECK-IN': return 'Chấm công vào làm bù';
        case 'ADDITIONAL-CHECK-OUT': return 'Chấm công tan làm bù';
        case 'SHIFT-CHANGE': return 'Đổi ca';
        case 'UPDATE-SHIFT': return 'Cập nhật ca';
        default: return stype;
    }
}

function mapStatusClass(status) {
    switch (status) {
        case 'APPROVED': return 'badges-approve';
        case 'PENDING': return 'badges-pending';
        case 'REJECTED': return 'badges-reject';
        default: return '';
    }
}

function clickCollapseAttends(element, code){
    document.getElementById(`collapse-icon-attend-${code}`).style.rotate = element.className.includes('collapsed') ? "90deg" : "unset";
}

function clickCollapseShiftIssues(element, code, id){
    document.getElementById(`collapse-icon-shiftissue-${code}-${id}`).style.rotate = element.className.includes('collapsed') ? "90deg" : "unset";
}

function addMinutesStr(timeStr, minsToAdd) {
    if (!timeStr) return null;
    const [h, m] = timeStr.split(':').map(Number);
    const date = new Date();
    date.setHours(h, m + minsToAdd, 0, 0);
    const hh = String(date.getHours()).padStart(2, '0');
    const mm = String(date.getMinutes()).padStart(2, '0');
    return `${hh}:${mm}`;
}

const gt = (a,b)=> a && b && a > b;
