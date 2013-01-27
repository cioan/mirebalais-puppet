class mirebalais::components::mysql {
    include mysql

  $root_password = 'foo'
  $db_password = 'foo'

  class { 'mysql::server': 
    config_hash => { 'root_password' => $root_password }
  }

  mysql::db { 'openmrs':
    user     => 'openmrs',
    password => $db_password,
    host     => 'localhost',
    grant    => ['all'],
    require  => Class['mysql::server']
  }

}

