// notice
var local=localStorage.getItem('item-seen');
var arr_mandoc_id=[];
if (local!= null) {
  for (let i = 0; i < local.split(',').length; i++) {
    arr_mandoc_id.push(local.split(',')[i])
  }
}

for (let i = 0; i < arr_mandoc_id.length; i++) {
  $(`#item-notice-dash_${arr_mandoc_id[i]}`).remove();
}

function seen_notice(element,id){
  arr_mandoc_id.push(id);
  localStorage.setItem('item-seen',arr_mandoc_id);
}

if ($("#div-container").find(".status-away").length==0) {
  $('#modal-notice').css('display', 'none');
  $('#modal-notice').removeClass('show');
}
function closeModal(){
  $('#modal-notice').removeClass('show');
  $('#modal-notice').css('display', 'none');

};
  
// end notice 
// Truong Phu Dong:  Biến động nhấn sự theo tháng 

    var now = new Date();
    var month = (now.getMonth() + 1);
    var day = now.getDate();
    if (month < 10)
        month = "0" + month;
    if (day < 10)
        day = "0" + day;
    var today =  month + '-' + now.getFullYear();
    
    // Kiểm tra element tồn tại trước khi set value
    var changePickerElement = document.getElementById('change_in_personnel_picker');
    if (changePickerElement) {
        changePickerElement.value = today;
        $('#change_in_personnel_picker').val(today);
    }


  // var today = moment().format('YYYY-MM');
  // $('#change_in_personnel_picker').val(new Date(today).toJSON().slice(0,10));


  // Chỉ attach event listeners nếu element tồn tại
  if (document.getElementById('change_in_personnel_picker')) {
    $('#change_in_personnel_picker').on("changeDate", function(e) {
      filterCalender(e.date.getMonth() + 1,e.date.getFullYear());

    });

    $('#change_in_personnel_picker').on("keyup", function(e) {
    if(e.target.value.trim().length == 0){
      chart_change_personnel.xAxis[0].update({categories: month_user_change_list})
      chart_change_personnel.series[0].update({
          name: Receive,
          data: new_user_change_count
        });
      chart_change_personnel.series[1].update({
          name: Liquidation,
          data: old_user_change_count
      });
      chart_change_personnel.redraw();
    }
    });
  } // Đóng if statement cho element check

  // Chỉ tạo chart nếu element tồn tại
  let chart_change_personnel = null;
  if (document.getElementById('chart_dashboard_Change_in_personnel_by_month')) {
    chart_change_personnel = Highcharts.chart('chart_dashboard_Change_in_personnel_by_month', {
    chart: {
      type: 'column'
    },
    title: {
      text: Change_in_staff_by_month,
      align: 'left'
    },
    xAxis: {
      categories: month_user_change_list
   },
    yAxis: {
      min: 0,
      title: {
        text: People
      },
      stackLabels: {
        enabled: true,
        style: {
          fontWeight: 'bold',
          color: ( // theme
            Highcharts.defaultOptions.title.style &&
            Highcharts.defaultOptions.title.style.color
          ) || 'gray',
          textOutline: 'none'
        }
      }
    },
    legend: {
      align: 'right',
      x: 0,
      verticalAlign: 'top',
      y: 33,
      floating: true,
      backgroundColor:
        Highcharts.defaultOptions.legend.backgroundColor || 'white',
      borderColor: '#CCC',
      borderWidth: 1,
      shadow: false
    },
    tooltip: {
      headerFormat: '<b>{point.x}</b><br/>',
      pointFormat: '{series.name}: {point.y}<br/>' + translate + ': {point.stackTotal}'
    },
    plotOptions: {
      column: {
        stacking: 'normal',
        dataLabels: {
          enabled: false
        }
      }
    },
    colors: ['#318ae7', '#31e77a']
    ,
   series: [{
      name: Receive,
      data: new_user_change_count
    }, {
      name: Liquidation,
      data: old_user_change_count

    }]
  });
  } // Đóng if statement cho chart creation

 function filterCalender(month,year) {
      jQuery.ajax({
      data: {
          month: month,
          year: year
        },
        type: 'GET',
        url: dashboards_personnelbymonth_path,
        success: function (result) {
          data_user_days = result.days.map(item=>{
            return "Ngày " + item.day
          });
          data_user_new_count = result.days.map(item=>{
            return item.new_count
          });
          data_user_old_count = result.days.map(item=>{
            return item.old_count
          });
          chart_change_personnel.xAxis[0].update({categories: data_user_days})
          chart_change_personnel.series[0].update({
              name: Receive,
              data: data_user_new_count
            });
          chart_change_personnel.series[1].update({
              name: Liquidation,
              data: data_user_old_count
          });
          chart_change_personnel.redraw();
      }
    });
  }


