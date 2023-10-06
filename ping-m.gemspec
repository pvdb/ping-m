# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ping/monitor'

Gem::Specification.new do |spec|
  spec.name          = Ping::Monitor::NAME
  spec.version       = Ping::Monitor::VERSION
  spec.authors       = ['Peter Vandenberk']
  spec.email         = ['pvandenberk@mac.com']

  spec.summary       = 'Continuously monitor ping performance'
  spec.description   = 'Monitor ping RTT in real-time & analyse recorded RTTs'
  spec.homepage      = 'https://github.com/pvdb/ping-m'
  spec.license       = 'MIT'

  spec.files         = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`
      .split("\x0")
      .reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = ['>= 3.3.0', '< 4.0.0']

  spec.add_dependency 'rainbow', '~> 3.0'

  spec.metadata['rubygems_mfa_required'] = 'true'
end
