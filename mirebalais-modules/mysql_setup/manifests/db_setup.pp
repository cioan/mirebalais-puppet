class mysql_setup::db_setup(
  $openmrs_db = hiera('openmrs_db'),
  $openmrs_db_user = decrypt(hiera('openmrs_db_user')),
  $openmrs_db_password = decrypt(hiera('openmrs_db_password')),
  $mirth_db = hiera('mirth_db'),
  $mirth_db_user = decrypt(hiera('mirth_db_user')),
  $mirth_db_password = decrypt(hiera('mirth_db_password')),
) {

  database { $openmrs_db :
    ensure  => present,
    require => Service['mysqld'],
    charset => 'utf8',
  } ->

  database_user { "${openmrs_db_user}@localhost":
    ensure        => present,
    password_hash => mysql_password($openmrs_db_password),
    require       => Service['mysqld'],
  } ->

  database_grant { "${openmrs_db_user}@localhost/${openmrs_db}":
    privileges => ['all'],
    require    => Service['mysqld'],
  } ->

  database_grant { "root@localhost/${openmrs_db}":
    privileges => ['all'],
    require    => Service['mysqld'],
  }

  database { $mirth_db :
    ensure  => present,
    charset => 'utf8',
    require => Service['mysqld'],
  }

  database_user { "${mirth_db_user}@localhost":
    ensure        => present,
    password_hash => mysql_password($mirth_db_password),
    require       => Service['mysqld'],
  } ->

  database_grant { "${mirth_db_user}@localhost/${mirth_db}":
    privileges => ['all'],
    require    => Service['mysqld'],
  } ->

  database_grant { "root@localhost/${mirth_db}":
    privileges => ['all'],
    require    => Service['mysqld'],
  }

  database_grant { "${mirth_db_user}@localhost/${openmrs_db}.pacsintegration_outbound_queue":
    privileges => ['all'],
    require    => [ Service['mysqld'], Database[$openmrs_db] ]
  }
}
