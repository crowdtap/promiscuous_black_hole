# encoding: utf-8
Gem::Specification.new do |s|
  s.name        = 'promiscuous_black_hole'
  s.version     = '0.1.0'
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Crowdtap']
  s.email       = 'devs@crowdtap.com'
  s.summary     = 'Normalize and record all data published through promiscuous'
  s.description = 'Normalize and record all data published through promiscuous'
  s.homepage    = 'https://github.com/crowdtap/normcore2'
  s.license     = 'MIT'

  s.add_dependency 'pg'
  s.add_dependency 'promiscuous'
  s.add_dependency 'sequel'
  s.add_dependency 'newrelic_rpm'

  s.add_development_dependency 'bundler'
  s.add_development_dependency 'mongoid'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'rspec', '~> 3.0'

  s.files        = Dir['**/*.rb']
  s.require_path = 'lib'
  s.has_rdoc     = false
end
