$(document).ready(function(){

  var br = new BookReader();

  br.getPageWidth = function(index) {
    return this.pageW[index];
  };

  br.getPageHeight = function(index) {
    return this.pageH[index];
  };

  // br.getPageURI
  // Reduce and rotate are ignored in this simple implementation, but
  // we could e.g. look at reduce and load images from a different
  // directory or pass the information to an image server

  br.getPageURI = function(index) {
    return br.digital_object_base_path + "/" + br.leafMap[index];
  };

  br.getPageSide = function(index) {
    if (0 === (index & 0x1)) {
      return "R";
    } else {
      return "L";
    }
  };

  br.getPageNum = function(index) {
    var pageNum = this.pageNums[index];
    if (pageNum) {
      return pageNum;
    } else {
      return "n" + index;
    }
  };

  br.updateNavPageNum = function(index) {
    var pageNum = this.getPageNum(index);
    var pageStr;
    pageStr = index + 1 + " / " + this.numLeafs;
    $("#pagenum .currentpage").text(pageStr);
  };

  br.leafNumToIndex = function(leafNum) {
    var index = jQuery.inArray(leafNum, this.leafMap);
    if (index == -1 ) {
      return null;
    } else {
      return index;
    }
  };

  br.getSpreadIndices = function(pindex) {
    var spreadIndices = [null, null];
    if ("rl" == this.pageProgression) {
      if (this.getPageSide(pindex) == "R") {
        spreadIndices[1] = pindex;
        spreadIndices[0] = pindex + 1;
      } else {
        spreadIndices[0] = pindex;
        spreadIndices[1] = pindex - 1;
      }
    } else {
      if (this.getPageSide(pindex) == "L") {
        spreadIndices[0] = pindex;
        spreadIndices[1] = pindex + 1;
      } else {
        spreadIndices[1] = pindex;
        spreadIndices[0] = pindex - 1;
      }
    }
    return spreadIndices;
  };

  br.uniquifyPageNums = function() {
    var seen = {};
    for (var i = br.pageNums.length - 1; i--; i >= 0) {
      var pageNum = br.pageNums[i];
      if ( !seen[pageNum] ) {
        seen[pageNum] = true;
      } else {
        br.pageNums[i] = null;
      }
    }
  };

  br.cleanupMetadata = function() {
    br.uniquifyPageNums();
  };

  // Not used features
  br.getEmbedURL = function(viewParams) {
    return "";
  };

  br.getEmbedCode = function(frameWidth, frameHeight, viewParams) {
    return "";
  };

  // Setup tooltips -- later we could load these from a file for i18n
  br.initUIStrings = function() {
    var titles = { ".zoom_in": "Zoom avanti",
                   ".zoom_out": "Zoom indietro",
                   ".onepg": "Una pagina",
                   ".twopg": "Due pagine",
                   ".book_left": "Pagina precedente",
                   ".book_right": "Pagina successiva",
                   ".BRdn": "Mostra / nascondi barra di navigazione",
                   ".BRup": "Mostra / nascondi barra di navigazione"
                 };

    for (var icon in titles) {
        if (titles.hasOwnProperty(icon)) {
            $("#BookReader").find(icon).attr("title", titles[icon]);
        }
    }
  };

  // Custom horizontal TOC without page numbers
  br.addChapter = function(chapterTitle, pageNumber, pageIndex) {
      // var uiStringPage = 'Pagina'; // i18n

      var percentThrough = BookReader.util.cssPercentage(pageIndex, this.numLeafs - 1);
      // $('<div class="chapter" style="left:' + percentThrough + ';"><div class="title">'
      //  + chapterTitle + '<span>|</span> ' + uiStringPage + ' ' + pageNumber + '</div></div>')
      $('<div class="chapter" style="left:' + percentThrough + ';"><div class="title">'
          + chapterTitle + '</div></div>')
      .appendTo('#BRnavline')
      .data({'self': this, 'pageIndex': pageIndex })
      .bt({
          contentSelector: '$(this).find(".title")',
          trigger: 'hover',
          closeWhenOthersOpen: true,
          cssStyles: {
              padding: '12px 14px',
              backgroundColor: '#000',
              border: '4px solid #e2dcc5',
              //borderBottom: 'none',
              fontFamily: '"Arial", sans-serif',
              fontSize: '12px',
              fontWeight: '700',
              color: '#fff',
              whiteSpace: 'nowrap'
          },
          shrinkToFit: true,
          width: '200px',
          padding: 0,
          spikeGirth: 0,
          spikeLength: 0,
          overlap: '21px',
          overlay: false,
          killTitle: true, 
          textzIndex: 9999,
          boxzIndex: 9998,
          wrapperzIndex: 9997,
          offsetParent: null,
          positions: ['top'],
          fill: 'black',
          windowMargin: 10,
          strokeWidth: 0,
          cornerRadius: 0,
          centerPointX: 0,
          centerPointY: 0,
          shadow: false
      })
      .hover( function() {
              // remove hover effect from other markers then turn on just for this
              $('.search,.chapter').removeClass('front');
                  $(this).addClass('front');
              }, function() {
                  $(this).removeClass('front');
              }
      )
      .bind('click', function() {
          $(this).data('self').jumpToIndex($(this).data('pageIndex'));
      });
  };

  br.getOpenLibraryRecord = function(callback) {
    $.getJSON(
      // Comment following lines in order not to load horizontal TOC
      location.href.match(/.*\/digital_objects\/\d+\//) + "bookreader_record",
      function(json){ if (json) callback(br, json); }
    );
  };

  br.gotOpenLibraryRecord = function(self, olObject) {
    if (olObject) {
        if (olObject["table_of_contents"]) {
            // Comment following lines if you don't use horizontal TOC
            self.updateTOC(olObject["table_of_contents"]);
        }
        $("#BRshare").remove();
        $("#BRinfo").remove();
    }
  };

  var Navigation = {

    setup_jstree : function(){
      $("#BRtree")
      .bind("loaded.jstree", function(event, data) {
        //$(this).jstree("open_all")
      })
      .jstree({ // start jstree configuration with configuration object
        "plugins"   : [ "themes", "ui", "json_data" ],
        "core"        : {
          "initially_open"  : ["[data-is-toc='true']"]
        },
        "ui"        : {
          "initially_select"  : ["[data-is-toc='true']"]
        },
        "json_data" : {
          "ajax": {
            "dataType" : "json",
            "url" : "nodes"
          }
        }
      });
    }, // setup_jstree

    bind_toc_nodes : function (book_reader) {
      $("#BRtree ul li[data-page-number!='null']").live("click", function(event){
        var node_element    = $(this);
        var digital_file_id = node_element.data("digital-file-id");
        var page_number     = node_element.data("page-number").toString();
        // page_number requires [data-page-number!='null'] in the selector

        book_reader.jumpToPage(page_number);

        event.preventDefault();
        event.stopPropagation();
      });
    } // bind_toc_nodes

  }; // Navigation

  $.getJSON(
    location.href.match(/.*\/digital_objects\/\d+\//) + "bookreader_data",
    function(json){
      br.digital_object_base_path = json.base_path;
      br.pageW                    = json.widths;
      br.numLeafs                 = br.pageW.length;
      br.pageH                    = json.heights;
      br.leafMap                  = json.leaf_map;
      br.pageNums                 = json.page_numbers;
      br.bookTitle                = json.book_title;
      br.bookUrl                  = json.book_url;
      br.mode                     = 2;
      br.reductionFactors         = [
                                      {reduce: 0.50,  autofit: null},
                                      {reduce: 1,     autofit: null},
                                      {reduce: 2,     autofit: null},
                                      {reduce: 3,     autofit: null},
                                      {reduce: 4,     autofit: null}
                                    ];
      br.imagesBaseURL            = "/javascripts/bookreader/images/";
      br.pageProgression          = "lr";
      br.cleanupMetadata();

      if (br.numLeafs > 0) {
        br.init();

        // Customize BRtoolbar - top
        $("#BRtoolbarbuttons").remove();
        $("a.logo").parent("span").remove();
        $("#BRreturn").before("<button class='BRicon index' title='Indice'></div>");
        $("#BRreturn a").attr( { 'href': br.bookUrl, 'title': "Vai alla descrizione dell\'oggetto digitale" } );

        // Customize BRnav - bottom
        $("button.BRicon.thumb").remove();

        // Custom element BRtree
        Navigation.setup_jstree();
        Navigation.bind_toc_nodes(br);
      } else {
        alert("L'oggetto digitale non contiene files");
      }
    }
  ); // getJSON

  // OPTIMIZE: rivedere e eventualmente spostare in funzioni
  $(".BRicon.index").live("click", function() {
    $("#BRtree").slideToggle("slow");
  });

  $("#BRnavCntlBtm.BRup").live("click", function() {
    $("#BRtree").animate({ width: "hide" }, "fast");
  });

});

