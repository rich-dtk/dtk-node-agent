#!/usr/bin/env bash

# read the config file
DIR="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. ${DIR}/install.config

# install all the necessary dependencies
apt-get install -y ruby1.8 ruby1.8-dev build-essential libruby1.8-extras irb wget curl rubygems1.8 lsb_release

# get OS codename
osname=`lsb_release -d | | awk '{print $2}'`
codename=`lsb_release -c | awk '{print $2}'`

# install puppet and gems
gem install puppet -v "${puppet_version}" --no-rdoc --no-ri
gem install grit stomp --no-rdoc --no-ri 

# create puppet group
groupadd puppet

# create puppet dirs
mkdir -p /var/log/puppet

# download and add the official puppet labs apt repo
wget http://apt.puppetlabs.com/puppetlabs-release-${codename}.deb
if [[ $? -eq 0 ]]; then 
	dpkg -i puppetlabs-release-${codename}.deb
else
	echo "Something went wrong while installing the Puppetlabs apt repo. Possible reason is this OS is not officially supported."
fi;

# install the latest version of mcollective
apt-get install mcollective mcollective-client mcollective-common

# copy puppet libs
mkdir -p  /var/lib/puppet/lib/puppet/indirector/
cp -rf ${DIR}/puppet_additions/puppet_lib_base/puppet/indirector/* /var/lib/puppet/lib/puppet/indirector/

# copy mcollective plugins
cp -rf ${DIR}/mcollective_additions/plugins/v${mcollective_version}/ /usr/share/mcollective/plugins

# copy mcollective config
cp -f ${DIR}/mcollective_additions/server.cfg /etc/mcollective

# start the mcollective service
service mcollective start