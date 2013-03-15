class mirebalais {

  include mirebalais::components::java
  include mirebalais::components::tomcat
  include mirebalais::components::openmrs
  include mirebalais::components::mirth

  if $environment != 'test' {
    include mirebalais::components::apache_ssl
  }

  if $environment == 'production' {
    include mirebalais::components::mysql_backup
  }

  include mirebalais::components::mysql

  
}
