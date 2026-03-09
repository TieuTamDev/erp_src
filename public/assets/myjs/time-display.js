var totalSec1;
   var totalSec2;
   var totalSec, day, month, year, hour, min, sec;

   function toDateTime(secx) // Đổi giây ra ngày tháng năm, giờ phút, giây
   {
       sec = secx / 1000;
       min = Math.floor(sec / 60);
       sec -= min * 60;

       hour = Math.floor(min / 60);
       min -= hour * 60;

       day = Math.floor(hour / 24); 

       hour -= day * 24;

       year = Math.floor(day / 365);
       day -= year * 365;

       var soNgay = day;
       timThang(soNgay);
   }

   var ngayTrongThang = new Array(31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31); // Áp dụng tính cho các tháng 30, 31 hay 28 ngày.
   function timThang(soNgay) { 
       for (var i = 0; i <= 11; i++) {
           if (soNgay >= ngayTrongThang[i]) {
               soNgay -= ngayTrongThang[i];
           }
           else {
               month = i;
               day = soNgay;
               break;
           }
       }
   }
