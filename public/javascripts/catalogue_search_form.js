$(document).ready(function() {

  $('#unimarc-text-form').hide().css({opacity : '0'});
  $('a.toggle-catalogue-form.second').hide();

  $('a.toggle-catalogue-form').click(
    function (event) {
      if ($('#catalogue-search-form').is(':visible')) {
        $('#unimarc-text-form').slideDown().fadeTo('fast', '1');
        $('#catalogue-search-form').fadeTo('fast','0').slideUp('normal');
        $('a.toggle-catalogue-form.first').toggle();
        $('a.toggle-catalogue-form.second').toggle();
      } else {
        $('#catalogue-search-form').slideDown().fadeTo('fast', '1');
        $('#unimarc-text-form').fadeTo('fast','0').slideUp('normal');
        $('a.toggle-catalogue-form.second').toggle();
        $('a.toggle-catalogue-form.first').toggle();
      }
      event.preventDefault();
    }
  );

});

