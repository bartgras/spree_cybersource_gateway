module Spree
  class Gateway::CyberSource < Gateway
    preference :login, :string
    preference :password, :string

    attr_accessible :preferred_login, :preferred_password

    def provider_class 
      ActiveMerchant::Billing::CyberSourceGateway
    end

    def payment_profiles_supported?
      true
    end

    # might need this????
    def options
      # add :test key in the options hash, as that is what the ActiveMerchant::Billing::CyberSourceGateway expects
      if self.preferred_test_mode
        self.class.preference :test, :boolean, :default => true
      else
        self.class.remove_preference :test
      end

      super
    end

    # something like this (copied from beanstream)
    def create_profile(payment)
      creditcard = payment.source
      if creditcard.gateway_customer_profile_id.nil?
        options = options_for_create_customer_profile(creditcard, {})

        result = provider.store(creditcard, options)

        ## this is where i need to pick back up and figure out why i'm getting 'general failure' as well as what result params below will correspond to the correct ids
        if result.success?
          creditcard.update_attributes(:gateway_customer_profile_id => result.params['???'], :gateway_payment_profile_id => result.params['???'])
        else
          creditcard.gateway_error(result) if creditcard.respond_to? :gateway_error
        end
      end
    end


    def options_for_create_customer_profile(creditcard, gateway_options)
      order = creditcard.payments.first.order
      address = order.bill_address
      { :order_id        => order.number,
        :email           => order.email,
        :billing_address => 
        { :name     => address.full_name,
          :phone    => address.phone,
          :address1 => address.address1,
          :address2 => address.address2,
          :city     => address.city,
          :state    => address.state_name || address.state.abbr,
          :country  => address.country.iso,
          :zip      => address.zipcode
        }
      }.merge(gateway_options)
    end

  end
end
