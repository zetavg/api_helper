# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'api_helper/version'

Gem::Specification.new do |spec|
  spec.name          = "api_helper"
  spec.version       = APIHelper::VERSION
  spec.authors       = ["Neson"]
  spec.email         = ["neson@dex.tw"]

  spec.summary       = %q{Helpers for creating standard web API.}
  spec.description   = %q{Helpers for creating standard web API for Rails or Grape with ActiveRecord.}
  spec.homepage      = "https://github.com/Neson/APIHelper"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"

  spec.add_development_dependency "activesupport", ">= 3"
end
