set :force_whenever, true
require 'redant/deploy'
require 'capistrano/mailer'
ActionMailer::Base.delivery_method = :sendmail # or :sendmail, or whatever
ActionMailer::Base.sendmail_settings =  { :arguments => "-i" }
CapMailer.configure do |config|
  config[:recipient_addresses]  = notify 
  config[:sender_address]       = "jago@redant.com.au"
  config[:subject_prepend]      = "[12WBT-CAP-DEPLOY]"
  config[:site_name]            = "12wbt.com"
end

current_release=capture("cat #{current_path}/REVISION").chomp
set :release_notes, release_log(current_release)
#before 'deploy:update_code', 'thinking_sphinx:stop'
after 'deploy:update_code', 'thinking_sphinx:restart'

namespace 'thinking_sphinx' do
  desc "Start the Sphinx daemon"
  task :start do
    rake "thinking_sphinx:configure thinking_sphinx:start"
  end

  desc "Stop the Sphinx daemon"
  task :stop do
    rake "thinking_sphinx:configure thinking_sphinx:stop"
  end

  desc "Stop and then start the Sphinx daemon"
  task :restart do
    rake "thinking_sphinx:configure thinking_sphinx:stop thinking_sphinx:start"
  end
  def rake(*tasks)
    rails_env = fetch(:rails_env, "production")
    rake = fetch(:rake, "rake")
    tasks.each do |t|
      run "if [ -d #{release_path} ]; then cd #{release_path}; else cd #{current_path}; fi; if [ -f Rakefile ]; then #{rake} RAILS_ENV=#{rails_env} #{t}; fi;", :roles => :cron
    end
  end
end

case stage
when "production"
  roles.clear
  role :cron, "martingale.anchor.net.au"
  role :db, "martingale.anchor.net.au", "lazaret.anchor.net.au"
  role :app, "squid980.anchor.net.au", "squid740.anchor.net.au", "squid950.anchor.net.au", "squid970.anchor.net.au", "pitch570.anchor.net.au", "pitch580.anchor.net.au"
  set :use_delayed_job, false
  after "deploy:restart", "deploy:restart_delayed_job"
#  after "deploy", "deploy:notify"
  set :host, "www.12wbt.com"
when "uat"
  roles.clear
  role :cron, "pitch190.anchor.net.au"
  role :db, "pitch190.anchor.net.au"
  role :app, "pitch160.anchor.net.au", "pitch180.anchor.net.au"
  set :use_delayed_job, false
  after "deploy:restart", "deploy:restart_delayed_job"
#  after "deploy", "deploy:notify"
  set :host, "uat.12wbt.com"
when "bert"
  set :use_delayed_job, false
when "ernie"
  set :use_delayed_job, false
