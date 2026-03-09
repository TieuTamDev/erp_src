(function ($) {
  const methods = {
    init: function (settings) {
      const options = $.extend({
        startWeekOnMonday: true,
        showHeader: true,
        onDateClick: null,
        currentTime: moment().startOf('isoWeek'),
        hour_range:["06:00","07:00","08:00","09:00","10:00","11:00","12:00","13:00","14:00","15:00","16:00","17:00","18:00","19:00","20:00","21:00"],
        day_of_week:["Thứ 2","Thứ 3","Thứ 4","Thứ 5","Thứ 6","Thứ 7","CN"],
        day_of_week_short:["T2","T3","T4","T5","T6","T7","CN"],
        viewType:"week", // week || month
        events: [],
        renderWeekEvent: null,
        renderMonthEvent: null,
        week:{
            column_width: 100,
            row_height: 97,
            item_height:28
        }
      }, settings);

      return this.each(function () {
        const $container = $(this);
        const data = {
          options: options,
          events: options.events || [],
        };
        $container.data('calendarData', data);
        renderTable($container);
      });
    },

    loadEvents: function (events) {
      return this.each(function () {
        const $container = $(this);
        const data = $container.data('calendarData');
        if (data) {
          data.events = events;
          $container.data('calendarData', data);
          renderEvents($container);
        }
      });
    },

    updateDate: function(date) {
      return this.each(function () {
        const $container = $(this);
        const data = $container.data('calendarData');
        if (data) {
          data.options.currentTime = moment(date).startOf('isoWeek');
          data.events = [];
          $container.data('calendarData', data);
          updateTime($container);
        }
      });
    },
    switchView:function (viewType) {
      return this.each(function () {
        const $container = $(this);
        const data = $container.data('calendarData');
        if (data) {
          data.options.viewType = viewType;
          $container.data('calendarData', data);
          renderTable($container);
        }
      });
    }
  };

  function renderTable($container) {
    const data = $container.data('calendarData');
    const options = data.options;
    const header = renderTableHeader(options);
    const rows = renderTableRow(options);
    $container.html("");
    const calendar = $(`
      <table class="table table-bordered calender-table m-0">
        <thead>
          <tr>
            ${header}
          </tr>
        </thead>
        <tbody>
          ${rows}
        </tbody>
      </table>
    `);
    $container.append(calendar);

    // apply current time
    updateTime($container);
  }

  function renderTableHeader(options) {
    let columns = [];
    let header = ``;
    if(options.viewType == "week"){
      columns.push(`<th></th>`)
      options.hour_range.forEach(hour=>{
          columns.push(`<th style="width:${options.week.column_width}px;border: 0px;">${hour}</th>`);
      });
      header =  `<tr style="vertical-align: middle;height: 60px;">${columns.join("")}</tr>`;
    }else if(options.viewType == "month"){
      options.day_of_week_short.forEach(day=>{
        columns.push(`<th style="background: #E5E7EB;padding:0px;">${day}</th>`);
      });
      header = `<tr style="text-align: center;vertical-align: middle;height: 34px;">${columns.join("")}</tr>`;
    }
    return header;
  }

  function renderTableRow(options) {
    let rows = [];
    if(options.viewType == "week"){
      let cells= options.day_of_week.map((day,index)=>{
        let cell = options.hour_range.map(hour=>{return `<td style="position: relative;" data-time="${hour}"></td>`});
        return `<tr data-row="${index}" style="height: 66px;text-align: center;vertical-align: middle;"><td class="group-column"><div>${day}</div><div class="group-column-day" style="color:#3C3C43;font-weight: 600;font-size: 18px;line-height: 14px;"></div></td> ${cell.join("")} </tr>`;
      });
      rows.push(cells.join(""));
    }else if(options.viewType == "month"){
      
    }

    return rows.join("");
  }

  function updateTime(container) {
    let data = container.data('calendarData');
    let options = data.options;
    if(options.viewType == "week"){
      let day_ranges = getDayRange(options);
      container.find('tr[data-row]').each((index,element)=>{
        let row = $(element).data("row");
        $(element).attr("data-date",day_ranges[row]);
        $(element).find('td').attr("data-date",day_ranges[row]);
        $(element).find(`.group-column-day`).html(day_ranges[row].split("-")[2]);
      });
    }else if(options.viewType == "month"){
      let rows = [];
      let week_days = getMonthWeeks(options.currentTime.year(),options.currentTime.month());
      week_days.forEach(week=>{
          let cell = [];
          week.forEach(day=>{
              let style = day.day == 7 ? "background: #f9f9f9;" : "";
              cell.push(`<td data-date="${day.date}" style="${style};padding: 0;position: relative;">
                            <div style="position: absolute;height: 100%;width: 100%;display: flex;flex-direction: column;">
                                <div class="ps-2" style="font-weight: 600;width: fit-content;">${day.date.split("-")[2]}</div>
                                <div data-cell-date="${day.date}" style="font-weight: 600;flex-grow: 1;"></div>
                            </div>
                          </td>`);
          });
          let row_highlight = "";
          if(week[0].week_num == options.currentTime.isoWeek()){
            row_highlight = "row-hightlight";
          }
          rows.push(`<tr class="${row_highlight}" style="height: 106px;">${cell.join("")}</tr>`);
      })
      container.find("tbody").html(rows.join(""));
    }
    renderEvents(container);
  }
  
  function renderEvents(container) {
    let data =  container.data('calendarData');
    let events = data.events;
    let options = data.options;
    // clearn all event items
    $(".event-item").remove();

    if(options.viewType == "week"){
        let row_padding_bottom = 60;
        let row_padding_top = 4;
        let item_height = options.week.item_height;
        let groups = groupEventsByUser(events);

        // reset row 
        container.find(`tr[data-date]`).css("height",options.week.row_height);
        // each row
        groups.forEach((group)=>{
            let date = group.date;
            let row = container.find(`tr[data-date="${date}"]`);
            let row_height = (group.events.length * item_height) + (group.events.length * 5)+ row_padding_top + row_padding_bottom;
            row.css("height",row_height);
            // each user
            group.events.forEach((events,index)=>{
            events.works.forEach(event=>{
                let cell = row.find(`td[data-time="${event.start.split(":")[0]}:00"]`);
                if(cell.length > 0){
                    let cell_width = cell[0].getBoundingClientRect().width;
                    let item = renderEventItem(event,options);
                    let item_top = (index * item_height)+ 10 + (index * 5);
                    item.css("top",item_top + "px");
                    let item_left = (parseInt(event.start.split(":")[1]) / 60) * cell_width;
                    item.css("left",item_left + "px");
                    let item_width = getTimeLength(event.start,event.end,cell_width);
                    item.css("width",item_width + "px");
                    cell.append(item);
                }
            });
            });
        });
    }else if (options.viewType == "month"){
      let groups = groupEventsByDate(events);
      container.find(`div[data-cell-date]`).html('');
      groups.forEach(group=>{
        let date = group.date;
        let cell = container.find(`div[data-cell-date="${date}"]`);
        cell.html(``);
        group.users.forEach((user_name,index)=>{
          if(index < 2){
            let item = renderEventItem(user_name,options);
            cell.append(item);
          }
        });
        if(group.users.length > 2){
          let addmore = $(`<div style="text-align: center;width: 100%;cursor: pointer;">+ thêm ${group.users.length - 2}</div>`);
          addmore.on('click',()=>{
            let moreitems = group.users.map(user=>{
              return `<div class="event-item-month">
                        <span class="me-2">📅<span>  ${user}
                      </div>`;
            });
            let moreItem = `<div id="more-${date}" style="position: absolute;top:0;left:0;background: white;width: 100%;border: 1px solid #bbb8b8;padding: 3px 3px;z-index: 2;">
                              <div style="display: flex;justify-content: space-between;padding: 2px 7px;">
                                <span>${date}</span>
                                <span style="cursor: pointer;font-weight: bold;" onclick="$('#more-${date}').remove()">x</span>
                              </div>
                              <div style="margin-top: 5px;">
                                ${moreitems.join("")}
                              </div>
                            </div>`;
            cell.append(moreItem);
          });
          cell.append(addmore);
        }
      });
    }
    
  }

  function groupEventsByUser(events) {
    const groupedByUser = {};

    events.forEach(event => {
      const { date, user_id} = event;

      if (!groupedByUser[date]) {
        groupedByUser[date] = {};
      }

      if (!groupedByUser[date][user_id]) {
        groupedByUser[date][user_id] = [];
      }
      groupedByUser[date][user_id].push(event);

    });
    const result = Object.entries(groupedByUser).map(([date, users]) => {
      const events = Object.entries(users).map(([user_id, works]) => ({
        user_id: parseInt(user_id),
        works,
      }));
      return { date, events };
    });

    return result;
  }

  function groupEventsByDate(events) {
    const groupedByDate = {};
    events.forEach(event => {
      const { date, title } = event;
      if (!groupedByDate[date]) {
        groupedByDate[date] = new Set();
      }
      const userName = title.split(" ca ")[0];
      groupedByDate[date].add(userName);
    });

    const result = Object.entries(groupedByDate).map(([date, usersSet]) => ({
      date,
      users: Array.from(usersSet)
    }));

    return result;
  }

  function renderEventItem(event,options) {
    let item = "";
    if(options.viewType == "week"){
        if (typeof options.renderWeekEvent === "function") {
            item =  options.renderWeekEvent(event);
        }else{
            item = renderWeekEvent(event);
        }

    }else if(options.viewType == "month"){
      if (typeof options.renderMonthEvent === "function") {
            item =  options.renderMonthEvent(event);
        }else{
            item = renderMonthEvent(event);
        }
    }
    return $(item);
  }

  function renderWeekEvent(data) {
    return `<div class="event-item" style="position: absolute;border-left: 4px solid ${data.color};">
                <span style="color:${data.color};filter: brightness(85%);font-weight: 600;">${data.title}</span> <span style="color:${data.color}">${data.start} - ${data.end}</span>
            </div>`;
  }

  function renderMonthEvent(data) {
    return `<div class="event-item-month">
              <span class="me-2">📅<span> ${data}
            </div>`;
  }

  // Units

    function getMonthWeeks(year, month) {
        const startOfMonth = moment([year, month]).startOf('month');
        const endOfMonth = moment([year, month]).endOf('month');

        const start = startOfMonth.clone().startOf('isoWeek');
        const end = endOfMonth.clone().endOf('isoWeek');

        const weeks = [];
        let current = start.clone();

        while (current.isSameOrBefore(end)) {
            const week = [];
            for (let i = 0; i < 7; i++) {
                week.push({
                    date: current.format('YYYY-MM-DD'),
                    day: current.isoWeekday(),
                    inMonth: current.month() === (month),
                    week_num:current.isoWeek()
                });
                current.add(1, 'day');
            }
            weeks.push(week);
        }

        return weeks;
    }

    function getDayRange(options) {
        let result = [];
        if(options.viewType == "week"){
          const start = options.currentTime.clone().startOf('isoWeek');
          for (let i = 0; i < 7; i++) {
              const day = moment(start).add(i, 'days');
              result.push(day.format("YYYY-MM-DD"));
          }
        }else if(options.viewType == "month"){

        }
        return result;
    }

  function getTimeLength(startTime, endTime,hour_length) {
    const [startH, startM] = startTime.split(':').map(Number);
    const [endH, endM] = endTime.split(':').map(Number);

    const startTotalMinutes = startH * 60 + startM;
    const endTotalMinutes = endH * 60 + endM;

    const durationMinutes = endTotalMinutes - startTotalMinutes;
    return (durationMinutes / 60) * hour_length;
  }

  
  $.fn.smallCalendar = function (methodOrOptions) {
    if (methods[methodOrOptions]) {
      return methods[methodOrOptions].apply(this, Array.prototype.slice.call(arguments, 1));
    } else if (typeof methodOrOptions === 'object' || !methodOrOptions) {
      return methods.init.apply(this, arguments);
    } else {
      $.error('Method ' + methodOrOptions + ' does not exist on jQuery.smallCalendar');
    }
  };
})(jQuery);
