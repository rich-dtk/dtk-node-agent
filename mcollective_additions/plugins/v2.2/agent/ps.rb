module MCollective
  module Agentregex group 1st n collumns and put everything else in the last group
    class Ps < RPC::Agent
      metadata    :name        => "ps info",
                  :description => "Agent to get ps info (running processes)",
                  :author      => "Reactor8",
                  :license     => "",
                  :version     => "",
                  :url         => "",
                  :timeout     => 2
      action "get_ps" do 
        output=`ps -ef`
        output.gsub!(/^.+\]$/,'')
        results = output.scan(/(\S+)[\s].*?(\S+)[\s].*?(\S+)[\s].*?(\S+)[\s].*?(\S+)[\s].*?(\S+)[\s].*?(\S+)[\s].*?(.+)/)
        results.shift

        ps_result = []
        results.each do |result|
          ps_packet = {}
          ps_packet.store(:uid, result[0])
          ps_packet.store(:pid,   result[1])
          ps_packet.store(:ppid,   result[2])
          ps_packet.store(:cpu,    result[3])
          ps_packet.store(:start_time,  result[4])
          ps_packet.store(:tty,    result[5])
          ps_packet.store(:time,  result[6])
          ps_packet.store(:command,  result[7].strip)
          ps_result << ps_packet
        end

        reply[:data]  = ps_result
        reply[:pbuilderid] = Facts["pbuilderid"]
        reply[:status] = :ok
      end
    end
  end
end
