require 'rubygems'
require 'cheri/swing'

include Cheri::Swing

frame = swing {

  bgcolor = color(240,238,220)
  
  column_headings = ['SKU','Product Name','Quantity','Unit Price','Total Price'].to_java
  data = [
    ['123-456-789','Foo',3,2.75,3*2.75],
    ['123-456-790','Foo Plus',5,3.75,5*3.75],
    ['555-867-5309','Super Foo',2,9.27,2*9.27],
    ['987-654-321','Foo for Bars',4,7.99,4*7.99]
  ].to_java

  frame('Table Demo 1') { |frm| size 500, 375
    content_pane { background  bgcolor; box_layout frm, :Y_AXIS
      bevel_border :RAISED }
    on_window_closing { frame.dispose }
    menu_bar { background bgcolor
      menu("File") {  mnemonic :VK_F; background :WHITE
        menu_item("Exit") { mnemonic :VK_X; background :WHITE
          on_click { frame.dispose }
        }
    } }
    y_panel { background bgcolor
      compound_border(titled_border('Current Order Items') {
        etched_border :LOWERED }, empty_border( 7,7,7,7) )
      scroll_pane(
        @my_table = table(data,column_headings) {
          get_table_header {
            background :BLUE; foreground :WHITE;
            font('Dialog',:BOLD,12)
          }
      }) {
        get_viewport { background :WHITE }
      }
    }
  }
}

frame.show  