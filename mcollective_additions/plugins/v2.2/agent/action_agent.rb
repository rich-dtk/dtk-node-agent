require 'json'
require 'cgi'

module MCollective
  module Agent
    class Action_agent < RPC::Agent
     action "run_command" do
        #validate :action_agent_request, String

        payload = request[:action_agent_request].to_json
        Log.info "Run command has been started with params: "
        Log.info payload

        # we encode payload
        encoded_payload = CGI.escape(payload)
        result = `/opt/puppet-omnibus/embedded/bin/dtk-action-agent '#{encoded_payload}'`

        json_result = JSON.parse(result)
        reply[:results] = json_result['results']
        reply[:errors]  = json_result['errors']

        Log.info "Results: "
        Log.info reply[:results]

        Log.info "Errors: "
        Log.info reply[:errors]


        reply[:pbuilderid] = Facts["pbuilderid"]

        if reply[:errors].empty?
          Log.info "DTK Action Agent has finished successfully sending proper response"
          reply[:status] = :ok
        else
          reply[:status]     = :failed
          reply[:statusmsg]  = :failed
          reply[:statuscode] = 1

          Log.error "DTK Action Agent has errors:"
          reply[:errors].each { |a| Log.error a }
        end

      end

    end
  end
end