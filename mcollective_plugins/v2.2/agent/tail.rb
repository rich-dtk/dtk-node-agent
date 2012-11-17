module MCollective
  module Agent
    class Tail < RPC::Agent

      # number of lines that will be returned on first request
      BATCH_SIZE_OF_LOG = 50

      action "get_log" do
        begin
          unless File.exists? request[:log_path]
            reply[:data]  =    { :error => "File #{request[:log_path]} not found on given node."}
            reply[:pbuilderid] = Facts["pbuilderid"]
            reply[:status] = :ok
            return
          end

          # returns total number of lines in file, one is to start next iteration with new line
          last_line  = `wc -l #{request[:log_path]} | awk '{print $1}'`.to_i + 1
          # if there is start line from CLI request we use it, if not we take last BATCH_SIZE_OF_LOG lines
          start_line = (request[:start_line].empty? ? last_line-BATCH_SIZE_OF_LOG : request[:start_line])
          # returns needed lines
          if (request[:grep_option].nil? || request[:grep_option].empty?)
            output = `tail -n +#{start_line} #{request[:log_path]}`
          else
            output = `tail -n +#{start_line} #{request[:log_path]} | grep #{request[:grep_option]}`
          end

          reply[:data]      = { :output => output, :last_line => last_line }
          reply[:pbuilderid] = Facts["pbuilderid"]
          reply[:status]    = :ok
        rescue Exception => e
          Log.error e
        end
      end

      action "grep" do
        begin
          unless File.exists? request[:log_path]
            reply[:data]  =    { :error => "File #{request[:log_path]} not found on given node."}
            reply[:pbuilderid] = Facts["pbuilderid"]
            reply[:status] = :ok
            return
          end          
          
          # returns needed lines
          if (request[:stop_on_first_match].empty? || request[:stop_on_first_match].nil? || request[:stop_on_first_match].eql?('false'))
            output = `more #{request[:log_path]} | grep #{request[:grep_pattern]}`
          else
            output = `more #{request[:log_path]} | grep #{request[:grep_pattern]} | tail -1`
          end
          reply[:data]      = { :output => output}
          reply[:pbuilderid] = Facts["pbuilderid"]
          reply[:status]    = :ok
        rescue Exception => e
          Log.error e
        end
      end

    end
  end
end
