Gem::Specification.new do |s|
	s.name = 'prestashop-automation'
	s.version = '0.8.4'
	s.date = '2014-05-14'
	s.description = "A nice ruby framework to build complex selenium tests around PrestaShop.\nThis gem provides building blocks to create advanced scenarios in a very consise way."
	s.summary = 'Framework to test and automate tasks in PrestaShop.'
	s.authors = ["François-Marie de Jouvencel"]
	s.email = 'fm.de.jouvencel@gmail.com'
	s.files = Dir.glob("{lib,test}/**/*")
	s.homepage = 'https://github.com/djfm/prestashop-automation'
	s.license = 'OSL'
	%w(mysql2 selenium-webdriver capybara rspec).each do |dep|
		s.add_runtime_dependency dep
	end
end
