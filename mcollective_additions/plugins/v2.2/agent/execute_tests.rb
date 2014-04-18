module MCollective
  module Agent
    class Execute_tests < RPC::Agent
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
        log_error = ([e.inspect]+backtrace_subset(e)).join("\n")
        @log.info("\n----------------error-----\n#{log_error}\n----------------error-----")
      end

      action "execute_tests" do
        #Get list of component modules that have spec tests
        list_output=`ls /etc/puppet/modules/*/dtk/serverspec/spec/localhost/*/*_spec.rb`
        regex_pattern=/modules\/(.+)\/dtk\/serverspec\/spec\/localhost\/(.+)\//
        ModuleInfo = Struct.new(:module_name, :component_name, :full_component_name)
        modules_info = []

        components = []
        #Strip away node part (/)...leave only part which represent full component name
        request[:components].each do |c|
          if c.include? "/"
            components << c.split("/").last
          else
            components << c
          end
        end

        list_output.each do |line|
          match = line.match(regex_pattern)
          components.each do |c|
            if c.include? "::"
              stripped_c = c.split("::").last
              modules_info << ModuleInfo.new(match[1],match[2],c) if stripped_c.eql? match[2]
            elsif c.eql? match[2]
              modules_info << ModuleInfo.new(match[1],match[2],c)
            end
          end
        end

        all_spec_results = []
        #filter out redundant module info if any
        modules_info = modules_info.uniq
        #Pull latest changes for modules if any
        git_server = Facts["git-server"]

        begin
          modules_info.each do |module_info|
            component_module = module_info[:module_name]
            component_name = module_info[:component_name]
            full_component_name = module_info[:full_component_name]
            #Filter out version context for modules that don't exist on node
            filtered_version_context = request[:version_context].select { |x| x[:implementation] == module_info[:module_name] }.first
            pull_modules(filtered_version_context,git_server)

            @log.info("Executing serverspec test: /etc/puppet/modules/#{component_module}/dtk/serverspec/spec/localhost/#{component_name}/*_spec.rb")
            spec_results=`/opt/puppet-omnibus/embedded/bin/rspec /etc/puppet/modules/#{component_module}/dtk/serverspec/spec/localhost/#{component_name}/*_spec.rb --format j 2>&1`
            raise spec_results unless spec_results_json = JSON.parse(spec_results)

            spec_results_json['examples'].each do |spec|
              spec_result = {}
              spec_result.store(:module_name, component_module)
              spec_result.store(:component_name, full_component_name)
              spec_result.store(:test_result, spec['full_description'])
              spec_result.store(:status, spec['status'])
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