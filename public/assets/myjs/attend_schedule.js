let attendanceMap = {};

let shiftMap = {};
let attendanceForCalendar = {};
let attendWorkshifts = [];
let currentViewType = "dayGridMonth";
let tempRange = [];
let skipOnChange = false;
let defaultDate;
let rowsPerPage = 5;
let currentPage = 1;
flatpickr.localize(flatpickr.l10ns.vn);

const WEEK_POINT_SOURCE_ID = "ATT_POINTS";
const setRange = (input, min, max) => {
  if (!input) return;
  input.min = min || "";
  input.max = max || "";
  input.oninput = () => input.setCustomValidity("");
  input.oninvalid = () =>
    input.setCustomValidity(`Thời gian phải trong khoảng ${min} – ${max}`);
};
const inRange = (t, min, max) => (!min || t >= min) && (!max || t <= max);
// setting màu cho shift
function getShiftColor(shiftData) {
  if (!shiftData) return "#fd7e14"; // Cam – ngày làm việc bình thường

  switch (shiftData.is_day_off) {
    case "OFF":
      return "#000000"; // Đen – nghỉ hàng tuần
    case "HOLIDAY":
      return "#dc3545"; // Đỏ – ngày lễ
    case "ON-LEAVE":
      return "#94a3b8"; // Xám – nghỉ phép cá nhân
    case "TEACHING-SCHEDULE":
      return "#125de7"; // Xanh dương – lịch giảng dạy
    case "WORK-TRIP":
      return "#28a745"; // Xanh – đủ công
    default:
      if (shiftData.checkin?.trim() && shiftData.checkout?.trim()) {
        return "#28a745"; // Xanh – đủ công
      }
      return "#fd7e14"; // Cam – đang làm nhưng chưa đủ công
  }
}
// setting text cho shift
function getShiftStatusText(shift) {
  switch (shift.is_day_off) {
    case "OFF":
      return "Nghỉ hàng tuần";
    case "HOLIDAY":
      return "Nghỉ lễ";
    case "ON-LEAVE":
      return "Nghỉ phép";
    case "TEACHING-SCHEDULE":
      return "Lịch giảng dạy";
    case "WORK-TRIP":
      return "Đi công tác";
    default:
      return null;
  }
}

//// Khởi tạo & cấu hình lịch
window.addEventListener("load", function () {
  initCalendarSchedule();
});
//  Khởi tạo FullCalendar và load dữ liệu lịch làm việc
function initCalendarSchedule() {
  var elementSchedule = document.getElementById("schedule-calendar");
  if (elementSchedule) {
    calendarSchedule = new FullCalendar.Calendar(elementSchedule, {
      initialView: "dayGridMonth",
      locale: "vi",
      headerToolbar: true,
      footerToolbar: false,
      height: 640,
      contentHeight: 640,
      eventOrder: "displayOrder",
      dayMaxEventRows: 3,
      slotDuration: "00:15:00", // độ cao mỗi slot (tùy chọn)
      eventTimeFormat: { hour: "2-digit", minute: "2-digit", hour12: false }, // HH:mm
      events: function (fetchInfo, successCallback, failureCallback) {
        $.ajax({
          url: fetch_all_attends_in_month_attends_path,
          type: "GET",
          dataType: "JSON",
          data: {
            start: fetchInfo.startStr,
            end: fetchInfo.endStr,
          },
          success: function (response) {
            shiftMap = {};
            attendanceMap = {};
            attendanceForCalendar = {};
            //  Lọc bỏ những event không cần hiển thị
            const filteredEvents = [];
            response.forEach((ev) => {
              const dateKey = ev.start.split("T")[0];
              // Nếu là loại DAY_STATUS → lưu riêng và bỏ qua hiển thị
              if (ev.extendedProps && ev.extendedProps.type === "DAY_STATUS") {
                const shiftType = ev.extendedProps.shift_type; // "MORNING" hoặc "AFTERNOON"
                if (!attendanceMap[dateKey]) {
                  attendanceMap[dateKey] = {};
                }
                if (ev.status === "APPROVED") {
                  if (!attendanceForCalendar[dateKey]) {
                    attendanceForCalendar[dateKey] = {};
                  } else {
                    attendanceForCalendar[dateKey] = ev.work_date;
                  }
                  attendanceMap[dateKey][shiftType] = ev.extendedProps;
                }

                // Dữ liệu hỗ trợ khác
                if (!shiftMap[dateKey]) shiftMap[dateKey] = [];
                shiftMap[dateKey].push({
                  shift_name: ev.extendedProps.shift_name || "Không rõ",
                  work_time: `${ev.extendedProps.registered_shift_start_time} - ${ev.extendedProps.registered_shift_end_time}`,
                  checkin: ev.extendedProps.checkin,
                  checkout: ev.extendedProps.checkout,
                  location: ev.extendedProps.location || "",
                  is_day_off: ev.extendedProps.is_day_off || "",
                });
                return;
              }

              // Thêm vào danh sách hiển thị
              filteredEvents.push(ev);
              // Thêm event test "Long Event"
            });
            // ✅ Chỉ gửi event cần hiển thị
            successCallback(filteredEvents);
            renderShiftIndicators();
            // if (
            //   calendarSchedule.view.type === "timeGridWeek" ||
            //   calendarSchedule.view.type === "timeGridDay"
            // ) {
            //   renderWeekCheckpointsIfNeeded(calendarSchedule);
            // }
          },
          error: function () {
            failureCallback([]);
          },
        });
      },
      datesSet: function (info) {
        $("#calendar-schedule-title").html(calendarSchedule.view.title);

        if (info.view.type === "timeGridWeek") {
          // sang week/day → render events giờ
          renderWeekCheckpointsIfNeeded(calendarSchedule);
        } else {
          // về month/dayGrid → bỏ nguồn checkpoint, refetch lại events gốc, vẽ icon S/C
          const src = calendarSchedule.getEventSourceById(WEEK_POINT_SOURCE_ID);
          if (src) src.remove();
          // calendarSchedule.refetchEvents(); // gây request 2 lần
          setTimeout(renderShiftIndicators, 0);
        }
      },

      eventClick: function (info) {
        const ev = info.event;
        const props = ev.extendedProps;
        switch (props.type) {
          case "ATTEND_DETAIL":
            showAttendDetailPopup(props);
            break;
          case "SHIFT_ISSUE":
            showShiftIssuePopup(props, ev);
            break;
        }
      },
    });
    $("#calendar-schedule-title").html(calendarSchedule.view.title);
    calendarSchedule.render();
  }
}
//  Xử lý sự kiện bấm nút chuyển tháng (trái/phải) trong lịch
function clickNextcalendar(direct) {
  if (!calendarSchedule) {
    console.warn("Calendar not work");
    return;
  }
  if (direct == 0) {
    calendarSchedule.prev();
  } else {
    calendarSchedule.next();
  }
}

function renderShiftIndicators() {
  console.log("Rendering shift indicators...");

  document
    .querySelectorAll(".shift-indicator-container")
    .forEach((el) => el.remove());
  document.querySelectorAll(".fc-daygrid-day").forEach((el) => {
    const rawDateStr = el.getAttribute("data-date");
    const dateStr = new Date(rawDateStr).toISOString().split("T")[0];

    const data = attendanceMap[dateStr];
    if (!data) return;

    const morning = data["MORNING"];
    const afternoon = data["AFTERNOON"];

    // === Ca sáng ===
    const morningColor = getShiftColor(morning);
    // === Ca chiều ===
    const afternoonColor = getShiftColor(afternoon);

    const container = document.createElement("div");
    container.className = "shift-indicator-container";
    container.style =
      "position:absolute; top: 2px; right: 2px; z-index:10; display:flex; gap:2px;";

    if (morning) {
      const s = document.createElement("div");
      s.innerText = "S";
      s.className = "shift-circle morning";
      s.style = `background:${morningColor}; width:16px; height:16px; border-radius:50%; font-size:10px; color:white; text-align:center;`;
      s.setAttribute("data-date", dateStr);
      s.setAttribute("data-shift", "morning");
      s.addEventListener("mouseenter", (e) =>
        showShiftTooltip(dateStr, e, "morning")
      );
      s.addEventListener("mouseleave", hideShiftTooltip);
      container.appendChild(s);
    }

    if (afternoon) {
      const c = document.createElement("div");
      c.innerText = "C";
      c.className = "shift-circle afternoon";
      c.style = `background:${afternoonColor}; width:16px; height:16px; border-radius:50%; font-size:10px; color:white; text-align:center;`;
      c.setAttribute("data-date", dateStr);
      c.setAttribute("data-shift", "afternoon");
      c.addEventListener("mouseenter", (e) =>
        showShiftTooltip(dateStr, e, "afternoon")
      );
      c.addEventListener("mouseleave", hideShiftTooltip);
      container.appendChild(c);
    }

    const frame = el.querySelector(".fc-daygrid-day-frame");
    if (frame) {
      frame.appendChild(container);
    }
  });
}

// Xử lý show calendar theo tháng hoặc tuần
$(".dropdown-item[data-fc-view]").click(function () {
  var view = $(this).data("fc-view");
  $("a.dropdown-item.d-flex.justify-content-between.active").removeClass(
    "active"
  );
  $(this).addClass("active");
  $("#data-view-title").text($(this).text());
  calendarSchedule.changeView(view);
});
////
////Tooltip & hiển thị thông tin ca làm việc
function showShiftTooltip(dateStr, e, shiftType = null) {
  const data = shiftMap[formatDateKey(new Date(dateStr))];
  let tooltipEl = document.getElementById("day-tooltip");
  if (!tooltipEl) {
    tooltipEl = document.createElement("div");
    tooltipEl.id = "day-tooltip";
    tooltipEl.style.cssText = `
      display: none;
      position: fixed;
      z-index: 9999;
      background: white;
      border: 1px solid #ccc;
      border-radius: 4px;
      box-shadow: 0 2px 6px rgba(0,0,0,0.2);
      padding: 8px;
      font-size: 0.9rem;
      max-width: 300px;
    `;
    document.body.appendChild(tooltipEl);
  }

  if (!data || data.length === 0) {
    tooltipEl.style.display = "none";
    return;
  }

  let filteredData = data;
  if (shiftType === "morning") {
    filteredData = data.filter((s) =>
      s.shift_name.toLowerCase().includes("sáng")
    );
  } else if (shiftType === "afternoon") {
    filteredData = data.filter((s) =>
      s.shift_name.toLowerCase().includes("chiều")
    );
  }
  if (filteredData.length === 0) {
    tooltipEl.style.display = "none";
    return;
  }

  const dateObj = new Date(dateStr);
  const fullDateStr = dateObj.toLocaleDateString("vi-VN", {
    weekday: "long",
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
  });

  const html =
    `<div class="fw-bold text-primary mb-2">${fullDateStr}</div>` +
    filteredData
      .map((shift) => {
        const statusText = getShiftStatusText(shift);
        const useStatusForTime = ["Nghỉ hàng tuần", "Nghỉ lễ", "Nghỉ phép", "Lịch giảng dạy"].includes(statusText);
        if (useStatusForTime) {
          return `
          <div class="mb-1">
            <strong>${shift.shift_name}${statusText ? ` (${statusText})` : ""}</strong><br>
          </div>
        `;
        } else {
          const checkin = shift.checkin || "---";
          const checkout = shift.checkout || "---";
          return `
          <div class="mb-1">
            <strong>${shift.shift_name}${statusText ? ` (${statusText})` : ""}</strong><br>
            🕒 ${shift.work_time}<br>
            ✅ Vào: ${checkin} | Ra: ${checkout}<br>
            📍 ${shift.location || "Không có thông tin"}
          </div>
        `;
        }
      })
      .join("");

  tooltipEl.innerHTML = html;
  tooltipEl.style.display = "block";

  const tw = tooltipEl.offsetWidth || 250;
  const th = tooltipEl.offsetHeight || 120;

  let left = e.clientX - tw / 2;
  let top = e.clientY - th - 8;

  if (left < 0) left = 0;
  if (left + tw > window.innerWidth) {
    left = window.innerWidth - tw - 10;
  }
  if (top < 0) {
    top = e.clientY + 8;
  }

  tooltipEl.style.left = `${left}px`;
  tooltipEl.style.top = `${top}px`;
}
//  Ẩn tooltip khi không còn hover biểu tượng S/C
function hideShiftTooltip() {
  const tooltipEl = document.getElementById("day-tooltip");
  if (!tooltipEl) {
    console.warn("Tooltip element not found.");
    return;
  }
  tooltipEl.style.display = "none";
}
//  Chuyển đổi đối tượng Date thành chuỗi "YYYY-MM-DD" để dùng làm key tra dữ liệu
function formatDateKey(date) {
  const yyyy = date.getFullYear();
  const mm = String(date.getMonth() + 1).padStart(2, "0");
  const dd = String(date.getDate()).padStart(2, "0");
  return `${yyyy}-${mm}-${dd}`;
}
////
////API load dữ liệu
//  Gọi API lấy danh sách người duyệt để hiển thị trong modal tạo đề xuất
function loadManagersAndRequests() {
  $.ajax({
    type: "GET",
    url: get_data_request_attend_attends_path,
    dataType: "json",
    success: function (response) {
      const approverSelect = $("#approverSelect");
      approverSelect.empty();

      if (response.all_managers && response.all_managers.length > 0) {
        response.all_managers.forEach((manager) => {
          approverSelect.append(
            `<option value="${manager.user_id}">${manager.name}</option>`
          );
        });
      } else {
        approverSelect.append(`<option disabled>Không có người duyệt</option>`);
      }

      // Xử lý allowed_requests nếu cần
    },
    error: function () {
      alert("Không thể tải danh sách người duyệt.");
    },
  });
}

