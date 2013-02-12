class mirebalais::components::mirth (
    $root_password = $mirebalais::mysql_root_password,
    $mirth_db = $mirebalais::mysql_mirth_db,
    $mirth_db_user = $mirebalais::mysql_mirth_db_user,
    $mirth_db_password = $mirebalais::mysql_mirth_db_password,
    $mirth_user = $mirebalais::mirth_user,
    $mirth_password = $mirebalais::mirth_password,
    $default_db = $mirebalais::mysql_default_db,
    $tomcat = $mirebalais::tomcat,
    $pacs_ip_address = $mirebalais::pacs_ip_address,
    $pacs_destination_port = $mirebalais::pacs_destination_port

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
    require  => [ File['/etc/init.d/mcservice'], File['/usr/local/mirthconnect/conf/mirth.properties'], File["/usr/local/mirthconnect/appdata"], Database[$mirth_db] ]
  }

  exec { 'create mirth user':
    cwd      => '/usr/local/mirthconnect',
    command  => "echo 'user add ${mirth_user} ${mirth_password} mirth user PIH mogoodrich@pih.org' | /usr/local/mirthconnect/mccommand",
    require => Service['mcservice']
  }

  exec { 'stop all channels':
    cwd      => '/usr/local/mirthconnect',
    command  => "echo 'channel stop *' | /usr/local/mirthconnect/mccommand",
    require => Service['mcservice']
  }

  file { '/tmp/readHL7FromOpenmrsDatabaseChannel.xml':
    ensure  => present,
    content => template("mirebalais/mirth/readHL7FromOpenmrsDatabaseChannel.xml.erb"),
  }

  file { '/tmp/sendHL7ToPacsChannel.xml':
    ensure  => present,
    content => template("mirebalais/mirth/sendHL7ToPacsChannel.xml.erb"),
  }

  exec { 'import read channel':
    cwd      => '/usr/local/mirthconnect',
    command  => "echo 'import /tmp/readHL7FromOpenmrsDatabaseChannel.xml force' | /usr/local/mirthconnect/mccommand",
    require => [ Service['mcservice'], Exec['stop all channels'], File['/tmp/readHL7FromOpenmrsDatabaseChannel.xml'] ]
  }

  exec { 'import write channel':
    cwd      => '/usr/local/mirthconnect',
    command  => "echo 'import /tmp/sendHL7ToPacsChannel.xml force' | /usr/local/mirthconnect/mccommand",
    require => [ Service['mcservice'], Exec['stop all channels'], File['/tmp/sendHL7ToPacsChannel.xml'] ]
  }

  exec { 'deploy read channel':
    cwd      => '/usr/local/mirthconnect',
    command  => "echo 'channel deploy \"Read HL7 From OpenMRS Database\"' | /usr/local/mirthconnect/mccommand",
    require => [ Service['mcservice'], Exec['import read channel'] ]
  }

  exec { 'deploy write channel':
    cwd      => '/usr/local/mirthconnect',
    command  => "echo 'channel deploy \"Send HL7 To Pacs\"' | /usr/local/mirthconnect/mccommand",
    require => [ Service['mcservice'], Exec['import write channel'] ]
  }

  exec { 'start all channels':
    cwd      => '/usr/local/mirthconnect',
    command  => "echo 'channel start *' | /usr/local/mirthconnect/mccommand",
    require => [ Service['mcservice'], Exec['deploy read channel'], Exec['deploy write channel'] ]
  }

}

