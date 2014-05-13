require_relative '../lib/prestashop.rb'

ps = PrestaShopAutomation::PrestaShop.new({
	:back_office_url => 'http://localhost/1.6/admin-dev/',
	:front_office_url => 'http://localhost/1.6/',
	:admin_email => 'pub@prestashop.com',
	:admin_password => '123456789'
})

describe 'Back Office Primitives' do

	before :all do
		ps.login_to_back_office
	end

	after :all do
		ps.logout_of_back_office
	end

	describe 'Changing a few settings' do
		it 'should enable OPC' do
			ps.set_order_process_type :opc
		end

		it 'should disable OPC' do
			ps.set_order_process_type :five_steps
		end

		it 'shoud enable Gift Wrapping' do
			ps.set_gift_wrapping_option true, :price => 2
		end

		it 'shoud enable Friendly URLs' do
			ps.set_friendly_urls true
		end
	end

	describe 'Navigating the back office' do
		it 'should go to AdminOrders' do
			ps.goto_admin_tab 'AdminOrders'
		end
	end

end

describe 'Front Office Primitives' do
		it 'should login' do
			ps.login_to_front_office
		end
		it 'should logout' do
			ps.logout_of_front_office
		end
end
