module MCollective
  module Agent
    class Netstat < RPC::Agent
      metadata    :name        => "netstat info",
                  :description => "Agent to get netstat info",
                  :author      => "Reactor8",
                  :license     => "",
                  :version     => "",
                  :url         => "",
                  :timeout     => 2
      action "get_tcp_udp" do 
        output = `netstat -nltpu`
        results = output.scan(/(^[a-z0-9]+)\s+(\d)\s+(\d)\s+([a-z0-9:.*]+)\s+([0-9:.*]+)\s+(LISTEN)?\s+([0-9a-zA-Z\/\-: ]+)/m)
        
        netstat_result = []
        results.each do |result|
          netstat_packet = {}
          netstat_packet.store(:protocol, result[0])
          netstat_packet.store(:recv_q,   result[1])
          netstat_packet.store(:send_q,   result[2])
          netstat_packet.store(:local,    result[3])
          netstat_packet.store(:foreign,  result[4])
          netstat_packet.store(:state,    result[5])
          netstat_packet.store(:program,  result[6].strip)
          netstat_result << netstat_packet
        end

        reply[:data]  = netstat_result
        reply[:pbuilderid] = Facts["pbuilderid"]
        reply[:status] = :ok
      end
    end
  end
end
