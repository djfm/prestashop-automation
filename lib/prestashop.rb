require 'rspec-expectations'
require 'capybara'
require 'capybara/rspec'

require_relative 'actions/general.rb'
require_relative 'actions/settings.rb'

require_relative 'helpers/general.rb'

module PrestaShopAutomation
	class PrestaShop < Capybara::Session

        include RSpec::Expectations
        include RSpec::Matchers
        include Capybara::RSpecMatchers

		include PrestaShopAutomation::GeneralHelpers
		include PrestaShopAutomation::GeneralActions
		include PrestaShopAutomation::SettingsActions


		def initialize options

			@front_office_url = options[:front_office_url]
			@back_office_url  = options[:back_office_url]
			@admin_email = options[:admin_email] || 'pub@prestashop.com'
			@admin_password = options[:admin_password] || '123456789'
			@default_customer_email = options[:default_customer_email] || 'pub@prestashop.com'
			@default_customer_password = options[:default_customer_password] || '123456789'
			@database_user = options[:database_user] || 'root'
			@database_password = options[:database_password] || ''
			@database_name = options[:database_name]
			@database_prefix = options[:database_prefix] || 'ps_'
			@database_port = options[:database_port] || '3306'
			@database_host = options[:database_host]
			@version = options[:version]

			super :selenium
		end

        def quit_browser
            driver.browser.quit
        end

	end
end
