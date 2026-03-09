$( document ).ready(function() {
  var optionTableNoFileNoSearch = { 
    "info":     false,  
    "autoWidth": false, 
    "searching": false,
    columnDefs: [{ targets: 'no-sort', orderable: false }],
    "language": {
        "lengthMenu": "_MENU_",
        "decimal":        "",
        "emptyTable":     noDataTable,  
        "loadingRecords": loadingTable,
        "processing":     "",  
        "zeroRecords":    noMatchingTable,
        "paginate": {
            "first":      firstTable,
            "last":       lastTable,
            "next":       nextTable,
            "previous":   previousTable
        }
    }, 
    "order": [],
    lengthMenu: [
        [ 12],
        ["12"],
    ],
    pageLength: 12,
    "dom": '<"top"Bf>r<"table-responsive scrollbar"t><"mt-3 d-flex justify-content-center align-items-center"pl>',
    stateSave: true,
}
  $('#table_salary_benefit_user').DataTable(optionTableNoFileNoSearch); 
});

function show_feild_tax_code_Insurance_No(data, list) {
    let show_feild_forensic_information = document.getElementById("show_feild_forensic_information");       
    if (data == "forensic"){
        if (show_feild_forensic_information) {
        if (!show_feild_forensic_information.checked) {  
            document.getElementById("lable_forensic_information").classList.add('d-none');
            document.getElementById("lable_bhxh_user").classList.add('d-none');  
            document.getElementById("lable_tax_user").classList.add('d-none');  
            document.getElementById("lable_place_insurance_user").classList.add('d-none');  
            document.getElementById("open_bao_hiem").classList.add('capp-form-bg');

            document.getElementById("lable_cancel_forensic_information").classList.remove('d-none');
            document.getElementById("btn_add_new_forensic_information").classList.remove('d-none');
            document.getElementById("feild_bhxh_user").classList.remove('d-none');  
            document.getElementById("feild_tax_user").classList.remove('d-none');  
            document.getElementById("feild_place_insurance_user").classList.remove('d-none');  
        } else {   
            document.getElementById("lable_forensic_information").classList.remove('d-none');
            document.getElementById("lable_bhxh_user").classList.remove('d-none');  
            document.getElementById("lable_tax_user").classList.remove('d-none');  
            document.getElementById("lable_place_insurance_user").classList.remove('d-none');  
            document.getElementById("open_bao_hiem").classList.remove('capp-form-bg');

            document.getElementById("btn_add_new_forensic_information").classList.add('d-none');
            document.getElementById("lable_cancel_forensic_information").classList.add('d-none');
            document.getElementById("feild_bhxh_user").classList.add('d-none');  
            document.getElementById("feild_tax_user").classList.add('d-none');  
            document.getElementById("feild_place_insurance_user").classList.add('d-none');  
        }
        }
    }
   
} 

function clickCollapseFamilyInfo(element){
    document.getElementById('collapse-family-icon-info').style.rotate = element.className.includes('collapsed') ? "90deg" : "unset";
}
function clickCollapseInsurantInfo(element){
    document.getElementById('collapse-insurant-icon-info').style.rotate = element.className.includes('collapsed') ? "90deg" : "unset";
}
function clickCollapseBenefitPayslipInfo(element){
    document.getElementById('icon_payslip_benefit').style.rotate = element.className.includes('collapsed') ? "unset" : "-90deg";
}
var value_year_benefit = $( "#date_benefit_year" ).val() 
$( "#title_table_benefit" ).text(translate_Title_table_benefit+" "+value_year_benefit);
var select_year_benefit = $("#date_benefit_year");

var chart_benefit_amount_month = Highcharts.chart('chart_benefit', {
    chart: {
      type: 'line'
    },
    title: {
      text: translate_Title_benefit +" "+ value_year_benefit
    },
    xAxis: { 
      categories: value_month
    },
    yAxis: {
      title: {
        text: translate_Amount
      }
    }, 
    colors: ['#318ae7', '#31e77a', '#ff9900', '#858585'],
    plotOptions: {
      line: {
        dataLabels: {
          enabled: false
        }
      }
    },
    series: [{
      name: translate_Basic_Salary,
      data: value_base_salary
    }, {
      name: translate_Additional_Income,
      data: value_extra_income
    }, {
        name: translate_Deductions,
        data: value_dedution
    }, {
    name: translate_Perform,
    data: value_snet
    }]
  });

