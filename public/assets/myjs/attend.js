let workshifts = null;
let allManagers = null;
let calendarWorkshifts, today = dayjs().startOf('day');
let weeks = [];
let activeWeekId = null;
let holidayMap = {};
let leaveMap   = {};
let leaveLabelMap = {};
let teachingMap = {};
let teachingLabelMap = {};
let workLocations = [];
let defaultLocation = "";
dayjs.extend(window.dayjs_plugin_isoWeek);
const MAX_WEEKS = 4;
const DATE_RE = /^\d{4}-\d{2}-\d{2}$/;
const DATE_RE_DMY = /^\d{2}\/\d{2}\/\d{4}$/;
const isBetween = (val, from, to) => val >= from && val <= to;
const WEEK_LABEL = (d) => `Tuần ${dayjs(d).isoWeek()}`;
document.getElementById('save-draft').addEventListener('click', e => {
    e.preventDefault();
    handleSubmit('DRAFT');
});
document.getElementById('save-selections').addEventListener('click', e => {
    e.preventDefault();
    handleSubmit('SUBMIT');
});
document.getElementById('btnAddWeek').addEventListener('click', e => {
    e.preventDefault();
    handleAddWeek();
});

document.addEventListener('DOMContentLoaded', () => {
    const msg = localStorage.getItem('successMessage');
    if (msg) {
        showAlert(msg, 'success');
        localStorage.removeItem('successMessage');
    }
});

$('#workshiftModal').on('shown.bs.modal', function () {
    calendarWorkshifts.render();
    calendarWorkshifts.updateSize();
    highlightWeek(activeWeekId);
    drawSpecialFlags();
    const optionsHtml = allManagers.map(a =>
        `<option value="${a.user_id}">${a.name}</option>`
    ).join('');
    $('#approverWorkshift').html(optionsHtml);
    const wk = weeks.find(w => w.id === activeWeekId);
    const isDisableBtn = wk && (wk.status === 'PENDING' || wk.status === 'APPROVED');
    syncApproverSelect(activeWeekId, isDisableBtn);

    $('#approverWorkshift').off('change').on('change', function () {
        setApproverForWeek(activeWeekId, this.value);
    });
});

$(document).ready(function () {
    // Xử lý show modal đăng ký lịch làm việc
    $('#register-workshift').on('click', function (e) {
        e.preventDefault();
        openModal();
    });
});

function clickSelectEvidence() {
    $('#image-evidence-edit').click();
}

function onSelectEvidence(input) {
    let file = input.files[0];
    showPreviewEvidence(file);
}

function showPreviewEvidence(file) {
    let file_Mb = (file.size / 1024 / 1024).toFixed(1);

    // valid file size
    if (file_Mb > 3) {
        $('#upload-evidence').find('#valid-message').html(`Ảnh bạn vừa chọn kích thước quá lớn (${file_Mb} MB). <br />Dung lượng ảnh cho phép: dưới 3 MB. <br />Vui lòng chọn ảnh khác!`);
        $('#upload-evidence').find('#valid-message').show();
        return;
    } else {
        $('#upload-evidence').find('#valid-message').html("");
        $('#upload-evidence').find('#valid-message').hide();
    }

    var reader = new FileReader();
    reader.onloadend = function() {
        $('#evidence-preview').css("background-image", `url(${reader.result})`);
    }
    reader.readAsDataURL(file);
}

/* ---------- Open CALENDAR WORKSHIFT modal ---------- */
async function openModal () {
    showLoadding(true);
    if (!workshifts) {
        try {
            const res = await fetch(get_all_workshifts);
            workshifts = await res.json();
        } catch (err) {
            console.error("Lỗi khi tải ca làm việc:", err);
        }
    }
    if (!allManagers) {
        try {
            const res = await fetch(get_all_managers);
            allManagers = await res.json();
        } catch (err) {
            console.error("Lỗi khi tải danh sách phê duyệt:", err);
        }
    }
    if (!calendarWorkshifts) initWorkshiftCalendar();

    if (gon.is_lecturer) {
        await Promise.all([
            loadSpecialDates(),
            loadWorkLocations(),
            loadTeachingSchedules()
        ]);
    } else {
        await Promise.all([
            loadSpecialDates(),
            loadWorkLocations()
        ]);
    }
    renderTemplateShiftRow();

    if (!weeks.length) {
        try {
            const res = await fetch(get_scheduleweeks);
            const json = await res.json();

            if (json.length) {
                let firstWeekId = null;
                json.forEach((data, index) => {
                    const monday = dayjs(data.start_date, 'YYYY-MM-DD');
                    const id = `week-${monday.format('YYYY-MM-DD')}`;
                    if (index === 0) {
                        firstWeekId = id;
                    }
                    buildWeekFromAPI(monday, data)
                });
                switchToWeek(firstWeekId);
            } else {
                const nextMonday = today.add(0, 'week').startOf('isoWeek');
                createWeek(nextMonday);
            }
        } catch (err) { console.error(err); }
    }
    $('#workshiftModal').modal('show');
    showLoadding(false);
}

/* ---------- LOAD NGÀY NGHỈ LỄ VÀ NGÀY PHÉP ---------- */
async function loadSpecialDates () {
    try {
        if (get_holidays) {
            const r1 = await fetch(get_holidays);
            const json = await r1.json();

            if (json && Array.isArray(json.result)) {
                const map = {};
                json.result.forEach(it => {
                    const dISO = toISODate(it.date || it.holiday_date || it.ngay);
                    const name = String(it.subject || it.title || it.name || 'Nghỉ lễ').trim();
                    if (dISO) map[dISO] = name;
                });
                holidayMap = map;
            } else {
                holidayMap = normalizeHolidayResponse(json);
            }
        } else {
            holidayMap = {};
        }

        if (get_user_on_leaves) {
            const r2 = await fetch(get_user_on_leaves);
            const raw = await r2.json();

            if (raw && Array.isArray(raw.result)) {
                const mapSession   = {};
                const mapLabel  = {};

                const toISO = (dStr) => {
                    const s = String(dStr || '').trim();
                    if (DATE_RE.test(s)) return s;
                    if (DATE_RE_DMY.test(s)) {
                        const [dd, mm, yyyy] = s.split('/');
                        return `${yyyy}-${mm}-${dd}`;
                    }
                    return '';
                };

                const mergeSession = (prev, curr) => {
                    if (!prev) return curr;
                    if (prev === 'ALL' || curr === 'ALL') return 'ALL';
                    if ((prev === 'AM' && curr === 'PM') || (prev === 'PM' && curr === 'AM')) return 'ALL';
                    return curr;
                };

                raw.result.forEach(it => {
                    const iso = toISO(it.date);
                    const sess = String(it.session || it.type || '').trim().toUpperCase();
                    const lbl  = it.sholtype;
                    if (!iso) return;
                    if (!['AM','PM','ALL'].includes(sess)) return;

                    mapSession[iso] = mergeSession(mapSession[iso], sess);

                    if (!mapLabel[iso]) {
                        mapLabel[iso] = lbl;
                    } else if (!mapLabel[iso].includes(lbl)) {
                        mapLabel[iso] += ' / ' + lbl;
                    }
                });

                leaveMap      = mapSession;
                leaveLabelMap = mapLabel;
            } else {
                leaveMap      = normalizeLeaveResponse(raw); // fallback cũ
                leaveLabelMap = {};
            }
        } else {
            leaveMap = {};
            leaveLabelMap = {};
        }
    } catch (e) {
        console.warn('Không tải được ngày: ', e);
        holidayMap = {}; leaveMap = {};
    }
}

/* ---------- LOAD ĐỊA ĐIỂM LÀM VIỆC ---------- */
async function loadWorkLocations() {
    try {
        if (!get_campus) return;
        const r = await fetch(get_campus);
        const raw = await r.json();

        let list = [];
        if (raw && Array.isArray(raw.result)) {
            list = raw.result.map(it => ({
                value: it.scode,
                label: (it.name || it.scode || '').trim()
            }));
        } else {
            list = normalizeCampus(raw);
        }

        workLocations   = list || [];
        defaultLocation = workLocations[0]?.value || "";
    } catch (e) {
        console.warn('Không tải được địa điểm làm việc: ', e);
        workLocations = [];
        defaultLocation = "";
    }
}

