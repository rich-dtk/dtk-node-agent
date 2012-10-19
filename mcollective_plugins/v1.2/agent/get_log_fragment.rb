#!/usr/bin/env ruby
require 'rubygems'

module MCollective
  #TODO: shoudl go in common area
  LogFileHandles = {:task_id => Hash.new, :top_task_id => Hash.new}

  module Agent
    class Get_log_fragment < RPC::Agent
            metadata    :name        => "get log fragment",
                        :description => "get log fragment",
                        :author      => "Reactor8",
                        :license     => "",
                        :version     => "",
                        :url         => "",
                        :timeout     => 20
      def initialize()
        super()
        @log = Log.instance
      end
      def get_action()
        validate :key, String
        validate :value, String
        log_file_dir = "/var/log/puppet" 
        key = request[:key]
        value = request[:value]
        lines = get_log_fragment(log_file_dir,key,value)
        pbuilderid = Facts["pbuilderid"]
        if lines.nil?
          error_msg = "Cannot find log fragment matching #{key}=#{value}"
          error_response = {
            :status => :failed, 
            :error => {
              :message => error_msg
            },
            :pbuilderid => pbuilderid
          }
          @log.error(error_msg)
          reply.data = error_response
        else
          ok_response = {
            :status => :ok,
            :data => lines,
            :pbuilderid => pbuilderid
          }
          reply.data = ok_response
        end
      end
     private
      def get_log_fragment(log_file_dir,key,value)
        #flush file if it is open
        if file_handle = (LogFileHandles[key.to_sym]||{})[value]
          file_handle.flush
        end
 
        delim = key.to_sym == :top_task_id ? "\\." : ":"
        string_key = "#{key}:#{value.to_s}#{delim}"
        ret = Array.new
        matches = Dir["#{log_file_dir}/*.log"].grep(Regexp.new(string_key))
        if matches.size == 0
          return nil
        end
        matching_file = matches.size == 1 ?
          matches.first :
          #this finds teh most recent file
          matches.map{|file|[file,File.mtime(file)]}.sort{|a,b|b[1]<=>a[1]}.first[0]
        begin
          f = File.open(matching_file)
          until f.eof
            ret << f.readline.chop
          end
        ensure
          f.close
        end
        ret
      end
    end
  end
end
