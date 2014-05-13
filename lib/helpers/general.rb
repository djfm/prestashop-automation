module PrestaShopAutomation
	module GeneralHelpers

		def click_label_for id
			find("label[for='#{id}']").click
		end

		def click_button_named name, options={}
			selector = "button[name='#{name}']"
			if options[:first]
				first(selector).click
			else
				find(selector).click
			end
		end

		def click selector
			find(selector).click
		end

		def expect_to matcher
			expect(self).to matcher
		end

		def standard_success_check
			expect_to have_selector '.alert.alert-success'
		end
	end
end
