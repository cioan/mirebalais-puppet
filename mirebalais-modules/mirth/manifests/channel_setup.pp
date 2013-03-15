class mirth::channel_setup (
  $mirth_user = decrypt(hiera('mirth_user')),
  $mirth_password = decrypt(hiera('mirth_password')),
) {

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
    content => template('mirth/readHL7FromOpenmrsDatabaseChannel.xml.erb'),
    require => File['/usr/local/mirthconnect']
  }

  file { '/usr/local/mirthconnect/sendHL7ToPacsChannelMirebalais.xml':
    ensure  => present,
    content => template('mirth/sendHL7ToPacsChannelMirebalais.xml.erb'),
    require => File['/usr/local/mirthconnect']
  }

  file { '/usr/local/mirthconnect/sendHL7ToPacsChannelBoston.xml':
    ensure  => present,
    content => template('mirth/sendHL7ToPacsChannelBoston.xml.erb'),
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
