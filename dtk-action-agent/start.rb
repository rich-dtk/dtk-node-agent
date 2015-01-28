require 'posix/spawn'
require File.expand_path("./lib/arbiter", File.dirname(__FILE__))


commands = [
  ['ls'],
  ['more /var/log/appstore.log'],
  ['git','pull'],
  ['ls'],
  ['git','status'],
  ['git','pull'],
  ['more /var/log/appstore.log'],
  ['git','status'],
  ['git','pull'],
  ['ls'],
  ['git','status'],
  ['git clone git@github.com:rich-reactor8/server.git'],
]

arbiter = DTK::Agent::Arbiter.new(commands)
arbiter.run
arbiter.results