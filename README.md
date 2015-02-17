SUMMARY
-------

A Point Of Sale (POS) screen for Spree.

POS screen hooks into the Admin Tabs and is meant to be used to sell inside a shop, possibly with a touchscreen and a scanner. Allows for quick checkout and basic adjustment of line item prices also with discount percentages.


Features
--------
 * Input field for find items by sku/ean
 * Print receipts of the order
 * Do discounts directly from the interface
 * Change calculator
 * Label printing
 * Flag orders as sold in pos
 * Page for searching products

How to use
----------

A minimal transaction is one scan, and pressing of print button.

Basic bar scanner input (sku/ean search) or search by name. No Customer, no shipping, no coupons, but these are achievable through the order interface.

POS creates orders (just like the admin/order) and in fact lets you switch between the two views freely by adding links back and forth. Pressing new customer will create a new order (in checkout), which is finalised when print is pressed. ONLY pressing print will finalise the order, if you do not press print (ie press new customer) the order will be left
 in "checkout" state and thus not be a sale in your system.

Installation
------------

The best way for using this software is by adding this code to your Gemfile:

```shell
gem "spree_pos", :git => "git://github.com/CodeCantor/spree-pos.git"
gem "spree_html_invoice", :git => "git://github.com/CodeCantor/spree-html-invoice.git"
```

For installing the assets needed and creating the default objects run this command:

```shell
rails generate spree_pos:install
```

Continue reading the configuration section for see how to finish the setup.

Configure
--------
**IMPORTANT**: You have to config the shipping method with the zone of the ship address in the pos.

By default, the address chosen by the pos, will be the one setted to the current user logged. You can config this address changing this options:

  * Ship Address: You can config this options setting :pos_ship_address to the id of the Spree::Address you would like to use.
  * Bill Address: You can config this options setting :pos_bill_address to the id of the Spree::Address you would like to use. By default it will use :ship_address if not set

If you would like to use an other shipping method you can change it using, :pos_shipping_method. By default, it will take 'At Store' with a flat rate.

You can also change the invoice generator url, in wich the pos will redirect after pressing the print button:

  * Pos printing: Change the option :pos_printing to the url you would like to use after pressing print.

If you change this option, the spree_html_invoice gem is not longer required.

What is the EAN?
---------------

Many sales and especially POS systems rely on barcode scanning. A barcode scanner functions identical to keyboard
input  to the product code. You may use the sku field for this but we use that for the suppliers code (or our own).

So there is a migration supplied that provides a ean (European Article code, may be upc too) for the Variant class, and fields to edit it and search by it.


TO-DO
-----
 * Move all texts to SpreePos::Config or to locale files
 * Fix creation of "At store" shipping method in seeds
 * TESTS !!!
 * Being able to assign a user directly to an order directly from the interface for later invoice printing.
 * Do ease the mechanism for devolutions
 * Refactor the view so it has the calculator prettier
 * Being able to use promotions from this interface
 * Create a report with the information of the day sells
 * Recover funcionality for add stock directly from pos

Copyright (c) 2011 [Torsten Ruger], released under the New BSD License
Copyright (c) 2013 [Enrique Alvarez (enrique at codecantor dot com)], released under the New BSD License
