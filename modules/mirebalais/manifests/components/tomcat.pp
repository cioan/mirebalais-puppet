class mirebalais::components::tomcat (
    $tomcat = $mirebalais::tomcat,
  ){

  case $tomcat {
    tomcat6: {
      $version = '6.0.36'
      $source = 'http://archive.apache.org/dist/tomcat/tomcat-6/v6.0.36/bin/apache-tomcat-6.0.36.tar.gz'
    }
    tomcat7: {
      $version = '7.0.35'
      $source = 'http://archive.apache.org/dist/tomcat/tomcat-7/v7.0.35/bin/apache-tomcat-7.0.35.tar.gz'
    }
  }

  notice("installing tomcat version: ${version}")

  include wget

  package { "tar":
    ensure => installed,
  }

  wget::fetch { "download-tomcat":
    source      => $source,
    destination => "/tmp/tomcat.tgz",
    timeout     => 0,
    verbose     => false,
  }

  exec { "tomcat-unzip":
    cwd     => "/usr/local",
    command => "tar --group=${tomcat} --owner=${tomcat} -xzf /tmp/tomcat.tgz",
    unless  => "test -d /usr/local/apache-tomcat-${version}",
    require => [ Package["tar"], Wget::Fetch["download-tomcat"], User[$tomcat] ],
  } ~>

  file { "/usr/local/${tomcat}":
    ensure  => 'link',
    target  => "/usr/local/apache-tomcat-${version}",
    owner   => $tomcat,
    group   => $tomcat,
    require => Exec["tomcat-unzip"],
  }

  file { "/etc/init.d/${tomcat}":
    source  => "puppet:///modules/mirebalais/${tomcat}/init",
    ensure  => file,
  }

  file { "/etc/default/${tomcat}":
    source  => "puppet:///modules/mirebalais/${tomcat}/default",
    ensure  => file,
  }

  file { "/etc/logrotate.d/${tomcat}":
    source  => "puppet:///modules/mirebalais/${tomcat}/logrotate",
    ensure  => file,
  }

  user { $tomcat:
    ensure => 'present',
    home   => "/home/${tomcat}",
    shell  => '/bin/sh',
  }

  file { "/home/${tomcat}":
    ensure  => directory,
    owner   => $tomcat,
    group   => $tomcat,
    mode    => 755,
    require => User[$tomcat]
  }

  service { $tomcat:
    enable => true,
    require => [ Exec['tomcat-unzip'], File["/usr/local/${tomcat}"] ],
  }   

}
