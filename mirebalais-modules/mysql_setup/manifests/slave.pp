class mysql_setup::slave (
  $master_ip = hiera('mysql_master_ip'),
  $replication_user = decrypt(hiera('replication_db_user')),
  $replication_password = decrypt(hiera('replication_db_password')),
  $root_password = decrypt(hiera('mysql_root_password')),
){

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
