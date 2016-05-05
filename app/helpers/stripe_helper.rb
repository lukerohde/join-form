module StripeHelper
	require "net/http"
	require "net/https"
	require "uri"
	
	def get_stripe_token(authorization_code)
		uri = URI.parse("https://connect.stripe.com/oauth/token")
		
		response = Net::HTTP.post_form(uri, {
				client_secret: ENV['STRIPE_SECRET_KEY'],
				code: authorization_code,
				grant_type: "authorization_code"
			})

		if response.body.blank?
			{ "error" => response.code, "error_description" => response.message }
		else
			JSON.parse(response.body)
		end
	end

	def deauthorize_stripe_user_id(stripe_user_id)
		uri = URI.parse("https://connect.stripe.com/oauth/deauthorize")
		
		http = Net::HTTP.new(uri.host, uri.port)
		http.use_ssl = true
		request = Net::HTTP::Post.new(uri.request_uri)
		request.basic_auth(ENV['STRIPE_SECRET_KEY'], nil)
		request.set_form_data({
			client_id: ENV['STRIPE_CLIENT_ID'], 
			stripe_user_id: stripe_user_id
			})
		response = http.request(request)

		response.code == "200" ? true : false
	end
end
