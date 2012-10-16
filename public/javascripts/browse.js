$(document).ready(function () {

  // tree instance
  $("#toc-read-only")
  .bind("loaded.jstree", function(event, data) {
      $(this).jstree("open_all")
  })
  .jstree({ // start jstree configuration with configuration object
    "plugins" : [ "themes", "json_data", "ui" ],
    "ui" : { initially_select : ["[data-is-toc='true']"] },
    "crrm" : { "input_width_limit": 255 },
    "json_data" : {
      "ajax" : {
                "dataType" : "json",
                "url" : "nodes"
               }
    }
  }) // end jstree configuration

  var Navigation = {

    bind_toc_nodes : function () {
      $("#toc-read-only ul li").live("click", function(event){
        var node_element = $(this)
        var digital_file_id = node_element.attr("data-digital-file-id")

        if(node_element.attr("data-digital-file-id") == "null"){
          alert("Il nodo non è ancora stato associato a un file")
        } else {
          DigitalObject.load_digital_file({
                          variant : "M",
                          digital_file_id : digital_file_id
                        })
        }

        event.preventDefault()
        event.stopPropagation()
      })
    },

    bind_next_link : function () {
      $("#next-digital-file-link").live("click", function(event){
        var link_element = $(this)
        var digital_file_id = link_element.attr("data-next-digital-file-id")
        DigitalObject.load_digital_file({
          digital_file_id : digital_file_id,
          variant : "M"
        })
        event.preventDefault()
      })
    },

    bind_previous_link : function () {
      $("#previous-digital-file-link").live("click", function(event){
        var link_element = $(this)
        var digital_file_id = link_element.attr("data-previous-digital-file-id")
        DigitalObject.load_digital_file({
          digital_file_id : digital_file_id,
          variant : "M"
        })
        event.preventDefault()
      })
    },

    unbind_toc_nodes : function () {
      $("#toc-read-only ul li").unbind("click")
    },

    unbind_next_link : function () {
      $("#next-digital-file-link").unbind("click")
    },

    unbind_previous_link : function () {
      $("#previous-digital-file-link").unbind("click")
    },

    bind_all : function () {
      this.bind_toc_nodes()
      this.bind_next_link()
      this.bind_previous_link()
    },

    unbind_all : function () {
      this.unbind_toc_nodes()
      this.unbind_next_link()
      this.unbind_previous_link()
    }

  }

  var DigitalObject = {

    set_next_link : function(next_digital_file_id){
      $("#next-digital-file-link")
      .attr("data-next-digital-file-id", next_digital_file_id)
    },

    set_previous_link : function(previous_digital_file_id){
      $("#previous-digital-file-link")
      .attr("data-previous-digital-file-id", previous_digital_file_id)
    },

    load_digital_file : function (args_obj) {
      var params = new Object()
      if(args_obj.digital_file_id){
        params = { "variant" : args_obj.variant, "digital_file_id" : args_obj.digital_file_id }
      }else{
        params = { "variant" : args_obj.variant }
      }

      var existing_digital_file_id = $("#image-area img").attr("data-digital-file-id")

      if (existing_digital_file_id != args_obj.digital_file_id || !args_obj.digital_file_id ){
        $.get(
          location.pathname.replace('browse','digital_file_path'), // "digital_objects/52/digital_file_path"
          params,
          function(json_response){
            var img = new Image()
            $(img)
            .attr( {"src" : json_response.current_digital_file_absolute_path,
                    "data-digital-file-id" : json_response.current_digital_file_id } )
            .one("load", function(){
              var image_wrapped_by_div = $(this).wrap('<div class="absolute-position"></div>').parent().hide()

              image_wrapped_by_div.css({marginLeft: "auto", marginRight: "auto"})

              image_wrapped_by_div.appendTo($("#image-area")).fadeIn(300, function(){
                if($("#image-area div").length > 1){
                  $("#image-area div:first").fadeOut(300,function(){
                    $(this).remove()
                  })
                }
                DigitalObject.set_next_link( json_response.next_digital_file_id )
                DigitalObject.set_previous_link( json_response.previous_digital_file_id )
              })
            })
          }
        )
      }
    } // end of load_digital_file function

  } // end of DigitalObject

  DigitalObject.load_digital_file({variant : "M"})
  Navigation.bind_all()

})

