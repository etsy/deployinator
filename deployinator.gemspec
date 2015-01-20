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
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_development_dependency "mocha"

  gem.add_runtime_dependency "rake"
  gem.add_runtime_dependency "json"
  gem.add_runtime_dependency "mustache", "~> 0.99"
  gem.add_runtime_dependency "pony"
  gem.add_runtime_dependency "tlsmail"
  gem.add_runtime_dependency "eventmachine"
  gem.add_runtime_dependency "eventmachine-tail"
  gem.add_runtime_dependency "em-websocket"
  gem.add_runtime_dependency "sinatra", ">=1.4.3"
end
