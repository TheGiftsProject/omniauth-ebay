require 'multi_xml'

module EbayAPI

  class EbayApiError < StandardError
    attr_accessor :request, :response

    def initialize(message=nil, request=nil, response=nil)
      super(message)
      @request = request
      @response = response
    end
  end

  EBAY_LOGIN_URL = "https://signin.ebay.com/ws/eBayISAPI.dll"
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

    response = api(X_EBAY_API_GETSESSIONID_CALL_NAME, request)
    parsed_response = MultiXml.parse(response)
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

    response = api(X_EBAY_API_FETCHAUTHTOKEN_CALL_NAME, request)
    parsed_response = MultiXml.parse(response)
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

    response = api(X_EBAY_API_GETUSER_CALL_NAME, request)
    parsed_response = MultiXml.parse(response)
    user = parsed_response && parsed_response["GetUserResponse"] && parsed_response["GetUserResponse"]["User"]

    if (!user)
      raise EbayApiError.new("Failed to retrieve user info", request, response)
    end

    user
  end

  def ebay_login_url(session_id)
    #TODO: Refactor ruparams to receive all of the request query string

    ru_params = []
    session_id = URI.escape(session_id).gsub('+', '%2B')

    internal_return_to = request.params['internal_return_to'] || request.params[:internal_return_to]

    if (internal_return_to)
      internal_return_to_params = 'internal_return_to=' + internal_return_to
      ru_params << internal_return_to_params
    end

    if (options.auth_type == OmniAuth::Strategies::Ebay::AuthType::Simple)
      url = "#{EBAY_LOGIN_URL}?SignIn&runame=#{options.runame}&SessId=#{session_id}"

      session_id_params = 'sid=' + session_id
      ru_params << session_id_params
    else
      url = "#{EBAY_LOGIN_URL}?SingleSignOn&runame=#{options.runame}&sid=#{session_id}"
    end

    url << "&ruparams=#{CGI::escape(ru_params.join('&'))}" unless ru_params.empty?
    url
  end

  protected

  def api(call_name, request)
    headers = ebay_request_headers(call_name, request.length.to_s)
    url = URI.parse(options.apiurl)
    req = Net::HTTP::Post.new(url.path, headers)
    http = Net::HTTP.new(url.host, url.port)
    http.use_ssl = true
    http.start { |h| h.request(req, request) }.body
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
end
