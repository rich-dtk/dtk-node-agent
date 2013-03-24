#!/usr/bin/env ruby

STDOUT.sync = true

require 'rubygems'
require 'fog'
require 'awesome_print'
require 'trollop'

# read and check arguments
opts = Trollop::options do
    opt :region, "AWS Region on which to create the AMI image", :required => true, :type => :string
    opt :aws_key, "AWS Access Key", :required => true, :default => Fog.credentials[:aws_access_key_id], :type => :string
    opt :aws_secret, "AWS Secret Access Key", :required => true, :default => Fog.credentials[:aws_secret_access_key], :type => :string
    opt :security_group, "AWS Security group", :default => 'default', :type => :string
    opt :key_pair, "AWS keypair for the new instance", :required => true, :type => :string
    opt :key_path, "Path to the PEM file for ssh access", :required => true, :type => :string
    opt :ssh_username, "SSH Username", :required => true, :type => :string
    opt :ami_id, "AMI id which to spin up", :required => true, :type => :string
    opt :image_name, "Name of the new image", :required => true, :type => :string
end

region = opts[:region]
image_id = opts[:ami_id]
key_name = opts[:key_pair]
key_path = opts[:key_path]
ssh_username = opts[:ssh_username]
image_name = opts[:image_name]
security_group = opts[:security_group]

fog = Fog::Compute.new({:provider => 'AWS', :region=>region})

puts "Creating new instance..."
server = fog.servers.create(:key_name=>key_name, :image_id=>image_id, :flavor_id=>'t1.micro', :groups => security_group)
#server = fog.servers.last

# set up ssh access
Fog.credentials = Fog.credentials.merge({ 
  :private_key_path => key_path,
})
server.username = ssh_username

# wait for server to become available
server.wait_for { print "."; ready? }
sleep 100

# test ssh connection before proceeding
begin
	server.ssh('ls /')
rescue
	puts "Unable to connect via ssh. Please make sure that the ssh key and username you provided are correct."
	puts "Terminating instance..."
	server.destroy
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
