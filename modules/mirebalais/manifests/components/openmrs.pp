class mirebalais::components::openmrs (
    $default_db = $mirebalais::mysql_default_db,
    $default_db_user = $mirebalais::mysql_default_db_user,
    $default_db_password = $mirebalais::mysql_default_db_password,
    $tomcat = $mirebalais::tomcat,
  ){

  include apt
  
  apt::source { 'mirebalais':
    location   => 'http://bamboo.pih-emr.org/mirebalais-repo',
    repos      => 'unstable/',
  }

  package { "mirebalais": 
    ensure => installed,
    require => Apt::Source['mirebalais'],
  }

  exec { "tomcat-stop":
    command => "service ${tomcat} stop",
    user    => 'root',
    require => Package['mirebalais'],
  }   

  file { '/tmp/liquibase.jar':
    source => "puppet:///modules/mirebalais/liquibase.jar"
  }

  exec { 'migrate base schema':
    cwd     =>  '/tmp/',
    command => "java -Dliquibase.databaseChangeLogTableName=liquibasechangelog -Dliquibase.databaseChangeLogLockTableName=liquibasechangeloglock -jar liquibase.jar --driver=com.mysql.jdbc.Driver --classpath=/usr/local/${tomcat}/webapps/mirebalais.war --url=jdbc:mysql://localhost:3306/${default_db} --changeLogFile=liquibase-schema-only.xml --username=${default_db_user} --password=${default_db_password} update",
    user    => 'root',
    require => Exec['tomcat-stop'],
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
    command => "service ${tomcat} stop",
    user    => 'root',
    require => Exec['migrate update to latest'],
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