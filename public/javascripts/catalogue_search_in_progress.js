$(document).ready(function() {

  $('.search-throbber').hide();

  $('#catalogue-search-form form').submit(function (event){
    $('a.toggle-catalogue-form, a.refine-search').unbind('click').click(function(event){
      event.preventDefault();
    });
    $(this).find(':submit').hide();
    $('.search-throbber').fadeIn(300);
  });

});