select_year_benefit.addClass("form-select form-select-sm");
select_year_benefit.change(function() {
  chart_benefit_amount_month.showLoading();
  value_year_benefit = $( "#date_benefit_year" ).val();
  jQuery.ajax({
    data: {
      user_id: user_id_detail,
      syear: value_year_benefit
    },
        type: 'POST',
        url: link_show_chart,
        success: function (result) { 
          $( "#title_table_benefit" ).text(translate_Title_table_benefit+" "+value_year_benefit);
          chart_benefit_amount_month = Highcharts.chart('chart_benefit', {
                chart: {
                  type: 'line'
                },
                title: {
                  text: translate_Title_benefit +" "+ value_year_benefit
                },
                xAxis: { 
                  categories: value_month
                },
                yAxis: {
                  title: {
                    text: translate_Amount
                  }
                }, 
                colors: ['#318ae7', '#31e77a', '#ff9900', '#858585'],
                plotOptions: {
                  line: {
                    dataLabels: {
                      enabled: false
                    }
                  }
                },
                series: [{
                  name: translate_Basic_Salary,
                  data: result.data_Basic_Salary
                }, {
                  name: translate_Additional_Income,
                  data: result.data_Additional_Income
                }, {
                    name: translate_Deductions,
                    data: result.data_Deductions
                }, {
                name: translate_Perform,
                data: result.data_Net
                }]
          }); 
          $("#tbody_salary_benefit_user tr").remove(); 
          if (result.data_Table.length == 0) {
            $("#tbody_salary_benefit_user").append(`
            <tr>
            <td colspan="6" style="text-align: center" class="ps-0">${noMatchingTable}</td>
            <td style="text-align: center" class="d-none"></td>
            <td style="text-align: center" class="d-none"></td>
            <td style="text-align: center" class="d-none"></td>
            <td style="text-align: center" class="d-none"></td>
            <td style="text-align: center" class="d-none"></td>
            </tr>
            `);
          } else {
            for (let i = 0; i < result.data_Table.length; i++) { 
              $("#tbody_salary_benefit_user").append(`
              <tr>
                <td style="text-align: center" class="ps-0">${result.data_Table[i].month}</td>
                <td style="text-align: center">${result.data_Table[i].basic_Salary.toString().replace(/(\d)(?=(\d\d\d)+(?!\d))/g, "$1,")}đ</td>
                <td style="text-align: center">${result.data_Table[i].additional_Income.toString().replace(/(\d)(?=(\d\d\d)+(?!\d))/g, "$1,")}đ</td>
                <td style="text-align: center">${result.data_Table[i].Deductions.toString().replace(/(\d)(?=(\d\d\d)+(?!\d))/g, "$1,")}đ</td>
                <td style="text-align: center">${result.data_Table[i].Net.toString().replace(/(\d)(?=(\d\d\d)+(?!\d))/g, "$1,")}đ</td>
                  <td style="text-align: center;" class="pe-0">
                    <a type="button" data-bs-toggle="modal" data-bs-target="#payslip_benefit_${result.data_Table[i].id}">
                      <span  class="fas fa-money-check-alt fs-1" style="vertical-align: middle;"></span>
                    </a> 
                    <div class="modal fade style_table_benefit" id="payslip_benefit_${result.data_Table[i].id}" data-bs-keyboard="false" data-bs-backdrop="static" tabindex="-1" aria-labelledby="payslip_benefit_${result.data_Table[i].id}Label" aria-hidden="true">
                      <div class="modal-dialog modal-xl mt-6" role="document" style="max-width: 90% !important;">
                        <div class="modal-content border-0">
                          <div class="position-absolute top-0 end-0 mt-3 pt-1 me-3 z-index-1">
                            <button class="btn-close btn btn-sm btn-circle d-flex flex-center transition-base" data-bs-dismiss="modal" aria-label="Close"></button>
                          </div>
                          <div class="modal-body p-0">
                            <div class="rounded-top-lg py-3 ps-4 pe-6" style="--falcon-bg-opacity: 1; background-color: rgba(var(--falcon-facebook-rgb), var(--falcon-bg-opacity)) !important;border-top-left-radius: 0.3rem !important;border-top-right-radius: 0.3rem !important;">
                              <h4 class="mb-0 text-uppercase" id="staticBackdropLabel" style="color: aliceblue;">Thông tin chi tiết tiền lương tháng ${result.data_Table[i].month}. ${result.data_Table[i].year}</h4>
                              <h5 class="mb-0 text-uppercase" id="staticBackdropLabel" style="color: aliceblue;">Salary payslip ${result.data_Table[i].month}. ${result.data_Table[i].year}</h5>
                            </div>
                            <div class="mt-2 p-2 ps-3 pe-3">
                              <table class="table border border-1 table-sm mb-0" style="color: var(--falcon-badge-soft-dark-color);">
                                <tbody> 
                                  <tr>
                                    <td class="ps-2 pe-2 border-bottom-0"  style="font-weight: bold; text-align: left; color: var(--falcon-badge-soft-dark-color);">Họ và tên/Staff Name:</td>
                                    <td class="ps-2 pe-2 border-bottom-0"  style="width: 15%;font-weight: 500; text-align: left;--falcon-bg-opacity: 1; color: rgba(var(--falcon-facebook-rgb), var(--falcon-bg-opacity)) !important;">${user_name}</td>
                                    <td class="ps-2 pe-2 border-start border-bottom-0"  style="font-weight: 500; text-align: left; color: var(--falcon-badge-soft-dark-color);">Ngày công chuẩn trong tháng:</td>
                                    <td class="ps-2 pe-2 border-bottom-0"  style="width: 10%;font-weight: 500; text-align: left;--falcon-bg-opacity: 1; color: rgba(var(--falcon-facebook-rgb), var(--falcon-bg-opacity)) !important;">26 ngày</td>
                                  </tr>
                                  <tr>
                                    <td class="ps-2 pe-2 border-bottom-0"  style="font-weight: bold; text-align: left; color: var(--falcon-badge-soft-dark-color);">Mã nhân viên/Staff Code:</td>
                                    <td class="ps-2 pe-2 border-bottom-0"  style="width: 15%;font-weight: 500; text-align: left;--falcon-bg-opacity: 1; color: rgba(var(--falcon-facebook-rgb), var(--falcon-bg-opacity)) !important;">${user_sid}</td>
                                    <td class="ps-2 pe-2 border-start border-bottom-0"  style="font-weight: 500; text-align: left; color: var(--falcon-badge-soft-dark-color);">Ngày công thực tế làm việc:</td>
                                    <td class="ps-2 pe-2 border-bottom-0"  style="width: 10%;font-weight: 500; text-align: left;--falcon-bg-opacity: 1; color: rgba(var(--falcon-facebook-rgb), var(--falcon-bg-opacity)) !important;">26 ngày</td>
                                  </tr>
                                  <tr>
                                    <td class="ps-2 pe-2 border-bottom-0"  style="font-weight: bold; text-align: left; color: var(--falcon-badge-soft-dark-color);">Phòng ban/Department:</td>
                                    <td class="ps-2 pe-2 border-bottom-0"  style="width: 15%;font-weight: 500; text-align: left;--falcon-bg-opacity: 1; color: rgba(var(--falcon-facebook-rgb), var(--falcon-bg-opacity)) !important;">${name_department}</td>
                                    <td class="ps-2 pe-2 border-start border-bottom-0"  style="font-weight: 500; text-align: left; color: var(--falcon-badge-soft-dark-color);"><b><i>Trong đó:</i></b></td>
                                    <td class="ps-2 pe-2 border-bottom-0"  style="width: 15%;font-weight: 500; text-align: left;--falcon-bg-opacity: 1; color: rgba(var(--falcon-facebook-rgb), var(--falcon-bg-opacity)) !important;"></td>
                                  </tr>
                                  <tr>
                                    <td class="ps-2 pe-2 border-bottom-0"  style="font-weight: bold; text-align: left; color: var(--falcon-badge-soft-dark-color);">Vị trí việc làm/Job Position:</td>
                                    <td class="ps-2 pe-2 border-bottom-0"  style="width: 15%;font-weight: 500; text-align: left;--falcon-bg-opacity: 1; color: rgba(var(--falcon-facebook-rgb), var(--falcon-bg-opacity)) !important;">${job_name}</td>
                                    <td class="ps-2 pe-2 border-start border-bottom-0"  style="font-weight: 500; text-align: left; color: var(--falcon-badge-soft-dark-color);">- Số ngày thử việc:</td>
                                    <td class="ps-2 pe-2 border-bottom-0"  style="width: 10%;font-weight: 500; text-align: left;--falcon-bg-opacity: 1; color: rgba(var(--falcon-facebook-rgb), var(--falcon-bg-opacity)) !important;">0 ngày</td>
                                  </tr>
                                  <tr>
                                    <td class="ps-2 pe-2 border-bottom-0"  style="font-weight: bold; text-align: left; color: var(--falcon-badge-soft-dark-color);">
                                      Lương cơ bản/Base Salary:
                                    </td>
                                    <td class="ps-2 pe-2 border-bottom-0"  style="width: 15%;font-weight: 500; text-align: left;--falcon-bg-opacity: 1; color: rgba(var(--falcon-facebook-rgb), var(--falcon-bg-opacity)) !important;">
                                    ${result.data_Table[i].basic_Salary.toString().replace(/(\d)(?=(\d\d\d)+(?!\d))/g, "$1,")}đ
                                    </td>
                                    <td class="ps-2 pe-2 border-start border-bottom-0"  style="font-weight: 500; text-align: left; color: var(--falcon-badge-soft-dark-color);">
                                      - Số ngày chính thức:
                                    </td>
                                    <td class="ps-2 pe-2 border-bottom-0"  style="width: 10%;font-weight: 500; text-align: left;--falcon-bg-opacity: 1; color: rgba(var(--falcon-facebook-rgb), var(--falcon-bg-opacity)) !important;">
                                      0 ngày
                                    </td>
                                  </tr>
                                  <tr>
                                    <td class="ps-2 pe-2 border-bottom-0"  style="font-weight: bold; text-align: left; color: var(--falcon-badge-soft-dark-color);">
                                      Tổng thu nhập khi làm đủ ngày công chuẩn/Total Income:
                                    </td>
                                    <td class="ps-2 pe-2 border-bottom-0"  style="width: 15%;font-weight: 500; text-align: left;--falcon-bg-opacity: 1; color: rgba(var(--falcon-facebook-rgb), var(--falcon-bg-opacity)) !important;">
                                    ${result.data_Table[i].basic_Salary.toString().replace(/(\d)(?=(\d\d\d)+(?!\d))/g, "$1,")}đ
                                    </td>
                                    <td class="ps-2 pe-2 border-start border-bottom-0"  style="font-weight: 500; text-align: left; color: var(--falcon-badge-soft-dark-color);">
                                      - Số ngày nghỉ phép:
                                    </td>
                                    <td class="ps-2 pe-2 border-bottom-0"  style="width: 10%;font-weight: 500; text-align: left;--falcon-bg-opacity: 1; color: rgba(var(--falcon-facebook-rgb), var(--falcon-bg-opacity)) !important;">
                                      0 ngày
                                    </td>
                                  </tr>
                                  <tr>
                                    <td class="ps-2 pe-2 border-bottom-0"  style="font-weight: bold; text-align: left; color: var(--falcon-badge-soft-dark-color);">
                                      Trình độ học vấn/Academic Level:
                                    </td>
                                    <td class="ps-2 pe-2 border-bottom-0"  style="width: 15%;font-weight: 500; text-align: left;--falcon-bg-opacity: 1; color: rgba(var(--falcon-facebook-rgb), var(--falcon-bg-opacity)) !important;">
                                    ${academic_rank}
                                    </td>
                                    <td class="ps-2 pe-2 border-start border-bottom-0"  style="font-weight: 500; text-align: left; color: var(--falcon-badge-soft-dark-color);">
                                      - Số ngày công vượt NCC:
                                    </td>
                                    <td class="ps-2 pe-2 border-bottom-0"  style="width: 10%;font-weight: 500; text-align: left;--falcon-bg-opacity: 1; color: rgba(var(--falcon-facebook-rgb), var(--falcon-bg-opacity)) !important;">
                                      0 ngày
                                    </td>
                                  </tr>
                                  <tr>
                                    <td class="ps-2 pe-2 border-bottom-0"  style="font-weight: bold; text-align: left; color: var(--falcon-badge-soft-dark-color);">
                                      Số năm kinh nghiệm/No. of Years of Experience:
                                    </td>
                                    <td class="ps-2 pe-2 border-bottom-0"  style="width: 15%;font-weight: 500; text-align: left;--falcon-bg-opacity: 1; color: rgba(var(--falcon-facebook-rgb), var(--falcon-bg-opacity)) !important;">
                                      2 năm
                                    </td>
                                    <td class="ps-2 pe-2 border-start border-bottom-0"  style="font-weight: 500; text-align: left; color: var(--falcon-badge-soft-dark-color);">
                                      - Số ngày nghỉ covid khi thử việc:
                                    </td>
                                    <td class="ps-2 pe-2 border-bottom-0"  style="width: 10%;font-weight: 500; text-align: left;--falcon-bg-opacity: 1; color: rgba(var(--falcon-facebook-rgb), var(--falcon-bg-opacity)) !important;">
                                      0 ngày
                                    </td>
                                  </tr>
                                  <tr>
                                    <td class="ps-2 pe-2 border-bottom-0"  style="font-weight: bold; text-align: left; color: var(--falcon-badge-soft-dark-color);">
                                      Thâm niên làm việc tại BUH/No. of Years working in BUH:
                                    </td>
                                    <td class="ps-2 pe-2 border-bottom-0 tham_nien_benefit" style="width: 15%;font-weight: 500; text-align: left;--falcon-bg-opacity: 1; color: rgba(var(--falcon-facebook-rgb), var(--falcon-bg-opacity)) !important;">
                                      
                                    </td>
                                    <td class="ps-2 pe-2 border-start border-bottom-0"  style="font-weight: 500; text-align: left; color: var(--falcon-badge-soft-dark-color);">
                                      - Số ngày nghỉ lương chế độ BHXH:
                                    </td>
                                    <td class="ps-2 pe-2 border-bottom-0"  style="width: 10%;font-weight: 500; text-align: left;--falcon-bg-opacity: 1; color: rgba(var(--falcon-facebook-rgb), var(--falcon-bg-opacity)) !important;">
                                      0 ngày
                                    </td>
                                  </tr>
                                  <tr>
                                    <td class="ps-2 pe-2 border-bottom-0"  style="font-weight: bold; text-align: left; color: var(--falcon-badge-soft-dark-color);">
                                      Điểm đánh giá nhân lực/KPI:
                                    </td>
                                    <td class="ps-2 pe-2 border-bottom-0" style="width: 15%;font-weight: 500; text-align: left;--falcon-bg-opacity: 1; color: rgba(var(--falcon-facebook-rgb), var(--falcon-bg-opacity)) !important;">
                                      80%
                                    </td>
                                    <td class="ps-2 pe-2 border-start border-bottom-0"  style="font-weight: 500; text-align: left; color: var(--falcon-badge-soft-dark-color);">
                                      - Số ngày làm lễ, tết:
                                    </td>
                                    <td class="ps-2 pe-2 border-bottom-0"  style="width: 10%;font-weight: 500; text-align: left;--falcon-bg-opacity: 1; color: rgba(var(--falcon-facebook-rgb), var(--falcon-bg-opacity)) !important;">
                                      0 ngày
                                    </td>
                                  </tr>
                                  <tr>
                                    <td class="ps-2 pe-2 border-bottom-0"  style="font-weight: bold; text-align: left; color: var(--falcon-badge-soft-dark-color);">
                                      Số người phụ thuộc/No. of Department:
                                    </td>
                                    <td class="ps-2 pe-2 border-bottom-0" style="width: 15%;font-weight: 500; text-align: left;--falcon-bg-opacity: 1; color: rgba(var(--falcon-facebook-rgb), var(--falcon-bg-opacity)) !important;">
                                      2 người
                                    </td>
                                    <td class="ps-2 pe-2 border-start border-bottom-0"  style="font-weight: 500; text-align: left; color: var(--falcon-badge-soft-dark-color);">
                                      - Số buổi trực 12h:
                                    </td>
                                    <td class="ps-2 pe-2 border-bottom-0"  style="width: 10%;font-weight: 500; text-align: left;--falcon-bg-opacity: 1; color: rgba(var(--falcon-facebook-rgb), var(--falcon-bg-opacity)) !important;">
                                      0 buổi
                                    </td>
                                  </tr>
                                  <tr>
                                    <td class="ps-2 pe-2 border-bottom-0"  style="font-weight: bold; text-align: left; color: var(--falcon-badge-soft-dark-color);">
                                      Mức giảm trừ cho người phụ thộc/Deduction of Dependants:
                                    </td>
                                    <td class="ps-2 pe-2 border-bottom-0" style="width: 15%;font-weight: 500; text-align: left;--falcon-bg-opacity: 1; color: rgba(var(--falcon-facebook-rgb), var(--falcon-bg-opacity)) !important;">
                                      200,000 VND
                                    </td>
                                    <td class="ps-2 pe-2 border-start border-bottom-0"  style="font-weight: 500; text-align: left; color: var(--falcon-badge-soft-dark-color);">
                                      - Số buổi trực 16h:
                                    </td>
                                    <td class="ps-2 pe-2 border-bottom-0"  style="width: 10%;font-weight: 500; text-align: left;--falcon-bg-opacity: 1; color: rgba(var(--falcon-facebook-rgb), var(--falcon-bg-opacity)) !important;">
                                      0 buổi
                                    </td>
                                  </tr>
                                  <tr>
                                    <td class="ps-2 pe-2 border-bottom-0"  style="font-weight: bold; text-align: left; color: var(--falcon-badge-soft-dark-color);">
                                      Mức giảm trừ cho bản thân/Deduction of Family Circumtance:
                                    </td>
                                    <td class="ps-2 pe-2 border-bottom-0" style="width: 15%;font-weight: 500; text-align: left;--falcon-bg-opacity: 1; color: rgba(var(--falcon-facebook-rgb), var(--falcon-bg-opacity)) !important;">
                                      200,000 VND
                                    </td>
                                    <td class="ps-2 pe-2 border-start border-bottom-0"  style="font-weight: 500; text-align: left; color: var(--falcon-badge-soft-dark-color);">
                                      - Số buổi trực 24h:
                                    </td>
                                    <td class="ps-2 pe-2 border-bottom-0"  style="width: 10%;font-weight: 500; text-align: left;--falcon-bg-opacity: 1; color: rgba(var(--falcon-facebook-rgb), var(--falcon-bg-opacity)) !important;">
                                      0 buổi
                                    </td>
                                  </tr>
                                  <tr>
                                    <td class="ps-2 pe-2"  style="font-weight: bold; text-align: left; color: var(--falcon-badge-soft-dark-color);"> 
                                    </td>
                                    <td class="ps-2 pe-2" style="width: 15%;font-weight: 500; text-align: left;--falcon-bg-opacity: 1; color: rgba(var(--falcon-facebook-rgb), var(--falcon-bg-opacity)) !important;">
                                    </td>
                                    <td class="ps-2 pe-2 border-start"  style="font-weight: 500; text-align: left; color: var(--falcon-badge-soft-dark-color);">
                                      - Số buổi trực lãnh đạo:
                                    </td>
                                    <td class="ps-2 pe-2"  style="width: 10%;font-weight: 500; text-align: left;--falcon-bg-opacity: 1; color: rgba(var(--falcon-facebook-rgb), var(--falcon-bg-opacity)) !important;">
                                      0 buổi
                                    </td>
                                  </tr>
                                </tbody>
                              </table> 
                            </div>
                            <div class="p-2 ps-3 pe-3">
                                <table class="table table-bordered border border-1 table-sm mb-0" style="color: var(--falcon-badge-soft-dark-color);">
                                  <thead style="--falcon-bg-opacity: 1; background-color: rgba(var(--falcon-facebook-rgb), var(--falcon-bg-opacity)) !important; color: aliceblue;">
                                    <tr>
                                      <th colspan="3" style="text-align: center">Thu nhập chi tiết/Detail Income</th>
                                    </tr>
                                  </thead>
                                  <tbody> 
                                    <tr>
                                      <td class="ms-0 ps-2 pe-2 border border-1">
                                        <div class="d-flex">
                                          <div class="d-flex flex-column flex-grow-1" style="text-align: left">
                                            <span class="m-0 p-0" style="font-weight: 600;">1. Trợ cấp theo vị trí</span> 
                                            <span class="m-0 p-0" style="font-weight: 600;">Position Allowance</span>  
                                          </div>
                                          <div class="d-flex align-items-center" style="font-weight: 600;">
                                            0 VND
                                          </div>
                                        </div>
                                        <div class="d-flex mt-2">
                                          <div class="d-flex flex-column flex-grow-1" style="text-align: left">
                                            <span class="m-0 p-0" style="font-weight: 600;">2. Trợ cấp theo trình độ</span> 
                                            <span class="m-0 p-0" style="font-weight: 600;">Academic Allowance</span>  
                                          </div>
                                          <div class="d-flex align-items-center" style="font-weight: 600;">
                                            0 VND
                                          </div>
                                        </div>
                                      </td> 
                                      <td class="ms-0 ps-2 pe-2 border border-1">
                                        <div class="d-flex">
                                          <div class="d-flex flex-column flex-grow-1" style="text-align: left">
                                            <span class="m-0 p-0" style="font-weight: 600;">3. Trợ cấp theo kinh nghiệm</span> 
                                            <span class="m-0 p-0" style="font-weight: 600;">Experience Allowance</span>  
                                          </div>
                                          <div class="d-flex align-items-center" style="font-weight: 600;">
                                            0 VND
                                          </div>
                                        </div>
                                        <div class="d-flex mt-2">
                                          <div class="d-flex flex-column flex-grow-1" style="text-align: left">
                                            <span class="m-0 p-0" style="font-weight: 600;">4. Trợ cấp theo thâm niên</span> 
                                            <span class="m-0 p-0" style="font-weight: 600;">Seniority Allowance</span>  
                                          </div>
                                          <div class="d-flex align-items-center" style="font-weight: 600;">
                                            0 VND
                                          </div>
                                        </div>
                                      </td> 
                                      <td class="ms-0 ps-2 pe-2 border border-1">
                                        <div class="d-flex">
                                          <div class="d-flex flex-column flex-grow-1" style="text-align: left">
                                            <span class="m-0 p-0" style="font-weight: 600;">5. Trợ cấp theo năng lực</span> 
                                            <span class="m-0 p-0" style="font-weight: 600;">Performance Allowance</span>  
                                          </div>
                                          <div class="d-flex align-items-center" style="font-weight: 600;">
                                            0 VND
                                          </div>
                                        </div>
                                        <div class="d-flex mt-2">
                                          <div class="d-flex flex-column flex-grow-1" style="text-align: left">
                                            <span class="m-0 p-0" style="font-weight: 600;">6. Trợ cấp khác</span> 
                                            <span class="m-0 p-0" style="font-weight: 600;">Other Allowance</span>  
                                          </div>
                                          <div class="d-flex align-items-center" style="font-weight: 600;">
                                            0 VND
                                          </div>
                                        </div>
                                      </td>  
                                    </tr>
                                  </tbody>
                                  <tfoot style="--falcon-bg-opacity: 1; background-color: rgba(var(--falcon-facebook-rgb), var(--falcon-bg-opacity)) !important; color: aliceblue;">
                                    <tr>
                                      <th class="border border-1" colspan="2" style="text-align: center">Tổng thu nhập khi làm đủ ngày công chuẩn/Total Income</th>
                                      <th class="border border-1" style="text-align: center;">0 VND</th>
                                    </tr>
                                  </tfoot>
                                </table>
                            </div>
                            <div class="p-2 ps-3 pe-3">
                                <table class="table border border-1 table-sm mb-0" style="color: var(--falcon-badge-soft-dark-color);">
                                  <thead>
                                    <tr>
                                      <th class="ps-2 pe-2"  style="font-weight: 600; border: none;text-align: left;--falcon-bg-opacity: 1; background-color: rgba(var(--falcon-facebook-rgb), var(--falcon-bg-opacity)) !important;color: aliceblue;">1. Tổng thu nhập/Total Income</th>
                                      <th class="ps-2 pe-2"  style="font-weight: 600; border: none;width: 20%;text-align: right;--falcon-bg-opacity: 1; background-color: rgba(var(--falcon-facebook-rgb), var(--falcon-bg-opacity)) !important;color: aliceblue;">0 VND</th>
                                    </tr>
                                  </thead>
                                  <tbody > 
                                    <tr>
                                      <td class="ps-2 pe-2"  style="font-weight: 600; text-align: left;">1.1 Lương và các khoản trợ cấp theo ngày làm việc thực tế/Salary & Allowances</td>
                                      <td class="ps-2 pe-2"  style="font-weight: 600; text-align: center;">0 VND</td>
                                    </tr>
                                    <tr>
                                      <td class="ps-2 pe-2"  style="font-weight: 600; text-align: left;">1.2 Tiền trực/Shift Allowances</td>
                                      <td class="ps-2 pe-2"  style="font-weight: 600; text-align: center;">0 VND</td>
                                    </tr>
                                    <tr>
                                      <td class="ps-2 pe-2"  style="font-weight: 600; text-align: left;">1.3 Các khoản bổ sung khác/Other additional Income</td>
                                      <td class="ps-2 pe-2"  style="font-weight: 600; text-align: center;">0 VND</td>
                                    </tr>
                                    <tr>
                                      <td class="ps-2 pe-2"  style="text-align: left;font-style: italic;">1.3.1 Thu nhập bổ sung từ số ngày công vượt NCC</td>
                                      <td class="ps-2 pe-2"  style="text-align: center; font-style: italic;">0 VND</td>
                                    </tr>
                                    <tr>
                                      <td class="ps-2 pe-2"  style="text-align: left;font-style: italic;">1.3.2 Thu nhập bổ sung từ tiền trực lãnh đạo</td>
                                      <td class="ps-2 pe-2"  style="text-align: center; font-style: italic;">0 VND</td>
                                    </tr>
                                    <tr>
                                      <td class="ps-2 pe-2"  style="text-align: left;font-style: italic;">1.3.3 Trợ cấp hỗ trợ nghỉ ốm đau do Covid trong thời gian thử việc</td>
                                      <td class="ps-2 pe-2"  style="text-align: center; font-style: italic;">0 VND</td>
                                    </tr>
                                    <tr>
                                      <td class="ps-2 pe-2"  style="text-align: left;font-style: italic;">1.3.4 Trợ cấp làm việc ngày lễ, tết (Lương cơ bản/NCC x Số ngày công làm việc x 300%)</td>
                                      <td class="ps-2 pe-2"  style="text-align: center; font-style: italic;">0 VND</td>
                                    </tr>
                                    <tr>
                                      <td class="ps-2 pe-2"  style="text-align: left;font-style: italic;">1.3.5 Trợ cấp tham gia lấy mẫu đoàn KSK</td>
                                      <td class="ps-2 pe-2"  style="text-align: center; font-style: italic;">0 VND</td>
                                    </tr>
                                    <tr>
                                      <td class="ps-2 pe-2"  style="text-align: left;font-style: italic;">1.3.6 Truy lĩnh tháng trước</td>
                                      <td class="ps-2 pe-2"  style="text-align: center; font-style: italic;">0 VND</td>
                                    </tr>
                                    <tr>
                                      <td class="ps-2 pe-2"  style="font-weight: 600; text-align: left;">1.4 Thưởng/Bonus</td>
                                      <td class="ps-2 pe-2"  style="font-weight: 600; text-align: center;">0 VND</td>
                                    </tr>
                                    <tr>
                                      <td class="ps-2 pe-2"  style="font-weight: 600; text-align: left;">1.5 Tiền doanh thu/Revenue Income</td>
                                      <td class="ps-2 pe-2"  style="font-weight: 600; text-align: center;">0 VND</td>
                                    </tr>
                                    <tr>
                                      <td class="ps-2 pe-2"  style="font-weight: 600; text-align: left;">1.6 Tổng thu nhập/Total Income: <i>(1.1)+(1.2)+(1.3)+(1.4)+(1.5)</i></td>
                                      <td class="ps-2 pe-2"  style="font-weight: 600; text-align: center;">0 VND</td>
                                    </tr>
                                  </tbody>
                                  <thead>
                                    <tr>
                                      <th class="ps-2 pe-2"  style="font-weight: 600; border: none;text-align: left;--falcon-bg-opacity: 1; background-color: rgba(var(--falcon-facebook-rgb), var(--falcon-bg-opacity)) !important;color: aliceblue;">2. Các khoản giảm trừ/Total Deduction</th>
                                      <th class="ps-2 pe-2"  style="font-weight: 600; border: none;width: 20%;text-align: right;--falcon-bg-opacity: 1; background-color: rgba(var(--falcon-facebook-rgb), var(--falcon-bg-opacity)) !important;color: aliceblue;"></th>
                                    </tr>
                                  </thead>
                                  <tbody > 
                                    <tr>
                                      <td class="ps-2 pe-2"  style="font-weight: 600; text-align: left;">2.1 Thuế thu nhập cá nhân/Personal Income Tax</td>
                                      <td class="ps-2 pe-2"  style="font-weight: 600; text-align: center;"></td>
                                    </tr>
                                    <tr>
                                      <td class="ps-2 pe-2"  style="text-align: left;font-style: italic;">2.1.1 Thu nhập chịu thuế/Taxable income</td>
                                      <td class="ps-2 pe-2"  style="text-align: center; font-style: italic;">0 VND</td>
                                    </tr>
                                    <tr>
                                      <td class="ps-2 pe-2"  style="text-align: left;font-style: italic;">2.1.2 Giảm trừ bản thân + Người phụ thuộc/Family Circumtance Deductions & No. Of Dependants</td>
                                      <td class="ps-2 pe-2"  style="text-align: center; font-style: italic;">0 VND</td>
                                    </tr>
                                    <tr>
                                      <td class="ps-2 pe-2"  style="text-align: left;font-style: italic;">2.1.3 Thu nhập tính thuế/Taxable income (2.1.1)-(2.1.2)-(2.2)</td>
                                      <td class="ps-2 pe-2"  style="text-align: center; font-style: italic;">0 VND</td>
                                    </tr>
                                    <tr>
                                      <td class="ps-2 pe-2"  style="text-align: left;font-style: italic;">2.1.4 Thuế TNCN phải nộp/Personal Income Tax</td>
                                      <td class="ps-2 pe-2"  style="text-align: center; font-style: italic;">0 VND</td>
                                    </tr>
                                    <tr>
                                      <td class="ps-2 pe-2"  style="font-weight: 600; text-align: left;">2.2 Tiền trích đóng BHXH-BHYT-BHTN/Social Insurance - Medical Insurance - Unemployment Insurance</td>
                                      <td class="ps-2 pe-2"  style="font-weight: 600; text-align: center;">0 VND</td>
                                    </tr>
                                    <tr>
                                      <td class="ps-2 pe-2"  style="font-weight: 600; text-align: left;">2.3 Tiền trích đóng Quỹ Công đoàn/Trade Union Fee</td>
                                      <td class="ps-2 pe-2"  style="font-weight: 600; text-align: center;">0 VND</td>
                                    </tr>

                                    <tr>
                                      <td class="ps-2 pe-2"  style="font-weight: 600; text-align: left;">2.4 Tiền truy thu BHXH BHYT BHTN tháng trước/Retrieve Insurance of last month</td>
                                      <td class="ps-2 pe-2"  style="font-weight: 600; text-align: center;">0 VND</td>
                                    </tr>
                                    <tr>
                                      <td class="ps-2 pe-2"  style="font-weight: 600; text-align: left;">2.5 Các khoản khấu trừ khác/Other Deduction</td>
                                      <td class="ps-2 pe-2"  style="font-weight: 600; text-align: center;">0 VND</td>
                                    </tr>
                                    <tr>
                                      <td class="ps-2 pe-2"  style="font-weight: 600; text-align: left;">2.6 Tổng các khoản khấu trừ/Total Deduction <i>(2.1.4)+(2.2)+(2.3)+(2.4)+(2.5)</i></td>
                                      <td class="ps-2 pe-2"  style="font-weight: 600; text-align: center;">0 VND</td>
                                    </tr>
                                  </tbody>
                                  <thead>
                                    <tr>
                                      <th class="ps-2 pe-2"  style="font-weight: 600; border: none;text-align: left;--falcon-bg-opacity: 1; background-color: rgba(var(--falcon-facebook-rgb), var(--falcon-bg-opacity)) !important;color: aliceblue;">3. Thu nhập thực nhận/Net takehome pay: <i>(1.6)-(2.6)</i></th>
                                      <th class="ps-2 pe-2"  style="font-weight: 600; border: none;width: 20%;text-align: right;--falcon-bg-opacity: 1; background-color: rgba(var(--falcon-facebook-rgb), var(--falcon-bg-opacity)) !important;color: aliceblue;">0 VND</th>
                                    </tr>
                                  </thead>
                                </table>
                            </div>
                            <div class="card border m-2 ms-3 me-3 mb-3">
                              <div onclick="clickCollapseBenefitPayslipInfo(this)" class="d-flex justify-content-between align-items-center p-2 pe-3" style="text-align: left; cursor: pointer;"  data-bs-toggle="collapse" href="#collapse_payslip_benefit_${result.data_Table[i].id}" role="button" aria-expanded="false" aria-controls="collapse_payslip_benefit_${result.data_Table[i].id}">
                                <div class="d-flex" style="font-weight: 600;">
                                  <span style="--falcon-bg-opacity: 1; color: rgba(var(--falcon-facebook-rgb), var(--falcon-bg-opacity)) !important;" class="far fa-question-circle fs-1 me-2"></span>
                                  <span style="--falcon-bg-opacity: 1; color: rgba(var(--falcon-facebook-rgb), var(--falcon-bg-opacity)) !important; font-weight: 700;">Những câu hỏi thường gặp</span>
                                </div>
                                <span id="icon_payslip_benefit" style="--falcon-bg-opacity: 1; color: rgba(var(--falcon-facebook-rgb), var(--falcon-bg-opacity)) !important;" class="fas fa-caret-left fs-1"></span>
                              </div>
                              <div class="collapse" id="collapse_payslip_benefit_${result.data_Table[i].id}">
                                <table class="table table-responsive table-sm mb-0" style="color: var(--falcon-badge-soft-dark-color);">
                                  <tbody > 
                                    <tr>
                                      <td class="ms-0 p-2 border-bottom" style="border: none; ">
                                        <div class="">
                                          <div style="text-align: left">
                                            <div class="m-0 ms-1 p-0" style="font-size: 14px; font-weight: 600;color: red;">1. Bệnh viện Đại học Y Dược Buôn Ma Thuột chân thành cảm ơn sự cố gắng và nỗ lực hoàn thành công việc của Quý Anh/Chị trong thời gian vừa qua.</div> 
                                            <div class="m-0 p-0" style="text-indent: 21px; font-size: 14px; font-weight: 600;color: red;">Hy vọng Quý Anh/Chị sẽ tiếp tục phát huy năng lực và cùng đồng hành với Bệnh viện trong sứ mệnh chăm sóc sức khỏa cộng đồng.</div>  
                                          </div> 
                                        </div>
                                      </td> 
                                    </tr>
                                    <tr>
                                      <td class="ms-0 p-2 border-bottom" style="border: none; ">
                                        <div class="">
                                          <div style="text-align: left">
                                            <div class="m-0 ms-1 p-0" style="font-size: 14px; font-weight: 500;">2. Lương và phúc lợi là thông tin của từng cá nhân, Quý Anh/Chị vui lòng bảo mật thông tin theo đúng cam kết đã thỏa thuận với Bệnh viện.</div> 
                                            <div class="m-0 p-0" style="text-indent: 21px; font-size: 14px; font-weight: 500;">Việc tiết lộ thông tin cho cá nhân khác dưới bất kỳ hình thức nào khi chưa có sự đồng ý của Bệnh viện sẽ bị xử lý kỷ luật theo quy định.</div>  
                                          </div> 
                                        </div>
                                      </td> 
                                    </tr>
                                    <tr>
                                      <td class="ms-0 p-2 border-bottom" style="border: none; ">
                                        <div class="">
                                          <div style="text-align: left">
                                            <div class="m-0 ms-1 p-0" style="font-size: 14px; font-weight: 500;">3. Mọi vướng mắc của Quý Anh/Chị về thu nhập tiền lương chỉ trao đổi và giải quyết với <b>Bộ phận Tiền lương - Phòng Tổ chức - Hành chính - Quản trị</b>. Các sai sót <i>(Nếu có)</i> sẽ được điều chỉnh, bổ sung trong kỳ lương tiếp theo.</div> 
                                          </div> 
                                        </div>
                                      </td> 
                                    </tr>
                                    <tr>
                                      <td class="ms-0 p-2 border-bottom" style="border: none; ">
                                        <div class="">
                                          <div style="text-align: left">
                                            <div class="m-0 ms-1 p-0" style="font-size: 14px; font-weight: 500;">4. Các khoản chế độ của BHXH <i>(Ốm đau, thai sản, dưỡng sức,...)</i> không chi trả cùng tiền lương hằng tháng, sau khi cơ quan BHXH duyệt hồ sơ thanh toán NLĐ sẽ nhận tiền chế độ tại <b>phòng Tài chính - Kế toán</b>.</div> 
                                          </div> 
                                        </div>
                                      </td> 
                                    </tr>
                                    <tr>
                                      <td class="ms-0 p-2" style="border: none; ">
                                        <div class="">
                                          <div style="text-align: left">
                                            <div class="m-0 ms-1 p-0" style="font-size: 14px; font-weight: 500;">5. Khoản thu thuế TNCN trên đây chỉ là tạm tính và tạm nộp cho cơ quan nhà nước. Nếu người lao động có thu nhập trong năm tài chính <i>(Từ 01/01 -31/12 hằng năm)</i> tại Bệnh viện và chỉ có thu nhập tại một nơi trong năm đó thì Phòng Tài chính - Kế toán của Bệnh viện sẽ quyết toán thuế thay người lao động vào dịp kết thúc năm tài chính. Sau ngày 31/03 năm tài chính tiếp theo nếu số thuế đã tạm thu nhiều hơn số thuế phát sinh thực tế thì được hoàn trả và ngược lại nếu ít hơn thì NLĐ phải nộp bổ sung. Trường hợp NLĐ nào có 2 nguồn thu nhập trở lên trong năm tài chính thì NLĐ đó phải thực hiện việc quyết toán thuế với cơ quan nhà nước.</div> 
                                            <div class="m-0 p-0" style="text-indent: 21px; font-size: 14px; font-weight: 500;">Mọi vướng mắc về đăng ký người phụ thuộc để giảm trừ gia cảnh, quyết toán thuế TNCN, Quý Anh/Chị vui lòng liên hệ <b>Nhân viên kế toán Thuế - Phòng Tài chính Kế toán</b> để được hướng dẫn và hỗ trợ.</div>  
                                          </div> 
                                        </div>
                                      </td> 
                                    </tr>
                                  </tbody>
                                </table>
                              </div>
                            </div> 
                          </div>
                        </div>
                      </div>
                    </div>
                  </td>
              </tr>
              `);
            } 
          }
          displayData();
          chart_benefit_amount_month.hideLoading();
        }
    });
});

