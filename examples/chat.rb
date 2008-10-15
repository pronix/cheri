# note: intentionally reproducing layout of Profligacy example for comparison

require 'rubygems'
require 'cheri/swing'

class ChatApp
  include Cheri::Swing
  Enter = java.awt.event.KeyEvent::VK_ENTER
  EventQueue = java.awt.EventQueue

  def initialize
    swing[:auto]
    @frame = frame 'Cheri::Swing: grid_table (GridBagLayout) example' do |f|
      size 800,600
      box_layout f, :X_AXIS
      empty_border 4,4,4,4
      on_window_closing {@frame.dispose}
      grid_table do
        grid_row :insets=>[6,6,6,6] do
          label('The chat:', :weightx=>0.7,:anchor=>:north) { font 'Dialog', :BOLD, 20 }
          label('The people:', :wx=>0.3,:a=>:n) { font 'Dialog', :BOLD, 20 }
        end
        grid_row :i=>6, :wy=>0.01 do
          scroll_pane :fill=>:both do
            bevel_border :RAISED; minimum_size 200,100
            @chat = text_area { text "[You]: Hello, you look familiar..."; editable false }
          end
          list ['Me','You'].to_java, :f=>:both do
            bevel_border :LOWERED; minimum_size 100,100
          end
        end
        grid_row { label "What you're saying:",:a=>:sw,:wy=>0 }
        grid_row :wy=>0 do
          @text = text_field(:a=>:w,:f=>:horizontal,:i=>[6,2]) {bevel_border :LOWERED
            # send current text if enter is pressed
            on_key_pressed {|e| send_later if e.key_code == Enter }
          }
          grid_table :a=>:se, :f=>:h do
            defaults :i=>[6,2], :wx=>0.1
            grid_row :f=>:h do
              button('Send', :a=>:sw) {on_click { send_msg }}
              button('Love', :a=>:s) {on_click { send_msg :You, 'Oh, baby!'}}
              button('Quit', :a=>:se) {on_click{ @frame.dispose }}
            end
          end
        end
      end
    end
    @frame.visible = true
  end
  
  def send_msg(sender=:Me,text=nil)
    @chat.text += "\n[#{sender}]: " + (text || @text.text)
    @text.text = '' if sender == :Me
  end

  def send_later(*args)
    # procs as Runnables not supported in JRuby 1.0.x (there's another way, won't show here)
    EventQueue.invoke_later(proc {send_msg(*args)}) unless JRUBY_VERSION =~ /^1.0/
  end
end

ChatApp.new