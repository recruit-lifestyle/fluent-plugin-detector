# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |gem|
  gem.name          = "fluent-plugin-detector"
  gem.version       = "0.0.1"
  gem.authors       = ["mihirat"]
  gem.email         = ["mihirat@r.recruit.co.jp"]

  gem.description   = "Fluentd plugin to filter logs with desired encoding."
  gem.summary       = gem.description
  gem.homepage      = "TODO: Put your gem's website or public repo URL here."
  gem.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if gem.respond_to?(:metadata)
    gem.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  gem.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|gem|features)/}) }
  gem.test_files  = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.executables   = gem.files.grep(%r{^exe/}) { |f| File.basename(f) }
  gem.require_paths = ["lib"]

  gem.add_dependency "fluentd", ">= 0.12.0"
  gem.add_development_dependency "bundler", "~> 1.12"
  gem.add_development_dependency "rake"
  gem.add_development_dependency "test-unit"
end
