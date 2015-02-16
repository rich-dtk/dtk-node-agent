module DTK
  module Agent

    ##
    # This is container for command as received from Node Agent

    class Command

      attr_accessor :command_type, :command, :if_success, :if_fail, :process, :child_task

      ##
      # command    - string to be run on system, e.g. ifconfig
      # type       - type of command e.g. syscall, ruby
      # if         - callback to be run if exit status is  = 0
      # unless     - callback to be run if exit status is != 0
      # child_task - if it is spawned by another main task
      #
      def initialize(value_hash)
        @command_type = value_hash['type']
        @command      = value_hash['command']
        @if_success   = value_hash['if']
        @if_fail      = value_hash['unless']
        @spawned      = false
        @child_task   = value_hash['child_task'] || false

        if @if_success && @if_fail
          Log.warn "Unexpected case, both if/unless conditions have been set for command #{@command}(#{@command_type})"
        end
      end

      ##
      # Creates Posix Spawn of given process
      #
      def start_task
        begin
          @process = POSIX::Spawn::Child.new(@command)
          Log.debug("Command started: '#{self.to_s}'")
        rescue Exception => e
          @error_message = e.message
        end
      end

      ##
      # Checks if there is callaback present, callback beeing if/unless command
      #
      def callback_pending?
        return false if @spawned
        command_to_run = (self.exitstatus.to_i == 0) ? @if_success : @if_fail
        !!command_to_run
      end


      ##
      # Creates Command object for callback, first check 'if' than 'unless'. There should be no both set so priority is given
      # to 'if' callback in case there are two
      #
      def spawn_callback_task
        callback_command = (self.exitstatus.to_i == 0) ? @if_success : @if_fail
        new_command = Command.new('type' => @command_type, 'command' => callback_command, 'child_task' => true)
        @spawned = true
        new_command
      end

      def exited?
        return true if @error_message
        self.process.status.exited?
      end

      def exitstatus
        return 1 if @error_message
        self.process.status.exitstatus
      end

      def out
        return '' if @error_message
        self.process.out
      end

      def err
        return @error_message if @error_message
        self.process.err
      end

      def to_s
        "#{@command} (#{command_type})"
      end

    end
  end
  end