/* ---------- LOAD LỊCH GIẢNG DẠY CỦA GIẢNG VIÊN ---------- */
async function loadTeachingSchedules () {
    try {
        if (!get_teaching_schedules) { teachingMap = {}; teachingLabelMap = {}; return; }
        const r = await fetch(get_teaching_schedules);
        const raw = await r.json();

        if (raw && Array.isArray(raw.result)) {
            const sessMap = {};
            const labelMap = {};

            const toISO = (dStr) => {
                const s = String(dStr || '').trim();
                if (DATE_RE.test(s)) return s;
                if (DATE_RE_DMY.test(s)) {
                    const [dd, mm, yyyy] = s.split('/');
                    return `${yyyy}-${mm}-${dd}`;
                }
                return '';
            };

            const pushSession = (arr, s) => {
                if (!Array.isArray(arr)) arr = [];
                if (!arr.includes(s)) arr.push(s);
                return arr;
            };

            raw.result.forEach(it => {
                const iso = toISO(it.date);
                const sess = String(it.session || it.type || '').trim().toUpperCase(); // AM|PM|NT
                const lbl  = it.subject;
                if (!iso) return;
                if (!['AM','PM','NT'].includes(sess)) return;

                sessMap[iso] = pushSession(sessMap[iso], sess);

                if (!labelMap[iso]) labelMap[iso] = { AM: '', PM: '', NT: '' };
                if (lbl) {
                    const cur = labelMap[iso][sess];
                    labelMap[iso][sess] = cur ? `${cur} / ${lbl}` : lbl;
                }
            });

            teachingMap = sessMap;
            teachingLabelMap = labelMap;
        } else {
            teachingMap = {}; teachingLabelMap = {};
        }
    } catch (e) {
        console.warn('Không tải được lịch giảng dạy: ', e);
        teachingMap = {}; teachingLabelMap = {};
    }
}

/* ---------- Render KHUNG GIỜ MẪU ---------- */
function renderTemplateShiftRow () {
    const wrap = document.getElementById('templateShiftContainer');
    if (!wrap) return;

    // const optionHTML = makeLocationOptions();

    const label = document.createElement('label');
    label.className = 'form-label fw-bold mb-2 w-100';
    label.textContent = 'Khung giờ mẫu (Áp dụng cho cả tuần)';

    const row = document.createElement('div');
    row.className = 'template-shift-row';

    /*
    row.innerHTML = `
    ${workshifts.map(s => `
      <div class="tpl-group">
        <div class="tpl-label">${s.label}</div>
        <div class="tpl-fields">
          <input type="text"
                 id="tpl-${s.code}-start"
                 class="text-center form-control form-control-sm time-compact"
                 value="${s.start}" readonly>
          <span>→</span>
          <input type="text"
                 id="tpl-${s.code}-end"
                 class="text-center form-control form-control-sm time-compact"
                 value="${s.end}" readonly>
          <select id="tpl-${s.code}-place" class="form-select form-select-sm">
            ${optionHTML}
          </select>
        </div>
      </div>
    `).join('')}
    <button id="btnApplyTemplate" type="button" class="btn btn-primary btn-sm tpl-apply">Áp dụng</button>
  `;
    */

    row.innerHTML = `
    ${workshifts.map(s => `
      <div class="tpl-group">
        <div class="tpl-label">${s.label}</div>
        <div class="tpl-fields">
          <input type="text"
                 id="tpl-${s.code}-start"
                 class="text-center form-control form-control-sm time-compact"
                 value="${s.start}" readonly>
          <span>→</span>
          <input type="text"
                 id="tpl-${s.code}-end"
                 class="text-center form-control form-control-sm time-compact"
                 value="${s.end}" readonly>
          <div id="tpl-${s.code}-place-wrapper">
            ${createLocationDropdownHTML(`tpl-${s.code}-place`)}
          </div>
        </div>
      </div>
    `).join('')}
    <button id="btnApplyTemplate" type="button" class="btn btn-primary btn-sm tpl-apply">Áp dụng</button>
  `;

    wrap.replaceChildren(label, row);
    wrap.classList.remove('d-none');

    const fpCommon = {
        enableTime: true, noCalendar: true, time_24hr: true,
        minuteIncrement: 5, dateFormat: 'H:i', disableMobile: true
    };
    workshifts.forEach(s => {
        flatpickr(`#tpl-${s.code}-start`, { ...fpCommon, minTime: s.min, maxTime: s.max });
        flatpickr(`#tpl-${s.code}-end`,   { ...fpCommon, minTime: s.min, maxTime: s.max });
        // Khởi tạo dropdown checkbox
        initLocationDropdown(`tpl-${s.code}-place`, defaultLocation);
    });

    document.getElementById('btnApplyTemplate')
        .addEventListener('click', e => { e.preventDefault(); applyTemplateToWeek(); });
}

/* ---------- KHỞI TẠO CALENDAR WORKSHIFT ---------- */
function initWorkshiftCalendar() {
    const calendarEl = document.getElementById('calendar');
    calendarWorkshifts = new FullCalendar.Calendar(calendarEl, {
        locale: 'vi',
        firstDay: 1,
        height: 'auto',
        initialView: 'dayGridMonth',
        headerToolbar: { start: 'prev', center: 'title', end: 'next' },
        dateClick: handleDateClick,
        dayCellDidMount: (arg) => {
            if (dayjs(arg.date).isBefore(today)) arg.el.classList.add('fc-past-disabled');
        },
        viewDidMount: () => {
            const prevBtn = calendarEl.querySelector('.fc-prev-button');
            if (prevBtn) {
                prevBtn.classList.remove('fc-button', 'fc-button-primary', 'btn-primary', 'btn-icon');
                prevBtn.classList.add('btn', 'btn-sm', 'btn-falcon-default');
            }
            const nextBtn = calendarEl.querySelector('.fc-next-button');
            if (nextBtn) {
                nextBtn.classList.remove('fc-button', 'fc-button-primary', 'btn-primary', 'btn-icon');
                nextBtn.classList.add('btn', 'btn-sm', 'btn-falcon-default');
            }
        }
    });

    calendarWorkshifts.on('datesSet', () => {
        updateCalendarTitle();
        highlightWeek(activeWeekId);
        drawSpecialFlags();
    });
}

/* ---------- HIỂN THỊ NGÀY LỄ, NGÀY NGHỈ PHÉP LÊN CARLENDAR ---------- */
function drawSpecialFlags() {
    if (!calendarWorkshifts) return;

    const cells = calendarWorkshifts.el.querySelectorAll('.fc-daygrid-day[data-date]');

    cells.forEach(el => {
        // reset
        el.classList.remove('fc-day-holiday', 'fc-day-leave');
        el.querySelectorAll('.fc-day-flag').forEach(n => {
            try {
                const t = window.bootstrap?.Tooltip?.getInstance(n);
                if (t) t.dispose();
            } catch (_) {}
            n.remove();
        });

        const ymd = el.getAttribute('data-date');
        const holidayName = (holidayMap || {})[ymd];
        const hasLeave    = !!(leaveMap || {})[ymd];

        let label = null;
        let type  = null;

        if (holidayName) {
            label = String(holidayName).trim() || 'Nghỉ lễ';
            type  = 'holiday';
        } else if (hasLeave) {
            label = (leaveLabelMap && leaveLabelMap[ymd]) || 'Nghỉ';
            type  = 'leave';
        }

        if (!label) return;

        el.classList.add(type === 'holiday' ? 'fc-day-holiday' : 'fc-day-leave');

        const flag = document.createElement('div');
        flag.className = 'fc-day-flag';
        flag.textContent = label;

        flag.setAttribute('title', label);

        if (window.bootstrap && bootstrap.Tooltip) {
            flag.setAttribute('data-bs-toggle', 'tooltip');
            flag.setAttribute('data-bs-placement', 'top');
            flag.setAttribute('data-bs-title', label);
            bootstrap.Tooltip.getOrCreateInstance(flag);
        }

        const host = el.querySelector('.fc-daygrid-day-top') || el;
        host.appendChild(flag);
    });
}

/* ---------- CLICK NGÀY TRÊN CALENDAR ---------- */
function handleDateClick (info) {
    const clicked = dayjs(info.date);
    if (clicked.isBefore(today)) return;

    const startMonday = clicked.startOf('isoWeek');
    const existing = weeks.find(w => w.start.isSame(startMonday, 'date'));

    if (existing) {
        switchToWeek(existing.id);
    }
}

/* ---------- THÊM TUẦN BẰNG NÚT "+" ---------- */
function handleAddWeek () {
    if (weeks.length >= MAX_WEEKS) return showAlert(`Chỉ được đăng kí tối đa ${MAX_WEEKS} tuần!`, 'warning');

    // tuần mới = max(weeks) + 1 tuần, hoặc next week nếu chưa
    let base = weeks.length ? weeks[weeks.length - 1].start.add(1, 'week') : today.add(1, 'week').startOf('isoWeek');
    createWeek(base);
}

/* ---------- TẠO TUẦN MỚI ---------- */
function createWeek (monday) {
    const weekId = `week-${monday.format('YYYY-MM-DD')}`;

    weeks.push({ id: weekId, start: monday, data: {} });
    buildWeekTab(weekId, monday);
    buildWeekTable(weekId, monday);

    switchToWeek(weekId);
    updateRemoveIcons();
}

/* ---------- SHOW ICON REMOVE ON LAST TAB ---------- */
function updateRemoveIcons () {
    const tabs = [...document.querySelectorAll('#weekTabs li')];
    tabs.forEach(li => li.querySelector('a.remove').classList.add('d-none'));
    const newTabs = tabs.filter(li => li.dataset.new === 'true');
    if (newTabs.length) {
        newTabs[newTabs.length - 1].querySelector('a.remove').classList.remove('d-none');
    }
}

