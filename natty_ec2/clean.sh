#!/bin/sh
#TODO: clean up; complete hack
/etc/init.d/mcollective stop
base_dir=`dirname "$0"`

rm -r /etc/puppet/modules/*
cp -r ${base_dir}/../src/etc/puppet/modules/r8 /etc/puppet/modules/

cp  ${base_dir}/../mcollective_plugins/v2.2/agent/* /usr/share/mcollective/plugins/mcollective/agent
cp  ${base_dir}/../mcollective_plugins/v2.2/facts/* /usr/share/mcollective/plugins/mcollective/facts

cat ${base_dir}/clean/etc/mcollective/facts.yaml > /etc/mcollective/facts.yaml
cat ${base_dir}/clean/etc/mcollective/server.cfg > /etc/mcollective/server.cfg

cd /root/.ssh; rm id_rsa id_rsa.pub known_hosts 

rm /var/log/mcollective.log
rm /var/log/puppet/*
