require 'base64'

module MCollective
  module Agent
    class Dev_manager < RPC::Agent

      AGENT_MCOLLECTIVE_LOCATION = "#{::MCollective::Config.instance.libdir.join}/mcollective/agent/"
 
      action "inject_agent" do
        begin

          ret ||= Response.new() 

          request[:agent_files].each do |k,v|
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

          t1 = Thread.new do
            sleep(2)
            Log.instance.info "Initiating mcollective restart..."
            system("/etc/init.d/mcollective restart")
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