// 
document.getElementById("id_cancel_add_benefit").onclick = function() {
  document.getElementById("id_add_benefit").style.display = "block";
  document.getElementById("id_add_benefit_orther").style.display = "block";
  document.getElementById("id_cancel_add_benefit").style.display = "none";
}

function clickCollapseBenefit(element){
  document.getElementById('collapse-benefit').style.rotate = element.className.includes('collapsed') ? "90deg" : "unset";
}

function clickAddNewBenefit(){
  $('#id_cancel_add_benefit').css('display', 'block');
  $('#id_add_benefit').css('display', 'none');
  $("#benefit_year_add_others").val(new Date().getFullYear());
}

function clickCloseAddNewBenefit(){
  $('#id_cancel_add_benefit').css('display', 'none');
  $('#id_add_benefit').css('display', 'block');
  document.getElementById('benefit_name').value="";
  document.getElementById('benefit_amount').value="";
  document.getElementById('benefit_desc').value="";
  $("#benefit_year_add_others").prop("selectedIndex", 0).val();
}

function saveBenefitOther(){
  if ($('#benefit_name').val() == "") {
      $('#benefit_name').css('border','1px solid red');
      $('#err_add_benefit_other').css('display', 'block');
      $('#err_add_benefit_other').html(`${vaild_required} ${Benefit_name}`);
  }else{
      $('#benefit_name').css('border','1px solid var(--falcon-input-border-color)');
      $('#err_add_benefit_other').css('display', 'none');
      $('#form_add_benefit').submit();
  }
}

