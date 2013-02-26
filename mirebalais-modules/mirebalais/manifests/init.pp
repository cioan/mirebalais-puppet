class mirebalais {

  include mirebalais::components::java
  include mirebalais::components::tomcat
  include mirebalais::components::openmrs
  include mirebalais::components::apache_ssl
  include mirebalais::components::mirth

  if $environment == 'production' {
    include mirebalais::components::mysql_backup
  }

  include mirebalais::components::mysql

  class { 'apt':
    always_apt_update => true,
  }

  file { '/etc/environment':
    source => 'puppet:///modules/mirebalais/etc/environment'
  }

}
