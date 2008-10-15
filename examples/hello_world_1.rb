require 'rubygems'
require 'cheri/swing'

include Cheri::Swing

frame = swing {

  frame('Hello World Demo 1') { |obj| size 320, 240
    box_layout obj,:Y_AXIS
    content_pane { background :RED }
    on_window_closing { frame.dispose }
    menu_bar { 
      menu('File') {  mnemonic :VK_F; background :WHITE
        menu_item('Exit') { mnemonic :VK_X; background :WHITE
          on_click { frame.dispose }
        }
      }
    }
    y_glue
    x_panel { background :WHITE 
      label('Hello, World!') {  foreground :BLUE }
    }
    y_glue
  }
}

frame.show

