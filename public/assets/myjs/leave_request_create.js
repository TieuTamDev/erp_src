const rangePicker = $("#date_leave_range");
let leave_half = []
let isServerDatesLoaded = false;
let allSelectedDates = {};
let allSelectedDateTimes = {};
let allUserSelectedDates = {};
let allUserSelectedDateTimes = {};
const serverIndexes = new Set();
let datesLeaveEditByIndex = {};
let serverDateTimesEditByIndex = {};
const prevSelectedDatesByIndex = {};

let dates_leave_edit = []
let day_time_leave = []
let day_time_leave_tmp = []
let check_leader_tchc;
let check_sub_leader_tchc;
let check_sub_leader_bgd;
let check_tchcbuh;
let can_submit = true;
let value_cancel_tmp = {}
let isBUH = gon.organization == "BUH";
// Thông số đầu vào
const total_annual_leave = parseFloat(gon.total_leave);
const leave_taken = parseFloat(gon.total_used); 
let leave_remaining = 0;
let leave_earned = 0;
let leave_advanced = 0;
let total_leave = 0;    
let titleMessWarning = "Số ngày nghỉ dự kiến đã vượt quá số ngày phép \n Bạn có muốn tiếp tục và nộp đơn xin nghỉ không?"
let current_year_leave = new Date().getFullYear();
let data_leave_user = {};
let user_id_leave_request = "";
let check_register_for_user = false;
let svalue_leave_am = gon.svalue_leave_am;
let svalue_leave_pm = gon.svalue_leave_pm;
let users_handover = [];
let onRemoveDay = false;
let send_to_tchc = false;
      
$(document).ready(function() {
    let is_user_page = true //window.location.pathname.includes("user");
    let tableLeaveRequest = $('#tableleaverequest').DataTable({...optionTable,...{
        // searching: true,
        pageLength: 5,
        lengthMenu: [ [5, 10, 20, 50], [5, 10, 20, 50] ],   
        lengthChange: is_user_page,
        paging: true,
        stateSave: false,        
        info: true,
        deferRender: true,
        ordering: false,
        processing: true,
        serverSide: true,
    dom:
    '<"row"<"col-sm-12 table-responsive"tr>>' +                                                   // bảng dữ liệu
    '<"row mt-2"<"col-sm-6 d-flex"i><"col-sm-6 d-flex justify-content-end align-items-center"p l f>>', // info + phân trang + page length
        language: {
            lengthMenu: "_MENU_",
            emptyTable: "Không có dữ liệu",
            paginate: {
                previous: "Trước",
                next: "Sau"
            },
            info: "", // ẩn info mặc định
            infoEmpty: ""
        },
        "ajax": {
            "url": ERP_PATH + "leave_request/datas_leave_request?user_id=" + gon.user_id, 
            "type": "GET",
            "data": function(d) {
                d.page = d.start / d.length + 1;
                d.per_page = d.length; 
                d.search = $('#custom-search input').val();
            }
        },
        // render input data
        columns: [
            { data: "stype"},
            { data: "status_formated" },
            { data: "details" },
            { data: "dttotal",
                render: function(data, type, row) {
                    return data ? data + " ngày" : "0 ngày";
                }
            },
            { data: "btn" },
        ],
    }});
    // Tạo ô tìm kiếm gắn vào custom-search
    $('#custom-search').html(`
    <div class="input-group" style="height: 36px">
        <input type="text" class="form-control form-control-sm rounded-3" placeholder="Tìm kiếm">
        <i class="fas fa-search position-absolute top-50 end-0 translate-middle"></i>
    </div>
    `);
    tableLeaveRequest.on('draw', function () {
        const pageInfo = tableLeaveRequest.page.info();
        let customText = "";
        const data = tableLeaveRequest.rows({ page: 'current' }).data();
        const currentLength = data.length;
        if (pageInfo.recordsTotal === 0) {
            customText = "Không có bản ghi nào";
        } else {
            customText = `Hiển thị ${currentLength} trên tổng ${pageInfo.recordsTotal} bản ghi`;
        }
        if (window.location.pathname.includes("details")) {
            $(".btn-remove, .btn-edit").remove();
        }
        $('.dataTables_info').html(customText);
    });

    // Gắn sự kiện tìm kiếm
    $('#custom-search input').on('keyup change', function () {
        tableLeaveRequest.search(this.value).draw();
    });
    checkPage();
    get_dates_leaved()
});

// start on click button function
function onShowProcessHandle(holpros_id) {
    $.ajax({
        type: "GET",
        url: ERP_PATH + "leave_request/process_handle",
        data: {holpros_id: holpros_id},
        success: function (response) {
            $("#total_holpros").html(response.holpros.dttotal || 0);
            if (response.holdetails) {
                items_detail = ""
                response.holdetails.forEach((detail, index) => {
                    items_detail += itemHolprosdetail(detail)
                    if (index + 1 != response.holdetails.length) {
                        items_detail += "<hr>"
                    }
                })
                $(".details-leave-request").html(items_detail);
            }
            if (response.process_handle) {
                $(".process-handle-lr").empty();
                response.process_handle.forEach(mandoc => {
                    $(".process-handle-lr").append(renderFormProcessHandle(mandoc.id, mandoc.status))
                    items_process_handle = ""
                    mandoc.process_handle.forEach(data => {
                        items_process_handle += itemStepHandle(data.updated_at.split(" - "), data.title_step_process, data.users, data.uhandle_status)
                    })
                    $(`.render-process-handle-${mandoc.id}`).html(items_process_handle);
                });
            }
            
            const reason = response.holpros.note || '';
            const status = response.holpros.status;

            let message = "";

            if (status === "REFUSE") {
                message = `Lý do từ chối: <span class="fw-bold">${escapeAndFormat(reason)}</span>`;
            } else if (status === "CANCEL") {
                message = `Lý do hủy: <span class="fw-bold">${escapeAndFormat(reason)}</span>`;
            }

            $(".reason").html(message).toggle(!!message);
            showLoadding(false);
        }
    });
}

function escapeAndFormat(text) {
    return $('<div>').text(text).html().replace(/\n/g, "<br>");
}

function onDeleteLeaveRequest(holpros_id) {
    $("input[name='holpros_id']").val(holpros_id);
}

function addMoreLeaveRequest(stype, action = "ADD") {
    let index = $(".leave-request-item").last().data("index") + 1 || $(".leave-request-item").length + 1;
    $(".action").val(action)
    $(".stype").val(stype);
    $(".uhandle_id").val(null);
    $(".render-form-create-lr").append(formCreateLeaveRequest(index));
    can_submit = true;
    onRemoveDay = false;
    // if (action == "ADD" || action == "CANCEL") serverIndexes.clear();
    if (stype == "ON-LEAVE" || action == "CANCEL") {
        $(".user_request").hide();
        datas = gon.users_in_department;
        datas = datas.filter(user => user.user_id !== parseInt(gon.user_id));
        element = "handover_receiver";
        isServerDatesLoaded = false;
        get_dates_leaved(index);
        $(".btn-temp").show();
    } else {
        $(".user_request").show();
        datas = gon.users;
        // Loại bỏ user có id trùng với user_id_leave_request (nếu có)
        datas = datas.filter(user => user.user_id !== parseInt(gon.user_id));
        datas_receiver = gon.users_in_department.filter(user => user.id !== parseInt(gon.user_id));
        element = "user_id";
        renderOptionUsers(datas_receiver, "handover_receiver", index);
        $(".btn-temp").hide();
    }

    $(".btn-more").attr("onclick", `addMoreLeaveRequest("${stype}")`);
    renderOptionUsers(datas, element, index);
    renderOptionCountries(index);
    renderOptionHolstype(index);
    onShowIssuePlace({ value: "IN-COUNTRY" }, index);
    initializeSelect2(index);
    initializeFlatpickr(index);

    if (action == "CANCEL") {
        $(".btn-temp").hide();
        $('select[name="holtype"]').closest("div.mb-2").hide();
        $('select[name="handover_receiver"]').closest("div.mb-2").hide();
        $('input[name="region_type_1"]').closest("div.mb-2").hide();
        $('select[name="issued_place"]').closest("div.mb-2").hide();
        $('textarea[name="note"]').closest("div.row").hide();
        $('textarea[name="place_before_hol"]').closest("div.row").hide();
        $('.btn-more').hide();
        $('.remove-leave-request').hide();
    }else{
        $('select[name="holtype"]').closest("div.mb-2").show();
        $('select[name="handover_receiver"]').closest("div.mb-2").show();
        $('input[name="region_type_1"]').closest("div.mb-2").show();
        $('select[name="issued_place"]').closest("div.mb-2").show();
        $('textarea[name="note"]').closest("div.row").show();
        $('textarea[name="place_before_hol"]').closest("div.row").show();
        $('.btn-more').show();
        $('.remove-leave-request').show();
    }

    $(`.leave-request-item[data-index="${index}"]`).find(`select[name='region_type_${index}']`).trigger("change");

    // Disabled dates
    if (action != "EDIT" && action != "CANCEL") {
        let itemsLeaveRequest = $(`.leave-request-item[data-index='${index}']`);
    
        const fp = itemsLeaveRequest.find("input[name='date_leave_range']")[0]._flatpickr;
        let disabledDates = [];
        if (stype == "ON-LEAVE") {
            
        } else if (check_register_for_user) {
            if (user_id_leave_request != "") $(`.leave-request-item`).find(`select[name='user_id']`).val(user_id_leave_request).trigger("change").prop('disabled', true).trigger('change.select2');
            // disableDates = data_leave_user.days_leaved.map(date => flatpickr.parseDate(date, "d/m/Y"));
            disabledDates = getAllSelectedDatesExcluding(index).map(date => flatpickr.parseDate(date, "d/m/Y"));
            fp.set("disable", disabledDates); 
        }
    }
    
    let scrollTarget = $(`.leave-request-item[data-index='${index}']`);
    let modalBody = $('.modal-body');
    let targetOffset = scrollTarget.offset().top - modalBody.offset().top + modalBody.scrollTop() - 30;
    modalBody.animate({ scrollTop: targetOffset });
}

function onEditLeaveRequest(button, action = "EDIT") {
    var data = JSON.parse(new TextDecoder("utf-8").decode(Uint8Array.from(atob($(button).data('leave-request')), c => c.charCodeAt(0))));
    day_time_leave = [];
    dates_leave_edit = []
    value_cancel_tmp = {}
    serverIndexes.clear();
    datesLeaveEditByIndex = {};
    serverDateTimesEditByIndex = {};

    data.holprosdetails.forEach((holprodetail, index) => {
        addMoreLeaveRequest(holprodetail.stype, action);
        serverIndexes.add(index + 1);
        $(".detail-date-lr").find("p.text-center").hide();
        $(".stype").val(holprodetail.stype);

        dtto = moment(holprodetail.dtto).format("DD/MM/YYYY");
        dtfrom = moment(holprodetail.dtfrom).format("DD/MM/YYYY");
        issued_place = holprodetail.issued_place.split("$$$");
        if (issued_place.length == 1) {
            region_type = issued_place[0];
            country = null;
        } else {
            region_type = issued_place[1];
            country = issued_place[0];
        }
        let itemsLeaveRequest = $(`.leave-request-item[data-index='${index + 1}']`);
        // let rawDates = holprodetail.details ? holprodetail.details.split('$$$').map(part => part.split('-')[0]) : [];
        
        // let dates = rawDates.map(date => {
        //     if (date.match(/^\d{4}-\d{2}-\d{2}$/)) {
        //         const [y, m, d] = date.split("-");
        //         return `${d}/${m}/${y}`;
        //     } else if (date.match(/^\d{2}\/\d{2}\/\d{4}$/)) {
        //         return date;
        //     }
        //     return null;
        // }).filter(date => date);

        const originalDayTimes = (holprodetail.details || "")
        .split("$$$")
        .map(s => s.trim())
        .filter(Boolean)
        .map(parseDetailToken)
        .filter(Boolean);

        const dates = originalDayTimes.map(([d]) => d);

        datesLeaveEditByIndex[index + 1] = dates;
        serverDateTimesEditByIndex[index + 1] = originalDayTimes;
        value_cancel_tmp[index + 1] = holprodetail.details
        handover_receiver = holprodetail.handover_receiver.split("|||")
        itemsLeaveRequest.find("select[name='holtype']").val(holprodetail.sholtype).trigger("change");
        itemsLeaveRequest.find("input[name='dttotal']").val(holprodetail.itotal);
        itemsLeaveRequest.find("input[name='details']").val(holprodetail.details);
        itemsLeaveRequest.find("select[name='handover_receiver']").val(handover_receiver.every(item => item === "") ? [] : handover_receiver).trigger("change");
        itemsLeaveRequest.find(`input[name='region_type_${index + 1}'][value='${region_type}']`).prop("checked", true).trigger("change")
        itemsLeaveRequest.find("textarea[name='issued_national']").val(holprodetail.issued_national);
        itemsLeaveRequest.find("textarea[name='place_before_hol']").val(holprodetail.place_before_hol);
        itemsLeaveRequest.find("textarea[name='note']").val(holprodetail.note);
        itemsLeaveRequest.find("input[name='holprosdetail_id']").val(holprodetail.id);
        itemsLeaveRequest.find("select[name='issued_place']").val(country).trigger("change");

        const fp = itemsLeaveRequest.find("input[name='date_leave_range']")[0]._flatpickr;
        if (fp) {
            allSelectedDates[(index + 1).toString()] = dates;

            if (action == "CANCEL") {
                const { valid, invalid } = getValidDays(holprodetail.details);
                const allDates = [...valid, ...invalid];
                const fp = flatpickr(itemsLeaveRequest.find("input[name='date_leave_range']"), {
                    mode: "multiple",
                    dateFormat: "d/m/Y",
                    defaultDate: allDates,
                    enable: allDates,
                    monthSelectorType: "dropdown",
                    showMonths: 1,
                    yearSelectorType: "dropdown",
                    onChange: function(selectedDates, dateStr, instance) {
                        // Xử lý không cho bỏ chọn các ngày invalid
                        const selected = selectedDates.map(d =>
                            ("0" + d.getDate()).slice(-2) + "/" +
                            ("0" + (d.getMonth() + 1)).slice(-2) + "/" +
                            d.getFullYear()
                        );
                        let needRestore = false;
                        invalid.forEach(invDay => {
                            if (!selected.includes(invDay)) needRestore = true;
                        });
                        // if (needRestore) {
                            // Luôn giữ lại các ngày invalid
                            const restoreDates = [...selected, ...invalid.filter(invDay => !selected.includes(invDay))];
                            instance.setDate(restoreDates, false);
                            // Optionally: alert hoặc toast cảnh báo
                            // alert("Bạn không thể bỏ chọn những ngày này!");
                        // }
                        // $(document).ready(function () {
                            renderRadios(holprodetail.details, restoreDates, index + 1, action, false);
                        // });
                    }
                });
            }else{
                if (dates.length > 0) {
                    const parsedDates = dates.map(date => flatpickr.parseDate(date, "d/m/Y"));
                    
                    fp.setDate(parsedDates);
                    dates_leave_edit.push(...dates);
                } else {
                    console.warn(`Không có ngày hợp lệ để thiết lập cho index ${index + 1}`);
                }
                const disableDates = getAllSelectedDatesExcluding(index + 1, dates).map(date => flatpickr.parseDate(date, "d/m/Y"));
                fp.set("disable", disableDates);
                fp.redraw();
            }
        }

        // if (action != "CANCEL") {
        // }

        //     $(document).ready(function () {
                renderRadios(holprodetail.details, dates, index + 1, action);
                if (action == "CANCEL") $("textarea[name='place_before_hol'").closest(".row.mb-3").hide();
            // });
        day_time_leave_tmp = index >= data.holprosdetails.length ? true : false
        updateLeaveDatePagination(index + 1);
        disableDuplicateDateTimeRadios(index + 1);
    });

    $(".holpros_id").val(data.holpros_id);
    $(".uhandle_id").val(data.uhandle_id);
}

