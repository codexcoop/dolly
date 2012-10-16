/*jshint laxbreak:true, eqeqeq: true, plusplus:true, undef:true, sub:true*/
/*!
asi:true
jquery.lazydoll plugin

version: 0.0.7, 2011-06-25

License: Affero GPL

Author
 - Luca Belmondo
 - lucabelmondo@fastmail.fm

https://github.com/lucabelmondo/lazydoll
*/

(function( $ ){

  $.lazydoll = {};

  $.lazydoll.defaults = {
    container     : window,
    placeholder   : "/images/grey.gif",
    delay         : 400,
    fade_in       : true,
    fade_in_speed : 400,
    show_loading  : false,
    icon_url      : "/images/loading-icon.gif",
    icon_width    : 24,
    icon_height   : 24
  };

  var methods = {

    init : function( options ) {
      // store options with defaults in the $.lazydoll object
      $.lazydoll.options = $.extend({}, $.lazydoll.defaults, options);
      if ( $.lazydoll.options.show_loading ) { methods.setup_loading_icon(); }
      methods.setup_placeholders( this );
      methods.setup_container();
      methods.setup_show_visibles_on_scroll( this );
      methods.setup_appearance( this );
      // show the first images on load
      $.lazydoll.options.container.trigger('scroll');
      return this;
    }, // methods.init

    // ensure that the container is a jQuery object
    setup_container : function( ) {
      if ( !($.lazydoll.options.container instanceof jQuery) ) {
        $.lazydoll.options.container = $($.lazydoll.options.container);
      }
    },

    setup_placeholders : function( $set ) {
      $set.addClass('lazy-loadable')
          .not("[data-original-src]")
          .each(function(){ methods.setup_placeholder_for_img( $(this) ); });
    },

    setup_placeholder_for_img : function( $img ) {
      $img.data('original-src', $img.attr('src'))
          .attr('src', $.lazydoll.options.placeholder);
    },

    // considers only the first element in the wrapped set
    relative_offsets : function( $element ) {
      var top, right, bottom, left;
      $element = $element.first();

      if ( $element.get(0) === window ) {
        top     = 0;
        bottom  = $element.height();
        left    = 0;
        right   = $element.width();
      } else if ( $.lazydoll.options.container.get(0) === window )  {
        top     = $element.offset().top - $(window).scrollTop();
        bottom  = top + $element.height();
        left    = $element.offset().left - $(window).scrollLeft();
        right   = left + $element.width();
      } else {
        top     = $element.offset().top;
        bottom  = top + $element.height();
        left    = $element.offset().left;
        right   = left + $element.width();
      }

      return {top:top, right:right, bottom:bottom, left:left};
    },

    // finds the intersections between the offsets of the given $element and the container
    is_visible : function( $element ) {
      var element, container, top, bottom, left, right, vertically, horizontally;

      element   = methods.relative_offsets( $element );
      container = methods.relative_offsets( $.lazydoll.options.container );

      top     = Math.max.apply(Math, [container.top, element.top]);
      bottom  = Math.min.apply(Math, [container.bottom, element.bottom]);
      left    = Math.max.apply(Math, [container.left, element.left]);
      right   = Math.min.apply(Math, [container.right, element.right]);

      vertically    = top < bottom;
      horizontally  = left < right;

      return vertically && horizontally;
    },

    reset_timer : function( ) {
      var self;
      self = this;
      if(typeof self.timeout_id === "number") {
        window.clearTimeout(self.timeout_id);
        //delete self.timeout_id;
        self.timeout_id = null;
      }
    },

    setup_appearance : function( $set ) {
      $set.one('appear.lazydoll', function (event){
        if ( $.lazydoll.options.fade_in ) {
          var $img, $img_wrap, $tmp_img;
          // the target img still shows a placeholder
          $img = $(this);
          // build a minimal wrap to position the tmp animated image exactly on top of the target img
          $img_wrap =
            $("<span />").addClass("img-tmp-wrapper").css({
              borderWidth:0, padding:0, margin:0, display:'inline-block',
              width:$img.outerWidth(), height:$img.outerHeight(), position:'relative'
            });
          // set up the tmp animated image, as a clone of the original image
          $tmp_img =
            $img.clone().css( {opacity:0.0, position:'absolute', left:'0px'} )
            .attr( 'src', $img.data('original-src') )
            .bind( 'load', function(event){
              var $this;
              $this = $(this);
              $this.animate( {opacity:1.0}, $.lazydoll.options.fade_in_speed, function(){
                $img.attr( 'src', $img.data('original-src') ).removeClass('lazy-loadable').addClass('lazy-loaded').css({position:'static'});
                $img.delay(100).css({zIndex:9999}).delay(100, function(){
                  $this.remove();
                  $img.css({position:'static'}).unwrap();
                });
                $img.parents(".img-tmp-wrapper:first").find(".loading-icon").remove();
              });
            });
          // wrap the original image
          $img.wrap($img_wrap);
          // add the loading_icon if requested (after wrapping, otherwise the wrap has dimensions zero)
          if ( $.lazydoll.options.show_loading ) { methods.add_loading_icon_to( $img ); }
          // insert the tmp img in the dom => it is loaded and the animation is executed
          $tmp_img.appendTo($img.parents("span:first"));
        } else {
          $(this).attr( 'src', $(this).data('original-src') );
        }
      });
    },

    show_visibles_in_set : function( $set ) {
      $set.filter(".lazy-loadable").each ( function (index, element) {
        var $img;
        $img = $(element);
        if ( methods.is_visible($img) ) {
          $img.trigger('appear.lazydoll');
        }
      });
    },

    setup_show_visibles_on_scroll : function( $set ) {
      var self = this;
      // bind the actual scroll
      $.lazydoll.options.container.bind( 'scroll', function ( event ){
        methods.reset_timer();
        self.timeout_id = window.setTimeout(
          function( ) { methods.show_visibles_in_set( $set ); },
          $.lazydoll.options.delay
        );
      });
      // trigger scroll on window resize
      $(window).bind('resize', function(event){
        $.lazydoll.options.container.trigger('scroll');
      });
    },

    add_loading_icon_to : function( $img ) {
      var $wrap, $loading_icon, top, left;

      $img.css({position:'absolute'});

      $wrap         = $img.parents(".img-tmp-wrapper:first");
      $loading_icon = $.lazydoll.options.loading_icon.clone().show();
      top           = parseInt( ($wrap.height() - $.lazydoll.options.icon_height)/2, 10 );
      left          = parseInt( ($wrap.width() - $.lazydoll.options.icon_width)/2, 10 );

      $wrap.css({display:'inline-block', position:'relative'}).append($loading_icon);
      $loading_icon.css({ top:top, left:left });
    }, // /add_loading_icon_to

    setup_loading_icon : function( ) {
      var $loading_icon, $tmp_wrapper;

      $loading_icon = $("<img />").attr({src:$.lazydoll.options.icon_url})
                                  .addClass('loading-icon')
                                  .css({ position:'absolute' });

      $.lazydoll.options.loading_icon = $loading_icon;
      $.lazydoll.options.tmp_wrapper  = $tmp_wrapper;
    } // /setup_loading_icon

  }; // /methods

  $.fn.lazydoll = function( method ) {
    if ( methods[method] ) {
      return methods[method].apply( this, Array.prototype.slice.call( arguments, 1 ));
    } else if ( typeof method === 'object' || ! method ) {
      return methods.init.apply( this, arguments );
    } else {
      $.error( 'Method ' +  method + ' does not exist on jQuery.lazydoll' );
    }
  };

})( jQuery );

