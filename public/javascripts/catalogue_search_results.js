$(document).ready(function() {

  var Unimarc = {
    toggle_detailed_unimarc : function(){
    }
  };

  if ($('#no-results-message').length === 0 && $('#unimarc-text-form').length === 0 ) {
    $('#catalogue-search-form').hide();
  }
  
  $('a.refine-search').click( function(event) {
    if($('#no-results-message').length === 0) {
      $('#catalogue-search-form').animate({height:'toggle', opacity:'toggle' }, 'fast');
    }
    event.preventDefault();
  });

  $('a[data-result-index]').click(
    function (event) {
      var result_index = $(this).attr('data-result-index');
      var no_record_details_present = $('.record-details[data-result-index='+ result_index +']').length === 0

      $('.record-details').fadeTo('fast','0').slideUp('normal', function(){
        $(this).remove();
      });

      if (no_record_details_present) {
        var record_content = $('input:hidden[data-result-index='+ result_index +']').attr('value');
        var record_details =  $("<p />", { 'class' : 'record-details', 'data-result-index' : result_index });

        record_details.html(record_content).css({opacity : '0'}).hide();
        $('.catalogue-records li[data-result-index='+ result_index +'] form').before(record_details);

        record_details.slideDown().fadeTo('fast', '1');
      }
      event.preventDefault();
    }
  );

});

