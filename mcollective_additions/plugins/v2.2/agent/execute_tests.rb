module MCollective
  module Agent
    class Execute_tests < RPC::Agent
      def initialize()
        super()
        @log = Log.instance
      end

      action "execute_tests" do 
        #Get list of component modules that have spec tests
        list_output=`ls /etc/puppet/modules/*/dtk/serverspec/spec/localhost/*/*_spec.rb`
        regex_pattern=/modules\/(.+)\/dtk\/serverspec\/spec\/localhost\/(.+)\//
        ModuleInfo = Struct.new(:module_name, :component_name)
        modules_info = []

        components = []
        request[:components].each do |c|
          if c.include? "::"
            components << c.split("::").last
          elsif c.include? "/"
            components << c.split("/").last
          else
            components << c
          end
        end

        list_output.each do |line|
          match = line.match(regex_pattern)
          components.each do |c|
            if c.eql? match[2]
              modules_info << ModuleInfo.new(match[1],match[2])
            end
          end
        end

        all_spec_results = []
        #filter out redundant module info if any
        modules_info = modules_info.uniq
        modules_info.each do |module_info|
          component_module = module_info[:module_name]
          component = module_info[:component_name]

          spec_results=`/opt/puppet-omnibus/embedded/bin/rspec /etc/puppet/modules/#{component_module}/dtk/serverspec/spec/localhost/#{component}/*_spec.rb --format j`
          @log.info("Executing serverspec test: /etc/puppet/modules/#{component_module}/tests/serverspec/spec/localhost/#{component}/*_spec.rb")

          spec_results_json = JSON.parse(spec_results)

          spec_results_json['examples'].each do |spec|
            spec_result = {}
            spec_result.store(:module_name, component_module)
            spec_result.store(:component_name, component)
            spec_result.store(:test_result, spec['full_description'])
            spec_result.store(:status, spec['status'])
            all_spec_results << spec_result
          end
        end

        reply[:data] = all_spec_results
        reply[:pbuilderid] = Facts["pbuilderid"]
        reply[:status] = :ok
      end
    end
  end
end