//  Gọi API để load danh sách các ca làm việc và gán vào các dropdown tương ứng
function loadWorkshifts() {
  $.ajax({
    url: ERP_PATH + "/api/v1/mapi_utils/get_all_workshifts",
    method: "GET",
    success: function (response) {
      if (response.result && response.result.length > 0) {
        let data = response.result;
        attendWorkshifts = response.result;
        const selects = [
          $("#shiftSelectChangecheck"),
          $("#shiftSelectChange"),
          $("#shiftSelectAdditional"),
          $("#shiftSelectUpdate"),
          $("#shiftSelectNew"),
          $("#leave-workshift"),
          $("#comp-workshift"),
        ];

        selects.forEach((select) => {
          if (select.length > 0) {
            select.empty();

            // Nếu là selectUpdate thì thêm option "Cả ngày" trước
            if (select.attr("id") === "shiftSelectUpdate") {
              const caSang = data.find((item) => item.min < "12:00");
              const caChieu = data.find((item) => item.min >= "12:00");

              select.append(
                $("<option>")
                  .val("-1")
                  .text("Cả ngày")
                  .attr("data-shift-type", "full")
                  .attr("data-morning-id", caSang?.id || "")
                  .attr("data-afternoon-id", caChieu?.id || "")
              );
            }

            // data.forEach((item) => {
            //   let shiftType = "";
            //   if (item.min < "12:00") shiftType = "morning";
            //   else shiftType = "afternoon";

            //   const option = $("<option>")
            //     .val(item.id)
            //     .text(item.label)
            //     .attr("data-shift-type", shiftType);

            //   select.append(option);
            // });
            data.forEach((item) => {
              const shiftType = item.min < "12:00" ? "morning" : "afternoon";
              const option = $("<option>")
                .val(item.id)
                .text(item.label)
                .attr("data-shift-type", shiftType)
                .attr("data-min", item.min) // 👈 gắn min
                .attr("data-max", item.max) // 👈 gắn max
                .attr("data-code", item.code); // (nếu cần)
              select.append(option);
            });
            // ✅ Gán mặc định nếu chưa chọn
            const defaultValue = select
              .find("option")
              .filter(function () {
                return $(this).css("display") !== "none";
              })
              .first()
              .val();

            select.val(defaultValue);
          }
        });
        updateShiftInputs();
        applyAllRanges();
      }
    },
    error: function (err) {
      console.error("Lỗi khi load danh sách ca làm việc:", err);
    },
  });
}
//lấy người có thể đổi ca.
function loadSwapCandidates(originalDate, targetDate) {
  const type = $("#request-type").val();
  const $sel = $("#swap-with-user-id");
  if (type !== "shift-change") return;

  if (!originalDate) {
    $sel
      .empty()
      .append("<option disabled selected>Chưa chọn ngày</option>")
      .prop("disabled", true)
      .trigger("change");
    return;
  }

  const CURRENT_USER_ID =
    typeof gon !== "undefined" && gon.user_id
      ? gon.user_id
      : document.querySelector('meta[name="current-user-id"]')?.content ||
        document.getElementById("current-user-id")?.value;

  if (!CURRENT_USER_ID) {
    $sel
      .empty()
      .append("<option disabled selected>Thiếu user</option>")
      .prop("disabled", true)
      .trigger("change");
    return;
  }

  $sel
    .prop("disabled", true)
    .empty()
    .append("<option disabled selected>Đang tải...</option>")
    .trigger("change");

  $.ajax({
    url: ERP_PATH + "/api/v1/mapi_utils/attends/available_swap_candidates",
    method: "POST", // PHẢI LÀ POST
    dataType: "json",
    data: {
      user_id: CURRENT_USER_ID,
      original_date: originalDate,
      target_date: targetDate || originalDate,
    },
    success: function (res) {
      // Chuẩn hoá về mảng
      const raw = (res && (res.data ?? res.result)) ?? res;
      const list = Array.isArray(raw) ? raw : [];

      if (!list.length) {
        $sel
          .empty()
          .append(
            "<option disabled selected>Không có ứng viên phù hợp</option>"
          )
          .prop("disabled", true)
          .trigger("change");
        return;
      }

      // Gộp theo user
      const byUser = {};
      list.forEach((item) => {
        const uid = item.user_id;
        if (!byUser[uid]) byUser[uid] = { ...item, shifts: item.shifts || [] };
        if (item.shift) byUser[uid].shifts.push(item.shift);
      });
      const uniq = Object.values(byUser);

      // Render
      $sel.empty();
      $sel.append('<option value="" selected disabled>— Chọn người —</option>');
      uniq.forEach((u) => {
        const label = `${u.name || u.fullname || ""} (${u.sid || ""})`;
        $sel.append($("<option>").val(u.user_id).text(label));
      });

      $sel.prop("disabled", false).trigger("change");
    },
    error: function (xhr) {
      let msg = "Lỗi tải danh sách";
      try {
        msg = JSON.parse(xhr.responseText).msg || msg;
      } catch (_) {}
      $sel
        .empty()
        .append(`<option disabled selected>${msg}</option>`)
        .prop("disabled", true)
        .trigger("change");
    },
  });
}
////
////Flatpickr & chọn ngày/giờ
// Chỉ init flatpickr sau khi modal đã shown
document
  .getElementById("requestModal")
  .addEventListener("shown.bs.modal", function () {
    $.ajax({
      type: "POST",
      url: get_available_dates,
      data: {
        user_id: CURRENT_USER_ID
      },
      success: function (response) {
        if (response && response.result) {
          initFlatpickrWithAvailableDates(attendanceForCalendar, response);
        } else {
          alert("Không có dữ liệu ngày khả dụng.");
        }
      },
      error: function () {
        alert("Không thể tải danh sách ngày.");
      },
    });
  });
