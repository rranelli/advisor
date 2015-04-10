lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'advisor/version'

Gem::Specification.new do |spec|
  spec.name = 'advisor'
  spec.version = Advisor::VERSION
  spec.required_ruby_version = '~>2.0'

  spec.summary  = 'AOP without the AOP magic'
  spec.authors  = ['Renan Ranelli']
  spec.email    = ['renanranelli@gmail.com']
  spec.homepage = 'http://github.com/rranelli/advisor'
  spec.license  = 'MIT'

  spec.files       = `git ls-files -z`.split("\x0")
  spec.executables = spec.files.grep(/^bin\//) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'pry'
end
