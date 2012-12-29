require 'spec_helper'
require 'vcr'
require 'fakeweb'

VCR.configure do |c|
  c.cassette_library_dir = 'fixtures/vcr_cassettes'
  c.hook_into :fakeweb
end

describe OmniAuth::Strategies::Ebay do
  def app
    Rack::Builder.new {
      use Rack::Session::Cookie
      use OmniAuth::Strategies::Ebay, "runame", "devid", "appid", "certid", "siteid", "https://api.ebay.com/ws/api.dll"
      run lambda {|env| [404, {'Content-Type' => 'text/plain'}, [nil || env.key?('omniauth.auth').to_s]] }
    }.to_app
  end

  let(:auth_hash) { last_request.env['omniauth.auth'] }
  describe "#request_phase" do
    xit "should redirect to ebay with session_id" do
      VCR.use_cassette 'request_phase' do
        get '/auth/ebay'
        last_response.should be_redirect
      end
    end

    xit "should fail" do
      get '/auth/ebay'
      last_response.should be_redirect
      last_response.location.should =~ /\/auth\/failure/
    end
  end

  describe "#callback_phase" do
    xit "should initialize auth uid and info" do
      VCR.use_cassette 'callback_phase' do
        get '/auth/ebay/callback?sid=fake&username=test_user&'
        auth_hash.should_not be_nil
        auth_hash.uid.should == 'fake_eias_token'
      end
    end

    xit "should fail" do
      get '/auth/ebay/callback'
      auth_hash.should be_nil
    end
  end
end