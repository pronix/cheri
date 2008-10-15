#--
# Copyright (C) 2007,2008 William N Dortch <bill.dortch@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++
#

module Cheri
module JRuby
module Explorer

class RootNodeViewer < HtmlNameValueListViewer
  include InstanceListener

  def initialize(*r,&k)
    super
    main.add_instance_listener(self)  
  end

  def title
    'Instances'
  end
  def icon
    CheriIcon
  end
  def table_rows
    main.instance_list.each do |inst|
      name_value_row(inst.name,inst.address)
    end  
  end
  def instance_added(instance)
    refresh
  end
  def instance_removed(instance)
    refresh  
  end
end #RootNodeViewer

class RubyInstanceViewer < HtmlNameValueListViewer
  def title
    @instance.name
  end

  def icon
    @instance.icon
  end

  def table_rows
    name_value_row('RUBY_PLATFORM',proxy.ruby_platform)
    name_value_row('RUBY_VERSION',proxy.ruby_version)
    name_value_row('RUBY_RELEASE_DATE',proxy.ruby_release_date)
    nil
  end
end #RubyInstanceViewer

class JRubyInstanceViewer < RubyInstanceViewer
  JVersion = 'java.version'.freeze
  JVendor = 'java.vendor'.freeze
  RtName = 'java.runtime.name'.freeze
  RtVersion = 'java.runtime.version'.freeze
  VmName = 'java.vm.name'.freeze
  VmVersion = 'java.vm.version'.freeze
  VmVendor = 'java.vm.vendor'.freeze

  def table_rows
    super
    env = proxy.env_java_brief
    name_value_row('JRUBY_VERSION',proxy.jruby_version)
    name_value_row('Java version',env[JVersion])
    name_value_row('Java vendor',env[JVendor])
    name_value_row('Runtime name',env[RtName])
    name_value_row('Runtime version',env[RtVersion])
    name_value_row('VM name',env[VmName])
    name_value_row('VM version',env[VmVersion])
    name_value_row('VM vendor',env[VmVendor])
    name_value_row('SecurityManager',proxy.security_manager)
    name_value_row('Available processors',proxy.available_processors)
    name_value_row('Total memory',"#{(proxy.total_memory/1000.0).round}K")
    name_value_row('Free memory',"#{(proxy.free_memory/1000.0).round}K")
    name_value_row('Maximum memory',"#{(proxy.max_memory/1000.0).round}K")
    name_value_row('ObjectSpace enabled',proxy.object_space?)
    name_value_row('JRuby start time',proxy.jruby_start_time)
    nil
  end
  
end #JRubyInstanceViewer

class LocalJRubyInstanceViewer < JRubyInstanceViewer
  def title
    'Local JRuby'  
  end
  def title_tab
    'Local'  
  end
end #LocalJRubyInstanceViewer

#class NameValueListViewer < HtmlNameValueListViewer
#
#end

class EnvViewer < HtmlNameValueListViewer
  def title
    "#{@instance.name}: ENV"
  end
  def title_tree
    'ENV'  
  end
  def icon
    VariablesIcon  
  end
  def leaf?
    true  
  end
  def table_rows
    env = proxy.env.sort
    env.each do |name,value|
      if Array === value
        value = value.sort rescue value
        name_value_row(name,value_list(value))  
      else    
        name_value_row(name,esc(value));
      end
    end
    nil
  end
end

class JavaEnvViewer < HtmlNameValueListViewer
  def title
    "#{@instance.name}: ENV_JAVA"
  end
  def title_tree
    'ENV_JAVA'  
  end
  def icon
    VariablesIcon  
  end
  def leaf?
    true  
  end
  def table_rows
    env = proxy.env_java.sort
    env.each do |name,value|
      if Array === value
        value = value.sort rescue value
        name_value_row(name,value_list(value))  
      else    
        name_value_row(name,esc(value));
      end
    end
    nil
  end
end

class GlobalVariablesViewer < HtmlNameValueListViewer
  def title
    "#{@instance.name}: global_variables"
  end
  def title_tree
    'global_vars'  
  end
  def title_tab
    "#{@instance.name}: global"
  end
  def icon
    VariablesIcon  
  end
  def leaf?
    true  
  end
  def table_rows
    vars = proxy.global_vars.sort
    vars.each do |name,value|
      if Array === value
        value = value.sort rescue value
        name_value_row(@esc = esc(name),value_list(value))
      else    
        name_value_row(@esc = esc(name),esc(value))
      end
    end
    nil
  end
