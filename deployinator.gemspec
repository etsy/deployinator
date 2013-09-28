# encoding: utf-8

Gem::Specification.new do |spec|
  spec.name          = 'deployinator'
  spec.version       = '1.0.0'
  spec.authors       = ['Etsy']
  spec.email         = ['no-reply@example.com']
  spec.description   = 'Deploy code like Etsy!'
  spec.summary       = spec.summary
  spec.homepage      = 'https://github.com/etsy/deployinator'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'json', '~> 1.7.7'
  spec.add_runtime_dependency 'mustache'
  spec.add_runtime_dependency 'open4'
  spec.add_runtime_dependency 'pony'
  spec.add_runtime_dependency 'rack', '~> 1.5.2'
  spec.add_runtime_dependency 'rake'
  spec.add_runtime_dependency 'sinatra'
  spec.add_runtime_dependency 'tlsmail'

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'capybara', '~> 1.1.4'
  spec.add_development_dependency 'foreman'
  spec.add_development_dependency 'nokogiri', '~> 1.4.7' # for ruby 1.8.6
  spec.add_development_dependency 'puma'
end
