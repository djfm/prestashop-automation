module PrestaShopAutomation
	module TaxesActions

		def create_tax options
			goto_admin_tab 'AdminTaxes'
			click '#page-header-desc-tax-new_tax'
			fill_in 'name_1', :with => options[:name]
			fill_in 'rate', :with => options[:rate]
			click_label_for 'active_on'
			click '#tax_form_submit_btn'
			standard_success_check
			return current_url[/\bid_tax=(\d+)/, 1].to_i
		end

		def create_tax_group options
			goto_admin_tab 'AdminTaxRulesGroup'
			find('#page-header-desc-tax_rules_group-new_tax_rules_group').click
			fill_in 'name', :with => options[:name]
			click_label_for 'active_on'
			click '#tax_rules_group_form_submit_btn'
			standard_success_check

			options[:taxes].each do |tax|
				find('#page-header-desc-tax_rule-new').click
				select_by_value '#country', (tax[:country_id] || 0)
				select_by_value '#behavior', {:no => 0, :sum => 1, :multiply => 2}[tax[:combine] || :no]
				select_by_value '#id_tax', tax[:tax_id]
				click '#tax_rule_form_submit_btn'
				standard_success_check
			end

			return current_url[/\bid_tax_rules_group=(\d+)/, 1].to_i
		end

		def create_tax_group_from_rate rate, taxes_pool={}
			if /^(?:\d+(?:.\d+)?)$/ =~ rate.to_s
				tax_id = create_tax :name => "#{rate}% Tax (Rate)", :rate => rate
				taxes_pool[rate] ||= create_tax_group :name => "#{rate}% Tax (Group)", :taxes => [{:tax_id => tax_id}]
			elsif /(?:\d+(?:.\d+)?)(?:\s*(?:\+|\*)\s*(?:\d+(?:.\d+)?))+/ =~ rate
				taxes = []
				combine = {'+' => :sum, '*' => :multiply}[rate[/(\+|\*)/, 1]] || :no
				rate.split(/\s+/).each do |token|
					if token == '+'
						combine = :sum
					elsif token == '*'
						combine = :multiply
					else
						tax_id = taxes_pool[rate] ||= (create_tax :name => "#{token}% Tax (Rate)", :rate => token)
						taxes << {
							:tax_id => tax_id,
							:combine => combine
						}
					end
				end
				create_tax_group :name => "Composite #{rate} Tax (Group)", :taxes => taxes
			else
				throw "Invalid tax rate format: #{rate}"
			end
		end

	end
end
