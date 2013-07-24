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

# read the config file
base_dir="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. ${base_dir}/install.config

# update PATH just in case
export PATH=$PATH:/sbin:/usr/sbin

# check package manager used on the system and install appropriate packages/init scripts
if [[ `which apt-get` ]]; then
	apt-get update  --fix-missing
	apt-get install -y ruby rubygems build-essential irb wget curl lsb-release git
	getosinfo
	wget http://apt.puppetlabs.com/puppetlabs-release-${codename}.deb
	if [[ $? -eq 0 ]]; then 
		dpkg -i puppetlabs-release-${codename}.deb
		apt-get update
		# install mcollective client
		apt-get install -y mcollective-client
		rm puppetlabs-release-${codename}.deb
	else
		echo "Something went wrong while installing the Puppetlabs apt repo. Possible reason is this OS is not officially supported."
	fi;
	# enable ec2-run-user-data just to be sure
	[[ -f /etc/init.d/ec2-run-user-data ]] && update-rc.d ec2-run-user-data defaults
elif [[ `which yum` ]]; then
	yum -y install ruby rubygems redhat-lsb git
	yum -y groupinstall "Development tools"
	getosinfo
	# install and enable cloud-init scripts on RHEL/Centos if not available
	[[ ! -f /etc/init.d/ec2-run-user-data ]] && cp ${base_dir}/src/etc/init.d/ec2-run-user-data /etc/init.d/
	chkconfig --level 345 ec2-run-user-data on
	if [[ ${release:0:1} == 5 ]]; then
		rpm -ivh http://yum.puppetlabs.com/el/5/products/i386/puppetlabs-release-5-6.noarch.rpm
	elif [[ ${release:0:1} == 6 ]]; then
		rpm -ivh http://yum.puppetlabs.com/el/6/products/i386/puppetlabs-release-6-6.noarch.rpm
	else
		echo "Something went wrong while installing the Puppetlabs apt repo. Possible reason is this OS is not officially supported."
	fi;
	# install mcollective client
	yum -y install mcollective-client
else
	echo "Unsuported OS for autmatic agent installation. Exiting now..."
	exit 1
fi;

# install puppet
gem install puppet -v "${puppet_version}" --no-rdoc --no-ri

# create puppet group
groupadd puppet

# create puppet dirs
mkdir -p {/var/log/puppet/,/var/lib/puppet/lib/puppet/indirector,/etc/puppet/modules,/usr/share/mcollective/plugins/mcollective}

# install the dtk-client gem from the repository (no auth since it will be public by release)
gem sources -a http://gems.r8network.com
gem install dtk-client --no-rdoc --no-ri