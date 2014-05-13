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
	end
end
