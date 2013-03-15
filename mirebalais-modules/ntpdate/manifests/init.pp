class ntpdate {
  file { '/etc/ntp.conf':
    source => 'puppet:///modules/ntpdate/etc/ntp.conf'
  }
}
