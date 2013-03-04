node default {
  Exec { path => [ "/bin/", "/sbin/" , "/usr/bin/", "/usr/sbin/" ] }
  include mirebalais

  if $environment == 'production' {
    include mirebalais_logging
  }

}
