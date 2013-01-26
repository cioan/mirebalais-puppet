class mysql_mirebalais {
    include mysql

  class { 'mysql::server': 
    config_hash => { 'root_password' => 'foo' }
  }

  mysql::db { 'openmrs':
    user     => 'openmrs',
    password => 'foo',
    host     => 'localhost',
    grant    => ['all'],
    require  => Class['mysql::server']
  }


}
