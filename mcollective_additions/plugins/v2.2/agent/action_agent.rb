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
        reply[:status] = reply[:data]['errors'].empty? ? :ok : :failed

        if reply[:status] == :ok
          Log.info "DTK Action Agent has finished successfully sending proper response"
        else
          Log.error "DTK Action Agent has errors:"
          reply[:data]['errors'].each { |a| Log.error a }
        end
      end

    end
  end
end