metadata    :name        => "ssh agent",
            :description => "SSH Agent allows adding of public keys, removing them and listing",
            :author      => "Reactor8",
            :license     => "",
            :version     => "",
            :url         => "",
            :timeout     => 2
action "grant_access", :description => "Add SSH access to host instance" do
end
action "revoke_access", :description => "Remove SSH access from host instance" do
end
action "list_access", :description => "List current SSH access for host instance" do
end
