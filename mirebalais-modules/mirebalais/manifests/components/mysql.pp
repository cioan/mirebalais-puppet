class mirebalais::components::mysql (
    $root_password = decrypt(hiera('mysql_root_password')),
    $openmrs_db = hiera('openmrs_db'),
    $openmrs_db_user = decrypt(hiera('openmrs_db_user')),
    $openmrs_db_password = decrypt(hiera('openmrs_db_password')),
    $replication_user = decrypt(hiera('replication_db_user')),
    $replication_password = decrypt(hiera('replication_db_password')),
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
    database { $openmrs_db :
      ensure  => present,
      require => Service['mysqld'],
      charset => 'utf8',
    } ->

    database_user { "${openmrs_db_user}@localhost":
      ensure        => present,
      password_hash => mysql_password($openmrs_db_password),
      require       => Service['mysqld'],
    } ->

    database_grant { "${openmrs_db_user}@localhost/${openmrs_db}":
      privileges => ['all'],
      require    => Service['mysqld'],
    } ->

    database_grant { "root@localhost/${openmrs_db}":
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
      unless  => "mysql -u root -p${root_password} -e 'show slave status'|test -z",
      require => [ Service['mysqld'], Exec['set_mysql_rootpw'] ]
    }

    exec { 'start slave':
      command     => "mysql -uroot -p${root_password} -e \"start slave;\"",
      require     => Service['mysqld'],
      subscribe   => Exec['master replication setup'],
      refreshonly => true
    }
  }

}