/* ---------- FECTH DATA SCHEDULE WEEK ---------- */
function buildWeekFromAPI (monday, ws) {
    const id = `week-${monday.format('YYYY-MM-DD')}`;
    weeks.push({
        id,
        schedule_id: ws.id,
        start    : monday,
        status   : ws.status,
        checked_by : ws.checked_by,
        reason   : ws.reason || '',
        data     : ws.shift_details
    });
    buildWeekTab(id, monday, ws.status, ws.checked_by);
    buildWeekTable(id, monday, ws.shift_details, ws.status, ws.reason);
    updateRemoveIcons();
}

/* ---------- TẠO TAB NAV ---------- */
function buildWeekTab (id, monday, status = 'TEMP', checked_by = null) {
    const statusProvided = arguments.length >= 3;
    const statusClass = {
        TEMP: 'badges-temp',
        PENDING: 'badges-pending',
        REJECTED: 'badges-reject',
        APPROVED: 'badges-approve'
    }[status] || '';
    const labelStatus = ({
        TEMP    : 'Nháp',
        PENDING : 'Đang chờ duyệt',
        REJECTED: 'Từ chối',
        APPROVED: 'Đã duyệt'
    })[status] || '';

    const navUl = document.getElementById('weekTabs');
    const li = document.createElement('li');
    li.className = 'fs-0 d-flex nav-link nav-week-tab';
    const isNewWeek = !statusProvided;
    li.dataset.new  = isNewWeek;
    li.innerHTML = `
    <a class="week" id="tab-${id}" data-check-by="${checked_by}" data-bs-toggle="tab" href="#pane-${id}" role="tab">
      ${WEEK_LABEL(monday)} ${statusProvided && labelStatus ? `<span class="badges ${statusClass}">${labelStatus}</span>` : ''}
    </a>
    <a class="ms-1 remove"><span class="fas fa-trash fs--1 ms-1 text-danger"></span></a>`;
    updateRemoveIcons();
    navUl.appendChild(li);

    li.querySelector('a.remove').addEventListener('click', (e) => {
        e.preventDefault();
        e.stopPropagation();
        removeWeek(id);
    });
    li.querySelector('a.week').addEventListener('click', () => switchToWeek(id));
}

