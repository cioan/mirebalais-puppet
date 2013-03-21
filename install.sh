#! /bin/bash

if [ -z "$1" ]
then
  echo "You need to provide the environment to install in:"
  echo "./install.sh ENVIRONMENT"
  echo "ENVIRONMENT can be test|production"
  exit 1
fi

if [ "$1" != "test" ]
then
  if [ ! -f /etc/encryptor_secret_key ]
  then
    echo "Please provide a username to fetch private data"
    read user

    scp $user@dev.pih-emr.org:/etc/mirebalais/* .

    mv encryptor_secret_key /etc/
    mv pih-emr.org.key /etc/ssl/private/
  fi

  if [ ! -f ~/.ssh/id_dsa ]
  then
    ssh-keygen -q -t dsa -f ~/.ssh/id_dsa -P ''
  fi

  echo "Please make sure you have copied this ssh public key to the backup server so that database backups can be uploaded there:"
  cat ~/.ssh/id_dsa.pub
  read -p "Press a key to continue"
fi

apt-get update
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
