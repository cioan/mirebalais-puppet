class mirebalais {

  file { '/etc/environment' :
		source => "puppet:///modules/mirebalais/ect/environment" ,
  }  



}

