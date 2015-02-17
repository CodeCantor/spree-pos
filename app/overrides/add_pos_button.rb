Deface::Override.new(:virtual_path => "spree/admin/shared/_order_tabs",
                     :name => "add_pos_button",
                     insert_bottom: '[data-hook="admin_order_tabs"]',
                     :partial => "spree/admin/orders/pos_button",
                     :disabled => false)