module MCollective
  module Agent
    class Git_access < RPC::Agent
      metadata    :name        => "git access",
                  :description => "Agent to enable git access",
                  :author      => "Reactor8",
                  :license     => "",
                  :version     => "",
                  :url         => "",
                  :timeout     => 20
      action "add_rsa_info" do 
        ssh_folder_path = '/root/.ssh'
        rsa_path     = "#{ssh_folder_path}/id_rsa"
        rsa_pub_path = "#{ssh_folder_path}/id_rsa.pub"
        known_hosts  = "#{ssh_folder_path}/known_hosts"

        begin
          # validate request
          validate_request(request)

          #create private rsa file if needed
          unless donot_create_file?(:private,rsa_path,request[:agent_ssh_key_private])
            File.open(rsa_path,"w",0600){|f|f.print request[:agent_ssh_key_private]}
          end

          #create public rsa file if needed
          unless donot_create_file?(:public,rsa_pub_path,request[:agent_ssh_key_public])
            File.open(rsa_pub_path,"w"){|f|f.print request[:agent_ssh_key_public]}
          end

          #create or append if key not there
          skip = nil
          fp = request[:server_ssh_rsa_fingerprint]
          if File.exists?(known_hosts)
            fp_key = (fp =~ Regexp.new("^[|]1[|]([^=]+)=");$1)
            if fp_key
              fp_key_regexp =  Regexp.new("^.1.#{fp_key}")
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

      def donot_create_file?(type,path,content)
        # raises exception if these files already exists and content differs
        if File.exists?(path)
          existing = File.open(path).read
          if existing == content
            true
          else
            raise "RSA #{type} key already exists and differs from one in payload"
          end
        end
      end
    end
  end
end

    