/* ---------- TẠO BẢNG CA CHI TIẾT ---------- */
function buildWeekTable(id, monday, detail = [], status = 'TEMP', reason = '') {
    const enableNightColumn = gon.is_lecturer;
    const isReadonly = status === 'PENDING' || status === 'APPROVED';
    /* Gom dữ liệu detail thành map[YYYY-MM-DD][workshift_id] */
    const map = {};
    if (detail && detail.length) {
        detail.forEach(d => {
            const ymd = dayjs(d.work_date, 'DD/MM/YYYY').format('YYYY-MM-DD');
            (map[ymd] ||= {})[d.workshift_id] = d;
        });
    }

    /* Khung pane */
    const pane = document.createElement('div');
    pane.className = 'me-2 tab-pane fade table-responsive';
    pane.id   = `pane-${id}`;
    pane.role = 'tabpanel';

    /* thead */
    const theadCells = workshifts
        .map((ws, idx) => {
            return `
              <th style="font-size: 13px;" class="text-dark text-left ${idx === 0 ? 'pe-0' : ''}" colspan="1">
                ${ws.label} (Giờ vào - Giờ ra - Địa điểm)
              </th>
              <th style="font-size: 13px;" class="text-dark text-center ${idx === 0 ? 'ps-0' : ''}">Nghỉ</th>
            `;
        })
        .join('');

    /* tbody */
    const viDays = ['Thứ 2','Thứ 3','Thứ 4','Thứ 5','Thứ 6','Thứ 7','Chủ nhật'];
    const locationOptions = workLocations.map(l => `<option value="${l.value}">${l.label}</option>`).join('');

    const tbodyRows = Array.from({ length: 7 }).map((_, idx) => {
        const date  = monday.add(idx, 'day');
        const ymd   = date.format('YYYY-MM-DD');
        const dayName = viDays[idx];

        const holidayName = holidayMap[ymd] || null;
        const leaveType   = (leaveMap[ymd] || '').toUpperCase();
        const teachingSessions = Array.isArray(teachingMap[ymd]) ? teachingMap[ymd].map(s => String(s).toUpperCase()) : (teachingMap[ymd] ? [String(teachingMap[ymd]).toUpperCase()] : []);
        const hasTeachAM = teachingSessions.includes('AM');
        const hasTeachPM = teachingSessions.includes('PM');
        const hasTeachNT = teachingSessions.includes('NT');
        const teachingLabelsOfDay = (teachingLabelMap && teachingLabelMap[ymd]) || { AM:'', PM:'', NT:'' };

        const leaveLabel  = (typeof leaveLabelMap !== 'undefined' && leaveLabelMap && leaveLabelMap[ymd]) ? leaveLabelMap[ymd] : 'Nghỉ phép';
        const leftLabel   = dayName;

        /* ----- lấy giờ từ map, ngược lại lấy giờ mặc định ------ */
        const rowData = map[ymd] || {};
        const hasAnyDetailInDay = Object.keys(rowData).length > 0;
        /* ô input cho từng workshift */
        const inputs = workshifts.map((ws, index) => {
            const d  = rowData[ws.id] || {};
            const st = d.start_time ?? ws.start ?? '';
            const et = d.end_time   ?? ws.end   ?? '';
            const locValue = (d.location ?? defaultLocation) || defaultLocation;
            const isLeaveFull = leaveType === 'ALL';
            const disabled    = (isReadonly || isLeaveFull) ? 'disabled' : '';
            const tdClasses = ['row-workshift', `shift-${ws.code}`];

            const isHolidayCell = (d.is_day_off === 'HOLIDAY') || (!hasAnyDetailInDay && !!holidayName);
            const isCompensatoryCell = (d.is_day_off === 'COMPENSATORY-LEAVE'); // @author: an.cdb --/03/2026
            const isLeaveCell   = (d.is_day_off === 'ON-LEAVE') ||
                (leaveType === 'ALL') ||
                (leaveType === 'AM' && isMorningShift(ws)) ||
                (leaveType === 'PM' && isAfternoonShift(ws));
            const isTeachCell  = (hasTeachAM && isMorningShift(ws)) || (hasTeachPM && isAfternoonShift(ws));
            const isOffCell     = (d.is_day_off === 'OFF' || d.is_day_off === true);

            if (isHolidayCell) tdClasses.push('off-holiday');
            if (isCompensatoryCell) tdClasses.push('off-compensatory');
            if (isLeaveCell)   tdClasses.push('off-leave');
            if (isTeachCell)   { tdClasses.push('teaching-schedule'); tdClasses.push('off-teaching'); }
            if (isOffCell)     tdClasses.push('day-off');

            const suppressByLeave = (leaveType === 'ALL') ||
                (leaveType === 'AM' && isMorningShift(ws)) ||
                (leaveType === 'PM' && isAfternoonShift(ws)) ||
                (d.is_day_off === 'ON-LEAVE');

            const suppressByTeaching = (hasTeachAM && isMorningShift(ws)) || (hasTeachPM && isAfternoonShift(ws));

            const showToggle = !(suppressByLeave || suppressByTeaching);
            const mustOff = isHolidayCell || isOffCell || isCompensatoryCell;
            const toggleDisabled = isReadonly ? 'disabled' : '';

            const toggleCell = showToggle
                ? `<td class="text-center align-middle">
                   <div class="form-check form-switch m-0 d-flex justify-content-${index === 0 ? 'left me-1' : 'center'}">
                     <input class="form-check-input dayoff-toggle" type="checkbox"
                            ${mustOff ? 'checked' : ''} ${toggleDisabled}>
                   </div>
                 </td>`
                : `<td class="text-center align-middle"></td>`;

            if (suppressByTeaching) {
                const teachingLabel = isMorningShift(ws) ? (teachingLabelsOfDay.AM || 'Giảng dạy') : (teachingLabelsOfDay.PM || 'Giảng dạy');
                const strikeClass = isLeaveCell ? ' text-primary text-decoration-line-through' : ' text-success';
                return `
                  <td class="${tdClasses.join(' ')} ${index === 0 ? 'pe-0' : ''}" data-shift-code="${ws.code}">
                    <div class="d-flex ${ws.code.includes("sang") ? 'me-3' : ''}">
                      <span class="fw-semibold${strikeClass}">${teachingLabel}</span>
                    </div>
                  </td>
                  <td class="text-center align-middle"></td>`;
            }

            /*
            return `
                <td class="${tdClasses.join(' ')} ${index === 0 ? 'pe-0' : ''}" data-shift-code="${ws.code}" data-location="${locValue}" data-start="${st || ''}" data-end="${et || ''}">
                    <div class="d-flex ${ws.code.includes("sang") ? 'me-3' : ''}">
                        <input type="text" name="${ws.code}-start"
                             class="me-1 text-center form-control ${ws.code}-start flat-${ws.code}-start"
                             value="${st}" ${disabled}>
                        <span class="text-center me-1">→</span>
                        <input type="text" name="${ws.code}-end"
                            class="me-2 text-center form-control ${ws.code}-end flat-${ws.code}-end"
                            value="${et}" ${disabled}>
                        <select name="location" class="location form-select form-select-sm place-${ws.code}">
                           ${makeLocationOptions()}
                        </select>
                    </div>
                </td>
                ${toggleCell}`;
            */

            return `
                <td class="${tdClasses.join(' ')} ${index === 0 ? 'pe-0' : ''}" data-shift-code="${ws.code}" data-location="${locValue}" data-start="${st || ''}" data-end="${et || ''}">
                    <div class="d-flex ${ws.code.includes("sang") ? 'me-3' : ''}">
                        <input type="text" name="${ws.code}-start"
                             class="me-1 text-center form-control ${ws.code}-start flat-${ws.code}-start"
                             value="${st}" ${disabled}>
                        <span class="text-center me-1">→</span>
                        <input type="text" name="${ws.code}-end"
                            class="me-2 text-center form-control ${ws.code}-end flat-${ws.code}-end"
                            value="${et}" ${disabled}>
                        <div class="location-wrapper-${ws.code}" data-location-value="${locValue}">
                           ${createLocationDropdownHTML(`${id}-${ymd}-${ws.code}`)}
                        </div>
                    </div>
                </td>
                ${toggleCell}`;
        }).join('');

        const hasNightTeaching = hasTeachNT;
        const nightCellHtml = enableNightColumn
            ? (hasNightTeaching
                ? `<td class="row-night off-teaching text-start" data-shift-code="ca-toi">
                   <div class="d-flex flex-column">
                     <span class="fw-semibold text-success">${teachingLabelsOfDay.NT || 'Giảng dạy'}</span>
                   </div>
                 </td>`
                : `<td class="row-night text-start" data-shift-code="ca-toi">&nbsp;</td>`)
            : '';

        // Text “Nghỉ lễ/Nghỉ phép” cạnh ngày
        let rightStatus = '';
        if (holidayName) {
            const t = (holidayName || 'Nghỉ lễ');
            rightStatus =
                `<span class="ms-2 ws-status-badge ws-status-holiday"
                title="${t}"
                data-bs-toggle="tooltip" data-bs-placement="top" data-bs-title="${t}">${t}</span>`;
        } else if (leaveType) {
            const t = leaveLabel;
            rightStatus =
                `<span class="ms-2 ws-status-badge ws-status-leave"
                title="${t}"
                data-bs-toggle="tooltip" data-bs-placement="top" data-bs-title="${t}">${t}</span>`;
        }

        return `
          <tr data-date="${ymd}">
            <td class="text-dark">${leftLabel} ${rightStatus}</td>
            ${inputs}
            ${nightCellHtml}
          </tr>`;
    }).join('');

    /* Gắn bảng vào DOM */
    pane.innerHTML += `
    <table class="table table-sm align-middle mb-0 table-workshift">
      <thead><tr><th></th>${theadCells}${enableNightColumn ? `<th style="font-size: 13px;" class="text-dark text-center">Ca tối</th>` : ''}</tr></thead>
      <tbody>${tbodyRows}</tbody>
    </table>`;
    document.getElementById('weekTabContent').appendChild(pane);

    /*
    pane.querySelectorAll('td.row-workshift').forEach(td => {
        const code = td.dataset.shiftCode;
        const sel  = td.querySelector(`.place-${code}`);
        if (!sel) return;

        const location = td.getAttribute('data-location') || '';
        if (location && Array.from(sel.options).some(o => o.value === location || o.text === location)) {
            sel.value = location;
        }
    });
    */

    // Khởi tạo dropdown checkbox cho location
    pane.querySelectorAll('td.row-workshift').forEach(td => {
        const code = td.dataset.shiftCode;
        const wrapper = td.querySelector(`.location-wrapper-${code}`);
        if (!wrapper) return;

        const dropdownId = wrapper.querySelector('[data-dropdown-id]')?.getAttribute('data-dropdown-id');
        const location = td.getAttribute('data-location') || '';
        
        if (dropdownId) {
            const isDisabled = td.querySelector('input')?.disabled || false;
            initLocationDropdown(dropdownId, location, isDisabled);
        }
    });

    /* Flatpickr cho input giờ */
    workshifts.forEach(ws => {
        pane.querySelectorAll(`.flat-${ws.code}-start`).forEach(el => {
            const fp = flatpickr(el, {
                enableTime:true, noCalendar:true, time_24hr:true,
                dateFormat:'H:i', minuteIncrement:5,
                defaultDate: el.value || null,
                minTime: ws.min, maxTime: ws.max, disableMobile:true
            });
            el.addEventListener('change', (e) => {
                const td = e.target.closest('td.row-workshift');
                if (td) td.setAttribute('data-start', e.target.value || '');
                updateWeeklyHoursUI();
            });
        });
        pane.querySelectorAll(`.flat-${ws.code}-end`).forEach(el => {
            const fp = flatpickr(el, {
                enableTime:true, noCalendar:true, time_24hr:true,
                dateFormat:'H:i', minuteIncrement:5,
                defaultDate: el.value || null,
                minTime: ws.min, maxTime: ws.max, disableMobile:true
            });
            el.addEventListener('change', (e) => {
                const td = e.target.closest('td.row-workshift');
                if (td) td.setAttribute('data-end', e.target.value || '');
                updateWeeklyHoursUI();
            });
        });
    });

    /* Toggle “Nghỉ” -> tô/xóa class day-off */
    pane.querySelectorAll('.dayoff-toggle').forEach(tg => {
        tg.onchange = e => {
            const tr = e.target.closest('tr');
            const td = e.target.closest('td');
            const tdWorkshift = td.previousElementSibling
            const ymd = tr.dataset.date;
            const checked = e.target.checked;
            const isHolidayRow = !!holidayMap[ymd];

            if (isHolidayRow) {
                tdWorkshift.classList.toggle('off-holiday', checked);
                if (checked) tdWorkshift.classList.remove('day-off');
            } else {
                tdWorkshift.classList.toggle('day-off', checked);
            }
            updateWeeklyHoursUI();
        };
    });

    /* Disable khi tuần PENDING hoặc APPROVED */
    if (isReadonly) {
        pane.querySelectorAll('tbody tr').forEach(tr => {
            const ymd = tr.getAttribute('data-date');
            const dayDetail = map[ymd] || {};
            const hasAnyDetailInDay = Object.keys(dayDetail).length > 0;
            const isHolidayByMap = !!holidayMap[ymd];

            tr.querySelectorAll('td.row-workshift').forEach(td => td.classList.add('pending'));

            // Set trạng thái toggle theo TỪNG CA
            const cells = tr.querySelectorAll('td.row-workshift');
            cells.forEach(td => {
                const toggleTd = td.nextElementSibling; // cột toggle ngay sau ô ca
                const tgl = toggleTd?.querySelector?.('.dayoff-toggle');
                if (!tgl) return;

                // Xác định ca hiện tại
                const code = td.getAttribute('data-shift-code');
                const ws   = workshifts.find(w => w.code === code);
                const d    = ws ? dayDetail[ws.id] : null;

                const isOffByDetail     = (d?.is_day_off === 'OFF');
                const isHolidayByDetail = (d?.is_day_off === 'HOLIDAY');
                const isLeaveByDetail   = (d?.is_day_off === 'ON-LEAVE');

                // Nếu đã có detail trong ngày: chỉ ca nào HOLIDAY/OFF trong DB mới bật.
                // Nếu chưa có detail (tuần mới): auto bật theo holidayMap cho cả ngày.
                const shouldCheck =
                    isHolidayByDetail ||
                    isOffByDetail ||
                    (!hasAnyDetailInDay && isHolidayByMap);

                tgl.checked  = shouldCheck && !isLeaveByDetail; // không bật cho ca nghỉ phép
                tgl.disabled = true;
            });
        });
        updateWeeklyHoursUI();
    }

    pane.querySelectorAll('.ws-status-badge[data-bs-toggle="tooltip"]').forEach(el => {
        try { bootstrap.Tooltip.getOrCreateInstance(el); } catch(_) {}
    });
}

/* ---------- HIỂN THỊ TỔNG GIỜ TRÊN TUẦN ---------- */
function ensureTotalHourBadge() {
    const draftBtn = document.getElementById('save-draft');
    if (!draftBtn) return;
    let badge = document.getElementById('total-hours-badge');
    if (!badge) {
        badge = document.createElement('span');
        badge.id = 'total-hours-badge';
        badge.className = 'ms-2 text-danger fs-1 fw-bold me-auto';
        draftBtn.parentElement?.insertBefore(badge, draftBtn);
    }
    return badge;
}

