/**
 * Created by LB-Trong on 5/8/2016.
 */
$(document).ready(function() {

	$(function(){
	  $("table").colResizable();
	});

    $('.navi_header_menu').addClass('hidemenu');
    $('.closeme').hide();
    $('.closeme').addClass('hidemenu');


    $('.clickme').click(function(){
        $('.navi_header_menu').show("fast");
        $('.navi_header_menu').removeClass('hidemenu');

        $('.clickme').hide();
        $('.closeme').show();
        $('.formatmenutitle').addClass('back_position');
        $('.closeme').removeClass('hidemenu');



    });
    $('.closeme').click(function(){
        $('.formatmenutitle').removeClass('back_position');
        $('.navi_header_menu').addClass('hidemenu');
        $('.clickme').show();
        $('.closeme').addClass('hidemenu');
        $('.closeme').hide();
        $('.navi_header_menu').hide();


    });


    //Header top menu

    $('.navi_header_top_menu').addClass('hidemenu');
    $('.closeme_top').hide();
    $('.closeme_top').addClass('hidemenu');


    $('.clickme_top').click(function(){
        $('.navi_header_top_menu').show("fast");
        $('.navi_header_top_menu').removeClass('hidemenu');

        $('.clickme_top').hide();
        $('.closeme_top').show();
        $('.formatmenutitle_top').addClass('back_position');
        $('.closeme_top').removeClass('hidemenu');



    });
    $('.closeme_top').click(function(){
        $('.formatmenutitle_top').removeClass('back_position');
        $('.navi_header_top_menu').addClass('hidemenu');
        $('.clickme_top').show();
        $('.closeme_top').addClass('hidemenu');
        $('.closeme_top').hide();
        $('.navi_header_top_menu').hide();



    });




});