module MCollective
  module Agent
    class Git_access < RPC::Agent
      action "add_rsa_info" do 
        SSH_FOLDER_PATH = '/root/.ssh'

        def validate_existance(file)
          raise "Missing #{file} unable to continue." unless File.exists?(file)
        end

        def append_to_file(file,value)
          outfile = File.open(file,'a')
          outfile.print value
          outfile.close
        end

        def validate_request(req)
          required_params = [:agent_ssh_key_public, :agent_ssh_key_private, :server_ssh_key_public, :server_hostname ]
          missing_params  = []
          required_params.each do |param|
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

          # validate existance of needed files
          validate_existance(rsa_path)
          validate_existance(rsa_pub_path)

          # validate request
          validate_request(request)

          # create files if not present
          unless File.exists?(known_hosts)
            FileUtils.touch known_hosts
            raise "Not able to create hosts file #{known_hosts}, unable to continue" unless File.exists?(known_hosts)
          end

          append_to_file(rsa_path,request[:agent_ssh_key_private])
          append_to_file(rsa_pub_path, request[:agent_ssh_key_public])
          append_to_file(known_hosts,"#{request[:server_hostname]} ssh-rsa #{request[:server_ssh_key_public]}")
          
          reply.data   = { :status => 'OK', :message => "Public/Private keys added successfully."}
        rescue Exception => e
          reply.data   = { :status => 'FAILED', :message => e.message}
        end
      end
    end
  end
end
