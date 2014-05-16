require 'prestashop-automation'

ps = PrestaShopAutomation::PrestaShop.new({
	:back_office_url => 'http://localhost/1.6-taxes-prestashop-tests/admin-dev/',
	:front_office_url => 'http://localhost/1.6-taxes-prestashop-tests/',
	:installer_url => 'http://localhost/1.6-taxes-prestashop-tests/install-dev/',
	:admin_email => 'pub@prestashop.com',
	:admin_password => '123456789',
	:database_name => '1.6-taxes-prestashop-tests'
})

describe 'Back Office Primitives' do

	before :all do
		ps.login_to_back_office
	end

	after :all do
		ps.logout_of_back_office
	end

	describe 'Changing a few settings' do

		[:item, :line, :total].each do |mode|
			it "should set rounding rule to #{mode}" do
				ps.set_rounding_rule mode
			end
		end

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

	describe 'Creating And Deleting a Cart Rule' do
		it 'should work with one product' do
			id = ps.create_cart_rule :name => 'YiiHaaa', :product_id => 1, :amount => '10%'
			ps.delete_cart_rule id
		end
	end

	describe 'Creating carriers' do
		it 'should work in the simplest case' do
			ps.create_carrier :name => 'Turtle Bob'
		end
	end

	describe 'Creating taxes' do

		it 'should create a complicated tax group' do
			ps.create_tax_group_from_rate '10 + 9.6'
		end

		it 'should create a tax and a tax group' do
			tax_id = ps.create_tax :name => 'Some Tax', :rate => '20'
			ps.create_tax_group :name => 'Test Tax Group', :taxes => [{:tax_id => tax_id}]
		end
	end

	describe 'Creating products' do

		it 'should work with a specific price' do
			ps.create_product :name => 'Petit Sachet de Vis Cruciformes Pas Cher', :price => '1.92', :specific_price => 'minus 1 tax included'
		end

		it 'should work with just a price and a name' do
			ps.create_product :name => 'Petit Sachet de Vis Cruciformes', :price => '1.85'
		end
	end

	describe 'Navigating the back office' do
		it 'should go to AdminOrders' do
			ps.goto_admin_tab 'AdminOrders'
		end
	end

end

describe 'Installing' do
	it 'should use the UI to prepare the database' do
		ps.drop_database
		ps.install
		ps.reset!
	end

	it 'should prepare the database externally' do
		ps.drop_database
		ps.install :prepare_database => true
		ps.reset!
	end
end

describe 'Front Office Primitives' do

	before :all do
		ps.login_to_front_office
		ps.login_to_back_office
		ps.set_friendly_urls false
	end

	after :all do
		ps.logout_of_front_office
		ps.logout_of_back_office
	end

	it 'should add product 1 to cart and make an order in OPC' do
		ps.goto_back_office
		ps.set_order_process_type :opc
		ps.goto_front_office
		ps.add_product_to_cart 1
		order_id = ps.order_current_cart_opc :carrier => 'My carrier'
		ps.goto_back_office
		ps.validate_order id: order_id
	end

	it 'should add product 1 to cart and make an order in 5 steps checkout' do
		ps.goto_back_office
		ps.set_order_process_type :five_steps
		ps.goto_front_office
		ps.add_product_to_cart 1
		order_id = ps.order_current_cart_5_steps :carrier => 'My carrier'
		ps.goto_back_office
		ps.validate_order id: order_id
	end
end
