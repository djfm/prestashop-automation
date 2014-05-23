require 'mysql2'

module PrestaShopAutomation
	module InstallerActions

		def install options={}
			if options[:prepare_database]
				prepare_database
			end

			visit @installer_url
			select_by_value '#langList', options[:language] || 'en'
			click '#btNext'
			click_label_for 'set_license'
			click '#btNext'

			fill_in 'infosShop', :with => options[:shop_name] || @database_name
			if has_selector? "input[name='db_mode']"
				find("input[name='db_mode'][value='#{options[:no_demo_products] ? 'lite' : 'full'}']").click
			end
			select_by_value_jqChosen '#infosCountry', options[:country] || 'us'

			if options[:timezone]
				select_by_value_jqChosen '#infosTimezone', options[:timezone]
			end

			fill_in 'infosFirstname', :with => options[:admin_firstname] || @admin_firstname || 'John'
			fill_in 'infosName', :with => options[:admin_lastname] || @admin_lastname || 'Doe'
			fill_in 'infosEmail', :with => options[:admin_email] || @admin_email || 'pub@prestashop.com'
			password = options[:admin_password] || @admin_password || '123456789'
			fill_in 'infosPassword', :with => password
			fill_in 'infosPasswordRepeat', :with => password

			if options[:newsletter]
				check 'infosNotification'
			else
				uncheck 'infosNotification'
			end

			click '#btNext'

			fill_in 'dbServer', :with => "#{@database_host}:#{@database_port}"
			fill_in 'dbName', :with => @database_name
			fill_in 'dbLogin', :with => @database_user
			fill_in 'dbPassword', :with => @database_password
			fill_in 'db_prefix', :with => @database_prefix

			click '#btTestDB'

			if options[:prepare_database]
				#db should be ok if we used :prepare_database
				expect_to have_selector '#dbResultCheck.okBlock'
			else
				check 'db_clear' if has_selector? 'db_clear'
				expect_to have_selector '#dbResultCheck.errorBlock'
				click '#btCreateDB'
				expect_to have_selector '#dbResultCheck.okBlock'
			end

			click '#btNext'

			wait_until do
				has_selector? 'a.BO' and has_selector? 'a.FO'
			end
		end

		def add_module_from_repo repo, branch=nil
			b = branch ? ['-b', branch] : []
			unless system 'git', 'clone', repo, *b, :chdir => File.join(@filesystem_path, 'modules')
				throw "Could not clone '#{repo}' into '#{@filesystem_path}'"
			end
		end

		def install_module name
			goto_admin_tab 'AdminModules'
			link = first("a[href*='install='][href*='controller=AdminModules']", :visible => false)['href']
			randomname = link[/\binstall=([^&?#]+)/, 1]
			link.gsub! randomname, name
			visit link
			#check that the entry was added to the DB
			expect(client.query("SELECT * FROM #{safe_database_name}.#{@database_prefix}module WHERE name='#{client.escape name}'").count).to be 1
		end

		def update_all_modules
			goto_admin_tab 'AdminModules'
			if has_selector? '#desc-module-update-all'
				click '#desc-module-update-all'
				goto_admin_tab 'AdminModules'
				expect_to have_selector '#desc-module-check-and-update-all'
			end
		end

		def drop_database
			client.query("DROP DATABASE IF EXISTS #{safe_database_name}")
		end

		def database_exists
			count = client.query("SHOW DATABASES LIKE '#{client.escape @database_name}'").count
			expect(count).to be <= 1
			count == 1
		end

		def prepare_database
			if !database_exists
				client.query "CREATE DATABASE #{safe_database_name}"
			else
				tables = client.query("SHOW TABLES IN #{safe_database_name} LIKE '#{client.escape @database_prefix}%'")
				tables.each do |row|
					table = row.values[0]
					client.query "DROP TABLE #{safe_database_name}.`#{table}`"
				end
			end
		end

		private

		def safe_database_name
			"`#{@database_name.gsub '`', ''}`"
		end

		def client
			return @client if @client

			@client = Mysql2::Client.new({
				host: @database_host,
				username: @database_user,
				password: @database_password,
				port: @database_port
			})
		end
	end
end
