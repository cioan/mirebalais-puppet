class ntpdate {
  file { '/etc/ntp.conf':
    source => 'puppet:///modules/ntpdate/etc/ntp.conf'
  }

  exec { 'update time':
    command     => 'ntpdate-debian',
    subscribe   => File['/etc/ntp.conf'],
    refreshonly => true
  }
}
