namespace :deploy do
  desc 'Deploys the app with puppet'
  task :default do
    run("cd /etc/puppet && git pull")
    run("cd /etc/puppet && bundle")
    run("cd /etc/puppet && librarian-puppet install")
    run("cd /etc/puppet && puppet apply -v -d manifests/site.pp")
  end
end
