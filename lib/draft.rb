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
	def create_cart_rule options
		visit '/admin-dev'
		find('#maintab-AdminPriceRule').hover
		find('#subtab-AdminCartRules a').click
		find('#page-header-desc-cart_rule-new_cart_rule').click
		fill_in 'name_1', :with => options[:name]

		pu = options[:partial_use] != false
		click_label_for "partial_use_#{pu ? 'on' : 'off'}"
		click_label_for 'active_on'

		find('#cart_rule_link_conditions').click
		find('input[name="date_from"]').set '1900-01-01 00:00:00'
		find('input[name="date_to"]').set '2500-01-01 00:00:00'

		find('input[name="quantity"]').set 1000000
		find('input[name="quantity_per_user"]').set 1000000

		product_name = nil
		if options[:product_id]
			check 'product_restriction'
			find('#product_restriction_div a').click
			within '#product_rule_type_1' do
				find('option[value="products"]').click
			end
			find('#product_rule_group_table a[href*="javascript:addProductRule("]').click
			find('#product_rule_1_1_choose_link').click
			within '#product_rule_select_1_1_1' do
				option = find("option[value='#{options[:product_id]}']", :visible => false)
				option.click
				product_name = option.native.text.strip
			end
			addButton = find('#product_rule_select_1_1_add')
			addButton.click
			addButton.native.send_keys :escape
		end

		find('#cart_rule_link_actions').click

		if options[:free_shipping]
			click_label_for 'free_shipping_on'
		else
			click_label_for 'free_shipping_off'
		end

		click_label_for 'free_gift_off'

		amount_exp = /^(?:(\w+)\s+)?(\d+(?:\.\d+)?)\s*(?:tax\s+(excluded|included))$/
		if m = amount_exp.match(options[:amount].strip)
			currency, amount, with_tax = m[1].to_s.strip, m[2].to_f, (m[3] == 'included' ? 1 : 0)
			choose 'apply_discount_amount'
			fill_in 'reduction_amount', :with => amount
			if currency != ''
				within 'select[name="reduction_currency"]' do
					find(:xpath, "//option[normalize-space()='#{currency}']").click
				end
			end
			within 'select[name="reduction_tax"]' do
				find("option[value='#{with_tax}']").click
			end

			find('#desc-cart_rule-save-and-stay').click
			expect(page).to have_selector '.alert.alert-success'
			find('#cart_rule_link_actions').click

			if options[:product_id]
				choose 'apply_discount_to_product'
				fill_in 'reductionProductFilter', :with => product_name
				find('div.ac_results ul li').click
			end
		elsif m = /^(\d+(?:\.\d+)?)\s*%$/.match(options[:amount].strip)
			percent = m[1]
			choose 'apply_discount_percent'
			fill_in 'reduction_percent', :with => percent
			if options[:product_id]
				choose 'apply_discount_to_selection'
			else
				choose 'apply_discount_to_order'
			end
		else
			throw "Invalid cart rule amount specified!"
		end

		find('#desc-cart_rule-save-and-stay').click
		expect(page).to have_selector '.alert.alert-success'
		id = page.current_url[/\bid_cart_rule=(\d+)/, 1].to_i
		id.should be > 0
		@@cart_rules << id
		return id
	end

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

	def create_carrier options
		visit '/admin-dev'
		find('#maintab-AdminParentShipping').hover
		find('#subtab-AdminCarriers a').click
		find('#page-header-desc-carrier-new_carrier').click

		fill_in 'name', :with => options[:name]
		fill_in 'delay_1', :with => options[:delay] || 'Turtle'
		fill_in 'grade', :with => options[:grade] if options[:grade]
		fill_in 'url', :with => options[:tracking_url] if options[:tracking_url]

		find('.buttonNext.btn.btn-default').click

		find("label[for='shipping_handling_#{options[:with_handling_fees] ? 'on' : 'off'}']").click
		find("label[for='is_free_#{options[:free_shipping] ? 'on' : 'off'}']").click

		if options[:based_on] == :price
			choose 'billing_price'
		else
			choose 'billing_weight'
		end

		within '#id_tax_rules_group' do
			find("option[value='#{options[:tax_group_id] || 0}']").click
		end

		oob = options[:out_of_range_behavior] === :disable ? 1 : 0

		within '#range_behavior' do
			find("option[value='#{oob}']").click
		end

		options[:ranges] = options[:ranges] || [{:from_included => 0, :to_excluded => 1000, :prices => {0 => 0}}]

		options[:ranges].each_with_index do |range, i|

			if i > 0
				find('#add_new_range').click
			end

			unless options[:free_shipping]
				if i == 0
					find("input[name='range_inf[#{i}]']").set range[:from_included]
					find("input[name='range_sup[#{i}]']").set range[:to_excluded]
				else
					find("input[name='range_inf[]']:nth-of-type(#{i})").set range[:from_included]
					find("input[name='range_sup[]']:nth-of-type(#{i})").set range[:to_excluded]
				end
			end

			sleep 1

			range[:prices].each_pair do |zone, price|

				nth = i > 0 ? ":nth-of-type(#{i})" : ""

				if zone == 0
					find('.fees_all input[type="checkbox"]').click if i == 0
					unless options[:free_shipping]
						tp = all('.fees_all input[type="text"]')[i]
						tp.set price
						tp.native.send_keys :tab
					end
					sleep 4
				else
					check "zone_#{zone}"
					sleep 1
					unless options[:free_shipping]
						if i == 0
							find("input[name='fees[#{zone}][#{i}]']").set price
						else
							find("input[name='fees[#{zone}][]']"+nth).set price
						end
					end
				end
			end
		end

		find('.buttonNext.btn.btn-default').click

		fill_in 'max_height', :with => options[:max_package_height] if options[:max_package_height]
		fill_in 'max_width', :with => options[:max_package_width] if options[:max_package_width]
		fill_in 'max_depth', :with => options[:max_package_depth] if options[:max_package_depth]
		fill_in 'max_weight', :with => options[:max_package_weight] if options[:max_package_weight]

		if !options[:allowed_groups]
			check 'checkme'
		else
			check 'checkme'
			uncheck 'checkme'
			options[:allowed_groups].each do |group|
				check "groupBox_#{group}"
			end
		end

		find('.buttonNext.btn.btn-default').click

		find('label[for="active_on"]').click
		sleep 4 #this wait seems necessary, strange
		find('a.buttonFinish').click
		expect(page).to have_selector '.alert.alert-success'
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
