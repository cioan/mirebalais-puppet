class mysql_setup (
    $root_password = decrypt(hiera('mysql_root_password')),
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
    content => template('mysql_setup/my.cnf.erb'),
  } ~>

  service { 'mysqld':
    ensure  => running,
    name    => 'mysql',
    enable  => true,
    require => [ File['/etc/mysql/my.cnf'], Package['mysql-server'] ],
  }
}
