#!/usr/bin/env ruby

require 'fog'
require 'ap'
require 'json'

regions = [ "us-east-1", "us-west-1", "us-west-2", "eu-west-1", "ap-southeast-1", "ap-southeast-2", "ap-northeast-1", "sa-east-1"]

raise ArgumentError, "You must specify timestamp argument" if ARGV[0].nil?
ts_filter = ARGV[0].split(",")

list = Hash.new
list[:nodes_info] = Hash.new

resolver = {
	'saucy' => 'ubuntu',
	'trusty' => 'ubuntu',
	'precise' => 'ubuntu',
	'lucid' => 'ubuntu',
	'wheezy' => 'debian',
	'centos64' => 'centos',
	'centos6' => 'centos',
	'rhel64' => 'redhat',
	'rhel6' => 'redhat'
}

regions.each do |region|
    fog = Fog::Compute.new({:provider => 'AWS', :region => region})
    fog.describe_images('Owner' => 'self').body["imagesSet"].each do |i|
      next unless ts_filter.any? { |w| i['name'] =~ /#{w}/ }
    	i['name'] =~ /dtk\-agent\-([a-zA-Z0-9]*)\-([0-9]{10})/
        if $1 && !$2.strip.empty?
	        raise "Missing mapping #{$1}  2: #{$2}" unless resolver[$1.downcase]
		    	list[:nodes_info].store(
		    		i['imageId'],
		    		{
		    			'region' => region,
		    			'type' => $1,
		    			'os_type' => resolver[$1.downcase],
		    			'display_name' => $1.capitalize,
		    			'png' => "#{$1}.png",
		    			'sizes' => ["t1.micro","m1.small","m1.medium"]
		    		}
		    	) 
        else
        	puts "Your skipped #{i['name']} with 1: #{$1} 2: #{$2}"
        end
    end
end

puts list.to_json

