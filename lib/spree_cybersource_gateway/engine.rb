module SpreeCybersourceGateway
  class Engine < Rails::Engine
    require 'spree_core'
    engine_name 'spree_cybersource_gateway'
    isolate_namespace Spree

    config.autoload_paths += %W(#{config.root}/lib)

    # use rspec for tests
    config.generators do |g|
      g.test_framework :rspec
    end

    def self.activate
      Dir.glob(File.join(File.dirname(__FILE__), "../../app/**/*_decorator*.rb")) do |c|
        Rails.application.config.cache_classes ? require(c) : load(c)
      end
    end
	
    config.to_prepare &method(:activate).to_proc

    initializer "cybersource.register.payment_methods" do |app|
      app.config.spree.payment_methods += [
                                           Spree::Gateway::CyberSource
    ]
    end

  end
end
