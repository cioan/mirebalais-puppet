#! /bin/bash

if [ -z "$1" ]
  then
    echo "You need to provide the environment to install in:"
    echo "./install.sh ENVIRONMENT"
    echo "ENVIRONMENT can be test|production|production_slave"
    exit 1
fi

apt-get install -y rubygems

gem install bundler --no-ri --no-rdoc

bundle

librarian-puppet install

echo "modulepath = /etc/puppet/modules:/etc/puppet/mirebalais-modules" > puppet.conf
echo "environment = $1" >> puppet.conf

puppet apply -v \
  --detailed-exitcodes \
  --logdest=console \
  --logdest=syslog \
  manifests/site.pp

test $? -eq 0 -o $? -eq 2
