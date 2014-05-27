require 'rspec'
require 'rspec/core'
require 'rspec/core/formatters/json_formatter'
require 'json'

ModulePath = "/etc/puppet/modules"
ServerspecPath = "dtk/serverspec/spec/localhost"

module MCollective
  module Agent
    class ServerSpecHelper
      def execute(spec_path, vars={})
        vars.each_pair do |k,v|
          Thread.current[k] = v
        end

        config = RSpec.configuration
        json_formatter = RSpec::Core::Formatters::JsonFormatter.new(config.output)
        reporter =  RSpec::Core::Reporter.new(json_formatter)
        config.instance_variable_set(:@reporter, reporter)
        ::RSpec::Core::Runner.run([spec_path,'--format','j'])
        json_formatter.output_hash
      end
    end

    class Execute_tests_v2 < RPC::Agent
      def initialize()
        super()
        @log = Log.instance
      end

      def pull_modules(module_version_context, git_server)
        ENV['GIT_SHELL'] = nil #This is put in because if vcsrepo Puppet module used it sets this
        begin
          repo_dir = "#{ModulePath}/#{module_version_context[:implementation]}"
          remote_repo = "#{git_server}:#{module_version_context[:repo]}"
          opts = Hash.new
          begin
            if File.exists?(repo_dir)
              @log.info("Branch already exists. Checkout to branch and pull latest changes...")
              git_repo = ::DTK::NodeAgent::GitClient.new(repo_dir)
              git_repo.pull_and_checkout_branch?(module_version_context[:branch],opts)
            else
              @log.info("Branch does not exist. Cloning branch...")
              git_repo = ::DTK::NodeAgent::GitClient.new(repo_dir,:create=>true)
              git_repo.clone_branch(remote_repo,module_version_context[:branch],opts)
            end
          rescue Exception => e
            log_error(e)
            #to achieve idempotent behavior; fully remove directory if any problems
            FileUtils.rm_rf repo_dir
            raise e
          end
        rescue Exception => e
          log_error(e)
        end
      end

      def log_error(e)
        log_error = ([e.inspect]+e.backtrace).join("\n")
        @log.info("\n----------------error-----\n#{log_error}\n----------------error-----")
      end

      action "execute_tests_v2" do
        spec_helper = ServerSpecHelper.new
        all_tests = Dir["#{ModulePath}/*/#{ServerspecPath}/*.rb"]
        all_spec_results = []

        #Pull latest changes for modules if any
        git_server = Facts["git-server"]

        begin
          request[:components].each do |component|
            #Filter version context for modules that exist on node
            filtered_version_context = request[:version_context].select { |x| x[:implementation] == component[:module_name] }.first
            pull_modules(filtered_version_context,git_server)

            test = all_tests.select { |test| test.include? component[:test_name] }
            @log.info("Executing serverspec test: #{test.first}")

            spec_results = spec_helper.execute(test.first, component[:params])
            component_name = ""
            if component[:component].include? "/"
	            component_name = component[:component].split("/").last
	          else
	            component_name = component[:component]
            end

            spec_results[:examples].each do |spec|
              spec_result = {}
              spec_result.store(:module_name, component[:module_name])
              spec_result.store(:component_name, component_name)
              spec_result.store(:test_component_name, component[:test_component])
              spec_result.store(:test_name, component[:test_name])
              spec_result.store(:test_result, spec[:full_description])
              spec_result.store(:status, spec[:status])
              all_spec_results << spec_result
            end
          end
          reply[:data] = all_spec_results
          reply[:pbuilderid] = Facts["pbuilderid"]
          reply[:status] = :ok
        rescue Exception => e
          @log.info("Error while executing serverspec test")
          @log.info(e.message)
          reply[:data] = { :test_error => "#{e.message.lines.first}" }
          reply[:pbuilderid] = Facts["pbuilderid"]
          reply[:status] = :notok
        end
      end
    end
  end
end