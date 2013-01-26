class jdk {
  include apt
  
  apt::ppa { "ppa:webupd8team/java": }

   package { "oracle-java6-installer": 
    ensure => installed,
    require => [Apt::Ppa['ppa:webupd8team/java'],
                Exec['skipping license approval']]
  }

  exec {'skipping license approval':
    command => "/bin/echo  'oracle-java6-installer shared/accepted-oracle-license-v1-1 boolean true' | /usr/bin/debconf-set-selections",
    user    => 'root',
    require => Apt::Ppa['ppa:webupd8team/java'],
  }

}
