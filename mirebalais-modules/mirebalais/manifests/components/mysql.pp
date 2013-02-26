class mirebalais::components::mysql (
    $root_password = hiera('mysql_root_password'),
    $default_db = hiera('mysql_default_db'),
    $default_db_user = hiera('mysql_default_db_user'),
    $default_db_password = hiera('mysql_default_db_password'),
    $replication_user = hiera('db_replication_user'),
    $replication_password = hiera('db_replication_password'),
    $mysql_server_id = hiera('mysql_server_id'),
  ){

  include mysql

  class { 'mysql::server':
    manage_service => false,
    config_hash    => {
      'root_password' => $root_password,
      'config_file'   => '/tmp/my.cnf',
      'restart'       => false
    },
  } ->

  file { '/etc/mysql/my.cnf':
    ensure  => file,
    content => template('mirebalais/mysql/my.cnf.erb'),
  } ~>

  service { 'mysqld':
    ensure  => running,
    name    => 'mysql',
    enable  => true,
    require => [File['/etc/mysql/my.cnf'], Package['mysql-server']],
  }

  if $environment != 'production_slave' {
    database { $default_db :
      ensure  => present,
      require => Service['mysqld'],
      charset => 'utf8',
    } ->

    database_user { "${default_db_user}@localhost":
      ensure        => present,
      password_hash => mysql_password($default_db_password),
      require       => Service['mysqld'],
    } ->

    database_grant { "${default_db_user}@localhost/${default_db}":
      privileges => ['all'],
      require    => Service['mysqld'],
    } ->

    database_grant { "root@localhost/${default_db}":
      privileges => ['all'],
      require    => Service['mysqld'],
    }

    if $environment != 'test' {

      database_user { "${replication_user}@%":
        ensure        => present,
        password_hash => mysql_password($replication_password),
        require       => Service['mysqld'],
      }

      database_grant { "${replication_user}@%":
        privileges => [Repl_slave_priv],
        require    => Service['mysqld'],
      }
    }
  }

  if $environment == 'production_slave' {
    $master_ip = hiera('mysql_master_ip')
    exec { 'master replication setup':
      command => "/usr/bin/mysql -uroot -p${root_password} -e \"CHANGE MASTER TO MASTER_HOST='${master_ip}', MASTER_USER='${replication_user}', MASTER_PASSWORD='${replication_password}', MASTER_LOG_FILE='mysql-bin.000001', MASTER_LOG_POS=245;\"",
      require => [ Service['mysqld'], Exec['set_mysql_rootpw'] ]
    }

    exec { 'start slave':
      command => "mysql -uroot -p${root_password} -e \"start slave;\"",
      require => [ Service['mysqld'], Exec['master replication setup'] ]
    }
  }

}