end #GlobalVariablesViewer


class ConstantsViewer < HtmlNameValueListViewer
  include ParentViewerInterface
  include DRbHelper
    
  def title
    "#{@instance.name}: Module.constants"
  end
  def title_tree
    'constants'  
  end
  def title_tab
    "#{@instance.name}: const"
  end
  def icon
    ConstantIcon  
  end

  def table_rows
    consts = proxy.constants.sort
    consts.each do |name,type,value|
      # TODO: screen this in proxy?
      value = '' if value == name
      if Array === value
        value = value.sort rescue value
        name_type_value_row(name,type,value_list(value))  
      else    
        name_type_value_row(name,type,esc(value))
      end
    end
    nil
  end
  
  def load_children
    recs = drb_to_array(proxy.const_recs).sort
    children = []
    recs.each do |rec|
      ntv = case rec.clazz
        when 'Class' : NodeTypeValue.new(Class,rec.value,rec)
        when 'Module' : NodeTypeValue.new(Module,rec.value,rec)
        else NodeTypeValue.new(:constant,rec.clazz,rec)
      end
      children << ntv
    end
    @children = children
  end
  
  def children_loaded?
    @children  
  end

end #ConstantsViewer

class ConfigViewer < HtmlNameValueListViewer
  def title
    "#{@instance.name}: Config::CONFIG"
  end
  def title_tree
    'CONFIG'  
  end
  def title_tab
    "#{@instance.name}: CONFIG"
  end
  def icon
    VariablesIcon  
  end
  def leaf?
    true  
  end
  def table_rows
    cfg = proxy.config.sort
    cfg.each do |name,value|
      if Array === value
        value = value.sort rescue value
        name_value_row(name,value_list(value))  
      else    
        name_value_row(name,esc(value));
      end
    end
    nil
  end
end


# TODO: factor/generalize the header row code

class ObjectViewer < HtmlNameValueListViewer
  include ValueViewerInterface
  
  #:stopdoc:
  HdrInstVars = 'Instance variables'.freeze
  HdrInstVarName = 'Variable name'.freeze
  HdrName = 'Name'.freeze
  HdrType = 'Type'.freeze
  HdrId = 'Id'.freeze
  HdrValue = 'Value'.freeze
  Center = 'center'.freeze
  Left = 'left'.freeze
  Right = 'right'.freeze
  #:startdoc:

  def title
    "#{@instance.name}: #{@value.clazz}"
  end
  def title_tree
    "#{@value.clazz}" 
  end
  def title_tab
    "#{@instance.name}: #{@value.clazz}"
  end
  def icon
    ObjectIcon  
  end
  def leaf?
    true  
  end

  def table_rows
    value_header_row
    type_id_value_row(esc(@value.clazz),@value.id,esc(@value.value))
    instance_var_rows if value.vars
  end
  
  def instance_var_rows
    if (vars = value.vars)
      col_header_row HdrInstVarName
      vars.each do |name,type,value,id|
        if Array === value
          name_type_id_value_row(name,esc(type),id,value_list(value))
        else
          name_type_id_value_row(name,esc(type),id,esc(value))
        end
      end
      empty_row
    end
  end

  def header_row(hdr,cols=4)
    tr do
      th hdr, :bgcolor => NColor, :colspan => cols, :align => Left
    end  
  end

  def value_header_row
    tr do
      th HdrType, :bgcolor => NColor, :align => Left
      th HdrId, :bgcolor => NColor, :align => Right
      th HdrValue, :bgcolor => NColor, :align => Left
    end  
  end

  def col_header_row(name = HdrName)
    tr do
      th name, :bgcolor => NColor, :align => Left
      th HdrType, :bgcolor => NColor, :align => Left
      th HdrId, :bgcolor => NColor, :align => Right
      th HdrValue, :bgcolor => NColor, :align => Left
    end  
  end
end

class ConstantViewer < ObjectViewer
  HdrConstName = 'Constant name'.freeze
  def title
    "#{@instance.name}: #{@value.qname}"
  end
  def title_tree
    "#{@value.name}" 
  end
  def title_tab
    "#{@instance.name}: #{@value.name}"
  end
  def icon
    ConstantIcon  
  end
  
  def table_rows
    col_header_row HdrConstName
    name_type_id_value_row(@value.name,esc(@value.clazz),@value.id,esc(@value.value))
    instance_var_rows if @value.vars
  end

