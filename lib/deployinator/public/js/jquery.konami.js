/*!
 * jQuery Konami code trigger v. 0.1
 *
 * Copyright (c) 2009 Joe Mastey
 * Dual licensed under the MIT and GPL licenses:
 *   http://www.opensource.org/licenses/mit-license.php
 *   http://www.gnu.org/licenses/gpl.html
 *
 * Usage:
 *  // konami code unlocks the tetris
 *  $('#tetris').konami(function(){
 *     $(this).show();
 *  });
 * 
 *
 *  // enable all weapons on 'idkfa'.
 *  // note that each weapon must be unlocked by its own code entry
 *  $('.weapon').konami(function(){
 *     $(this).addClass('enabled');
 *  }, {'code':[73, 68, 75, 70, 65]});
 *
 *
 *  // listens on any element that can trigger a keyup event.
 *  // unlocks all weapons at once
 *  $(document).konami(function(){
 *     $('.weapon').addClass('enabled');
 *  }, {'code':[73, 68, 75, 70, 65]});
 *
 *
 */
(function($){
    $.fn.konami             = function( fn, params ) {
        params              = $.extend( {}, $.fn.konami.params, params );
        this.each(function(){
            var tgt         = $(this);
            tgt.bind( 'konami', fn )
               .bind( 'keyup', function(event) { $.fn.konami.checkCode( event, params, tgt ); } );
        });
        return this;
    };
    
    $.fn.konami.params      = {
        'code'      : [38, 38, 40, 40, 37, 39, 37, 39, 66, 65],
        'step'      : 0
    };
    
    $.fn.konami.checkCode   = function( event, params, tgt ) {
        if(event.keyCode == params.code[params.step]) {
            params.step++;
        } else {
            params.step     = 0;
        }
        
        if(params.step == params.code.length) {
            tgt.trigger('konami');
            params.step     = 0;
        }
    };
})(jQuery);

