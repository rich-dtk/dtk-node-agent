module MCollective
  module Agent
    class Git_access < RPC::Agent
      action "add_rsa_info" do 
        ssh_folder_path = '/root/.ssh'
        rsa_path     = "#{ssh_folder_path}/id_rsa"
        rsa_pub_path = "#{ssh_folder_path}/id_rsa.pub"
        known_hosts  = "#{ssh_folder_path}/known_hosts"


        #TODO: move to using mcollective vallidation on ddl
        def validate_request(req)
          required_params = [:agent_ssh_key_public, :agent_ssh_key_private, :server_ssh_rsa_fingerprint]
          missing_params  = []
          required_params.each do |param|
            missing_params << param if req[param].nil?
          end

          unless missing_params.empty?
            raise "Request is missing required param(s): #{missing_params.join(',')} please review your request."
          end
        end

        begin
          # validate request
          validate_request(request)

          # fails if these files already exists and content differs
          if File.exists?(rsa_path)
            existing_rsa = File.open(rsa_path).read
            if existing_rsa == request[:agent_ssh_key_private]
              # create private key file
              File.open(rsa_path,"w",0600){|f|f.print request[:agent_ssh_key_private]}
            else
              raise "RSA private key already exists and differs from one in payload"
            end
          end
          if File.exists?(rsa_pub_path)
            existing_rsa_pub = File.open(rsa_pub_path).read
            if existing_rsa_pub == request[:agent_ssh_key_public]
              # create public key file
              File.open(rsa_pub_path,"w"){|f|f.print request[:agent_ssh_key_public]}
            else
              raise "RSA public key already exists and differs from one in payload"
            end
          end

          #create or append if key not there
          skip = nil
          fp = request[:server_ssh_rsa_fingerprint]
          if File.exists?(known_hosts)
            fp_key = (fp =~ Regexp.new("(^[^=]+)=");$1)
            if fp_key
              fp_key_regexp =  Regexp.new("^#{fp_key}")
              skip = !!File.open(known_hosts){|f|f.find{|line|line =~ fp_key_regexp}} 
            end
          end
          unless skip
            File.open(known_hosts,"a"){|f|f.print request[:server_ssh_rsa_fingerprint]}
          end

          reply.data   = { :status => :succeeded}
        rescue Exception => e
          reply.data   = { :status => :failed, :error => {:message => e.message}}
        end
      end
    end
  end
end