/* ---------- TÍNH TỔNG GIỜ TRÊN TUẦN ---------- */
function computeWeeklyHours(weekId) {
    const wk = weeks.find(w => w.id === weekId);
    if (!wk) return 0;
    const pane = document.getElementById(`pane-${weekId}`);
    if (!pane) return 0;

    let weeklyHours = 0;

    pane.querySelectorAll('tbody tr').forEach(row => {
        const ymd = row.getAttribute('data-date');
        const isHoliday = !!holidayMap?.[ymd];

        workshifts.forEach(s => {
            const td = row.querySelector(`td.row-workshift.shift-${s.code}`) ||
                row.querySelector(`td.row-workshift[data-shift-code="${s.code}"]`);
            if (!td) return;

            // loại trừ các case không tính giờ (holiday/leave/day-off/teaching)
            const blocked = td.classList.contains('off-holiday') ||
                td.classList.contains('off-leave')   ||
                td.classList.contains('day-off')     ||
                td.classList.contains('off-teaching');
            if (blocked) return;

            // Lấy giá trị giờ:
            const startInp = row.querySelector(`.${s.code}-start`);
            const endInp   = row.querySelector(`.${s.code}-end`);

            const st = (startInp?.value && startInp.value.trim()) || td.getAttribute('data-start') || '';
            const et = (endInp  ?.value && endInp.value.trim())   || td.getAttribute('data-end')   || '';

            const h = (st && et) ? diffHour(st, et) : 0;
            if (h > 0) weeklyHours += h;
        });
    });

    return weeklyHours ? parseFloat(weeklyHours.toFixed(1)) : 0;
}

/* ---------- UPDATE TỔNG GIỜ ---------- */
function updateWeeklyHoursUI() {
    const badge = ensureTotalHourBadge();
    if (!badge) return;

    const hours = computeWeeklyHours(activeWeekId);
    const require = requiredWeeklyHours(activeWeekId);
    const wk = weeks.find(w => w.id === activeWeekId);
    const label = wk ? `Tổng giờ làm việc ${WEEK_LABEL(wk.start)}: ${hours} giờ / ${require} giờ` : `Tổng giờ làm việc tuần: ${hours} giờ / ${require} giờ`;
    badge.textContent = label;
}

/* ---------- CHUYỂN TAB ---------- */
function switchToWeek (id) {
    activeWeekId = id;
    document.querySelectorAll('#weekTabs .nav-week-tab').forEach(li => {
        const a = li.querySelector('a.week');
        li.classList.toggle('active', a?.id === `tab-${id}`);
    });
    document.querySelectorAll('#weekTabContent .tab-pane').forEach(p => p.classList.toggle('show', p.id === `pane-${id}`));
    document.querySelectorAll('#weekTabContent .tab-pane').forEach(p => p.classList.toggle('active', p.id === `pane-${id}`));

    const reasonBox = document.getElementById('reasonBox');
    const wk = weeks.find(w => w.id === id);
    if (wk && wk.status === 'REJECTED' && wk.reason) {
        reasonBox.classList.remove('d-none')
        reasonBox.innerHTML = `<strong>Lý do:</strong> ${wk.reason}`;
    } else {
        reasonBox.classList.add('d-none');
        reasonBox.innerHTML = '';
    }
    const isDisableBtn = wk.status === 'PENDING' || wk.status === 'APPROVED';
    document.getElementById('save-selections').disabled = isDisableBtn;

    syncApproverSelect(id, isDisableBtn);
    highlightWeek(id);
    updateCalendarTitle();
    updateWeeklyHoursUI();
}

/* ---------- REMOVE WEEK ---------- */
function removeWeek (id) {
    if (weeks.length === 1) return showAlert('Phải có ít nhất 1 tuần để đăng kí!', 'warning');
    weeks = weeks.filter(w => w.id !== id);
    document.getElementById(`tab-${id}`)?.parentElement.remove();
    document.getElementById(`pane-${id}`)?.remove();

    switchToWeek(weeks[0].id);
    updateRemoveIcons();
}

/* ---------- HIGHLIGHT TUẦN TRÊN CALENDAR ---------- */
function highlightWeek(id) {
    const week = weeks.find(w => w.id === id);
    if (!week || !calendarWorkshifts) return;

    calendarWorkshifts.el
        .querySelectorAll('.fc-daygrid-day')
        .forEach(el => el.classList.remove('fc-week-selected'));

    const monday = week.start;
    const sunday = monday.add(6, 'day');

    calendarWorkshifts.el
        .querySelectorAll('.fc-daygrid-day[data-date]')
        .forEach(el => {
            const d = dayjs(el.getAttribute('data-date'));
            if (d.isSameOrAfter(monday, 'day') && d.isSameOrBefore(sunday, 'day')) {
                el.classList.add('fc-week-selected');
            }
        });
}

/* ---------- CẬP NHẬT TIÊU ĐỀ ---------- */
function updateCalendarTitle () {
    const week = weeks.find(w => w.id === activeWeekId);
    const titleEl = document.getElementById('calendarTitle');
    const fcTitle = calendarWorkshifts.view.title;             // “07/2025 Tuần 29”
    titleEl.textContent = week ? `${WEEK_LABEL(week.start)}` : fcTitle;
}

/* ---------- ÁP DỤNG KHUNG GIỜ MẪU ---------- */
function applyTemplateToWeek () {
    const pane = document.querySelector(`#pane-${activeWeekId}`);
    if (!pane) return;

    pane.querySelectorAll('tr').forEach(row => {
        if (row.rowIndex === 0) return;
        workshifts.forEach(s => {
            const td = row.querySelector(`td.row-workshift.shift-${s.code}`)
                || row.querySelector(`td.row-workshift[data-shift-code="${s.code}"]`);
            if (!td) return;

            if (td.classList.contains('off-holiday') || td.classList.contains('off-leave') || td.classList.contains('off-teaching'))   return;

            const tplStart = document.getElementById(`tpl-${s.code}-start`).value;
            const tplEnd   = document.getElementById(`tpl-${s.code}-end`).value;
            // const tplPlace = document.getElementById(`tpl-${s.code}-place`).value;

            // Lấy tất cả giá trị được chọn từ dropdown checkbox template
            const tplDropdownWrapper = document.querySelector(`[data-dropdown-id="tpl-${s.code}-place"]`);
            const tplSelectedValues = tplDropdownWrapper ? tplDropdownWrapper.getSelectedValues() : [];

            const startInp = row.querySelector(`.${s.code}-start`);
            const endInp   = row.querySelector(`.${s.code}-end`);
            // const plcSel   = row.querySelector(`.place-${s.code}`);
            
            // Tìm dropdown trong row hiện tại và set giá trị
            const rowDropdownWrapper = td.querySelector('[data-dropdown-id]');

            if (startInp._flatpickr) {
                startInp._flatpickr.setDate(tplStart, true, 'H:i');
            } else {
                startInp.value = tplStart;
            }

            if (endInp._flatpickr) {
                endInp._flatpickr.setDate(tplEnd, true, 'H:i');
            } else {
                endInp.value = tplEnd;
            }
            
            // plcSel.value = tplPlace || defaultLocation;

            // Set giá trị cho dropdown trong row
            if (rowDropdownWrapper) {
                const checkboxes = rowDropdownWrapper.querySelectorAll('input[type="checkbox"]');
                const selectedText = rowDropdownWrapper.querySelector('.selected-text');
                
                // Bỏ check tất cả
                checkboxes.forEach(cb => cb.checked = false);
                
                // Check tất cả checkbox tương ứng với giá trị được chọn từ template
                tplSelectedValues.forEach(val => {
                    const targetCheckbox = Array.from(checkboxes).find(cb => cb.value === val);
                    if (targetCheckbox) {
                        targetCheckbox.checked = true;
                    }
                });
                
                // Cập nhật text hiển thị
                if (selectedText) {
                    if (tplSelectedValues.length === 0) {
                        selectedText.textContent = 'Chọn địa điểm';
                        selectedText.title = '';
                    } else if (tplSelectedValues.length === 1) {
                        const checkbox = Array.from(checkboxes).find(cb => cb.checked);
                        const label = checkbox?.nextElementSibling?.textContent || tplSelectedValues[0];
                        selectedText.textContent = label;
                        selectedText.title = label;
                    } else {
                        const labels = tplSelectedValues.map(val => {
                            const cb = Array.from(checkboxes).find(c => c.value === val);
                            return cb?.nextElementSibling?.textContent || val;
                        }).join(', ');
                        selectedText.textContent = `${tplSelectedValues.length} địa điểm`;
                        selectedText.title = labels;
                    }
                }
            }
        });
    });
    // updateWeeklyHoursUI();
}

