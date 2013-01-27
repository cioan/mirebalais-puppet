#! /bin/bash

MODULES_FILE="PuppetModules"

function install_modules(){
  while read module 
  do
    puppet module install $module
  done < $MODULES_FILE
}

install_modules
puppet apply -v --modulepath "modules/:$(puppet config print modulepath)" site.pp 