//  Truong Phu Dong:  end
// ================================================================================

    // Lazy load Phân bổ nhân sự
    // Dat Le
    var nows = new Date();
    var current_year = nows.getFullYear();
    let user_rank_char = null;
    function renderUserRankChart() {
        if (user_rank_char) return;

        // set giá trị mặc định năm
        $('#change_in_personnel_picker_dv').val(current_year);

        // tạo chart
        user_rank_char = Highcharts.chart('chart_dashboard_Personnel_allocation_by_unit', {
            chart: { type: 'column' },
            title: { text: Staff_allocation_by_unit, align: 'left' },
            xAxis: { categories: months },
            yAxis: {
                min: 0,
                title: { text: People },
                stackLabels: {
                    enabled: true,
                    style: {
                        fontWeight: 'bold',
                        color: (Highcharts.defaultOptions.title.style &&
                            Highcharts.defaultOptions.title.style.color) || 'gray',
                        textOutline: 'none'
                    }
                }
            },
            legend: {
                align: 'right', x: 0, verticalAlign: 'top', y: 33, floating: true,
                backgroundColor: Highcharts.defaultOptions.legend.backgroundColor || 'white',
                borderColor: '#CCC', borderWidth: 1, shadow: false
            },
            tooltip: {
                headerFormat: '<b>{point.x}</b><br/>',
                pointFormat: '{series.name}: {point.y}<br/>' + translate + ': {point.stackTotal}'
            },
            plotOptions: {
                column: { stacking: 'normal', dataLabels: { enabled: false } }
            },
            series: getRankChartData(current_year)
        });

        // bỏ skeleton khi chart đã có
        document.getElementById('chart_dashboard_Personnel_allocation_by_unit')
            ?.classList.remove('skeleton', 'skeleton-chart');

        // gắn handler đổi năm
        $("#change_in_personnel_picker_dv")
            .off('changeDate.rank')
            .on('changeDate.rank', function (ev) {
                if (!user_rank_char) return;
                user_rank_char.showLoading();
                let selectYear = ev.target.value;
                let seriesData = getRankChartData(selectYear);
                seriesData.forEach((data, index) => {
                    user_rank_char.series[index].update(data, false);
                });
                user_rank_char.redraw();
                setTimeout(() => user_rank_char.hideLoading(), 300);
            });
    }

    (function lazyRenderChart() {
        const el = document.getElementById('chart_dashboard_Personnel_allocation_by_unit');
        if (!el) return;

        if ('IntersectionObserver' in window) {
            const io = new IntersectionObserver((entries, obs) => {
                entries.forEach(e => {
                    if (e.isIntersecting) {
                        renderUserRankChart();
                        obs.unobserve(el);
                    }
                });
            }, { rootMargin: '200px 0px', threshold: 0.01 });
            io.observe(el);
        } else {
            renderUserRankChart();
        }
    })();

    document.addEventListener('turbo:before-cache', function () {
        if (user_rank_char) {
            try { user_rank_char.destroy(); } catch (e) {}
            user_rank_char = null;
        }
    });
    function getRankChartData(year){
        let user_rank_data = []
        academic_rank.forEach(rank=>{
          let count_by_month = [];
          for (let i = 0; i < 12; i++) {
            let count = 0;
            for (let index = 0; index < user_data_list.length; index++) {
              let user = user_data_list[index];
              let date_from = new Date(Date.parse(user.dtfrom));
              let date_to = new Date(Date.parse(user.dtto));
              if(user.academic_rank != rank.rank_name){
                continue;
              }

              if(date_to.getFullYear() < year){
                continue;
              }
              if(date_to.getFullYear() == year && date_from.getMonth() <= i){
                continue;
              }
              if(date_from.getFullYear() < year){
                count ++;
              }else if(date_from.getFullYear() == year){
                if(date_from.getMonth() <= i){
                  count++;
                }
              }
            }
            count_by_month.push(count);
          }

          user_rank_data.push({
            name:rank.rank_name,
            data:count_by_month
          });
        });
        return user_rank_data;
      }
    function isDayInMonth(year,month,str_date_to_check){
        if(!str_date_to_check){
          return false;
        }
        let date_check = new Date(Date.parse(str_date_to_check));
        if(date_check.getFullYear() == year && date_check.getMonth() == month){
            return true;
        }

        return false;
      }

// ================================================================================

  // Age categories
  var categories = [
    '18-20', '21-24', '25-29', '30-34', '35-40', '40-45',
    '45-49', '50-54', '55-59', '60-64', '65-69'
  ];

  Highcharts.chart('chart_dashboard_Personnel_age', {
    chart: {
      type: 'bar'
    },
    title: {
      text: Staff_age,
    align: 'left'
    },
    accessibility: {
      point: {
        valueDescriptionFormat: '{index}. '+ Age +'{xDescription}, {value}%.'
      }
    },
    xAxis: [{
      categories: categories,
      reversed: false,
      labels: {
        step: 1
      },
      accessibility: {
        description: 'Age (male)'
      }
    }, { // mirror axis on right side
      opposite: true,
      reversed: false,
      categories: categories,
      linkedTo: 0,
      labels: {
        step: 1
      },
      accessibility: {
        description: 'Age (female)'
      }
    }],
    yAxis: {
      title: {
        text: null
      },
      labels: {
        formatter: function () {
          return Math.abs(this.value) + '%';
        }
      },
      accessibility: {
        description: 'Percentage population',
        rangeDescription: 'Range: 0 to 5%'
      }
    },

    plotOptions: {
      series: {
        stacking: 'normal'
      }
    },
    colors: ['#318ae7', '#ff9b00'],
    tooltip: {
      formatter: function () {
        return '<b>' + this.series.name + ',' + Age + '' + this.point.category + '</b><br/>' +
          + Population +' : ' + Highcharts.numberFormat(Math.abs(this.point.y), 1) + '%';
      }
    },

    series: [{
          name: Male,
          data: age_male_array
      }, {
          name:Female,
          data: age_female_array
      }]
  });



