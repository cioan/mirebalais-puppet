class openmrs::mirebalais (
    $mirebalais_release = hiera('mirebalais_release'),
    $tomcat = hiera('tomcat'),
    $remote_zlidentifier_url = hiera('remote_zlidentifier_url'),
    $remote_zlidentifier_username = decrypt(hiera('remote_zlidentifier_username')),
    $remote_zlidentifier_password = decrypt(hiera('remote_zlidentifier_password')),
	  $lacolline_server_url = hiera('lacolline_server_url'),
    $lacolline_username = decrypt(hiera('lacolline_username')),
    $lacolline_password = decrypt(hiera('lacolline_password')),
  ){

  file { '/etc/apt/apt.conf.d/99auth':
    ensure  => present,
    owner   => root,
    group   => root,
    content => 'APT::Get::AllowUnauthenticated yes;',
    mode    => '0644'
  }

  apt::source { 'mirebalais':
    ensure      => present,
    location    => 'http://bamboo.pih-emr.org/mirebalais-repo',
    release     => $mirebalais_release,
    repos       => '',
    include_src => false,
  }

  package { 'mirebalais':
    ensure  => latest,
    require => [ Service[$tomcat], Apt::Source['mirebalais'], File['/etc/apt/apt.conf.d/99auth'] ],
  }

  file { "/home/${tomcat}/.OpenMRS/mirebalais.properties":
    ensure  => present,
    content => template('openmrs/mirebalais.properties.erb'),
    owner   => $tomcat,
    group   => $tomcat,
    mode    => '0644',
    require => File["/home/${tomcat}/.OpenMRS"]
  }

  file { "/home/${tomcat}/.OpenMRS/feature_toggles.properties":
    ensure  => present,
    content => template('openmrs/feature_toggles.properties.erb'),
    owner   => $tomcat,
    group   => $tomcat,
    mode    => '0644',
    require => File["/home/${tomcat}/.OpenMRS"]
  }
}

