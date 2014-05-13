#!/usr/bin/ruby

require_relative 'lib/prestashop.rb'

ps = PrestaShopAutomation::PrestaShop.new({
        :back_office_url => 'http://partners16.fmdj.fr/admin-dev/',
        :front_office_url => 'http://partners16.fmdj.fr/',
        :admin_email => 'pub@prestashop.com',
        :admin_password => '123456789'
})

ps.login_to_back_office

sleep 15
