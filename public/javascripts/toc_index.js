$(document).ready(function () {

  $("#images-list img").lazydoll({
    container : "#images-list"
  });

  // tree instance
  $("#toc")
  .bind("loaded.jstree", function(event, data) {
    $(this).jstree("open_all");
    $(this).find("li").each( function(index, element) {
      if($(this).attr("data-digital-file-id") != "null" ){
        var tick_icon = new Image();
        $(tick_icon).attr("src", "/images/icons/tick.png");
        $(this).find("a:first").after($(tick_icon));
      }
    });
  })
  .jstree({ // start jstree configuration with configuration object
    "plugins" : [ "themes", "json_data", "ui", "crrm", "dnd" ],
    "dnd" :
      {
        "drop_finish" : function (data) {
          // data.o - the object being dragged (the node to assign to)
          // data.r - the drop target (the digital_file to be assigned)
          var node_numeric_id = $(data.o).attr('id').replace('node-', '');
          var digital_file_numeric_id = $(data.r).attr('data-digital-file');
          NodeManipulation.assign(node_numeric_id, digital_file_numeric_id);
        },
        "drag_finish" : function (data) {
          // data.o - the foreign object being dragged (the digital_file to be assigned)
          // data.r - the target node (the node to assign to)
          var node_numeric_id = $(data.r).attr('id').replace('node-', '');
          var digital_file_numeric_id = $(data.o).attr('data-digital-file');
          NodeManipulation.assign(node_numeric_id, digital_file_numeric_id);
        }
    },
    "ui" : {
      "initially_select" : ["[data-is-toc='true']"],
      "select_limit" : 1
    },
    "crrm" : { "input_width_limit": 255 },
    "json_data" : {
      "ajax" : {
                "dataType" : "json",
                "url" : "nodes" // as a relative path, all url will be appended to current url
               }
    }
  }) // end configuration
  .bind("create.jstree", function (e, data) {
    NodeManipulation.create(data);
  })
  .bind("remove.jstree", function (e, data) {
    NodeManipulation.remove(data.rslt.obj.attr("id"));
  })
  .bind("rename.jstree", function (e, data) {
    var node_numeric_id = data.rslt.obj.attr("id").replace("node-", "");
    var new_name = data.rslt.new_name;
    NodeManipulation.rename(node_numeric_id, new_name);
  })
  .bind("move_node.jstree", function (e, data) {
    NodeManipulation.move_node(data);
  }); // end jstree instance

  // .o - the node being moved
  // .r - the reference node in the move
  // .ot - the origin tree instance
  // .rt - the reference tree instance
  // .p - the position to move to (may be a string - "last", "first", etc)
  // .cp - the calculated position to move to (always a number)
  // .np - the new parent

  var NodeManipulation = {

    create : function (data){
      $.post(
        "nodes", // e' la url (path), perche' quella corrente viene gia' inclusa
                 // mentre la action e' sempre create perche' la request e' $.post
        {
          "node[parent_id]" : data.rslt.parent.attr("id").replace("node-",""),
          "node[description]" : data.rslt.name
        },
        function (json_response) {
          if(json_response.status) {
            $(data.rslt.obj).attr("id", "node-" + json_response.node.id);
          }
          else {
            $.jstree.rollback(data.rlbk);
          }
        }
      );
      return false;
    }, // end of create function

    rename : function (node_numeric_id, new_name) {
      $.post(
        "nodes/" + node_numeric_id, // e' l''url (path), l'url corrente viene gia' inclusa
                                    // mentre la action e' sempre update perche' la request e' "_method":"PUT"
        {
          "_method"           : "PUT", // notice the underscore (rails mimics the put with _method param)
          "id"                : node_numeric_id,
          "node[description]" : new_name
        },
        function (json_response) {
          if(json_response.status) {
            $('.node-description[data-node='+ json_response.node.id +']').fadeOut(200, function(){
              $(this).find('span').html(json_response.node.description).parent().fadeIn(200);
            });
          } else {
            $.jstree.rollback(data.rlbk);
          }
        }
      );
      return false;
    }, // end of rename function

    remove : function(node_id) {
      // var node_id = data.rslt.obj.attr("id")
      var node_numeric_id = node_id.toString().replace("node-", "");
      $.post(
        "nodes/" + node_numeric_id, // e' l''url (path), l'url corrente viene gia' inclusa
                                    // mentre la action e' sempre update perche' la request e' "_method":"DELETE"
        {
          "_method" : "DELETE", // notice the underscore (rails mimics the put with _method param)
          "id"      : node_numeric_id
        },
        function (json_response) {
          if(json_response.status) {
            $(".node-description[data-parent-id="+ json_response.node.id +"]")
            .slideUp(200, function(){
              $(this).remove();
            });

            var flat_sub_tree = json_response.flat_sub_tree;
            var nodes_selectors = [];

            for(x in flat_sub_tree){
              nodes_selectors = nodes_selectors
                                .concat([".node-description[data-node="+ flat_sub_tree[x] +"]"]);
            }

            $(nodes_selectors.join(", "))
            .slideUp(200, function(){
              $(this).remove();
            });
          } else {
            $.jstree.rollback(data.rlbk);
          }
        }
      );
      return false;
    }, // end of remove function

    assign : function(given_node_id, given_digital_file_id){
      $.post(
        "nodes/" + given_node_id + "/assign", // url della action
        {
          "_method" : 'PUT',
          "id" : given_node_id,
          "node[digital_file_id]" : given_digital_file_id
        },
        function (json_response) {

          if(json_response.status) {
            var existing_description_element = $('.node-description[data-node='+ json_response.node.id +']');
            var digital_file_group = $('.associated-nodes[data-digital-file='+ json_response.node.digital_file_id +']');
            var current_node = $("#toc ul li#node-"+ json_response.node.id );

            current_node.attr("data-digital-file-id", json_response.node.digital_file_id);

            if (existing_description_element.length > 0) {
              existing_description_element.slideUp(200, function(){
                $(this).remove();
              });
              $("li#node-"+ json_response.node.id +" img:first").fadeOut(200, function(){
                $(this).remove();
              });
            }

            $.get(
              ("nodes/" + json_response.node.id + "/description_template"),
              { "node[description]" : json_response.node.description },
              function (data) {
                data;
                digital_file_group.append( $(data).hide() );
                digital_file_group.find('.node-description:last').slideDown(200);

                var tick_icon = new Image();
                $(tick_icon).attr("src", "/images/icons/tick.png");
                current_node.find("a:first").after($(tick_icon));
              }
            );
          }
        }
      );
      return false;
    }, // end of assign function

    move_node : function(data){
      var node_numeric_id = data.rslt.o.attr("id").replace("node-", "");
      $.post(
        "nodes/" + node_numeric_id + "/move",
        {
          "_method" : "PUT",
          "id" : node_numeric_id,
          "node[parent_id]" : data.rslt.np.attr("id").replace("node-",""), //new parent
          "node[position]" : data.rslt.cp, // new calculated position, start from zero
          "node[description]" : data.rslt.name, // original name
          "copy" : data.rslt.cy ? 1 : 0
        },
        function (json_response) {
          if(json_response.status) {
            $(data.rslt.oc).attr("id", "node-" + json_response.node.id);
            if(data.rslt.cy && oc.children("UL").length) {
              data.inst.refresh(data.rslt.oc);
            }
          }
          else {
            $.jstree.rollback(data.rlbk);
          }
          $("#analyze").click();
        }
      );
      return false;
    }

  }; // end of NodeManipulation-namespaced functions

  // DOUBLE-CLICK IN-PLACE EDITING
  //[id^='node-']
  $("#toc ul li").live("dblclick", function(){
    $("#toc").jstree("rename", this);
    return false;
  });

  // ASK FOR CONFIRMATION BEFORE STARTING REMOVAL
  $("#delete-node").click( function(){
    var clicked_node = $(".jstree-clicked").parent();
    if (  clicked_node.attr("data-is-toc") == "true" ) {
      alert("Non è possibile rimuovere il nodo iniziale");
    } else {
      var question = "Confermi l'eliminazione del nodo selezionato e dei nodi dipendenti?";
      var answer   = confirm( question );
      if ( answer == 1  ) {
        $("#toc").jstree("remove", clicked_node);
      }
    }
    return false;
  });

  // REMOVE ASSOCIATION BETWEEN A NODE AND A DIGITAL FILE
  $('.remove-assignment').live('click', function () {
    var digital_file_id = $(this).attr('data-digital-file');
    var node_id = $(this).attr('data-node');
    $.post(
      "nodes/"+ node_id +"/remove_assignment",
      {
        "_method" : 'PUT',
        "id"      : node_id
      },
      function(json_response){
        var current_node = $("#toc ul li#node-"+ json_response.node.id );
        current_node.attr("data-digital-file-id", "null");
        if(json_response.status){
          $('.node-description[data-node='+ json_response.node.id +']').slideUp(200, function(){
            $(this).remove();
          });
          $("li#node-"+ json_response.node.id +" img:first").fadeOut(200, function(){
            $(this).remove();
          });
          $("#toc ul li#node-"+ json_response.node.id +" > a:first").animate(
            { backgroundColor: "#F2F2F0", color : "black" },
            230,
            function(){
              $(this).removeAttr("style");
            }
          );
        }
      }
    );
    return false;
  }); // end remove_assignment

  // animate node corresponding to hovered node description in the assigned list

  $(".node-description").live('mouseenter', function() {
    var node_id = $(this).attr("data-node");
    var corresponding_node = $("#toc ul li#node-"+ node_id +" > a:first");
    corresponding_node.animate({ backgroundColor: "#BA1820", color : "white" }, 150);
  });

  $(".node-description").live('mouseleave', function() {
    var node_id = $(this).attr("data-node");
    var corresponding_node = $("#toc ul li#node-"+ node_id +" > a:first");
    corresponding_node.animate({ backgroundColor: "#F2F2F0", color : "black" }, 230, function(){
      $(this).removeAttr("style");
    });
  });

  // WORK IN PROGRESS (NON CANCELLARE): far scattare l'animazione solo se
  // il mouse resta sull'elemento target per un certo tempo
  // http://stackoverflow.com/questions/1273566/how-do-i-check-if-the-mouse-is-over-an-element-in-jquery
  //
  //
  //  $(".node-description").live('mouseenter', function(event){
  //      var t = setTimeout("alert('entrato')",4000)
  //  })
  //
  // $("someelement").mouseenter(function(){
  //     clearTimeout($(this).data('timeoutId'));
  //     $(this).find(".tooltip").fadeIn("slow");
  // }).mouseleave(function(){
  //     var someelement = this;
  //     var timeoutId = setTimeout(function(){ $(someelement).find(".tooltip").fadeOut("slow");}, 650);
  //     $(someelement).data('timeoutId', timeoutId); //set the timeoutId, allowing us to clear this trigger if the mouse comes back over
  // });


  $("#tree_actions input").click(function () {
    $("#toc").jstree(this.id);
  });

  $("#toc-wrapper").resizable({
      handles: { "e": "#handle"},
      alsoResize : "#toc_editor, #toc",
      maxWidth: 450,
      minWidth: 220
  });

});

