class mirebalais_logging (
  $smtp_username = decrypt(hiera('smtp_username')),
  $smtp_password = decrypt(hiera('smtp_password')),
  ){

  logstash::input::file { 'syslog':
    type => 'syslog',
    path => [ '/var/log/*.log', '/var/log/messages', '/var/log/syslog' ]
  }

  logstash::input::file { 'apache-access':
    type => 'apache-access',
    path => [ '/var/log/apache2/ssl_access.log' ]
  }

  logstash::input::file { 'apache-error':
    type => 'apache-error',
    path => [ '/var/log/apache2/error.log' ]
  }

  logstash::input::file { 'tomcat':
    type => 'tomcat',
    path => [ '/usr/local/tomcat6/logs/catalina.out' ]
  }

  logstash::filter::grok { 'apache-combined-log':
    type    => 'apache-access',
    pattern => [ '%{COMBINEDAPACHELOG}' ]
  }

  logstash::filter::grep { 'tomcat-error-tag':
    add_tag   => [ 'error' ],
    add_field => { 'event_type' => 'ERROR' },
    drop      => false,
    match     => { '@message' => 'ERROR' },
    type      => 'tomcat'
  }

  logstash::filter::grep { 'tomcat-warn-tag':
    add_tag   => [ 'warning' ],
    add_field => { 'event_type' => 'WARN' },
    drop      => false,
    match     => { '@message' => 'WARN' },
    type      => 'tomcat'
  }

  logstash::filter::multiline { 'tomcat-exception':
    pattern => '^[^\s]+Exception',
    type    => 'tomcat',
    what    => 'previous'
  }

  logstash::filter::multiline { 'tomcat-stacktrace':
    pattern => '^\t',
    type    => 'tomcat',
    what    => 'previous'
  }

  logstash::filter::multiline { 'tomcat-stacktrace-continued':
    pattern => '^Caused by',
    type    => 'tomcat',
    what    => 'previous'
  }

  logstash::output::elasticsearch { 'elasticsearch':
    embedded => true
  }

  logstash::output::email { 'error_email':
    to      => 'mirebalais@thoughtworks.com',
    match   => {'error' => '@event_type,ERROR, , or, @event_type,WARN'},
    options => {'address'              => 'smtp.gmail.com',
                'port'                 => '587',
                'userName'             => $smtp_username,
                'password'             => $smtp_password,
                'enable_starttls_auto' => true,
                'authentication'       => 'plain'},
    tags    => ['error', 'warning'],
    type    => 'tomcat',
    subject => 'Found ERROR or WARN on %{@source_host}',
    body    => 'Here is the event line %{@message}'
  }

  class { 'logstash':
    provider     => 'custom',
    jarfile      => 'puppet:///modules/mirebalais_logging/logstash-1.1.9-monolithic.jar',
    installpath  => '/usr/local/logstash',
    defaultsfile => 'puppet:///modules/mirebalais_logging/logstash_default'
  }
}