function renderRadios(details, selected = [], index, action, save = true) {
    let dayList = "";
    const details_days = details.split("$$$");
    const dateListContainer = $(`#leave-request-${index} .detail-date-lr`);
    dateListContainer.find(".row").remove();

    let dayTimes = [];
    details_days.forEach((item) => {
        if (item) {
            const parsed = parseDetailToken(item);
            if (!parsed) return;
            const [day, time] = parsed;

            if (selected.includes(day) || selected.length < 1) {
                dayTimes.push([day, time]);
                // --- Push vào mảng tổng ---
                if (save) day_time_leave.push({value: `${day}-${time}`, index: index});
                let checkDay = checkLegitDay(day)
                // ---------------------------
                if (checkDay.is_legit) {
                    dateListContainer.append(renderListDays(day, time, index, action, action == "CANCEL" ? getValidDays(details).valid : [], checkDay.is_disable_checkbox))
                    $(`#${day.replace(/\//g, "")}-${index}-${time}`).prop("checked", true);   
                }else{

                }
            }
        }
    });
    allSelectedDateTimes[index.toString()] = dayTimes;
    attachRadioChangeHandler(index);
}

function checkLegitDay(day) {
    let today = new Date()
    let current_hour = today.getHours();
    let is_legit = true;
    let is_disable_checkbox = {};
    if (day == moment(today).format("DD/MM/YYYY") && gon.organization != "BUH") {
        if (current_hour > svalue_leave_am && current_hour < svalue_leave_pm){
            is_disable_checkbox.PM = false;
            is_disable_checkbox.ALL = true;
            is_disable_checkbox.AM = true;
            return {is_legit: is_legit, is_disable_checkbox: is_disable_checkbox}
        }else if (current_hour > svalue_leave_pm) {
            is_legit = false
            return {is_legit: is_legit, is_disable_checkbox: is_disable_checkbox}
        }
    }
    return {is_legit: is_legit, is_disable_checkbox: is_disable_checkbox}
}

function getValidDays(detailsStr) {
    if (!detailsStr) return [];
    const now = new Date();
    const validDays = [];
    const invalidDays = [];

    const items = detailsStr.split('$$$');
    for (let item of items) {
        const [dayStr] = item.split('-');
        if (!dayStr) continue;

        // Parse ngày dd/mm/yyyy
        const [d, m, y] = dayStr.split('/').map(Number);
        let date = new Date(y, m - 1, d);
        date.setDate(date.getDate()); // Trừ 1 ngày
        date.setHours(19, 0, 0, 0); // Set giờ 19h

        if (now < date) {
            validDays.push(dayStr);
        }else{
            invalidDays.push(dayStr);
        }
    }
    return {valid: validDays, invalid: invalidDays};
}

function onCreateLeaveRequest(type) {
    let datasSubmit = formatDataSave();
    $(".user_id").val($("select[name='user_id']").val()?.split("$$$")[0]);
    let action = $('input[name="action_submit"]').val()
    $(".form-create-leave-request").append(`<input type="hidden" name="datas" value='${JSON.stringify(datasSubmit)}'>`);
    if (type == "SAVE") {
        $(".form-create-leave-request").append(`<input type="hidden" name="commit" value='save'>`);
        $(".form-create-leave-request").submit();
        showLoadding(true);
    }else{
        if (action == "CANCEL"){
            let is_change = Object.entries(value_cancel_tmp).some(([key, value]) => {
                let current_details = $(`.leave-request-item[data-index='${key}'] [name='details']`).val();
                return current_details != value;
            });
            if (is_change) {
                handleSubmit(action);
            }else{
                Swal.fire({
                    title: "Thông báo",
                    text: `Vui lòng thay đổi thông tin ngày nghỉ để tiếp tục!`,
                    icon: "warning",
                });
            }
        }else{
            if (!validateionCreate()) return;
            if (!can_submit) {
                Swal.fire({
                    title: "Thông báo",
                    text: `Nhân sự ${$("select[name='user_id']").val().split("$$$")[1]} chưa được cấu hình nghỉ phép!`,
                    icon: "warning",
                });
                return;
            }
            let totalLeaveDefault = -999;
            let totalLeaveChoosed = checkTotalLeaveChoosed();
            
            total = Object.keys(data_leave_user).length == 0 ? total_leave : data_leave_user.total_leave;
            if(totalLeaveChoosed > 0) totalLeaveDefault = totalLeaveChoosed

            if (isBUH) {
                titleMessWarning = "Số ngày nghỉ dự kiến đã vượt quá số ngày phép \n Bạn có muốn tiếp tục và nộp đơn xin nghỉ không?"
            }else{
                titleMessWarning = `Bạn đã đăng ký nghỉ quá số ngày phép còn lại là ${Object.keys(data_leave_user).length == 0 ? customRound(total_leave) : customRound(data_leave_user.total_leave)} ngày! \n Vui lòng chỉnh sửa, điều chỉnh Đơn xin nghỉ cho phù hợp!`
            }
            if (totalLeaveDefault > total) {
                Swal.fire({
                    title: "Xác nhận",
                    text: titleMessWarning,
                    icon: "question",
                    showCancelButton: true,
                    showConfirmButton: isBUH ? true : false,
                    confirmButtonText: "Nộp đơn",
                    cancelButtonText: "Hủy bỏ"
                }).then((result) => {
                    if (result.isConfirmed) {
                        handleSubmit(action);
                    }
                });
            }else{
                if (isBUH) {
                    handleSubmit(action);
                }else{
                    Swal.fire({
                        title: "Cảnh báo",
                        text: " Ngày nghỉ bạn chọn có thể thuộc lịch nghỉ hàng tuần. Hệ thống sẽ tự trừ phép. Bạn có muốn tiếp tục không?",
                        icon: "question",
                        showCancelButton: true,
                        showConfirmButton: true,
                        confirmButtonText: "Vẫn đăng ký",
                        cancelButtonText: "Hủy bỏ"
                    }).then((result) => {
                        if (result.isConfirmed) {
                            handleSubmit(action);
                        }
                    });
                }
            }
        } 
    }
}

function checkTotalLeaveChoosed() {
    let leaveChoosed = 0;
    $(".leave-request-item").each(function (index, element) {
        holtype = $(element).find("select[name='holtype']").val();
        dttotal = $(element).find("input[name='dttotal']").val();
        if (holtype == "NGHI-PHEP") {
            dtdeadline = Object.keys(data_leave_user).length == 0 ? parseDate(gon.dtdeadline) : parseDate(data_leave_user.dtdeadline);
            const count = $(element).find('input[name="date_leave_range"]').val()
                .split(', ')
                .map(s => s.trim())
                .map(parseDate)
                .filter(d => d <= dtdeadline)
                .length;
            leaveChoosed += parseFloat(dttotal);
            if (count > 0) {
                if (Object.keys(data_leave_user).length == 0) {
                    leaveChoosed -= count >gon.remain_amount ? gon.remain_amount : count; 
                }else{
                    leaveChoosed -= count > data_leave_user.remain_amount ? data_leave_user.remain_amount : count; 
                }
            }
        }
    });
    return leaveChoosed;
}

function validLeaveChoosed() {
    if ($('input[name="action_submit"]').val() == "CANCEL") return;
    let totalLeaveDefault = -999;
    let totalLeaveChoosed = checkTotalLeaveChoosed();
    let alertItem = $("#leaveRequestModal .alert-danger");
    let total = Object.keys(data_leave_user).length == 0 ? total_leave : data_leave_user.total_leave;
    if(totalLeaveChoosed > 0) totalLeaveDefault = totalLeaveChoosed

    if (totalLeaveDefault > total) {
       alertItem.text(`Bạn đã đăng ký nghỉ quá số ngày nghỉ phép! Số phép còn lại là ${Object.keys(data_leave_user).length == 0 ? customRound(total_leave) : customRound(data_leave_user.total_leave)} ngày.`);
       alertItem.show();
    } else {
       alertItem.hide();
    }
}

function handleSubmit(action) {
    const stype = $("input[name='stype']").val();
    const $form = $("#form-create-leave-request");
    const hiddenInputName = 'leave_bgd_flag';
    if (stype == "ON-ADDITIONAL-LEAVE") {
        // Đăng ký nghỉ thay        
        if (gon.organization[0] == "BUH"){
            // Đăng ký nghỉ phép cho bệnh viện
            $form.find(`input[name="${hiddenInputName}"]`).remove();
            
            if (gon.faculty == "PTCHC(BUH)" &&  gon.leader_roles_buh && !((check_leader_tchc || check_sub_leader_tchc) && check_tchcbuh) && action != "CANCEL") {
                showLoadding(true);
                $form.submit();
            } else if(gon.faculty == "BGD(BUH)" && check_sub_leader_bgd && action != "CANCEL") {
                $form.append(`<input type="hidden" name="${hiddenInputName}" value="1">`);
                $form.submit();
                showLoadding(true);
            } 
            else if(gon.faculty == "BGD(BUH)" && gon.leave_bgd) {
                $form.append(`<input type="hidden" name="${hiddenInputName}" value="1">`);
                $form.submit();
                showLoadding(true);
            } 
            else {
                assignUserNext();
            }
        }else {
            // Đăng ký nghỉ phép cho bên trường
            if ((gon.leader_roles || gon.sub_leader_roles) && !(check_leader_tchc || check_sub_leader_tchc)) {
                // Nếu là trưởng phòng hoặc phó phòng đăng ký cho nhân viên thì submit
                showLoadding(true);
                $form.submit();
            } else if (gon.sub_leader_roles && (check_leader_tchc || check_sub_leader_tchc)) {
                // Nếu là phó phòng và nhân sự được đăng ký là trưởng hoặc phó thì gửi cho bước tiếp theo
                assignUserNext();
            }else if (gon.leader_roles && (check_sub_leader_tchc || !check_leader_tchc)){
                // Nếu là trưởng phòng và nhân sự được đăng ký là phó phòng hoặc không phải là trưởng phòng thì submit
                showLoadding(true);
                $form.submit();
            }else{
                showLoadding(true);
                $form.submit();
            }
        }
    }
    else if(gon.leave_bgd == true){
        $form.find(`input[name="${hiddenInputName}"]`).remove();
        $form.append(`<input type="hidden" name="${hiddenInputName}" value="1">`);
        $form.submit();
        showLoadding(true);
    }else{
        // Cá nhân tự đăng ký
        $form.find(`input[name="${hiddenInputName}"]`).remove();
        assignUserNext();
    }
    showLoadding(false);
}

function assignUserNext() {
    $(".form-create-leave-request").append(`<input type="hidden" name="commit" value='submit'>`);
    $(".form-create-leave-request").append(`<input type="hidden" name="org" value='${gon.organization[0]}'>`);
    getInfoUserNext();
    $("#form-create-leave-request").hide();
    $("#assignUserNextModal").modal("show");
    showLoadding(true);
}

function parseDate(str) {
  const [day, month, year] = str.split('/').map(Number);
  return new Date(year, month - 1, day);
}

// $("#btnSubmit").click(function(){
//     showLoadding(true);
// });
const form = document.getElementById('assign-user');
form.addEventListener('submit', function (event) {
    showLoadding(true);
    if (!form.checkValidity()) {
        event.preventDefault();
        event.stopPropagation();
        showLoadding(false);
    }

    form.classList.add('was-validated');
});

