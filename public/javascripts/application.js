$(document).ready(function() {

  // live_search
  $("#original-objects-ajax-search").live_search({
    url             : "/original_objects/ajax_search",
    results         : '#original-object-search-results'
  });

  // tipTip
  $(".tooltip").tipTip({
      activation: "click",
      keepAlive: true,
      maxWidth: "400px",
      defaultPosition: "top",
      delay: 200,
      exit: function() {
              active_tiptip();
              return false;
            }
  });

  $("*").click(function() {
    $("#tiptip_holder").hide();
  });

  // jQuery UI icon => edit
  $(".edit-link").button({
      icons: { primary: 'ui-icon-pencil' },
      text: false
  });

  $(".completed-marker").button({
    icons: { primary:'ui-icon-check' },
    text: false
  });

  $(".digital-files-available").button({
    icons: { primary: 'ui-icon-image' },
    text: false
  });

  // STRIKE LABELS FOR REMOVED TERMS
  // hide the destroy checkbox (visual hint seems enough)
//  $(".already-assigned-terms input:checkbox[name$='[_destroy]']").hide()
//  var $_destroy_checkboxes = $("input:checkbox[name$='[_destroy]']")

//  var strike_labels = function (checkbox) {
//    if (checkbox instanceof jQuery) { var $_checkbox = checkbox }
//    else { var $_checkbox = $(checkbox) }

//    var $_associated_text_labels =  $("label[for="+$_checkbox.attr('id')+"]")
//                                    .filter(function(){
//                                      return $(this).text()
//                                    })
//    if ($_checkbox.is(':checked')) {
//      $_associated_text_labels.css({textDecoration:'line-through'})
//    } else {
//      $_associated_text_labels.css({textDecoration:'none'})
//    }
//  }

//  $_destroy_checkboxes.each(function(){strike_labels(this)})

//  $_destroy_checkboxes.change(function(){strike_labels(this)})
  // END OF STRIKE LABELS FOR REMOVED TERMS

  // ENTITY-TERMS MANAGEMENT FUNCTIONS
  var EntityTerm = {

    show_form_element : function(options){
      var form_element_class = options.form_element_class;
      var property_id = options.property_id;
      var form_element_selector = options.form_element_selector;

      $('div.terms-addition p.new-value[data-property-id='+ property_id +']')
      .css({opacity : '0'})
      .delay(50)
      .slideDown(150, function() {
        $(this).fadeTo(150, '1.0');
      });
    },

    clone_form_element : function (options) {
      var form_element_class = options.form_element_class;
      var property_id = options.property_id;
      var new_index = new Date().getTime();
      var terms_list_selector = 'p.'+ form_element_class +'[data-property-id='+ property_id +']';
      var new_form_field_item = $(terms_list_selector + ':first').clone();
      new_form_field_item
      .children()
      .remove('.only-for-page-loading')
      .attr('id', function(){ if ($(this).attr('id')) { return $(this).attr('id').replace(/\d+/, new_index); } } )
      .attr('name', function(){ if ($(this).attr('name')) { return $(this).attr('name').replace(/\d+/, new_index); } } )
      .attr('for', function(){ if ($(this).attr('for')) { return $(this).attr('for').replace(/\d+/, new_index); } } );

      if (new_form_field_item.hasClass('new-term')) {
        new_form_field_item.find('input:text').attr('value','');
      }

      var element_to_append = $(new_form_field_item)
                              .append($("<a href=\"#nogo\" class=\"remove-value\">- rimuovi</a>"));

      $(terms_list_selector +':last')
      .after( element_to_append.hide() );

      // container_element
      $(terms_list_selector +':last')
      .css({opacity : '0'})
      .delay(200)
      .slideDown(150, function() {
        $(this).fadeTo(100, 1.0);
      });

    }
  };

  // ENTITY-TERMS MANAGEMENT SETUP
  $('a.select-value').live('click', function(e) {
    var property_id = $(this).attr('data-property-id');
    EntityTerm.clone_form_element({
        form_element_class  : 'terms-list',
        property_id         : property_id
    });
    return false;
  });

  $('div.terms-addition p.new-value').hide();

  $('a.add-value').live('click', function(event) {
    var property_id = $(this).attr('data-property-id');
    EntityTerm.clone_form_element({
        form_element_class  : 'new-value',
        property_id         : property_id
    });
    event.preventDefault();
  });

  $('a.remove-value').live('click', function(e) {
    $(this).parent().fadeTo(100, '0', function() {
      $(this).slideUp(150,function(){
        $(this).delay(100).remove();
      });
    });
    return false;
  });

  $("a.new-term").live("click", function(){
    var property_id = $(this).attr('data-property-id');
    var new_index = new Date().getTime();
    var new_form_field_item = $('.terms-list[data-property-id='+ property_id +']:first')
                              .clone();
  });

  // FORCE TO EXPLICITLY REQUIRE THE ACTIVATION OF A FIELD

  // step 0: create and set value in hidden helper field
  var create_and_set_hidden_field = function (field) {
    if (field instanceof jQuery) { var $field = field; } else { var $field = $(field); }
    var $hidden_field = $field.prevAll("input:hidden[name="+ $field.attr("name") +"]:first");
    if ($hidden_field.length === 0) {
      $hidden_field = $("<input />").attr({type:"hidden", name:$field.attr("name")}).insertBefore($field);
    }
    $hidden_field.val($field.attr("value"));
  };

  // step 1: disable non empty fields, hide the activating command otherwise
  $("input:text.activable, textarea.activable, select.activable").each( function(index) {
    var $field = $(this);
      $field.attr({disabled:"disabled"});
      create_and_set_hidden_field($field);
  });

  // step 2: manage activation of the activable field
  $("a.activate-field").click( function(event){
    var $command = $(this);
    var $field = $command.parent().find("input:text.activable:first, textarea.activable:first, select.activable:last");
    $field.removeAttr("disabled").focus();
    $command.fadeOut("fast");
    event.preventDefault();
  });

  // step 3: store the value in an hidden field, and lock the activable field again
  // the hidden field is required, because disabled fields don't send any value to the server
  // (by HTML design itself)
  $("input:text.activable, textarea.activable, select.activable").blur( function(){
    var $field = $(this);
      $field.parent().find("a.activate-field").fadeIn();
      $field.attr({disabled:"disabled"});
      create_and_set_hidden_field($field);
    //}
  });
  // END OF "FORCE TO EXPLICITLY REQUIRE THE ACTIVATION OF A FIELD"

});

