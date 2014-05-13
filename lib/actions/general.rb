module PrestaShopAutomation
	module GeneralActions
		def login_to_back_office
			visit @back_office_url
			fill_in "email", :with => @admin_email
			fill_in "passwd", :with => @admin_password
			click_label_for 'stay_logged_in'
			click_button_named 'submitLogin', :first => true
			expect(self).to have_selector('#header_logout', :visible => false)
		end
	end
end