//  Khởi tạo Flatpickr để chọn ngày có ca làm việc (>= hôm nay) cho form đề xuất
function initFlatpickrWithAvailableDates(attendanceForCalendar, availableDates) {
  if (
      !availableDates ||
      !availableDates.result ||
      !availableDates.result.start_date ||
      !availableDates.result.end_date
  ) {
    alert("Không còn ngày làm việc nào từ hôm nay trở đi.");
    return;
  }
  const { start_date, end_date } = availableDates.result;

  const [sd, sm, sy] = start_date.split("/").map(Number);
  const [ed, em, ey] = end_date.split("/").map(Number);

  const startDate = new Date(sy, sm - 1, sd, 0, 0, 0);
  const endDate   = new Date(ey, em - 1, ed, 0, 0, 0);

  const enabledDates = [];
  for (let d = new Date(startDate); d <= endDate; d.setDate(d.getDate() + 1)) {
    const y = d.getFullYear();
    const m = String(d.getMonth() + 1).padStart(2, "0");
    const da = String(d.getDate()).padStart(2, "0");
    enabledDates.push(`${y}-${m}-${da}`);
  }
  const todayStr = new Date().toISOString().split("T")[0]; // YYYY-MM-DD
  if (enabledDates.includes(todayStr)) {
    defaultDate = todayStr;
  } else {
    defaultDate = enabledDates[0] || null; // nếu mảng rỗng thì null
  }
  if (enabledDates.length === 0) {
    alert("Không còn ngày làm việc nào từ hôm nay trở đi.");
    return;
  }
  //Cấu hình riêng cho ngày đăng ký đổi ca (request-date-new)
  flatpickr("#request-date-new", {
    dateFormat: "Y-m-d",
    altInput: true,
    altFormat: "l, d/m/Y",
    locale: "vn",
    minDate: "today", // chỉ từ hôm nay trở đi
    defaultDate: "today",
  });

  //Cấu hình cho các trường ngày làm việc chung (dùng attendanceMap)
  flatpickr("#original-date", {
    dateFormat: "Y-m-d", // format gửi form
    altInput: true,
    altFormat: "l, d/m/Y", // Thứ, dd/mm/yyyy
    locale: "vn",
    enable: enabledDates,
    allowInput: false, // không cho nhập tay
    defaultDate: defaultDate,
    clickOpens: true, // chỉ mở lịch khi click

    onChange: function (selectedDates, dateStr, instance) {
      const selectedDate = selectedDates[0];
      const weekNum = getWeekNumber(selectedDate);
      document.getElementById("week_num").value = weekNum;
    },

    onReady: function (selectedDates) {
      const selectedDate = selectedDates[0];
      const weekNum = getWeekNumber(selectedDate);
      document.getElementById("week_num").value = weekNum;
    },
    onClose(selectedDates, dateStr, instance) {
      // Không cho để trống: nếu user cố xoá → set lại default
      if (!dateStr)
        instance.setDate(instance.config.defaultDate || "today", true);
    },
  });
  let suppressOnChange = false;
  let tempRange = [];
  let isInRangeState = false;

  // @author: an.cdb - @date: 10/03/2026 - cấu hình flatpickr cho nghỉ bù
  // - cấu hình chọn ngày có ca làm việc vượt giờ
  // Khởi tạo lịch cho Ngày làm vượt giờ (Chỉ cho phép chọn quá khứ/hôm nay)
  flatpickr("#comp-original-date", {
      dateFormat: "Y-m-d",
      altInput: true,
      altFormat: "l, d/m/Y",
      locale: "vn",
      maxDate: "today",
      defaultDate: "today",
      clickOpens: true,
  });

  // Khởi tạo lịch cho Ngày bù (Chỉ cho phép chọn từ hôm nay trở đi)
  flatpickr("#leave-date", {
      dateFormat: "Y-m-d",
      altInput: true,
      altFormat: "l, d/m/Y",
      locale: "vn",
      minDate: "today",
      defaultDate: "today",
      clickOpens: true,
  });
  

  // cấu hình cho chọn nhiều ngày đi công tác
  flatpickr("#business_trip_range", {
    mode: "multiple",
    dateFormat: "Y-m-d",
    altInput: true,
    locale: "vn",
    altFormat: "l - d/m/Y",
    allowInput: false,
    enable: enabledDates, // các ngày được phép chọn
    onReady: function (selectedDates, instance) {
      if (instance.altInput) {
        instance.altInput.placeholder = "Chọn ngày công tác…";
      }
      if (selectedDates.length === 1) {
        tempRange = [selectedDates[0]];
      }
    },
    onChange: function (selectedDates, dateStr, instance) {
      if (suppressOnChange) return;

      const isRangeMode = document.getElementById("range_mode_toggle").checked;
      const sorted = [...selectedDates].sort((a, b) => a - b);

      if (isRangeMode) {
        if (selectedDates.length === 1) {
          // Chọn ngày đầu tiên
          tempRange = [sorted[0]];
          // isInRangeState = false;
          updateTripFields(sorted[0], null, [sorted[0]]);
          return;
        }

        if (selectedDates.length === 2) {
          const [start, end] = sorted;
          const expectedLength =
            Math.abs((end - start) / (1000 * 60 * 60 * 24)) + 1;

          // Nếu chưa tạo range hoặc bị phá vỡ (bỏ mất ngày ở giữa)
          if (!isInRangeState) {
            const rangeDates = [];
            let current = new Date(start);
            while (current <= end) {
              rangeDates.push(new Date(current));
              current.setDate(current.getDate() + 1);
            }

            suppressOnChange = true;
            instance.setDate(rangeDates, false); // không trigger lại
            suppressOnChange = false;

            tempRange = rangeDates;
            isInRangeState = true; // ✅ Đánh dấu đang trong range
            updateTripFields(start, end, rangeDates);
            return;
          } else {
            // ✅ Đã là range, người dùng bỏ 1 ngày giữa → chuyển sang multiple
            tempRange = selectedDates;
            isInRangeState = false;
            updateTripFields(start, end, selectedDates);
            return;
          }
        }

        if (selectedDates.length > 2) {
          // Người dùng đã bỏ ngày giữa trong range hoặc chọn nhiều ngày → chuyển multiple
          tempRange = selectedDates;
          isInRangeState = false;
          const first = sorted[0];
          const last = sorted[sorted.length - 1];
          updateTripFields(first, last, sorted);
        }
      } else {
        // ⛅ Chế độ ngày lẻ (multiple)
        tempRange = selectedDates;
        isInRangeState = false;

        if (selectedDates.length > 0) {
          const first = sorted[0];
          const last = sorted[sorted.length - 1];
          updateTripFields(first, last, sorted);
        } else {
          updateTripFields(null, null, []);
        }
      }
    },
  });

  // Cấu hình Flatpickr cho time picker thông thường (không có minuteIncrement)
  flatpickr(".time-picker", {
    enableTime: true,
    noCalendar: true,
    dateFormat: "H:i",
    time_24hr: true,
    defaultDate: new Date(), // Gán thời gian hiện tại
    allowInput: true, // Cho phép nhập tay cho các time picker khác
    appendTo: document.getElementById("requestModal"), // Đảm bảo popup không bị lệch
    onOpen: function (selectedDates, dateStr, instance) {
      setTimeout(() => {
        const calendar = instance.calendarContainer;
        calendar.style.width = "auto";
        calendar.style.minWidth = "217px";
        calendar.style.maxWidth = "240px";
      }, 10); // chờ render xong mới set
    },
  });

  // Cấu hình Flatpickr riêng cho time picker cập nhật ca (chỉ cho phép chọn theo bước 5 phút)
  flatpickr(".time-picker-update-shift", {
    enableTime: true,
    noCalendar: true,
    dateFormat: "H:i",
    time_24hr: true,
    minuteIncrement: 5, // Chỉ cho phép chọn theo bước 5 phút (0, 5, 10, 15, ...)
    allowInput: false, // Không cho phép nhập bằng tay
    clickOpens: true, // ✅ Cho phép mở bằng click
    disableMobile: true, // Vô hiệu hóa mobile input để tránh nhập tay
    // Không set defaultDate vì sẽ được set động bởi setDefaultMorningTime/setDefaultAfternoonTime
    appendTo: document.getElementById("requestModal"), // Đảm bảo popup không bị lệch
    onOpen: function (selectedDates, dateStr, instance) {
      setTimeout(() => {
        const calendar = instance.calendarContainer;
        calendar.style.width = "auto";
        calendar.style.minWidth = "217px";
        calendar.style.maxWidth = "240px";
        
        // Thêm class cụ thể cho popup của time picker cập nhật ca
        calendar.classList.add('time-picker-update-shift-flatpickr-popup');
        
        // Vô hiệu hóa tất cả input trong popup
        const inputs = calendar.querySelectorAll('input');
        inputs.forEach(input => {
          input.setAttribute('readonly', 'readonly');
          input.style.pointerEvents = 'none';
          
          // Ngăn chặn việc nhập tay trong popup
          input.addEventListener('keydown', function(e) {
            e.preventDefault();
            return false;
          });
          
          input.addEventListener('keyup', function(e) {
            e.preventDefault();
            return false;
          });
          
          input.addEventListener('keypress', function(e) {
            e.preventDefault();
            return false;
          });
          
          input.addEventListener('input', function(e) {
            e.preventDefault();
            return false;
          });
        });
      }, 10); // chờ render xong mới set
    },
    onReady: function (selectedDates, dateStr, instance) {
      // Vô hiệu hóa input chính - chỉ chặn nhập tay, không chặn click
      const input = instance.element;
      input.setAttribute('readonly', 'readonly');
      // Không set pointerEvents = 'none' để vẫn có thể click
      
      // Ngăn chặn việc nhập tay bằng keyboard
      input.addEventListener('keydown', function(e) {
        e.preventDefault();
        return false;
      });
      
      input.addEventListener('keyup', function(e) {
        e.preventDefault();
        return false;
      });
      
      input.addEventListener('keypress', function(e) {
        e.preventDefault();
        return false;
      });
      
      input.addEventListener('input', function(e) {
        e.preventDefault();
        return false;
      });
    },
  });
}
//lấy giá trị ngày từ input.
function getISODateStr(inputSelector) {
  const v = $(inputSelector).val();
  // flatpickr đã format Y-m-d; fallback lấy từ altInput nếu cần
  return v && v.length ? v : document.querySelector(inputSelector)?.value || "";
}
// Đặt lại ngày đi công tác
document
  .getElementById("clear_business_trip")
  .addEventListener("click", function () {
    const fp = document.querySelector("#business_trip_range")._flatpickr;
    if (fp) {
      fp.clear();
      updateTripFields(null, null, []);
      toggleTripFooter([]);
    }
  });

function updateTripFields(start, end, dates) {
  // Cập nhật input ngày bắt đầu/kết thúc
  document.getElementById("trip_start").value = start ? formatDate(start) : "";
  document.getElementById("trip_end").value = end ? formatDate(end) : "";

  // Cập nhật danh sách ngày đã chọn
  const dateStrings = dates && dates.length ? dates.map(formatDate) : [];
  document.getElementById("trip_dates_filtered").value = dateStrings.join(",");

  // Render giao diện chọn ca
  renderBusinessTripShiftOptions(dates || []);

  // Cập nhật dữ liệu shift (dạng JSON)
  collectShiftData();
  currentPage = 1;
  paginateShiftRows();
}

function collectShiftData() {
  const container = document.getElementById("business-trip-shift-container");
  const rows = Array.from(container.querySelectorAll("div.shift-row"));

  const result = rows.map((row) => {
    const dateStr = row.dataset.date;
    const checked = row.querySelector("input[type='radio']:checked");
    const label = checked ? checked.value : "Cả ngày";

    const shiftIDs = []; // từ attendWorkshifts tìm id tương ứng
    if (label === "Cả ngày") {
      const item = attendWorkshifts.find((s) => s.min < "12:00");
      const other = attendWorkshifts.find((s) => s.min >= "12:00");
      item && shiftIDs.push(item.id);
      other && shiftIDs.push(other.id);
    } else if (label === "Sáng" || label === "Chiều") {
      const match = attendWorkshifts.find((s) => {
        const type = s.min < "12:00" ? "Sáng" : "Chiều";
        return type === label;
      });
      match && shiftIDs.push(match.id);
    }

    return { date: dateStr, shifts: shiftIDs };
  });

  document.getElementById("trip_shift_data").value = JSON.stringify(result);
}

function renderBusinessTripShiftOptions(dates) {
  const container = document.getElementById("business-trip-shift-container");
  container.innerHTML = "";

  dates.forEach((date) => {
    const dateStr = flatpickr.formatDate(date, "d-m-Y");

    const row = document.createElement("div");
    row.className =
      "d-flex justify-content-between align-items-center mb-2 px-2 py-1 border rounded shift-row flex-wrap";
    row.dataset.date = dateStr;

    // ❌ Nút xóa ngày
    const removeBtn = document.createElement("button");
    removeBtn.type = "button";
    removeBtn.className = "btn btn-sm btn-link text-danger p-0 fw-bold";
    removeBtn.innerHTML = "❌";
    removeBtn.style.textDecoration = "none";
    removeBtn.onclick = () => {
      const fp = document.querySelector("#business_trip_range")._flatpickr;
      const remaining = fp.selectedDates.filter(
        (d) => flatpickr.formatDate(d, "d-m-Y") !== dateStr
      );
      fp.setDate(remaining, false);
      if (remaining.length > 0) {
        updateTripFields(
          remaining[0],
          remaining[remaining.length - 1],
          remaining
        );
      } else {
        updateTripFields(null, null, []);
      }
    };

    // 📅 Label ngày
    const dateLabel = document.createElement("span");
    dateLabel.className = "fw-bold";
    dateLabel.textContent = dateStr;

    // Gộp nút xoá và ngày vào bên trái
    const leftCol = document.createElement("div");
    leftCol.className = "d-flex align-items-center gap-2";
    leftCol.appendChild(removeBtn);
    leftCol.appendChild(dateLabel);

    // Code cũ - @author: trong.lq @date: 30/10/2025
    // // 🔘 Shift radio chỉ có "Cả ngày"
    // const shiftGroup = document.createElement("div");
    // shiftGroup.className = "d-flex align-items-center gap-2";
    // const radioId = `shift-${dateStr}-0`;
    // const radio = document.createElement("input");
    // radio.type = "radio";
    // radio.name = `shift-radio-${dateStr}`;
    // radio.id = radioId;
    // radio.value = "Cả ngày";
    // radio.className = "form-check-input";
    // radio.checked = true;
    // radio.addEventListener("change", () => {
    //   calculateTotalDays();
    //   collectShiftData();
    // });
    // const lbl = document.createElement("label");
    // lbl.setAttribute("for", radioId);
    // lbl.className = "form-check-label mb-0";
    // lbl.textContent = "Cả ngày";
    // shiftGroup.appendChild(radio);
    // shiftGroup.appendChild(lbl);

    // Code mới - @author: trong.lq @date: 30/10/2025
    // 🔘 Nhóm lựa chọn ca: Cả ngày / Sáng / Chiều
    const shiftGroup = document.createElement("div");
    shiftGroup.className = "d-flex align-items-center gap-3 flex-wrap";

    const options = [
      { value: "Cả ngày", label: "Cả ngày" },
      { value: "Sáng", label: "Sáng" },
      { value: "Chiều", label: "Chiều" },
    ];

    options.forEach((opt, idx) => {
      const wrapper = document.createElement("div");
      wrapper.className = "form-check form-check-inline m-0";

      const id = `shift-${dateStr}-${idx}`;
      const r = document.createElement("input");
      r.type = "radio";
      r.name = `shift-radio-${dateStr}`;
      r.id = id;
      r.value = opt.value;
      r.className = "form-check-input";
      if (idx === 0) r.checked = true; // mặc định "Cả ngày"
      r.addEventListener("change", () => {
        calculateTotalDays();
        collectShiftData();
      });

      const l = document.createElement("label");
      l.setAttribute("for", id);
      l.className = "form-check-label mb-0";
      l.textContent = opt.label;

      wrapper.appendChild(r);
      wrapper.appendChild(l);
      shiftGroup.appendChild(wrapper);
    });

    // 🧱 Gắn vào dòng
    row.appendChild(leftCol);
    row.appendChild(shiftGroup);
    container.appendChild(row);
  });

  // 🔁 Cập nhật số ngày + JSON
  calculateTotalDays();
  collectShiftData();
  toggleTripFooter(dates);

  // 👁️ Ẩn/hiện khu tổng số ngày
  const footer = document.getElementById("trip-footer-controls");
  if (footer) {
    footer.classList.toggle("d-none", dates.length === 0);
  }

  paginateShiftRows();
}

