class tomcat {

  $tomcat_port = 8080
  
  notice("Establishing http://$hostname:$tomcat_port/")

  package { 'tomcat6':
    ensure => installed,
    require => Package['oracle-java6-installer'],
  }

  user { 'tomcat6':
    ensure => 'present',
    home   => '/home/tomcat6',
    shell  => '/bin/sh',
  }

  service { 'tomcat6':
    ensure => running,
    require => Package['tomcat6'],
  }   

}
