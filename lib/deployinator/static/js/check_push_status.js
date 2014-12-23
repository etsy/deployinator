/*
 * This polls to get the header css class to use based on the current server time
 */
;$(function () {
  var update_header_class = function (data) {
    $("header").removeClass("push-open");
    $("header").removeClass("push-closed");
    $("header").removeClass("push-caution");
    $("header").addClass(data);
  };

  check_push_status = function () {
    jQuery.get("/header_class", update_header_class);
  }
  // do it right now
  check_push_status();
  // and do it every minute
  header_check = setInterval(check_push_status, 60000);
});
