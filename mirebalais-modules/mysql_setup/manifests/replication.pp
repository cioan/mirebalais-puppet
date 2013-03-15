class mysql_setup::replication(
  $replication_user = decrypt(hiera('replication_db_user')),
  $replication_password = decrypt(hiera('replication_db_password')),
) {

  database_user { "${replication_user}@%":
    ensure        => present,
    password_hash => mysql_password($replication_password),
    require       => Service['mysqld'],
  } ->

  database_grant { "${replication_user}@%":
    privileges => [Repl_slave_priv],
    require    => Service['mysqld'],
  }
}