// function renderBusinessTripShiftOptions(dates) {
//   const container = document.getElementById("business-trip-shift-container");
//   container.innerHTML = "";

//   dates.forEach((date) => {
//     const dateStr = flatpickr.formatDate(date, "Y-m-d");

//     const row = document.createElement("div");
//     row.className = "d-flex align-items-center mb-2 gap-2 flex-wrap shift-row";
//     row.dataset.date = dateStr;

//     // ❌ Nút xóa ngày
//     const removeBtn = document.createElement("button");
//     removeBtn.type = "button";
//     removeBtn.className = "btn btn-sm btn-link text-danger p-0 fw-bold";
//     removeBtn.innerHTML = "❌";
//     removeBtn.onclick = () => {
//       const fp = document.querySelector("#business_trip_range")._flatpickr;
//       const remaining = fp.selectedDates.filter(
//         (d) => flatpickr.formatDate(d, "Y-m-d") !== dateStr
//       );
//       fp.setDate(remaining, false); // không trigger onChange
//       if (remaining.length > 0) {
//         updateTripFields(
//           remaining[0],
//           remaining[remaining.length - 1],
//           remaining
//         );
//       } else {
//         updateTripFields(null, null, []);
//       }
//     };

//     // 🗓️ Label ngày
//     const dateLabel = document.createElement("span");
//     dateLabel.className = "fw-bold";
//     dateLabel.textContent = dateStr;

//     // ☀️ Nhóm radio
//     // const shiftOptions = ["Cả ngày", "Sáng", "Chiều"];
//     const shiftOptions = ["Cả ngày"];
//     const shiftGroup = document.createElement("div");
//     shiftGroup.className = "d-flex flex-wrap gap-2";

//     shiftOptions.forEach((label, i) => {
//       const radioId = `shift-${dateStr}-${i}`;
//       const radio = document.createElement("input");
//       radio.type = "radio";
//       radio.name = `shift-radio-${dateStr}`;
//       radio.id = radioId;
//       radio.value = label;
//       radio.className = "form-check-input";
//       if (i === 0) radio.checked = true;

//       radio.addEventListener("change", () => {
//         calculateTotalDays();
//         collectShiftData();
//       });

//       const lbl = document.createElement("label");
//       lbl.setAttribute("for", radioId);
//       lbl.className = "form-check-label";
//       lbl.textContent = label;

//       const wrapper = document.createElement("div");
//       wrapper.className = "form-check form-check-inline";
//       wrapper.appendChild(radio);
//       wrapper.appendChild(lbl);

//       shiftGroup.appendChild(wrapper);
//     });

//     // 📦 Gắn mọi thứ vào dòng
//     row.appendChild(removeBtn);
//     row.appendChild(dateLabel);
//     row.appendChild(shiftGroup);
//     container.appendChild(row);
//   });

//   // 🔁 Cập nhật số ngày + JSON
//   calculateTotalDays();
//   collectShiftData();
//   toggleTripFooter(dates);
//   // 👁️ Ẩn/hiện khu tổng số ngày
//   const footer = document.getElementById("trip-footer-controls");
//   if (footer) {
//     if (dates.length > 0) {
//       footer.classList.remove("d-none");
//     } else {
//       footer.classList.add("d-none");
//     }
//   }

//   paginateShiftRows();
// }
////
////Xử lý form đề xuất
const requestTypeEl = document.getElementById("request-type");
const swapSel = document.getElementById("swap-with-user-id");
const timeAdditional = document.getElementById("additional-time");
function toggleRequiredByType() {
  const t = requestTypeEl?.value;

  // Đổi ca
  if (swapSel) {
    const need = t === "shift-change";
    swapSel.disabled = !need;
    swapSel.required = need;
  }

  // Additional: 1 input giờ, đổi name/label theo type
  if (timeAdditional) {
    const need = t === "additional-check-in" || t === "additional-check-out";
    timeAdditional.required = need;
    timeAdditional.name =
      t === "additional-check-out" ? "check_out_time" : "check_in_time";
    const lbl = document.getElementById("label-additional-time");
    if (lbl)
      lbl.textContent = t === "additional-check-out" ? "Giờ ra*" : "Giờ vào*";
  }

  // Early/Late
  const timeEarlyLate = document.getElementById("request-time");
  const selEarlyLate = document.getElementById("shiftSelectChangecheck");
  const needEL = t === "early-check-out" || t === "late-check-in";
  if (timeEarlyLate) timeEarlyLate.required = needEL;
  if (selEarlyLate) selEarlyLate.required = needEL;
}
requestTypeEl?.addEventListener("change", toggleRequiredByType);
toggleRequiredByType();
// Ẩn/hiện section + chỉ toggle disabled (không đụng tới name/required)
// @author: trong.lq
// @date: 22/10/2025
const toggleRequestSections = (type) => {
  const map = {
    "early-check-out": "#section-early-late",
    "late-check-in": "#section-early-late",
    "shift-change": "#section-shift-change",
    "additional-check-in": "#section-additional-check",
    "additional-check-out": "#section-additional-check",
    "update-shift": "#section-update-shift",
    "work-trip": "#section-work-trip",
    "edit-plan": "#section-edit-plan",
    "compensatory-leave": "#section-compensatory-leave",
  };

  const allSections = [
    "#section-early-late",
    "#section-shift-change",
    "#section-additional-check",
    "#section-update-shift",
    "#section-work-trip",
    "#section-edit-plan",
    "#section-compensatory-leave",
  ];

  const activeSectionId = map[type];

  allSections.forEach((sel) => {
    const sec = document.querySelector(sel);
    if (!sec) return;

    const isActive = sel === activeSectionId;
    sec.classList.toggle("d-none", !isActive);

    // Ẩn thì disable -> không validate, không submit
    // Hiện thì enable -> validate và submit bình thường
    sec.querySelectorAll("input, select, textarea").forEach((el) => {
      el.disabled = !isActive;
    });
  });

  // Quy tắc đặc thù
  if (activeSectionId === "#section-additional-check") {
    const section = document.querySelector("#section-additional-check");
    const timeInput = section.querySelector("#additional-time");
    const timeLabel = section.querySelector("#label-additional-time");
    if (timeInput && timeLabel) {
      timeInput.value = "";
      if (type === "additional-check-in") {
        timeLabel.innerHTML = 'Giờ vào<span class="text-danger">*</span>:';
        timeInput.name = "check_in_time"; // input này dùng chung nên vẫn cần đổi name
        timeInput.required = true;
      } else {
        timeLabel.innerHTML = 'Giờ ra<span class="text-danger">*</span>:';
        timeInput.name = "check_out_time"; // input này dùng chung nên vẫn cần đổi name
        timeInput.required = true;
      }
    }
  }

  if (activeSectionId === "#section-shift-change") {
    const swapSel = document.getElementById("swap-with-user-id");
    if (swapSel) {
      swapSel.disabled = false;
      swapSel.required = true;
      if (!swapSel.value && !swapSel.querySelector('option[value=""]')) {
        const opt = document.createElement("option");
        opt.value = "";
        opt.disabled = true;
        opt.selected = true;
        opt.textContent = "— Chọn người —";
        swapSel.prepend(opt);
      }
    }
  } else {
    // Không phải đổi ca -> đảm bảo select không tham gia validate/submit
    const swapSel = document.getElementById("swap-with-user-id");
    if (swapSel) {
      swapSel.required = false;
      swapSel.disabled = true;
    }
  }

  // @author: trong.lq
  // @date: 22/10/2025
  // Load dữ liệu tuần khi chọn "Chỉnh sửa kế hoạch làm việc"
  if (activeSectionId === "#section-edit-plan") {
    loadApprovedWeeks();
  }
};

// @author: trong.lq
// @date: 22/10/2025
// Function load dữ liệu tuần có trạng thái APPROVED
function loadApprovedWeeks() {
  const weekSelect = document.getElementById("plan-week-select");
  if (!weekSelect) return;

  // Hàm format ngày: yyyy-mm-dd → dd/mm/yyyy
  function formatDate(dateStr) {
    const date = new Date(dateStr);
    return date.toLocaleDateString('vi-VN');
  }

  // Clear existing options except first one
  weekSelect.innerHTML = '<option value="">-- Chọn tuần --</option>';

  // Call AJAX to get scheduleweeks data from API
  console.log('Loading approved weeks...');
  $.ajax({
    url: ERP_PATH + "/api/v1/mapi_utils/get_scheduleweeks",
    method: "GET",
    dataType: "json",
    data: {
      user_id: gon.user_id || null  // Pass user_id if available
    },
    beforeSend: function(xhr) {
      console.log('Sending request to:', ERP_PATH + "/api/v1/mapi_utils/get_scheduleweeks");
    },
    success: function(response) {
      console.log('Success response:', response);
      if (response && response.result && Array.isArray(response.result)) {
        // Filter weeks with APPROVED status
        const approvedWeeks = response.result.filter(week => week.status === 'APPROVED');
        
        // Add options to select
        approvedWeeks.forEach(week => {
          const option = document.createElement('option');
          option.value = week.week_num;
          option.textContent = `Tuần ${week.week_num} (${formatDate(week.start_date)} - ${formatDate(week.end_date)})`;
          weekSelect.appendChild(option);
        });

        if (approvedWeeks.length === 0) {
          const option = document.createElement('option');
          option.value = "";
          option.textContent = "-- Không có tuần nào được duyệt --";
          option.disabled = true;
          weekSelect.appendChild(option);
        }
      }
    },
    error: function(xhr, status, error) {
      console.error('Error loading approved weeks:', error);
      console.error('Response:', xhr.responseText);
      console.error('Status:', xhr.status);
      
      const option = document.createElement('option');
      option.value = "";
      
      if (xhr.status === 401 || xhr.status === 403) {
        option.textContent = "-- Vui lòng đăng nhập --";
      } else if (xhr.status === 404) {
        option.textContent = "-- Endpoint không tồn tại --";
      } else if (xhr.responseText && xhr.responseText.includes('<!DOCTYPE')) {
        option.textContent = "-- Server trả về HTML thay vì JSON --";
      } else {
        option.textContent = "-- Lỗi tải dữ liệu --";
      }
      
      option.disabled = true;
      weekSelect.appendChild(option);
    }
  });
}

/// ✅ Hàm xử lý khi người dùng chọn loại ca làm việc ("Cả ngày", "Sáng", "Chiều")
// Đồng thời hiển thị phần chọn ca tương ứng và gán hidden input nếu là "Cả ngày"
function updateShiftInputs() {
  const selected = $("#shiftSelectUpdate").find("option:selected");
  const shiftType = selected.data("shift-type"); // Giá trị: "full", "morning", "afternoon"
  // 👉 Hiển thị / ẩn phần chọn ca sáng/chiều tùy theo loại ca
  if (shiftType === "full") {
    $(".shift-morning").show();
    $(".shift-afternoon").show();
    // Set thời gian mặc định cho cả ca sáng và chiều
    setDefaultMorningTime();
    setDefaultAfternoonTime();
  } else if (shiftType === "morning") {
    $(".shift-morning").show();
    $(".shift-afternoon").hide();
    // Clear giá trị ca chiều khi chọn ca sáng
    $("#afternoon-check-in").val("");
    $("#afternoon-check-out").val("");
    // Set thời gian mặc định cho ca sáng
    setDefaultMorningTime();
  } else if (shiftType === "afternoon") {
    $(".shift-morning").hide();
    $(".shift-afternoon").show();
    // Clear giá trị ca sáng khi chọn ca chiều
    $("#morning-check-in").val("");
    $("#morning-check-out").val("");
    // Set thời gian mặc định cho ca chiều
    setDefaultAfternoonTime();
  } else {
    $(".shift-morning").hide();
    $(".shift-afternoon").hide();
    // Clear tất cả giá trị khi không chọn ca nào
    $("#morning-check-in").val("");
    $("#morning-check-out").val("");
    $("#afternoon-check-in").val("");
    $("#afternoon-check-out").val("");
  }

  // 👉 Xóa các input ẩn cũ nếu có
  $("input[name='morning_workshift_id']").remove();
  $("input[name='afternoon_workshift_id']").remove();

  // 👉 Tạo hidden input cho ca sáng/chiều tùy theo loại ca được chọn
  if (shiftType === "full") {
    // Chọn "Cả ngày" - tạo cả 2 hidden input
    const morningId = selected.data("morning-id");
    const afternoonId = selected.data("afternoon-id");
    $("#shiftSelectUpdate").after(
      `<input type="hidden" name="morning_workshift_id" value="${morningId}" />`
    );
    $("#shiftSelectUpdate").after(
      `<input type="hidden" name="afternoon_workshift_id" value="${afternoonId}" />`
    );
  } else if (shiftType === "morning") {
    // Chọn ca sáng - chỉ tạo hidden input cho ca sáng
    const morningId = selected.val();
    $("#shiftSelectUpdate").after(
      `<input type="hidden" name="morning_workshift_id" value="${morningId}" />`
    );
  } else if (shiftType === "afternoon") {
    // Chọn ca chiều - chỉ tạo hidden input cho ca chiều
    const afternoonId = selected.val();
    $("#shiftSelectUpdate").after(
      `<input type="hidden" name="afternoon_workshift_id" value="${afternoonId}" />`
    );
  }
}

