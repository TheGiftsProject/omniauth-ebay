require 'multi_xml'
require 'active_support/core_ext/object/to_query'

module EbayAPI

  class EbayApiError < StandardError
    attr_accessor :request, :response

    def initialize(message=nil, request=nil, response=nil)
      super(message)
      @request = request
      @response = response
    end
  end

  EBAY_PRODUCTION_LOGIN_URL = "https://signin.ebay.com/ws/eBayISAPI.dll"
  EBAY_SANDBOX_LOGIN_URL = "https://signin.sandbox.ebay.com/ws/eBayISAPI.dll"

  EBAY_PRODUCTION_XML_API_URL = "https://api.ebay.com/ws/api.dll"
  EBAY_SANDBOX_XML_API_URL = "https://api.sandbox.ebay.com/ws/api.dll"


  def sandbox?
    options.environment == :sandbox
  end

  def login_url
    return EBAY_SANDBOX_LOGIN_URL if sandbox?
    EBAY_PRODUCTION_LOGIN_URL
  end

  def api_url
    return EBAY_SANDBOX_XML_API_URL if sandbox?
    EBAY_PRODUCTION_XML_API_URL
  end

  X_EBAY_API_REQUEST_CONTENT_TYPE = 'text/xml'
  X_EBAY_API_COMPATIBILITY_LEVEL = '675'
  X_EBAY_API_GETSESSIONID_CALL_NAME = 'GetSessionID'
  X_EBAY_API_FETCHAUTHTOKEN_CALL_NAME = 'FetchToken'
  X_EBAY_API_GETUSER_CALL_NAME = 'GetUser'

  def generate_session_id
    request = %Q(
          <?xml version="1.0" encoding="utf-8"?>
          <GetSessionIDRequest xmlns="urn:ebay:apis:eBLBaseComponents">
            <RuName>#{options.runame}</RuName>
          </GetSessionIDRequest>
    )

    parsed_response, response = api(X_EBAY_API_GETSESSIONID_CALL_NAME, request)
    session_id = parsed_response && parsed_response["GetSessionIDResponse"] && parsed_response["GetSessionIDResponse"]["SessionID"]

    if (!session_id)
      raise EbayApiError.new("Failed to generate session id", request, response)
    end

    session_id
  end

  def get_auth_token(username, secret_id)
    request = %Q(
          <?xml version="1.0" encoding="utf-8"?>
          <FetchTokenRequest xmlns="urn:ebay:apis:eBLBaseComponents">
             <RequesterCredentials>
               <Username>#{username}</Username>
             </RequesterCredentials>
             <SecretID>#{secret_id.gsub(' ', '+')}</SecretID>
          </FetchTokenRequest>
    )

    parsed_response, response = api(X_EBAY_API_FETCHAUTHTOKEN_CALL_NAME, request)
    token = parsed_response && parsed_response["FetchTokenResponse"] && parsed_response["FetchTokenResponse"]["eBayAuthToken"]

    if (!token)
      raise EbayApiError.new("Failed to retrieve auth token", request, response)
    end

    token
  end

  def get_user_info(username, auth_token)
    request = %Q(
          <?xml version="1.0" encoding="utf-8"?>
          <GetUserRequest xmlns="urn:ebay:apis:eBLBaseComponents">
            <DetailLevel>ReturnAll</DetailLevel>
            <UserID>#{username}</UserID>
            <RequesterCredentials>
              <eBayAuthToken>#{auth_token}</eBayAuthToken>
            </RequesterCredentials>
            <WarningLevel>High</WarningLevel>
          </GetUserRequest>
    )

    parsed_response, response = api(X_EBAY_API_GETUSER_CALL_NAME, request)
    user = parsed_response && parsed_response["GetUserResponse"] && parsed_response["GetUserResponse"]["User"]

    if (!user)
      raise EbayApiError.new("Failed to retrieve user info", request, response)
    end

    user
  end

  def ebay_login_url(session_id, ruparams={})
    url = "#{login_url}?#{options.auth_type}&runame=#{options.runame}&#{session_id_field_name}=#{URI.escape(session_id).gsub('+', '%2B')}"

    ruparams[:internal_return_to] = internal_return_to if internal_return_to
    ruparams[:sid] = session_id
    url << "&ruparams=#{ruparams.to_query.gsub("=", "%3D").gsub("&", "%26")}" unless ruparams.empty?

    url
  end

  protected

  def api(call_name, request)
    headers = ebay_request_headers(call_name, request.length.to_s)
    url = URI.parse(api_url)
    req = Net::HTTP::Post.new(url.path, headers)
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    response = http.start { |h| h.request(req, request) }.body
    [MultiXml.parse(response), response]
  end

  def ebay_request_headers(call_name, request_length)
    {
        'X-EBAY-API-CALL-NAME'  => call_name,
        'X-EBAY-API-COMPATIBILITY-LEVEL'  => X_EBAY_API_COMPATIBILITY_LEVEL,
        'X-EBAY-API-DEV-NAME' => options.devid,
        'X-EBAY-API-APP-NAME' => options.appid,
        'X-EBAY-API-CERT-NAME' => options.certid,
        'X-EBAY-API-SITEID' => options.siteid.to_s,
        'Content-Type' => X_EBAY_API_REQUEST_CONTENT_TYPE,
        'Content-Length' => request_length
    }
  end

  private

  def internal_return_to
    request.params['internal_return_to'] || request.params[:internal_return_to]
  end

  def session_id_field_name
    if options.auth_type == OmniAuth::Strategies::Ebay::AuthType::SSO
      OmniAuth::Strategies::Ebay::AuthType::SSO_SID_FIELD_NAME
    else
      OmniAuth::Strategies::Ebay::AuthType::SIMPLE_SID_FIELD_NAME
    end
  end

end
