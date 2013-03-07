require 'base64'

module MCollective
  module Agent
    class Dev_manager < RPC::Agent

      AGENT_MCOLLECTIVE_LOCATION = '/usr/share/mcollective/plugins/mcollective/agent/'

      action "inject_agent" do
        begin

          request[:agent_files].each do |k,v|
            content = Base64.decode64(v)
            File.open("#{AGENT_MCOLLECTIVE_LOCATION}#{k}",'w') do |file|
              file << content
            end
          end

          t1 = Thread.new do 
            system("sudo /etc/init.d/mcollective restart")
            sleep(20)
          end

          t1.join

        rescue Exception => e
          Log.error e
        end
      end
    end
  end
end
