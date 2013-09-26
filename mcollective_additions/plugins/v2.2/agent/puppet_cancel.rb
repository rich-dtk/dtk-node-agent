require 'rubygems'
require 'puppet'
require 'grit'
require 'tempfile'
require 'fileutils'

#TODO: move to be shared by agents
PuppetApplyLogDir = "/var/log/puppet"
ModulePath =  "/etc/puppet/modules"

module MCollective
  module Agent
    class Puppet_cancel < RPC::Agent
      def initialize()
        super()
        @log = Log.instance
        @reply_data = nil
      end

      #
      # Amar:
      # puppet_cancel agent gets 'task_id' in request 
      # And goes through list of live threads inside stomp/mcollective process.
      # If thread with matching 'task_id' is found that thread is killed
      # If thread with matching 'task_id' is not found, error is returned in response
      #
      def run_action
        task_id = request[:top_task_id]
        @log.info("Terminating puppet apply thread for task_id=#{task_id}")

        ret ||= Response.new()

        Thread.list.each do |t|
          if t[:task_id] == task_id
	          t[:is_canceled] = true
            t.kill
            @log.info("Puppet apply thread for task_id=#{task_id} terminated.")
            ret.set_status_succeeded!()
            return ret
          end
        end

        @log.info("Puppet apply thread for task_id=#{task_id} is not running on this node.")
        ret.set_status_failed!()
        error_info = { :error => { :message => "Puppet apply thread for task_id=#{task_id} is not running on the node." } }
        ret.merge!(error_info)
       end

   end
    #TODO: this should be common accross Agents
    class Response < Hash
      def initialize(hash={})
        super()
        self.merge!(hash)
        self[:status] = :unknown unless hash.has_key?(:status)
      end

      def to_hash()
        Hash.new.merge(self)
      end

      def failed?()
        self[:status] == :failed
      end

      def set_status_failed!()
        self[:status] = :failed
      end
      def set_status_succeeded!()
        self[:status] = :succeeded
      end
      def set_dynamic_attributes!(dynamic_attributes)
        self[:dynamic_attributes] = dynamic_attributes
      end
    end
  end
end

