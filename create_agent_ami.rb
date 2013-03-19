#!/usr/bin/env ruby

STDOUT.sync = true

require 'rubygems'
require 'fog'
require 'awesome_print'

# check arguments
unless ARGV.length == 5
  puts 'Wrong number of arguments.'
  puts 'Usage:     ruby create_agent_ami.rb region ami_id key_name key_path image_name'
  puts 'Example:   ruby create_agent_ami.rb us-east-1 ami-da0000aa test_key /somepath/test_key.pem r8-agent-ubuntu-precise'
  exit
end

region = ARGV[0]
image_id = ARGV[1]
key_name = ARGV[2]
key_path = ARGV[3]
image_name = ARGV[4]

# check if AWS credentials are available to Fog
if Fog.credentials.empty?
	puts "Please make sure that your AWS credentials are set in the ~/.fog file."
	abort
end

fog = Fog::Compute.new({:provider => 'AWS', :region=>region})

ap "Creating new instance..."
server = fog.servers.create(:key_name=>key_name, :image_id=>image_id, :flavor_id=>'t1.micro')

#server = fog.servers.last

Fog.credentials = Fog.credentials.merge({ 
  :private_key_path => key_path 
})

# wait for server to become available
server.wait_for { print "."; ready? }
sleep(20)

# upload the entire dtk-node-agent directory via scp
ap "Copying files to the new intance..."
server.scp(File.expand_path(File.dirname(__FILE__)), '/tmp', {:recursive=>true})

# execute the installation script on the instance
ap "Performing agent installation..."
execute_ssh = server.ssh('sudo bash /tmp/dtk-node-agent/install_agent.sh')
puts execute_ssh.first.stdout

# create new ami image_id
data = fog.create_image(server.identity, image_name, '')
image_id = data.body['imageId']
ap "Creating an AMI image: " + image_id

# wait for the AMI creation to complete
Fog.wait_for do
  fog.describe_images('ImageId' =>image_id).body['imagesSet'].first['imageState'] == 'available'
end

# Terminate the instance
ap "Terminating the running instance"
server.destroy
