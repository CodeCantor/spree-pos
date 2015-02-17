class Spree::Admin::RefundController < Spree::Admin::BaseController
  layout 'spree/admin/layouts/refund'

  def select_order
    @reasons = Spree::ReturnAuthorizationReason.active
    @stock_locations = Spree::StockLocation.active
  end

  def select_items
    @order = Spree::Order.find_by(number: params[:order_number])
    if @order
      @order.return_authorizations.select(&:can_cancel?).map(&:cancel) if @order.return_authorizations.count > 0
      @return_authorization = Spree::ReturnAuthorization.create(order: @order, 
          return_authorization_reason_id: params[:reason_id],
          stock_location_id: params[:stock_location_id])
      
      unless @return_authorization.valid?
        flash[:error] = @return_authorization.errors.full_messages.join("; ")
        redirect_to action: :select_order
      end

      if @order.state == 'complete'
        @variants = @order.variants
      else
        flash[:error] = "This order can't be refund because is in state #{@order.state}"
        redirect_to action: :select_order
      end
    else
      flash[:error] = 'The order number is has not been found'
      redirect_to action: :select_order
    end
  end

  def create_refund
    @order = Spree::Order.find_by(number: params[:order_number])
    @return_authorization = Spree::ReturnAuthorization.find_by(number: params[:rma])
    @coupon_amount = params[:coupon_amount].try(&:to_f)
    @coupon_description = params[:coupon_description]

    if @coupon_amount && @coupon_amount > 0
      create_discount_coupon  "#{@return_authorization.number}NI", @coupon_amount, @coupon_description, "REFUND #{@order.number}"
      @return_authorization.reason = "POS refund. Create coupon #{@coupon.code} with the amount #{params[:coupon_amount]}"
      @return_authorization.stock_location_id = params[:stock_location_id]
    end

    (params[:return_quantity] || []).each { |variant_id, qty| @return_authorization.add_variant(variant_id.to_i, qty.to_i) }
    @return_authorization.receive
  end

  def select_coupon

  end

  def create_coupon
    amount = params[:coupon_amount].to_f
    description = params[:coupon_description]
    create_discount_coupon(Spree::Promotion.random_code, amount, description, 'Coupon pos')
    redirect_to "/admin/print_coupon/#{@coupon.code}"
  end

  protected
  def create_discount_coupon(code, amount, description = nil, name = nil)
    @coupon = Spree::Promotion.create(name: name, usage_limit: 1)
    @coupon.description = description unless description.try(&:empty?)
    @coupon.code = code
    action = @coupon.actions.build(type: 'Spree::Promotion::Actions::CreateAdjustment')
    calculator = Spree::Calculator::FlatRate.create
    action.calculator = calculator
    @coupon.save!
    calculator.preferred_amount = amount
    calculator.save!
  end
end