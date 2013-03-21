#!/usr/bin/env ruby

STDOUT.sync = true

require 'rubygems'
require 'fog'
require 'awesome_print'

# check arguments
unless ARGV.length == 6
  puts 'Wrong number of arguments.'
  puts 'Usage:     ruby create_agent_ami.rb region ami_id key_name key_path ssh_username image_name'
  puts 'Example:   ruby create_agent_ami.rb us-east-1 ami-da0000aa test_key /somepath/test_key.pem root r8-agent-ubuntu-precise'
  exit
end

region = ARGV[0]
image_id = ARGV[1]
key_name = ARGV[2]
key_path = ARGV[3]
ssh_username = ARGV[4]
image_name = ARGV[5]

# check if AWS credentials are available to Fog
if Fog.credentials.empty?
	puts "Please make sure that your AWS credentials are set in the ~/.fog file."
	abort
end

fog = Fog::Compute.new({:provider => 'AWS', :region=>region})

puts "Creating new instance..."
server = fog.servers.create(:key_name=>key_name, :image_id=>image_id, :flavor_id=>'t1.micro')
#server = fog.servers.last

# set up ssh access
Fog.credentials = Fog.credentials.merge({ 
  :private_key_path => key_path,
})
server.username = ssh_username

# wait for server to become available
server.wait_for { print "."; ready? }
sleep 60

# test ssh connection before proceeding
begin
	server.ssh('ls /')
rescue
	puts "Unable to connect via ssh. Please make sure that the ssh key and username you provided are correct."
	puts "Terminating instance..."
	#server.destroy
	abort
end

# upload the entire dtk-node-agent directory via scp
puts "Copying files to the new intance..."
server.scp(File.expand_path(File.dirname(__FILE__)), '/tmp', {:recursive=>true})

# execute the installation script on the instance
puts "Performing agent installation..."
execute_ssh = server.ssh('sudo bash /tmp/dtk-node-agent/install_agent.sh')
puts execute_ssh.first.stdout

# create new ami image_id
data = fog.create_image(server.identity, image_name, '')
image_id = data.body['imageId']
puts "Creating an AMI image: " + image_id

sleep 5
# wait for the AMI creation to complete
Fog.wait_for do
  fog.describe_images('ImageId' =>image_id).body['imagesSet'].first['imageState'] == 'available'
end

# Terminate the instance
puts "Terminating the running instance"
server.destroy
