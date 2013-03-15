Exec { path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/', '/usr/local/bin/' ] }

class { 'apt':
  always_apt_update => true,
}

node default {
  include java
  include mysql_setup
  include mirth
  include tomcat
  include openmrs
}

node /^((?!replication).*)$/ inherits default {
  include mysql_setup::db_setup
}

node 'emr.hum.ht' inherits default {
  include apache_ssl
  include logging
  include mysql_setup::db_setup
  include mysql_setup::backup
  include mysql_setup::replication
}

node 'emrreplicaiton.hum.ht' inherits default {
  include apache_ssl
  include logging
  include logging::hiera
  include mysql_setup::slave
}
