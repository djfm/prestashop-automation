require 'rest-client'
require 'json'

module PrestaShopAutomation
	module UsersActions
		def create_user options={}

			random_user = JSON.parse(RestClient.get('http://api.randomuser.me/'), :symbolize_names => true)[:results].first[:user]

			visit @front_office_url
			first('a.login').click
			puts random_user
			find('#email_create').set (options[:email] || random_user[:email])
			click '#SubmitCreate'

			click_label_for "id_gender#{(options[:gender] || random_user[:gender]) == 'female' ? 2 : 1}"

			customer_firstname = options[:firstname] || random_user[:name][:first]
			customer_lastname = options[:lastname] || random_user[:name][:last]
			passwd = options[:password] || random_user[:password]

			fill_in 'customer_firstname', :with => customer_firstname
			fill_in 'customer_lastname', :with => customer_lastname
			fill_in 'passwd', :with => passwd

			click '#submitAccount'
			first(:xpath, "//a[i/@class='icon-building']").click

			select_random_option '#id_country'
			select_random_option '#id_state'

			if false
				address1
				city
				phone_mobile
			end

			sleep 60
		end
	end
end
