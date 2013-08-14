require 'rubygems'
require 'puppet'
require 'grit'
require 'tempfile'
require 'fileutils'

#dont want to run standard hooks and just want store configs for catalogs/resources, not for facts...
Puppet.settings.set_value(:storeconfigs,true,:memory, :dont_trigger_handles => true)
Puppet::Resource::Catalog.indirection.cache_class = :store_configs
Puppet::Resource.indirection.terminus_class = :store_configs

AGENT_MCOLLECTIVE_LOCATION = "#{::MCollective::Config.instance.libdir}/mcollective/agent/"

module MCollective
  module Agent
    class Sync_agent_code < RPC::Agent
      def initialize()
        super()
        @log = Log.instance
        @reply_data = nil
      end
      
      def old_run_action
        ret ||= Response.new()
        #git_server_url = request[:git_server_url]
        raise "git server is not set in facts" unless git_server_url = Facts["git-server"]
        branch = request[:branch]
        cmd_opts = {:raise => true, :timeout => 60}
        
        begin
          # Amar: if git repo dir exists pull code, otherwise (first converge case) clone agent's project from git
          if File.directory?(AgentGitPath)
            grit_repo = ::Grit::Repo.new(AgentGitPath)
            grit_repo.git.send(:pull, cmd_opts)
            @log.info("Latest agent code pulled from GIT Repositoy.")
          else
            clone_args = [git_server_url, AgentGitPath]
            clone_args += ["-b", branch] if branch
            ::Grit::Git.new("").clone(cmd_opts, *clone_args)
            @log.info("Agent project successfully cloned from GIT Repository.")            
          end
          # Copy latest agents to mcollective agent's directory
          agents = Dir.glob("#{AgentGitPath}/mcollective_additions/plugins/v2.2/agent/*")
          FileUtils.cp_r(agents, AgentMcollectivePath)
          @log.info("Agent files copied to mcollective destination.")
          # System call to restart mcollective
          system("sudo /etc/init.d/mcollective restart")
          @log.info("mcollective system restart completed.")

          ret.set_status_succeeded!()
        rescue Exception => e
          @log.error("Error in syncing agent's code with GIT Repository: '#{git_server_url}'. Error: #{e}")
          ret.set_status_failed!()
          error_info = { :errors => { :message => "Error in syncing agent's code with GIT Repository: '#{git_server_url}'." } }
          ret.merge!(error_info)
        end

        return ret
      end

   end
      #TODO: this should be common accross Agents
      class Response < Hash
        def initialize(hash={})
          super()
          self.merge!(hash)
          self[:status] = :unknown unless hash.has_key?(:status)
        end

        def to_hash()
          Hash.new.merge(self)
        end

        def failed?()
          self[:status] == :failed
        end

        def set_status_failed!()
          self[:status] = :failed
        end
        def set_status_succeeded!()
          self[:status] = :succeeded
        end
        def set_dynamic_attributes!(dynamic_attributes)
          self[:dynamic_attributes] = dynamic_attributes
        end
      end
  end
end

