module Spree
  class Gateway::CyberSource < Gateway
    preference :login, :string
    preference :password, :string

    attr_accessible :preferred_login, :preferred_password

    def provider_class 
      ActiveMerchant::Billing::CyberSourceGateway
    end
  end
end
