require 'shellwords'

module PrestaShopAutomation
	module OrdersActions

		def add_product_to_cart id, quantity=1
			visit @front_office_url, "/index.php?id_product=#{id}&controller=product&id_lang=1"
			fill_in 'quantity_wanted', :with => (quantity || 1)
			find('#add_to_cart button').click
			sleep 1
		end

		def add_products_to_cart products
			products.each do |product|
				add_product_to_cart product[:id], product[:quantity]
			end
		end

		def order_current_cart_5_steps options
			visit @front_office_url, "/index.php?controller=order"
			find('a.standard-checkout').click
			find('button[name="processAddress"]').click
			click_label_for "cgv"
			click_label_for "gift" if options[:gift_wrapping]
			find(:xpath, '//tr[contains(., "'+options[:carrier]+'")]').find('input[type=radio]', :visible => false).click
			click_button_named 'processCarrier'
			click 'a.bankwire'
			click '#cart_navigation button'
			order_id = current_url[/\bid_order=(\d+)/, 1].to_i
			expect(order_id).to be > 0
			return order_id
		end

		def order_current_cart_opc options
			visit @front_office_url, "/index.php?controller=order-opc"
			visit @front_office_url, "/index.php?controller=order-opc" #yeah, twice, there's a bug
			click_label_for "cgv"
			click_label_for "gift" if options[:gift_wrapping]
			find(:xpath, '//tr[contains(., "'+options[:carrier]+'")]').find('input[type=radio]', :visible => false).click
			click 'a.bankwire'
			click '#cart_navigation button'
			order_id = current_url[/\bid_order=(\d+)/, 1].to_i
			expect(order_id).to be > 0
			return order_id
		end

		def validate_order options
			goto_admin_tab 'AdminOrders'

			visit @back_office_url, first('td.pointer[onclick]')['onclick'][/\blocation\s*=\s*'(.*?)'/, 1].sub(/\bid_order=\d+/, "id_order=#{options[:id]}")
			click '#id_order_state_chosen'
			click 'li[data-option-array-index="6"]' #hardcoded for now: payment accepted
			click_button_named 'submitState'
			pdf_url = find('a[href*="generateInvoicePDF"]')['href']

			if options[:dump_pdf_to]
				all_cookies = driver.browser.manage.all_cookies
				cookies = all_cookies.map do |c| "#{c[:name]}=#{c[:value]}" end.join ";"
					cmd = "curl --url #{Shellwords.shellescape pdf_url} -b \"#{cookies}\" -o #{Shellwords.shellescape options[:dump_pdf_to]} 2>/dev/null"
					`#{cmd}` #download the PDF
			end

			if options[:get_invoice_json]
				visit pdf_url+'&debug=1'
				return JSON.parse(find('body').text)
			end
		end
	end
end
