require File.expand_path('../command', __FILE__)


module DTK
  module Agent
    class Commander

      def initialize(execution_list)
        @command_tasks  = execution_list.collect { |command| Command.new(command) }
      end

      def run
        @command_tasks.each do |command_task|
          command_task.start_task
        end

        loop do
          all_finished = true
          sleep(1)

          # we check status of all tasks
          # (Usually is not good practice to change array/map you are iterating but this seems as cleanest solutions)
          @command_tasks.each do |command_task|

            # is task finished
            if command_task.exited?
              Log.debug("Command '#{command_task}' finished, with status #{command_task.exitstatus}")

              # if there is a callback start it
              if command_task.callback_pending?
                new_command_task = command_task.spawn_callback_task
                new_command_task.start_task
                @command_tasks << new_command_task
                Log.debug("Command '#{new_command_task}' spawned as callback")
                # new task added we need to check again
                all_finished = false
              end
            else
              # we are not ready yet, some tasks need to finish
              all_finished = false
            end
          end

          break if all_finished
        end
      end

      def results
        @command_tasks.collect do |command_task|
          process = command_task.process
          {
            :status      => command_task.exitstatus,
            :stdout      => command_task.out,
            :stderr      => command_task.err,
            :description => command_task.to_s,
            :child_task  => command_task.child_task
          }
        end
      end

    private

      ##
      # Sets environmental variables
      def self.set_environment_variables(env_vars_hash)
        return unless env_vars_hash
        env_vars_hash.each do |k, v|
          ENV[k] = v.to_s.strip
          Log.debug("Environment variable set (#{k}: #{v})")
        end
      end

    end

  end
end