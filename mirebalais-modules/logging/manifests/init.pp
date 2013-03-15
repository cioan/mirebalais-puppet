class logging (
  $smtp_username = decrypt(hiera('smtp_username')),
  $smtp_password = decrypt(hiera('smtp_password')),
  ){

  file { '/etc/logstash/conf.d/logstash.conf':
    ensure  => file,
    content => template('mirebalais_logging/logstash.conf.erb'),
    require => File['/etc/logstash/conf.d'],
    notify  => Service['logstash']
  }

  class { 'logstash':
    provider     => 'custom',
    jarfile      => 'puppet:///modules/mirebalais_logging/logstash-1.1.9-monolithic.jar',
    installpath  => '/usr/local/logstash',
    defaultsfile => 'puppet:///modules/mirebalais_logging/logstash_default'
  }

  if $environment == 'production_slave' {
    include mirebalais_logging::kibana
  }
}
