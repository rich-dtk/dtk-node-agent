metadata    :name        => "get log fragment",
                        :description => "get log fragment",
                        :author      => "Reactor8",
                        :license     => "",
                        :version     => "",
                        :url         => "",
                        :timeout     => 20
action "get", :description => "get log data fragment" do
  display :always
  %w{status error data pbuilderid}.each do |k|
    output k.to_sym,
      :description => k.capitalize,
      :display_as => k.capitalize
  end		
end
