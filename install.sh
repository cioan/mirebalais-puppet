#! /bin/bash

if [ -z "$1" ]
  then
    echo "You need to provide the environment to install in:"
    echo "./install.sh ENVIRONMENT"
    echo "ENVIRONMENT can be test|production|production_slave"
    exit 1
fi

apt-get install -y puppet rubygems

gem install --no-rdoc --no-ri puppet-module

MODULES_FILE="PuppetModules"

function install_modules(){
  while read module 
  do
    puppet module install $module
  done < $MODULES_FILE
}

install_modules
puppet apply -v --modulepath "modules/:./:$(puppet config print modulepath)" site.pp --environment $1

exit 0
