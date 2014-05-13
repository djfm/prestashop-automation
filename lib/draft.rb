# encoding: UTF-8

require 'capybara'
require 'capybara/dsl'
require 'capybara/rspec'
require 'capybara-screenshot'
require 'capybara-screenshot/rspec'
require 'json'
require 'set'
require 'shellwords'

Capybara.default_driver = :selenium
Capybara.save_and_open_page_path = "screenshots"

module PrestaShopHelpers
	include Capybara::DSL

	@@cart_rules = Set.new

	def delete_cart_rule id, andFromSet=true
		visit '/admin-dev'
		find('#maintab-AdminPriceRule').hover
		find('#subtab-AdminCartRules a').click
		url = first("a[href*='&deletecart_rule&']", :visible => false)['href']
		url.gsub! /\bid_cart_rule=\d+/, "id_cart_rule=#{id}"
		visit url
		expect(page).to have_selector '.alert.alert-success'
		if andFromSet
			@@cart_rules.delete id
		end
	end

	def delete_cart_rules
		@@cart_rules.each do |id|
			delete_cart_rule id, false
		end
		@@cart_rules = Set.new
	end

	def add_products_to_cart products
		products.each do |product|
			visit "/index.php?id_product=#{product[:id]}&controller=product&id_lang=1"
			fill_in 'quantity_wanted', :with => (product[:quantity] || 1)
			find('#add_to_cart button').click
			sleep 1
		end
	end

	def order_current_cart_5_steps options
		visit "/index.php?controller=order"
		find('a.standard-checkout').click
		find('button[name="processAddress"]').click
		expect(page).to have_selector '#uniform-cgv'
		click_label_for "cgv"
		click_label_for "gift" if options[:gift_wrapping]
		page.find(:xpath, '//tr[contains(., "'+options[:carrier]+'")]').find('input[type=radio]', :visible => false).click
		find('button[name="processCarrier"]').click
		find('a.bankwire').click
		find('#cart_navigation button').click
		order_id = page.current_url[/\bid_order=(\d+)/, 1].to_i
		order_id.should be > 0
		return order_id
	end

	def order_current_cart_opc options
		visit "/index.php?controller=order-opc"
		visit "/index.php?controller=order-opc" #yeah, twice, there's a bug
		click_label_for "cgv"
		click_label_for "gift" if options[:gift_wrapping]
		page.find(:xpath, '//tr[contains(., "'+options[:carrier]+'")]').find('input[type=radio]', :visible => false).click
		find('a.bankwire').click
		find('#cart_navigation button').click
		order_id = page.current_url[/\bid_order=(\d+)/, 1].to_i
		order_id.should be > 0
		return order_id
	end

	def validate_order options
		visit '/admin-dev/'
		find('#maintab-AdminParentOrders').hover
		find('#subtab-AdminOrders a').click

		url = first('td.pointer[onclick]')['onclick'][/\blocation\s*=\s*'(.*?)'/, 1].sub(/\bid_order=\d+/, "id_order=#{options[:id]}")
		visit "/admin-dev/#{url}"
		find('#id_order_state_chosen').click
		find('li[data-option-array-index="6"]').click
		find('button[name="submitState"]').click
		pdf_url = find('a[href*="generateInvoicePDF"]')['href']

		all_cookies = page.driver.browser.manage.all_cookies
		cookies = all_cookies.map do |c| "#{c[:name]}=#{c[:value]}" end.join ";"
		puts pdf_url
		cmd = "curl --url #{Shellwords.shellescape pdf_url} -b \"#{cookies}\" -o #{Shellwords.shellescape options[:dump_pdf_to]} 2>/dev/null"
		`#{cmd}` #download the PDF

		visit pdf_url+'&debug=1'
		return JSON.parse(page.find('body').text)
	end

	def test_invoice scenario, options

		set_order_process_type scenario['meta']['order_process'].to_sym

		if scenario["discounts"]
			scenario["discounts"].each_pair do |name, amount|
				create_cart_rule :name=> name, :amount => amount
			end
		end

		if scenario["gift_wrapping"]
			set_gift_wrapping_option true,
				:price => scenario["gift_wrapping"]["price"],
				:tax_group_id => scenario["gift_wrapping"]["vat"] ? get_or_create_tax_group_id_for_rate(scenario["gift_wrapping"]["vat"]) : nil,
				:recycling_option => false
		else
			set_gift_wrapping_option false
		end

		carrier_name = get_or_create_carrier({
			:name => scenario['carrier']['name'],
			:with_handling_fees => scenario['carrier']['with_handling_fees'],
			:free_shipping => scenario['carrier']['shipping_fees'] == 0,
			:ranges => [{:from_included => 0, :to_excluded => 1000, :prices => {0 => scenario['carrier']['shipping_fees']}}],
			:tax_group_id => scenario['carrier']['vat'] ? get_or_create_tax_group_id_for_rate(scenario['carrier']['vat']) : nil
		})

		products = []
		scenario['products'].each_pair do |name, data|
			id = get_or_create_product({
				:name => name,
				:price => data['price'],
				:tax_group_id => get_or_create_tax_group_id_for_rate(data['vat']),
				:specific_price => data['specific_price']
			})
			products << {id: id, quantity: data['quantity']}

			if data["discount"]
				create_cart_rule({
					:product_id => id,
					:amount => data["discount"],
					:free_shipping => false,
					:name => "#{name} with (#{data['discount']}) discount"
				})
			end
		end

		add_products_to_cart products

		order_id = if scenario['meta']['order_process'] == 'five_steps'
			order_current_cart_5_steps :carrier => carrier_name, :gift_wrapping => scenario["gift_wrapping"]
		else
			order_current_cart_opc :carrier => carrier_name, :gift_wrapping => scenario["gift_wrapping"]
		end

		invoice = validate_order :id => order_id, :dump_pdf_to => options[:dump_pdf_to]

		if scenario['expect']['invoice']
			if expected_total = scenario['expect']['invoice']['total']
				actual_total = invoice['order']
				mapping = {
					'to_pay_tax_included' => 'total_paid_tax_incl',
					'to_pay_tax_excluded' => 'total_paid_tax_excl',
					'products_tax_included' => 'total_products_wt',
					'products_tax_excluded' => 'total_products',
					'shipping_tax_included' => 'total_shipping_tax_incl',
					'shipping_tax_excluded' => 'total_shipping_tax_excl',
					'discounts_tax_included' => 'total_discounts_tax_incl',
					'discounts_tax_excluded' => 'total_discounts_tax_excl',
					'wrapping_tax_included' => 'total_wrapping_tax_incl',
					'wrapping_tax_excluded' => 'total_wrapping_tax_excl'
				}
				expected_total.each_pair do |key, value_expected|
					value_expected.to_s.should eq actual_total[mapping[key]].to_s
				end
			end
		end
	end
end

RSpec.configure do |config|
  config.include PrestaShopHelpers
end