$('#info-user-next').on('change', function () {
  this.setCustomValidity(this.value ? '' : 'Vui lòng chọn người phê duyệt');
});

$(document).on('click', '.remove-leave-request', function () {
    var index = $(this).data('index');
    $(`.leave-request-item[data-index='${index}']`).remove();
    data_leave_user = {};
    // Cập nhật lại allSelectedDates khi xóa đơn
    delete allSelectedDates[index];
    delete allSelectedDateTimes[index];
    delete allUserSelectedDateTimes[index];
    leaveDateCurrentPageMap.delete(String(index));
    leaveDatePageSizeMap.delete(String(index));
    // Cập nhật lại các Flatpickr khác để enable lại các ngày đã bị disable do đơn này
    $(".leave-request-item").each(function () {
        const idx = $(this).data('index');
        const fp = $(this).find("input[name='date_leave_range']")[0]?._flatpickr;
        if (fp) {
            fp.set("disable", getAllSelectedDatesExcluding(idx));
        }
    });
    if ($(`.leave-request-item`).length == 0) {
        user_id_leave_request = ""
    }
});
// end on click button function
// disable handle_receive when selected user_id
$(document).on('change', 'select[name="user_id"]', function () {
    const selectedUser = $(this).val();
    const currentIndex = $(this).data('index');

    const handoverSelect = $(`select[name="handover_receiver"][data-index="${currentIndex}"]`);

    handoverSelect.find('option').prop('disabled', false).show();

    if (selectedUser) {
        // Remove the selected user from current selected values if present
        let currentValues = handoverSelect.val() || [];
        if (currentValues.includes(selectedUser)) {
            currentValues = currentValues.filter(v => v !== selectedUser);
            handoverSelect.val(currentValues).trigger('change');
        }
        // Disable and hide the selected user in handover_receiver
        handoverSelect.find(`option[value="${selectedUser}"]`).prop('disabled', true).hide();
    }
    
    // if (user_id_leave_request != selectedUser) {
        
    // }

    user_id_leave_request = selectedUser;
    handoverSelect.trigger('change.select2');
    // $(`.leave-request-item`).find(`select[name='user_id']`).val(user_id_leave_request).select2({theme: "bootstrap-5"});
    $.ajax({
        type: "GET",
        url: ERP_PATH + "leave_request/get_days_leave?user_id=" + selectedUser.split("$$$")[0] || "",
        success: function (response) {
            data_leave_user = response || [];
            if (Object.keys(data_leave_user).length != 0) {
                check_register_for_user = true;
                can_submit = true;
                response.works.filter(item => {
                    const isTCHCBUH = item.dfaculty?.toUpperCase() === "PTCHC(BUH)";
                    if (gon.organization[0] == "BUH") {
                        check_leader_tchc = response.is_leader_buh
                        check_sub_leader_tchc = response.is_leader_buh
                        check_sub_leader_bgd = response.check_per_bgd
                        check_tchcbuh = isTCHCBUH
                    } else {
                        const pnameLower = item.pname?.toLowerCase();
                        const hasLeader = pnameLower?.includes("trưởng") || pnameLower?.includes("giám") || pnameLower?.includes("chánh") || pnameLower?.includes("chủ tịch");
                        const hasSubLeader = pnameLower?.includes("phó");
    
                        check_leader_tchc = hasLeader
                        check_sub_leader_tchc = hasSubLeader
                        check_tchcbuh = isTCHCBUH
                    }
                });
                users_handover = response.users_handover
                users_handover = users_handover.filter(user => user.user_id !== parseInt(selectedUser));
                renderOptionUsers(users_handover, "handover_receiver", currentIndex);

                allSelectedDates["sever"] = Array.isArray(response.days_leaved) 
                                                ? response.days_leaved
                                                    .filter(date => typeof date[0] === 'string' && date[0].match(/^\d{2}\/\d{2}\/\d{4}$/))
                                                    .map(date => date[0])
                                                : [];
                allSelectedDateTimes["sever"] = Array.isArray(response.days_leaved)
                                                    ? response.days_leaved
                                                    : [];
                let itemsLeaveRequest = $(`.leave-request-item[data-index='${currentIndex}']`);
                const fp = itemsLeaveRequest.find("input[name='date_leave_range']")[0]._flatpickr;

                disabledDates = getAllSelectedDatesExcluding(currentIndex).map(date => flatpickr.parseDate(date, "d/m/Y"));

                fp.set("disable", disabledDates); 
            }else{
                Swal.fire({
                    title: "Thông báo",
                    text: `Nhân sự ${selectedUser.split("$$$")[1]} chưa được cấu hình nghỉ phép!`,
                    icon: "warning",
                });
                can_submit = false;
            }
        }
    });
});

// start functions proccess
function get_dates_leaved(index = 0, callback) {
    showLoadding(true);

    $.ajax({
        type: "GET",
        url: ERP_PATH + "leave_request/dates_leaved",
        data: {},
        success: function(response) {
            
            // leave_half = response.filter(item => !item.includes("ALL"));
                        // console.log(response.map(item => item.split('-')[0]))        
            allSelectedDates["sever"] = Array.isArray(response) 
                ? response
                    .filter(date => typeof date[0] === 'string' && date[0].match(/^\d{2}\/\d{2}\/\d{4}$/))
                    .map(date => date[0])
                : [];
            allSelectedDateTimes["sever"] = Array.isArray(response)
                ? response
                : [];
            isServerDatesLoaded = true;

            let itemsLeaveRequest = $(`.leave-request-item[data-index='${index}']`);
            
            if (itemsLeaveRequest.length > 0) {
                const fp = itemsLeaveRequest.find("input[name='date_leave_range']")[0]._flatpickr;
                disabledDates = getAllSelectedDatesExcluding(index).map(date => flatpickr.parseDate(date, "d/m/Y"));
                fp.set("disable", disabledDates);
                refreshAllPickersDisabled();
                // if (callback) callback();
            }
            refreshAllPickersDisabled();
            showLoadding(false);
        },
        error: function(xhr, status, error) {
            console.error("Lỗi khi tải dữ liệu từ server:", error);
            allSelectedDates["sever"] = [];
            allSelectedDateTimes["sever"] = [];
            // if (callback) callback();
        }
    });
}
function checkPage() {
    calculateDaysOffMonth();
    if (isBUH) {
    }else{
        total_leave = total_annual_leave + gon.remain_amount - leave_taken;
    }
    if (window.location.pathname.includes("leave_request")) {
        $("#tableleaverequest_info").hide();
        $(".render-info-leave").remove();
        $(".serach-add-container").remove();
    } else if(window.location.pathname.includes("user")) {
        $(".info-leave").remove();
        $(".table-leave").removeClass("col-xl-8 col-xxl-9 ps-3");
        $("#tableleaverequest_info").show();
        $("#tableleaverequest_info").closest(".row").addClass("align-items-center");

        $(".table-leave").closest(".row").removeClass();
        $(".table-leave").closest(".card-body").removeClass();
        $(".table-leave").closest(".card").removeClass();

        $(".remain-leave").html(`
            <span class="text-dark">Phép tồn năm ${current_year_leave - 1} :</span>
            <span class="text-dark ms-4">${gon.remain_amount} ngày</span>
        `);
        $(".annual-leave").html(`
            <span class="text-dark">Phép năm ${current_year_leave} :</span>
            <span class="text-dark ms-4">${gon.total_leave} ngày</span>
        `);
        $(".total-leave").html(`
            <span class="text-dark">Tổng ngày phép năm ${current_year_leave} :</span>
            <span class="text-dark ms-4">${gon.total_used}/${gon.total_leave} ngày</span>
        `);
        if (window.location.pathname.includes("details")) {
            $(".btn-add").remove();
        }
    } else {
        $(".render-info-leave").remove();
        $("#tableleaverequest_info").hide();
        $(".serach-add-container").remove();
        $("#tableleaverequest_info").closest(".row").addClass("align-items-center");
    }
}

function normalizeDayString(dayStr) {
  if (!dayStr) return null;
  if (/^\d{2}\/\d{2}\/\d{4}$/.test(dayStr)) return dayStr;          // dd/mm/yyyy
  if (/^\d{4}-\d{2}-\d{2}$/.test(dayStr)) {                        // yyyy-mm-dd
    const [y, m, d] = dayStr.split("-");
    return `${d}/${m}/${y}`;
  }
  return null;
}

// token có thể là "09/01/2026-PM" hoặc "2026-01-09-PM"
function parseDetailToken(token) {
  if (!token) return null;
  const parts = token.split("-").map(s => s.trim()).filter(Boolean);
  if (parts.length < 2) return null;
  const time = parts.pop();               // AM/PM/ALL
  const datePart = parts.join("-");       // phần còn lại là date
  const day = normalizeDayString(datePart);
  if (!day) return null;
  return [day, time];
}

function addOccupied(map, date, type) {
  if (!map[date]) map[date] = { AM: false, PM: false };
  if (type === "ALL") { map[date].AM = true; map[date].PM = true; }
  if (type === "AM") map[date].AM = true;
  if (type === "PM") map[date].PM = true;
}

// occupied = slot đã bị chiếm bởi (UI của các đơn khác + DB), nhưng:
// DB sẽ bị TRỪ các slot gốc của tất cả record đang edit (serverIndexes)
// vì các record đó đã được đại diện bằng UI hiện tại.
function buildOccupiedMap(excludeIndex) {
  const occupied = {};
  const excludeKey = String(excludeIndex);

  // 1) slot từ UI (các đơn trong modal)
  for (const idx in allSelectedDateTimes) {
    if (idx === "sever") continue;
    if (idx === excludeKey) continue;
    (allSelectedDateTimes[idx] || []).forEach(([d, t]) => addOccupied(occupied, d, t));
  }

  // 2) build tập slot cần “trừ” khỏi DB = slot gốc của toàn bộ record đang edit
  const skipServerSlots = new Set();
  serverIndexes.forEach(i => {
    const key = String(i);
    (serverDateTimesEditByIndex[key] || []).forEach(([d, t]) => {
      skipServerSlots.add(`${d}-${t}`);
    });
  });

  // 3) slot từ DB (sever) - trừ slot của record đang edit
  (allSelectedDateTimes["sever"] || []).forEach(([d, t]) => {
    if (skipServerSlots.has(`${d}-${t}`)) return;
    addOccupied(occupied, d, t);
  });

  return occupied;
}

// Refresh disable của TẤT CẢ picker + radio sau mỗi lần DB/UI thay đổi
function refreshAllPickersDisabled() {
  $(".leave-request-item").each(function () {
    const idx = $(this).data("index");
    const fp = $(this).find("input[name='date_leave_range']")[0]?._flatpickr;
    if (!fp) return;

    const disableDates = getAllSelectedDatesExcluding(idx, datesLeaveEditByIndex[idx] || [])
      .map(d => flatpickr.parseDate(d, "d/m/Y"));

    fp.set("disable", disableDates);
    fp.redraw();
  });

  disableDuplicateDateTimeRadios();
}

function isFullDay(dateStr) {
    let hasAM = false;
    let hasPM = false;
    let hasALL = false;
    for (const key in allSelectedDateTimes) {
        const times = allSelectedDateTimes[key];
        times.forEach(dt => {
            if (Array.isArray(dt) && dt[0] === dateStr) {
                if (dt[1] === "ALL") hasALL = true;
                else if (dt[1] === "AM") hasAM = true;
                else if (dt[1] === "PM") hasPM = true;
            }
        });
    }
    // Chỉ return true nếu có cả AM và PM nhưng không có ALL
    // return hasAM && hasPM && !hasALL;
    // return hasALL || (hasAM && hasPM);
    if (hasALL && !hasAM && !hasPM) return true;              // chỉ có ALL
    if (hasALL && (hasAM || hasPM)) return false;             // ALL và có thêm AM hoặc PM
    if (!hasALL && hasAM && hasPM) return true;               // không có ALL, có cả AM & PM
    return false;   
}

// function getAllSelectedDatesExcluding(indexToExclude, currentDates = []) {
//     console.log(2);
    
//     const disabled = [];
//     // Thêm các ngày đã được chọn từ các đơn khác
//     // ============ 1. Thêm ngày nghỉ lễ từ API ==============
//     if (gon.all_holiday_csvc && gon.all_holiday_csvc.result) {
//         gon.all_holiday_csvc.result.forEach(item => {
//             const dateStr = item.date;  // dạng dd/mm/YYYY
//             if (typeof dateStr === 'string' && dateStr.match(/^\d{2}\/\d{2}\/\d{4}$/)) {
//                 disabled.push(dateStr);
//             }
//         });
//     }
//     console.log(disabled);
    
//     for (const [index, dates] of Object.entries(allSelectedDates)) {
        
//         if (parseInt(index) !== indexToExclude && index !== indexToExclude.toString()) {
//             if (Array.isArray(dates)) {
//                 for (const dateStr of dates) {
//                     if (typeof dateStr === 'string' && dateStr.match(/^\d{2}\/\d{2}\/\d{4}$/)) {
//                         // Kiểm tra nếu ngày này trong allSelectedDateTimes là "ALL" thì mới push vào disabled
//                         if (isFullDay(dateStr)) {
//                             disabled.push(dateStr);
//                         }
//                     } else {
//                         console.warn(`Ngày không hợp lệ trong allSelectedDates[${index}]:`, dateStr);
//                     }
//                 }
//             }
//         }
//     }

//     // Loại trừ các ngày hiện tại và loại bỏ trùng lặp
//     return Array.from(new Set(disabled)).filter(date => !dates_leave_edit.includes(date));
// }

