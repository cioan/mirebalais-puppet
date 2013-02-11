class mirebalais::components::openmrs (
    $default_db = $mirebalais::mysql_default_db,
    $default_db_user = $mirebalais::mysql_default_db_user,
    $default_db_password = $mirebalais::mysql_default_db_password,
    $tomcat = $mirebalais::tomcat,
  ){

  include apt

  file { "/etc/apt/apt.conf.d/99auth":
    ensure    => present,
    owner     => root,
    group     => root,
    content   => "APT::Get::AllowUnauthenticated yes;",
    mode      => 644;
  }
  
  apt::source { 'mirebalais':
    ensure      => present,
    location    => 'http://bamboo.pih-emr.org/mirebalais-repo',
    release     => 'unstable/',
    repos       => '',
    include_src => false,
  }

  package { "mirebalais": 
    ensure => installed,
    require => [ Service[$tomcat], Apt::Source['mirebalais'], File['/etc/apt/apt.conf.d/99auth'] ],
  }

  exec { "tomcat-stop":
    command => "service ${tomcat} stop",
    user    => 'root',
    require => Package['mirebalais'],
  }   

  file { '/tmp/liquibase.jar':
    ensure => present,
    source => "puppet:///modules/mirebalais/liquibase.jar"
  }

  exec { 'migrate base schema':
    cwd     =>  '/tmp/',
    command => "java -Dliquibase.databaseChangeLogTableName=liquibasechangelog -Dliquibase.databaseChangeLogLockTableName=liquibasechangeloglock -jar liquibase.jar --driver=com.mysql.jdbc.Driver --classpath=/usr/local/${tomcat}/webapps/mirebalais.war --url=jdbc:mysql://localhost:3306/${default_db} --changeLogFile=liquibase-schema-only.xml --username=${default_db_user} --password=${default_db_password} update",
    user    => 'root',
    require => [ Package['mirebalais'], Database[$default_db], Exec['tomcat-stop'] ],
  }

  exec { 'migrate core data':
    cwd     =>  '/tmp/',
    command => "java -Dliquibase.databaseChangeLogTableName=liquibasechangelog -Dliquibase.databaseChangeLogLockTableName=liquibasechangeloglock -jar liquibase.jar --driver=com.mysql.jdbc.Driver --classpath=/usr/local/${tomcat}/webapps/mirebalais.war --url=jdbc:mysql://localhost:3306/${default_db} --changeLogFile=liquibase-core-data.xml --username=${default_db_user} --password=${default_db_password} update",
    user    => 'root',
    require => Exec['migrate base schema'],
  }

  exec { 'migrate update to latest':
    cwd     =>  '/tmp/',
    command => "java -Dliquibase.databaseChangeLogTableName=liquibasechangelog -Dliquibase.databaseChangeLogLockTableName=liquibasechangeloglock -jar liquibase.jar --driver=com.mysql.jdbc.Driver --classpath=/usr/local/${tomcat}/webapps/mirebalais.war --url=jdbc:mysql://localhost:3306/${default_db} --changeLogFile=liquibase-update-to-latest.xml --username=${default_db_user} --password=${default_db_password} update",
    user    => 'root',
    require => Exec['migrate core data'],
  }

  exec { "tomcat-start":
    command => "service ${tomcat} start",
    user    => 'root',
    require => [ Exec['migrate update to latest'], Service['mcservice'], Exec['create mirth user'] ]
  }   

  file { "/home/${tomcat}/.OpenMRS":
    ensure  => directory,
    owner   => $tomcat,
    group   => $tomcat,
    mode    => 755,
    require => User[$tomcat]
  }

  file { "/home/${tomcat}/.OpenMRS/mirebalais.properties":
    content => template("mirebalais/OpenMRS/mirebalais.properties.erb"),
    ensure  => present,
    owner   => $tomcat,
    group   => $tomcat,
    mode    => 644,
    require => File["/home/${tomcat}/.OpenMRS"]
  } 
  
  file { "/home/${tomcat}/.OpenMRS/mirebalais-runtime.properties":
    content => template("mirebalais/OpenMRS/mirebalais-runtime.properties.erb"),
    ensure  => present,
    owner   => $tomcat,
    group   => $tomcat,
    mode    => 644,
    require => File["/home/${tomcat}/.OpenMRS"]
  }

}
