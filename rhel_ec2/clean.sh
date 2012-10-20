#!/bin/sh
#TODO: clean up;ceomplete hack
/etc/init.d/mcollective stop
base_dir=`dirname "$0"`

echo "temporarily commented out update to facts.yaml and server.cfg to keep server addr nailed"
#cat ${base_dir}/clean/etc/mcollective/facts.yaml > /etc/mcollective/facts.yaml
#cat ${base_dir}/clean/etc/mcollective/server.cfg > /etc/mcollective/server.cfg

cd /root/.ssh; rm id_rsa id_rsa.pub known_hosts 

rm -r /etc/puppet/modules/*
rm /var/log/mcollective.log
rm /var/log/puppet/*
