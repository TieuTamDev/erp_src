$('#search_user').bind('keypress keydown keyup', function (e) {
  if (e.keyCode == 13) { e.preventDefault(); }
});
$('#search_holiday').bind('keypress keydown keyup', function (e) {
  if (e.keyCode == 13) { e.preventDefault(); }
});
$('#search_contract').bind('keypress keydown keyup', function (e) {
  if (e.keyCode == 13) { e.preventDefault(); }
});
$('#search_review').bind('keypress keydown keyup', function (e) {
  if (e.keyCode == 13) { e.preventDefault(); }
});
$('#search_work').bind('keypress keydown keyup', function (e) {
  if (e.keyCode == 13) { e.preventDefault(); }
});
$('#search_task').bind('keypress keydown keyup', function (e) {
  if (e.keyCode == 13) { e.preventDefault(); }
});
$('#search_address').bind('keypress keydown keyup', function (e) {
  if (e.keyCode == 13) { e.preventDefault(); }
});
$('#search_archive').bind('keypress keydown keyup', function (e) {
  if (e.keyCode == 13) { e.preventDefault(); }
});
$('#search_identity').bind('keypress keydown keyup', function (e) {
  if (e.keyCode == 13) { e.preventDefault(); }
});

function openResetPassForm() {
  $("#popup-change-pw").modal('show');
}

var current_tab = localStorage.getItem("currentTab");

function setCurrentTab(tab, hightlight) {
  $("html, body").animate({ scrollTop: 0 }, 10);
  localStorage.setItem("currentTab", tab);
  let id_tag_a = document.getElementById(hightlight);
  document.getElementById("tab_user").classList.remove('activetab');
  document.getElementById("tab_work").classList.remove('activetab');
  document.getElementById("tab_work_info").classList.remove('activetab');
  document.getElementById("tab_inden").classList.remove('activetab');
  document.getElementById("tab_benefit").classList.remove('activetab');
  document.getElementById("tab_archive").classList.remove('activetab');
  document.getElementById("tab_review").classList.remove('activetab');
  document.getElementById("tab_contract").classList.remove('activetab');
  document.getElementById("tab_holidays").classList.remove('activetab');
  document.getElementById("tab_address").classList.remove('activetab');
  document.getElementById("tab_reset_pwd").classList.remove('activetab');
  document.getElementById("tab_signature").classList.remove('activetab');
  if (id_tag_a) {
    document.getElementById(hightlight).classList.add('activetab');
  }
}

