#!/usr/bin/env bash

# check if script was kicked off with root/sudo privileges
if [ "$(whoami)" != "root" ]; then
	echo "Not running as root. Exiting..."
	exit 0
fi

# get OS info
function getosinfo()
{
	export osname=`lsb_release -d | awk '{print $2}'`
	export codename=`lsb_release -c | awk '{print $2}'`
	export release=`lsb_release -r | awk '{print $2}'`
}

base_dir="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# update PATH just in case
export PATH=$PATH:/sbin:/usr/sbin

# check package manager used on the system and install appropriate packages/init scripts
if [[ `which apt-get` ]]; then
	apt-get update  --fix-missing
	apt-get install -y ruby1.8 ruby1.8-dev rubygems1.8 libopenssl-ruby1.8 build-essential wget curl lsb-release git
	# make sure ruby 1.8 is the default
	update-alternatives --set ruby /usr/bin/ruby1.8
	update-alternatives --set gem /usr/bin/gem1.8
elif [[ `which yum` ]]; then
	# install ruby and git
	yum -y install ruby rubygems ruby-devel
	# make sure gem version and sources are up to date
	[[ ! `gem sources | grep "rubygems.org"` ]] && gem sources -a https://rubygems.org
	gem update --system --no-rdoc --no-ri
else
	echo "Unsuported OS for automatic agent installation. Exiting now..."
	exit 1
fi;

# remove any existing gems
rm ${base_dir}/*.gem
# install the dtk-node-agent gem
cd ${base_dir}
gem build ${base_dir}/dtk-node-agent.gemspec
gem install ${base_dir}/dtk-node-agent*.gem --no-rdoc --no-ri

# remove root ssh files
rm /root/.ssh/id_rsa
rm /root/.ssh/id_rsa.pub 
rm /root/.ssh/known_hosts

# remove mcollective and puppet logs
rm -f /var/log/mcollective.log /var/log/puppet/*

# sanitize the AMI (creating unique ssh host keys will be handled by the cloud-init package)
find /root/.*history /home/*/.*history -exec rm -f {} \;
find /root /home /etc -name "authorized_keys" -exec rm -f {} \;
