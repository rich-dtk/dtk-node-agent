require 'puppet'

module MCollective
  module Util
    class PuppetRunner

      def self.apply(puppet_definition, resource_hash)
        pup = Puppet::Type.type(puppet_definition).new(resource_hash)
        catalog = Puppet::Resource::Catalog.new
        catalog.add_resource pup
        catalog.apply
        true
      end

    end
  end
end