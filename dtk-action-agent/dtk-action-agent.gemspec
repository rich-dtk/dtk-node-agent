# -*- encoding: utf-8 -*-
require File.expand_path('../lib/dtk-action-agent/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Rich PELAVIN"]
  gem.email         = ["rich@reactor8.com"]
  gem.description   = %q{The DTK Action Agent is designed to run commands on remote machine.}
  gem.summary       = %q{DTK Action Agent}
  gem.homepage      = ""
  gem.licenses      = ["GPL-3.0"]

  gem.files = %w(Gemfile dtk-action-agent.gemspec)
  gem.files += Dir.glob("bin/**/*")
  gem.files += Dir.glob("lib/**/*")

  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.name          = "dtk-action-agent"
  gem.require_paths = ["lib"]
  gem.version       = "#{DTK::ActionAgent::VERSION}.#{ARGV[3]}".chomp(".")

  gem.add_dependency 'posix-spawn','0.3.8'
  gem.add_dependency 'awesome_print', '1.1.0'

end
