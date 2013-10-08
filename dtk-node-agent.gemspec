# -*- encoding: utf-8 -*-
require File.expand_path('../lib/dtk-node-agent/version', __FILE__)
prod_version_path = File.expand_path('../lib/dtk-node-agent/prod_version', __FILE__)
if File.exist?("#{prod_version_path}.rb")
  require prod_version_path
else
  DtkNodeAgent::PROD_VERSION = nil
end

Gem::Specification.new do |gem|
  gem.authors       = ["Rich PELAVIN"]
  gem.email         = ["rich@reactor8.com"]
  gem.description   = %q{DTK node agent is tool used to install and configure DTK agents.}
  gem.summary       = %q{DTK ndoe agent tool.}
  gem.homepage      = "https://github.com/rich-reactor8/dtk-node-agent"

  gem.files = %w(README.md Gemfile Gemfile.lock dtk-node-agent.gemspec)
  gem.files += Dir.glob("bin/**/*")
  gem.files += Dir.glob("lib/**/*")
  gem.files += Dir.glob("puppet_additions/**/*")
  gem.files += Dir.glob("mcollective_additions/**/*")
  gem.files += Dir.glob("src/**/*")
  
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "dtk-client"
  gem.require_paths = ["lib"]
  gem.version       = DtkNodeAgent::PROD_VERSION || DtkNodeAgent::VERSION

  gem.add_dependency 'facter','~> 1.7'
  gem.add_dependency 'trollop' ,'~> 2.0'

end