$('#benefit_name').click(function(){
  if ($('#benefit_name').val() == "") {
    
  }else{
      $('#benefit_name').css('border','1px solid var(--falcon-input-border-color)');
      $('#err_add_benefit_other').css('display', 'none');
  }
})

function addBenefit(year){
  $('#checkbox_all_benefit').prop('checked',false);
  $('#benefit_year').val(year);
  $('#benefit_stype').val(benefit_type);

  $('#benefit_years').val(year);

  $('#benefit_stype_add_others').val(benefit_type);

  $('#benefit_stype_add_other').val(benefit_type);
  $('#benefit_year_add_other').val(year);

  let arr=[];
  jQuery.ajax({
      type: 'POST',
      url: user_benefit_update_path,
      data : { sYear: year, benefit_type: benefit_type,  user_id: user_id} ,
      dataType: 'JSON',
      success: function(response){
          document.getElementById('item_benefit').innerHTML ="";
          document.getElementById('item_benefit_other').innerHTML ="";
          for (let i = 0; i < response.sbenefit.length; i++) {
              if (response.sbenefit[i].btype =="MONEY") {
                  document.getElementById('item_benefit').innerHTML +=`<tr>
                  <td class="align-middle" style="width:50px !important">
                      <input  class="form-check-input" value="${response.sbenefit[i].id}" type="checkbox" id="benefit-${response.sbenefit[i].id}" name="benefit_name_add[]" data-bulk-select-row="data-bulk-select-row" />
                  </td>
                      <td style="vertical-align: middle;" ><label for="${response.sbenefit[i].id}"  style="font-weight: 600;text-align: start;text-transform: capitalize;cursor:pointer;">${response.sbenefit[i].name}</label></td>
                  </tr> `;
                  for (let j = 0; j < response.benefit_other.length; j++) {
                      if (response.benefit_other[j].sbenefit_id == response.sbenefit[i].id) {
                          arr.push(response.sbenefit[i].id)
                      }
                  }
              }
          }

          for (let i = 0; i < response.benefit_other.length; i++) {
              if (response.benefit_other[i].btype =="MONEY" && response.benefit_other[i].sbenefit_id == null){
                  document.getElementById('item_benefit').innerHTML +=`<tr>
                  <td class="align-middle" style="width:50px !important">
                      <input  class="form-check-input" value="${response.benefit_other[i].id}" type="checkbox" id="benefit-${response.benefit_other[i].id}"  name="benefit_name_add[]"  data-bulk-select-row="data-bulk-select-row" checked/>
                  </td>
                      <td style="vertical-align: middle;" ><label for="${response.benefit_other[i].id}"  style="font-weight: 600;text-align: start;text-transform: capitalize;cursor:pointer;">${response.benefit_other[i].name}</label></td>
                  </tr> `;
              }
              for (let a = 0; a < arr.length; a++) {
                      $('#benefit-'+`${arr[a]}`).prop('checked',true);
                      // console.log($('#'+`${arr[a]}`).parent().parent().css({'display': 'none'}));
              }
          }
          
      }
  });
}