function getAllSelectedDatesExcluding(indexToExclude, currentDates = []) {
  const disabled = [];

  // 1) Disable ngày nghỉ lễ (full-day)
  if (gon.all_holiday_csvc && gon.all_holiday_csvc.result) {
    gon.all_holiday_csvc.result.forEach(item => {
      const dateStr = item.date; // dd/mm/yyyy
      if (typeof dateStr === "string" && /^\d{2}\/\d{2}\/\d{4}$/.test(dateStr)) {
        disabled.push(dateStr);
      }
    });
  }

  // 2) Disable ngày bị chiếm FULL-DAY (AM & PM) dựa trên occupied map “đúng”
  const occupied = buildOccupiedMap(indexToExclude);
  Object.entries(occupied).forEach(([date, occ]) => {
    if (occ.AM && occ.PM) disabled.push(date);
  });

  // 3) loại trùng + không disable các ngày đang muốn giữ (currentDates)
  return Array.from(new Set(disabled)).filter(d => !currentDates.includes(d));
}


function updateOtherPickers(changedIndex) {
    $(".flatpickr-time-modal").each(function() {
        const parentId = $(this).closest("[id^='leave-request-']").attr("id");
        const index = parseInt(parentId.split("-").pop());
        if (index !== changedIndex) {
            const fp = $(this).get(0)?._flatpickr;
            if (fp) {
                const disableDates = getAllSelectedDatesExcluding(index).map(date => flatpickr.parseDate(date, "d/m/Y"));
                fp.set("disable", disableDates);
                fp.redraw();
            }
        }
    });
    disableDuplicateDateTimeRadios(changedIndex);
}

// function disableDuplicateDateTimeRadios(currentDataIndex) {
//     console.log(3);
    
//     // Bước 1: build dateTypeMap (không tính duplicate ngày đang chỉnh sửa ở server)
//     const dateTypeMap = {}; // { "25/07/2025": Set("ALL", "AM", "PM") }

//     // Lấy tất cả index trừ 'sever'
//     for (const idx in allSelectedDateTimes) {
//         if (serverIndexes.has(Number(idx)) && Number(idx) === Number(currentDataIndex)) continue;
//         allSelectedDateTimes[idx].forEach(([date, type]) => {
//             if (!dateTypeMap[date]) dateTypeMap[date] = new Set();
//             dateTypeMap[date].add(type);
//         });
//     }

//     // Duyệt 'sever', chỉ cộng những ngày KHÔNG nằm trong index đang chỉnh sửa
//     allSelectedDateTimes['sever']?.forEach(([date, type]) => {
//         // Nếu ngày này đang được chỉnh sửa ở currentDataIndex, thì KHÔNG tính
//         // Nếu bạn muốn cho phép vừa chỉnh PM vừa có AM ở server (chỉ trong trường hợp sửa chính ngày đó), thì bỏ qua
//         const editingDates = new Set((allSelectedDateTimes[currentDataIndex] || []).map(([d]) => d));
//         if (editingDates.has(date)) return;
//         if (!dateTypeMap[date]) dateTypeMap[date] = new Set();
//         dateTypeMap[date].add(type);
//     });

//     // Đếm duplicate
//     const dateCountMap = {};
//     for (const date in dateTypeMap) {
//         const types = Array.from(dateTypeMap[date]);
//         // Nếu có cả "AM" và "PM" → duplicate
//         if (types.includes("AM") && types.includes("PM")) {
//             dateCountMap[date] = 2; // duplicate
//         } else {
//             dateCountMap[date] = 1; // không duplicate
//         }
//     }

//     // Bước 2: disable radio
//     $(".leave-request-item").each(function () {
//         const index = $(this).data("index");

//         $(this).find(".detail-date-lr fieldset").each(function () {
//             const radios = $(this).find('input[type="radio"]');

//             radios.each(function () {
//                 const $radio = $(this);
//                 const dataDisabled = $radio.data("disabled")
//                 const val = $radio.val(); // VD: "08/07/2025-AM"
//                 const isChecked = $radio.is(":checked");

//                 const [date, part] = val.split("-");
//                 const isDuplicateDate = dateCountMap[date] > 1;

//                 let shouldDisable = false;

//                 if (isDuplicateDate) {
//                     shouldDisable = !isChecked;
//                 } else if ( dataDisabled ){
//                     shouldDisable = true
//                 } else {
//                     shouldDisable = false
//                 }

//                 $radio.prop("disabled", shouldDisable);
//                 $radio.closest("label").toggleClass("text-muted", shouldDisable);
//             });
//         });
//     });
// }

function disableDuplicateDateTimeRadios() {
  $(".leave-request-item").each(function () {
    const index = $(this).data("index");
    const occupied = buildOccupiedMap(index);

    $(this).find(".detail-date-lr fieldset").each(function () {
      const radios = $(this).find('input[type="radio"]');
      if (!radios.length) return;

      const sampleVal = $(radios.get(0)).val() || "";
      const [date] = sampleVal.split("-");
      const occ = occupied[date] || { AM: false, PM: false };

      radios.each(function () {
        const $radio = $(this);
        const isChecked = $radio.is(":checked");
        const dataDisabled = $radio.data("disabled");

        // radio đang checked thì luôn cho phép (để user nhìn/đổi)
        if (isChecked) {
          $radio.prop("disabled", false);
          $radio.closest("label").removeClass("text-muted");
          return;
        }

        const [, part] = ($radio.val() || "").split("-");
        let shouldDisable = false;

        if (part === "ALL") shouldDisable = occ.AM || occ.PM; // ALL cần trống cả 2 buổi
        if (part === "AM")  shouldDisable = occ.AM;
        if (part === "PM")  shouldDisable = occ.PM;

        if (dataDisabled) shouldDisable = true;

        $radio.prop("disabled", shouldDisable);
        $radio.closest("label").toggleClass("text-muted", shouldDisable);
      });
    });
  });
}

function disableInputsForDates(dates) {
  dates.forEach(dateWithPeriod => {
    const [date] = dateWithPeriod.split('-');

    const allInput = document.querySelector(`input[value="${date}-ALL"]`);
    if (allInput) allInput.disabled = true;

    const specificInput = document.querySelector(`input[value="${dateWithPeriod}"]`);
    if (specificInput) specificInput.disabled = true;
  });
}
// Lấy danh sách nhân sự để bàn giao công việc
function get_users_on_leave(days, index) {
    const $select = $(`.sel-handover-receiver[data-index="${index}"]`);
    const select_usser_id = $(`.sel_user_request[data-index="${index}"]`);
    $('.sel-handover-receiver option').prop('disabled', false);
    $select.trigger('change.select2');
    $.ajax({
        type: "GET",
        url: ERP_PATH + "leave_request/get_users_on_leave",
        data: {day_leaved: days},
        success: function (response) {

            $select.find('option').each(function () {
                const value = $(this).val();
                if (!value) return;

                const userId = parseInt(value.split('$$$')[0]);
                    if (response.includes(userId)) {
                        $(this).prop('disabled', true).addClass('hidden-option');
                    }
            });
            $select.find(`option[value="${select_usser_id.val()}"]`).prop('disabled', true).hide();
            $select.trigger('change.select2');
        }
    });
}

function formatDataSave() {
    let itemsLeaveRequest = $(".leave-request-item");
    let datas = []
    for (let i = 0; i < itemsLeaveRequest.length; i++) {
        holtype = $(itemsLeaveRequest[i]).find("select[name='holtype']").val();
        holprosdetail_id = $(itemsLeaveRequest[i]).find("input[name='holprosdetail_id']").val();
        date_leave_range = $(itemsLeaveRequest[i]).find("input[name='date_leave_range']").val().split(", ");
        if (date_leave_range.length < 2 ) {
            dtfrom = date_leave_range[0]
            dtto = dtfrom
        } else {
            dtfrom = date_leave_range[0];
            dtto = date_leave_range[1];
        }
        dttotal = $(itemsLeaveRequest[i]).find("input[name='dttotal']").val();
        details = $(itemsLeaveRequest[i]).find("input[name='details']").val();
        handover_receiver = $(itemsLeaveRequest[i]).find("select[name='handover_receiver']").val().join("|||");
        region_type = $(itemsLeaveRequest[i]).find(`input[name='region_type_${i + 1}']:checked`).val();
        country = $(itemsLeaveRequest[i]).find("select[name='issued_place']:not([disabled])").val();
        if (country == null) {
            issued_place = region_type
        }else{
            issued_place = `${country}$$$${region_type}`
        }
        issued_national = $(itemsLeaveRequest[i]).find("textarea[name='issued_national']:not([disabled])").val();
        place_before_hol = $(itemsLeaveRequest[i]).find("textarea[name='place_before_hol']").val();
        note = $(itemsLeaveRequest[i]).find("textarea[name='note']").val();
        holpros_id = $(".holpros_id").val();
        stype = $(".stype").val();
        datas.push({
            id: holprosdetail_id,
            stype: stype,
            sholtype: holtype,
            dtfrom: dtfrom,
            dtto: dtto,
            handover_receiver: handover_receiver,
            details: details,
            issued_place: issued_place, 
            holpros_id: holpros_id,
            itotal: dttotal,
            note: note,
            issued_national: issued_national,
            place_before_hol: place_before_hol,
        });
    }
    return datas;
}
let grouped = {};
const $deptSelect = $('#department-next');
const $userSelect = $('#info-user-next');

let deptIds = 0;
function getInfoUserNext() {
    showLoadding(true);
    stype = $("#stype").val();
    const user_id = $("select[name='user_id']").val() != null ? $("select[name='user_id']").val().split("$$$")[0] : null;
    let params_user_id = check_register_for_user && gon.organization[0] != "BUH" ? user_id : gon.user_id;
    $.ajax({
        type: "GET",
        url: ERP_PATH + `leave_request/fetchStaffForWorkflow`,
        data: {user_id: params_user_id, stype: stype},
        dataType: "JSON",
        success: function (response) {
            if (response.users && response.users.length > 0) {
                if (response.send_to == "TCHC") {
                    $(".lb-user").text("Đơn vị tiếp nhận");
                    $(".error-user").text("Vui lòng chọn đơn vị tiếp nhận.");
                    send_to_tchc = true;
                }else{
                    $(".lb-user").text("Người phê duyệt");
                    $(".error-user").text("Vui lòng chọn người phê duyệt.");
                    send_to_tchc = false    ;
                }

                grouped = {};
                response.users.forEach(item => {
                    if (!grouped[item.department_id]) {
                        grouped[item.department_id] = {
                            department_name: item.department_name,
                            users: []
                        };
                    }
                    if (item.user_id != user_id) {
                        grouped[item.department_id].users.push({ user_id: item.user_id, name: item.name , position_name: item.position_name});
                    }
                });
                deptIds = Object.keys(grouped);

                if (deptIds.length === 1) {
                    $deptSelect.closest("div.mb-3").hide();
                    $deptSelect.prop("disabled", true);
                    const dept = grouped[deptIds[0]];
                    populateUsers(dept.users);
                } else {
                    $deptSelect.closest("div.mb-3").show();
                    $deptSelect.prop("disabled", false);
                    $deptSelect.empty();
                    $userSelect.empty();
                    $deptSelect.append(`<option value="">Chọn phòng/khoa xử lý</option>`);
                    $.each(grouped, (id, dept) => {
                        $deptSelect.append(`<option value="${id}">${dept.department_name}</option>`);
                    });
                }
            }else{
                alert("Không tìm thấy đơn vị xử lý tiếp theo!!!")
                $(".form-create-leave-request").find("input[name='datas'], input[name='commit']").remove();
                $("#form-create-leave-request").show();
            }
            showLoadding(false);
        }
    });
}

$('#department-next').on('change', function () {
    this.setCustomValidity(this.value ? '' : 'Vui lòng chọn người phê duyệt');
    const selectedId = $(this).val();
    $userSelect.empty();
    if (grouped[selectedId]) {
        populateUsers(grouped[selectedId].users);
    }
});

// Hàm tạo option user
function populateUsers(users) {
    
    $userSelect.empty();
    $userSelect.append(`<option value="">${send_to_tchc ? "Chọn người tiếp nhận" : "Chọn người phê duyệt"}</option>`);
    $.each(users, (i, u) => {
        const data = { user_id: u.user_id, department_id: u.department_id };
        $userSelect.append(`<option value='${JSON.stringify(data)}'>${u.name} ${send_to_tchc ? ` - ${u.position_name}` : ""}</option>`);
    });
}

