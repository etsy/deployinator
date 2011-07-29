/*!
 * jQuery timed progress bar v.0.1
 *
 * Copyright (c) 2009 Erik Kastner
 *
 * Usage:
 *  // show a progress bar for 30 seconds
 *  $('#bar_dif').timed_bar(30);
 *
 */
;(function($) {
  $.fn.timed_bar = function(total_time) {
    return this.each(function() {
      var $this = $(this);
      var started = new Date();

      var div = $('<div>').addClass('bar').css({"height": "100%", "width": "0%" });
      var span = $('<span>').addClass('deploying').text('Deploying');
      $this.append(span, div);

      interval = setInterval(function() {
        diff = ((new Date()) - started) / 1000;
        if (diff >= total_time) {
          div.css("width", "100%");
          clearInterval(interval);
        }
        else {
          percent = diff / total_time * 100;
          if (percent >= 99) { percent = 99; }
          div.css("width", percent + "%");
        }
      }, 350);
    });
  };
})(jQuery);

