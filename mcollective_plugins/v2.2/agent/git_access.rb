module MCollective
  module Agent
    class Git_access < RPC::Agent
      action "add_rsa_info" do 
        SSH_FOLDER_PATH = '/root/.ssh'
        RequiredParams = [:agent_ssh_key_public, :agent_ssh_key_private, :server_ssh_rsa_fingerprint]
        def validate_request(req)
          missing_params  = []
          RequiredParams.each do |param|
            missing_params << param if req[param].nil?
          end

          unless missing_params.empty?
            raise "Request is missing required param(s): #{missing_params.join(',')} please review your request."
          end
        end

        begin
          rsa_path     = "#{SSH_FOLDER_PATH}/id_rsa"
          rsa_pub_path = "#{SSH_FOLDER_PATH}/id_rsa.pub"
          known_hosts  = "#{SSH_FOLDER_PATH}/known_hosts"

          # fails if these files already exists
          if File.exists?(rsa_path)
            raise "File #{rsa_path} already exists"
          end
          if File.exists?(rsa_pub_path)
            raise "File #{rsa_pub_path} already exists"
          end

          # validate request
          validate_request(request)

          # create files 
          File.open(rsa_path,"w",0600){|f|f.print request[:agent_ssh_key_private]}
          File.open(rsa_pub_path,"w"){|f|f.print request[:agent_ssh_key_public]}
          #create or append
          File.open(known_hosts,"a"){|f|f.print request[:server_ssh_rsa_fingerprint]}
          
          reply.data   = { :status => :succeeded}
        rescue Exception => e
          reply.data   = { :status => :failed, :error => {:message => e.message}}
        end
      end
    end
  end
end
