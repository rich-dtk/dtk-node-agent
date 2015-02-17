require 'json'

module MCollective
  module Agent
    class Action_agent < RPC::Agent
     action "run_command" do
        #validate :action_agent_request, String
        payload = request[:action_agent_request].to_json
        Log.info "Run command has been started with params: "
        Log.info payload

        reply[:data] = {}

        # Log.info `/opt/puppet-omnibus/embedded/bin/dtk-action-agent '#{payload}'`
        result = `/opt/puppet-omnibus/embedded/bin/dtk-action-agent '#{payload}'`
        reply[:data] = JSON.parse(result)

        reply[:pbuilderid] = Facts["pbuilderid"]
        reply[:status] = :ok
      end

    end
  end
end
