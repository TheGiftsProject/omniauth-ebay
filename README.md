OmniAuth eBay
====================================

In this gem you will find an OmniAuth eBay strategy that is compliant with the Open eBay Apps API.
You can read all about it here: [Open eBay Apps Developers Zone](http://developer.ebay.com/DevZone/open-ebay-apps/Concepts/OpeneBayUGDev.html)

Usage
=====================================

Note: The examples are for a Rails app.

* Add our gem to your `Gemfile`
`gem 'omniauth-ebay'`

* Add to your omniauth initializer (`config/initializers/omniauth.rb`) the ebay strategy like so:

`Rails.application.config.middleware.use OmniAuth::Builder do
    provider :ebay, "runame", "devid", "appid", "certid", "siteid", "apiurl"
end`

Insert your app credentials in the given order. You can find out these details by going into your developer's account at [eBay DevZone](https://developer.ebay.com/DevZone/account/)

* To use the strategy, you will need to access it's omniauth provider path: `/auth/ebay`. The callback phase path is the default one: `/auth/ebay/callback`.
You will need to define the callback path in your relevant app RUname, so don't forget to set the accept/reject paths in the devzone to the callback path.

* Set a route to the callback path of your sessions controller, and handle the session creation there. You will be able to access
the omniauth session data by accessing `request.env['omniauth.auth']`

How it Works
====================================

Request Phase
--------------------

* API call to eBay, requesting a session id.
* Redirecting to eBay login with the session id.

Callback Phase
-----------------------------------------

* API call to eBay, requesting an ebay auth token, with the secret id and username retrieved from the request.
* API call to eBay, requesting the user's info by using the ebay auth token from the last call.
* The strategy's UID is the eBay EIAS Token. Also these fields will also be exposed by accessing `request.env['omniauth.auth'].info`:
`ebay_id` - The user's eBay username.
`ebay_token` - The current session's auth token, to be used for API calls.
`email` - The user's email address.
* Extra data - We're also passing an optional parameter, `return_to`, which allows you to specify a URL you want the redirect the user to when the authentication process is completed.

