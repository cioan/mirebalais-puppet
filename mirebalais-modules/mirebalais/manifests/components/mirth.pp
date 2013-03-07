class mirebalais::components::mirth (
    $mirth_db = hiera('mirth_db'),
    $mirth_db_user = decrypt(hiera('mirth_db_user')),
    $mirth_db_password = decrypt(hiera('mirth_db_password')),
    $mirth_user = decrypt(hiera('mirth_user')),
    $mirth_password = decrypt(hiera('mirth_password')),
    $openmrs_db = hiera('openmrs_db'),
    $openmrs_db_user = decrypt(hiera('openmrs_db_user')),
    $openmrs_db_password = decrypt(hiera('openmrs_db_password')),
    $pacs_mirebalais_ip_address = hiera('pacs_mirebalais_ip_address'),
    $pacs_mirebalais_destination_port = hiera('pacs_mirebalais_destination_port'),
    $pacs_boston_ip_address = hiera('pacs_boston_ip_address'),
    $pacs_boston_destination_port = hiera('pacs_boston_destination_port')
  ){

  if $environment != 'production_slave' {
    database { $mirth_db :
      ensure  => present,
      require => Service['mysqld'],
      charset => 'utf8',
    }

    database_user { "${mirth_db_user}@localhost":
      ensure        => present,
      password_hash => mysql_password($mirth_db_password),
      require       => Service['mysqld'],
    } ->

    database_grant { "${mirth_db_user}@localhost/${mirth_db}":
      privileges => ['all'],
      require    => Service['mysqld'],
    } ->

    database_grant { "root@localhost/${mirth_db}":
      privileges => ['all'],
      require    => Service['mysqld'],
    }

    database_grant { "${mirth_db_user}@localhost/${openmrs_db}.pacsintegration_outbound_queue":
      privileges => ['all'],
      require    => [ Service['mysqld'], Database[$openmrs_db] ]
    }

    service { 'mcservice':
      ensure   => running,
      enable   => true,
      require  => [ File['/etc/init.d/mcservice'], File['/usr/local/mirthconnect/conf/mirth.properties'], File['/usr/local/mirthconnect/appdata'], Database[$mirth_db] ]
    }

    exec { 'wait for mcservice':
      command     => 'sleep 5',
      subscribe   => Service['mcservice'],
      refreshonly => true
    }

    exec { 'create mirth user':
      cwd     => '/usr/local/mirthconnect',
      command => "echo 'user add ${mirth_user} ${mirth_password} mirth user PIH mogoodrich@pih.org' | /usr/local/mirthconnect/mccommand",
      require => Exec['wait for mcservice'],
      unless  => 'echo "user list" | /usr/local/mirthconnect/mccommand |grep mirth'
    }

    exec { 'stop all channels':
      cwd         => '/usr/local/mirthconnect',
      command     => "echo 'channel stop *' | /usr/local/mirthconnect/mccommand",
      require     => Exec['wait for mcservice'],
      subscribe   => [ File['/usr/local/mirthconnect/readHL7FromOpenmrsDatabaseChannel.xml'], File['/usr/local/mirthconnect/sendHL7ToPacsChannelMirebalais.xml'], File['/usr/local/mirthconnect/sendHL7ToPacsChannelBoston.xml'] ],
      refreshonly => true
    }

    file { '/usr/local/mirthconnect/readHL7FromOpenmrsDatabaseChannel.xml':
      ensure  => present,
      content => template('mirebalais/mirth/readHL7FromOpenmrsDatabaseChannel.xml.erb'),
      require => File['/usr/local/mirthconnect']
    }

    file { '/usr/local/mirthconnect/sendHL7ToPacsChannelMirebalais.xml':
      ensure  => present,
      content => template('mirebalais/mirth/sendHL7ToPacsChannelMirebalais.xml.erb'),
      require => File['/usr/local/mirthconnect']
    }

    file { '/usr/local/mirthconnect/sendHL7ToPacsChannelBoston.xml':
      ensure  => present,
      content => template('mirebalais/mirth/sendHL7ToPacsChannelBoston.xml.erb'),
      require => File['/usr/local/mirthconnect']
    }

    exec { 'import read channel':
      cwd         => '/usr/local/mirthconnect',
      command     => "echo 'import /usr/local/mirthconnect/readHL7FromOpenmrsDatabaseChannel.xml force' | /usr/local/mirthconnect/mccommand",
      subscribe   => Exec['stop all channels'],
      refreshonly => true
    }

    exec { 'deploy read channel':
      cwd         => '/usr/local/mirthconnect',
      command     => "echo 'channel deploy \"Read HL7 From OpenMRS Database\"' | /usr/local/mirthconnect/mccommand",
      subscribe   => Exec['import read channel'],
      refreshonly => true
    }

    exec { 'import write channel 1':
      cwd         => '/usr/local/mirthconnect',
      command     => "echo 'import /usr/local/mirthconnect/sendHL7ToPacsChannelMirebalais.xml force' | /usr/local/mirthconnect/mccommand",
      subscribe   => Exec['stop all channels'],
      refreshonly => true
    }

    exec { 'deploy write channel 1':
      cwd         => '/usr/local/mirthconnect',
      command     => "echo 'channel deploy \"Send HL7 To Pacs Mirebalais\"' | /usr/local/mirthconnect/mccommand",
      subscribe   => Exec['import write channel 1'],
      refreshonly => true
    }

    exec { 'import write channel 2':
      cwd         => '/usr/local/mirthconnect',
      command     => "echo 'import /usr/local/mirthconnect/sendHL7ToPacsChannelBoston.xml force' | /usr/local/mirthconnect/mccommand",
      subscribe   => Exec['stop all channels'],
      refreshonly => true
    }

    exec { 'deploy write channel 2':
      cwd         => '/usr/local/mirthconnect',
      command     => "echo 'channel deploy \"Send HL7 To Pacs Boston\"' | /usr/local/mirthconnect/mccommand",
      subscribe   => Exec['import write channel 2'],
      refreshonly => true
    }

    exec { 'start all channels':
      cwd         => '/usr/local/mirthconnect',
      command     => "echo 'channel start *' | /usr/local/mirthconnect/mccommand",
      subscribe   => [ Exec['deploy read channel'], Exec['deploy write channel 1'], Exec['deploy write channel 2'] ],
      refreshonly => true
    }
  }

  file {'/usr/local/mirthconnect':
    ensure => directory,
    owner  => 'root',
    group  => 'root'
  }

  wget::fetch { 'download-mirth':
    source      => 'http://downloads.mirthcorp.com/connect/2.2.1.5861.b1248/mirthconnect-2.2.1.5861.b1248-unix.tar.gz',
    destination => '/usr/local/mirth.tgz',
    timeout     => 0,
    verbose     => false,
  } ~>

  exec { 'mirth-unzip':
    cwd     => '/usr/local',
    command => 'tar -C mirthconnect --strip-components=1 -xzf /usr/local/mirth.tgz',
    unless  => 'test -f /usr/local/mirthconnect/mcservice',
    require => [ Package['tar'], Wget::Fetch['download-mirth'], File['/usr/local/mirthconnect'] ],
  }

  file {'/usr/local/mirthconnect/logs':
    ensure  => directory,
    require => Exec['mirth-unzip']
  }

  file {'/usr/local/mirthconnect/appdata':
    source  => 'puppet:///modules/mirebalais/mirth/appdata',
    recurse => true,
    require => Exec['mirth-unzip']
  }

  file { '/usr/local/mirthconnect/conf/mirth.properties':
    ensure  => present,
    content => template('mirebalais/mirth/mirth.properties.erb'),
    require => Exec['mirth-unzip']
  }

  file { '/etc/init.d/mcservice':
    ensure  => link,
    target  => '/usr/local/mirthconnect/mcservice',
    require => Exec['mirth-unzip']
  }

}

