# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'tableau_ruby/version'

Gem::Specification.new do |spec|
  spec.name          = "tableau_ruby"
  spec.version       = TableauRuby::VERSION
  spec.authors       = ["Trax Web Team"]
  spec.email         = ["webteam@traxtech.com"]
  spec.summary       = %q{The unnoficial ruby client for the Tableau api.}
  spec.description   = %q{The unnoficial ruby client for the Tableau api.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "faraday", '~> 0.9'
  spec.add_runtime_dependency "nokogiri", '~> 1.6'
  spec.add_runtime_dependency "faraday_middleware", "0.9.1"
  spec.add_runtime_dependency 'oj', '2.12.5'

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "5.6.0"
  spec.add_development_dependency "mocha", "1.1.0"
  spec.add_development_dependency 'byebug'
end
