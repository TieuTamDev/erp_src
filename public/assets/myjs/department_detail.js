
document.addEventListener('readystatechange', event => {
    if (event.target.readyState === "interactive") {
        var user = document.getElementById("tab1");
        if (user) {
          user.checked = "checked"
        }
    }

    if (event.target.readyState === "complete") {

    }
  });







  