# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rdupes/version'

Gem::Specification.new do |spec|
  spec.name          = 'rdupes'
  spec.version       = Rdupes::VERSION
  spec.authors       = ['Harold Waterkeyn']
  spec.email         = ['hwaterke@users.noreply.github.com']

  spec.summary       = %q{Wrapper around fdupes}
  spec.description   = %q{Find and delete duplicate files}
  spec.homepage      = 'https://github.com/hwaterke/rdupes'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'colorize'
  spec.add_development_dependency 'bundler', '~> 1.13'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
end
