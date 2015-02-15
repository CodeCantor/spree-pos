class Spree::Admin::PrintCouponController < Spree::Admin::BaseController
  require 'barby'
  require 'barby/barcode/code_128'
  require 'barby/outputter/png_outputter'

  layout 'spree/admin/layouts/receipt'

  def print
    @coupon = Spree::Promotion.find_by code: params[:coupon_code]
    @calculator = @coupon.actions.first.calculator
    @coupon_amount = @calculator.try(:preferred_amount)
    @coupon_amount = @calculator.preferred_percent unless @coupon_amount
    create_barcode
  end

  protected
  def create_barcode
    @barcode_full_path = "#{Rails.public_path}/#{@coupon.code}.png"
    @barcode = Barby::Code128B.new(@coupon.code)
    File.open(@barcode_full_path, 'w'){|f| f.write @barcode.to_png }
  end
end
