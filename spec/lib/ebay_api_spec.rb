require 'spec_helper'
require 'ostruct'

class FakeStrategy
  include EbayAPI

  def options
    @options ||= begin
      options = OpenStruct.new
      options.runame = "runame"
      options.auth_type = OmniAuth::Strategies::Ebay::AuthType::SSO
      options
    end
  end
end

describe EbayAPI do
  subject { FakeStrategy.new }
  let(:good_response) { "good response" }
  let(:bad_response) { "bad response" }
  let(:bad_parsed_response) { {} }

  describe :ebay_login_url do
    let(:session_id) { "session_id"}
    let(:unescaped_session_id) { "asdasd+afasf" }
    let(:internal_return_to) { "http://someurl.com/somewhere" }
    let(:signIn) { OmniAuth::Strategies::Ebay::AuthType::Simple }
    let(:singleSignOn) { OmniAuth::Strategies::Ebay::AuthType::SSO }

    it "should cgi escape session id" do
      subject.stub(:internal_return_to) { false }
      subject.ebay_login_url(unescaped_session_id).should include("sid=#{CGI.escape(unescaped_session_id)}")
    end

    context :sandbox do
      it "should return the sandbox ebay login/api urls when sandbox environment is specified" do
        subject.stub(:internal_return_to) { internal_return_to }
        params = {}
        params[:internal_return_to] = internal_return_to
        params[:sid] = session_id
        subject.options.environment = :sandbox
        subject.login_url.should == EbayAPI::EBAY_SANDBOX_LOGIN_URL
        subject.api_url.should == EbayAPI::EBAY_SANDBOX_XML_API_URL
      end
    end

    context :production do
      it "should return the production login/api urls when production environment is specified" do
        subject.stub(:internal_return_to) { internal_return_to }
        params = {}
        params[:internal_return_to] = internal_return_to
        params[:sid] = session_id
        subject.login_url.should == EbayAPI::EBAY_PRODUCTION_LOGIN_URL
        subject.api_url.should == EbayAPI::EBAY_PRODUCTION_XML_API_URL
      end
      context :SingleSignOn do
        it "should return ebay login url with internal return to when internal_return_to given in request" do
          subject.stub(:internal_return_to) { internal_return_to }
          params = {}
          params[:internal_return_to] = internal_return_to
          params[:sid] = session_id
          subject.ebay_login_url(session_id).should == "#{EbayAPI::EBAY_PRODUCTION_LOGIN_URL}?#{singleSignOn}&runame=runame&sid=#{session_id}&ruparams=#{to_query(params)}"
        end

        it "should return ebay login url without internal return to when internal_return_to isn't given in request" do
          subject.stub(:internal_return_to) { false }
          params = {}
          params[:sid] = session_id
          subject.ebay_login_url(session_id).should == "#{EbayAPI::EBAY_PRODUCTION_LOGIN_URL}?#{singleSignOn}&runame=runame&sid=#{session_id}&ruparams=#{to_query(params)}"
        end
      end

      context :SignIn do
        before :each do
          subject.options.auth_type = OmniAuth::Strategies::Ebay::AuthType::Simple
        end
        it "should return ebay login url with internal_return_to when internal_return_to given in request" do
          subject.stub(:internal_return_to) { internal_return_to }
          params = {}
          params[:internal_return_to] = internal_return_to
          params[:sid] = session_id
          subject.ebay_login_url(session_id).should == "#{EbayAPI::EBAY_PRODUCTION_LOGIN_URL}?#{signIn}&runame=runame&SessId=#{session_id}&ruparams=#{to_query(params)}"
        end

        it "should return ebay login url without internal return to when internal_return_to isn't given in request" do
          subject.stub(:internal_return_to) { false }
          params = {}
          params[:sid] = session_id
          subject.ebay_login_url(session_id).should == "#{EbayAPI::EBAY_PRODUCTION_LOGIN_URL}?#{signIn}&runame=runame&SessId=#{session_id}&ruparams=#{to_query(params)}"
        end
      end
    end

    ## The activesupport to_query extension doesn't escape the = character as it's meant for a primary query string
    def to_query(params)
      params.to_query.gsub("=", "%3D").gsub("&", "%26")
    end
  end

  describe :generate_session_id do
    let(:good_parsed_response) do
      {
          "GetSessionIDResponse" =>
              {
                  "SessionID" => "sessionid"
              }
      }
    end

    it "should return a session id for a good response" do
      subject.stub(:api) { [good_parsed_response, good_response] }
      subject.generate_session_id.should == "sessionid"
    end

    it "should raise EbayAPIError for a bad response" do
      subject.stub(:api) { [bad_parsed_response, bad_response] }
      expect { subject.generate_session_id }.to raise_error EbayAPI::EbayApiError
    end
  end

  describe :get_auth_token do
    let(:good_parsed_response) do
      {
          "FetchTokenResponse" =>
              {
                  "eBayAuthToken" => "ebay_auth_token"
              }
      }
    end

    it "should return an ebay auth token for a good response" do
      subject.stub(:api) { [good_parsed_response, good_response] }
      subject.get_auth_token("username", "secret_id").should == "ebay_auth_token"
    end

    it "should raise EbayAPIError for a bad response" do
      subject.stub(:api) { [bad_parsed_response, bad_response] }
      expect { subject.get_auth_token("username", "secret_id") }.to raise_error EbayAPI::EbayApiError
    end
  end

  describe :get_user_info do
    let(:good_parsed_response) do
      {
          "GetUserResponse" =>
              {
                  "User" => {
                      "EIASToken" => "eiastoken",
                      "UserID" => "eiastoken",
                      "Email" => "eiastoken",
                      "RegistrationAddress" => {
                          "Name" => "name",
                          "Country" => "country"
                      }
                  }
              }
      }
    end

    it "should return user info for a good response" do
      subject.stub(:api) { [good_parsed_response, good_response] }
      subject.get_user_info("username", "auth_token").should == good_parsed_response["GetUserResponse"]["User"]
    end

    it "should raise EbayAPIError for a bad response" do
      subject.stub(:api) { [bad_parsed_response, bad_response] }
      expect { subject.get_user_info("username", "auth_token") }.to raise_error EbayAPI::EbayApiError
    end
  end

end
