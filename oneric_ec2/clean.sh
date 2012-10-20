#!/bin/sh
#TODO: clean up; complete hack
echo "stop mcollective service"
base_dir=`dirname "$0"`

echo "basedir = ${base_dir}"
cat ${base_dir}/clean/etc/mcollective/facts.yaml > /etc/mcollective/facts.yaml
cat ${base_dir}/clean/etc/mcollective/server.cfg > /etc/mcollective/server.cfg

cd /root/.ssh; rm id_rsa id_rsa.pub known_hosts known_hosts.old

rm -r /etc/puppet/modules/*
rm /var/log/mcollective.log
rm /var/log/puppet/*
