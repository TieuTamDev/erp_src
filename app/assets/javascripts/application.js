// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery-3.1.0.min
//= require bootstrap-sprockets
//= require moment
//= require bootstrap-datetimepicker
//= require daterangepicker
//= require turbolinks
//= require data-confirm-modal
//= require chartkick
//= require Chart.bundle
//= require dashboard
//= require jstree.min
//= require jquery.contextMenu
//= require_tree .
//= require jquery
//= require jquery_ujs

var ERROR_FORM_CLIENT                   = "error_form_client";
var WARNING_EMAIL_EMPTY                 = lib_translate("Email can't be blank");
var WARNING_EMAIL_INVALID               = lib_translate("Invalid email address");
var WARNING_PHONE_EMPTY                 = lib_translate("Phone number can't be blank");
var WARNING_URL_EMPTY                   = lib_translate("URL Website can't be blank");
var WARNING_URL_INVALID                 = lib_translate("Invalid URL Website");
var WARNING_PAYMENT_CARD_INVALID        = lib_translate("Invalid Credit/Debit Card number");
var WARNING_ADDRESS_STREET_EMPTY        = lib_translate("Street can't be blank");
var WARNING_ADDRESS_COUNTRY_EMPTY       = lib_translate("Country can't be blank");
var WARNING_ADDRESS_CITY_EMPTY          = lib_translate("City can't be blank");
var WARNING_ADDRESS_STATE_EMPTY         = lib_translate("State/Province or Region can't be blank");
var WARNING_ADDRESS_POSTCODE_EMPTY      = lib_translate("Portal Code can't be blank");
var WARNING_SUBDOMAIN_EMPTY             = lib_translate("Sub-domain of your site can't be blank");
var WARNING_JOB_TITLE_EMPTY             = lib_translate("Job Title can't be blank");
var WARNING_PATH_INVALID                = lib_translate("Invalid path url");

$(document).ajaxError(function(event,xhr,options,exc) {
    var errors = JSON.parse(xhr.responseText);
    var er ="<ul>";
    var err_divid = errors[0]
    for(var i = 1; i < errors.length; i++){
        var list = errors[i];
        er += "<li>"+list+"</li>"
    }
    er+="</ul>"
    $("#"+err_divid).html(er);
});

dataConfirmModal.setDefaults({
    title: lib_translate("Confirmation"),
    commit: lib_translate("Yes"),
    cancel: lib_translate("No")
});

function lib_translate(value)
{
    if(typeof I18n[value] != 'undefined')
        return I18n[value];
    else
        return value;
}
function lib_translate_var(string, variable)
{
    if(typeof I18n[string] != 'undefined')
    {
        translate = I18n[string];
        $.each(variable, function( key, value ) {
            key = "%{"+key+"}";
            result = translate.replace(key, value);
        });
    }else{
        $.each(variable, function( key, value ) {
            result = string.replace(key, value);
        });
    }
    return result;
}