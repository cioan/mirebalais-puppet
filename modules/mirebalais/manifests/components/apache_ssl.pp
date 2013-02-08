class mirebalais::components::apache_ssl (
    $tomcat = $mirebalais::tomcat,
  ){
  
  package { "apache2": 
    ensure => installed,
  }

  package { "libapache2-mod-jk": 
    ensure => installed,
  }

  file { '/etc/apache2/workers.properties':
    ensure => present,
    content => template("mirebalais/apache2/workers.properties.erb"),
    source => "puppet:///modules/mirebalais/apache2/workers.properties"
  } ~>

  file { '/etc/apache2/mods-available/jk.conf':
    ensure => present,
    source => "puppet:///modules/mirebalais/apache2/jk.conf"
  } ~>

  file { '/etc/apache2/sites-available/default-ssl':
    ensure => file,
    source => "puppet:///modules/mirebalais/apache2/sites-available/default-ssl"
  } ~>

  file { '/etc/apache2/sites-available/default':
    ensure => file,
    source => "puppet:///modules/mirebalais/apache2/sites-available/default"
  } ~>
  
  file { '/etc/ssl/certs/_.pih-emr.org.crt':
    ensure => present,
    source => "puppet:///modules/mirebalais/etc/ssl/certs/_.pih-emr.org.crt"
  } ~>

  file { '/etc/ssl/certs/gd_bundle.crt':
    ensure => present,
    source => "puppet:///modules/mirebalais/etc/ssl/certs/gd_bundle.crt"
  } ~>

  exec { 'enable apache mods':
    cmd     => 'a2enmod jk && a2enmod deflate && a2enmod ssl && a2ensite ssl && a2enmod rewrite',
    user    => 'root',
    require => [ Service[$tomcat], Package['apache2'], Package['libapache-mod-jk'] ],
  }

  exec { 'restart apache':
    cmd     => 'service apache2 restart',
    user    => 'root',
    require => [ Service['apache2'], Exec['enable apache mods'] ],
  }

  service { 'apache2':
    ensure   => running,
    enable   => true,
    require  => [ Package['apache2'], Package['libapache-mod-jk'] ],
  } ->

}