function removeDate(element, index, action = "") {
    const row = $(element).closest('.row');
    const dateStr = row.find('span').text().trim();

    row.remove();
    const rangePicker = $(`#leave-request-${index} input.flatpickr-time-modal[name="date_leave_range"]`);
    const fp = rangePicker.get(0)._flatpickr;
    const dateListContainer = $(`#leave-request-${index} .detail-date-lr`);

    if (fp) {
        let selectedDates = allSelectedDates[index] || [];
        let selectedDateTimes = allSelectedDateTimes[index] || [];
        selectedDates = selectedDates.filter(date => date !== dateStr);
        // selectedDateTimes = selectedDateTimes.filter(date => date !== dateStr);
        selectedDateTimes = selectedDateTimes.filter(([d]) => d !== dateStr);
        
        // Cập nhật allSelectedDates
        if (selectedDates.length > 0) {
            allSelectedDates[index] = selectedDates;
        } else {
            delete allSelectedDates[index];
        }
        if (selectedDateTimes.length > 0) {
            allSelectedDateTimes[index] = selectedDateTimes;
        } else {
            delete allSelectedDateTimes[index];
        }
        // 
        day_time_leave = day_time_leave.filter(item => {
            return !(item.value.split("-")[0] == dateStr && item.index == index);
        });

        // Parse lại danh sách ngày thành đối tượng Date để cập nhật Flatpickr
        const parsedDates = selectedDates.map(date => flatpickr.parseDate(date, "d/m/Y"));
        // Cập nhật Flatpickr
        onRemoveDay = true; 

        fp.set('disable', []); 
        fp.setDate(parsedDates, action == "CANCEL" ? false : true);

        refreshAllPickersDisabled();

        onRemoveDay = false; 

        // Cập nhật giao diện
        if (selectedDates.length === 0) {
            dateListContainer.find("p.text-center").show();
            dateListContainer.find("input[name='details']").val("");
            fp.set("disable", getAllSelectedDatesExcluding(index));
        } else {
            // Cập nhật input[name="details"]
            const detailsInput = dateListContainer.find("input[name='details']");
            const currentDetails = detailsInput.val().split("$$$").filter(item => item);
            const updatedDetails = currentDetails.filter(item => {
                const [date, time] = item.split("-");
                return date !== dateStr;
            });
            detailsInput.val(updatedDetails.join("$$$"));
        }
        
        if (action == "CANCEL"){
            // Cập nhật tổng số ngày
            attachRadioChangeHandler(index);
            // // Cập nhật các Flatpickr khác (disable các ngày đã chọn)
            updateOtherPickers(index);

            updateLeaveDatePagination(index);
        }
    } else {
        console.error(`Không tìm thấy Flatpickr instance cho index ${index}`);
    }
}

function validateionCreate() {
    let isValid = true;
    let scrollTarget = null; // nơi sẽ scroll đến nếu có lỗi
    let stype = $("#stype").val();
    let alertItem = $("#leaveRequestModal .alert-danger");
    $(".leave-request-item").each(function() {
        let index = $(this).data('index');
        let currentItem = $(this);

        let user_id = currentItem.find('select[name="user_id"]').val();
        let dateLeave = currentItem.find('input[name="date_leave_range"]').val();
        let holtype = currentItem.find('select[name="holtype"]').val();
        let holtype_title = currentItem.find('select[name="holtype"] option:selected').text();
        let handoverReceiver = currentItem.find('select[name="handover_receiver"]').val();
        let placeBeforeHol = currentItem.find('textarea[name="place_before_hol"]').val();
        let regionType = currentItem.find(`input[name="region_type_${index}"]:checked`).val();
        let issuedPlace = currentItem.find('select[name="issued_place"]').val();
        let issuedNational = currentItem.find('textarea[name="issued_national"]').val();
        let note = currentItem.find('textarea[name="note"]').val();
        let dttotal = parseFloat(currentItem.find("input[name='dttotal']").val()) || 0;

        handoverReceiver = handoverReceiver.every(u => u.trim() === "");
        if (!user_id && (stype != "ON-LEAVE")) {
            isValid = false;
            alertItem.text("Đơn " + index + ": Vui lòng chọn nhân sự đăng ký nghỉ phép");
            scrollTarget = currentItem.find('select[name="user_id"]');
            scrollTarget.addClass('border border-3 border-danger');
            return false;
        }

        if (!holtype) {
            isValid = false;
            alertItem.text("Đơn " + index + ": Vui lòng chọn loại đơn");
            scrollTarget = currentItem.find('select[name="holtype"]');
            scrollTarget.next('.select2-container').addClass('border border-3 border-danger rounded-2');
            return false;
        }

        if (!dateLeave) {
            isValid = false;
            alertItem.text("Đơn " + index + ": Vui lòng chọn thời gian nghỉ");
            scrollTarget = currentItem.find('input[name="date_leave_range"]');
            scrollTarget.addClass('border border-3 border-danger');
            return false;
        }

        if (handoverReceiver) {
            isValid = false;
            alertItem.text("Đơn " + index + ": Vui lòng chọn người bàn giao công việc");
            scrollTarget = currentItem.find('select[name="handover_receiver"]');
            scrollTarget.next('.select2-container').addClass('border border-3 border-danger rounded-2');
            return false;
        }

        if (regionType == "OUT-COUNTRY") {
            if (!issuedPlace) {
                isValid = false;
                alertItem.text("Đơn " + index + ": Vui lòng chọn quốc gia");
                scrollTarget = currentItem.find('select[name="issued_place"]');
                scrollTarget.next('.select2-container').addClass('border border-3 border-danger rounded-2');
                return false;
            }
            // if (!placeBeforeHol) {
            //     isValid = false;
            //     alertItem.text("Đơn " + index + ": Vui lòng điền địa chỉ nghỉ phép");
            //     scrollTarget = currentItem.find('textarea[name="place_before_hol"]');
            //     scrollTarget.addClass('border border-3 border-danger');
            //     return false;
            // }
            // if (!issuedNational) {
            //     isValid = false;
            //     alertItem.text("Đơn " + index + ": Vui lòng điền địa chỉ lưu trú nước ngoài");
            //     scrollTarget = currentItem.find('textarea[name="issued_national"]');
            //     scrollTarget.addClass('border border-3 border-danger');
            //     return false;
            // }
        } else {
            // if (!placeBeforeHol) {
            //     isValid = false;
            //     alertItem.text("Đơn " + index + ": Vui lòng điền địa chỉ nghỉ phép");
            //     scrollTarget = currentItem.find('textarea[name="issued_national"]');
            //     scrollTarget.addClass('border border-3 border-danger');
            //     return false;
            // }
        }

        if (!placeBeforeHol) {
            isValid = false;
            alertItem.text("Đơn " + index + ": Vui lòng điền địa chỉ nghỉ phép");
            scrollTarget = currentItem.find('textarea[name="place_before_hol"]');
            scrollTarget.addClass('border border-3 border-danger');
            return false;
        }
        if (gon.organization[0] === "BUH" && holtype === "NGHI-CDHH" && dttotal > 3) {
            isValid = false;
            alertItem.text("Đơn " + index + ": Chế độ hiếu/hỉ có tối đa 3 ngày");
            scrollTarget = currentItem.find('input[name="date_leave_range"]');
            scrollTarget.addClass('border border-3 border-danger');
            return false;
        }
        if (!note) {
            isValid = false;
            alertItem.text("Đơn " + index + ": Vui lòng nhập lý do nghỉ phép");
            scrollTarget = currentItem.find('textarea[name="note"]');
            scrollTarget.addClass('border border-3 border-danger');
            return false;
        }
    });
    
    if ($(".leave-request-item").length < 1) {
        isValid = false;
        alertItem.text("Vui lòng chọn loại đơn nghỉ phép");
    }
    if (!isValid) {
        alertItem.show();

        // Scroll đến dòng bị lỗi
        if (scrollTarget) {
            let modalBody = $('.modal-body');
            // Đảm bảo phần tử collapse chứa scrollTarget được mở
            let collapseSection = scrollTarget.closest('.collapse');
            if (collapseSection && !collapseSection.hasClass('show')) {
                collapseSection.collapse('show');
            }

            // Tính vị trí cuộn
            setTimeout(() => {
                let targetOffset = scrollTarget.offset().top - modalBody.offset().top + modalBody.scrollTop() - 30;
                modalBody.animate({ scrollTop: targetOffset }, 600, () => {
                    // Sau khi cuộn hoàn tất (1000ms), đợi thêm 3 giây rồi xóa class
                    setTimeout(() => {
                        $("#leaveRequestModal select, #leaveRequestModal input, #leaveRequestModal textarea, #leaveRequestModal .select2-container").removeClass("border border-3 border-danger");
                    }, 3000);
                });
            }, 300);
        }
    } else {
        alertItem.hide();
        $("#leaveRequestModal select, #leaveRequestModal input, #leaveRequestModal textarea, #leaveRequestModal .select2-container").removeClass("border border-3 border-danger");
    }
    return isValid;
}

const selector = '.tarea-place-before-hol, #note';
let t;

function sanitize(el){
    el.value = (el.value || '')
        .normalize('NFC')
        .replace(/[^\p{L}\p{M}\d ,\.:()\-\s]+/gu, '');
}

$(document).on('input', selector, function(e){
    if (e.originalEvent?.isComposing) return;
    clearTimeout(t);
    const el = this;
    t = setTimeout(() => sanitize(el), 100);
}).on('compositionend', selector, function(){
    sanitize(this);
});

// push value into details
function getSelectedRadioDetailValues(index) {
    const selectedValues = [];
    // Duyệt qua tất cả fieldset trong .detail-date-lr
    $(`.detail-date-lr fieldset[data-index='${index}']`).each(function() {
        const selectedRadio = $(this).find("input[type='radio']:checked");
        if (selectedRadio.length) {
            selectedValues.push(selectedRadio.val());
        }
    });
    return selectedValues.join("$$$");
}
// Hàm tính số ngày nghỉ
function calculateLeaveValues(index) {
    const results = {
        details: [], //chưa sử dụng =))
        total: 0
    };

    $(`.detail-date-lr fieldset[data-index='${index}']`).each(function() {
        const selectedRadio = $(this).find("input[type='radio']:checked");
        if (selectedRadio.length) {
            const value = selectedRadio.val();
            const [date, period] = value.split("-");
            let leaveValue = period === "ALL" ? 1 : 0.5;
            results.details.push({ date, period, value: leaveValue });
            results.total += leaveValue;
        }
    });

    return results;
}
// push value into dttotal
function attachRadioChangeHandler(index) {
    day_time_leave.filter(item => item.index == 1).forEach(({ value, index }) => {
        $(`fieldset[data-index='${index}'] input[value='${value}']`).prop("checked", true);
        let value_split = value.split("-")
        // Cập nhật buổi của ngày nghỉ
        // 
        var dateTime = allSelectedDateTimes[index].find(item => item[0] === value_split[0])

        // Nếu tìm thấy thì cập nhật buổi
        if (dateTime) {
            dateTime[1] = value_split[1];
        }
    });
    const total = calculateLeaveValues(index).total;
    const details = getSelectedRadioDetailValues(index);
    currentForm = $(`.leave-request-item[data-index="${index}"]`)
    currentForm.find("input[name='dttotal']").val(total);
    currentForm.find("input[name='details']").val(details);
}

function changeTimeLeave(input, index) {
    day_time_leave = day_time_leave.filter(item => item.index !== index);

    $(`fieldset[data-index='${index}'] input:checked`).each(function () {
        const value = $(this).val();
        day_time_leave.push({ value, index });
    });

    // Cập nhật tổng số ngày nghỉ
    attachRadioChangeHandler(index);

    // Cập nhật allSelectedDateTimes cho index này
    updateAllSelectedDateTimes(index);

    // Cập nhật các Flatpickr khác (disable các ngày đã chọn)
    updateOtherPickers(index);
    //
    validLeaveChoosed();
}
function updateAllSelectedDateTimes(index) {
    // Lấy danh sách ngày đã chọn cho index này
    const selectedDates = allSelectedDates[index] || [];
    // Lấy tất cả radio đã chọn trong các fieldset của index này
    const dateTimes = [];
    $(`.detail-date-lr fieldset[data-index='${index}']`).each(function() {
        const selectedRadio = $(this).find("input[type='radio']:checked");
        if (selectedRadio.length) {
            const value = selectedRadio.val();
            const [date, time] = value.split("-");
            dateTimes.push([date, time]);
        }
    });
    // if (check_register_for_user) {
    //     filteredDateTimes = allUserSelectedDateTimes
    // }else{
    //     filteredDateTimes = allSelectedDateTimes
    // }
    allSelectedDateTimes[index] = dateTimes;
}
// Khi thay đổi option issued_place(select) Trong nước - Ngoài nước
function onShowIssuePlace(select, index) {
    let currentForm = $(`.leave-request-item[data-index="${index}"]`)
    if (select.value == "IN-COUNTRY") {
        // currentForm.find(".lb-note").html("Lý do<span class='text-danger'>*</span>");
        currentForm.find(".issued_national").closest(".row").hide();
        currentForm.find(".issued_national, .country-select").prop("disabled", true);
        // currentForm.find(".content-issue-place-sel").removeClass("col-6").addClass("col-12");
        currentForm.find(".content-country-sel").hide();
        // currentForm.find(".tarea-place-before-hol").closest("div.row.mb-3").show();
        // currentForm.find("#place_before_hol").attr("placeholder", "Nhập địa chỉ nghỉ phép");
        // currentForm.find(".lb-place-before-hol").html("Địa chỉ nghỉ phép<span class='text-danger'>*</span>");
        $(".label-alert").hide();
    }else{
        $(".label-alert").show();
        // currentForm.find(".lb-note").html("Mục đích đi nước ngoài<span class='text-danger'>*</span>");
        currentForm.find(".issued_national").closest(".row").show();
        currentForm.find(".content-country-sel").show();
        currentForm.find(".issued_national, .country-select").prop("disabled", false);
        // currentForm.find(".content-issue-place-sel").removeClass("col-12").addClass("col-6");
        // currentForm.find(".tarea-place-before-hol").closest("div.row.mb-3").hide();
        // currentForm.find("#place_before_hol").attr("placeholder", "Nhập địa chỉ trước khi xuất cảnh");
        // currentForm.find(".lb-place-before-hol").html("Địa chỉ trước khi xuất cảnh<span class='text-danger'>*</span>");
    }
}
function getHoltypeSelected(select,index) {
    let nameHoltype = $(select).find("option:selected").text();
    $(`.holtype-title-${index}`).text(nameHoltype);
    validLeaveChoosed();
    // disabledOptionHoltype()
}
function getDayLeave(input, index) {
    let value = input.value;
    $(`.day-leave-${index}`).text(value);
}
function disabledOptionHoltype() {
    let selects = $(".leave-request-item select[name='holtype']")
    let selectedValues = selects.map(function() {
        return $(this).val();
    }).get().filter(code => code); // lọc bỏ giá trị rỗng
    
    selects.each(function() {
        let $select = $(this);
        let currentValue = $select.val();
        $select.find('option').each(function() {
            let $option = $(this);
            if ($option.val() === "" || $option.val() === currentValue) {
                $option.prop('disabled', false);
            } else if (selectedValues.includes($option.val())) {
                $option.prop('disabled', true);
            } else {
                $option.prop('disabled', false);
            }
        });
    });
}

