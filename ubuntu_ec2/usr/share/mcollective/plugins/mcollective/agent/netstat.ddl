metadata  :name        => "DTK Netstat Agent",
          :description => "Runs net stat commands and parsers their outputs",
          :author      => "Reactor8",
          :licence     => "",
          :version     => "",
          :url         => "",
          :timeout     => 0

action "nltpu", :description => "Runts netstat command on given node with flag 'nltpu'" do
  display :always

  output  :data => "Returns array of hash maps each representing one process with it's details.",
          :time => "Time stamp when the response was sent."
end