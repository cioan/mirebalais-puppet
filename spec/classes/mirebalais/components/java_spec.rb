require 'spec_helper'

describe 'mirebalais::components::java' do
  let (:facts) do
    {
      'lsbdistcodename' => 'precise',
      'operatingsystem' => 'Ubuntu',
      'osfamily'        => 'Debian'
    }
  end

  it 'should install java6' do
    should contain_package('oracle-java6-installer').with_ensure('installed')
  end
end
