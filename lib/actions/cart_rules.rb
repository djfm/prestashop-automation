module PrestaShopAutomation
	module CartRulesActions
		def create_cart_rule options
			goto_admin_tab 'AdminCartRules'
			find('#page-header-desc-cart_rule-new_cart_rule').click
			fill_in 'name_1', :with => options[:name]

			click_label_for "partial_use_#{onoff (options[:partial_use] != false)}"
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
				standard_success_check
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
			standard_success_check
			id = current_url[/\bid_cart_rule=(\d+)/, 1].to_i
			id.should be > 0
			return id
		end
	end
end
