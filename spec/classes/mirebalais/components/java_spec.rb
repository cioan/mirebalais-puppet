require 'spec_helper'

describe 'mirebalais::components::java' do
  it { should contain_package('oracle-java6-installer').with_ensure('installed') }
end