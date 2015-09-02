require 'base64'
require 'tmpdir'
require 'fileutils'

module MCollective
  module Agent
    class Dev_manager < RPC::Agent

      AGENT_MCOLLECTIVE_LOCATION = "#{::MCollective::Config.instance.libdir.join}/mcollective/agent/"
      DTK_AA_TEMP_DIR = File.join(Dir.tmpdir(), 'dtk-action-agent')

      action "inject_agent" do
        begin

          ret ||= Response.new()

          # make sure default `service` command paths are set
          ENV['PATH'] += ":/usr/sbin:/sbin"

          (request[:agent_files]||[]).each do |k,v|
            if v == :deleted
              File.delete("#{AGENT_MCOLLECTIVE_LOCATION}#{k}")
              next
            end
            content = Base64.decode64(v)
            File.open("#{AGENT_MCOLLECTIVE_LOCATION}#{k}",'w') do |file|
              file << content
            end
          end

          ret.set_status_succeeded!()

          dtk_aa_url    = request[:action_agent_remote_url]
          dtk_aa_branch = request[:action_agent_branch]

          # DTK Action Agent Sync
          if dtk_aa_url && dtk_aa_branch
            begin
              Log.instance.info("Started DTK Action Agent sync, temp dir '#{DTK_AA_TEMP_DIR}'")
              output = `git clone #{dtk_aa_url} -b #{dtk_aa_branch} #{DTK_AA_TEMP_DIR}`
              result = $?

              if result.success?
                Log.instance.info("Cloned latest code from branch '#{dtk_aa_branch}' for DTK Action Agent.")

                output = `cd #{DTK_AA_TEMP_DIR} && /opt/puppet-omnibus/embedded/bin/gem build #{DTK_AA_TEMP_DIR}/dtk-action-agent.gemspec && /opt/puppet-omnibus/embedded/bin/gem install #{DTK_AA_TEMP_DIR}/dtk-action-agent-*.gem --no-ri --no-rdoc`
                result = $?
                if result.success?
                  Log.instance.info("DTK Action Agent has been successfully update from branch '#{dtk_aa_branch}'")
                else
                  Log.instance.error("DTK Action Agent could not be updated, reason: #{output}")
                end
              else
                Log.instance.error("Not able to clone latest code from '#{dtk_aa_url} branch #{dtk_aa_branch}', aborting DTK Action Agent Sync. #{output}")
              end
            ensure
              FileUtils.rm_rf DTK_AA_TEMP_DIR
            end
          end

          t1 = Thread.new do
            sleep(2)
            Log.instance.info "Initiating mcollective restart..."
            system("#{service_command} restart")
          end

          def self.service_command
            cmd = `which service`.chomp
            cmd.empty? ? "/etc/init.d/mcollective" : "#{cmd} mcollective"
          end

          return ret

        rescue Exception => e
          Log.instance.error e
          ret.set_status_failed!()
          error_info = { :error => { :message => "Error syncing agents: #{e}" } }
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
