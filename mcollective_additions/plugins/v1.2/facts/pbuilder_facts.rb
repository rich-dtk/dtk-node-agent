require 'open-uri'
require 'timeout'
require 'yaml'

module MCollective
  module Facts
    # A factsource for pbuilder
    class Pbuilder_facts < Base

      def load_facts_from_source
        ret = {"pbuilderid" => get_pbuilderid()}
        yaml_file = '/etc/mcollective/facts.yaml'
        if File.exists?(yaml_file)
          yaml_facts = YAML.load_file(yaml_file)
          ret.merge!(yaml_facts)
        end
        ret
      end

      def get_pbuilderid()
        ret = nil
        begin
          addr = "169.254.169.254"
          wait_sec = 2
          Timeout::timeout(wait_sec) {open("http://#{addr}:80/")}
          ret = OpenURI.open_uri("http://#{addr}/2008-02-01/meta-data/instance-id").read
        rescue Timeout::Error
        rescue
          #TODO: unexpected; write to log what error is
        end
        ret
      end
    end
  end
end
