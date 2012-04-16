require 'rubygems'
require 'bundler'
Bundler.setup :default, :development, :test

require 'rack/test'
require 'capybara/rspec'
require 'capybara/mechanize'
require 'omniauth-ebay'

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.treat_symbols_as_metadata_keys_with_true_values = true
end