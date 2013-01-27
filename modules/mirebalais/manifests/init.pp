class mirebalais {
  include mirebalais::components::java
  include mirebalais::components::tomcat
  include mirebalais::components::mysql

  file { '/etc/environment' :
		source => "puppet:///modules/mirebalais/etc/environment" ,
  }  


}

