class mirebalais::components::mirth (
    $root_password = $mirebalais::mysql_root_password,
    $mirth_db = $mirebalais::mysql_mirth_db,
    $mirth_db_user = $mirebalais::mysql_mirth_db_user,
    $mirth_db_password = $mirebalais::mysql_mirth_db_password,
    $default_db = $mirebalais::mysql_default_db,
    $tomcat = $mirebalais::tomcat
  ){

  database { $mirth_db :
    require => Service['mysqld'],
    ensure  => present,
    charset => 'utf8',
  } ->

  database_user { "${mirth_db_user}@localhost":
    password_hash => mysql_password($mirth_db_password),
    ensure  => present,
    require => Service['mysqld'],
  } ->

  database_grant { "${mirth_db_user}@localhost/${mirth_db}":
    privileges => ['all'],
    require => Service['mysqld'],
  } ->

  database_grant { "root@localhost/${mirth_db}":
    privileges => ['all'],
    require => Service['mysqld'],
  }

  database_grant { "${mirth_db_user}@localhost/${default_db}.pacsintegration_outbound_queue":
    privileges => ['all'],
    require => [ Service['mysqld'], Database[$default_db] ]
  }

  file {"/usr/local/mirthconnect":
    ensure => directory,
    owner  => 'root',
    group  => 'root'
  }

  wget::fetch { "download-mirth":
    source      => 'http://downloads.mirthcorp.com/connect/2.2.1.5861.b1248/mirthconnect-2.2.1.5861.b1248-unix.tar.gz',
    destination => "/tmp/mirth.tgz",
    timeout     => 0,
    verbose     => false,
  } ~>

  exec { "mirth-unzip":
    cwd     => "/usr/local",
    command => "tar -C mirthconnect --strip-components=1 -xzf /tmp/mirth.tgz",
    unless  => "test -f /usr/local/mirthconnect/mcservice",
    require => [ Package["tar"], Wget::Fetch["download-mirth"], File["/usr/local/mirthconnect"] ],
  }

  file {"/usr/local/mirthconnect/logs": 
    ensure  => directory,
    owner   => $tomcat,
    group   => $tomcat,
    require => Exec['mirth-unzip']
  }

  file {"/usr/local/mirthconnect/appdata": 
    source  => "puppet:///modules/mirebalais/mirth/appdata",
    recurse => true,
    require => Exec['mirth-unzip']
  }

  file { '/usr/local/mirthconnect/conf/mirth.properties':
    ensure  => present,
    content => template("mirebalais/mirth/mirth.properties.erb"),
    require => Exec['mirth-unzip']
  }

  file { '/etc/init.d/mcservice':
    ensure => link,
    target => '/usr/local/mirthconnect/mcservice',
    require => Exec['mirth-unzip']
  }

  service { 'mcservice':
    ensure   => running,
    enable   => true,
    require  => File['/etc/init.d/mcservice']
  }

}