function getDateRangeArray(start, end) {
    const dateArray = [];
    const currentDate = new Date(start);
    while (currentDate <= end) {
        dateArray.push(new Date(currentDate));
        currentDate.setDate(currentDate.getDate() + 1);
    }
    return dateArray;
}

function diffYMD(startStr) {
    // startStr dạng "dd/mm/yyyy" hoặc "yyyy-mm-dd"
    let start;
    let parts;
    if (startStr.includes("/")) {
        parts = startStr.split("/").map(Number);
        // Nếu năm có 4 chữ số ở đầu, parse dạng yyyy/mm/dd
        if (parts[0] > 1000) {
            start = new Date(parts[0], parts[1] - 1, parts[2]);
        }
    }
    const now = new Date();

    let years = now.getFullYear() - start.getFullYear();
    let months = now.getMonth() - start.getMonth();
    let days = now.getDate() - start.getDate();

    if (days < 0) {
        months -= 1;
        // Số ngày trong tháng trước của now
        let prevMonth = new Date(now.getFullYear(), now.getMonth(), 0);
        days += prevMonth.getDate();
    }
    if (months < 0) {
        years -= 1;
        months += 12;
    }


    return { years, months, days, parts};
}

function calculateDaysOffMonth() {
    const diff = diffYMD(gon.dtfrom_contract);
    current_month = new Date().getMonth() + 1;

    let diffYear = diff.years
    let diffMonth = diff.months
    let diffDay = diff.days
    let partsDay = diff.parts //year - month - day
    // Nhân sự làm việc trên 1 năm hoặc nhân sự làm từ năm cũ sang năm mới tính là 1 năm
    if (diffYear > 0 || current_year_leave - partsDay[0] > 0) {
        // số phép 
        leave_year = Math.round((total_annual_leave / 12) * current_month);
    } else {
        // Lấy ngày trong tháng của dtfrom
        // nhân sự làm 
        if (partsDay[2] > 15) {
            yearLeaveCalculaTime = 12 - partsDay[1]
            timeAllowedMonth = current_month - partsDay[1]
        } else {
            yearLeaveCalculaTime = 12 - partsDay[1] + 1
            timeAllowedMonth = current_month - partsDay[1] + 1
        }
        leave_year = Math.round((gon.dayleave_of_pjob / yearLeaveCalculaTime) * timeAllowedMonth);
    }
    // số phép được sử dụng đến tháng hiện tại
    leave_remaining = leave_year - leave_taken;
    // số phép được ứng
    leave_advanced = (total_annual_leave - leave_taken) * 25 / 100;
    // Làm tròn đến số nguyên gần nhất
    leave_advanced = Math.round(leave_advanced);

    if (leave_remaining < 0) {
        leave_advanced = 0;
    }

    total_leave = leave_remaining + leave_advanced

    remain_amount = 0;

    let dom_info_leave = ""

    if (gon.organization != "BUH") {
        $(".render-day-leave, .render-day-advance").addClass("d-none");
        $(".lr-action").attr("style","height: unset");
        // Phép tồn
        dom_info_leave += renderDomInfoLeave(`Phép tồn ${current_year_leave - 1 }`, gon.remain_amount);
        // Phép năm
        dom_info_leave += renderDomInfoLeave(`Phép năm ${current_year_leave}`, gon.total_leave);
        // Phép thâm niên
        dom_info_leave += renderDomInfoLeave(`Phép thâm niên`, gon.seniority_amount);
        // Phép đã sử dụng
        dom_info_leave += renderDomInfoLeave(`Phép đã sử dụng`, leave_taken);
        // Phép còn lại tính đến tháng
        dom_info_leave += renderDomInfoLeave(`Phép còn lại`, gon.holiday_used + gon.remain_amount);
    }else{
        // Phép tồn
        dom_info_leave += renderDomInfoLeave(`Phép tồn ${current_year_leave - 1 }`, gon.remain_amount);
        // Phép năm
        dom_info_leave += renderDomInfoLeave(`Phép năm ${current_year_leave}`, gon.dayleave_of_pjob);
        // Phép thâm niên
        dom_info_leave += renderDomInfoLeave(`Phép thâm niên`, gon.seniority_amount);
        // Phép đã sử dụng
        dom_info_leave += renderDomInfoLeave(`Phép đã sử dụng`, leave_taken);
        // Phép còn lại tính đến tháng
        // dom_info_leave += renderDomInfoLeave(`Phép còn lại tính đến tháng ${current_month}`, leave_remaining < 0 ? 0 : customRound(leave_remaining));
        // dom_info_leave += renderDomInfoLeave(`Phép còn lại tính đến tháng ${current_month}`, gon.dayleave_of_pjob + gon.seniority_amount - leave_taken);
        dom_info_leave += renderDomInfoLeave(`Phép còn lại tính đến tháng ${current_month}`, leave_remaining);
        // Phép được ứng tối đa
        // dom_info_leave += renderDomInfoLeave(`Phép được ứng tối đa`, leave_advanced < 0 ? 0 : customRound(leave_advanced));
        dom_info_leave += renderDomInfoLeave(`Phép được ứng tối đa`, leave_advanced < 0 ? 0 : leave_advanced);
    }
    $(".info-leave-controller").html(dom_info_leave)
}

function renderDomInfoLeave(title, amount) {
    return `<div class="d-flex justify-content-between align-items-center mb-3">
                <span class="text-dark col-8">${title}</span>
                <span class="col-1 me-auto"></span>
                <span class="text-dark">${amount} ngày</span>
            </div>`;
}

function customRound(number) {
    const integerPart = Math.floor(number);
    const decimalDigit = Math.floor((number - integerPart) * 10); 

    if (decimalDigit < 5) {
        return integerPart;
    } else if (decimalDigit === 5) {
        return Math.floor(number * 10) / 10;
    } else {
        return integerPart + 1;
    }
}

// end functions proccess
// config 
// Hàm khởi tạo Flatpickr
// Dùng cho range
let isAutoSelectingRange = false;
function initializeFlatpickr(index) {
    const rangePicker = $(`#leave-request-${index} input.flatpickr-time-modal[name="date_leave_range"]`);
    const dateListContainer = $(`#leave-request-${index} .detail-date-lr`);
    if (!rangePicker.length) {
        console.warn(`Không tìm thấy rangePicker cho index ${index}. Kiểm tra DOM.`);
        return;
    }

    const existingInstance = rangePicker.data('flatpickrInstance');
    if (existingInstance) {
        existingInstance.destroy();
    }
    const now = new Date();
    const hour = now.getHours();



    const fp = rangePicker.flatpickr({
        mode: "multiple",
        dateFormat: "d/m/Y",
        altFormat: "F Y",
        locale: "vn",
        minDate:  hour >= 19 || (hour > svalue_leave_pm && gon.organization != "BUH") ? new Date().fp_incr(1) : "today",
        monthSelectorType: "dropdown",
        showMonths: 1,
        yearSelectorType: "dropdown",
        onChange: function(selectedDates, dateStr, instance) {            
            // Không chọn gì (clear)
            if (selectedDates.length === 0) {
                delete allSelectedDates[index];
                delete allSelectedDateTimes[index];
                $(`#leave-request-${index} #dttotal`).val(0);
                // Cập nhật UI (xóa rồi append lại)
                dateListContainer.find("div.row").remove();
                dateListContainer.find("p.text-center").hide();
                updateOtherPickers(index);
                isAutoSelectingRange = false;
                prevSelectedDatesByIndex[index] = []; 
                return;
            }

            const prevDates = prevSelectedDatesByIndex[index] || [];
            const currDates = selectedDates.map(d => moment(d).format("DD/MM/YYYY"));
            const isRemoving = currDates.length < prevDates.length;

            let daysInRange = [];

            // Nếu chỉ chọn 1 ngày
            if (selectedDates.length === 1) {
                daysInRange = [moment(selectedDates[0])];
                isAutoSelectingRange = false;
            // Nếu chọn đúng 2 ngày, fill range
            // onRemoveDay kiểm tra true nghĩa là xóa thì không cần chạy vô đây
            } else if (selectedDates.length === 2 && !isAutoSelectingRange && !onRemoveDay && prevDates.length === 1) {
                let [start, end] = selectedDates.map(d => moment(d)).sort((a, b) => a - b);
                delete allSelectedDates[index];
                delete allSelectedDateTimes[index];
                daysInRange = getValidDatesInRange(start, end, index);
                // Nếu range thực sự khác selectedDates ban đầu, set lại
                if (daysInRange.length !== 2 || !daysInRange[0].isSame(moment(selectedDates[0]), 'day') || !daysInRange[1].isSame(moment(selectedDates[1]), 'day')
                ) {
                    // instance.setDate(daysInRange.map(d => d.toDate()));
                    instance.setDate(daysInRange.map(d => d.toDate()), false);
                }

            // Nếu chọn nhiều hơn 2 ngày, giữ nguyên các ngày đang chọn, thêm ngày vừa click
            } else {
                isAutoSelectingRange = true;
                daysInRange = selectedDates.map(d => moment(d));
            }

            const occupied = buildOccupiedMap(index);

            // Cập nhật AM/PM/ALL cho từng ngày
            // let newSelectedDateTimes = daysInRange.map(d => {
            //     const formattedDate = d.format("DD/MM/YYYY");
            //     const existingEntry = allSelectedDateTimes[index]?.find(entry => entry[0] === formattedDate);
            //     if (existingEntry) {
            //         return [formattedDate, existingEntry[1]];
            //     } else {
            //         let defaultTime = "ALL";
            //         // if (hour > svalue_leave_am && gon.organization != "BUH" && d.isSame(moment(new Date()), 'day')) {
            //         //     defaultTime = "PM";
            //         // }else if (hour < svalue_leave_am && gon.organization != "BUH" && d.isSame(moment(new Date()), 'day')) {
            //         //     defaultTime = "ALL";
            //         // } 
            //         for (let otherIndex in allSelectedDateTimes) {
            //             if (otherIndex != index) {
            //                 const otherEntry = allSelectedDateTimes[otherIndex]?.find(entry => entry[0] === formattedDate);
            //                 if (otherEntry) {
            //                     defaultTime = otherEntry[1] === "AM" ? "PM" : "AM";
            //                     break;
            //                 }
            //             }
            //         }
            //         return [formattedDate, defaultTime];
            //     }
            // });
            let newSelectedDateTimes = daysInRange.map(d => {
                const formattedDate = d.format("DD/MM/YYYY");
                const existingEntry = allSelectedDateTimes[index]?.find(entry => entry[0] === formattedDate);

                if (existingEntry) {
                    return [formattedDate, existingEntry[1]];
                }

                const occ = occupied[formattedDate] || { AM: false, PM: false };

                let defaultTime = "ALL";
                if (occ.AM && !occ.PM) defaultTime = "PM";
                else if (!occ.AM && occ.PM) defaultTime = "AM";
                else defaultTime = "ALL";

                return [formattedDate, defaultTime];
            });
            allSelectedDateTimes[index] = newSelectedDateTimes;

            // Cập nhật UI (xóa rồi append lại)
            dateListContainer.find("div.row").remove();
            dateListContainer.find("p.text-center").hide();

            // Cập nhật allSelectedDates
            allSelectedDates[index] = daysInRange.map(d => d.format("DD/MM/YYYY"));

            let dateList = "";
            daysInRange.forEach((date, i) => {
                let is_disable_checkbox = {};
                if (date.isSame(moment(new Date()), 'day') && gon.organization != "BUH") {
                    // switch (newSelectedDateTimes[i][1]) {
                    //     case "AM":
                    //         is_disable_checkbox.PM = true;
                    //         is_disable_checkbox.ALL = true;
                    //         break;
                    //     case "PM":
                    //         is_disable_checkbox.AM = true;
                    //         is_disable_checkbox.ALL = true;
                    //         break;
                    // }
                    is_disable_checkbox[newSelectedDateTimes[i][1]] = false;
                }
                dateList += renderListDays(date.format("DD/MM/YYYY"), newSelectedDateTimes[i][1], index, "", [],  is_disable_checkbox);
            });
            dateListContainer.append(dateList);
            attachRadioChangeHandler(index);

            get_users_on_leave(allSelectedDates[index], index);
            updateOtherPickers(index);
            updateLeaveDatePagination(index);
            validLeaveChoosed();
            onRemoveDay = false; 
            prevSelectedDatesByIndex[index] = allSelectedDates[index] || [];
        },
        onReady: function(selectedDates, dateStr, instance) {
            const clearBtn = document.createElement("button");
            clearBtn.type = "button";
            clearBtn.className = "flatpickr-clear-btn btn btn-secondary mt-2";
            clearBtn.textContent = "Hủy";
            clearBtn.style.cursor = "pointer";
            clearBtn.style.float = "right";
            const acceptBtn = document.createElement("button");
            acceptBtn.type = "button";
            acceptBtn.className = "flatpickr-clear-btn btn btn-primary mt-2";
            acceptBtn.textContent = "Xác nhận";
            acceptBtn.style.cursor = "pointer";
            acceptBtn.style.float = "right";

            clearBtn.addEventListener("click", function () {
                instance.clear();
                delete allSelectedDates[index];
                delete allSelectedDateTimes[index];
                updateOtherPickers(index);
                updateLeaveDatePagination(index);
                instance.set("disable", getAllSelectedDatesExcluding(index, dates_leave_edit).map(date => flatpickr.parseDate(date, "d/m/Y")));
                dateListContainer.find("p.text-center").show();
                dateListContainer.find("div.row").remove();
                $(`#leave-request-${index} #dttotal`).val(0);
                $(`#leave-request-${index} input[name="date_leave_range"].flatpickr-time-modal`).val("");
                $(`#leave-request-${index} #dttotal`).val(0);

            });

            acceptBtn.addEventListener("click", function () {
                instance.close();
            });

            instance.calendarContainer.appendChild(acceptBtn);
            instance.calendarContainer.appendChild(clearBtn);
        }
        
    });

    rangePicker.data('flatpickrInstance', fp);
}

