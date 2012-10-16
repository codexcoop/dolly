// updated: 2011-06, 0.0.4
// TODO: remove functions related to "setup_add_result", because already implemented in relations.js

(function($){

  $.fn.adapt_to_html = function(content){
    return this.each(function(){
      var original_height = $(this).height();
      var $container = $(this);
      var $content = $(content);
      // prepare
      $container.css({position:'relative', overflow:'hidden', height:original_height });
      $content.css({opacity:0, position:'absolute'});
      // add
      $container.html($content);
      // animate
      $container.animate(
        {height: $content.height() + 'px'},
        'fast',
        function(){
          // new height should adapt to changes in content height
          $container.css({height:'auto', overflow:'auto'});
          $content.css({position:'relative', overflow:'auto'}).animate({opacity:1.0}, 'fast');
        }
      );
    });
  };

  $.live_search = {
    defaults : {
      url                 : location.pathname+"/live_search",
      param               : 'term', // TODO: implement dynamic param name
      nested_fields       : '#related-original-objects-fields',
      already_present     : '#already-present',
      wrapper             : '.live-search-wrap',
      results             : '.results-list',
      animate_results     : false,
      hide_details        : false,
      current             : '[data-current-id]:first',
      delay               :  380,
      more                : 'a',
      add_result          : 'a.add-result',
      details             : '.details',
      min_length          : 2
    },

    settings : { },

    elements : { },

    select_elements : function($field){
      var self = this;
      self.elements.container       = $field.parents( self.settings.wrapper+":first" );
      self.elements.already_present = self.elements.container.find( self.settings.already_present );
      self.elements.results         = self.elements.container.find( self.settings.results );
      self.elements.current         = self.elements.container.find( self.settings.current );
    },

    reset_timer : function() {
      if(typeof this.timeoutID === "number") {
        window.clearTimeout(this.timeoutID);
        //delete this.timeoutID;
        this.timeoutID = null;
      }
    },

    setup_more : function() {
      var self = this;
      var $more = self.elements.results.find(self.settings.more);
      $more.live('click', function(event){
        var $details;
        var result_id = $(this).attr('data-result-id');
        // find details
        $details = self.elements.results.find(self.settings.details +'[data-result-id='+ result_id +']');
        // animate them
        $details.animate({ opacity : 'toggle', height : 'toggle' }, 'fast');
        event.preventDefault();
      });
    },

    //setup_add_result : function() {
    //  var self              = this;
    //  var $add_result       = self.elements.results.find(self.settings.add_result);
    //  $add_result.live('click', function(event){
    //    var result_id = $(this).attr('data-result-id');
    //    // TODO: finish this
    //    event.preventDefault();
    //  })
    //},

    build_params : function($field){
      var self, params;
      self = this;
      if ( self.elements.current.length > 0 ) {
        params = {'id' : self.elements.current.attr('data-current-id'), 'term' : $field.val() };
      } else {
        params = {'term' : $field.val() };
      }
      $.extend(params, ($field.data('common-search-params') || {}));
      return params;
    },

    update_results_with : function($field, html_response){
      var self = this;
      var $html = $(html_response);
      var $container = $field.parents(self.settings.wrapper+":first");
      var $results = $container.find(self.settings.results);
      // hide details in results
      if (self.settings.hide_details) { $html.find(self.settings.details).hide(); }
      // insert animating
      $field.trigger("results-loading.livesearch", [$html]);
      if(self.settings.animate_results){
        $results.adapt_to_html($html);
      } else {
        $results.html($html);
      }
    },

    search_and_load : function($field) {
      var self = this;
      var $container = $field.parents(self.settings.wrapper+":first");
      var $results = $container.find(self.settings.results+":first");

      if($field.val().length === 0) {
        // TODO: loading visual element
      } else if ($field.val().length >= self.settings.min_length){
        // CustomAnimations.add_and_adapt_height($results, $('<p><em>ricerca in corso...</em></p>'))
        if ($results.data('previous_value') !== $field.val() ) {
          // do ajax request, and process response
          $.ajax({
            url: self.settings.url,
            data: self.build_params($field),
            success: function ( html_response ){
              self.update_results_with($field, html_response);
            },
            dataType: 'html'
          });
          // cache query string
          $results.data('previous_value', $field.val());
        }
      }
      delete this.timeoutID;
    },

    countdown_and_launch : function($field) {
      var self = this;
      self.reset_timer();
      self.timeoutID = window.setTimeout(
        function() { self.search_and_load($field); },
        self.settings.delay
      );
      // IE7 doesn't support additional params in window.setTimeout
      // self.timeoutID = window.setTimeout(
      //   function($field){self.search_and_load($field)},
      //   self.settings.delay,
      //   $field
      // )
    },

    setup : function($field) {
      var self = this;
      // $('original-object-search').css({position:'relative', overflow:'hidden'})
      $field.keyup(function(event){
        self.countdown_and_launch($field);
      });

      $(".hide-livesearch-results-cmd").live('click', function(event){
        var $command, $container, $results;
        event.preventDefault();
        $command    = $(this);
        $container  = $command.parents(".relation-selection:first");
        $results    = $container.find(".live-search-wrap .results-list");
        $results.data('previous_value', null);
        $results.animate({opacity:0.0, height:0}, 'fast', function(){
          $(this).empty().css({opacity:1.0});
        });
      });
    }

  };

  $.fn.live_search = function(options){
    $.extend($.live_search.settings, $.live_search.defaults, options||{});

    return this.each(function() {
      var $field = $(this);
      $.live_search.setup($field);
      $.live_search.select_elements($field);
      $.live_search.setup_more();
    });
  };

})(jQuery);

