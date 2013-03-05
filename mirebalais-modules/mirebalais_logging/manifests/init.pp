class mirebalais_logging {

  logstash::input::file { 'syslog':
    type => 'syslog',
    path => [ '/var/log/*.log', '/var/log/messages', '/var/log/syslog' ]
  }

  logstash::input::file { 'apache-access':
    type => 'apache-access',
    path => '/var/log/apache2/ssl_access.log'
  }

  logstash::input::file { 'apache-error':
    type => 'apache-error',
    path => '/var/log/apache2/error.log'
  }

  logstash::input::file { 'tomcat':
    type => 'tomcat',
    path => '/usr/local/tomcat6/logs/catalina.out'
  }

  logstash::filter::grok { 'apache-combined-log':
    type    => 'apache-access',
    pattern => '%{COMBINEDAPACHELOG}'
  }

  logstash::filter::grep { 'tomcat-error-tag':
    add_tag => 'error',
    drop    => false,
    match   => ['@message', 'ERROR'],
    type    => 'tomcat'
  }

  logstash::filter::miltiline { 'tomcat-exception':
    pattern => '^[^\s]+Exception',
    type    => 'tomcat',
    what    => 'previous'
  }

  logstash::filter::miltiline { 'tomcat-stacktrace':
    pattern => '^\t',
    type    => 'tomcat',
    what    => 'previous'
  }

  logstash::filter::miltiline { 'tomcat-stacktrace-continued':
    pattern => '^Caused by',
    type    => 'tomcat',
    what    => 'previous'
  }

  logstash::output::elasticsearch { 'elasticsearch':
    embedded => true
  }

  class { 'logstash':
    provider     => 'custom',
    jarfile      => 'puppet:///modules/mirebalais_logging/logstash-1.1.0-monolithic.jar',
    installpath  => '/usr/local/logstash',
    defaultsfile => 'puppet:///modules/mirebalais_logging/logstash_default'
  }
}
