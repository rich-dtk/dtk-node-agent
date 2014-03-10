module MCollective
  module Agent
    class Execute_tests < RPC::Agent
      def initialize()
        super()
        @log = Log.instance
      end

      action "execute_tests" do 
        #Get list of component modules that have spec tests
        list_output=`ls /etc/puppet/modules/*/tests/serverspec/spec/localhost/*/*_spec.rb`
        regex_pattern=/modules\/(.+)\/tests\/serverspec\/spec\/localhost\/(.+)\//
        ModuleInfo = Struct.new(:module_name, :component_name)
        modules_info = []

        list_output.each do |line|
          match = line.match(regex_pattern)
          modules_info << ModuleInfo.new(match[1],match[2])
        end

        all_spec_results = []
        modules_info.each do |module_info|
          component_module = module_info[:module_name]
          component = module_info[:component_name]

          spec_results=`rspec /etc/puppet/modules/#{component_module}/tests/serverspec/spec/localhost/#{component}/*_spec.rb --format j`
          @log.info("Executing serverspec test: /etc/puppet/modules/#{component_module}/tests/serverspec/spec/localhost/#{component}/*_spec.rb")
          spec_results_json =  JSON.parse(spec_results)

          spec_results_json['examples'].each do |spec|
            spec_result = {}
            spec_result.store(:module_name, component_module)
            spec_result.store(:component_name, component)
            spec_result.store(:test_result, spec['full_description'])
            spec_result.store(:status, spec['status'])
            all_spec_results << spec_result
          end
        end

        reply[:data]  = all_spec_results
        reply[:pbuilderid] = Facts["pbuilderid"]
        reply[:status] = :ok
      end
    end
  end
end
