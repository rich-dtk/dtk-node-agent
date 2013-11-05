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
  gem.name          = "dtk-node-agent"
  gem.require_paths = ["lib"]
  gem.version       = DtkNodeAgent::PROD_VERSION || "#{DtkNodeAgent::VERSION}.#{ARGV[3]}".chomp(".")

  gem.add_dependency 'puppet', '~> 2.7.23'
  gem.add_dependency 'facter', '~> 1.7.3'
  gem.add_dependency 'grit', '~> 2.5.0'
  gem.add_dependency 'stomp', '~> 1.3.1'
  gem.add_dependency 'sshkeyauth', '~> 0.0.11'

end