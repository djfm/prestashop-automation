module PrestaShopAutomation
	module GeneralHelpers

		def onoff val
			val ? 'on' : 'off'
		end

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

		def select_by_value select_selector, value
			within select_selector do
				find("option[value='#{value}']").click
			end
		end

		def select_by_value_jqChosen select_selector, value
			options = Hash[all("#{select_selector} option", :visible => false).to_a.each_with_index.map do |option, i|
				[option['value'], i]
			end]
			expect(options[value]).not_to be nil
			container = find("#{select_selector} + .chosen-container")
			container.click
			within container do
				click "li[data-option-array-index='#{options[value]}']"
			end
		end

		def click selector
			find(selector).click
		end

		def expect_to matcher
			expect(self).to matcher
		end

		def expect_not_to matcher
			expect(self).not_to matcher
		end

		def standard_success_check
			expect_to have_selector '.alert.alert-success'
		end

		def visit base, rest=nil
			if rest == nil
				super base
			else
				super base.sub(/\/\s*/, '') + rest.sub(/^\s*\//, '')
			end
		end

		def wait_until options = {}, &block
			elapsed = 0
			dt = options[:interval] || 1
			timeout = options[:timeout] || 60
			until (ok = yield) or (elapsed > timeout)
				elapsed += sleep dt
			end
			unless ok
				throw "Timeout exceeded!"
			end
		end
	end
end
