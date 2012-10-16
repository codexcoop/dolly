// # TODO: use this general implementation also for images' sorting

$(document).ready(function() {

  var AjaxSort = {

    custom_setup : function(opts){
      var cursor                  = opts.cursor // : 'move',
      var opacity                 = opts.opacity // : 0.6,
      var scroll                  = opts.scroll // : true,
      var tolerance               = opts.tolerance // : 'pointer',
      var handle                  = opts.handle // : $("#sortable-images-list img"),
      var container               = opts.container // "#sortable-images-list"
      var handle                  = opts.handle // "img"
      var dom_id_attr             = opts.dom_id_attr // data-digital-file-id
      var server_side_attribute   = opts.server_side_attribute // digital_file_id
      var controller              = opts.controller // digital_files
      var action                  = opts.action
      $(container).disableSelection()
      $(container).sortable(
        {
          cursor    : cursor,
          opacity   : opacity,
          scroll    : scroll,
          tolerance : tolerance,
          handle    : $(handle),
          update    : function (event, ui) {
            var moved_element_id  = parseInt( ui.item.attr(dom_id_attr) )
            var serialized_list   = $(this).sortable('serialize', {key : server_side_attribute } )
            var sorted_ids        = serialized_list.split('&').map( function(element_string){
                                     if(element_string.match(/\d+/)) return parseInt(element_string.match(/\d+/)[0])
                                   })
            var moved_element_position = sorted_ids.indexOf(moved_element_id) + 1
            var sortable_container = this

            $.post(
              controller +"/"+ moved_element_id +"/" + action,

              {
                _method : "PUT",
                id : moved_element_id,
                position : moved_element_position
              },

              function(json_response){
                var moved_element         = $("["+ dom_id_attr +"="+ moved_element_id +"]")
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
                  $(sortable_container).sortable("cancel") // rollback to position before present action
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
    }

  }

  AjaxSort.custom_setup({
    cursor                  : 'move',
    opacity                 : 0.6,
    scroll                  : true,
    tolerance               : 'pointer',
    container               : '#sortable_terms',
    handle                  : "[data-handle='handle-for-sort']",
    dom_id_attr             : 'data-term-id',
    server_side_attribute   : 'term_id',
    controller              : 'terms',
    action                  : 'move'
  })

})

