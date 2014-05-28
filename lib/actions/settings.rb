module PrestaShopAutomation
	module SettingsActions

		def set_rounding_rule option
			goto_admin_tab 'AdminPreferences'

			value = {:item => 1, :line => 2, :total => 3}[option.to_sym]

			if value

				if !has_selector? '#PS_ROUND_TYPE' and option.to_sym == :line
					#we don't have the option, but we asked for the default, so that's OK
					return
				end

				select_by_value '#PS_ROUND_TYPE', value
				click_button_named 'submitOptionsconfiguration', :first => true
				standard_success_check
			else
				throw "Unsupported option: #{option}"
			end
		end

		def set_rounding_method option
			mapping = {
				up: 0,
				down: 1,
				half_up: 2,
				half_down: 3,
				half_even: 4,
				half_odd: 5
			}

			goto_admin_tab 'AdminTaxes'
			value = mapping[option.to_sym]

			if value
				goto_admin_tab 'AdminPreferences'
				select_by_value '#PS_PRICE_ROUND_MODE', value
				click_button_named 'submitOptionsconfiguration', :first => true
				standard_success_check
			else
				throw "Unsupported option: #{option}"
			end
		end

		def set_friendly_urls on
			goto_admin_tab 'AdminMeta'
			if on
				click_label_for 'PS_REWRITING_SETTINGS_on'
			else
				click_label_for 'PS_REWRITING_SETTINGS_off'
			end
			click_button_named 'submitOptionsmeta', :first => true
			standard_success_check
		end

		def set_gift_wrapping_option on, options={}
			goto_admin_tab 'AdminOrderPreferences'
			if on
				click_label_for 'PS_GIFT_WRAPPING_on'
				find('input[name="PS_GIFT_WRAPPING_PRICE"]').set options[:price]
				select_by_value '#PS_GIFT_WRAPPING_TAX_RULES_GROUP', (options[:tax_group_id] || 0)
				click_label_for "PS_RECYCLABLE_PACK_#{onoff options[:recycling_option]}"
			else
				click_label_for 'PS_GIFT_WRAPPING_off'
			end
			click_button_named 'submitOptionsconfiguration', :first => true
			standard_success_check
		end

		def set_order_process_type value
			goto_admin_tab 'AdminOrderPreferences'
			select_by_value '#PS_ORDER_PROCESS_TYPE', {:five_steps => 0, :opc => 1}[value]
			click_button_named 'submitOptionsconfiguration', :first => true
			standard_success_check
		end

		def set_ecotax_option on, tax_group_id=nil
			goto_admin_tab 'AdminTaxes'
			click_label_for "PS_USE_ECOTAX_#{onoff on}"
			click_button_named 'submitOptionstax', :first => true
			standard_success_check

			if on and tax_group_id
				goto_admin_tab 'AdminTaxes' #for some reason, we need to refresh here
				select_by_value '#PS_ECOTAX_TAX_RULES_GROUP_ID', tax_group_id
				click_button_named 'submitOptionstax', :first => true
				standard_success_check
			end
		end

	end
end
