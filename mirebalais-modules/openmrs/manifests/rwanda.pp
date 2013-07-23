class openmrs::rwanda (
    $tomcat = hiera('tomcat'),

    $war_file = "openmrs.war",
    $war_url = "http://amigo.pih-emr.org/rwanda/openmrs/war/",
    $omod_url = "http://amigo.pih-emr.org/rwanda/openmrs/modules/",
  ){

  file { "/home/${tomcat}/.OpenMRS/modules":
    ensure  => directory,
    owner   => $tomcat,
    group   => $tomcat,
    mode    => '0755',
    require => File["/home/${tomcat}/.OpenMRS"]
  }

  wget::fetch { 'download-module-tarball':
    source      => 'http://amigo.pih-emr.org/rwanda/openmrs/modules/modules.tgz',
    destination => "/home/${tomcat}/openmrs-modules.tgz",
    timeout     => 0,
    verbose     => false,
  }

  exec { 'clear-modules':
    cwd     => "/home/${tomcat}/.OpenMRS/modules",
    command => "rm -f *.omod",
    require => File["/home/${tomcat}/.OpenMRS/modules"]
  }

  exec { 'module-tarball-unzip':
    cwd     => "/home/${tomcat}/",
    command => "tar --group=${tomcat} --owner=${tomcat} -xzf openmrs-modules.tgz -C .OpenMRS/modules",
    unless  => "test -d /usr/local/apache-tomcat-${version}",
    require => [ Wget::Fetch['download-tomcat'], User[$tomcat], Exec['clear-modules'] ],
  }

  wget::fetch { 'download-war':
    source      => 'http://amigo.pih-emr.org/rwanda/openmrs/war/openmrs.war',
    destination => "/usr/local/${tomcat}/webapps",
    timeout     => 0,
    verbose     => false,
    require => File["/usr/local/${tomcat}"],
  }

  exec { 'tomcat-stop':
    command     => "service ${tomcat} stop",
    user        => 'root',
    require => [ File["/usr/local/${tomcat}"], File["/etc/init.d/${tomcat}"], File["/etc/default/${tomcat}"], File["/etc/logrotate.d/${tomcat}"] ]
  }

  exec { 'clear-tomcat-files':
    cwd     => "/usr/local/${tomcat}",
    command => "rm -rf webapps/openmrs && rm -rf temp && rm -rf work",
    require => Exec['tomcat-stop'],
  }

  exec { 'tomcat-start':
    command     => "service ${tomcat} start",
    user        => 'root',
    require => [ Exec['module-tarball-unzip'], Wget::Fetch['download-war'], Exec['clear-tomcat-files'] ]
  }
}
