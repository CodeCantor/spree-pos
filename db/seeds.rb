# Create a new shipping method used by the POS for using in shipping
sm = Spree::ShippingMethod.new({
  name: 'At Store',
  display_on: 'back_end',
  tracking_url: '',
})
sm.shipping_categories << Spree::ShippingCategory.find(2)

# Using flatrate calculator if not some problems I am having
sm.calculator = Spree::Calculator::Shipping::FlatRate.new()
sm.save!
