require 'ap'
require 'posix-spawn'

module DTK
  module Agent
    class Arbiter

      attr_reader :process_pool

      def initialize(consumer_hash)
        @received_message = consumer_hash
        @process_pool     = []
      end

      def run
        (@received_message['commands']||[]).each do |message|
          @process_pool << POSIX::Spawn::Child.new(message)
        end

        loop do
          sleep(1)
          @process_pool.each do |process|
            unless process.status.exited?
              next
            end
          end
          break
        end
      end

      def results
        @process_pool.collect do |process|
          {
            :status => process.status.exitstatus,
            :stdout => process.out,
            :stderr => process.err
          }
        end
      end

      def print_results
        @process_pool.each do |process|
          ap process.status
          ap "STDOUT"
          print process.out
          ap "STDERR"
          print process.err
          ap "-----------------------------------"
        end
      end

    end
  end
end