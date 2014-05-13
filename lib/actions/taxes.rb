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
	end
end
