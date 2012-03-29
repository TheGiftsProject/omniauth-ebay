# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "omniauth-ebay/version"

Gem::Specification.new do |s|
  s.name        = "omniauth-ebay"
  s.version     = OmniAuth::Ebay::VERSION
  s.authors     = ["Itay Adler"]
  s.email       = ["itayadler@gmail.com"]
  s.homepage    = "https://github.com/TheGiftsProject/omniauth-ebay"
  s.summary     = %q{OmniAuth strategy for eBay}
  s.description = %q{In this gem you will find an OmniAuth eBay strategy that is compliant with the Open eBay Apps API.
You can read all about it here: [Open eBay Apps Developers Zone](http://developer.ebay.com/DevZone/open-ebay-apps/Concepts/OpeneBayUGDev.html)}

  s.rubyforge_project = "omniauth-ebay"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_runtime_dependency 'omniauth', '~> 1.0'
  s.add_development_dependency 'rspec', '~> 2.7'
end
