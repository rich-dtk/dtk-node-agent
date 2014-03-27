require 'puppet'

module MCollective
  module Util
    class PuppetRunner

      def self.apply(puppet_definition, resource_hash)
        Puppet.settings.initialize_global_settings
        Puppet.settings.initialize_app_defaults(Puppet::Settings.app_defaults_for_run_mode(Puppet.run_mode))

        pup = Puppet::Type.type(puppet_definition).new(resource_hash)
        catalog = Puppet::Resource::Catalog.new
        catalog.add_resource pup
        catalog.apply
        true
      end

    end
  end
end