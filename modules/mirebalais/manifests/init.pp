class mirebalais(
    $mysql_root_password = 'foo',
    $mysql_default_db = 'openmrs',
    $mysql_default_db_user = 'openmrs',
    $mysql_default_db_password = 'foo',
    $tomcat = 'tomcat6',
    $mysql_mirth_db = 'mirthdb',
    $mysql_mirth_db_user = 'mirth',
    $mysql_mirth_db_password = 'foo',
    $mirth_user = 'mirth',
    $mirth_password = 'Mirth123',
  ){

  include mirebalais::components::java
  include mirebalais::components::tomcat
  include mirebalais::components::openmrs
  include mirebalais::components::apache_ssl
  include mirebalais::components::mirth

  class { 'mirebalais::components::mysql':
    root_password => $mysql_root_password,
    default_db => $mysql_default_db,
    default_db_user => $mysql_default_db_user,
    default_db_password => $mysql_default_db_password 
  }

  file { '/etc/environment':
    source => "puppet:///modules/mirebalais/etc/environment"
  }  

}

class { 'apt':
  always_apt_update    => true,
}
