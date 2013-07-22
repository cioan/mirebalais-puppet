namespace :bootstrap do
  desc 'Bootstraps with Puppet and other basic tools'
  task :default do
    run('apt-get update')
    run('apt-get install git')
    run('cd /etc && git clone https://github.com/PIH/mirebalais-puppet puppet')
    run("cd /etc/puppet && ./install.sh #{:role}")
  end
end