// ✅ Function set thời gian mặc định cho ca sáng
function setDefaultMorningTime() {
  const morningIn = document.getElementById("morning-check-in");
  const morningOut = document.getElementById("morning-check-out");
  
  if (morningIn && !morningIn.value) {
    morningIn.value = "07:00";
  }
  if (morningOut && !morningOut.value) {
    morningOut.value = "11:00";
  }
}

// ✅ Function set thời gian mặc định cho ca chiều
function setDefaultAfternoonTime() {
  const afternoonIn = document.getElementById("afternoon-check-in");
  const afternoonOut = document.getElementById("afternoon-check-out");
  if (afternoonIn && !afternoonIn.value) {
    afternoonIn.value = "13:00";
  }
  if (afternoonOut && !afternoonOut.value) {
    afternoonOut.value = "17:00";
  }
}

// ✅ Function tính thời gian làm việc (tính bằng giờ)
function calculateWorkDuration(startTime, endTime) {
  if (!startTime || !endTime) return 0;
  
  const [startHour, startMinute] = startTime.split(':').map(Number);
  const [endHour, endMinute] = endTime.split(':').map(Number);
  
  const startMinutes = startHour * 60 + startMinute;
  const endMinutes = endHour * 60 + endMinute;
  
  const durationMinutes = endMinutes - startMinutes;
  return durationMinutes / 60; // Chuyển về giờ
}

// ✅ Function chuyển đổi số giờ thập phân thành định dạng "X giờ Y phút"
function formatDurationToHoursMinutes(durationInHours) {
  if (!durationInHours || durationInHours === 0) return "0 giờ";
  
  const hours = Math.floor(durationInHours);
  const minutes = Math.round((durationInHours - hours) * 60);
  
  if (minutes === 0) {
    return `${hours} giờ`;
  } else {
    return `${hours} giờ ${minutes} phút`;
  }
}

// ✅ Function lấy thời gian ca từ attendanceMap (thời gian đã đăng ký)
function getShiftDurationFromAttendanceMap(dateStr, shiftType) {
  // Debug: Log để kiểm tra dateStr
  
  if (!attendanceMap[dateStr] || !attendanceMap[dateStr][shiftType]) {
    return null;
  }
  
  const shiftData = attendanceMap[dateStr][shiftType];
  // Lấy thời gian đã đăng ký (registered_shift_start_time/end_time)
  const startTime = shiftData.registered_shift_start_time;
  const endTime = shiftData.registered_shift_end_time;
  
  
  if (!startTime || !endTime) return null;
  
  const duration = calculateWorkDuration(startTime, endTime);
  
  return duration;
}

////
//  Khi người dùng bấm nút "Tạo đề xuất" → kiểm tra ngày hợp lệ và mở modal
document
  .getElementById("create-request")
  .addEventListener("click", function () {
    // Code cũ - 17/09/2025: Chỉ kiểm tra attendanceDates trong view hiện tại
    // Code mới - 17/09/2025: Kiểm tra tổng quát attendanceForCalendar trước
    if (!attendanceForCalendar || Object.keys(attendanceForCalendar).length === 0) {
      pushToast("Không có ngày làm việc nào để tạo đề xuất. Vui lòng đăng ký lịch làm việc trước.", false);
      return;
    }

    const view = calendarSchedule.view;
    const startDate = view.activeStart;
    const endDate = new Date(view.activeEnd.getTime() - 86400000);

    const formatDate = (d) => d.toISOString().split("T")[0];
    const attendanceDates = [];

    let cursor = new Date(startDate);
    while (cursor <= endDate) {
      const key = formatDate(cursor);
      if (attendanceMap[key]) attendanceDates.push(key);
      cursor.setDate(cursor.getDate() + 1);
    }

    if (attendanceDates.length === 0) {
      console.log("Không có ngày chấm công phù hợp.");
      return; // stop tại đây và giữ loading
    }

    const originalDate = getISODateStr("#original-date"); // ngày có ca hiện tại
    const targetDate = getISODateStr("#request-date-new"); // ngày muốn đổi (nếu dùng)
    if (originalDate)
      loadSwapCandidates(originalDate, targetDate || originalDate);
    // initFlatpickrWithAvailableDates(attendanceMap);
    loadManagersAndRequests();
    loadWorkshifts();
    const modal = new bootstrap.Modal(document.getElementById("requestModal"));
    modal.show();
  });
document
  .getElementById("requestModal")
  .addEventListener("show.bs.modal", clearAppToasts);

// khi user đổi ngày trong 2 input thì reload candidates
// $("#original-date").on("change", function () {
//   const originalDate = this.value;
//   const targetDate = getISODateStr("#request-date-new") || originalDate;
//   loadSwapCandidates(originalDate, targetDate);
// });
$("#section-shift-change").on(
  "change",
  'input[name="original_date"]',
  function () {
    const $sec = $(this).closest("#section-shift-change");
    const originalDate = this.value;
    const targetDate =
      $sec.find('input[name="target_date"]').val() || originalDate;
    loadSwapCandidates(originalDate, targetDate);
  }
);
$("#request-date-new").on("change", function () {
  const targetDate = this.value;
  const $sec = $("#section-shift-change"); // <-- scope đúng section
  const originalDate =
    $sec.find('input[name="original_date"]').val() || targetDate;

  // Code cũ - 17/09/2025: Không kiểm tra originalDate null
  // loadSwapCandidates(originalDate, targetDate);
  
  // Code mới - 17/09/2025: Kiểm tra originalDate trước khi gọi function
  if (originalDate && originalDate.trim() !== '') {
    loadSwapCandidates(originalDate, targetDate);
  } else {
    // Xử lý trường hợp originalDate null/empty
    const $sel = $("#swap-with-user-id");
    $sel
      .empty()
      .append("<option disabled selected>Chưa chọn ngày gốc</option>")
      .prop("disabled", true)
      .trigger("change");
  }
});

