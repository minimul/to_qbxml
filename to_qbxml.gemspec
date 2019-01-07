# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'to_qbxml/version'

Gem::Specification.new do |gem|
  gem.name          = "to_qbxml"
  gem.version       = ToQbxml::VERSION
  gem.authors       = ["Christian Pelczarski (minimul)"]
  gem.email         = ["christian@minimul.com"]
  gem.description   = %q{Ruby Hash to QuickBooks XML Request}
  gem.summary       = %q{Takes Ruby Hash and turns it into QuickBooks XML Request}
  gem.homepage      = "http://minimul.com"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency('activesupport', '>= 3.2')
  gem.add_dependency('nokogiri', '>= 1.6')
  gem.add_dependency('builder', '>= 3.0')
  gem.add_dependency('json', '>= 1.8')

  gem.add_development_dependency('bundler')
  gem.add_development_dependency('rake')
  gem.add_development_dependency('rspec')
end