// ================================================================================



    Highcharts.chart('chart_dashboard_Salary_Fund', {
    chart: {
      type: 'column'
    },
    title: {
      text: Salary_fund_of_the_last_6_months_distributed_by_room,
      align: 'left'
    },
    xAxis: {
        categories:array_6_month
    },
    yAxis: {
      min: 0,
      title: {
        text: Amount
      },
      stackLabels: {
        enabled: true,
        style: {
          fontWeight: 'bold',
          color: ( // theme
            Highcharts.defaultOptions.title.style &&
            Highcharts.defaultOptions.title.style.color
          ) || 'gray',
          textOutline: 'none'
        }
      }
    },
    legend: {
      align: 'center',
      x: 50,
      verticalAlign: 'top',
      y: 30,
      floating: true,
      backgroundColor:
        Highcharts.defaultOptions.legend.backgroundColor || 'white',
      borderColor: '#CCC',
      borderWidth: 1,
      shadow: false
    },
    tooltip: {
      headerFormat: '<b>{point.x}</b><br/>',
      pointFormat: '{series.name}: {point.y}<br/>' + translate + ': {point.stackTotal}'

    },
    plotOptions: {
      column: {
        stacking: 'normal',
        dataLabels: {
          enabled: false
        }
      }
    },
    colors: ['#318ae7', '#31e77a', '#ff9900', '#858585']
    ,
    series: [{
      name: Administrative_offices,
      data: [3, 25, 53, 21, 44, 10]
    }, {
      name: Accounting_department,
      data: [14, 66, 42, 12, 22, 14]
    }, {
      name: Examination_room,
      data: [23, 8, 8, 20, 3, 5]
    }, {
      name: Admissions_Office,
      data: [11, 25, 42, 22, 45, 21]
    }]
  });



// ================================================================================

  Highcharts.chart('chart_dashboard_Average_salary_per_unit', {
    chart: {
      type: 'column'
    },
    title: {
      text: Average_salary_per_unit,
      align: 'left'
    },
    xAxis: {
      categories:chart_months
    },
    yAxis: {
      title: {
        text: Amount
      }
    },
    credits: {
      enabled: false
    },
    series: [{
      name: Units,
      data: [
        7000000, 4000000, 5000000, 7000000, 6000000]
    }]
  });

// ================================================================================


  Highcharts.chart('chart_dashboard_Salary_structure_division', {
  chart: {
    type: 'areaspline'
  },
  title: {
    text: Salary_structure_distribution,
    align: 'left'
  },
  legend: {
    layout: 'vertical',
    align: 'right',
    verticalAlign: 'top',
    x: -30,
    y: 33,
    floating: true,
    borderWidth: 1,
    backgroundColor:
      Highcharts.defaultOptions.legend.backgroundColor || '#FFFFFF'
  },
  xAxis: {
    plotBands: [{ // Highlight the two last years
      from: 2019,
      to: 2020,
      color: 'rgba(68, 170, 213, .2)'
    }]
  },
  yAxis: {
    title: {
      text: Amount
    }
  },
  tooltip: {
    shared: true,
    headerFormat: '<b>  '+ Salary_structure_distribution +' {point.x}</b><br>'
  },
  credits: {
    enabled: false
  },
  plotOptions: {
    series: {
      pointStart: 2000
    },
    areaspline: {
      fillOpacity: 0.5
    }
  },
  series: [{
    name: Salary,
    data:
      [
        122,
        45,
        78,
        355,
        21,
        64,
        77,
        755,
        45,
        35
      ]
  }, {
    name: Insurance,
    data:
      [
        24,
        422,
        36,
        132,
        75,
        424,
        71,
        755,
        74,
        455
      ]
  }, {
    name: Extra_income,
    data:
      [
        454,
        85,
        450,
        45,
        457,
        758,
        45,
        212,
        75,
        454
      ]
  }, {
    name: Bonus,
    data:
      [
        123,
        254,
        2422,
        442,
        425,
        42,
        125,
        241,
        252,
        21
      ]
  }, {
    name: Other_salary,
    data:
      [
        757,
        78,
        868,
        54,
        421,
        424,
        42,
        12,
        424,
        124
      ]
  }]
  });



  document.addEventListener("click", function(){
    $('#modal-notice').removeClass('show');
    $('#modal-notice').css('display','none');
  });
