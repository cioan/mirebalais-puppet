class apache2 (
  $tomcat = hiera('tomcat'),
  $services_ensure = hiera('services_ensure'),
  $services_enable = hiera('services_enable')
  ){

  package { 'apache2':
    ensure => installed,
  }

  package { 'libapache2-mod-jk':
    ensure => installed,
  }

  file { '/etc/logrotate.d/apache2':
    ensure  => file,
    source  => 'puppet:///modules/apache2/logrotate',
  }

  file { '/etc/apache2/workers.properties':
    ensure  => present,
    content => template('apache2/workers.properties.erb'),
  }

  file { '/etc/apache2/mods-available/jk.conf':
    ensure => present,
    source => 'puppet:///modules/apache2/jk.conf'
  }

  file { '/etc/apache2/sites-available/default-ssl':
    ensure => file,
    source => 'puppet:///modules/apache2/sites-available/default-ssl'
  }

  file { '/etc/apache2/sites-available/default':
    ensure => file,
    source => 'puppet:///modules/apache2/sites-available/default'
  }

  file { '/etc/ssl/certs/_.pih-emr.org.crt':
    ensure => present,
    source => 'puppet:///modules/apache2/etc/ssl/certs/_.pih-emr.org.crt'
  }

  file { '/etc/ssl/certs/gd_bundle.crt':
    ensure => present,
    source => 'puppet:///modules/apache2/etc/ssl/certs/gd_bundle.crt'
  }

  exec { 'enable apache mods':
    command     => 'a2enmod jk && a2enmod deflate && a2enmod ssl && a2ensite default-ssl && a2enmod rewrite',
    user        => 'root',
    subscribe   => [ Service[$tomcat], Package['apache2'], Package['libapache2-mod-jk'] ],
    refreshonly => true,
    notify      => Service['apache2']
  }

  service { 'apache2':
    ensure   => running,
    enable   => true,
    require  => [ Package['apache2'], Package['libapache2-mod-jk'] ],
  }
}