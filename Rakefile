require 'puppet-lint'
load 'tasks/whitespace.rake'

task :default => [:simplelint, :validate]

task :simplelint do
  linter = PuppetLint.new
  PuppetLint.configuration.send("disable_documentation")
  Dir['**/*.pp'].each do |pp|
    linter.file = pp
    linter.run
  end
  fail if linter.errors?
end

desc 'Validates the syntax of the puppet manifest files'
task :validate do
  puts `puppet parser validate #{Dir['**/*.pp'].join(' ')}`
  fail unless $?.to_i == 0
end

