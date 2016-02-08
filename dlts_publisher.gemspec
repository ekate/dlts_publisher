# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dlts_publisher/version'

Gem::Specification.new do |spec|
  spec.name          = "dlts_publisher"
  spec.version       = DltsPublisher::VERSION
  spec.authors       = ["Kate Pechekhonova"]
  spec.email         = ["ekate@nyu.edu"]
  spec.summary       = "Gem to publish DLTS books"
  spec.description   = " This gem is used to publish DLTS books.You need collection_path, script and rstar credentials"  
  spec.homepage      = ""
  spec.license       = ""

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
end
