require 'bundler/setup'
require 'rspec'
require 'capybara'
require 'shellwords'
require 'selenium/webdriver'

require_relative 'actions/general.rb'
require_relative 'actions/settings.rb'
require_relative 'actions/products.rb'
require_relative 'actions/taxes.rb'
require_relative 'actions/carriers.rb'
require_relative 'actions/cart_rules.rb'
require_relative 'actions/orders.rb'
require_relative 'actions/installer.rb'
require_relative 'actions/users.rb'

require_relative 'helpers/general.rb'

module PrestaShopAutomation

	class PrestaShop < Capybara::Session

		unless @drivers_defined
			Capybara.register_driver :selenium_with_long_timeout do |app|
			  client = Selenium::WebDriver::Remote::Http::Default.new
			  client.timeout = 300
			  Capybara::Selenium::Driver.new(app, :browser => :firefox, :http_client => client)
			end
			@drivers_defined = true
		end

        include RSpec::Expectations
        include RSpec::Matchers

		include PrestaShopAutomation::GeneralHelpers

		include PrestaShopAutomation::GeneralActions
		include PrestaShopAutomation::SettingsActions
        include PrestaShopAutomation::ProductsActions
        include PrestaShopAutomation::TaxesActions
        include PrestaShopAutomation::CarriersActions
        include PrestaShopAutomation::CartRulesActions
		include PrestaShopAutomation::OrdersActions
        include PrestaShopAutomation::InstallerActions
        include PrestaShopAutomation::UsersActions

		# Rspec defines this method, but we want the one from  Capybara::Session
		def all *args
			Capybara::Session.instance_method(:all).bind(self).call *args
		end

		def initialize options

			@front_office_url = options[:front_office_url]
			@back_office_url  = options[:back_office_url]
            @installer_url = options[:installer_url]
			@admin_email = options[:admin_email] || 'pub@prestashop.com'
			@admin_password = options[:admin_password] || '123456789'
			@default_customer_email = options[:default_customer_email] || 'pub@prestashop.com'
			@default_customer_password = options[:default_customer_password] || '123456789'
			@database_user = options[:database_user] || 'root'
			@database_password = options[:database_password] || ''
			@database_name = options[:database_name]
			@database_prefix = options[:database_prefix] || 'ps_'
			@database_port = options[:database_port] || '3306'
			@database_host = options[:database_host] || 'localhost'
            @filesystem_path = options[:filesystem_path]
			@version = options[:version]

			@dumps = []

			super :selenium_with_long_timeout
		end

        def quit
            driver.browser.quit
        end

		def dump_database target
			if database_exists
				cmd = "mysqldump -uroot "
				if @database_password.to_s.strip != ''
					cmd += "-p#{Shellwords.shellescape @database_password} "
				end
				cmd += "-h#{Shellwords.shellescape @database_host} "
				cmd += "-P#{@database_port} "
				cmd += "#{Shellwords.shellescape @database_name} "
				cmd += "> #{Shellwords.shellescape target}"
				`#{cmd}`
				if !$?.success?
					throw "Could not dump database!"
				end
				return true
			else
				return false
			end
		end

		def load_database src
			prepare_database
			cmd = "mysql -uroot "
			if @database_password.to_s.strip != ''
				cmd += "-p#{Shellwords.shellescape @database_password} "
			end
			cmd += "-h#{Shellwords.shellescape @database_host} "
			cmd += "-P#{@database_port} "
			cmd += "#{Shellwords.shellescape @database_name} "
			cmd += "< #{Shellwords.shellescape src}"
			`#{cmd}`
			return $?.success?
		end

		def clear_cookies
			reset!
		end

		def save
			out = {
				:database => nil,
				:files => nil
			}

			if database_exists
				out[:database] = Tempfile.new 'prestashop-db'
				dump_database out[:database].path
			end

			@dumps << out

			return out
		end

		def restore dump=nil
			unless dump
				dump = @dumps.pop
			end

			if dump[:database]
				load_database dump[:database].path
			end
		end

	end
end
