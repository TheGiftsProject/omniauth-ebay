require 'omniauth'

module OmniAuth
  module Strategies
    class Ebay
      include OmniAuth::Strategy
      include EbayAPI

      module AuthType
        SSO = 'SingleSignOn'
        Simple = 'SignIn'

        SSO_SID_FIELD_NAME = "sid"
        SIMPLE_SID_FIELD_NAME = "SessId"
      end

      args [:runame, :devid, :appid, :certid, :siteid, :environment, :auth_type]
      option :name, "ebay"
      option :runame, nil
      option :devid, nil
      option :appid, nil
      option :certid, nil
      option :siteid, nil
      option :environment, :production
      option :auth_type, AuthType::SSO

      uid { raw_info['EIASToken'] }
      info do
        {
            :ebay_id => raw_info['UserID'],
            :ebay_token => @auth_token,
            :email => raw_info['Email'],
            :full_name => raw_info["RegistrationAddress"] && raw_info["RegistrationAddress"]["Name"],
            :country => raw_info["RegistrationAddress"] && raw_info["RegistrationAddress"]["Country"]
        }
      end

      extra do
        {
            :internal_return_to => request.params['internal_return_to'] || request.params[:internal_return_to]
        }
      end

      #1: We'll get to the request_phase by accessing /auth/ebay
      #2: Request from eBay a SessionID
      #3: Redirect to eBay Login URL with the RUName and SessionID
      def request_phase
        session_id = generate_session_id
        redirect ebay_login_url(session_id)
      rescue => ex
        fail!("Failed to retrieve session id from ebay", ex)
      end

      #4: We'll get to the callback phase by setting our accept/reject URL in the ebay application settings(/auth/ebay/callback)
      #5: Request an eBay Auth Token with the returned username&secret_id parameters.
      #6: Request the user info from eBay
      def callback_phase
        @auth_token = get_auth_token(request.params["username"], request.params["sid"])
        @user_info = get_user_info(request.params["username"], @auth_token)
        super
      rescue => ex
        fail!("Failed to retrieve user info from ebay", ex)
      end

      def raw_info
        @user_info
      end
    end
  end
end

OmniAuth.config.add_camelization 'ebay', 'Ebay'