/* ---------- VALIDATION ---------- */
function validateAll (btn, activeId) {
    const alertBox = document.getElementById('alertBox');
    alertBox.classList.add('d-none');
    alertBox.innerHTML = '';

    const detailedErrors = [];
    const uniqueGlobalErrors = new Set();
    let allOK = true;

    // Xác định tuần cần validate
    const weeksToValidate = weeks.filter(w => {
        if (btn === 'SUBMIT')  return w.id === activeId;
        return !['APPROVED','PENDING'].includes(w.status);
    });

    weeksToValidate.forEach(week => {
        const pane = document.getElementById(`pane-${week.id}`);
        let weeklyHours = 0;

        let holidayDaysCnt       = 0;  // tổng số ngày là ngày lễ trong tuần
        let holidayWeekdayCnt    = 0;  // số ngày lễ KHÔNG rơi Chủ nhật (để cộng quota)

        // Đếm "ca OFF thường" theo ca = 0.5/ca
        let dayOffs = 0;

        // Cờ chủ nhật trùng ngày lễ
        let hasHolidayOnSunday = false;

        pane.querySelectorAll('tbody tr').forEach(row => {
            // clear lỗi cũ
            row.querySelectorAll('input[type="text"]').forEach(i => i.classList.remove('is-invalid'));

            const ymd = row.getAttribute('data-date');
            const isHoliday = !!holidayMap?.[ymd];
            const isSunday = (dayjs(ymd).day() === 0);

            if (isHoliday) {
                holidayDaysCnt += 1;
                if (isSunday) hasHolidayOnSunday = true;
                else holidayWeekdayCnt += 1; // chỉ cộng quota nếu không phải CN
            }

            // Tổng giờ/ngày (chỉ cộng các ca không bị chặn)
            let dayOK = true;
            let dayHours = 0;

            // Đếm trạng thái theo ca
            let blockedHoliday = 0; // số ca bị off-holiday
            let blockedLeave   = 0; // số ca bị off-leave
            let blockedOffReg  = 0; // số ca OFF thường (day-off) trên NGÀY THƯỜNG
            let enabledShifts  = 0; // số ca còn hiệu lực (không bị chặn)

            workshifts.forEach(s => {
                const td = row.querySelector(`td.row-workshift.shift-${s.code}`) ||
                    row.querySelector(`td.row-workshift[data-shift-code="${s.code}"]`);

                const isOffHoliday = td?.classList.contains('off-holiday');
                const isOffLeave   = td?.classList.contains('off-leave');
                const isTeachingSchedule   = td?.classList.contains('teaching-schedule');
                const isOffToggle  = td?.classList.contains('day-off');

                if (isOffHoliday) blockedHoliday += 1;
                if (isOffLeave)   blockedLeave   += 1;

                // *** ĐẾM QUOTA NGHỈ THEO TUẦN: chỉ tính OFF thường (day-off) và ngày lễ
                if (isOffToggle || isOffHoliday || isOffLeave || isTeachingSchedule) {
                    blockedOffReg += 1;  // dùng cho rule “1 ca OFF + 1 ca làm => 4 giờ”
                }

                if ((isOffToggle || isOffHoliday) && !isOffLeave) {
                    dayOffs += 0.5;
                }

                // Ca bị chặn nếu là 1 trong 3 loại
                const blocked = isOffHoliday || isOffLeave || isOffToggle || isTeachingSchedule;
                if (blocked) return;

                enabledShifts += 1;

                const startInp = row.querySelector(`.${s.code}-start`);
                const endInp   = row.querySelector(`.${s.code}-end`);
                const st = startInp?.value || '';
                const et = endInp  ?.value || '';

                // Rule thời gian min - max.
                if (diffHour(st, et) <= 0) {
                    dayOK = false;
                    startInp?.classList.add('is-invalid');
                    endInp  ?.classList.add('is-invalid');
                    uniqueGlobalErrors.add(` • ${s.label}: Thời gian bắt đầu phải nhỏ hơn thời gian kết thúc.`);
                } else {
                    dayHours += diffHour(st, et);
                }
            });

            // Ngày là ngày LỄ làm đủ 2 ca => 8 giờ
            if (isHoliday) {
                if (enabledShifts === 2) {
                    if (dayHours !== 8) {
                        dayOK = false;
                        workshifts.forEach(s => {
                            const td = row.querySelector(`td.row-workshift.shift-${s.code}`) ||
                                row.querySelector(`td.row-workshift[data-shift-code="${s.code}"]`);
                            const blocked = td?.classList.contains('off-holiday') ||
                                td?.classList.contains('off-leave')   ||
                                td?.classList.contains('teaching-schedule')   ||
                                td?.classList.contains('day-off');
                            if (!blocked) row.querySelectorAll(`.${s.code}-start, .${s.code}-end`).forEach(i => i.classList.add('is-invalid'));
                        });
                        uniqueGlobalErrors.add(' • Tổng giờ làm việc một ngày phải đúng 8 giờ.');
                    } else {
                        weeklyHours += dayHours;
                    }
                    if (!dayOK) allOK = false;
                    return;
                }
            }

            // NGÀY THƯỜNG có 1 ca OFF thường + 1 ca làm => ca làm phải đúng 4h
            if (blockedOffReg === 1 && enabledShifts === 1) {
                if (dayHours !== 4) {
                    dayOK = false;
                    workshifts.forEach(s => {
                        const td = row.querySelector(`td.row-workshift.shift-${s.code}`) ||
                            row.querySelector(`td.row-workshift[data-shift-code="${s.code}"]`);
                        const blocked = td?.classList.contains('off-holiday') ||
                            td?.classList.contains('off-leave')   ||
                            td?.classList.contains('teaching-schedule')   ||
                            td?.classList.contains('day-off');
                        if (!blocked) row.querySelectorAll(`.${s.code}-start, .${s.code}-end`).forEach(i => i.classList.add('is-invalid'));
                    });
                    uniqueGlobalErrors.add(' • Tổng giờ làm việc một ca phải đúng 4 giờ.');
                } else {
                    weeklyHours += dayHours;
                }
                if (!dayOK) allOK = false;
                return;
            }

            // NGÀY THƯỜNG làm đủ 2 ca => 8 giờ
            if (!isHoliday && enabledShifts === 2) {
                if (dayHours !== 8) {
                    dayOK = false;
                    workshifts.forEach(s => {
                        const td = row.querySelector(`td.row-workshift.shift-${s.code}`) ||
                            row.querySelector(`td.row-workshift[data-shift-code="${s.code}"]`);
                        const blocked = td?.classList.contains('off-holiday') ||
                            td?.classList.contains('off-leave')   ||
                            td?.classList.contains('teaching-schedule')   ||
                            td?.classList.contains('day-off');
                        if (!blocked) row.querySelectorAll(`.${s.code}-start, .${s.code}-end`).forEach(i => i.classList.add('is-invalid'));
                    });
                    uniqueGlobalErrors.add(' • Tổng giờ làm việc một ngày phải đúng 8 giờ.');
                } else {
                    weeklyHours += dayHours;
                }
            }

            if (!dayOK) allOK = false;
        });

        //   Mặc định chỉ được nghỉ 2 ca (không tính nghỉ phép)
        // const allowedDayOffs = 1 + holidayWeekdayCnt; // đơn vị: "ngày" (mỗi ca = 0.5)
        // if (dayOffs > allowedDayOffs) {
        //     allOK = false;
        //     detailedErrors.push(` • ${WEEK_LABEL(week.start)} chỉ được nghỉ 1 ngày (không tính nghỉ phép/nghỉ lễ).`);
        // }

        //   Mặc định tuần phải chọn 2 ca OFF thường (không tính nghỉ phép/nghỉ lễ);
        // if ((dayOffs < allowedDayOffs) && !hasHolidayOnSunday) {
        //     allOK = false;
        //     detailedErrors.push(` • ${WEEK_LABEL(week.start)} chưa chọn ngày nghỉ (không tính nghỉ phép/nghỉ lễ).`);
        // }
    });

    const allErrors = [...uniqueGlobalErrors, ...detailedErrors];
    if (!allOK) {
        alertBox.classList.remove('d-none');
        alertBox.innerHTML = allErrors.join('<br>');
    }
    return allOK;
}


/* ---------- TÍNH GIỜ ---------- */
function diffHour (start, end) {
    return (timeToMin(end) - timeToMin(start)) / 60;
}
// function timeToMin (t) {
//     const [h, m] = t.split(':').map(Number);
//     return h * 60 + m;
// }

function formatDate(dateStr) {
    const [year, month, day] = dateStr.split("-");
    return `${day}/${month}/${year}`;
}

