require 'json'

module MCollective
  module Agent
    class Action_agent < RPC::Agent
     action "run_command" do
        validate :bash_command, String
        command_to_run = request[:bash_command]

        Log.info "Run command has been started with bash command '#{command_to_run}'"

        payload = {
          :commands => [command_to_run].flatten
        }.to_json

        reply[:data] = {}

        result = `/opt/puppet-omnibus/embedded/bin/dtk-action-agent' #{payload}'`
        reply[:data][:output] = JSON.parse(result)

        reply[:pbuilderid] = Facts["pbuilderid"]
        reply[:status] = :ok
      end

    end
  end
end
