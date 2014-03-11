
task :environment do
  require File.expand_path(File.join(File.dirname(__FILE__), '..', 'config', 'boot.rb'))
end

namespace :accounts do
  desc 'Check for new votes and delegations'
  task :check => :environment do
    Account.all.each { |account|
      account.check
    }
  end
end