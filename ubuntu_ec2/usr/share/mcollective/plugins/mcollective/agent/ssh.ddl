metadata  :name        => "DTK SSH Bootstrap Agent",
          :description => "Adds :agent_ssh_key_public, :agent_ssh_key_private, :server_ssh_key_public, :server_hostname to appropriate files.",
          :author      => "Reactor8",
          :licence     => "",
          :version     => "",
          :url         => "",
          :timeout     => 0

action "add_rsa_info", :description => "Modifiies /root/.ssh/id_rsa, id_rsa.pub and known_hosts 'nltpu'" do
  display :always

  output  :data => "Returns status, and if there is error than an error message as well.",
          :status => "Returns status, OK or FAILED",
          :time => "Time stamp when the response was sent."
end

