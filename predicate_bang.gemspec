# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'predicate_bang/version'

Gem::Specification.new do |spec|
  spec.name          = 'predicate_bang'
  spec.version       = PredicateBang::VERSION
  spec.authors       = ["Faraz Yashar"]
  spec.email         = ["faraz.yashar@gmail.com"]
  spec.summary       = "Convert your predicate_methods? into bang_methods! without
abusing method_missing"
  spec.description   = "Convert your predicate_methods? into bang_methods! without
abusing method_missing."
  spec.homepage      = 'https://github.com/fny/predicate_bang'
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'minitest', '~> 5.5'

  spec.required_ruby_version = '>= 2.0.0'
end
