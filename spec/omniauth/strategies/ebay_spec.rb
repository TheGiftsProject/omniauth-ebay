require 'spec_helper'
require 'vcr'
require 'fakeweb'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  c.hook_into :fakeweb
  c.debug_logger = File.open("vcr_debug.txt", "w") if ENV['VCR_DEBUG']
end

describe OmniAuth::Strategies::Ebay do
  def app
    Rack::Builder.new {
      use Rack::Session::Cookie, secret: "42"
      use OmniAuth::Strategies::Ebay, "runame", "devid", "appid", "certid", "siteid", "https://api.ebay.com/ws/api.dll"
      run lambda {|env| [404, {'Content-Type' => 'text/plain'}, [nil || env.key?('omniauth.auth').to_s]] }
    }.to_app
  end

  let(:auth_hash) { last_request.env['omniauth.auth'] }
  describe "#request_phase" do
    it "should redirect to ebay with session_id" do
      VCR.use_cassette 'request_phase' do
        get '/auth/ebay'
        last_response.should be_redirect
        last_response.location.should == "https://signin.ebay.com/ws/eBayISAPI.dll?SingleSignOn&runame=runame&sid=fake&ruparams=sid%3Dfake"
      end
    end

    it "should fail" do
      VCR.use_cassette 'request_phase_failure' do
        get '/auth/ebay'
        last_response.should be_redirect
        last_response.location.should =~ /\/auth\/failure/
      end
    end
  end

  describe "#callback_phase" do
    it "should initialize auth uid and info" do
      VCR.use_cassette 'callback_phase' do
        get '/auth/ebay/callback?sid=fake&username=test_user&'
        auth_hash.should_not be_nil

        auth_hash.uid.should == 'fake_eias_token'

        auth_hash["info"].should_not be_nil
        auth_hash["info"]["name"].should == "Fake Name"
        auth_hash["info"]["nickname"].should == "test_user"
        auth_hash["info"]["email"].should == "test@user.com"
        auth_hash["info"]["country"].should == "US"

        auth_hash["credentials"].should_not be_nil
        auth_hash["credentials"]["token"].should == "fake_auth_token"

        auth_hash["extra"].should_not be_nil
        # returns entire response from GetUser
        auth_hash["extra"]["raw_info"]["Email"].should == "test@user.com"
        auth_hash["extra"]["raw_info"]["UserID"].should == "test_user"
        auth_hash["extra"]["raw_info"]["Status"].should == "Confirmed"
      end
    end

    it "should fail" do
      VCR.use_cassette 'callback_phase_failure' do
        get '/auth/ebay/callback'
        auth_hash.should be_nil
      end
    end
  end
end
