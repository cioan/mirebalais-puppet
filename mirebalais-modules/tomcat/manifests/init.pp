class tomcat (
    $tomcat = hiera('tomcat'),
    $services_enable = hiera('services_enable')
    $java_memory_parameters = hiera('java_memory_parameters')
    $java_profiler = hiera('java_profiler')
  ){

  case $tomcat {
    tomcat6: {
      $version = '6.0.36'
      $source  = 'http://archive.apache.org/dist/tomcat/tomcat-6/v6.0.36/bin/apache-tomcat-6.0.36.tar.gz'
    }
    tomcat7: {
      $version = '7.0.35'
      $source  = 'http://archive.apache.org/dist/tomcat/tomcat-7/v7.0.35/bin/apache-tomcat-7.0.35.tar.gz'
    }
  }

  wget::fetch { 'download-tomcat':
    source      => $source,
    destination => "/usr/local/tomcat-${version}.tgz",
    timeout     => 0,
    verbose     => false,
  }

  exec { 'tomcat-unzip':
    cwd     => '/usr/local',
    command => "tar --group=${tomcat} --owner=${tomcat} -xzf /usr/local/tomcat-${version}.tgz",
    unless  => "test -d /usr/local/apache-tomcat-${version}",
    require => [ Wget::Fetch['download-tomcat'], User[$tomcat] ],
  }

  file { "/usr/local/apache-tomcat-${version}":
    ensure  => directory,
    owner   => $tomcat,
    group   => $tomcat,
    recurse => true,
    require => Exec['tomcat-unzip'],
  }

  file { "/usr/local/${tomcat}":
    ensure  => 'link',
    target  => "/usr/local/apache-tomcat-${version}",
    owner   => $tomcat,
    group   => $tomcat,
    require => Exec['tomcat-unzip'],
  }

  file { "/etc/init.d/${tomcat}":
    ensure  => file,
    source  => "puppet:///modules/tomcat/${version}/init",
  }

  file { "/etc/default/${tomcat}":
    ensure  => file,
    content => template("tomcat/${version}/default.erb")
  }

  file { "/etc/logrotate.d/${tomcat}":
    ensure  => file,
    source  => "puppet:///modules/tomcat/${version}/logrotate",
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
    mode    => '0755',
    require => User[$tomcat]
  }

  service { $tomcat:
    enable  => $services_enable,
    require => [ Exec['tomcat-unzip'], File["/usr/local/${tomcat}"], File["/etc/init.d/${tomcat}"] ],
  }
}
