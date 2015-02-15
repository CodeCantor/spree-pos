module SpreePos

  class Engine < Rails::Engine
    engine_name 'spree_pos'

    config.autoload_paths += %W(#{config.root}/lib)
    config.assets.precompile += %w(admin/pos/refund/all.css admin/pos/refund/all.js)

    initializer "spree.spree_pos.preferences", :after => "spree.environment" do |app|
      SpreePos::Config = SpreePos::Configuration.new
    end

    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), '../../app/**/*_decorator*.rb')) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end
      Dir.glob(File.join(File.dirname(__FILE__), '../../app/overrides/*.rb')) do |c|
        Rails.configuration.cache_classes ? require(c) : load(c)
      end
      Spree::Product.class_eval do
        delegate_belongs_to :master, :ean
      end
    end
    initializer "spree.paypal_express.payment_methods", :after => "spree.register.payment_methods" do |app|
      app.config.spree.payment_methods << Spree::PaymentMethod::MoneyPos
      app.config.spree.payment_methods << Spree::PaymentMethod::CreditCardPos
    end

    config.to_prepare &method(:activate).to_proc
  end
end
