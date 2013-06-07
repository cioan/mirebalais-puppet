class ntpdate {
  file { '/etc/ntp.conf':
    source => 'puppet:///modules/ntpdate/etc/ntp.conf'
  }

  file { '/etc/default/rcS':
    source => 'puppet:///modules/ntpdate/etc/rcS_default'
  }

  exec { 'update time':
    command     => 'ntpdate-debian',
    subscribe   => File['/etc/ntp.conf'],
    refreshonly => true
  }
}
