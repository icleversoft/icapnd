# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'icapnd/version'

Gem::Specification.new do |spec|
  spec.name          = "icapnd"
  spec.version       = Icapnd::VERSION
  spec.authors       = ["iCleversoft"]
  spec.email         = ["iphone@icleversoft.com"]
  spec.summary       = %q{An APN server & library in which EventMachine daemons maintain a persistent connection to Apple servers and Redis acts as the glue with your Apps.}
  spec.description   = %q{Simple Server for sending Apple Push Notification messages.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
end
