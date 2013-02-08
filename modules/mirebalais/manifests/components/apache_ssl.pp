class mirebalais::components::apache_ssl {
  
  package { "apache2": 
    ensure => installed,
  }

  package { "libapache2-mod-jk": 
    ensure => installed,
  }

  exec {'skipping license approval':
    command => "/bin/echo  'oracle-java6-installer shared/accepted-oracle-license-v1-1 boolean true' | /usr/bin/debconf-set-selections",
    user    => 'root',
    require => Apt::Ppa['ppa:webupd8team/java'],
  }

}
