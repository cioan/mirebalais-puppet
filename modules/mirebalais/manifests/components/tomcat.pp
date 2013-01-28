class mirebalais::components::tomcat {

  $tomcat_port = 8080
  
  notice("Establishing http://$hostname:$tomcat_port/")

  package { 'tomcat6':
    ensure => installed,
    require => Package['oracle-java6-installer'],
  }

  user { 'tomcat6':
    ensure => 'present',
    home   => '/home/tomcat6/',
    shell  => '/bin/sh',
  }

  file { '/home/tomcat6':
    ensure  => directory,
    owner   => tomcat6,
    group   => tomcat6,
    mode    => 755,
    require => User['tomcat6']
  }

  service { 'tomcat6':
    ensure => running,
    require => Package['tomcat6'],
  }   

}