/* ---------- SUBMIT ---------- */
async function handleSubmit (btnType) {
    const ok = validateAll(btnType, activeWeekId);

    const getAlertErrors = () => {
        const box = document.getElementById('alertBox');
        if (!box || box.classList.contains('d-none')) return [];
        const raw = box.innerText || box.textContent || '';
        return raw.split(/\n|<br\s*\/?>/i).map(s => s.trim()).filter(Boolean);
    };

    const BLOCKING_PATTERNS = [
        /Thời gian .*bắt đầu.*kết thúc/i,
        /chỉ được nghỉ 1 ngày \(không tính nghỉ phép\/nghỉ lễ\)/i,
        /chưa chọn ngày nghỉ \(không tính nghỉ phép\/nghỉ lễ\)/i,
    ];
    const SOFT_PATTERNS = [
        /Tổng giờ làm việc một ngày phải đúng 8 giờ/i,
        /Tổng giờ làm việc một ca phải đúng 4 giờ/i,
    ];

    const errors = getAlertErrors();
    const hasBlocking = errors.some(e => BLOCKING_PATTERNS.some(re => re.test(e)));
    const onlySoft = errors.length > 0 &&
        errors.every(e => SOFT_PATTERNS.some(re => re.test(e)));

    // Nếu validateAll fail nhưng chỉ có lỗi mềm -> Không chặn
    if (!ok) {
        if (hasBlocking) {
            return;
        }
        if (!onlySoft) {
            // có lỗi khác mà không match blocking/soft -> chặn
            return;
        }
    }

    const weekNo = (() => {
        const w = weeks.find(w => w.id === activeWeekId);
        return w ? `tuần ${w.start.isoWeek()}` : '';
    })();

    const buildHourWarning = () => {
        const targetWeeks = (btnType === 'DRAFT')
            ? weeks.filter(w => !['APPROVED','PENDING'].includes(w.status)).map(w => w.id)
            : [activeWeekId];

        const warnings = [];
        targetWeeks.forEach(wid => {
            const req = requiredWeeklyHours(wid);
            const cur = computeWeeklyHours(wid);
            if (cur !== req) {
                const w = weeks.find(x => x.id === wid);
                warnings.push(`• ${WEEK_LABEL(w.start)}: hiện tại ${cur} giờ, yêu cầu ${req} giờ.`);
            }
        });
        return warnings.length ? `\n⚠️ Tổng số giờ làm việc không khớp:\n${warnings.join('\n')}\n` : '';
    };

    // Cảnh báo “mềm” (8h/ngày, 4h/ca) nếu có
    // === ADDED ===
    const softWarn = errors.filter(e => SOFT_PATTERNS.some(re => re.test(e)));
    const softWarnText = softWarn.length ? `\n⚠️ Cảnh báo:\n${softWarn.join('\n')}\n` : '';

    const hourWarn = buildHourWarning();

    // === CHANGED === nối cảnh báo vào prompt confirm
    const msg = (btnType === 'DRAFT'
            ? 'Bạn có muốn lưu nháp hết tất cả tuần làm việc hiện có không?'
            : `Bạn có muốn gửi phê duyệt lịch làm việc ${weekNo} không?`
    );
    const finalMsg = `${softWarnText}${hourWarn}\n${msg}`;

    if (!window.confirm(finalMsg)) return;

    const btn = document.getElementById(btnType === 'DRAFT' ? 'save-draft' : 'save-selections');
    btn.disabled = true;
    const oldLabel = btn.textContent;
    btn.textContent = btnType === 'DRAFT' ? 'Đang lưu…' : 'Đang gửi…';

    const payloadWeeks = weeks
        .filter(w => {
            const isSubmitted = ['PENDING', 'APPROVED'].includes(w.status);
            return !(isSubmitted && ['DRAFT', 'SUBMIT'].includes(btnType));
        })
        .map(w => buildPayload(w, btnType));

    if (!payloadWeeks.length) {
        btn.disabled = false;
        btn.textContent = btnType === 'DRAFT' ? 'Lưu nháp' : 'Gửi';
        return showAlert('Không có dữ liệu để lưu!','warning');
    }

    const payload = { data: payloadWeeks};

    try {
        showLoadding(true);
        const res  = await fetch(save_scheduleweeks, {
            method : 'POST',
            headers     : {
                'Content-Type': 'application/json',
                'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
            },
            credentials : 'same-origin',
            body   : JSON.stringify(payload)
        });
        if (!res .ok) throw new Error(await res .text());

        const json = await res.json();
        if (res.ok && json.success) {
            const messageSuccess = btnType === 'DRAFT' ? 'Lưu nháp thành công!' : 'Đăng kí thành công!';
            localStorage.setItem('successMessage', messageSuccess);
            $('#workshiftModal').modal('hide');
            showLoadding(false);
            window.location.reload();
        } else {
            const messageError = btnType === 'DRAFT' ? 'Lưu nháp thất bại!' : 'Đăng kí thất bại!';
            showLoadding(false);
            showAlert(json.message || messageError,'danger');
        }

    } catch (err) {
        console.error(err);
        showLoadding(false);
        showAlert('Có lỗi xảy ra khi lưu!', 'danger');
    } finally {
        btn.disabled = false;
        btn.textContent = btnType === 'DRAFT' ? 'Lưu nháp' : 'Gửi';
    }
}

/* ---------- TÍNH SỐ GIỜ PHẢI LÀM VIỆC TRONG TUẦN (TRỪ NGHỈ LỄ, NGHỈ PHÉP, LỊCH GIẢNG DẠY) ---------- */
function requiredWeeklyHours(weekId) {
    const wk = weeks.find(w => w.id === weekId);
    if (!wk) return 48;

    let quota = 48; // 12 ca * 4h

    // Quét 7 ngày (đảm bảo không trừ ngày CN)
    const monday = wk.start;
    for (let i = 0; i < 7; i++) {
        const d = monday.add(i, 'day');
        const ymd = d.format('YYYY-MM-DD');
        const isSunday = (d.day() === 0);
        if (isSunday) continue;

        let reduce = 0;

        // Nghỉ lễ (full day) -> -8h
        if (holidayMap?.[ymd]) {
            reduce = Math.max(reduce, 8);
        } else {
            // Nghỉ phép
            const lv = (leaveMap?.[ymd] || '').toUpperCase();
            if (lv === 'ALL') reduce += 8;
            else {
                if (lv === 'AM') reduce += 4;
                if (lv === 'PM') reduce += 4;
            }

            // Lịch giảng dạy (mỗi ca -4h; ALL -8h)
            const teach = Array.isArray(teachingMap[ymd]) ? teachingMap[ymd].map(s => String(s).toUpperCase()) : (teachingMap[ymd] ? [String(teachingMap[ymd]).toUpperCase()] : []);
            if (teach.includes('ALL')) {
                reduce += 8;
            } else {
                if (teach.includes('AM')) reduce += 4;
                if (teach.includes('PM')) reduce += 4;
            }

            // Không vượt quá 8h/ngày
            if (reduce > 8) reduce = 8;
        }

        quota -= reduce;
    }

    if (quota < 0) quota = 0;
    return quota;
}

/* ---------- BUILD PAYLOAD ---------- */
function buildPayload (weekObj, btnType = 'DRAFT') {
    /* Xử lý thông tin chung của tuần  */
    const element = document.getElementById(`tab-${weekObj.id}`);
    const checked_by  = (element?.getAttribute('data-check-by') || '');
    const start    = weekObj.start;
    const end      = start.add(6, 'day');
    const payload  = {
        id          : weekObj.schedule_id || null,
        week_num    : start.isoWeek(),
        checked_by  : checked_by,
        year        : start.year(),
        start_date  : start.format('YYYY-MM-DD'),
        end_date    : end.format('YYYY-MM-DD'),
        current_status: weekObj.status || 'NEW',
        time_required: requiredWeeklyHours(weekObj.id),
        time_register: computeWeeklyHours(weekObj.id),
        status      : btnType === 'SUBMIT' && weekObj.id === activeWeekId ? 'PENDING' : 'TEMP',
        shift_details : []
    };

    /*  Lấy bảng DOM để quét từng ngày / ca  */
    const pane = document.getElementById(`pane-${weekObj.id}`);
    if (!pane) return payload;

    pane.querySelectorAll('tbody tr').forEach(row => {
        const work_date = row.dataset.date;
        const isOff     = row.classList.contains('day-off');

        workshifts.forEach(s => {
            const td = row.querySelector(`td.row-workshift.shift-${s.code}`) || row.querySelector(`td.row-workshift[data-shift-code="${s.code}"]`);
            const startInp = td?.querySelector(`.${s.code}-start`);
            const endInp   = td?.querySelector(`.${s.code}-end`);
            // const plcSel   = td?.querySelector(`.place-${s.code}`);
            
            // Lấy location từ dropdown checkbox (lưu tất cả giá trị, phân cách bằng "/")
            let locationValue = defaultLocation;
            const dropdownWrapper = td?.querySelector('[data-dropdown-id]');
            if (dropdownWrapper && typeof dropdownWrapper.getSelectedValues === 'function') {
                const selectedValues = dropdownWrapper.getSelectedValues();
                locationValue = selectedValues.length > 0 ? selectedValues.join('/') : defaultLocation;
            }

            // Ưu tiên: HOLIDAY > ON-LEAVE > TEACHING-SCHEDULE > OFF > null
            let offFlag = null;
            if (td?.classList.contains('off-holiday')) offFlag = 'HOLIDAY';
            else if (td?.classList.contains('off-leave')) offFlag = 'ON-LEAVE';
            else if (td?.classList.contains('off-compensatory')) offFlag = 'COMPENSATORY-LEAVE';
            else if (td?.classList.contains('teaching-schedule')) offFlag = 'TEACHING-SCHEDULE';
            else if (td?.classList.contains('day-off')) offFlag = 'OFF';

            payload.shift_details.push({
                workshift_id : s.code,
                work_date    : work_date,
                start_time   : startInp?.value || (s.code === 'ca-sang' ? "07:00" : "13:00"),
                end_time     : endInp  ?.value || (s.code === 'ca-sang' ? "11:00" : "17:00"),
                is_day_off   : offFlag,
                // location: plcSel?.value || defaultLocation
                location: locationValue
            });
        });
    });

    return payload;
}

function setApproverForWeek(weekId, value) {
    const wk = weeks.find(w => w.id === weekId);
    if (!wk) return;
    wk.checked_by = value || null;

    const a = document.getElementById(`tab-${weekId}`);
    if (a) a.setAttribute('data-check-by', wk.checked_by ?? '');
}

