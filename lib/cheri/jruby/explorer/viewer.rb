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

# registered viewers
@viewers = {}
class << self
  # TODO: interface for registering sub[-sub]* types - TypeViewer class does support it
  # TODO: allow multiple viewer registrations for a type[/subtype] - user
  # could switch via View menu or popup
  def register_viewer(type,subtype,clazz)
    raise Cheri.new_type_error(type,Symbol,Class) unless Symbol === type || Class === type
    raise Cheri.new_type_error(clazz,Class) unless Class === clazz
    if subtype
      raise Cheri.new_type_error(subtype,Class,Symbol) unless Symbol === subtype || Class === subtype
    end
    if (tv = @viewers[type])
      if subtype
        sv = tv[subtype]
        if sv
          warn "replacing viewer for type #{type}/#{subtype} (#{sv.clazz}) with #{clazz}" if sv.clazz
          sv.clazz = clazz
        else
          tv[subtype] = TypeViewer.new(subtype,clazz)
        end
      else
        warn "replacing default viewer for type #{type} (#{tv.clazz}) with #{clazz}" if tv.clazz
        tv.clazz = clazz
      end
    else
      if subtype
        #warn "adding viewer for type #{type}/#{subtype} when no default viewer for #{type}"
        tv = TypeViewer.new(type,nil)
        tv[subtype] = TypeViewer.new(subtype,clazz)
        @viewers[type] = tv
      else
        @viewers[type] = TypeViewer.new(type,clazz)
      end      
    end
  end
  def viewer(type,subtype=nil)
    raise Cheri.new_type_error(type,Symbol,Class) unless Symbol === type || Class === type
    raise Cheri.new_type_error(subtype,Symbol,Class,String) unless subtype.nil? ||
        Symbol === subtype || Class === subtype || String === subtype
    unless (tv = @viewers[type])
      warn "no viewer found matching type: #{type} (#{subtype})"
      return
    end
    if subtype
      sv = tv[subtype]
      # TODO: silently return default?
      #warn "no viewer for subtype #{type}/#{subtype} - returning default for type" unless sv
      sv || tv
    else
      tv
    end
  end

end #self

class TypeViewer
  def initialize(type,clazz)
    raise Cheri.new_type_error(type,Symbol,Class) unless Symbol === type || Class === type
    raise Cheri.new_type_error(clazz,Class) unless clazz.nil? || Class === clazz
    @t = type
    @c = clazz if clazz
  end
  def type
    @t  
  end
  def clazz
    @c  
  end
  def clazz=(c)
    raise Cheri.new_type_error(c,Class) unless Class === c
    @c = c
  end
  def subtypes
    @s  
  end
  def []=(type,type_viewer)
    raise Cheri.new_type_error(type,Symbol,Class) unless Symbol === type || Class === type
    raise Cheri.new_type_error(type_viewer,TypeViewer) unless TypeViewer === type_viewer
    (@s ||= {})[type] = type_viewer
  end
  def [](type)
    raise Cheri.new_type_error(type,Symbol,Class,String) unless Symbol === type ||
        Class === type || String === type
    @s ? @s[type] : nil
  end
  
  # convenience method for instantiating +clazz+
  def new(*r)
    @c.new(*r) if @c
  end
end #TypeViewer


class NodeType
  def initialize(type,subtype=nil)
    @t = type
    @s = subtype if subtype
  end
  def type
    @t  
  end
  def subtype
    @s  
  end
end
class NodeTypeValue < NodeType
  def initialize(type,subtype,value)
    super(type,subtype)
    @v = value if value
  end
  def value
    @v  
  end
end

module ViewerInterface
  def initialize(node_type,main,instance,*r)
    @type = node_type
    @main = main
    @instance = instance  
  end

  # The node type of this viewer
  def type
    @type  
  end

  def main
    @main  
  end
  
  def instance
    @instance  
  end

  def proxy
    @instance.proxy  
  end
  
  def title
    @title
  end
  
  def title_tree
    title  
  end

  def title_tab
    title  
  end

  def icon
    @icon
  end

  def icon_tree
    icon  
  end

  def icon_tab
    icon  
  end

  def tooltip
    @tooltip
  end
  
  def leaf?
    false  
  end

  def view(&block)
    if @view
      @view.put_client_property(:viewer,self)
      cheri_yield(@view,&block) if block
      @view
    end
  end

  def refresh
  end

  def tab(&block)
    @tab ||= x_panel do
      opaque false
      label icon_tab
      x_spacer 2
      label title_tab
      x_spacer 10
      button CloseTabDimIcon do
        rollover_icon CloseTabIcon
        fixed_size 12,12
        tool_tip_text 'Close'
        content_area_filled false
        border_painted false
        on_click { close_view }
      end
    end
    cheri_yield @tab, &block if block_given?
    @tab
  end
  
  def close_view
    @main.close_view(self)
  end

