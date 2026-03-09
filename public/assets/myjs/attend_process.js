$(document).ready(function () {
    // Xử lý lấy hình ảnh minh chứng của các yêu cầu cần duyệt
    $('.process-attend-btn').on('click', function (e) {
        showLoadding(true);
        e.preventDefault();
        var detailId = $(this).attr('data-detail-id')
        $.ajax({
            type: 'GET',
            url: get_image_evidence_attends_path,
            data: { detail_id: detailId },
            dataType: 'JSON',
            success: function (response) {
                if (response.docs) {
                    $('#image-evidence').attr('src', response.docs);
                }
                let modal = $('#imageEvidenceModal');
                modal.find('.btn-approve').attr('data-detail-id', detailId)
                modal.find('.btn-reject').attr('data-detail-id', detailId)
                showLoadding(false);
                modal.modal('show');
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

    // Xử lý phê duyệt yêu cầu chấm công
    $('#imageEvidenceModal').find('.btn-approve').on('click', function (e) {
        showLoadding(true);
        e.preventDefault();
        var detailId = $(this).attr('data-detail-id')
        $.ajax({
            type: 'POST',
            url: approve_request_attends_path,
            data: { detail_id: detailId },
            dataType: 'JSON',
            success: function (response) {
                $('#attend-request')
                    .find('td[data-detail-id="' + detailId + '"]')
                    .html('<span class="text-success">Đã phê duyệt</span>')
                    .next('td')
                    .find('.process-attend-btn')
                    .remove();
                $('#imageEvidenceModal').modal('hide');
                showAlert("Phê duyệt yêu cầu thành công");
                showLoadding(false);
            },
            error: function (xhr) {
                try {
                    const res = JSON.parse(xhr.responseText);
                    pushError(res);
                } catch (e) {
                    showAlert("Lỗi không xác định!", 'danger');
                    $('#imageEvidenceModal').modal('hide');
                    showLoadding(false);
                }
            }
        });
    });

    // Xử lý từ chối yêu cầu chấm công
    $('#imageEvidenceModal').find('.btn-reject').on('click', function (e) {
        showLoadding(true);
        e.preventDefault();
        var detailId = $(this).attr('data-detail-id')
        $.ajax({
            type: 'POST',
            url: reject_request_attends_path,
            data: { detail_id: detailId },
            dataType: 'JSON',
            success: function (response) {
                $('#attend-request')
                    .find('td[data-detail-id="' + detailId + '"]')
                    .html('<span class="text-danger">Từ chối</span>')
                    .next('td')
                    .find('.process-attend-btn')
                    .remove();
                $('#imageEvidenceModal').modal('hide');
                showAlert("Từ chối yêu cầu thành công");
                showLoadding(false);
            },
            error: function (xhr) {
                try {
                    const res = JSON.parse(xhr.responseText);
                    pushError(res);
                } catch (e) {
                    showAlert("Lỗi không xác định!", 'danger');
                    $('#imageEvidenceModal').modal('hide');
                    showLoadding(false);
                }
            }
        });
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

});