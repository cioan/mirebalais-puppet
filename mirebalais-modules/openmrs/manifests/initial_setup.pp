class openmrs::initial_setup(
  $openmrs_db = hiera('openmrs_db'),
  $openmrs_db_user = decrypt(hiera('openmrs_db_user')),
  $openmrs_db_password = decrypt(hiera('openmrs_db_password')),
  $tomcat = hiera('tomcat'),
) {

  openmrs::liquibase_migrate { 'migrate base schema':
    dataset => 'liquibase-schema-only.xml',
    unless  => "mysql -u${openmrs_db_user} -p${openmrs_db_password} ${openmrs_db} -e 'desc patient'",
    require => [ Package['mirebalais'], Database[$openmrs_db] ],
  }

  openmrs::liquibase_migrate { 'migrate core data':
    dataset     => 'liquibase-core-data.xml',
    subscribe   => Openmrs::Liquibase_migrate['migrate base schema'],
    refreshonly => true
  }

  openmrs::liquibase_migrate { 'migrate update to latest':
    dataset     => 'liquibase-update-to-latest.xml',
    subscribe   => Openmrs::Liquibase_migrate['migrate core data'],
    refreshonly => true,
    notify      => Service[$tomcat]
  }
}
