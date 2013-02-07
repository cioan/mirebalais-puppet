class mirebalais::components::tomcat (
    $tomcat = $mirebalais::tomcat,
    $tomcat ? {
      tomcat6 => {
        $version = '6.0.36',
        $source = 'http://archive.apache.org/dist/tomcat/tomcat-6/v6.0.36/bin/apache-tomcat-6.0.36.tar.gz',
      },
      tomcat7 => {
        $version = '7.0.35',
        $source = 'http://archive.apache.org/dist/tomcat/tomcat-7/v7.0.35/bin/apache-tomcat-7.0.35.tar.gz',
      },
    },
  ){

  include wget

  $tomcat_port = 8080

  notice("Establishing http://${hostname}:${tomcat_port}/")

  wget::fetch { "download-tomcat":
    source      => $source,
    destination => "/tmp/tomcat.tgz",
    timeout     => 0,
    verbose     => false,
  }

  exec {"tomcat-unzip":
    cwd     => "/usr/local",
    command => "/usr/bin/unzip /tmp/tomcat.tgz",
    unless  => "test -f /usr/local/${tomcat}",
    require => [ Package["unzip"], Wget::Fetch["download-tomcat"] ],
  }

  file { "/usr/local/apache-tomcat-${version}":
    ensure  => 'link',
    target  => "/usr/local/${tomcat}",
    owner   => $tomcat,
    group   => $tomcat,
    recurse => true,
  }

  file { "/etc/init.d/${tomcat}":
    source  => "puppet:///modules/mirebalais/${tomcat}/init",
    ensure  => file,
  } ~>

  file { "/etc/default/${tomcat}":
    source  => "puppet:///modules/mirebalais/${tomcat}/default",
    ensure  => file,
  } ~>

  user { $tomcat:
    ensure => 'present',
    home   => "/home/${tomcat}/",
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
    ensure => running,
    require => [ Exec['tomcat-unzip'], File["/usr/local/apache-tomcat-${version}"] ],
  }   

}
