require 'facter'
module MCollective
  module Facts
    require 'yaml'
    # A factsource for pbuilder
    class Pbuilder_facts < Base
      #TODO: stub that right now just returns pbuilderid
      @@facts = Hash.new

      def load_facts_from_source
        unless @@facts["pbuilderid"] 
          begin
            Facter.ec2_instance_id
           rescue 
            Facter.loadfacts()
          end
          @@facts["pbuilderid"] = Facter.value('ec2_instance_id')
        end
        #TODO: hard coded file location
        fact_paths = %w{/etc/mcollective/facts.yaml}
        fact_paths.each do |yaml_file|
          if File.exists?(yaml_file)
            yaml_facts = YAML.load_file(yaml_file)
            @@facts.merge!(yaml_facts)
          end
        end
        @@facts 
      end
    end
  end
end