end

class ModuleViewer < ConstantViewer
  include ParentViewerInterface
  include DRbHelper
  #:stopdoc:
  SuperClazz = 'Superclass'.freeze
  Ancestors = 'Ancestors'.freeze
  HdrAncName = 'Ancestor name'.freeze
  #:startdoc:
  
  def title
    "#{@instance.name}: #{@value.qname.empty? ? @value.value : @value.qname}"
  end
  def title_tree
    "#{@value.name}" 
  end
  def title_tab
    "#{@instance.name}: #{@value.name.empty? ? @value.value : @value.name}"
  end
  def icon
    ModuleIcon  
  end
  def leaf?
    false  
  end

  def html_heading
    val = @value
    div :align => :left do
    table :width => TblWidth, :cellspacing => 2, :cellpadding => 2, :border => 0 do
      tr do
        td esc(title), :class => :hdr, :align => :left, :colspan=> 2
      end
      tr do
        th val.clazz, :align => :left, :bgcolor => NColor, :width => 120
        td esc(val.qname.empty? ? val.value : val.qname), :align => :left, :bgcolor => VColor
      end
      tr do
        th HdrId, :align => :left, :bgcolor => NColor, :width => 120
        td val.id, :align => :left, :bgcolor => VColor
      end
      if (sc = val.superclazz)
        tr do
          th SuperClazz, :align => :left, :bgcolor => NColor, :width => 120
          td esc(sc), :align => :left, :bgcolor => VColor
        end      
      end
      empty_row
    end
    if (anc = val.ancestors) && (first = anc.first)
      anc.shift if first.id == val.id && first.value == val.qname
    end
    if anc && !anc.empty?
      table :width => TblWidth, :cellspacing => 2, :cellpadding => 2, :border => 0 do
        tr do
          th HdrAncName, :bgcolor => NColor, :align => Left
          th HdrType, :bgcolor => NColor, :align => Left, :width => '20%'
          th HdrId, :bgcolor => NColor, :align => Right, :width => '10%'
        end
        anc.each do |name,type,id|
          tr do
            td esc(name), :bgcolor => VColor
            td type, :width => '20%', :bgcolor => VColor
            td id, :width => '10%', :bgcolor => VColor, :align => Right, :class => :oid
          end      
        end
        empty_row
      end
    end
    end #div
  end
  
  def table_rows
    instance_var_rows if value.vars
    method_rows
  end

  #:stopdoc:
  HdrPubClsMeth = 'Public class methods'.freeze
  HdrPubInsMeth = 'Public instance methods'.freeze
  HdrProClsMeth = 'Protected class methods'.freeze
  HdrProInsMeth = 'Protected instance methods'.freeze
  HdrPriClsMeth = 'Private class methods'.freeze
  HdrPriInsMeth = 'Private instance methods'.freeze
  #:startdoc:

  def method_rows
    if (meths = @methods ||= proxy.module_methods(@value.qname,@value.id))
      if (ms = meths.pub) && !ms.empty?
        method_header_row HdrPubClsMeth
        ms.sort.each do |m| method_row(m); end
        empty_row
      end
      if (ms = meths.pub_inst) && !ms.empty?
        method_header_row HdrPubInsMeth
        ms.sort.each do |m| method_row(m); end
        empty_row
      end
      if (ms = meths.pro) && !ms.empty?
        method_header_row HdrProClsMeth
        ms.sort.each do |m| method_row(m); end
        empty_row
      end
      if (ms = meths.pro_inst) && !ms.empty?
        method_header_row HdrProInsMeth
        ms.sort.each do |m| method_row(m); end
        empty_row
      end
      if (ms = meths.pri) && !ms.empty?
        method_header_row HdrPriClsMeth
        ms.sort.each do |m| method_row(m); end
        empty_row
      end
      if (ms = meths.pri_inst) && !ms.empty?
        method_header_row HdrPriInsMeth
        ms.sort.each do |m| method_row(m); end
        empty_row
      end
    end
  end
  
  def method_header_row(hdr,cols=4)
    tr do
      td b(hdr), :bgcolor => NColor, :colspan => cols
    end  
  end
  
  def method_row(meth,cols=4)
    tr td(esc(meth), :class => :method, :bgcolor => VColor, :colspan => cols)
  end

  Cls = 'Class'.freeze #:nodoc:
  Mod = 'Module'.freeze #:nodoc:
  def load_children
    recs = drb_to_array(proxy.const_recs(value.qname)).sort
    children = []
    recs.each do |rec|
      ntv = case rec.clazz
        when Cls : NodeTypeValue.new(Class,rec.value,rec)
        when Mod : NodeTypeValue.new(Module,rec.value,rec)
        else NodeTypeValue.new(:constant,rec.clazz,rec)
      end
      children << ntv
    end
    @children = children
  end
  
  def children_loaded?
    @children  
  end
  
  def refresh
    @methods = nil
    super  
  end

