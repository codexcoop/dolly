$(document).ready(function() {

  $("#sortable-images-list img").lazydoll();

/*
  $("#sortable-images-list").sortable(
    {
      cursor : 'move',
      opacity : 0.6,
      scroll : true,
      tolerance : 'pointer',
      handle : $("#sortable-images-list img"),
      update : function (event, ui) {
        var moved_digital_file_id       = parseInt( ui.item.attr("data-digital-file-id") )
        var serialized_list             = $(this).sortable('serialize', {key : "digital_file_id"} )
        var digital_file_ids            = serialized_list.split('&').map( function(dig_file_string){
                                            return parseInt(dig_file_string.match(/\d+/)[0])
                                          })
        var moved_digital_file_position = digital_file_ids.indexOf(moved_digital_file_id) + 1
        var sortable_container = this
        $.post(
          "digital_files/"+ moved_digital_file_id +"/move",

          {
            _method : "PUT",
            id : moved_digital_file_id,
            position : moved_digital_file_position
          },

          function(json_response){
            var moved_element         = $("[data-digital-file-id="+ moved_digital_file_id +"]")
            var original_border_color = moved_element.css("border-top-color")
            var success_border_color  = "#32c100"
            var failure_border_color  = "#d00100"
            var flash_time            =  150
            var fadeout_time          = 1200
            var delay_time            =  100
            if (json_response.status) {
              moved_element
              .animate( { borderBottomColor : success_border_color,
                          borderLeftColor   : success_border_color,
                          borderRightColor  : success_border_color,
                          borderTopColor    : success_border_color }, flash_time )
              .delay(delay_time)
              .animate( { borderBottomColor : original_border_color,
                          borderLeftColor   : original_border_color,
                          borderRightColor  : original_border_color,
                          borderTopColor    : original_border_color }, fadeout_time )
            }else{
              $(sortable_container).sortable("cancel") // rollback to order before present action
              moved_element
              .animate( { borderBottomColor : failure_border_color,
                          borderLeftColor   : failure_border_color,
                          borderRightColor  : failure_border_color,
                          borderTopColor    : failure_border_color }, flash_time )
              .delay(delay_time)
              .animate( { borderBottomColor : original_border_color,
                          borderLeftColor   : original_border_color,
                          borderRightColor  : original_border_color,
                          borderTopColor    : original_border_color }, fadeout_time )
            }
          }
        )
      }
    }
  )

  $("#sortable-images-list").disableSelection()
*/

})

