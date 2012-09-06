#!/usr/bin/env ruby
require 'rubygems'

module MCollective
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
        log_file = "/var/chef/solo.log" #TODO stub
        key = request[:key]
        value = request[:value]
        lines = get_log_fragment(log_file,key,value)
        if lines.empty?
          error_msg = "Cannot find log fragment matching #{key}=#{value}"
          error_response = {
            :status => :failed, 
            :error => {
              :formatted_exception => error_msg
            }
          }
          @log.error(error_msg)
          reply.data = error_response
        else
          reply.data = lines
        end
      end
     private
      def get_log_fragment(log_file,key,value)
        string_key = "#{key}:#{value.to_s}\\|"
        start_marker = Regexp.new("START_MARKER:.+#{string_key}")
        end_marker = Regexp.new("END_MARKER:.+#{string_key}")
        just_end_marker = Regexp.new("END_MARKER:")
        ret = Array.new
        begin
          f = File.open(log_file)
          until f.eof or f.readline =~ start_marker
          end
          end_found = false
          until f.eof or end_found
            line = f.readline
            if line =~ just_end_marker
              end_found = true
              unless line =~ end_marker
                @log.error("matched end marker line (#{line.chop}), which does not match #{key}=#{value}")
              end 
            else
              ret << line.chop
            end
          end
          #TODO: check for eof and find indicate did find end marker
         ensure
          f.close
        end
        ret
      end
    end
  end
end
