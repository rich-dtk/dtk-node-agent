#!/usr/bin/env bash

#install all the necessary dependencies
apt-get install -y ruby1.8 ruby1.8-dev build-essential libruby1.8-extras irb wget curl rubygems1.8 lsb_release

codename=`lsb_release -c | awk '{print $2}'`

wget http://apt.puppetlabs.com/puppetlabs-release-${codename}.deb
if [[ $? -eq 0 ]]; then 
	dpkg -i puppetlabs-release-${codename}.deb
else
	echo "Something went wrong while installing the Puppetlabs apt repo. Possible reason is this OS is not officially supported."
fi;


