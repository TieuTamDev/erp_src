// menu reponsive
$(document).on('turbolinks:load', function() {
    var device_width = $(window).width();
	if(device_width < 900){
		$("#button-menu-top").removeClass("btn-img");
		$("#button-menu-top").click(function(){
			$("#menu-top-mobile").slideToggle().removeClass("menu-top-mb");
		});
		$("#button-menu-middle").removeClass("btn-img-middle");
		$("#button-menu-middle").click(function(){
			$("#menu-middle-mobile").fadeToggle().removeClass("menu-middle-mb");
		});
	}
	//resize table
	$(".panel-top").resizable({
      handleSelector: ".splitter-horizontal",
      resizeWidth: false,
  	});
	$(function(){
	    $("table").resizableColumns({
	      store: store
	    });
	});
	// hightlight navigation
	var count= $(".navi_header_menu li").length;
	for(var i=0;i<count;i++){
		var link_href=$(".navi_header_menu li:eq("+i+") a").attr("href");
		var link_location =  $(location).attr('pathname');
		var link_sub_1 = link_href.replace("/","");
		var link_host = $(location).attr('href');
		var get_link_host = link_host.split('/');
		var link_sub_2 =get_link_host[3];
		if(link_href==link_location||link_sub_1==link_sub_2){
			$(".navi_header_menu li:eq("+i+") a").addClass("active_menu_header");
		}
	}
});