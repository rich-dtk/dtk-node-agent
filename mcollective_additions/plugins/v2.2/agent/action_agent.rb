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
        Log.info reply[:data]
        reply[:pbuilderid] = Facts["pbuilderid"]

        if reply[:data]['errors'].empty?
          Log.info "DTK Action Agent has finished successfully sending proper response"
          reply[:status] = :ok
        else
          reply[:status]     = :failed
          reply[:statusmsg]  = :failed
          reply[:statuscode] = 1

          Log.error "DTK Action Agent has errors:"
          reply[:data]['errors'].each { |a| Log.error a }
        end

      end

    end
  end
end