end

class ClassViewer < ModuleViewer
  def icon
    ClassIcon  
  end

end

class ResultListViewer < Viewer
  include ValueViewerInterface
  include NavViewerConstants
  #:stopdoc:
  Empty = '(empty)'
  #:startdoc:

  class ResultListItem
    def initialize(id,value)
      @i = id
      @v = value
    end
    def id
      @i
    end
    def v
      @v
    end
    alias_method :value,:v
    def ==(other)
      @v == other.v
    end    
    def eql?(other)
      @v.eql?(other.v)
    end
    def <=>(other)
      @v <=> other.v      
    end
    def to_s
      @v
    end
    alias_method :to_str, :to_s
    
  end #ResultListItem

#  def item_value(id)
#    @main.simple_value(@instance,id)
#  end
#
  def initialize(*r,&k)
    super
    create_object_list
  end
  
  def create_object_list
    res = @value.results
    proxy = @instance.proxy
    items = []
    res.length.times do |i|
      id = res[i]
      if (val = proxy.simple_value(id) rescue nil)
        val.strip!
        val = Empty if val.empty?
        items << ResultListItem.new(id,val)
      end
    end
    @obj_list = items.sort.to_java
  end

  def title
    "#{@instance.name}: Search Results"
  end
  def title_tree
    "Results" 
  end
  def title_tab
    "#{@instance.name}: Results"
  end
  def icon
    VariablesIcon  
  end

  # not expecting this to appear in trees, but if it does, it's a leaf
  def leaf?
    true
  end

  def view(&block)
    @view ||= scroll_pane do
      align :LEFT
      @top_view = y_panel do
        align :LEFT
        empty_border 4,4,4,4
        background :WHITE
        x_box do
          align :LEFT
          background :WHITE
          label title do
            align :LEFT
            set_font TFont
            foreground TColor
          end
          x_glue
        end
        @header = x_box do
          align :LEFT
          @cnames = y_panel do
            align :LEFT
            opaque false
            #background NColor
          end
          x_spacer 2
          @cvals = y_panel do
            align :LEFT
            opaque false
          end   
        end
        name_value_row('Class/Module',@value.args.clazz,CFont)
        if (vars = @value.args.vars) && !vars.empty?
          vname = vars[0].name.to_s
          vname = '  ' if vname.empty?
          vval = vars[0].value || '  '
          if Regexp === vval
            vval = vval.inspect
          elsif String === vval
            vval = '  ' if vval.empty?
          end
          name_value_row('Variable',vname)
          name_value_row('Value',vval)
        end
        last_row
        y_spacer 5
        x_box do
          align :LEFT
          label "=== found #{@value.length} objects ===" do
            align :LEFT
            foreground TColor
          end
        end
        y_spacer 3
        result_list
        y_spacer 3
        x_box do
          align :LEFT
          label '=== end of results ===' do
            align :LEFT
            foreground TColor
          end
        end
        # trying to get everything else pushed up
        y_glue
        y_panel do
          opaque false
        end
        y_glue
      end
    end
    super
  end
  
  def set_selection
    if (ix = @list.selected_index) >= 0
      @pending = ix
    end
  end
  def send_selection(new_tab=nil)
    if ix = @pending
      @pending = nil
      @main.show_result_object(self,@obj_list[ix].id,new_tab)
    end
  end
  def list_clicked(e)
    list = @list
    point = e.point
    if BUTTON1 == e.button &&
        (ix = list.location_to_index(point)) >= 0 &&
        list.get_cell_bounds(ix,ix).contains(point)
      send_selection((e.modifiers_ex & SHIFT) == SHIFT)
    end
  end

  def list_keyed(e)
    if @pending && e.action_key?
      send_selection((e.modifiers_ex & SHIFT) == SHIFT)
    end
  end
  
  def mouse_action(e)
    if e.popup_trigger?
      list = @list
      point = e.point
      if (ix = list.location_to_index(point)) >= 0 &&
          list.get_cell_bounds(ix,ix).contains(point)
        @menu_pending = ix
        selection_popup.show(e.component,e.x,e.y)
      end
    end
  end
  
  def menu_selection(new_tab)
    if ix = @menu_pending
      @menu_pending = nil
      @list.selected_index = ix
      send_selection(new_tab)
    end
  end
  
  def selection_popup
    @popup ||= popup_menu 'Open item in ... ' do
      menu_item 'Open in new tab' do
        on_click {menu_selection true}
      end
      menu_item 'Open in default tab' do
        on_click {menu_selection false}
      end
    end  
  end
  
  def result_list
    @list = list @obj_list do
      align :LEFT
      set_font ResFont
      foreground TColor
      selection_mode :SINGLE_SELECTION
      on_value_changed do |e|
        unless e.value_is_adjusting
          set_selection
        end
      end
      on_mouse_clicked   {|e| list_clicked e}
      on_mouse_pressed   {|e| mouse_action e}
      on_mouse_released  {|e| mouse_action e}
      on_key_pressed     {|e| list_keyed e}
      on_key_released    {|e| list_keyed e}
    end
  end
  
  def name_value_row(name,value,vfont=VFont)
    cheri_yield @cnames do
      x_panel do
        align :LEFT
        background NColor
        maximum_size 200,28
        on_mouse_entered do |e|
          e.source.background = HColor
        end
        on_mouse_exited do |e|
          e.source.background = NColor
        end
        x_spacer 2
        label name do
          align :LEFT,:CENTER
          set_font NFont
        end
        #x_glue
      end
      y_spacer 2
    end
    cheri_yield @cvals do
      x_panel do
        align :LEFT
        background VColor
        x_spacer 2
        label value do
          align :LEFT,:CENTER
          set_font vfont
        end
        x_glue
      end
      y_spacer 2
    end
  end

  def last_row
    cheri_yield @cnames do y_glue; end
    cheri_yield @cvals  do y_glue; end
  end
  
  def close_view
    @main.close_results_view(self)
  end
