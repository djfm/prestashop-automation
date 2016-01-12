Gem::Specification.new do |s|
	s.name = 'prestashop-automation'
	s.version = '0.9.3'
	s.date = '2014-05-14'
	s.description = "WARNING: No longer much maintained. A ruby framework to build complex selenium tests around PrestaShop.\nThis gem provides building blocks to create advanced test scenarios in a very consise way."
	s.summary = 'Framework to test and automate tasks in PrestaShop.'
	s.authors = ["François-Marie de Jouvencel"]
	s.email = 'fm.de.jouvencel@gmail.com'
	s.files = Dir.glob("{lib,test}/**/*")
	s.homepage = 'https://github.com/djfm/prestashop-automation'
	s.license = 'OSL'

	s.add_runtime_dependency 'mysql2', '~> 0'
	s.add_runtime_dependency 'selenium-webdriver', '~> 2.48', '>= 2.48.1'
	s.add_runtime_dependency 'capybara', '~> 0'
	s.add_runtime_dependency 'rspec', '~> 3.4', '>= 3.4.0'
end
