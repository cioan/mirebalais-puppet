Exec { path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/', '/usr/local/bin/' ] }

node default {
  class { 'apt':
    always_apt_update => true,
  }

  include wget
  include java
  include mysql
  include mysql_setup
  include tomcat
  include openmrs
}

node mirebalais inherits default {
  include mirth
  include openmrs::mirebalais
}

node /^((?!replication).*)$/ inherits mirebalais {
  include mysql_setup::db_setup
  include mirth::channel_setup
  include openmrs::initial_setup
}

node 'emr.hum.ht' inherits mirebalais {
  include ntpdate
  include apache2
  include logging
  include mysql_setup::db_setup
  include mysql_setup::backup
  include mysql_setup::replication
  include mirth::channel_setup
  include openmrs::initial_setup
}

node 'emrreplication.hum.ht' inherits mirebalais {
  include ntpdate
  include apache2
  include logging
  include logging::kibana
  include mysql_setup::slave
}

node 'emrtest.hum.ht' inherits mirebalais {
  include ntpdate
  include mysql_setup::db_setup
  include mirth::channel_setup
  include openmrs::initial_setup
}

node 'rwandatest.pih-emr.org' inherits default {
  include openmrs::rwanda
}
