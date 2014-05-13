module PrestaShopAutomation
	module ProductsActions
		#todo: ecotax
		def create_product options
			goto_admin_tab 'AdminProducts'

			find('#page-header-desc-product-new_product').click

			fill_in 'name_1', :with => options[:name]
			sleep 2
			click '#link-Seo'
			expect_not_to have_field('link_rewrite_1', with: "")

			click '#link-Prices'
			fill_in 'priceTE', :with => options[:price]

			if options[:tax_group_id]
				select_by_value '#id_tax_rules_group', options[:tax_group_id]
			end

			if sp = options[:specific_price]
				save_product

				click '#show_specific_price'

				if m = /^minus\s+(\d+(?:\.\d+)?)\s+tax\s+included$/.match(sp.strip)
					select_by_value '#sp_reduction_type', 'amount'
					fill_in 'sp_reduction', :with => m[1]
				elsif m = /^minus\s+(\d+(?:\.\d+)?)\s*%$/.match(sp.strip)
					select_by_value '#sp_reduction_type', 'percentage'
					fill_in 'sp_reduction', :with => m[1]
				else
					throw "Invalid specific price: #{sp}"
				end
			end

			save_product

			# allow ordering if out of stock
			click '#link-Quantities'
			choose 'out_of_stock_2'

			save_product

			return current_url[/\bid_product=(\d+)/, 1].to_i
		end

		private
		def save_product andWait=2
			click_button_named 'submitAddproductAndStay', :first => true
			standard_success_check
			sleep andWait
		end
	end
end
