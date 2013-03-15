#!/usr/bin/env ruby

require 'rubygems'
require 'fog'
require 'awesome_print'

fog = Fog::Compute.new({:provider => 'AWS', :aws_access_key_id => 'AKIAIIEVWN7MKUAJ5SDQ', :aws_secret_access_key => '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', :region=>'us-east-1'})

#server = fog.servers.create(:key_name=>'dario-use1', :image_id=>'ami-de0d9eb7', :flavor_id=>'t1.micro')

server = fog.servers.last

Fog.credentials = Fog.credentials.merge({ 
  :private_key_path => "c:\\Users\\dario\\Dropbox\\Store\\dario-use1.pem", 
  #:public_key_path => "C:\\Users\\haris\\.ssh\\id_rsa.pub" 
})

#server.wait_for { print "."; ready? }

#server.scp(File.dirname(__FILE__), '/tmp',{:recursive=>true})

#server.ssh('sudo bash /tmp/dtk-node-agent/install_agent.sh').Result.stdout
puts server.ssh('ls -lah /').first.stdout
