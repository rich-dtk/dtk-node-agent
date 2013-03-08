#!/usr/bin/env bash

# read the config file
base_dir="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. ${base_dir}/install.config

# install all the necessary dependencies
apt-get install -y ruby1.8 ruby1.8-dev build-essential libruby1.8-extras irb wget curl rubygems lsb-release

# get OS info
osname=`lsb_release -d | awk '{print $2}'`
codename=`lsb_release -c | awk '{print $2}'`

# install puppet and gems
gem install puppet -v "${puppet_version}" --no-rdoc --no-ri
gem install grit stomp --no-rdoc --no-ri 

# create puppet group
groupadd puppet

# create puppet dirs
mkdir -p {/var/log/puppet/lib/puppet/indirector/,/etc/puppet/modules}

# download and add the official puppet labs apt repo
wget http://apt.puppetlabs.com/puppetlabs-release-${codename}.deb
if [[ $? -eq 0 ]]; then 
	dpkg -i puppetlabs-release-${codename}.deb
	apt-get update
else
	echo "Something went wrong while installing the Puppetlabs apt repo. Possible reason is this OS is not officially supported."
fi;

# install the latest version of mcollective
apt-get install -y mcollective mcollective-client mcollective-common

# copy puppet libs
cp -rf ${base_dir}/puppet_additions/puppet_lib_base/puppet/indirector/* /var/lib/puppet/lib/puppet/indirector/

# copy r8 puppet module
cp -rf ${base_dir}/puppet_additions/modules/r8 /etc/puppet/modules

# copy mcollective plugins
cp -rf ${base_dir}/mcollective_additions/plugins/v${mcollective_version}/* /usr/share/mcollective/plugins/mcollective

# copy mcollective config
cp -f ${base_dir}/mcollective_additions/server.cfg /etc/mcollective

# start the mcollective service
service mcollective start