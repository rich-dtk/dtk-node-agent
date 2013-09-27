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
	apt-get install -y ruby1.8 ruby1.8-dev rubygems1.8 libopenssl-ruby1.8 build-essential wget curl lsb-release git
	# make sure ruby 1.8 is the default
	update-alternatives --set ruby /usr/bin/ruby1.8
	update-alternatives --set gem /usr/bin/gem1.8
	getosinfo
	wget http://apt.puppetlabs.com/puppetlabs-release-${codename}.deb
	if [[ $? -eq 0 ]]; then 
		dpkg -i puppetlabs-release-${codename}.deb
		apt-get update
		rm puppetlabs-release-${codename}.deb
	else
		echo "Something went wrong while installing the Puppetlabs apt repo. Possible reason is this OS is not officially supported."
	fi;
	# enable ec2-run-user-data just to be sure
	[[ -f /etc/init.d/ec2-run-user-data ]] && update-rc.d ec2-run-user-data defaults
elif [[ `which yum` ]]; then
	yum -y install redhat-lsb
	yum -y groupinstall "Development tools"
	getosinfo
	# set up epel and puppetlabs repos
	if [[ ${release:0:1} == 5 ]]; then
		[[ ! `yum repolist | grep epel` ]] && rpm -ivh http://dl.fedoraproject.org/pub/epel/5/x86_64/epel-release-5-4.noarch.rpm
		rpm -ivh http://yum.puppetlabs.com/el/5/products/i386/puppetlabs-release-5-6.noarch.rpm
	elif [[ ${release:0:1} == 6 ]]; then
		[[ ! `yum repolist | grep epel` ]] && rpm -ivh http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
		rpm -ivh http://yum.puppetlabs.com/el/6/products/i386/puppetlabs-release-6-6.noarch.rpm
	else
		echo "Something went wrong while installing the Puppetlabs apt repo. Possible reason is this OS is not officially supported."
	fi;
	# install ruby and git
	yum -y install ruby rubygems git
	# make sure gem version and sources are up to date
	[[ ! `gem sources | grep "rubygems.org"` ]] && gem sources -a https://rubygems.org
	gem update --system --no-rdoc --no-ri
	# install ec2-run-user-data init script
	[[ ! -f /etc/init.d/ec2-run-user-data ]] && cp ${base_dir}/src/etc/init.d/ec2-run-user-data /etc/init.d/
	chkconfig --level 345 ec2-run-user-data on
else
	echo "Unsuported OS for automatic agent installation. Exiting now..."
	exit 1
fi;

# install puppet and other gems
gem install puppet -v "${puppet_version}" --no-rdoc --no-ri
gem install grit stomp sshkeyauth --no-rdoc --no-ri

# create puppet group
groupadd puppet

# create puppet dirs
mkdir -p {/var/log/puppet/,/var/lib/puppet/lib/puppet/indirector,/etc/puppet/modules,/usr/share/mcollective/plugins/mcollective}

# install requried puppet modules
[[ ! -d /etc/puppet/modules/mcollective/ ]] && puppet module install example42/mcollective --version 2.0.7
#puppet module install puppetlabs/ruby

# install ruby and and collective via puppet
#puppet apply ${base_dir}/ruby.pp
puppet apply ${base_dir}/mcollective.pp

# copy puppet libs
cp -rf ${base_dir}/puppet_additions/puppet_lib_base/puppet/indirector/* /var/lib/puppet/lib/puppet/indirector/

# copy r8 puppet module
cp -rf ${base_dir}/puppet_additions/modules/r8 /etc/puppet/modules

# copy mcollective plugins
cp -rf ${base_dir}/mcollective_additions/plugins/v${mcollective_version}/* /usr/share/mcollective/plugins/mcollective
[[ -d /usr/libexec/mcollective/ ]] && cp -r /usr/libexec/mcollective/mcollective/* /usr/share/mcollective/plugins/mcollective
# copy mcollective config
cp -f ${base_dir}/mcollective_additions/server.cfg /etc/mcollective

# start the mcollective service
#service mcollective restart

# remove root ssh files
rm /root/.ssh/id_rsa
rm /root/.ssh/id_rsa.pub 
rm /root/.ssh/known_hosts

# remove mcollective and puppet logs
rm -f /var/log/mcollective.log /var/log/puppet/*

# sanitize the AMI (creating unique ssh host keys will be handled by the cloud-init package)
find /root/.*history /home/*/.*history -exec rm -f {} \;
find /root /home /etc -name "authorized_keys" -exec rm -f {} \;
