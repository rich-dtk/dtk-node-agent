#!/bin/sh
#TODO: clean up
/etc/init.d/mcollective stop
base_dir=`dirname "$0"`

cat ${base_dir}/clean/etc/mcollective/facts.yaml > /etc/mcollective/facts.yaml
cat ${base_dir}/clean/etc/mcollective/server.cfg > /etc/mcollective/server.cfg

rm -r /etc/puppet/modules/*
cp -r ${base_dir}/../src/etc/puppet/modules/r8 /etc/puppet/modules/

rm /var/log/mcollective.log
rm /var/log/puppet/*

rm -f /var/ec2/*ec2-run-user-data.*

rm /root/.ssh/id_rsa
rm /root/.ssh/id_rsa.pub 
rm /root/.ssh/known_hosts 

