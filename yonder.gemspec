# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('./lib')

require 'yonder/version'

Gem::Specification.new do |s|
  s.name = 'yonder'
  s.version = Yonder::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors = ['Daniel Bogan']
  s.email = ['d+yonder@waferbaby.com']
  s.homepage = 'http://github.com/waferbaby/yonder'
  s.summary = 'A Bluesky API gem'
  s.description = "A gem for interacting with Bluesky's API."
  s.license = 'MIT'

  s.required_ruby_version = '> 3.3'

  s.files = Dir['lib/**/*']
  s.require_path = 'lib'

  s.add_runtime_dependency 'httpx', '~> 1.5'

  s.metadata['rubygems_mfa_required'] = 'true'
end
