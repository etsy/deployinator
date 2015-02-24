# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'deployinator/version'

Gem::Specification.new do |gem|
  gem.name          = "etsy-deployinator"
  gem.version       = Deployinator::VERSION
  gem.authors       = ["JPaul"]
  gem.email         = ["jpaul@etsy.com"]
  gem.description   = %q{Deployinator as a Gem}
  gem.summary       = %q{Rewrite of deployinator to be a gem}
  gem.homepage      = "http://github.com/etsy/Deployinator"
  gem.licenses      = ["MIT"]

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
  gem.required_ruby_version = '>= 1.9.3'

  gem.add_development_dependency "mocha", "~> 0.14"
  gem.add_development_dependency "minitest", "<= 4.2.0"

  gem.add_runtime_dependency "rake", "~> 10", ">= 10.3.2"
  gem.add_runtime_dependency "json", "~> 1.8"
  gem.add_runtime_dependency "mustache", "~> 0.99"
  gem.add_runtime_dependency "pony", "~> 1.5"
  gem.add_runtime_dependency "tlsmail", "~> 0.0"
  gem.add_runtime_dependency "eventmachine", "~> 1.0", ">= 1.0.4"
  gem.add_runtime_dependency "eventmachine-tail", "~> 0.6", ">= 0.6.4"
  gem.add_runtime_dependency "em-websocket", "~> 0.5", ">= 0.5.1"
  gem.add_runtime_dependency "sinatra", "~> 1.4", ">=1.4.3"
end
