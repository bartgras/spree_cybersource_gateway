module Spree
  class Gateway::CyberSource < Gateway
    preference :login, :string
    preference :password, :string

    attr_accessible :preferred_login, :preferred_password

    def provider_class 
      ActiveMerchant::Billing::CyberSourceGateway
    end

    def authorize(amount, creditcard, gateway_options)
#binding.pry
      provider.authorize(amount, creditcard_or_reference(creditcard), gateway_options)
    end

    def purchase(amount, creditcard, gateway_options)
      provider.purchase(amount, creditcard_or_reference(creditcard), gateway_options)
    end

    def capture(authorization, creditcard, gateway_options)
#binding.pry
      provider.capture(amount, creditcard_or_reference(creditcard), gateway_options)
    end

    def credit(amount, creditcard, response_code, gateway_options)
#binding.pry
      provider.refund(amount, identification, gateway_options)
    end

    def void(response_code, creditcard, gateway_options)
#binding.pry
      provider.void(response_code, gateway_options)
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
#binding.pry

        ## this is where i need to pick back up and figure out why i'm getting 'general failure' as well as what result params below will correspond to the correct ids
        if result.success?
          # using 'subscriptionID' for both values since we only get one back from cybersource
          creditcard.gateway_customer_profile_id = result.params['subscriptionID']
          creditcard.gateway_payment_profile_id  = result.params['subscriptionID']
          creditcard.save!
        else
          creditcard.gateway_error(result) if creditcard.respond_to? :gateway_error
        end
      end
    end

    def creditcard_or_reference(creditcard)
      # re: the 'dummy' below:
      # the active_merchant class expects the creditcard referene number to be in this form:
      #   reference_code, subscription_id, request_token = reference.split(";")
      # which if goofy, b/c i don't have the outer pair available, so fake them (they are not used in the activemerchant 
      # method anyways, they are thrown out
      creditcard.gateway_payment_profile_id.present? ? "dummy;#{creditcard.gateway_payment_profile_id};dummy" : creditcard
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