//  Khi người dùng thay đổi loại đề xuất trong dropdown, cập nhật form tương ứng
document.getElementById("request-type").addEventListener("change", function () {
  toggleRequestSections(this.value);
  const type = this.value;
  if (type === "shift-change") {
    const $sec = $("#section-shift-change");
    const originalDate = $sec.find('input[name="original_date"]').val(); // ngày có ca hiện tại
    const targetDate =
      $sec.find('input[name="target_date"]').val() || originalDate; // ngày muốn đổi

    // Code cũ - 17/09/2025: Không kiểm tra originalDate null
    // loadSwapCandidates(originalDate, targetDate);
    
    // Code mới - 17/09/2025: Kiểm tra originalDate trước khi gọi function
    if (originalDate && originalDate.trim() !== '') {
      loadSwapCandidates(originalDate, targetDate);
    } else {
      // Xử lý trường hợp originalDate null/empty
      const $sel = $("#swap-with-user-id");
      $sel
        .empty()
        .append("<option disabled selected>Chưa chọn ngày gốc</option>")
        .prop("disabled", true)
        .trigger("change");
    }
  } 
});
document.addEventListener("DOMContentLoaded", function () {
  showFlashToasts();
  maybeShowErrorModal();
  showLoadding(false);

  // Refetch chỉ khi toast THÀNH CÔNG đã đóng
  var container = document.getElementById("toastContainer");
  if (container) {
    container.querySelectorAll(".toast").forEach(function (el) {
      el.parentNode.removeChild(el);
      el.addEventListener(
        "hidden.bs.toast",
        function () {
          var isSuccess =
            el.classList.contains("text-bg-success") ||
            el.classList.contains("bg-success");
          if (!isSuccess) return;

          if (typeof calendarSchedule !== "undefined" && calendarSchedule) {
            calendarSchedule.refetchEvents();
            if (typeof renderShiftIndicators === "function") {
              setTimeout(renderShiftIndicators, 100);
            }
          } else {
            location.reload();
          }
        },
        { once: true }
      );
    });
  }

  // Khi đổi loại đề xuất -> nếu là đổi ca thì load danh sách ứng viên
  const typeSel = document.getElementById("request-type");
  typeSel.addEventListener("change", () => {
    // Code cũ - 17/09/2025: Gọi loadSwapCandidates() không có tham số
    // if (typeSel.value === "shift-change") loadSwapCandidates();
    
    // Code mới - 17/09/2025: Kiểm tra và truyền tham số đúng
    if (typeSel.value === "shift-change") {
      const $sec = $("#section-shift-change");
      const originalDate = $sec.find('input[name="original_date"]').val();
      const targetDate = $sec.find('input[name="target_date"]').val() || originalDate;
      
      if (originalDate && originalDate.trim() !== '') {
        loadSwapCandidates(originalDate, targetDate);
      } else {
        // Xử lý trường hợp originalDate null/empty
        const $sel = $("#swap-with-user-id");
        $sel
          .empty()
          .append("<option disabled selected>Chưa chọn ngày gốc</option>")
          .prop("disabled", true)
          .trigger("change");
      }
    }
  });

  // Submit AJAX form đề xuất
  const form = document.getElementById("form_request_attend");
  form.addEventListener("submit", function (e) {
    e.preventDefault();

    // đi công tác
    // 🔍 Kiểm tra ngày công tác không bỏ trống nếu là đề xuất công tác
    const requestType = document.getElementById("request-type")?.value;
    if (requestType === "work-trip") {
      const tripRangeInput = document.getElementById("business_trip_range");
      if (!tripRangeInput || tripRangeInput.value.trim() === "") {
        pushToast("Vui lòng chọn ngày đi công tác.", false);
        return;
      }
    }
    // 🔍 Kiểm tra lý do không bỏ trống
    const reasonInput = form.querySelector("textarea[name='reason']");
    if (!reasonInput || reasonInput.value.trim() === "") {
      pushToast("Vui lòng nhập lý do.", false);
      return;
    }

    // Code cũ - 17/09/2025: Không kiểm tra người duyệt bắt buộc
    // Code mới - 17/09/2025: Kiểm tra người duyệt không bỏ trống
    const approverSelect = document.getElementById("approverSelect");
    if (!approverSelect || !approverSelect.value || approverSelect.value.trim() === "") {
      pushToast("Vui lòng chọn người duyệt.", false);
      return;
    }

    // Code cũ - 17/09/2025: Không kiểm tra original-date bắt buộc
    // Code mới - 17/09/2025: Kiểm tra original-date không bỏ trống cho các loại đề xuất cần thiết
    if (requestType === "early-check-out" || requestType === "late-check-in" || requestType === "shift-change") {
      const originalDateInput = form.querySelector('input[name="original_date"]');
      if (!originalDateInput || originalDateInput.value.trim() === "") {
        pushToast("Vui lòng chọn ngày làm việc.", false);
        return;
      }
    }

    // Code cũ - 17/09/2025: Không kiểm tra target_date và swap_with_user_id bắt buộc
    // Code mới - 17/09/2025: Kiểm tra target_date không bỏ trống cho đề xuất đổi ca
    if (requestType === "shift-change") {
      const targetDateInput = form.querySelector('input[name="target_date"]');
      if (!targetDateInput || targetDateInput.value.trim() === "") {
        pushToast("Vui lòng chọn ngày đăng ký đổi ca.", false);
        return;
      }

      // Code mới - 17/09/2025: Kiểm tra swap_with_user_id không bỏ trống cho đề xuất đổi ca
      const swapUserSelect = document.getElementById("swap-with-user-id");
      if (!swapUserSelect || !swapUserSelect.value || swapUserSelect.value.trim() === "") {
        pushToast("Vui lòng chọn người đổi ca.", false);
        return;
      }
    }

    // @author: trong.lq
    // @date: 22/10/2025
    // Kiểm tra tuần chỉnh sửa không bỏ trống cho đề xuất chỉnh sửa kế hoạch
    if (requestType === "edit-plan") {
      const planWeekSelect = document.getElementById("plan-week-select");
      if (!planWeekSelect || !planWeekSelect.value || planWeekSelect.value.trim() === "") {
        pushToast("Vui lòng chọn tuần chỉnh sửa.", false);
        return;
      }
    }

    // @author: an.cdb
    // @date: 10/03/2026
    // Kiểm tra compensatory-leave không bỏ trống
    if (requestType === "compensatory-leave") {
      // Kiểm tra ngày làm vượt giờ
      const originalDate = form.querySelector('input[name="original_date"]');
      if (!originalDate || originalDate.value.trim() === "") {
        pushToast("Vui lòng chọn ngày làm vượt giờ.", false);
        return;
      }

      // Kiểm tra ca làm vượt giờ
      const compWorkshift = document.getElementById("comp-workshift");
      if (!compWorkshift || !compWorkshift.value) {
          pushToast("Vui lòng chọn ca làm vượt giờ.", false);
          return;
      }

      // Kiểm tra ngày bù
      const leaveDate = form.querySelector('input[name="leave_date"]');
      if (!leaveDate || leaveDate.value.trim() === "") {
        pushToast("Vui lòng chọn ngày bù.", false);
        return;
      }

      // Kiểm tra ca nghỉ bù
      const leaveWorkshift = document.getElementById("leave-workshift");
      if (!leaveWorkshift || !leaveWorkshift.value || leaveWorkshift.value.trim() === "") {
        pushToast("Không có ca làm việc ngày " + (originalDate?.value || "...") + ". Vui lòng chọn ca nghỉ bù.", false);
        return;
      }
    }

    if (requestType === "early-check-out" || requestType === "late-check-in") {
      const sel = document.getElementById("shiftSelectChangecheck");
      const input = document.getElementById("request-time");
      const r = sel ? getRangeFromSelect(sel) : null;

      // Code cũ - 17/09/2025: Không kiểm tra ca làm việc bắt buộc
      // Code mới - 17/09/2025: Kiểm tra ca làm việc không bỏ trống
      if (!sel || !sel.value || sel.value.trim() === "") {
        pushToast("Vui lòng chọn ca làm việc.", false);
        return;
      }

      if (!input?.value) {
        pushToast("Vui lòng nhập thời gian.", false);
        return;
      }
      if (r && !inRange(input.value, r.min, r.max)) {
        reportRangeError(input, r);
        return;
      }
    }

    if (
      requestType === "additional-check-in" ||
      requestType === "additional-check-out"
    ) {
      const sel = document.getElementById("shiftSelectAdditional");
      const input = document.getElementById("additional-time");
      const r = sel ? getRangeFromSelect(sel) : null;

      // Code cũ - 17/09/2025: Không kiểm tra ca làm việc bắt buộc
      // Code mới - 17/09/2025: Kiểm tra ca làm việc không bỏ trống
      if (!sel || !sel.value || sel.value.trim() === "") {
        pushToast("Vui lòng chọn ca làm việc.", false);
        return;
      }

      if (!input?.value) {
        pushToast("Vui lòng nhập giờ.", false);
        return;
      }
      // if (r && !inRange(input.value, r.min, r.max)) {
      //   reportRangeError(input, r);
      //   return;
      // }
    }

    if (requestType === "update-shift") {
      const selUpdate = document.getElementById("shiftSelectUpdate");
      const opt = selUpdate?.options[selUpdate.selectedIndex];
      const type = opt?.getAttribute("data-shift-type");

      // Code cũ - 17/09/2025: Không kiểm tra ca làm việc bắt buộc
      // Code mới - 17/09/2025: Kiểm tra ca làm việc không bỏ trống
      if (!selUpdate || !selUpdate.value || selUpdate.value.trim() === "") {
        pushToast("Vui lòng chọn ca làm việc.", false);
        return;
      }

      const morningIn = document.getElementById("morning-check-in");
      const morningOut = document.getElementById("morning-check-out");
      const afternoonIn = document.getElementById("afternoon-check-in");
      const afternoonOut = document.getElementById("afternoon-check-out");

      // Kiểm tra phút phải chia hết cho 5 (0, 5, 10, 15, ...)
      const timeInputs = [morningIn, morningOut, afternoonIn, afternoonOut];
      for (const input of timeInputs) {
        if (input?.value) {
          const [hours, minutes] = input.value.split(':');
          const minuteValue = parseInt(minutes);
          if (minuteValue % 5 !== 0) {
            pushToast(`Thời gian ${input.value} không hợp lệ. Phút phải là bội số của 5 (0, 5, 10, 15, ...)`, false);
            input.focus();
            return;
          }
        }
      }

      // 1) vào <= ra nếu cả 2 có giá trị
      if (
        morningIn?.value &&
        morningOut?.value &&
        morningIn.value > morningOut.value
      ) {
        pushToast("Giờ vào ca sáng không được lớn hơn giờ ra.", false);
        return;
      }
      if (
        afternoonIn?.value &&
        afternoonOut?.value &&
        afternoonIn.value > afternoonOut.value
      ) {
        pushToast("Giờ vào ca chiều không được lớn hơn giờ ra.", false);
        return;
      }

      // 2) kiểm tra theo range đã gán
      if (type === "full") {
        const mId = opt.getAttribute("data-morning-id");
        const aId = opt.getAttribute("data-afternoon-id");
        const rM = getRangeByShiftId(selUpdate, mId);
        const rA = getRangeByShiftId(selUpdate, aId);

        if (rM) {
          if (morningIn?.value && !inRange(morningIn.value, rM.min, rM.max))
            return reportRangeError(morningIn, rM);
          if (morningOut?.value && !inRange(morningOut.value, rM.min, rM.max))
            return reportRangeError(morningOut, rM);
        }
        if (rA) {
          if (afternoonIn?.value && !inRange(afternoonIn.value, rA.min, rA.max))
            return reportRangeError(afternoonIn, rA);
          if (
            afternoonOut?.value &&
            !inRange(afternoonOut.value, rA.min, rA.max)
          )
            return reportRangeError(afternoonOut, rA);
        }
      } else if (type === "morning") {
        const r = getRangeFromSelect(selUpdate);
        if (r) {
          if (morningIn?.value && !inRange(morningIn.value, r.min, r.max))
            return reportRangeError(morningIn, r);
          if (morningOut?.value && !inRange(morningOut.value, r.min, r.max))
            return reportRangeError(morningOut, r);
        }
      } else if (type === "afternoon") {
        const r = getRangeFromSelect(selUpdate);
        if (r) {
          if (afternoonIn?.value && !inRange(afternoonIn.value, r.min, r.max))
            return reportRangeError(afternoonIn, r);
          if (afternoonOut?.value && !inRange(afternoonOut.value, r.min, r.max))
            return reportRangeError(afternoonOut, r);
        }
      }

      // ✅ Kiểm tra tổng thời gian chính xác 8 giờ cho ca "Cả ngày"
      if (type === "full") {
        const morningDuration = calculateWorkDuration(morningIn?.value, morningOut?.value);
        const afternoonDuration = calculateWorkDuration(afternoonIn?.value, afternoonOut?.value);
        const totalDuration = morningDuration + afternoonDuration;
        
        // Kiểm tra chính xác 8 giờ (không cho phép sai số)
        if (totalDuration !== 8) {
          pushToast(`Tổng thời gian làm việc phải chính xác 8 giờ. Hiện tại: ${totalDuration.toFixed(1)} giờ (Ca sáng: ${morningDuration.toFixed(1)}h, Ca chiều: ${afternoonDuration.toFixed(1)}h)`, false);
          return;
        }
      }

      // ✅ Kiểm tra thời gian ca sáng/chiều với attendanceMap
      // Lấy originalDateInput từ section update-shift (không bị hide)
      const updateShiftSection = document.getElementById("section-update-shift");
      const originalDateInput = updateShiftSection ? updateShiftSection.querySelector('input[name="original_date"]') : null;
      if (originalDateInput && originalDateInput.value) {
        const dateStr = originalDateInput.value;
        
        if (type === "morning") {
          const formDuration = calculateWorkDuration(morningIn?.value, morningOut?.value);
          const attendanceDuration = getShiftDurationFromAttendanceMap(dateStr, "MORNING");
          
          if (attendanceDuration !== null && formDuration !== attendanceDuration) {
            pushToast(`Thời gian ca sáng phải chính xác bằng thời gian theo kế hoạch. Đăng ký cập nhật ca: ${formatDurationToHoursMinutes(formDuration)}, Ca đăng ký theo kế hoạch: ${formatDurationToHoursMinutes(attendanceDuration)}`, false);
            return;
          }
        } else if (type === "afternoon") {
          const formDuration = calculateWorkDuration(afternoonIn?.value, afternoonOut?.value);
          const attendanceDuration = getShiftDurationFromAttendanceMap(dateStr, "AFTERNOON");
          
          if (attendanceDuration !== null && formDuration !== attendanceDuration) {
            pushToast(`Thời gian ca chiều phải chính xác bằng thời gian theo kế hoạch. Đăng ký cập nhật ca: ${formatDurationToHoursMinutes(formDuration)}, Ca đăng ký theo kế hoạch: ${formatDurationToHoursMinutes(attendanceDuration)}`, false);
            return;
          }
        }
      }
    }

    // Gửi AJAX
    if (typeof showLoadding === "function") showLoadding(true);

    const formData = new FormData(form);
    fetch(form.action, {
      method: "POST",
      body: formData,
      headers: {
        "X-CSRF-Token": document.querySelector("meta[name='csrf-token']")
          .content,
      },
    })
      .then(async (resp) => {
        const isJson = resp.headers
          .get("content-type")
          ?.includes("application/json");
        const data = isJson ? await resp.json() : {};
        return { ok: resp.ok, data };
      })
      .then(({ ok, data }) => {
        if (typeof showLoadding === "function") showLoadding(false);

        const success = !!data.success && ok;
        const msg =
          data.message ||
          data.msg ||
          data.error ||
          (success ? "Đã lưu thành công" : "Có lỗi xảy ra");
        const redirectUrl = data.redirect_url || "";

        pushToast(msg, success, redirectUrl);

        if (success) {
          const inst =
            bootstrap.Modal.getInstance(
              document.getElementById("requestModal")
            ) || new bootstrap.Modal(document.getElementById("requestModal"));
          inst.hide();
        }
      })
      .catch((err) => {
        console.error(err);
        if (typeof showLoadding === "function") showLoadding(false);
        pushToast("Lỗi kết nối server", false);
      });
  });

  toggleRequestSections("early-check-out");
});

const CURRENT_USER_ID =
  typeof gon !== "undefined" && gon.user_id ? gon.user_id : null;
