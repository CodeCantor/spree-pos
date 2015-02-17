class Spree::Admin::PosController < Spree::Admin::BaseController
  include Spree::Core::ControllerHelpers::Order

  before_filter :get_order , :except => [:new, :report]

  def get_order
    order_number = params[:number]
    @order = Spree::Order.find_by_number(order_number)
    raise "No order found for -#{order_number}-" unless @order
  end

  def payment
    if @order.state == "complete"
      redirect_to :action => :print and return
    end
    @payments = Spree::PaymentMethod.available(:pos)
    render layout: 'spree/admin/layouts/popup_pos'
  end

  def new

    begin
      unless params[:force] && spree_user_session[:pos_order]
        @order = Spree::Order.find spree_user_session[:pos_order]
      end

      unless @order.try(:cart?)
        init 
      end
    rescue ActiveRecord::RecordNotFound
      init
    end

    redirect_to :action => :show , :number => @order.number
  end

  def add
    if pid = params[:item]
      add_variant Spree::Variant.find pid


      flash.notice = t('product_added')
    end
    redirect_to :action => :show 
  end

  def remove
    if pid = params[:item]
      variant = Spree::Variant.find(pid)
      line_item = @order.line_items.find { |line_item| line_item.variant_id == variant.id }

      line_item.quantity -= 1
      if line_item.quantity == 0
        @order.line_items.delete line_item
      else
        line_item.save
      end
      flash.notice = t('product_removed') 
    end
    redirect_to :action => :show 
  end

  def apply_coupon
    @order.coupon_code = params[:coupon_code]
    handler = Spree::PromotionHandler::Coupon.new(@order).apply

    if handler.error.present?
      add_error handler.error
    elsif handler.success
      add_notice handler.success
    end
    redirect_to :action => :show
  end

  def print
    if @order.state != "complete"
      self.set_shipping_method
      @order.update_attributes(:pos_sell => true)
      unless @order.payment_ids.empty?
        @order.payments.first.delete unless @order.payments.first.amount == @order.total
      end
      if @order.payment_ids.empty?
        payment = Spree::Payment.new
        payment.payment_method = Spree::PaymentMethod.find params[:payment]
        payment.amount = @order.total
        payment.order = @order
        payment.save!
        payment.capture!
      end
      @order.state = "complete"
      @order.pos_know_website = ('true' == params[:pos_know_website])
      @order.pos_returning_user = ('true' == params[:pos_returning_user])
      @order.completed_at = Time.now
      @order.create_tax_charge!
      @order.finalize!
      @order.save!
      @order.shipments.map { |s| s.ship! }
    end
    url = SpreePos::Config[:pos_printing]
    url = url.sub("number" , @order.number.to_s)
    redirect_to url
  end
  
  def index
    redirect_to :action => :new 
  end
  
  def show

    # Here you can change the price manually
    if params[:price] && request.post?
      pid = params[:price].to_i
      item = @order.line_items.find { |line_item| line_item.id == pid }
      item.price = params["price#{pid}"].to_f
      item.save
      @order.reload # must be something cached in there, because it doesnt work without. shame.
      flash.notice = I18n.t("price_changed")
    end

    # Change the number of items
    if params[:quantity_id] && request.post?
      iid = params[:quantity_id].to_i
      item = @order.line_items.find { |line_item| line_item.id == iid }
      #TODO error handling
      item.quantity = params[:quantity].to_i
      item.save
      #TODO Hack to get the inventory to update. There must be a better way, but i'm lost in spree jungle
      item.variant.product.save
      @order.reload # must be something cached in there, because it doesnt work without. shame.
      flash.notice = I18n.t("quantity_changed") if item.valid?
      add_error I18n.t("no_enough_stock") unless item.sufficient_stock?
    end

    # Adding a discount
    if discount = params[:discount]
      if i_id = params[:item]
        item = @order.line_items.find { |line_item| line_item.id.to_s == i_id }
        item_discount( item , discount )
      else
        @order.line_items.each do |item|
          item_discount( item , discount )
        end
      end

      @order.reload # must be something cached in there, because it doesnt work without. shame.
    end

    if sku = params[:sku]
      prods = Spree::Variant.where(:sku => sku ).limit(2)
      if prods.length == 0 and Spree::Variant.instance_methods.include? "ean"
        prods = Spree::Variant.where(:ean => sku ).limit(2)
      end
      if prods.length == 1
        add_variant prods.first
      else
        redirect_to :action => :find , "q[product_name_cont]" => sku
        return
      end
    end

  end
  
  def item_discount item , discount
    item.price = item.variant.price * ( 1.0 - discount.to_f/100.0 )
    item.save!
  end
  
  def find
    init_search
    if params[:index]
      search = params[:q]
      search["name_cont"] = search["variants_including_master_sku_cont"]
      search["variants_including_master_sku_cont"] = nil
      init_search
    end
  end

  def report
    @payment_methods = Spree::PaymentMethod.all.each_with_object({}) { |pm,counts| counts[pm] = {} }

    params[:q] = {} unless params[:q]

    if params[:q][:updated_at_gt].blank?
      params[:q][:updated_at_gt] = Time.zone.now
    else
      params[:q][:updated_at_gt] = Time.zone.parse(params[:q][:updated_at_gt]) rescue Time.zone.now.beginning_of_month
    end

    if params[:q] && !params[:q][:updated_at_lt].blank?
      params[:q][:updated_at_lt] = Time.zone.parse(params[:q][:updated_at_lt]) rescue ''
    end

    params[:q][:s] ||= 'updated_at desc'

    @search = Spree::Payment.where(:state => 'completed').ransack(params[:q])
    @payment_methods.each do |pm,value|
      search = pm.payments.where(:state => 'completed').ransack(params[:q])
      payments = search.result
      value[:total] = Spree::Money.new(payments.map(&:amount).reduce(&:+), { :currency => 'EUR' }).money
    end
  end
  protected
  
  def add_notice no
    flash[:notice] = "" unless flash[:notice]
    flash[:notice] << no
  end

  def add_error no
    flash[:error] = "" unless flash[:error]
    flash[:error] << no
  end
  
  def init
    @order = Spree::Order.new(pos_sell: true)
    @order.associate_user!(spree_current_user)

    if SpreePos::Config[:pos_ship_address]
      ship_address = Spree::Address.find SpreePos::Config[:pos_ship_address]
      bill_address = Spree::Addess.find(SpreePos::Config[:pos_bill_address]) || bill_address
    elsif spree_current_user.ship_address
      ship_address = spree_current_user.ship_address
      bill_address = spree_current_user.bill_address || ship_address
    end
    
    @order.ship_address = ship_address
    @order.bill_address = bill_address
    
    @order.save!
    #method = Spree::ShippingMethod.find_by_name SpreePos::Config[:pos_shipping]
    #@order.shipping_method = method || Spree::ShippingMethod.first
    #@order.create_proposed_shipments
    spree_user_session[:pos_order] = @order.number
  end

  def add_variant variant, quantity = 1
    init unless @order
    # Using the same code as OrderContoller#populate
    options  = (params[:options] || {}).merge(currency: current_currency)
    @order.contents.add(variant, quantity, options)

    self.set_shipping_method
    @order.save!
  end

  def set_shipping_method
    # Calculate the shipments
    # TODO: Check stock location for be in the shop

    @order.create_proposed_shipments

    # Set shipping method as one named 'At Store'
    name_shipping = SpreePos::Config[:pos_shipping_method] || 'At Store'
    method = Spree::ShippingMethod.find_by_name name_shipping
    @order.shipments.map do |s| 
      sr = s.add_shipping_method(method, false)
      s.selected_shipping_rate_id = sr.id
    end
  end

  def init_search
    params[:q] ||= {}
    params[:q][:meta_sort] ||= "product_name asc"
    params[:q][:deleted_at_null] = "1"
    params[:q][:product_deleted_at_null] = "1"
    @search = Spree::Variant.ransack(params[:q])
    @variants = @search.result(:distinct => true).page(params[:page]).per(20)
  end

  def current_order
    @order
  end

end

