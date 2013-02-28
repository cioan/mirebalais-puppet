class mirebalais::components::openmrs (
    $openmrs_db = hiera('openmrs_db'),
    $openmrs_db_user = decrypt(hiera('openmrs_db_user')),
    $openmrs_db_password = decrypt(hiera('openmrs_db_password')),
    $tomcat = hiera('tomcat'),
  ){

  file { '/etc/apt/apt.conf.d/99auth':
    ensure  => present,
    owner   => root,
    group   => root,
    content => 'APT::Get::AllowUnauthenticated yes;',
    mode    => '644'
  }

  apt::source { 'mirebalais':
    ensure      => present,
    location    => 'http://bamboo.pih-emr.org/mirebalais-repo',
    release     => 'unstable/',
    repos       => '',
    include_src => false,
  }

  package { 'mirebalais':
    ensure  => latest,
    require => [ Service[$tomcat], Apt::Source['mirebalais'], File['/etc/apt/apt.conf.d/99auth'] ],
  }

  if $environment != 'production_slave' {

    file { '/tmp/liquibase.jar':
      ensure => present,
      source => 'puppet:///modules/mirebalais/liquibase.jar'
    }

    exec { 'migrate base schema':
      cwd     =>  '/tmp/',
      command => "java -Dliquibase.databaseChangeLogTableName=liquibasechangelog -Dliquibase.databaseChangeLogLockTableName=liquibasechangeloglock -jar liquibase.jar --driver=com.mysql.jdbc.Driver --classpath=/usr/local/${tomcat}/webapps/mirebalais.war --url=jdbc:mysql://localhost:3306/${openmrs_db} --changeLogFile=liquibase-schema-only.xml --username=${openmrs_db_user} --password=${openmrs_db_password} update",
      user    => 'root',
      unless  => "mysql -u${openmrs_db_user} -p${openmrs_db_password} ${openmrs_db} -e 'desc patient'",
      require => [ Package['mirebalais'], Database[$openmrs_db] ],
    }

    exec { 'migrate core data':
      cwd         =>  '/tmp/',
      command     => "java -Dliquibase.databaseChangeLogTableName=liquibasechangelog -Dliquibase.databaseChangeLogLockTableName=liquibasechangeloglock -jar liquibase.jar --driver=com.mysql.jdbc.Driver --classpath=/usr/local/${tomcat}/webapps/mirebalais.war --url=jdbc:mysql://localhost:3306/${openmrs_db} --changeLogFile=liquibase-core-data.xml --username=${openmrs_db_user} --password=${openmrs_db_password} update",
      user        => 'root',
      subscribe   => Exec['migrate base schema'],
      refreshonly => true
    }

    exec { 'migrate update to latest':
      cwd         =>  '/tmp/',
      command     => "java -Dliquibase.databaseChangeLogTableName=liquibasechangelog -Dliquibase.databaseChangeLogLockTableName=liquibasechangeloglock -jar liquibase.jar --driver=com.mysql.jdbc.Driver --classpath=/usr/local/${tomcat}/webapps/mirebalais.war --url=jdbc:mysql://localhost:3306/${openmrs_db} --changeLogFile=liquibase-update-to-latest.xml --username=${openmrs_db_user} --password=${openmrs_db_password} update",
      user        => 'root',
      subscribe   => Exec['migrate core data'],
      refreshonly => true
    }

  }

  if $environment != 'production_slave' {
    exec { 'tomcat-start':
      command     => "service ${tomcat} start",
      user        => 'root',
      require     => [ Service['mcservice'], Exec['create mirth user'] ],
      subscribe   => Exec['migrate update to latest'],
      refreshonly => true
    }
  }

  file { "/home/${tomcat}/.OpenMRS":
    ensure  => directory,
    owner   => $tomcat,
    group   => $tomcat,
    mode    => '755',
    require => User[$tomcat]
  }

  file { "/home/${tomcat}/.OpenMRS/mirebalais.properties":
    ensure  => present,
    content => template('mirebalais/OpenMRS/mirebalais.properties.erb'),
    owner   => $tomcat,
    group   => $tomcat,
    mode    => '644',
    require => File["/home/${tomcat}/.OpenMRS"]
  }

  file { "/home/${tomcat}/.OpenMRS/mirebalais-runtime.properties":
    ensure  => present,
    content => template('mirebalais/OpenMRS/mirebalais-runtime.properties.erb'),
    owner   => $tomcat,
    group   => $tomcat,
    mode    => '644',
    require => File["/home/${tomcat}/.OpenMRS"]
  }

}