end


class NavObjectViewer
  include ViewerInterface
  include ValueViewerInterface
  include NavViewer
  include Cheri::Swing
  
  def title
    "#{@instance.name}: #{@value.clazz}"
  end
  def title_tree
    "#{@value.clazz}" 
  end
  def title_tab
    "#{@instance.name}: #{@value.clazz}"
  end
  def icon
    ObjectIcon  
  end
  def leaf?
    true  
  end

  def content_section
    empty_row
    value_section
    if @value.vars
      empty_row
      variables_section
      last_row(@icols)
    else
      last_row(@vcols)
    end
    empty_row true
  end
  
  def value_section
    idcol = ColDef.new(NColor,nil,NFont,VColor,nil,CFont)
    typecol = ColDef.new(NColor,nil,NFont,VColor,nil,CFont)
    valcol = ColDef.new(NColor,nil,NFont,VColor,TColor,VFont,true,10000)    

    @vcols = [idcol,typecol,valcol]
    @vsec = x_box do
      init_cols(*@vcols)
      align :LEFT,:TOP
    end
    header_row(@vcols,HdrId,HdrType,HdrValue)
    value_row(@vcols,@value.id.to_s,@value.clazz,@value.value)  
  end
  
  def variables_section
    return unless (vars = value.vars)
    idcol = ColDef.new(NColor,nil,NFont,VColor,nil,CFont)
    namecol = ColDef.new(NColor,nil,NFont,VColor,nil,IFont)
    typecol = ColDef.new(NColor,nil,NFont,VColor,nil,CFont)
    valcol = ColDef.new(NColor,nil,NFont,VColor,TColor,VFont)

    @icols = [idcol,namecol,typecol,valcol]
    @isec = x_box do
      init_cols(*@icols)
      align :LEFT,:TOP
    end
    header_row(@icols,HdrId,HdrVarName,HdrType,HdrValue)
    vars.each do |name,type,value,id|
      idcol.clk = id
      namecol.clk = id
      value_row(@icols,id.to_s,name,type,value) 
    end   
  end

  def send_selection(id,new_tab=nil)
    @main.show_linked_object(self,id,new_tab)
  end

  def mouse_clicked(e,id)
    send_selection(id,(e.modifiers_ex & SHIFT) == SHIFT)
  end

  def mouse_action(e,id)
    if e.popup_trigger?
      @menu_pending = id
      selection_popup.show(e.component,e.x,e.y)
    end
  end
  
  def menu_selection(new_tab)
    if id = @menu_pending
      @menu_pending = nil
      send_selection(id,new_tab)
    end
  end
  
  def selection_popup
    @popup ||= popup_menu 'Open item in ... ' do
      menu_item 'Open in new tab' do
        on_click {menu_selection true}
      end
      menu_item 'Open in default tab' do
        on_click {menu_selection false}
      end
    end  
  end
  
  
  def view(&block)
    @view ||= scroll_pane do
      align :LEFT
      @top_view = y_panel do
        align :LEFT
        empty_border 4,4,4,4
        background :WHITE
        title_section title
        content_section
      end
    end
  end