function addBenefitOther(year){
  $('#checkbox_all_benefit_other').prop('checked',false);

  $('#item_benefit_year_other').val(year);
  $('#item_benefit_year_others').val(year);

  $('#item_benefit_stype_other').val(benefit_type);

  $('#benefit_year_add_other').val(year);

  $('#benefit_stype_add_others').val(benefit_type);
  $('#benefit_stype_add_other').val(benefit_type);

  let arr=[];
  jQuery.ajax({
      type: 'POST',
      url: user_benefit_update_path,
      data : { sYear: year, benefit_type: benefit_type,  user_id: user_id} ,
      dataType: 'JSON',
      success: function(response){
          document.getElementById('tbody_item_benefit').innerHTML ="";
          document.getElementById('tbody_item_benefit_other').innerHTML ="";
          for (let i = 0; i < response.sbenefit.length; i++) {
              if (response.sbenefit[i].btype == "OTHER") {
                  document.getElementById('tbody_item_benefit').innerHTML +=`<tr>
                  <td class="align-middle" style="width:50px !important">
                      <input  class="form-check-input" value="${response.sbenefit[i].id}" type="checkbox" id="benefit-${response.sbenefit[i].id}" name="benefit_name_add[]" data-bulk-select-row="data-bulk-select-row"/>
                  </td>
                      <td style="vertical-align: middle;" ><label for="${response.sbenefit[i].id}"  style="font-weight: 600;text-align: start;text-transform: capitalize;cursor:pointer;">${response.sbenefit[i].name}</label></td>
                  </tr> `;
              }
              for (let j = 0; j < response.benefit_other.length; j++) {
                  if (response.benefit_other[j].sbenefit_id == response.sbenefit[i].id) {
                      arr.push(response.sbenefit[i].id)
                  }
              }
          }

          for (let b = 0; b < response.list_benefit.length; b++) {

              if (response.list_benefit[b].btype == "OTHER" && response.list_benefit[b].sbenefit_id == null) {
                  document.getElementById('tbody_item_benefit').innerHTML +=`<tr>
                  <td class="align-middle" style="width:50px !important">
                      <input  class="form-check-input" value="${response.list_benefit[b].id}" type="checkbox" id="benefit-${response.list_benefit[b].id}" name="benefit_name_add[]" data-bulk-select-row="data-bulk-select-row"checked/>
                  </td>
                      <td style="vertical-align: middle;" ><label for="${response.list_benefit[b].id}"  style="font-weight: 600;text-align: start;text-transform: capitalize;cursor:pointer;">${response.list_benefit[b].name}</label></td>
                  </tr> `;
              }
              for (let a = 0; a < arr.length; a++) {
                  $('#benefit-'+`${arr[a]}`).prop('checked',true);
              }
          }
      }
  });
}

function clickDeleteBenefit(name,user_id){
  href_benefit += `?name=${name}&uid=${user_id}`;

  let html = `${mess_del_benefit} <span style="font-weight: bold; color: red"> ${name} </span>?`
  openConfirmDialog(html,(result )=>{
      if(result){
      doClick(href_benefit,'delete')
      }
  });

}

function checkAllItemBenefitOther(isChecked) {
  // console.log(isChecked);
  if(isChecked) {
      $('input[type="checkbox"]').each(function() { 
          this.checked = true; 
      });
  } else {
      $('input[type="checkbox"]').each(function() {
          this.checked = false;
      });
  }
}