// Lấy các ngày đã chọn ở các index khác làm disabled
function getSelectDateTimes(daysInRange, index) {
    
}
function getValidDatesInRange(start, end, index) {
    const disabledDates = getAllSelectedDatesExcluding(index);

    let dates = [];
    let curr = moment(start);
    let last = moment(end);
    while (curr <= last) {
        let dateStr = curr.format("DD/MM/YYYY");
        if (!disabledDates.includes(dateStr)) {
            dates.push(curr.clone());
        }
        curr.add(1, 'days');
    }
    return dates;
}

// Hàm khởi tạo Select2
function initializeSelect2(index) {
    const selectors = [
        `#leave-request-${index} .sel_user_request`,
        `#leave-request-${index} .sel-holtype`,
        `#leave-request-${index} .sel-handover-receiver`,
        `#leave-request-${index} .country-select`,
    ];

    selectors.forEach(selector => {
        const selectElement = $(selector);
        if (selectElement.length) {
            if (selectElement.hasClass("select2-hidden-accessible")) {
                selectElement.select2('destroy');
            }
            selectElement.select2({
                width: '100%',
                dropdownParent: $('#leaveRequestModal'),
                theme: "bootstrap-5",
                placeholder: selectElement.attr("placeholder"),
            });
        }
    });
}
// form type info leave 
function formCreateLeaveRequest(index) {
    return `
        <div class="border border-2 rounded-3 p-2 mb-2 leave-request-item" data-index="${index}" id="">
            <input type="hidden" name="holprosdetail_id" id="holprosdetail_id" value="">
            <div class="d-flex justify-content-between align-items-center me-1">
                <div class="d-flex align-items-center col-5">
                    <a class="ms-1" data-bs-toggle="collapse"  href="#leave-request-${index}" role="button" aria-expanded="true" aria-controls="leave-request-${index}">
                        <span class="fas fa-caret-right rotate-icon text-black" ></span>
                    </a>
                    <label class="holtype-title-${index} mb-0 ms-2"></label>
                </div>
                <div class="d-flex align-items-center justify-content-end col-7 ">
                    <p class="day-leave-${index} mb-0 d-none"></p>
                    <span class="far fas fa-times text-danger float-end remove-leave-request ms-3 cursor-pointer" data-index="${index}"></span>
                </div>
            </div>
            <div class="collapse show mt-3" id="leave-request-${index}">
                <!-- Nhân sự -->
                <div class="mb-2 user_request" style="display: none;">
                    <label class="form-label">Nhân sự <span class="text-danger">*</span></label>
                    <div>
                        <select class="selectpicker form-select sel_user_request" data-index="${index}" placeholder="Chọn nhân sự đăng ký nghỉ thay" name="user_id">
                        </select>
                    </div>
                </div>
                
                <!-- Chọn loại đơn -->
                <div class="mb-2">
                    <label for="formGroupExampleInput" class="form-label">Loại đơn <span class="text-danger">*</span></label>
                    <select class="form-select selectpicker sel-holtype" placeholder="Chọn loại đơn" onchange="getHoltypeSelected(this, ${index})" name="holtype" id="">
                    </select>
                </div>

                <!-- Chọn ngày nghỉ -->
                <div class="d-flex flex-column flex-lg-row mb-2">
                    <div class="col-12 col-lg-9 pe-lg-3 mb-2 mb-lg-0">
                        <label class="form-label">Thời gian nghỉ dự kiến <span class="fas fa-exclamation-circle"></span></label>
                        <input type="text" placeholder="Chọn thời gian nghỉ dự kiến" onchange="getDayLeave(this, ${index})" id="" name="date_leave_range" class="form-control flatpickr-time-modal">
                    </div>
                    <div class="col-12 col-lg-3">
                        <label class="form-label text-center">Tổng số ngày</label>
                        <input type="text" id="dttotal" name="dttotal" class="custom-input" readonly value="0">
                    </div>
                </div>
                <div class="mb-2">
                    <label for="">Chọn thời gian nghỉ trong ngày</label>
                    <div class="detail-date-lr rounded-2 p-2 bg-thead">
                        <input type="hidden" name="details" id="details" value="">
                        <p class="text-center mb-0"><i>Vui lòng chọn ngày để hiện thị tùy chọn buổi nghỉ</i></p>
                    </div>
                    <div class="leave-date-pagination" data-index="${index}"></div>
                </div>

                <!-- Cá nhân hỗ trợ công việc -->
                <div class="mb-2">
                    <label class="form-label">Người bàn giao công việc <span class="text-danger">*</span></label>
                    <div>
                        <select class="selectpicker form-select sel-handover-receiver" data-index="${index}" placeholder="Chọn người bàn giao", name="handover_receiver" multiple id="">
                        </select>
                    </div>
                </div>

                <!-- Place & country -->
                <div class="row gx-0 align-items-center mb-2 place-countries-controller">
                    <div class="content-issue-place-sel pe-0 pe-lg-2 col-12 col-lg-6 mb-2 mb-lg-0">
                        <label class="form-label col-auto me-auto me-lg-0">Địa điểm <span class="text-danger">*</span></label>
                        <div class="d-flex flex-row gap-3 align-items-start">
                            <div class="form-check mb-0">
                                <input class="form-check-input" type="radio" name="region_type_${index}" onchange="onShowIssuePlace(this, ${index})" id="region-type-in-${index}" checked value="IN-COUNTRY">
                                <label class="form-check-label mb-0 fw-normal" for="region-type-in-${index}">Trong nước</label>
                            </div>
                            <div class="form-check mb-0">
                                <input class="form-check-input" type="radio" name="region_type_${index}" onchange="onShowIssuePlace(this, ${index})" id="region-type-out-${index}" value="OUT-COUNTRY">
                                <label class="form-check-label mb-0 fw-normal" for="region-type-out-${index}">Nước ngoài</label>
                            </div>
                        </div>
                    </div>
                    <div class="col-12 col-lg-6 content-country-sel ps-0 ps-lg-2" style="display: none;">
                        <label class="form-label">Quốc gia <span class="text-danger">*</span></label>
                        <div>
                            <select class="form-select selectpicker country-select" placeholder="Chọn quốc gia" name="issued_place" id="">
                            </select>
                        </div>
                    </div>
                </div>
                ${isBUH ? '' : '<label class="label-alert" style="display:none;"><em class="fs--1 text-500">Lưu ý: Khi đơn xin nghỉ đi nước ngoài được duyệt, bạn cần in đơn và gửi về Phòng Tổ chức - Hành chính để lưu hồ sơ</em></label>'}


                <!-- Địa chỉ trước khi xuất cảnh || Địa chỉ nghỉ phép -->
                <div class="row mb-3">
                    <div class="col-12">
                        <label class="form-label lb-place-before-hol">Địa chỉ nghỉ phép <span class="text-danger">*</span></label>
                        <textarea class="form-control  tarea-place-before-hol" placeholder="Nhập địa chỉ nghỉ phép" name="place_before_hol" style="height: 100px"></textarea>
                    </div>
                </div>
                <!-- Địa chỉ lưu trú nước ngoài -->
                <div class="row mb-3 d-none">
                    <div class="col-12">
                        <label class="form-label">Địa chỉ lưu trú nước ngoài <span class="text-danger">*</span></label>
                        <textarea class="form-control issued_national" placeholder="Nhập địa chỉ lưu trú nước ngoài" name="issued_national" style="height: 100px"></textarea>
                    </div>
                </div>

                <!-- Lý do nghỉ -->
                <div class="row">
                    <div class="col-12">
                        <label class="form-label lb-note">Lý do <span class="text-danger">*</span></label>
                        <textarea class="form-control" placeholder="Nhập lý do nghỉ" name="note" id="note" style="height: 100px"></textarea>
                    </div>
                </div>
                <label class="d-none"><em class="fs--1 text-500">Lưu ý: Mục Lý do cần ghi rõ cả lý do và địa điểm nghỉ phép</em></label>
                
                <!-- priority -->
                <div class="d-flex align-items-center d-none">
                    <label class="form-label col-2">Mức độ <span class="text-danger">*</span></label>
                    <div class="d-flex gap-3 align-items-center">
                        <div class="form-check">
                            <input class="form-check-input" type="radio" name="priority" id="priority-normal" checked value="NORMAL">
                            <label class="form-check-label mb-0" for="priority-normal">Bình thường</label>
                        </div>
                        <div class="form-check">
                            <input class="form-check-input" type="radio" name="priority" id="priority-urgent" value="URGENT">
                            <label class="form-check-label mb-0" for="priority-urgent">Khẩn cấp</label>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    `
}
// form detail holpros
function itemHolprosdetail(data) {
    details = data.details.split("$$$") // Tách thành mảng các chuỗi
            .sort((a, b) => {
                // Chuyển đổi định dạng ngày dd/mm/yyyy thành đối tượng Date để so sánh
                const dateA = new Date(a.split("-")[0].split("/").reverse().join("-"));
                const dateB = new Date(b.split("-")[0].split("/").reverse().join("-"));
                return dateA - dateB; // Sắp xếp tăng dần
            })
            .map(detail => `<p class="mb-0 text-black">${detail.split("-")[0]} (${detail.split("-")[1] == "ALL" ? "Cả ngày" : detail.split("-")[1] == "AM" ? "Sáng" : detail.split("-")[1] == "PM" ? "Chiều" : ""})</p>`)
            .join("");
    if (data.region_type == "IN-COUNTRY") {
        title_place_before_hol = "Địa chỉ nghỉ phép"
        region_type = "Trong nước"
        hidden = "d-none"
    } else {
        title_place_before_hol = "Địa chỉ trước khi xuất cảnh"
        region_type = "Nước ngoài"
        hidden = ""
    }

    return `
    <div class="mt-3">
        <div class="col-6 mb-3 mt-1">
            <input type="text" id="dttotal" name="dttotal" class="custom-input" readonly value="${data.holstype || "" }">
        </div>
        <div class="row gx-0 mb-3 d-none">
            <p class="col-4 mb-0">Đơn nghỉ phép của nhân sự:</p>
            <div class="col-8 ps-3">
                <p class="mb-0 text-black">${data.full_name}</p>
            </div>
        </div>
        <div class="row gx-0 mb-3">
            <p class="col-4 mb-0">Thời gian nghỉ:</p>
            <div class="col-8 ps-3">
                <p class="mb-0 text-black d-none">${moment(data.dtfrom).format("DD/MM/YYYY")} - ${moment(data.dtto).format("DD/MM/YYYY")}</p>
                ${details}
            </div>
        </div>
        <div class="row gx-0 mb-3">
            <p class="col-4 mb-0">Cá nhân hỗ trợ công việc:</p>
            <div class="col-8 ps-3">
                ${data.handover_receiver == null || data.handover_receiver == ""  ? "" : data.handover_receiver.split("|||").map(user => `<p class="mb-0 text-black">${user.split("$$$")[1]}</p>`).join("")}
            </div>
        </div>
        <div class="row gx-0 mb-3">
            <p class="col-4 mb-0">Địa điểm:</p>
            <p class="mb-0 col-8 ps-3 text-black">${region_type}</p>
        </div>
        <div class="row gx-0 mb-3 ${hidden}">
            <p class="col-4 mb-0">Quốc gia:</p>
            <p class="mb-0 col-8 ps-3 text-black">${data.issued_place || ""}</p>
        </div>
        <div class="row gx-0 mb-3">
            <p class="col-4 mb-0">Địa chỉ nghỉ:</p>
            <p class="mb-0 col-8 ps-3 text-black">${data.place_before_hol || ""}</p>
        </div>
        <div class="row gx-0 mb-3 d-none">
            <p class="col-4 mb-0">Địa chỉ lưu trú nước ngoài:</p>
            <p class="mb-0 col-8 ps-3 text-black">${data.issued_national || ""}</p>
        </div>
        <div class="row gx-0 mb-3">
            <p class="col-4 mb-0">Lý do:</p>
            <p class="mb-0 col-8 ps-3 text-black">${data.note || ""}</p>
        </div>
    </div>`;
}
// 
function renderFormProcessHandle(mandoc_id, status) {
    title = status.includes("CANCEL") ? "Quy trình duyệt hủy" : "Quy trình duyệt"
    return `
        <div class="rounded-3 p-4 mt-4 ms-xl-3 position-relative" style="background-color: #F9FAFB;">
            <h5 class="text-center cursor-pointer position-absoute top-0 start-0"
            data-bs-toggle="collapse" 
            data-bs-target="#render-process-handle-${mandoc_id}" 
            aria-expanded="true"aria-controls=" 
            render-process-handle-${mandoc_id}"
            style="cursor:pointer;">
                ${title}
            </h5>
            <div class="collapse show" id="render-process-handle-${mandoc_id}">
                <div class="d-flex collapse show" style="background-color: #FFF;" >
                    <div class="timeline-vertical render-process-handle-${mandoc_id} col-12">
                    </div>
                </div>
            </div>
        </div>
    `
}
// form user handle process
function itemStepHandle(time, title_step, users,status) {
    day = time[0]
    time = time[1]
    check_status = status == "DAXULY" ? "done" : "notdone"
    return `
        <div class="timeline-item timeline-item-${check_status} timeline-item-end">
            <div class="timeline-icon timeline-icon-${check_status}"></div>
            <div class="row align-items-center">
                <div class="col-lg-5 timeline-item-time justify-content-start mt-lg-2">
                    <div>
                        <p class="fs-10 mb-0 fw-semi-bold">${day}</p>
                        <p class="fs-11 text-600">${time}</p>
                    </div>
                </div>
                <div class="col-lg-7 mx-3 mx-lg-0 px-3">
                    <div class="">
                        <h5 class="mb-2">${title_step}</h5>
                        ${users.map(({user_name, position_name}) => `<p class="fs-10 mb-0">${user_name} ${position_name == null ? "" : `(${position_name})`}</p>`).join("")}
                    </div>
                </div>
            </div>
        </div>
    `
}
// Chọn khoảng ngày hiện thị chi tiết
function renderListDays(day, time, index, action = "", valid_days = [], is_disable_checkbox = {}) {
    
    check_day = valid_days.includes(day) || valid_days.length < 1
    return `<div class="row align-items-center justify-content-between justify-content-sm-center gx-0">
                <span class="far fas fa-times text-danger col-auto col-sm-1 me-2 me-sm-0 ${check_day ? '' : 'd-none'}" onclick="removeDate(this, ${index}, '${action}')"></span>
                <span class="col-auto col-sm-2 ps-md-3 me-auto">${day}</span> 
                <fieldset data-index="${index}" class="col-auto col-sm-9 d-flex justify-content-end mt-2 mt-sm-0" id="group_${index}_${day.replace(/\//g, "")}">
                    <div class="col-auto col-sm-4 me-1 mx-sm-0 text-center">
                        <input class="form-check-input" ${action == "CANCEL" && (time == "AM" || time == "PM") || is_disable_checkbox?.ALL ? 'disabled data-disabled="true"' : 'data-disabled="false"'} onchange="changeTimeLeave(this, ${index})" type="radio" name="group_${index}_${day.replace(/\//g, "")}" id="${day.replace(/\//g, "")}-${index}-ALL" value="${day}-ALL" ${time == 'ALL' ? 'checked' : ''}>
                        <label class="form-check-label" for="${day.replace(/\//g, "")}-${index}-ALL">Cả ngày</label>
                    </div>
                    <div class="col-auto col-sm-4 mx-1 mx-sm-0 text-center">
                        <input class="form-check-input" ${action == "CANCEL" && !check_day || is_disable_checkbox?.AM ? 'disabled data-disabled="true"' : 'data-disabled="false"'} onchange="changeTimeLeave(this, ${index})" type="radio" name="group_${index}_${day.replace(/\//g, "")}" id="${day.replace(/\//g, "")}-${index}-AM" value="${day}-AM" ${time == 'AM' ? 'checked' : ''}>
                        <label class="form-check-label" for="${day.replace(/\//g, "")}-${index}-AM">Sáng</label>
                    </div>
                    <div class="col-auto col-sm-4 mx-1 mx-sm-0 text-center">
                        <input class="form-check-input" ${action == "CANCEL" && !check_day || is_disable_checkbox?.PM ? 'disabled data-disabled="true"' : 'data-disabled="false"'} onchange="changeTimeLeave(this, ${index})" type="radio" name="group_${index}_${day.replace(/\//g, "")}" id="${day.replace(/\//g, "")}-${index}-PM" value="${day}-PM" ${time == 'PM' ? 'checked' : ''}>
                        <label class="form-check-label" for="${day.replace(/\//g, "")}-${index}-PM">Chiều</label>
                    </div>
                </fieldset>
            </div>`;
}