end #NavObjectViewer

class NavModuleViewer
  include ViewerInterface
  include ValueViewerInterface
  include ParentViewerInterface
  include NavViewer
  include Cheri::Swing
  include DRbHelper
  #:stopdoc:
  SuperClazz = 'Superclass'.freeze
  Ancestors = 'Ancestors'.freeze
  HdrAncName = 'Ancestor name'.freeze
  HdrPubClsMeth = 'Public class methods'.freeze
  HdrPubInsMeth = 'Public instance methods'.freeze
  HdrProClsMeth = 'Protected class methods'.freeze
  HdrProInsMeth = 'Protected instance methods'.freeze
  HdrPriClsMeth = 'Private class methods'.freeze
  HdrPriInsMeth = 'Private instance methods'.freeze
  #:startdoc:
  

  def title
    "#{@instance.name}: #{@value.qname.empty? ? @value.value : @value.qname}"
  end
  def title_tree
    "#{@value.name}" 
  end
  def title_tab
    "#{@instance.name}: #{@value.name.empty? ? @value.value : @value.name}"
  end
  def icon
    ModuleIcon  
  end
  def leaf?
    false  
  end

  def content_section
    val = @value
    header_section
    empty_row
    if (anc = val.ancestors) && (first = anc.first)
      anc.shift if first.id == val.id && first.value == val.qname
    end
    if anc && !anc.empty?
      ancestor_section    
      empty_row
    end
    if val.vars
      variables_section
      empty_row
    end
    methods_section
    last_row @last_cols
    empty_row true
  end
  
  def header_section
    namecol = ColDef.new(NColor,nil,NFont,NColor,nil,NFont)
    valcol = ColDef.new(VColor,nil,CFont,VColor,nil,CFont)

    @hcols = [namecol,valcol]
    @hsec = x_box do
      init_cols(*@hcols)
      align :LEFT,:TOP
    end
    val = @value
    header_row(@hcols,val.clazz, val.qname.empty? ? val.value : val.qname)  
    header_row(@hcols,HdrId,val.id.to_s)
    if (sc = val.superclazz)
      header_row(@hcols,SuperClazz,sc)    
    end
    @last_cols = @hcols
  end

  def ancestor_section
    idcol = ColDef.new(NColor,nil,NFont,VColor,nil,CFont)
    namecol = ColDef.new(NColor,nil,NFont,VColor,nil,CFont)
    typecol = ColDef.new(NColor,nil,NFont,VColor,nil,CFont)

    @acols = [idcol,namecol,typecol]
    @asec = x_box do
      init_cols(*@acols)
      align :LEFT,:TOP
    end
    header_row(@acols,HdrId,HdrAncName,HdrType)
    @value.ancestors.each do |name,type,id|
      idcol.clk = id
      namecol.clk = id
      value_row(@acols,id.to_s,name,type)   
    end
    @last_cols = @acols
  end

  def variables_section
    return unless (vars = value.vars)
    idcol = ColDef.new(NColor,nil,NFont,VColor,nil,CFont)
    namecol = ColDef.new(NColor,nil,NFont,VColor,nil,IFont)
    typecol = ColDef.new(NColor,nil,NFont,VColor,nil,CFont)
    valcol = ColDef.new(NColor,nil,NFont,VColor,TColor,VFont)

    @icols = [idcol,namecol,typecol,valcol]
    @isec = x_box do
      init_cols(*@icols)
      align :LEFT,:TOP
    end
    header_row(@icols,HdrId,HdrVarName,HdrType,HdrValue)
    vars.each do |name,type,value,id|
      idcol.clk = id
      namecol.clk = id
      value = value + '...' if value.length == 100
      value_row(@icols,id.to_s,name,type,value) 
    end   
    @last_cols = @icols
  end
  
  def methods_section
    return unless (meths = @methods ||= proxy.module_methods(@value.qname,@value.id))
    coldef = ColDef.new(NColor,nil,NFont,VColor,nil,VFont)

    @mcols = [coldef]
    @msec = x_box do
      init_cols(*@mcols)
      align :LEFT,:TOP
    end
    if (ms = meths.pub) && !ms.empty?
      header_row(@mcols,HdrPubClsMeth)
      ms.sort.each do |m|
        value_row(@mcols,m)
      end
    end
    if (ms = meths.pub_inst) && !ms.empty?
      header_row(@mcols,HdrPubInsMeth)
      ms.sort.each do |m|
        value_row(@mcols,m)
      end
    end
    if (ms = meths.pro) && !ms.empty?
      header_row(@mcols,HdrProClsMeth)
      ms.sort.each do |m|
        value_row(@mcols,m)
      end
    end
    if (ms = meths.pro_inst) && !ms.empty?
      header_row(@mcols,HdrProInsMeth)
      ms.sort.each do |m|
        value_row(@mcols,m)
      end
    end
    if (ms = meths.pri) && !ms.empty?
      header_row(@mcols,HdrPriClsMeth)
      ms.sort.each do |m|
        value_row(@mcols,m)
      end
    end
    if (ms = meths.pri_inst) && !ms.empty?
      header_row(@mcols, HdrPriInsMeth)
      ms.sort.each do |m|
        value_row(@mcols,m)
      end
    end
    @last_cols = @mcols
  end
  
  Cls = 'Class'.freeze #:nodoc:
  Mod = 'Module'.freeze #:nodoc:
  def load_children
    recs = drb_to_array(proxy.const_recs(value.qname)).sort
    children = []
    recs.each do |rec|
      ntv = case rec.clazz
        when Cls : NodeTypeValue.new(Class,rec.value,rec)
        when Mod : NodeTypeValue.new(Module,rec.value,rec)
        else NodeTypeValue.new(:constant,rec.clazz,rec)
      end
      children << ntv
    end
    @children = children
  end
  
  def children_loaded?
    @children  
  end

  def send_selection(id,new_tab=nil)
    @main.show_linked_object(self,id,new_tab)
  end

  def mouse_clicked(e,id)
    send_selection(id,(e.modifiers_ex & SHIFT) == SHIFT)
  end

  def mouse_action(e,id)
    if e.popup_trigger?
      @menu_pending = id
      selection_popup.show(e.component,e.x,e.y)
    end
  end
  
  def menu_selection(new_tab)
    if id = @menu_pending
      @menu_pending = nil
      send_selection(id,new_tab)
    end
  end
  
  def selection_popup
    @popup ||= popup_menu 'Open item in ... ' do
      menu_item 'Open in new tab' do
        on_click {menu_selection true}
      end
      menu_item 'Open in default tab' do
        on_click {menu_selection false}
      end
    end  
  end
  
  
  def view(&block)
    @view ||= scroll_pane do
      align :LEFT
      @top_view = y_panel do
        align :LEFT
        empty_border 4,4,4,4
        background :WHITE
        title_section title
        content_section
      end
    end
  end

end

class NavClassViewer < NavModuleViewer

  def icon
    ClassIcon  
  end

end


register_viewer(:root_node,nil,RootNodeViewer)
register_viewer(:ruby_instance,nil,RubyInstanceViewer)
register_viewer(:jruby_instance,nil,JRubyInstanceViewer)
register_viewer(:env,nil,EnvViewer)
register_viewer(:env_java,nil,JavaEnvViewer)
register_viewer(:global_vars,nil,GlobalVariablesViewer)
register_viewer(:global_const,nil,ConstantsViewer)
register_viewer(:config,nil,ConfigViewer)
#register_viewer(:object,nil,ObjectViewer)
register_viewer(:object,nil,NavObjectViewer)
register_viewer(:constant,nil,ConstantViewer)
#register_viewer(Class,nil,ClassViewer)
#register_viewer(Module,nil,ModuleViewer)
register_viewer(Class,nil,NavClassViewer)
register_viewer(Module,nil,NavModuleViewer)
register_viewer(:results,nil,ResultListViewer)


end #Explorer
end #JRuby
end #Cheri
