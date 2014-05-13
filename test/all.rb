require_relative '../lib/prestashop.rb'

describe 'Automation Primitives' do

	ps = nil

	before :each do
		ps.quit_browser if ps

		ps = PrestaShopAutomation::PrestaShop.new({
				:back_office_url => 'http://localhost/1.6/admin-dev/',
				:front_office_url => 'http://localhost/1.6/',
				:admin_email => 'pub@prestashop.com',
				:admin_password => '123456789'
		})
	end

	describe 'Changing a few settings' do
		it 'shoud enable Friendly URLs' do
			ps.login_to_back_office
			ps.set_friendly_urls true
		end
	end

	describe 'Navigating the back office' do
		it 'should go to AdminOrders' do
			ps.login_to_back_office
			ps.goto_admin_tab 'AdminOrders'
		end
	end

	describe 'Logging in and out' do
		it 'should work in the Front-Office' do
			ps.login_to_front_office
			ps.logout_of_front_office
		end

		it 'should work in the Back-Office' do
			ps.login_to_back_office
			ps.logout_of_back_office
		end
	end

end
