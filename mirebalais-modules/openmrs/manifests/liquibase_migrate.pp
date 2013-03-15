define openmrs::liquibase_migrate(
  $dataset,
  $unless = '',
  $openmrs_db = hiera('openmrs_db'),
  $openmrs_db_user = decrypt(hiera('openmrs_db_user')),
  $openmrs_db_password = decrypt(hiera('openmrs_db_password')),
  $tomcat = hiera('tomcat'),
) {

  file { '/usr/local/liquibase.jar':
    ensure => present,
    source => 'puppet:///modules/openmrs/liquibase.jar'
  }

  exec { $title:
    cwd     =>  '/usr/local/',
    command => "java -Dliquibase.databaseChangeLogTableName=liquibasechangelog -Dliquibase.databaseChangeLogLockTableName=liquibasechangeloglock -jar liquibase.jar --driver=com.mysql.jdbc.Driver --classpath=/usr/local/${tomcat}/webapps/mirebalais.war --url=jdbc:mysql://localhost:3306/${openmrs_db} --changeLogFile=${dataset} --username=${openmrs_db_user} --password=${openmrs_db_password} update",
    user    => 'root',
    unless  => $unless,
  }
}