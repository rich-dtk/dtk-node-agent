require 'ap'
require 'posix-spawn'

module DTK
  module Agent
    class Arbiter

      attr_reader :process_pool

      def initialize(consumer_hash)
        @received_message = consumer_hash
        @process_pool     = []

        # sets enviorment variables
        Commander.set_environment_variables(@received_message['env_vars'])
        @positioner     = Positioner.new(@received_message['positioning'])
        @commander = Commander.new(@received_message['execution_list'])
      end

      def run
        # start positioning files
        @positioner.run()

        # start commander runnes
        @commander.run()

        # return results
        @commander.results()
      end

    end
  end
end