function syncApproverSelect(weekId, isDisable) {
    const approverSel = document.getElementById('approverWorkshift');
    if (!approverSel) return;

    const a = document.getElementById(`tab-${weekId}`);
    const wk = weeks.find(w => w.id === weekId);
    const fromState = wk?.checked_by || '';
    const fromAttr  = (a?.getAttribute('data-check-by') || '');
    const prefValue = (fromState || (fromAttr && fromAttr !== 'null') || '');

    const applySelectValue = () => {
        let target = prefValue;
        if (!target) {
            target = approverSel.options[0]?.value || '';
        } else {
            const has = Array.from(approverSel.options).some(o => o.value == prefValue);
            if (!has) target = approverSel.options[0]?.value || '';
        }
        approverSel.value = target;
        setApproverForWeek(weekId, target);
        approverSel.disabled = !!isDisable;
    };

    if (approverSel.options.length > 0) {
        applySelectValue();
    } else {
        const obs = new MutationObserver(() => {
            if (approverSel.options.length > 0) {
                applySelectValue();
                obs.disconnect();
            }
        });
        obs.observe(approverSel, { childList: true });
        setTimeout(() => obs.disconnect(), 5000);
    }
}

if (!dayjs.prototype.isSameOrAfter) {
    dayjs.prototype.isSameOrAfter = function (d, unit) {
        return this.isSame(d, unit) || this.isAfter(d, unit);
    };
}
if (!dayjs.prototype.isSameOrBefore) {
    dayjs.prototype.isSameOrBefore = function (d, unit) {
        return this.isSame(d, unit) || this.isBefore(d, unit);
    };
}

function normalizeHolidayResponse(raw) {
    const map = {};
    if (!raw) return map;

    const put = (k, v) => {
        const key = toISODate(k) || toISODate(v);
        if (key) map[key] = String(v && toISODate(v) ? k : v || 'Nghỉ lễ').trim();
    };

    if (Array.isArray(raw)) {
        raw.forEach(it => {
            if (it && typeof it === 'object') {
                Object.entries(it).forEach(([k, val]) => put(k, val));
            }
        });
    } else if (typeof raw === 'object') {
        Object.entries(raw).forEach(([k, val]) => put(k, val));
    }
    return map;
}

function normalizeLeaveResponse(raw) {
    const map = {};
    if (!raw) return map;
    if (Array.isArray(raw)) {
        raw.forEach(it => {
            if (it && typeof it === 'object') {
                Object.entries(it).forEach(([k, v]) => {
                    if (DATE_RE.test(k)) map[k] = String(v).toUpperCase();
                    else if (DATE_RE.test(v)) map[v] = String(k).toUpperCase();
                });
            }
        });
    } else if (typeof raw === 'object') {
        Object.entries(raw).forEach(([k, v]) => {
            if (DATE_RE.test(k)) map[k] = String(v).toUpperCase();
            else if (DATE_RE.test(v)) map[v] = String(k).toUpperCase();
        });
    }
    return map;
}

function normalizeCampus(raw) {
    const out = [];
    if (!raw) return out;

    if (Array.isArray(raw)) {
        raw.forEach(item => {
            if (item && typeof item === 'object') {
                Object.entries(item).forEach(([value, label]) => {
                    out.push({ value, label });
                });
            } else if (typeof item === 'string') {
                out.push({ value: item, label: item });
            }
        });
    } else if (typeof raw === 'object') {
        Object.entries(raw).forEach(([value, label]) => {
            out.push({ value, label });
        });
    }
    return out;
}

function makeLocationOptions() {
    return workLocations.map(l => `<option value="${l.value}">${l.label}</option>`).join('');
}

/* ---------- TẠO DROPDOWN CHECKBOX CHO ĐỊA ĐIỂM ---------- */
function createLocationDropdownHTML(id) {
    const items = workLocations.map(loc => `
        <div class="location-dropdown-item" data-value="${loc.value}">
            <input type="checkbox" id="${id}-${loc.value}" value="${loc.value}">
            <label for="${id}-${loc.value}">${loc.label}</label>
        </div>
    `).join('');

    return `
        <div class="location-dropdown-wrapper" data-dropdown-id="${id}">
            <button type="button" class="location-dropdown-toggle" aria-expanded="false" data-toggle-id="${id}">
                <span class="selected-text">Chọn địa điểm</span>
                <span class="caret">▼</span>
            </button>
            <div class="location-dropdown-menu hide">
                ${items}
            </div>
        </div>
    `;
}

/* ---------- KHỞI TẠO DROPDOWN CHECKBOX ---------- */
function initLocationDropdown(wrapperId, defaultValue, isDisabled = false) {
    const wrapper = document.querySelector(`[data-dropdown-id="${wrapperId}"]`);
    if (!wrapper) return;

    const toggle = wrapper.querySelector('.location-dropdown-toggle');
    const menu = wrapper.querySelector('.location-dropdown-menu');
    const selectedText = toggle.querySelector('.selected-text');
    const checkboxes = menu.querySelectorAll('input[type="checkbox"]');

    // Disable dropdown nếu cần
    if (isDisabled) {
        toggle.disabled = true;
        toggle.style.opacity = '0.6';
        toggle.style.cursor = 'not-allowed';
        checkboxes.forEach(cb => cb.disabled = true);
    }

    // Hàm cập nhật text hiển thị (giới hạn độ dài để tránh thay đổi layout)
    const updateSelectedText = () => {
        const checked = Array.from(checkboxes).filter(cb => cb.checked);
        if (checked.length === 0) {
            selectedText.textContent = 'Chọn địa điểm';
            selectedText.title = ''; // Xóa tooltip
        } else if (checked.length === 1) {
            const label = checked[0].nextElementSibling.textContent;
            selectedText.textContent = label;
            selectedText.title = label; // Tooltip khi hover để xem đầy đủ
        } else {
            const labels = checked.map(cb => cb.nextElementSibling.textContent).join(', ');
            selectedText.textContent = `${checked.length} địa điểm`;
            selectedText.title = labels; // Tooltip hiển thị tất cả
        }
    };

    // Hàm lấy giá trị đã chọn
    wrapper.getSelectedValues = () => {
        return Array.from(checkboxes)
            .filter(cb => cb.checked)
            .map(cb => cb.value);
    };

    // Set giá trị mặc định (hỗ trợ dạng "A/B/C" và dạng cũ "A")
    if (defaultValue) {
        const values = String(defaultValue)
            .split('/')
            .map(v => v.trim())
            .filter(Boolean);

        if (values.length > 0) {
            checkboxes.forEach(cb => {
                cb.checked = values.includes(cb.value);
            });
            updateSelectedText();
        }
    }

    // Toggle dropdown
    toggle.addEventListener('click', (e) => {
        e.preventDefault();
        e.stopPropagation();
        if (isDisabled) return;
        
        const isExpanded = toggle.getAttribute('aria-expanded') === 'true';
        
        // Đóng tất cả dropdown khác
        document.querySelectorAll('.location-dropdown-toggle[aria-expanded="true"]').forEach(t => {
            if (t !== toggle) {
                t.setAttribute('aria-expanded', 'false');
                const otherWrap = t.closest('.location-dropdown-wrapper');
                if (otherWrap) otherWrap.classList.remove('is-open');
                t.parentElement.querySelector('.location-dropdown-menu').classList.remove('show');
                t.parentElement.querySelector('.location-dropdown-menu').classList.add('hide');
            }
        });

        // Toggle dropdown hiện tại
        toggle.setAttribute('aria-expanded', !isExpanded);
        menu.classList.toggle('show');
        menu.classList.toggle('hide');

        wrapper.classList.toggle('is-open', menu.classList.contains('show'));
    });

    // Xử lý sự kiện checkbox
    checkboxes.forEach(checkbox => {
        checkbox.addEventListener('change', (e) => {
            e.stopPropagation();
            updateSelectedText();
        });
    });

    // Xử lý click item (bao gồm label)
    menu.querySelectorAll('.location-dropdown-item').forEach(item => {
        item.addEventListener('click', (e) => {
            if (e.target.tagName === 'INPUT') return; // Đã xử lý ở checkbox
            e.stopPropagation();
            if (e.target.tagName === 'LABEL') return; // Native <label for> tự toggle checkbox
            const checkbox = item.querySelector('input[type="checkbox"]');
            if (!checkbox.disabled) {
                checkbox.checked = !checkbox.checked;
                checkbox.dispatchEvent(new Event('change'));
            }
        });
    });

    // Đóng dropdown khi click ra ngoài
    document.addEventListener('click', (e) => {
        if (!wrapper.contains(e.target)) {
            toggle.setAttribute('aria-expanded', 'false');
            menu.classList.remove('show');
            menu.classList.add('hide');
            wrapper.classList.remove('is-open');
        }
    });
}

function timeToMin (t) {
    const [h, m] = String(t||'00:00').split(':').map(Number); return h*60 + (m||0);
}
function isMorningShift(ws) {
    return timeToMin(ws.start || ws.min || '08:00') <  12*60;
}
function isAfternoonShift(ws) {
    return timeToMin(ws.start || ws.min || '13:00') >= 12*60;
}

function toISODate(s) {
    const x = String(s || '').trim();
    if (DATE_RE.test(x)) return x;
    if (DATE_RE_DMY.test(x)) {
        const [dd, mm, yyyy] = x.split('/');
        return `${yyyy}-${mm}-${dd}`;
    }
    return '';
}