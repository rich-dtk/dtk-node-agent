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
	apt-get -y install python-software-properties build-essential wget curl lsb-release logrotate
	getosinfo
	if [[ ${osname} == 'Ubuntu' ]]; then
		# add the git core ppa
		yes | sudo add-apt-repository ppa:git-core/ppa
		apt-get update
	fi;
	if [[ ${codename} == 'squeeze' ]]; then
		echo "deb http://backports.debian.org/debian-backports squeeze-backports main" > /etc/apt/sources.list.d/squeeze-backports.list
		apt-get update
		apt-get -y install git/squeeze-backports
	fi;
	apt-get -y install git
	# install puppet-omnibus
	wget "http://dtk-storage.s3.amazonaws.com/puppet-omnibus_2.7.23-fpm0_amd64.deb" -O puppet-omnibus.deb
	dpkg -i puppet-omnibus.deb
	apt-get -y -f install
	rm -rf puppet-omnibus.deb
elif [[ `which yum` ]]; then
	# install ruby and git
	yum -y groupinstall "Development Tools"
	yum -y install ruby rubygems ruby-devel wget redhat-lsb logrotate
	# install puppet-omnibus
	getosinfo
	wget "http://dtk-storage.s3.amazonaws.com/puppet-omnibus-2.7.23.fpm0-1.x86_64.el${release:0:1}.rpm" -O puppet-omnibus.rpm
	yum -y --nogpgcheck localinstall puppet-omnibus.rpm
	rm -rf puppet-omnibus.rpm
else
	echo "Unsuported OS for automatic agent installation. Exiting now..."
	exit 1
fi;

export PATH=/opt/puppet-omnibus/embedded/bin/:/opt/puppet-omnibus/bin/:$PATH

# remove any existing gems
[[ `ls ${base_dir}/*.gem 2>/dev/null` ]] && rm ${base_dir}/*.gem
# install the dtk-node-agent gem
cd ${base_dir}
gem build ${base_dir}/dtk-node-agent.gemspec
gem install ${base_dir}/dtk-node-agent*.gem --no-rdoc --no-ri

# run the gem
dtk-node-agent -d

# link the mcollective daemon script to the omnibus path
ln -sf /opt/puppet-omnibus/embedded/bin/mcollectived /usr/sbin/mcollectived

# remove puppet.conf if it exists
[[ -f /etc/puppet/puppet.conf ]] && rm /etc/puppet/puppet.conf

# copy puppet and mcollective logrotate files
[[ ! -f /etc/logrotate.d/mcollective ]] && cp ${base_dir}/src/etc/logrotate.d/mcollective /etc/logrotate.d/mcollective
[[ ! -f /etc/logrotate.d/puppet ]] && cp ${base_dir}/src/etc/logrotate.d/puppet /etc/logrotate.d/puppet

# remove root ssh files
rm /root/.ssh/id_rsa
rm /root/.ssh/id_rsa.pub 
rm /root/.ssh/known_hosts

# remove mcollective and puppet logs
rm -f /var/log/mcollective.log /var/log/puppet/*

# sanitize the AMI (creating unique ssh host keys will be handled by the cloud-init package)
find /root/.*history /home/*/.*history -exec rm -f {} \;
find /root /home /etc -name "authorized_keys" -exec rm -f {} \;
