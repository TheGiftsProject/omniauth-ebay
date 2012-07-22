require 'multi_xml'

module EbayAPI

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
    MultiXml.parse(response)["GetSessionIDResponse"]["SessionID"]
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
    MultiXml.parse(response)["FetchTokenResponse"]["eBayAuthToken"]
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
    MultiXml.parse(response)["GetUserResponse"]['User']
  end

  def ebay_login_url(session_id)
    #TODO: Refactor ruparams to receive all of the request query string
    url = "#{EBAY_LOGIN_URL}?SingleSignOn&runame=#{options.runame}&sid=#{URI.escape(session_id).gsub('+', '%2B')}"
    internal_return_to = request.params['internal_return_to'] || request.params[:internal_return_to]
    url << "&ruparams=#{CGI::escape('internal_return_to=' + internal_return_to)}" if internal_return_to

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
