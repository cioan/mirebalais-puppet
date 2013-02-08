class mirebalais::components::mysql (
    $root_password = $mirebalais::mysql_root_password,
    $default_db = $mirebalais::mysql_default_db,
    $default_db_user = $mirebalais::mysql_default_db_user,
    $default_db_password = $mirebalais::mysql_default_db_password,
  ){

  include mysql

  class { 'mysql::server': 
    manage_service => false,
    config_hash => { 
      'root_password' => $root_password,  
      'config_file' => '/tmp/my.cnf',
      'restart' => false
    },
  } ->

  class { 'mysql::backup':
    backupuser     => $default_db_user,
    backuppassword => $default_db_password,
    backupdir      => '/tmp/backups',
  }

  file { '/etc/mysql/my.cnf':
    source  => 'puppet:///modules/mirebalais/mysql/my.cnf',
    ensure  => file,
  } ~>

  service { 'mysqld':
    ensure   => running,
    name     => 'mysql',
    enable   => true,
    require  => [File['/etc/mysql/my.cnf'], Package['mysql-server']],
  } ->

  database { $default_db :
    require => Service['mysqld'],
    ensure  => present,
    charset => 'utf8',
  } ->

  database_user { "${default_db_user}@localhost":
    password_hash => mysql_password($default_db_password),
    ensure  => present,
    require => Service['mysqld'],
  } ->

  database_grant { "${default_db_user}@localhost/${default_db}":
    privileges => ['all'],
    require => Service['mysqld'],
  } ->

  database_grant { "root@localhost/${default_db}":
    privileges => ['all'],
    require => Service['mysqld'],
  }

}