function getSelectedRequestType() {
  return $("#request-type").val();
}
// ✅ Gọi hàm xử lý mỗi khi người dùng thay đổi loại ca
$("#shiftSelectUpdate").on("change", updateShiftInputs);
//  Tính số tuần trong năm cho một ngày cụ thể (theo tiêu chuẩn ISO)
function getWeekNumber(input) {
  if (!input) return ""; // rỗng thì trả rỗng

  // chấp nhận cả Date lẫn string "YYYY-MM-DD"
  const d =
    input instanceof Date
      ? new Date(
          Date.UTC(input.getFullYear(), input.getMonth(), input.getDate())
        )
      : new Date(input + (input.length === 10 ? "T00:00:00" : ""));

  if (isNaN(d)) return "";

  // Tính ISO week
  d.setUTCDate(d.getUTCDate() + 4 - (d.getUTCDay() || 7));
  const yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
  return Math.ceil(((d - yearStart) / 86400000 + 1) / 7);
}
//  Hiển thị chi tiết thông tin đề xuất lịch (về sớm, đổi ca, đi muộn, cập nhật ca...)
function showShiftIssuePopup(props, ev) {
  // @author: trong.lq
  // @date: 23/10/2025
  const currentDate =
    props.currentDate ?? moment(ev.start).format("DD/MM/YYYY");
  let timeHTML = "";
  let extraHTML = "";
  switch (props.stype) {
    case "LATE-CHECK-IN":
    case "ADDITIONAL-CHECK-IN":
      timeHTML = `<span class="mb-2">Thời gian: <strong class="text-dark">${
        props.us_start || "-"
      }</strong></span>`;
      break;

    case "EARLY-CHECK-OUT":
    case "ADDITIONAL-CHECK-OUT":
      timeHTML = `<span class="mb-2">Thời gian: <strong class="text-dark">${
        props.us_end || "-"
      }</strong></span>`;
      break;

    case "SHIFT-CHANGE": {
      extraHTML = `
                <span class="mb-2">Đổi ca với: <strong class="text-dark">${
                  props.to_user || "-"
                }</strong></span>
                <span class="mb-2">Ngày đăng ký đổi ca: <strong class="text-dark">${
                  props.to_date || "-"
                }</strong></span>
                <span class="mb-2">Ca cần đổi: <strong class="text-dark">${
                  props.to_workshift || "-"
                }</strong></span>`;
      break;
    }

    case "SHIFT-CHANGE-APPROVED": {
      extraHTML = `
                <span class="mb-2">Đổi ca với: <strong class="text-dark">${
                  props.to_user || "-"
                }</strong></span>
                <span class="mb-2">Ngày bị đổi ca: <strong class="text-dark">${
                  props.to_date || "-"
                }</strong></span>
                <span class="mb-2">Ca bị đổi: <strong class="text-dark">${
                  props.to_workshift || "-"
                }</strong></span>`;
      break;
    }

    case "UPDATE-SHIFT": {
      extraHTML = `<span class="mb-2">Thời gian thay đổi: <strong class="text-dark">${
        `${props.us_start} - ${props.us_end}` || "-"
      }</strong></span>`;
      break;
    }

    case "EDIT-PLAN": {
      // @author: trong.lq
      // @date: 23/10/2025
      // Hiển thị chi tiết cho đề xuất chỉnh sửa kế hoạch làm việc
      extraHTML = `<span class="mb-2">Tuần chỉnh sửa: <strong class="text-dark">${
        props.content || "-"
      }</strong></span>`;
      break;
    }

    // @author: trong.lq
    // @date: 30/10/2025
    // Hiển thị theo yêu cầu: mỗi ngày kèm nhãn ca (ca sáng/ca chiều/ca ngày)
    case "WORK-TRIP": {
      const grouped = Array.isArray(props.grouped_work_trips)
        ? props.grouped_work_trips
        : null;

      if (grouped && grouped.length > 0) {
        const byDate = {};
        grouped.forEach((it) => {
          const dYmd = String(it.work_date || "");
          if (!dYmd) return;
          if (!byDate[dYmd]) byDate[dYmd] = { morning: false, afternoon: false };
          const name = (it.shift_name || "").toLowerCase();
          if (name.includes("sáng")) byDate[dYmd].morning = true;
          else if (name.includes("chiều")) byDate[dYmd].afternoon = true;
          else {
            const st = String(it.start_time || "");
            if (st && st < "12:00") byDate[dYmd].morning = true; else byDate[dYmd].afternoon = true;
          }
        });

        const entries = Object.keys(byDate)
          .sort()
          .map((dYmd) => {
            const d = window.moment ? moment(dYmd).format("DD-MM-YYYY") : dYmd.split("-").reverse().join("-");
            const f = byDate[dYmd];
            let label = "";
            if (f.morning && f.afternoon) label = "cả ngày";
            else if (f.morning) label = "ca sáng";
            else if (f.afternoon) label = "ca chiều";
            else label = "ca";
            return `<div class=\"mb-1\">📅 <strong>${d}</strong>: <strong>${label}</strong></div>`;
          })
          ;

        const mid = Math.ceil(entries.length / 2);
        const col1 = entries.slice(0, mid).join("");
        const col2 = entries.slice(mid).join("");

        extraHTML = `
          <div class=\"mt-1\">\n            <div class=\"mb-2\">Chi tiết công tác theo ngày:</div>\n            <div class=\"row\">\n              <div class=\"col-12 col-md-6\">${col1}</div>\n              <div class=\"col-12 col-md-6\">${col2}</div>\n            </div>\n          </div>`;
      } else {
        const dateText = props.currentDate || "-";
        const label = (props.current_workshift || "").toLowerCase();
        let sum = "ca";
        if (label.includes("cả ngày")) sum = "cả ngày";
        else if (label.includes("sáng")) sum = "ca sáng";
        else if (label.includes("chiều")) sum = "ca chiều";
        extraHTML = `
          <div class=\"mt-1\">\n            <div class=\"mb-2\">Chi tiết công tác:</div>\n            <div>📅 <strong>${dateText}</strong>: <strong>${sum}</strong></div>\n          </div>`;
      }
      break;
    }

    // @author: an.cdb - @date: 10/03/2026 - Thêm chi tiết cho đề xuất nghỉ bù
    case "COMPENSATORY-LEAVE": {
      extraHTML = `<span class="mb-2">Chi tiết nghỉ bù: <strong class="text-dark">${props.content || "-"}</strong></span>`;
      break;
    }
  }

  // @author: trong.lq
  // @date: 30/10/2025
  // Ẩn dòng "Ca hiện tại" cho WORK-TRIP vì đã có chi tiết theo ngày bên dưới
  const currentShiftHtml = props.stype === "WORK-TRIP" ? "" : `
      <span class="mb-2">Ca hiện tại: <strong class="text-dark">${
        props.current_workshift || "-"
      }</strong></span>`;

  // Ẩn dòng "Ngày làm việc" cho WORK-TRIP
  const currentDateHtml = props.stype === "WORK-TRIP" ? "" : `
      <span class="mb-2">Ngày làm việc: <strong class="text-dark">${
        currentDate || "-"
      }</strong></span>`;

  const html = `
    <div class="col-12 row text-left">
      <span class="mb-2">Trạng thái: <strong class="${mapStatusClass(
        props.status
      )}">${mapStatus(props.status) || "-"}</strong></span>
      ${currentDateHtml}
      ${currentShiftHtml}
      <span class="mb-2">Người xử lý: <strong class="text-dark">${
        props.approved_by || "-"
      }</strong></span>
      ${timeHTML}
      ${extraHTML}
      <span class="mb-2">Lý do: <strong class="text-dark">${
        props.note || "-"
      }</strong></span>
      <span class="mb-2">Minh chứng:</span>
      <div class="ms-3 d-flex justify-content-center border rounded w-100 h-50">
        <img class="img-fluid w-75" style="max-width: 75%" src="${
          props.docs || avatar_url
        }">
      </div>
    </div>`;

  $("#proposalTitle").text(
    `Chi tiết đề xuất ${titleMap[props.stype.replace(/-/g, "_")]}`
  );
  $("#proposalModalBody").html(html);
  $("#proposalModal").modal("show");
}
const titleMap = {
  EARLY_CHECK_OUT: "về sớm",
  LATE_CHECK_IN: "đi trễ",
  SHIFT_CHANGE: "đổi ca",
  SHIFT_CHANGE_APPROVED: "đổi ca",
  WORK_TRIP: "đi công tác",
  UPDATE_SHIFT: "cập nhật ca",
  ADDITIONAL_CHECK_IN: "chấm công vào làm bù",
  ADDITIONAL_CHECK_OUT: "chấm công tan làm bù",
  EDIT_PLAN: "chỉnh sửa kế hoạch làm việc",
  COMPENSATORY_LEAVE: "nghỉ bù",
};

function mapStatusClass(status) {
  switch (status) {
    case "APPROVED":
      return "badges badges-success";
    case "PENDING":
      return "badges badges-warning";
    case "REJECTED":
      return "badges badges-danger";
    default:
      return "";
  }
}

function mapStatus(status) {
  switch (status) {
    case "APPROVED":
      return "Đã phê duyệt";
    case "PENDING":
      return "Chờ phê duyệt";
    case "REJECTED":
      return "Từ chối";
    default:
      return "";
  }
}
function clearAppToasts() {
  const container = document.getElementById("toastContainer");
  if (container) {
    container.innerHTML = ""; // Xoá hết
  }
}
function showFlashToasts() {
  var container = document.getElementById("toastContainer");
  if (!container) return;

  if (window._didPostSuccessRefresh === undefined) {
    window._didPostSuccessRefresh = false;
  }

  container.querySelectorAll(".toast").forEach(function (el) {
    // ✅ tránh khởi tạo lặp lại 1 toast
    if (el.dataset.inited === "1") return;
    el.dataset.inited = "1";

    var isSuccess =
      el.classList.contains("text-bg-success") ||
      el.classList.contains("bg-success");

    // Tự đóng sau 7s (success & error đều đóng)
    var t = new bootstrap.Toast(el, { delay: 2000, autohide: true });
    t.show();

    el.addEventListener(
      "hidden.bs.toast",
      function () {
        // ✅ remove khỏi DOM khi đã ẩn
        try {
          el.remove();
        } catch {}

        // ✅ chỉ redirect/refetch đúng 1 lần nếu là toast success
        if (isSuccess) {
          if (window._didPostSuccessRefresh) return;
          window._didPostSuccessRefresh = true;

          if (typeof showLoadding === "function") showLoadding(false);

          var redirectUrl = el.dataset.redirectUrl;
          if (redirectUrl) {
            window.location.href = redirectUrl;
          } else if (
            typeof calendarSchedule !== "undefined" &&
            calendarSchedule
          ) {
            calendarSchedule.refetchEvents();
            if (typeof renderShiftIndicators === "function") {
              setTimeout(renderShiftIndicators, 100);
            }
          } else {
            location.reload();
          }
        } else {
          if (typeof showLoadding === "function") showLoadding(false);
        }
      },
      { once: true }
    );
  });
}

// Nếu có thông điệp lỗi trong #errorModal .modal-body thì show modal
function maybeShowErrorModal() {
  var modalEl = document.getElementById("errorModal");
  if (!modalEl) return;
  var body = modalEl.querySelector(".modal-body");
  if (body && (body.textContent || "").trim().length) {
    try {
      new bootstrap.Modal(modalEl).show();
    } catch (_) {}
  }
}
////Upload & preview minh chứng
// xét hình ảnh
function onSelectEvidence(input) {
  const file = input.files && input.files[0];
  const preview = document.getElementById("evidence-preview");
  const msg = document.getElementById("valid-message");

  if (!file) {
    preview.style.backgroundImage = "";
    preview.style.height = "80px"; // Quay lại nhỏ khi không có ảnh
    msg.textContent = "";
    return;
  }

  const reader = new FileReader();
  reader.onload = (e) => {
    preview.style.backgroundImage = `url('${e.target.result}')`;
    preview.style.height = "280px"; // Chiều cao khi đã upload ảnh
    msg.textContent = "";
  };
  reader.readAsDataURL(file);
}

function clickSelectEvidence() {
  document.getElementById("image-evidence-edit").click();
}
////
document
  .getElementById("requestModal")
  .addEventListener("hidden.bs.modal", () => {
    document.getElementById("evidence-preview").style.backgroundImage = "";
    document.getElementById("evidence-preview").style.height = "80px"; // Reset lại nhỏ
    document.getElementById("image-evidence-edit").value = "";
    document.getElementById("valid-message").textContent = "";
  });