end
if stage!='uat' && stage != 'production' && :task_name =="deploy" then
repo=repo_prompt("12wbt").split
set :repository, repo[0]
set :branch, repo[1]
set :deploy_via, :export 
end
namespace :deploy do
  desc "Send email notification of deployment (only send variables you want to be in the email)"
  task :notify, :roles => :cron, :once => true do
    puts "send"
    show.me
    mailer.send_notification_email(self)
    puts "sent"
  end
  
  task :restart_delayed_job do
    run "sudo god restart dj_#{application}", :roles => :db
  end
  desc "set up crontab"
  task :run_whenever do
    run "cd #{fetch :release_path} && #{fetch :whenever_command} --update-crontab #{fetch :whenever_identifier} --set environment=#{rails_env}", :roles => :cron
  end
  desc "blah blah restart the thing"
  task :restart do
    case stage
    when "production"
      run "touch /home/deploy/apps/12wbt/current/public/heartbeat;sleep 45;sudo god restart #{application}_#{app_server};sleep 90;rm -f /home/deploy/apps/12wbt/current/public/heartbeat", :hosts => "squid740.anchor.net.au"
      run "touch /home/deploy/apps/12wbt/current/public/heartbeat;sleep 45;sudo god restart #{application}_#{app_server};sleep 90;rm -f /home/deploy/apps/12wbt/current/public/heartbeat", :hosts => "squid950.anchor.net.au"
      run "touch /home/deploy/apps/12wbt/current/public/heartbeat;sleep 45;sudo god restart #{application}_#{app_server};sleep 90;rm -f /home/deploy/apps/12wbt/current/public/heartbeat", :hosts => "squid970.anchor.net.au"
      run "touch /home/deploy/apps/12wbt/current/public/heartbeat;sleep 45;sudo god restart #{application}_#{app_server};sleep 90;rm -f /home/deploy/apps/12wbt/current/public/heartbeat", :hosts => "squid980.anchor.net.au"
      run "touch /home/deploy/apps/12wbt/current/public/heartbeat;sleep 45;sudo god restart #{application}_#{app_server};sleep 90;rm -f /home/deploy/apps/12wbt/current/public/heartbeat", :hosts => "pitch570.anchor.net.au"
      run "touch /home/deploy/apps/12wbt/current/public/heartbeat;sleep 45;sudo god restart #{application}_#{app_server};sleep 90;rm -f /home/deploy/apps/12wbt/current/public/heartbeat", :hosts => "pitch580.anchor.net.au"
    when "uat"
      run "touch /home/deploy/apps/uat_12wbt/current/public/heartbeat;sleep 45;sudo god restart #{application}_#{app_server};sleep 90;rm -f /home/deploy/apps/uat_12wbt/current/public/heartbeat", :hosts => "pitch160.anchor.net.au"
      run "touch /home/deploy/apps/uat_12wbt/current/public/heartbeat;sleep 45;sudo god restart #{application}_#{app_server};sleep 90;rm -f /home/deploy/apps/uat_12wbt/current/public/heartbeat", :hosts => "pitch180.anchor.net.au"
    else
      run "sudo god restart #{application}_#{app_server}", :roles => :app
    end

    if use_delayed_job==true then
      run "sudo god restart dj_#{application}", :roles => :app
    end
  end
end

after "deploy:restart", "memcached:clear"
namespace :memcached do
  desc "Flush memcached"
  task :clear do
    run "cd #{deploy_to}/current && nohup script/cache_clear.sh #{stage} > /dev/null 2>&1 &"
  end
end

desc "copy assets from production"
task :transpose_assets do
  run "rsync -lrpt --exclude 'avatars' --exclude '*_photos' --exclude 'weight_trackers' martingale.anchor.net.au:/hadata/shared/system/* #{shared_path}/system", :once => true
end

desc "set up the latest backup from production"
task :transpose do
  db_list = {"dev" => "12wbt_dev", "uat" => "uat_12wbt", "bert" => "bert", "ernie" => "ernie" }
  case stage
  when "production" 
    raise Capistrano::CommandError.new("no")
  when "uat"
    run "~/db_update.sh #{db_list[stage]}", :hosts => "pitch160.anchor.net.au"
  else
    run "~/db_update.sh #{db_list[stage]}", :hosts => "coast140.anchor.net.au"
  end
end

namespace :update do
  task :database do
    local_settings = YAML.load(ERB.new(File.read("config/database.yml")).result)["development"]
    database = capture "ls -t1 ~/db*.sql.gz | head -n1", :hosts => "pitch160.anchor.net.au"
    download database.chomp!,"/tmp/dump.sql.gz", :hosts => "pitch160.anchor.net.au"
    run_locally("mysql -u#{local_settings["username"]} #{"-p#{local_settings["password"]}" if local_settings["password"]} #{local_settings["database"]} -e'drop database #{local_settings["database"]}; create database #{local_settings["database"]}'")
    run_locally("gzip -dc /tmp/dump.sql.gz | mysql -u#{local_settings["username"]} #{"-p#{local_settings["password"]}" if local_settings["password"]} #{local_settings["database"]}")
    run_locally("rm /tmp/dump.sql.gz")
  end
end
