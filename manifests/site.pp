Exec { path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/', '/usr/local/bin/' ] }

node default {
  class { 'apt':
    always_apt_update => true,
  }

  include wget
  include java
  include mysql
  include mysql_setup
  include mirth
  include tomcat
  include openmrs
}

node /^((?!replication).*)$/ inherits default {
  include mysql_setup::db_setup
  include mirth::channel_setup
  include openmrs::initial_setup
}

node 'emr.hum.ht' inherits default {
  include ntpdate
  include apache2
  include logging
  include mysql_setup::db_setup
  include mysql_setup::backup
  include mysql_setup::replication
  include mirth::channel_setup
  include openmrs::initial_setup
}

node 'emrreplicaiton.hum.ht' inherits default {
  include ntpdate
  include apache2
  include logging
  include logging::kibana
  include mysql_setup::slave
}

node 'emrtest.hum.ht' inherits default {
  include ntpdate
}