document.addEventListener('readystatechange', event => {
  if (event.target.readyState === "interactive") {
    if (`${save_tab_details}` == "identity" || current_tab == "Identity") {
      var identity = document.getElementById("tab9");
      if (identity) {
        identity.checked = "checked"
        document.getElementById("tab_user").classList.remove('activetab');
        document.getElementById("tab_work").classList.remove('activetab');
        document.getElementById("tab_work_info").classList.remove('activetab');
        document.getElementById("tab_inden").classList.add('activetab');
        document.getElementById("tab_benefit").classList.remove('activetab');
        document.getElementById("tab_archive").classList.remove('activetab');
        document.getElementById("tab_review").classList.remove('activetab');
        document.getElementById("tab_contract").classList.remove('activetab');
        document.getElementById("tab_holidays").classList.remove('activetab');
        document.getElementById("tab_address").classList.remove('activetab');
        document.getElementById("tab_reset_pwd").classList.remove('activetab');
        document.getElementById("tab_signature").classList.remove('activetab');
      }
    } else if (current_tab == "Password") {
      var resetPwd = document.getElementById("tab11");
      if (resetPwd) {
        resetPwd.checked = "checked"
        document.getElementById("tab_user").classList.remove('activetab');
        document.getElementById("tab_work").classList.remove('activetab');
        document.getElementById("tab_work_info").classList.remove('activetab');
        document.getElementById("tab_inden").classList.remove('activetab');
        document.getElementById("tab_benefit").classList.remove('activetab');
        document.getElementById("tab_archive").classList.remove('activetab');
        document.getElementById("tab_review").classList.remove('activetab');
        document.getElementById("tab_contract").classList.remove('activetab');
        document.getElementById("tab_holidays").classList.remove('activetab');
        document.getElementById("tab_address").classList.remove('activetab');
        document.getElementById("tab_reset_pwd").classList.add('activetab');
        document.getElementById("tab_signature").classList.add('activetab');
      }
    } else if (`${save_tab_details}` == "benefit" || current_tab == "Benefit") {
      var benefit = document.getElementById("tab10");
      if (benefit) {
        benefit.checked = "checked"
        document.getElementById("tab_user").classList.remove('activetab');
        document.getElementById("tab_work").classList.remove('activetab');
        document.getElementById("tab_work_info").classList.remove('activetab');
        document.getElementById("tab_inden").classList.remove('activetab');
        document.getElementById("tab_benefit").classList.add('activetab');
        document.getElementById("tab_archive").classList.remove('activetab');
        document.getElementById("tab_review").classList.remove('activetab');
        document.getElementById("tab_contract").classList.remove('activetab');
        document.getElementById("tab_holidays").classList.remove('activetab');
        document.getElementById("tab_address").classList.remove('activetab');
        document.getElementById("tab_reset_pwd").classList.remove('activetab');
        document.getElementById("tab_signature").classList.remove('activetab');
      }
    } else if (`${save_tab_details}` == "archive" || current_tab == "Archive") {
      var archive = document.getElementById("tab8");
      if (archive) {
        archive.checked = "checked"
        document.getElementById("tab_user").classList.remove('activetab');
        document.getElementById("tab_work").classList.remove('activetab');
        document.getElementById("tab_work_info").classList.remove('activetab');
        document.getElementById("tab_inden").classList.remove('activetab');
        document.getElementById("tab_benefit").classList.remove('activetab');
        document.getElementById("tab_archive").classList.add('activetab');
        document.getElementById("tab_review").classList.remove('activetab');
        document.getElementById("tab_contract").classList.remove('activetab');
        document.getElementById("tab_holidays").classList.remove('activetab');
        document.getElementById("tab_address").classList.remove('activetab');
        document.getElementById("tab_reset_pwd").classList.remove('activetab');
        document.getElementById("tab_signature").classList.remove('activetab');
      }
    } else if (current_tab == "Work_infomations") {
      var Work_infomations = document.getElementById("tab6");
      if (Work_infomations) {
        Work_infomations.checked = "checked"
        document.getElementById("tab_user").classList.remove('activetab');
        document.getElementById("tab_work").classList.remove('activetab');
        document.getElementById("tab_work_info").classList.add('activetab');
        document.getElementById("tab_inden").classList.remove('activetab');
        document.getElementById("tab_benefit").classList.remove('activetab');
        document.getElementById("tab_archive").classList.remove('activetab');
        document.getElementById("tab_review").classList.remove('activetab');
        document.getElementById("tab_contract").classList.remove('activetab');
        document.getElementById("tab_holidays").classList.remove('activetab');
        document.getElementById("tab_address").classList.remove('activetab');
        document.getElementById("tab_reset_pwd").classList.remove('activetab');
        document.getElementById("tab_signature").classList.remove('activetab');
      }
    } else if (`${save_tab_details}` == "address" || current_tab == "Address") {
      var work = document.getElementById("tab7");
      if (work) {
        work.checked = "checked"
        document.getElementById("tab_user").classList.remove('activetab');
        document.getElementById("tab_work").classList.remove('activetab');
        document.getElementById("tab_work_info").classList.remove('activetab');
        document.getElementById("tab_inden").classList.remove('activetab');
        document.getElementById("tab_benefit").classList.remove('activetab');
        document.getElementById("tab_archive").classList.remove('activetab');
        document.getElementById("tab_review").classList.remove('activetab');
        document.getElementById("tab_contract").classList.remove('activetab');
        document.getElementById("tab_holidays").classList.remove('activetab');
        document.getElementById("tab_address").classList.add('activetab');
        document.getElementById("tab_reset_pwd").classList.remove('activetab');
        document.getElementById("tab_signature").classList.remove('activetab');
      }
    } else if (`${save_tab_details}` == "work" || current_tab == "Work") {
      var work = document.getElementById("tab5");
      if (work) {
        work.checked = "checked"
        document.getElementById("tab_user").classList.remove('activetab');
        document.getElementById("tab_work").classList.add('activetab');
        document.getElementById("tab_work_info").classList.remove('activetab');
        document.getElementById("tab_inden").classList.remove('activetab');
        document.getElementById("tab_benefit").classList.remove('activetab');
        document.getElementById("tab_archive").classList.remove('activetab');
        document.getElementById("tab_review").classList.remove('activetab');
        document.getElementById("tab_contract").classList.remove('activetab');
        document.getElementById("tab_holidays").classList.remove('activetab');
        document.getElementById("tab_address").classList.remove('activetab');
        document.getElementById("tab_reset_pwd").classList.remove('activetab');
        document.getElementById("tab_signature").classList.remove('activetab');
      }
    } else if (`${save_tab_details}` == "review" || current_tab == "Review") {
      var review = document.getElementById("tab4");
      if (review) {
        review.checked = "checked"
        document.getElementById("tab_user").classList.remove('activetab');
        document.getElementById("tab_work").classList.remove('activetab');
        document.getElementById("tab_work_info").classList.remove('activetab');
        document.getElementById("tab_inden").classList.remove('activetab');
        document.getElementById("tab_benefit").classList.remove('activetab');
        document.getElementById("tab_archive").classList.remove('activetab');
        document.getElementById("tab_review").classList.add('activetab');
        document.getElementById("tab_contract").classList.remove('activetab');
        document.getElementById("tab_holidays").classList.remove('activetab');
        document.getElementById("tab_address").classList.remove('activetab');
        document.getElementById("tab_reset_pwd").classList.remove('activetab');
        document.getElementById("tab_signature").classList.remove('activetab');
      }
    } else if (`${save_tab_details}` == "contract" || current_tab == "Contract") {
      var contract = document.getElementById("tab3");
      if (contract) {
        contract.checked = "checked"
        document.getElementById("tab_user").classList.remove('activetab');
        document.getElementById("tab_work").classList.remove('activetab');
        document.getElementById("tab_work_info").classList.remove('activetab');
        document.getElementById("tab_inden").classList.remove('activetab');
        document.getElementById("tab_benefit").classList.remove('activetab');
        document.getElementById("tab_archive").classList.remove('activetab');
        document.getElementById("tab_review").classList.remove('activetab');
        document.getElementById("tab_contract").classList.add('activetab');
        document.getElementById("tab_holidays").classList.remove('activetab');
        document.getElementById("tab_address").classList.remove('activetab');
        document.getElementById("tab_reset_pwd").classList.remove('activetab');
        document.getElementById("tab_signature").classList.remove('activetab');
      }
    } else if (`${save_tab_details}` == "holiday" || current_tab == "Holidays") {
      var holiday = document.getElementById("tab2");
      if (holiday) {
        holiday.checked = "checked"
        document.getElementById("tab_user").classList.remove('activetab');
        document.getElementById("tab_work").classList.remove('activetab');
        document.getElementById("tab_work_info").classList.remove('activetab');
        document.getElementById("tab_inden").classList.remove('activetab');
        document.getElementById("tab_benefit").classList.remove('activetab');
        document.getElementById("tab_archive").classList.remove('activetab');
        document.getElementById("tab_review").classList.remove('activetab');
        document.getElementById("tab_contract").classList.remove('activetab');
        document.getElementById("tab_holidays").classList.add('activetab');
        document.getElementById("tab_address").classList.remove('activetab');
        document.getElementById("tab_reset_pwd").classList.remove('activetab');
        document.getElementById("tab_signature").classList.remove('activetab');
      }
    } else if (`${save_tab_details}` == "signature" || current_tab == "Signature") {
      var signature = document.getElementById("tab12");
      if (signature) {
        signature.checked = "checked"
        document.getElementById("tab_user").classList.remove('activetab');
        document.getElementById("tab_work").classList.remove('activetab');
        document.getElementById("tab_work_info").classList.remove('activetab');
        document.getElementById("tab_inden").classList.remove('activetab');
        document.getElementById("tab_benefit").classList.remove('activetab');
        document.getElementById("tab_archive").classList.remove('activetab');
        document.getElementById("tab_review").classList.remove('activetab');
        document.getElementById("tab_contract").classList.remove('activetab');
        document.getElementById("tab_holidays").classList.remove('activetab');
        document.getElementById("tab_address").classList.remove('activetab');
        document.getElementById("tab_reset_pwd").classList.remove('activetab');
        document.getElementById("tab_signature").classList.add('activetab');
      }
    } else {
      var user = document.getElementById("tab1");
      localStorage.removeItem('currentTab');
      if (user) {
        user.checked = "checked"
        document.getElementById("tab_user").classList.add('activetab');
        document.getElementById("tab_work").classList.remove('activetab');
        document.getElementById("tab_work_info").classList.remove('activetab');
        document.getElementById("tab_inden").classList.remove('activetab');
        document.getElementById("tab_benefit").classList.remove('activetab');
        document.getElementById("tab_archive").classList.remove('activetab');
        document.getElementById("tab_review").classList.remove('activetab');
        document.getElementById("tab_contract").classList.remove('activetab');
        document.getElementById("tab_holidays").classList.remove('activetab');
        document.getElementById("tab_address").classList.remove('activetab');
        document.getElementById("tab_reset_pwd").classList.remove('activetab');
        document.getElementById("tab_signature").classList.remove('activetab');
      }
    }
  }

  if (event.target.readyState === "complete") {
    save_tab_details = "";
  }
});

function clearCurrentTab() {
  localStorage.removeItem('currentTab');
}


const leftMenu = document.querySelector("#user-profile-menu-left");
var left_menu_user_profile = document.getElementById("user-profile-menu-left");
function hide_menu_left_profile_user() {

  const tab_class = leftMenu.getAttribute("class");

  let width = window.innerWidth;
  if (width <= 767.5) {
    if (tab_class.includes("show_menu_bar")) {
      left_menu_user_profile.classList.add("hide_menu_bar");
      document.getElementById("set_background").classList.add("background-none-user-menu");
      left_menu_user_profile.classList.remove("show_menu_bar");
    } else {
      left_menu_user_profile.classList.remove("hide_menu_bar");
      left_menu_user_profile.classList.add("show_menu_bar");
      document.getElementById("set_background").classList.remove("background-none-user-menu");
    }
  } else {
    return false;
  }

}