end #ViewerInterface

module ValueViewerInterface
  def initialize(node_type,main,instance,value,*r)
    super
    @value = value  
  end
  def value
    @value  
  end
end

module ParentViewerInterface
  def children
    @children
  end

  def children_loaded?
  end

  def load_children  
  end

  def leaf?
    false  
  end
  
end

class Viewer
  include ViewerInterface
  include Cheri::Swing

  def initialize(*r)
    super
    swing[:auto => true]
  end
  
end

class HtmlViewer < Viewer
  include Cheri::Html
  TblWidth = '98%'
  TColor = '#080080'
  HtmlStyle = %q[
    .method { font-family: monospaced, courier; font-size: medium }
    .oid { font-family: monospaced, courier; }
    .var { font-family: monospaced, courier; font-weight: bold }
    .val { font-family: monospaced, courier; color: #000080 }
    .hdr { font-family: sans-serif; font-size: large; font-weight: bold; color: #000080 }
    body { font-family: sans-serif; }
  ]
  ContType = 'text/html'.freeze
  
  def html_style
    HtmlStyle 
  end

  def view(&block)
    @view ||= scroll_pane do
      align :LEFT
      @html_view = editor_pane do
        editable false
        content_type ContType
        html_document
      end
    end
    super
  end

  def html_document
    html do
      head do
        style html_style          
      end
      # TODO: body attrs should be in style sheet
      body :bgcolor => :white do
        div :align => :left do
          html_heading
          html_content            
        end 
      end         
    end
  
  end

  def html_heading
    html_title
  end
  
  def html_title
    table :width => TblWidth, :cellspacing => 2, :cellpadding => 2, :border => 0 do
      tr do 
        td esc(title), :class => :hdr, :align => :left, :colspan=> 2
      end
    end
    #h2 title, :align => :left, :text => TColor
  end
  
  def html_content
  end

  def refresh
    cheri_yield @html_view do
      html_document
    end
  end
end

class HtmlTableViewer < HtmlViewer
  def html_content
    table :width => TblWidth, :cellspacing => 2, :cellpadding => 2, :border => 0 do
      table_rows
      nil
    end
  end

  def table_rows
  end
  
  def empty_row
    tr td('&nbsp;')  
  end
  
end

class HtmlNameValueListViewer < HtmlTableViewer
  HColor = '#f0faff'.freeze
  NColor = '#f0e2e0'.freeze
  VColor = '#f0f0f0'.freeze
  Right = 'right'.freeze
  Top = 'top'.freeze

  def name_value_row(name,value)
   v = tr do
      th name, :align => :left, :valign => Top, :width=> 160, :bgcolor => NColor
      td value, :bgcolor => VColor, :class => :val
      nil
    end
    v
  end

  def name_type_value_row(name,type,value)
    tr do
      th name, :class => :var, :align => :left, :valign => Top, :width=> 120, :bgcolor => NColor
      td type, :bgcolor => VColor, :valign => Top
      td value, :bgcolor => VColor, :class => :val
      nil
    end  
  end

  def name_type_id_value_row(name,type,id,value)
    tr do
      td name, :class => :var, :valign => Top, :width=> 120, :bgcolor => VColor
      td type, :bgcolor => VColor, :valign => Top
      td id, :bgcolor => VColor, :align => Right, :valign => Top, :width => 20, :class => :oid
      td value, :bgcolor => VColor, :class => :val
      nil
    end  
  end

  def type_id_value_row(type,id,value)
    tr do
      td type, :bgcolor => VColor, :valign => Top
      td id, :bgcolor => VColor, :align => Right, :valign => Top, :width => 20, :class => :oid
      td value, :bgcolor => VColor, :class => :val
      nil
    end  
  end

  def id_value_row(type,id,value)
    tr do
      td id, :bgcolor => VColor, :align => Right, :valign => Top, :width => 20, :class => :oid
      td value, :bgcolor => VColor, :class => :val
      nil
    end  
  end

  def value_list(value_array)
    table do
      value_array.each do |value|
        tr td(esc(value))      
      end
      nil
    end  
  end

end #HtmlNameValueListViewer


module NavViewerConstants
  Color = ::Java::JavaAwt::Color
  Font = ::Java::JavaAwt::Font
  TColor = Color.new(0,0,0x80)
  NColor = Color.new(0xf0,0xe2,0xe0)
  VColor = Color.new(0xf0,0xf0,0xf0)
  HColor = Color.new(0xd0,0xe0,0xff)
  TFont = Font.new('Dialog',Font::BOLD,18)
  NFont = Font.new('Dialog',Font::BOLD,14)
  VFont = Font.new('Monospaced',Font::PLAIN,14)
  IFont = Font.new('Monospaced',Font::BOLD,14)
  CFont = Font.new('Dialog',Font::PLAIN,14)
  ResFont = Font.new('Monospaced',Font::PLAIN,12)
  MouseEvent = ::Java::JavaAwtEvent::MouseEvent
  BUTTON1 = MouseEvent::BUTTON1
  BUTTON2 = MouseEvent::BUTTON2
  BUTTON3 = MouseEvent::BUTTON3
  SHIFT = MouseEvent::SHIFT_DOWN_MASK
  HdrName = 'Name'.freeze
  HdrVarName = 'Variable name'.freeze
  HdrType = 'Type'.freeze
  HdrId = 'Id'.freeze
  HdrValue = 'Value'.freeze
end

module NavViewer
  include NavViewerConstants

  class ColDef
    attr :col, true
    attr :hbg, true
    attr :hfg, true
    attr :hfont, true
    attr :dbg, true
    attr :dfg, true
    attr :dfont, true
    attr :dtext, true
    attr :maxh, true
    attr :clk, true
    def initialize(hbg,hfg,hfont,dbg,dfg,dfont,dtext=nil,maxh=nil)
      @hbg = hbg if hbg
      @hfg = hfg if hfg
      @hfont = hfont if hfont
      @dbg = dbg if dbg
      @dfg = dfg if dfg
      @dfont = dfont if dfont
      @dtext = dtext if dtext
      @maxh = maxh if maxh
    end
  end

  def initialize(*r)
    super
    swing[:auto]
  end
  
  def title_section(title)
    x_box do
      align :LEFT
      label title do
        align :LEFT
        set_font TFont
        foreground TColor
      end
      x_spacer 2
    end
  end
  
  def init_cols(*coldefs)
    coldefs.each do |cd|
      cd.col = y_panel do
        align :LEFT,:TOP
        opaque false
      end
    end
  end

  def last_row(cols)
    cols.each do |col|
      cheri_yield col.col do
        y_glue
      end    
    end  
  end
  
  def header_row(cols,*labels)
    last = labels.length - 1
    labels.length.times do |i|
      col = cols[i] || cols.last
      cheri_yield col.col do
        x_panel do
          align :LEFT,:TOP
          background col.hbg || NColor
          maximum_size 1000, 24
          x_spacer 2
          label labels[i] do
            align :LEFT,:TOP
            set_font col.hfont || NFont
            foreground col.hfg if col.hfg
          end
          x_spacer 2
          x_glue if i == last
        end
        x_spacer 1
        y_spacer 2
      end
    end
    cheri_yield cols.last.col do
      x_glue    
    end
    y_spacer 2
  end

  def value_row(cols,*values) 
    last = values.length - 1
    values.length.times do |i|
      col = cols[i] || cols.last
      cheri_yield col.col do
        #y_glue
        x_panel do
          align :LEFT,:TOP
          background col.dbg || VColor
          maximum_size 1000,col.maxh || 24
          x_spacer 2
          if col.clk
            on_mouse_entered do |e|
              e.source.background = HColor
            end
            on_mouse_exited do |e|
              e.source.background = VColor
            end
          end
          if col.dtext
            text_area do
              align :LEFT,:TOP
              editable false
              line_wrap true
              set_font col.dfont || VFont
              background col.dbg || VColor
              foreground col.dfg if col.dfg
              text values[i]
            end
          else
            label values[i] do
              align :LEFT,:TOP
              set_font col.dfont || VFont
              foreground col.dfg if col.dfg
              if (click_val = col.clk)
                on_mouse_entered do |e|
                  e.source.parent.background = HColor
                end
                on_mouse_exited do |e|
                  e.source.parent.background = VColor
                end
                on_mouse_clicked   {|e| mouse_clicked(e,click_val) }
                on_mouse_pressed   {|e| mouse_action(e,click_val) }
                on_mouse_released  {|e| mouse_action(e,click_val) }
              end
            end
          end
          x_spacer 2
          x_glue if i == last
        end
        x_spacer 1
        y_spacer 2
      end
    end
    cheri_yield cols.last.col do
      x_glue    
    end
    y_spacer 2
  end

  def empty_row(glue=nil)
    x_box do
      align :LEFT,:TOP
      spacer 1,12
    end
    y_glue if glue
  end
  
  def mouse_clicked(e,val=nil)
  end
  
  def mouse_action(e,val=nil)
  end
  
end

module DRbHelper
  # work around DRb (or possibly JRuby) issue iterating pseudo-array.
  # TODO: need a client-side proxy for error handling and issues like this.
  def drb_to_array(maybe_array)
    return maybe_array if Array === maybe_array
    Array.new(maybe_array.length) {|i| maybe_array[i]}
  end

end

end #Explorer
end #JRuby
end #Cheri
