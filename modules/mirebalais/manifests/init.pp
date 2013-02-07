class mirebalais(
    $mysql_root_password = 'foo',
    $mysql_default_db = 'openmrs',
    $mysql_default_db_user = 'openmrs',
    $mysql_default_db_password = 'foo'
    $tomcat = 'tomcat6'
  ){

  include mirebalais::components::java
  include mirebalais::components::tomcat

  class { 'mirebalais::components::mysql':
    root_password => $mysql_root_password,
    default_db => $mysql_default_db,
    default_db_user => $mysql_default_db_user,
    default_db_password => $mysql_default_db_password 
  }

  file { '/etc/environment':
    source => "puppet:///modules/mirebalais/etc/environment"
  }  

  file { '/home/$tomcat/.OpenMRS':
    ensure  => directory,
    owner   => $tomcat,
    group   => $tomcat,
    mode    => 755,
    require => User[$tomcat]
  }

  file { '/home/$tomcat/.OpenMRS/mirebalais.properties':
    content => template("mirebalais/OpenMRS/mirebalais.properties.erb"),
    ensure  => present,
    owner   => $tomcat,
    group   => $tomcat,
    mode    => 644,
    require => User[$tomcat]
  } 
  
  file { '/home/$tomcat/.OpenMRS/mirebalais-runtime.properties':
    content => template("mirebalais/OpenMRS/mirebalais-runtime.properties.erb"),
    ensure  => present,
    owner   => $tomcat,
    group   => $tomcat,
    mode    => 644,
    require => User[$tomcat]
  }

}