function getRangeFromSelect(selectEl) {
  if (!selectEl) return null;
  const opt = selectEl.options[selectEl.selectedIndex];
  if (!opt) return null;
  const min = opt.getAttribute("data-min") || "";
  const max = opt.getAttribute("data-max") || "";
  return { min, max };
}

// NOTE: helper set range + error
function setInputRangeBySelect(selectEl, inputEl) {
  if (!selectEl || !inputEl) return;
  const r = getRangeFromSelect(selectEl);
  if (r) setRange(inputEl, r.min, r.max);
}

function reportRangeError(input, r) {
  // 1. Hiển thị thông báo
  pushToast(`Thời gian phải nằm trong khoảng ${r.min} – ${r.max}`, false);
}

function getRangeByShiftId(selectEl, id) {
  if (!selectEl || !id) return null;
  const opt = Array.from(selectEl.options).find(
    (o) => String(o.value) === String(id)
  );
  if (!opt) return null;
  return {
    min: opt.getAttribute("data-min") || "",
    max: opt.getAttribute("data-max") || "",
  };
}

// NOTE: áp range cho toàn bộ form theo select hiện tại
function applyAllRanges() {
  // Early/Late
  const selEarlyLate = document.getElementById("shiftSelectChangecheck");
  const timeEarlyLate = document.getElementById("request-time");
  if (selEarlyLate && timeEarlyLate) {
    const setEL = () => setInputRangeBySelect(selEarlyLate, timeEarlyLate);
    selEarlyLate.addEventListener("change", setEL);
    setEL();
  }

  // Additional
  const selAdditional = document.getElementById("shiftSelectAdditional");
  const timeAdditional = document.getElementById("additional-time");
  if (selAdditional && timeAdditional) {
    const setAD = () => setInputRangeBySelect(selAdditional, timeAdditional);
    // Bỏ valid giờ vào, giờ ra của đề xuất chấm công bù
    // selAdditional.addEventListener("change", setAD);
    // setAD();
  }

  // Update-shift
  const selUpdate = document.getElementById("shiftSelectUpdate");
  const morningIn = document.getElementById("morning-check-in");
  const morningOut = document.getElementById("morning-check-out");
  const afternoonIn = document.getElementById("afternoon-check-in");
  const afternoonOut = document.getElementById("afternoon-check-out");

  if (selUpdate && (morningIn || afternoonIn)) {
    const setUP = () => {
      const opt = selUpdate.options[selUpdate.selectedIndex];
      if (!opt) return;
      const type = opt.getAttribute("data-shift-type"); // full/morning/afternoon
      
      // Gọi updateShiftInputs để set thời gian mặc định cho ca sáng
      updateShiftInputs();

      if (type === "full") {
        // lấy min/max theo 2 option id đã gắn ở "Cả ngày"
        const mId = opt.getAttribute("data-morning-id");
        const aId = opt.getAttribute("data-afternoon-id");
        const rM = getRangeByShiftId(selUpdate, mId);
        const rA = getRangeByShiftId(selUpdate, aId);
        if (rM) {
          setRange(morningIn, rM.min, rM.max);
          setRange(morningOut, rM.min, rM.max);
        }
        if (rA) {
          setRange(afternoonIn, rA.min, rA.max);
          setRange(afternoonOut, rA.min, rA.max);
        }
      } else if (type === "morning") {
        const r = getRangeFromSelect(selUpdate);
        if (r) {
          setRange(morningIn, r.min, r.max);
          setRange(morningOut, r.min, r.max);
        }
        // ẩn chiều thì thôi
      } else if (type === "afternoon") {
        const r = getRangeFromSelect(selUpdate);
        if (r) {
          setRange(afternoonIn, r.min, r.max);
          setRange(afternoonOut, r.min, r.max);
        }
      }
    };
    selUpdate.addEventListener("change", setUP);
    setUP();
  }
}

function pushToast(message, isSuccess, redirectUrl) {
  var ctn = document.getElementById("toastContainer");
  if (!ctn) return;

  var cls = isSuccess ? "text-bg-success" : "text-bg-danger";
  var extra =
    isSuccess && redirectUrl ? ` data-redirect-url="${redirectUrl}"` : "";

  var html = `
    <div class="toast align-items-center ${cls} border-0" role="alert" aria-live="assertive" aria-atomic="true"${extra}>
      <div class="d-flex">
        <div class="toast-body">
          ${message || (isSuccess ? "Thành công" : "Có lỗi xảy ra")}
        </div>
        <button type="button" class="btn-close me-2 m-auto" data-bs-dismiss="toast"></button>
      </div>
    </div>
  `;
  ctn.insertAdjacentHTML("beforeend", html);
  showFlashToasts();
}

function normalizeTime(t) {
  if (!t) return "";
  const parts = t.split(":");
  const hh = String(parts[0]).padStart(2, "0");
  const mm = String(parts[1] || "00").padStart(2, "0");
  const ss = String(parts[2] || "00").padStart(2, "0");
  return `${hh}:${mm}:${ss}`;
}

function addMinutesISO(iso, minutes) {
  const d = new Date(iso);
  d.setMinutes(d.getMinutes() + minutes);
  return d.toISOString().slice(0, 19); // YYYY-MM-DDTHH:mm:ss
}

/** Tạo events từ attendanceMap, chỉ lấy trong phạm vi view hiện tại */
function buildCheckpointEventsFromAttendance(calendar) {
  const start = calendar.view.activeStart;
  const end = calendar.view.activeEnd;

  const inRange = (dateKey) => {
    const d = new Date(dateKey + "T00:00:00");
    return d >= start && d < end;
  };

  const out = [];

  Object.entries(attendanceMap || {}).forEach(([dateKey, shifts]) => {
    if (!inRange(dateKey)) return;

    ["MORNING", "AFTERNOON"].forEach((shiftType) => {
      const s = shifts?.[shiftType];
      if (!s) return;

      const isDayOff = s.is_day_off;

      // ✅ Giờ mặc định cho mỗi ca (nếu không có giờ cụ thể)
      const baseTimeStart = `${dateKey}T${
        shiftType === "MORNING" ? "08:00:00" : "13:00:00"
      }`;
      const baseTimeEnd = `${dateKey}T${
        shiftType === "MORNING" ? "12:00:00" : "17:00:00"
      }`;

      if (isDayOff) {
        let title = "",
          color = "",
          className = "",
          textColor = "#ffffff";

        switch (isDayOff) {
          case "OFF":
            title = "❌ Nghỉ hàng tuần";
            color = "#000000";
            className = "fc-off";
            break;
          case "HOLIDAY":
            title = "📅 Nghỉ lễ";
            color = "#dc3545";
            className = "fc-holiday";
            break;
          case "ON-LEAVE":
            title = "💤 Nghỉ phép";
            color = "#94a3b8";
            className = "fc-leave";
            textColor = "#1b53a7";
            break;
        }

        out.push({
          id: `off-${dateKey}-${shiftType}`,
          title,
          start: baseTimeStart,
          end: baseTimeEnd,
          allDay: false,
          color,
          textColor,
          classNames: [className],
        });
      }

      // ✅ Nếu không nghỉ → hiển thị giờ làm việc
      const ci =
        s.registered_shift_start_time &&
        normalizeTime(s.registered_shift_start_time);
      const co =
        s.registered_shift_end_time &&
        normalizeTime(s.registered_shift_end_time);

      if (!isDayOff && ci) {
        const startISO = `${dateKey}T${ci}`;
        out.push({
          id: `ci-${dateKey}-${shiftType}`,
          title: "✅ Vào làm",
          start: startISO,
          end: addMinutesISO(startISO, 5),
          allDay: false,
          color: "#e0f2fe",
          textColor: "#1b53a7",
          classNames: ["fc-checkin"],
        });
      }

      if (!isDayOff && co) {
        const startISO = `${dateKey}T${co}`;
        out.push({
          id: `co-${dateKey}-${shiftType}`,
          title: "🏁 Tan làm",
          start: startISO,
          end: addMinutesISO(startISO, 5),
          allDay: false,
          color: "#e0f2fe",
          textColor: "#1b53a7",
          classNames: ["fc-checkout"],
        });
      }
    });
  });

  return out;
}

/** Render/check refresh events giờ khi đang ở timeGridWeek/Day */
function renderWeekCheckpointsIfNeeded(calendar) {
  if (!calendar) return;
  const t = calendar.view.type;
  if (t !== "timeGridWeek") return;
  if (!attendanceMap || !Object.keys(attendanceMap).length) return;

  // xoá source cũ (nếu có)
  const old = calendar.getEventSourceById(WEEK_POINT_SOURCE_ID);
  if (old) old.remove();

  // thêm source mới
  const points = buildCheckpointEventsFromAttendance(calendar);
  calendar.addEventSource({ id: WEEK_POINT_SOURCE_ID, events: points });
}

function formatDate(date) {
  if (!(date instanceof Date)) return "";

  const year = date.getFullYear();
  const month = String(date.getMonth() + 1).padStart(2, "0");
  const day = String(date.getDate()).padStart(2, "0");
  return `${year}-${month}-${day}`; // YYYY-MM-DD
}

function calculateTotalDays() {
  const container = document.getElementById("business-trip-shift-container");
  const rows = container.querySelectorAll(".shift-row"); // Mỗi dòng ứng với 1 ngày

  let total = 0;

  rows.forEach((row) => {
    const radios = row.querySelectorAll("input[type='radio']");
    radios.forEach((r) => {
      if (r.checked) {
        if (r.value === "Cả ngày") total += 1;
        else total += 0.5;
      }
    });
  });
  document.getElementById("total_days_selected").value = total;
}

/**
 * Hiển thị hoặc ẩn khu vực footer của đi công tác
 * (bao gồm chọn số dòng hiển thị và tổng số ngày)
 * tùy theo số lượng ngày đã chọn.
 *
 * @param {Date[]} dates - Danh sách ngày đã chọn
 */
function toggleTripFooter(dates) {
  const wrapper = document.getElementById("business-trip-wrapper");
  if (wrapper) {
    wrapper.classList.toggle("d-none", dates.length === 0);
  }
}

// 🧩 Hàm phân trang các dòng ca làm việc hiển thị theo trang
function paginateShiftRows() {
  const allRows = document.querySelectorAll(
    "#business-trip-shift-container .shift-row"
  );
  const totalPages = Math.ceil(allRows.length / rowsPerPage);

  if (currentPage > totalPages) currentPage = totalPages || 1;

  const start = (currentPage - 1) * rowsPerPage;
  const end = currentPage * rowsPerPage;

  allRows.forEach((row, index) => {
    const shouldShow = index >= start && index < end;
    row.classList.toggle("hidden-row", !shouldShow);
  });

  updatePageIndicator(currentPage, totalPages);
}

// 🔢 Cập nhật hiển thị số trang
function updatePageIndicator(current, total) {
  const currentEl = document.getElementById("current-page");
  const totalEl = document.getElementById("total-pages");
  if (currentEl && totalEl) {
    currentEl.textContent = current;
    totalEl.textContent = total;
  }
}

// ⏪⏩ Gọi khi bấm nút chuyển trang
function goToPage(direction) {
  const allRows = document.querySelectorAll(
    "#business-trip-shift-container .shift-row"
  );
  const totalPages = Math.ceil(allRows.length / rowsPerPage);

  if (direction === "prev" && currentPage > 1) {
    currentPage--;
  } else if (direction === "next" && currentPage < totalPages) {
    currentPage++;
  }

  paginateShiftRows();
}

// 🔄 Sự kiện: thay đổi số dòng/trang
document.getElementById("rowsPerPage").addEventListener("change", (e) => {
  rowsPerPage = parseInt(e.target.value, 10);
  currentPage = 1;
  paginateShiftRows();
});

document.addEventListener("DOMContentLoaded", () => {
  const prevBtn = document.getElementById("prev-page");
  const nextBtn = document.getElementById("next-page");

  if (prevBtn) {
    prevBtn.addEventListener("click", () => goToPage("prev"));
  }

  if (nextBtn) {
    nextBtn.addEventListener("click", () => goToPage("next"));
  }
});
