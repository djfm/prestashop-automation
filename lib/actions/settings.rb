module PrestaShopAutomation
	module SettingsActions
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
	end
end
