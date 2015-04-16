# config valid only for Capistrano 3.1

set :initial, ENV['initial'] || 'false'

#rvm version in server
set :rvm_ruby_version, 'ruby-2.1.2'
# set :default_env, { rvm_bin_path: '~/usr/local/rvm/scripts/bin' }


#Application name
set :application, 'ror_cap_test'

# Default value for :scm is :git
set :scm, :git

#Github url for the repo
set :repo_url, 'git@github.com:sansarp/ror_cap_test.git'
#Server user
set :user, "ec2-user"

# Default branch is :master
# ask :branch, proc { `git rev-parse --abbrev-ref HEAD`.chomp }.call

# Log format like colors fonts
set :format, :pretty

# Log level
set :log_level, :debug

# Must be set true for password prompt from git to work
set :pty, true

# Default value for :linked_files is []
set :linked_files, %w{config/database.yml config/application.yml}

# Default value for linked_dirs is []
set :linked_dirs, %w{bin log tmp/pids tmp/cache tmp/sockets vendor/bundle public/system}

# Default value for default_env is {}
# set :default_env, { path: "/opt/ruby/bin:$PATH" }

# Default value for keep_releases is 5
set :keep_releases, 3

#Set cron jobs through whenever gem
#set :whenever_identifier, -> { "#{fetch(:application)}_#{fetch(:stage)}" }


namespace :deploy do

  desc 'Reload application'
  task :reload do
    desc "Reload app after change"
    on roles(:app), in: :sequence, wait: 5 do
      # Your restart mechanism here, for example:
      execute :touch, release_path.join('tmp/restart.txt')
    end
  end

  %w[start stop restart].each do |command|
    desc "#{command} Nginx."
    task command do
      on roles(:app) do
        execute "sudo service nginx #{command}"
      end
    end
  end

  after :publishing, :reload
end

#These are one time tasks for the first deploy
namespace :setup do

  desc "Upload database.yml and application.yml files."
  task :yml do
    on roles(:app) do
      execute "mkdir -p #{shared_path}/config"
      upload! StringIO.new(File.read("config/database.yml")), "#{shared_path}/config/database.yml"
      upload! StringIO.new(File.read("config/application.yml")), "#{shared_path}/config/application.yml"
    end
  end

  desc "drop the database."
  task :db_drop do
    on roles(:app) do
      within "#{release_path}" do
        with rails_env: fetch(:rails_env) do
          execute :rake, "db:drop"
        end
      end
    end
  end

  desc "Create the database."
  task :db_create do
    on roles(:app) do
      within "#{release_path}" do
        with rails_env: fetch(:rails_env) do
          execute :rake, "db:create"
        end
      end
    end
  end

  desc "Seed the database."
  task :db_seed do
    on roles(:app) do
      within "#{release_path}" do
        with rails_env: fetch(:rails_env) do
          execute :rake, "db:seed"
        end
      end
    end
  end

  if fetch(:initial) == "true"
    before 'deploy:migrate', 'setup:db_create'
    after 'deploy:migrate', 'setup:db_seed'
  end

  if fetch(:initial) == 'reinitialize'
    before 'deploy:migrate', 'setup:db_drop'
    before 'deploy:migrate', 'setup:db_create'
    after 'deploy:migrate', 'setup:db_seed'
  end

  before 'deploy:starting', 'setup:yml'

end