function renderOptionUsers(datas, element, index) {
    const leaveRequestItem = document.querySelector(`.leave-request-item[data-index="${index}"]`);
    if (!leaveRequestItem) return;

    const select = leaveRequestItem.querySelector(`select[name="${element}"]`);
    if (!select) return;

    // Xóa các option cũ
    select.innerHTML = '';

    // Thêm option mặc định
    const defaultOption = document.createElement('option');
    defaultOption.value = '';
    defaultOption.textContent = 'Chọn nhân sự';
    select.appendChild(defaultOption);

    // Nhóm người dùng theo department_name
    const grouped = {};
    datas.forEach(user => {
        if (!grouped[user.department_name]) {
            grouped[user.department_name] = [];
        }
        grouped[user.department_name].push(user);
    });

    // Tạo optgroup cho mỗi phòng ban
    Object.entries(grouped).forEach(([departmentName, users]) => {
        const optgroup = document.createElement('optgroup');
        optgroup.label =  `➤ ${departmentName}`;

        users.forEach(user => {
            const option = document.createElement('option');
            option.value = `${user.user_id}$$$${user.name}`;
            option.textContent = user.name;
            optgroup.appendChild(option);
        });

        select.appendChild(optgroup);
    });
}
function renderOptionHolstype(index) {
    data_holtypes = gon.holtypes
    const leaveRequestItem = document.querySelector(`.leave-request-item[data-index="${index}"]`);

    const holTypesSel = leaveRequestItem ? leaveRequestItem.querySelector('select[name="holtype"]') : null;
    if (holTypesSel) {
        default_option = document.createElement('option');
        default_option.value = "";
        default_option.textContent = `Chọn loại đơn`;
        holTypesSel.appendChild(default_option)
        data_holtypes.forEach(holtype => {
            const option = document.createElement('option');
            option.value = holtype.code;
            option.textContent = holtype.name;
            holTypesSel.appendChild(option);
        });
    }
}
function renderOptionCountries(index) {
    datas = gon.nationalities
    const leaveRequestItem = document.querySelector(`.leave-request-item[data-index="${index}"]`);
    const countriesSel = leaveRequestItem ? leaveRequestItem.querySelector('select[name="issued_place"]') : null;
    if (countriesSel) {
        // Đăng ký locale tiếng Việt
        datas.forEach(country => {
            const option = document.createElement('option');
            option.value = country.scode;
            option.textContent = country.name;
            countriesSel.appendChild(option);
        });
    }
}
$("#leaveRequestModal").on("hidden.bs.modal", function () {
    data_leave_user = {};
    day_time_leave = [];
    users_handover = [];
    list_index = [];
    user_id_leave_request  = ""
    element = $(".leave-request-item")
    // for (let i = 0; i < element.length; i++) {
    //     list_index.push($(element).data("index"))
    // }
    // list_index.forEach(index => {
    //     delete allSelectedDates[index];
    //     delete allSelectedDateTimes[index];
    // });
    allSelectedDates = {}
    allSelectedDateTimes = {}
    $(".leave-request-item").remove();
    $("#leaveRequestModal .alert-danger").hide();
    $("#leaveRequestModal select, #leaveRequestModal input, #leaveRequestModal textarea, #leaveRequestModal .select2-container").removeClass("border border-3 border-danger");
    $(".holpros_id").val(null);
    leaveDateCurrentPageMap.clear();
    leaveDatePageSizeMap.clear();

    serverIndexes.clear();
    serverDateTimesEditByIndex = {};
    datesLeaveEditByIndex = {};
    dates_leave_edit = [];
    day_time_leave_tmp = [];

});
$("#leaveRequestModal").on("show.bs.modal", function () {
    $(".form-create-leave-request").find("input[name='datas'], input[name='commit']").remove();
});
$("#assignUserNextModal").on("hidden.bs.modal", function () {
    $(".form-create-leave-request").find("input[name='datas'], input[name='commit']").remove();
    $("#form-create-leave-request").show();
});
const DEFAULT_PAGE_SIZE = 10;
const PAGE_SIZE_OPTIONS = [10, 15, 20, 'all'];
const PAGINATION_CLASS = 'leave-date-pagination';

// Mỗi index sẽ có PAGE_SIZE và CURRENT_PAGE riêng
const leaveDatePageSizeMap = new Map();
const leaveDateCurrentPageMap = new Map();

// Lấy PAGE_SIZE của 1 index
function getLeaveDatePageSize(dataIndex) {
    let val = leaveDatePageSizeMap.get(dataIndex.toString());
    if (!val) return DEFAULT_PAGE_SIZE;
    return val === 'all' ? 'all' : parseInt(val, 10);
}

// Lấy CURRENT_PAGE của 1 index
function getLeaveDateCurrentPage(dataIndex) {
    return leaveDateCurrentPageMap.get(dataIndex.toString()) || 1;
}

// Cập nhật phân trang cho 1 leave-request-item (theo data-index)
function updateLeaveDatePagination(dataIndex, currentPage = getLeaveDateCurrentPage(dataIndex)) {
    const item = document.querySelector(`.leave-request-item[data-index="${dataIndex}"]`);
    if (!item) return;

    // Lưu lại currentPage cho index này
    leaveDateCurrentPageMap.set(String(dataIndex), currentPage);

    // Lấy PAGE_SIZE cho index này
    let pageSize = getLeaveDatePageSize(dataIndex);
    const rows = item.querySelectorAll('.detail-date-lr .row.align-items-center.gx-0');
    const total = rows.length;

    // Tính toán
    const totalPages = (pageSize === 'all') ? 1 : Math.ceil(total / pageSize);

    // ✅ FIX: nếu đang đứng ở trang > tổng số trang (do xóa hết trang cuối) -> nhảy về trang cuối còn tồn tại
    if (pageSize !== 'all' && totalPages > 0 && currentPage > totalPages) {
        currentPage = totalPages;
    }

    leaveDateCurrentPageMap.set(String(dataIndex), currentPage);

    // Ẩn tất cả
    rows.forEach(r => r.style.display = 'none');
    // Hiển thị các dòng thuộc trang hiện tại
    if (pageSize === 'all') {
        rows.forEach(r => r.style.display = '');
    } else {
        for (let i = (currentPage - 1) * pageSize; i < Math.min(currentPage * pageSize, total); i++) {
            rows[i].style.display = '';
        }
    }

    // Render nút phân trang + page size selector
    renderLeaveDatePaginationControls(item, dataIndex, currentPage, totalPages, pageSize);
}

// Tạo nút chuyển trang + page size selector cho leave-request-item
function renderLeaveDatePaginationControls(item, dataIndex, currentPage, totalPages, pageSize) {
    let paginationDiv = item.querySelector(`.${PAGINATION_CLASS}[data-index="${dataIndex}"]`);
    if (!paginationDiv) {
        // Nếu chưa có, tạo mới
        paginationDiv = document.createElement('div');
        paginationDiv.className = PAGINATION_CLASS;
        paginationDiv.setAttribute('data-index', dataIndex);
        const dateList = item.querySelector('.detail-date-lr');
        if (dateList) dateList.appendChild(paginationDiv);
    }

    // Build page size selector
    let html = `<select class="form-select form-select-sm d-inline w-auto mx-2 leave-page-size-selector" 
                    data-index="${dataIndex}" 
                    onchange="changeLeaveDatePageSize(${dataIndex}, this)">`;
    for (const opt of PAGE_SIZE_OPTIONS) {
        const val = (opt === 'all') ? 'all' : opt;
        html += `<option value="${val}"${getLeaveDatePageSize(dataIndex) == val ? ' selected' : ''}>${opt === 'all' ? 'Tất cả' : opt + '/ngày'}</option>`;
    }
    html += `</select>`;

    // Build pagination buttons (nếu pageSize === 'all' thì không render số trang)
    if (pageSize !== 'all') {
        for (let i = 1; i <= totalPages; i++) {
            html += `<button type="button" class="btn btn-sm ${i === currentPage ? 'btn-primary' : 'btn-outline-primary'} mx-1" onclick="gotoLeaveDatePage(${dataIndex},${i})">${i}</button>`;
        }
    }
    paginationDiv.innerHTML = html;
}

// Hàm gọi khi bấm nút chuyển trang
window.gotoLeaveDatePage = function(dataIndex, page) {
    leaveDateCurrentPageMap.set(String(dataIndex), page);
    updateLeaveDatePagination(dataIndex, page);
}

// Hàm đổi PAGE_SIZE khi chọn option
window.changeLeaveDatePageSize = function(dataIndex, selectEl) {
    let val = selectEl.value;
    leaveDatePageSizeMap.set(String(dataIndex), val);
    leaveDateCurrentPageMap.set(String(dataIndex), 1); // reset về page 1 khi đổi page size
    updateLeaveDatePagination(dataIndex, 1);
}

// Gọi 1 lần khi trang load xong (hoặc khi thêm/sửa/xóa ngày)
function updateAllLeaveDatePaginations() {
    document.querySelectorAll('.leave-request-item').forEach(item => {
        const dataIndex = item.getAttribute('data-index');
        // Nếu chưa set page size cho index này, đặt mặc định
        if (!leaveDatePageSizeMap.has(dataIndex)) {
            leaveDatePageSizeMap.set(dataIndex, DEFAULT_PAGE_SIZE);
        }
        if (!leaveDateCurrentPageMap.has(dataIndex)) {
            leaveDateCurrentPageMap.set(dataIndex, 1);
        }
        updateLeaveDatePagination(dataIndex, getLeaveDateCurrentPage(dataIndex));
    });
}