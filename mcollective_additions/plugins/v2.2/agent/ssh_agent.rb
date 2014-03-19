module MCollective
  module Agent
    class Ssh_agent < RPC::Agent

      AGENT_MCOLLECTIVE_LOCATION = "#{::MCollective::Config.instance.libdir}/mcollective/agent/"
      SSH_AUTH_KEYS_FILE_NAME    = "authorized_keys"

      action "grant_access" do
        validate :rsa_pub_key, String
        validate :rsa_pub_name, String
        validate :system_user, String

        ::MCollective::Util.loadclass("MCollective::Util::PuppetRunner")
        ::MCollective::Util::PuppetRunner.apply(
          :ssh_authorized_key,
          {
            :name => request[:rsa_pub_name],
            :ensure => 'present',
            :key =>normalize_rsa_pub_key(request[:rsa_pub_key]),
            :type => 'ssh-rsa',
            :user => request[:system_user]
          }
        )

        reply[:data] = { :message => "Access to system user '#{request[:system_user]}' has been granted for '#{request[:rsa_pub_name]}'" }
        reply[:pbuilderid] = Facts["pbuilderid"]
        reply[:status] = :ok
      end
      
      action "revoke_access" do
        validate :rsa_pub_name, String
        validate :system_user, String

        ::MCollective::Util.loadclass("MCollective::Util::PuppetRunner")
        ::MCollective::Util::PuppetRunner.apply(
          :ssh_authorized_key,
          {
            :name => request[:rsa_pub_name],
            :ensure => 'absent',
            :type => 'ssh-rsa',
            :user => request[:system_user]
          }
        )

        reply[:data] = { :message => "Access for system user '#{request[:system_user]}' has been revoked" }
        reply[:pbuilderid] = Facts["pbuilderid"]
        reply[:status] = :ok
      end


      def normalize_rsa_pub_key(rsa_pub_key)
        rsa_pub_key.strip!()
        rsa_pub_key.gsub!(/.* (.*) .*/,'\1')
        rsa_pub_key
      end
    end
  end
end
