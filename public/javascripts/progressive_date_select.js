// TODO: pluginize
// TODO: extend to hour/minute/seconds
// TODO: emancipate from position of selects, get them by attributes

$(document).ready(function(){

  $.fn.dimensions = function() {
    result = {}
    result.height = this.height()
    result.width = this.width()
    return result
  }

  var ProgressiveDateSelect = {

    add_hidden_fields_if_missing : function (opts) {
      var self = this
      var $_years  = $('.'+ opts.css_class +'[name*=(1i)]')
      $_years.each(function(index, element){
        var model_attribute = $(this).attr('name').match(/(?!.*\[).*(?=\(1i\))/)[0] // "project[start_date(1i)]" => start_date
        var new_hidden_field_name = $(element).attr('name').replace('(1i)','_format') // "project[start_date(1i)]" => start_date
        if ($(element).prevAll("input:hidden[name='"+ new_hidden_field_name +"]").size() == 0) {
          $('<input />').attr({name:new_hidden_field_name, type:'hidden'}).insertBefore($(element))
        }
      })
    },

    // UTILITIES
    jquerify : function(input){
      if (input instanceof jQuery) {
        var $_output = input
      } else {
        var $_output = $(input)
      }
      return $_output
    },

    extract_date_format_from : function (date_field) {
      var self = this
      return self.date_format_field(date_field).val()
    },

    extract_common_name_part_from : function ($_current_field) {
      return $_current_field.attr('name').replace(/\(\d+i\)\]/, '')
    },

    extract_prompt_from :function(select){
      var self = this
      var $_select = self.jquerify(select)
      return $_select.find('option:first').text()
    },

    // FIND ELEMENTS
    months_and_days : function (opts) {
      var self = this
      return $('.'+ opts.css_class +'[name*=(2i)], .'+ opts.css_class +'[name*=(3i)]')
    },

    years : function (opts) {
      var self = this
      return $('.'+ opts.css_class +'[name*=(1i)]')
    },

    next_field : function(current_field, css_class){
      var self = this
      var $_current_field = self.jquerify(current_field)
      var common_name_part = self.extract_common_name_part_from($_current_field)

      return $_current_field.nextAll("select[name*='"+common_name_part+"']:first")
    },

    previous_field : function(current_field, css_class){
      var self = this
      var $_current_field = self.jquerify(current_field)
      var common_name_part = self.extract_common_name_part_from($_current_field)

      return $_current_field.prevAll("select[name*='"+common_name_part+"']:first")
    },

    date_format_field : function (date_field) {
      var self = this
      var $_date_field = self.jquerify(date_field)
      var common_name_part = self.extract_common_name_part_from($_date_field)

      var model_attribute = $_date_field.attr('name').match(/(?!.*\[).*(?=\(.i\))/)[0]
      // "project[start_date(1i)]" => start_date

      var hidden_field_name = $_date_field.attr('name').replace(/\(.i\)/g,'_format')
      // "project[start_date(1i)]" => "project[start_date_format]"

      return $("input:hidden[name='"+ hidden_field_name +"']:last")
    },

    target_elements : function(field, caller, css_class){
      var self = this
      var $_field = self.jquerify(field)
      var $_caller = self.jquerify(caller)
      var common_name_part = self.extract_common_name_part_from($_field)

      var target_elements               = {}
      target_elements.fields_$          = $_field.nextAll("select[name*='"+common_name_part+"']").andSelf()
      target_elements.reset_commands_$  =   function(){ if ($_caller.is('select') && !$_caller.attr('name').match(/\(1i\)\]/) ) {
                                              return $_caller.nextAll("a.reset_field."+css_class+":gt(0)")
                                            } else {
                                              return $_field.nextAll("a.reset_field."+css_class)
                                            } }.call()

      target_elements.show_commands_$   = $_caller.nextAll(".show_next_field."+css_class)
      target_elements.commands_$        = target_elements.show_commands_$.add(target_elements.reset_commands_$)

      return target_elements
    },

    // CREATE NEW ELEMENTS
    create_next_field_command : function(prompt,css_class){
      return  $('<a />')
              .addClass('show_next_field')
              .addClass(css_class)
              .attr({href:'#nogo'})
              .html('&nbsp;'+prompt+'&nbsp;')
    },

    create_reset_command : function (opts) {
      var self = this
      return  $('<a />',{href:'#nogo',html:'&nbsp;x&nbsp;'})
              .css({fontWeight:'bold'})
              .addClass(opts.css_class)
              .addClass('reset_field')
    },

    // ACTIONS
    hide_and_disable_according_format : function ($_input_fields, regexp, css_class) {
      var self = this
      $_input_fields.each(function(index, element){
        var date_format_string = self.extract_date_format_from(element)
        if (date_format_string != null && !date_format_string.match(regexp)) {
          $(this).css({opacity:0}).attr({disabled:true}).val('') //
          $(this).nextAll('a.'+ css_class +':first').css({opacity:0})
        }
      })
    },

    insert_next_field_commands : function(opts){
      var self = this
      self.years({css_class:opts.css_class}).each(function(){
        var $_current_field = $(this)
        if($_current_field.val() != ''){
          var common_name_part = self.extract_common_name_part_from($_current_field)
          var $_next_disabled_field = $(this).nextAll("select[name*='"+common_name_part+"']:disabled:first")
          var prompt = self.extract_prompt_from($_next_disabled_field)
          self.create_next_field_command(prompt,opts.css_class).insertBefore($_next_disabled_field)
        }
      })
    },

    reset_from_field : function(opts){
      var self = this
      var $_field = self.jquerify(opts.field)

      if ($_field.attr('name').match('(2i)')) { var new_date_format = 'Y' }
      else if ($_field.attr('name').match('(3i)')) { var new_date_format = 'YM' }

      if (self.previous_field($_field).val() != '') { self.date_format_field($_field).val(new_date_format) }

      var $_next_field_command = self.create_next_field_command(self.extract_prompt_from($_field),opts.css_class).css({opacity:0})
      var target_elements       = self.target_elements(opts.field, opts.caller, opts.css_class)

      target_elements.show_commands_$.remove()
      target_elements.reset_commands_$.animate({opacity:0},'fast')
      target_elements.fields_$.animate({opacity:0},'fast',function(){
        $(this).attr({disabled:true}).val('')
        if(opts.insert_next_field_command) $_next_field_command.insertBefore($_field).animate({opacity:1},'fast')
      })
    },

    update_date_format : function(date_field){
      var self = this
      var $_date_field = self.jquerify(date_field)

      if ($_date_field.attr('name').match('(1i)') ) {
        if ($_date_field.val() != '') {var new_value = 'Y'} else {var new_value = ''}
      } else if ($_date_field.attr('name').match('(2i)') ) {
        if ($_date_field.val() != '') {var new_value = 'YM'} else {var new_value = 'Y'}
      } else if ($_date_field.attr('name').match('(3i)')) {
        if ($_date_field.val() != '') {var new_value = 'YMD'} else {var new_value = 'YM'}
      }
      self.date_format_field(date_field).val(new_value)
    },

    show_next_field : function($_previous_field,css_class){
      var self = this
      var common_name_part = self.extract_common_name_part_from($_previous_field)
      var $_next_select = $_previous_field.nextAll("select[name*='"+ common_name_part +"']:first")
      var $_next_reset_command = $_next_select.nextAll("a."+ css_class +":first")
      var $_next_show_command = $_previous_field.nextAll("a.show_next_field:first")

      $_next_show_command.remove()
      $_next_select.removeAttr('disabled').animate({opacity:1},'fast')
      $_next_reset_command.show().animate({opacity:1},'fast')
    },

    // SETUPS
    setup_show_next_field_on_change : function(opts) {
      var self = this
      $("."+ opts.css_class +"[name$='i)]']").change(function(event){
        var $_current_field = $(this)
        var $_next_field = self.next_field(this,opts.css_class)

        self.update_date_format(this)
        if ($_current_field.val() != '') {
          self.show_next_field($_current_field,opts.css_class)
        } else {
          if($_next_field.size()>0) {
            self.reset_from_field({
              field                       : $_next_field,
              css_class                   : opts.css_class,
              insert_next_field_command   : false,
              caller                      : $_current_field
            })
          }
        }
      })
    },

    setup_months_and_days : function(opts){
      var self = this
      var $_months  = $('.'+ opts.css_class +'[name*=(2i)]')
      var $_days    = $('.'+ opts.css_class +'[name*=(3i)]')
      var $_months_and_days = self.months_and_days({css_class : opts.css_class})
      var $_reset_command = self.create_reset_command({css_class : opts.css_class})
      $_reset_command.insertAfter($_months_and_days)
      self.hide_and_disable_according_format($_months, /M/, opts.css_class)
      self.hide_and_disable_according_format($_days, /D/, opts.css_class)
    },

    setup_next_field_commands : function(opts){
      var self = this
      $('a.show_next_field').live('click', function(event){
        var $_previous_field = $(this).prevAll('.'+opts.css_class+':enabled:first')
        var common_name_part = self.extract_common_name_part_from($_previous_field)
        var $_next_field = $(this).nextAll("select[name*='"+ common_name_part +"']:first")
        $(this).hide()
        self.show_next_field($_previous_field,opts.css_class)
        event.preventDefault()
      })
    },

    setup_reset_command : function(opts){
      var self = this
      $('a.'+opts.css_class+'.reset_field').live('click',function(event){
        var $_previous_field = $(this).prevAll('.'+opts.css_class+':enabled:first')
        self.reset_from_field({
          field:$_previous_field,
          css_class:opts.css_class,
          insert_next_field_command:true,
          caller:this
        })
        event.preventDefault()
      })
    },

    setup : function(opts) {
      //this.add_hidden_fields_if_missing({css_class : opts.css_class})
      this.setup_months_and_days({css_class : opts.css_class})
      this.setup_show_next_field_on_change({css_class : opts.css_class})
      this.insert_next_field_commands({css_class : opts.css_class})
      this.setup_next_field_commands({css_class : opts.css_class})
      this.setup_reset_command({css_class : opts.css_class})
    }

  }

  ProgressiveDateSelect.setup({
    css_class : 'progressive_date_select'
  })

})

