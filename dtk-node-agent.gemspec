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
  gem.description   = %q{The DTK Node Agent runs on your nodes that you wish to manage using your DTK Server.  It comes pre-installed on all nodes created/managed by hosted DTK Server accounts.}
  gem.summary       = %q{DTK Node Agent gem.}
  gem.homepage      = "https://github.com/rich-reactor8/dtk-node-agent"
  gem.licenses      = ["GPL-3.0"]

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

  gem.add_dependency 'puppet', '~> 3.3.2'
  gem.add_dependency 'facter', '~> 1.7.3'
  gem.add_dependency 'grit', '~> 2.5.0'
  gem.add_dependency 'stomp', '~> 1.3.1'
  gem.add_dependency 'sshkeyauth', '~> 0.0.11'
  gem.add_dependency 'serverspec', '~> 1.1.0'
  gem.add_dependency 'specinfra', '~> 1.0.4'

end
