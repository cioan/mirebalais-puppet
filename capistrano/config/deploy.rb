namespace :deploy do
  desc 'Deploys the app with puppet'
  task :default do
    run("cd /etc/puppet && #{sudo} git pull")
    run("cd /etc/puppet && #{sudo} bundle")
    run("cd /etc/puppet && #{sudo} librarian-puppet install")
    run("cd /etc/puppet && #{sudo} puppet apply -v -d manifests/site.pp")
  end
end
