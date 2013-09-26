$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "common_engine/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'common_engine'
  s.version     = CommonEngine::VERSION
  s.authors     = ['Josh Starcher', 'Justin Sabelko', 'Kurt Eichstadt']
  s.email       = ['programmers@cojourners.com']
  s.homepage    = 'http://cru.org'
  s.summary     = 'Collection of models and whatnot that are used across several cru apps.'
  s.description = 'Collection of models and whatnot that are used across several cru apps.'

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", ">= 3.0.0"
  s.add_dependency "sidekiq"
  s.add_dependency "global_registry"
  s.add_dependency 'aasm', '~> 3.0.9'
  s.add_dependency 'acts_as_list', '~> 0.1.8'
  s.add_dependency 'rubycas-client'

end
