module PrestaShopAutomation
	module CarriersActions
		def create_carrier options
			goto_admin_tab 'AdminCarriers'
			find('#page-header-desc-carrier-new_carrier').click

			fill_in 'name', :with => options[:name]
			fill_in 'delay_1', :with => options[:delay] || 'Turtle'
			fill_in 'grade', :with => options[:grade] if options[:grade]
			fill_in 'url', :with => options[:tracking_url] if options[:tracking_url]

			click '.buttonNext.btn.btn-default'

			click_label_for "shipping_handling_#{onoff options[:with_handling_fees]}"
			click_label_for "is_free_#{onoff options[:free_shipping]}"

			choose options[:based_on] == :price ? 'billing_price' : 'billing_weight'

			select_by_value '#id_tax_rules_group', (options[:tax_group_id] || 0)

			select_by_value '#range_behavior', (options[:out_of_range_behavior] === :disable ? 1 : 0)


			options[:ranges] = options[:ranges] || [{:from_included => 0, :to_excluded => 1000, :prices => {0 => 0}}]
			options[:ranges].each_with_index do |range, i|

				if i > 0
					click '#add_new_range'
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

			click '.buttonNext.btn.btn-default'

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

			click '.buttonNext.btn.btn-default'

			click_label_for 'active_on'
			sleep 4 #this wait seems necessary, strange
			click 'a.buttonFinish'
			standard_success_check
		end
	end
end
