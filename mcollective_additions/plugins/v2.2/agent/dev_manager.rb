require 'base64'

module MCollective
  module Agent
    class Dev_manager < RPC::Agent

      AGENT_MCOLLECTIVE_LOCATION = "#{::MCollective::Config.instance.libdir}/mcollective/agent/"

      action "inject_agent" do
        begin
          #TODO: look at locking out other agents calls during this segment
          ret = Response.new() 

          #first update the agent files and tell mcolelctive about it
          request[:agent_files].each do |agent_path,v|
            agent_name = agent_path.gsub(/\.rb$/,"") 
            full_path = "#{AGENT_MCOLLECTIVE_LOCATION}#{agent_path}"
            if v.kind_of?(Symbol) and v == :deleted
              MCHelper.uninstall(agent_name)
              File.delete(full_path) if File.exists?(full_path)
            else
              content = Base64.decode64(v)
              File.open(full_path,'w'){|file|file << content}
              MCHelper.install_or_reinstall_agent(agent_name)
            end
          end
          ret.set_status_succeeded!()
        rescue Exception => e
          Log.error e
          ret.set_status_failed!()
          error_info = { :error => { :message => "Error syncing agents: #{e}" } }
          ret.merge!(error_info)
        end
        ret
      end

      module MCHelper
        def self.uninstall_agent(agent_name)
          ::MCollective::PluginManager.delete("#{agent_name}_agent")
        end
        def self.install_or_reinstall_agent(agent_name)
          #Modified fragment fRom https://github.com/ripienaar/mcollective-agent-debugger
          classname = "MCollective::Agent::#{agent_name.capitalize}"
          ::MCollective::PluginManager.delete("#{agent_name}_agent")
          ::MCollective::PluginManager.loadclass(classname)
          ::MCollective::PluginManager << {:type => "#{agent_name}_agent", :class => classname}
        end
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

      def set_status_failed!()
        self[:status] = :failed
      end
      def set_status_succeeded!()
        self[:status] = :succeeded
      end
    end
  end
end
 
