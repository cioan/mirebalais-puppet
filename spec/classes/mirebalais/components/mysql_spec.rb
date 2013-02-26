require 'spec_helper'

describe 'mirebalais::components::mysql' do
  context 'environment = production_slave' do
    let (:facts) do
      {
        'lsbdistcodename' => 'precise',
        'operatingsystem' => 'Ubuntu',
        'osfamily'        => 'Debian',
        'environment'     => 'production_slave'
      }
    end

    it 'should setup replication' do
      should contain_exec('master replication setup')
    end
  end
end
