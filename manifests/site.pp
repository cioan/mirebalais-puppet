Exec { path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/', '/usr/local/bin/' ] }

node default {
  class { 'apt':
    always_apt_update => true,
  }

  include wget
  include java
  include mysql_setup
  include mirth
  include tomcat
  include openmrs
}

node /^((?!replication).*)$/ inherits default {
  include mysql_setup::db_setup
  include mirth::channel_setup
}

node 'emr.hum.ht' inherits default {
  include apache2
  include logging
  include mysql_setup::db_setup
  include mysql_setup::backup
  include mysql_setup::replication
  include mirth::channel_setup
}

node 'emrreplicaiton.hum.ht' inherits default {
  include apache2
  include logging
  include logging::hiera
  include mysql_setup::slave
}
