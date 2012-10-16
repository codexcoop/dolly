// version 0.0.4

(function( $ ){

// PLUGIN
$.fn.autocomplete_setup = function() {

  return this.each(function(){

    var $field, controller, action, cache, path, lastXhr;

    $field      = $(this);
    controller  = $field.data('autocompletion-controller');
    action      = $field.data('autocompletion-action') || 'list';
    cache       = {};

    if (action === 'index') {
      path = "/"+ controller +".json";
    } else {
      path = "/"+ controller +"/"+action+".json";
    }

    $field.autocomplete({
      minLength: 2,
      source: function( request, response ) {
        var term = request.term;
        if ( term in cache ) {
          response( cache[ term ] );
          return;
        }
        lastXhr = $.getJSON( path, request, function( data, status, xhr ) {
          cache[ term ] = data;
          if ( xhr === lastXhr ) {
            response( data );
          }
        });
      } // source: function( request, response ) {
    }); // $field.autocomplete({

  }); // return this.each(function(){

};

})( jQuery );

