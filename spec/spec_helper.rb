# -*- encoding : utf-8 -*-
require 'rspec-puppet'

fixture_path = File.expand_path(File.join(File.dirname(__FILE__), 'fixtures'))

RSpec.configure do |conf|
  module_path = File.join(fixture_path, 'modules') + ':' + File.join(fixture_path, 'mirebalais-modules')
  conf.module_path = module_path
  conf.manifest_dir = File.join(fixture_path, 'manifests')
  conf.hiera_config = File.join(fixture_path, 'hiera.yaml')
end

if ENV['PUPPET_DEBUG']
  Puppet::Util::Log.level = :debug
  Puppet::Util::Log.newdestination(:console)
end
