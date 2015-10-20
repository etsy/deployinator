require 'sinatra/base'
require 'mustache/sinatra'
require 'deployinator'
require 'deployinator/controller'
require 'deployinator/helpers'
require 'deployinator/helpers/deploy'
require 'deployinator/helpers/version'
require 'deployinator/helpers/git'
require 'deployinator/helpers/plugin'
require 'deployinator/views/index'
require 'deployinator/views/log'
require 'deployinator/views/run_logs'
require 'deployinator/views/log_table'
require 'deployinator/views/deploys_status'
require 'deployinator/views/stats'

module Deployinator
  class DeployinatorApp < Sinatra::Base
    register Mustache::Sinatra
    helpers Deployinator::Helpers,
      Deployinator::Helpers::DeployHelpers,
      Deployinator::Helpers::GitHelpers,
      Deployinator::Helpers::VersionHelpers,
      Deployinator::Helpers::PluginHelpers

    def github_diff_url(params)
      stack = params[:stack].intern
      gh_info = git_info_for_stack[stack]
      "https://#{which_github_host(stack)}/#{gh_info[:user]}/#{gh_info[:repository]}/compare/#{params[:r1]}...#{params[:r2]}"
    end

    set :mustache, {
      :views     => Deployinator.root('views'),
      :templates => Deployinator.root('templates'),
      :namespace => Deployinator::Views
    }

    set :public_folder, Deployinator.root('public')
    set :static, true

    before do
      register_plugins(nil)
      init(env)
      @disabled_override = params[:override].nil? ? false : true
    end

    get '/' do
        mustache Deployinator::Views::Index
    end

    get '/stats' do
        mustache Deployinator::Views::Stats
    end

    get '/run_logs/view/:log' do
      template = open("#{File.dirname(__FILE__)}/templates/stream.mustache").read
      template.gsub!("{{ yield }}", "{{{yield}}}")
      Mustache.render(template, :yield => open("run_logs/" + params[:log]).read)
    end

    get '/run_logs/?' do
      @stack = "log"
      @params = params
      mustache Deployinator::Views::RunLogs
    end

    get '/run_logs/latest/:log_type' do
      run_logs = get_run_logs(:limit => 1, :type => params[:log_type])
      if run_logs.count == 1
        run_log = run_logs.first[:name]
        redirect "/run_logs/view/#{run_log}"
      else
        redirect "/"
      end
    end

    get '/log/?' do
      @stack = "log"
      @params = params
      mustache Deployinator::Views::LogTable
    end

    get '/:stack/can-deploy' do
      lock_info = push_lock_info(params["stack"]) || {}
      lock_info[:can_deploy] = lock_info.empty?
      content_type "application/json"
      lock_info.to_json
    end

    get '/diff/:stack/:r1/:r2/?' do
      @stack = params[:stack]
      diff(params["r1"], params["r2"], params["stack"], params[:time])
    end

    get '/diff/:stack/:r1/:r2/github/?' do
      redirect github_diff_url(params)
    end

    get '/head_rev/:stack' do
      git_head_rev(params[:stack]).chomp
    end

    get '/:stack/remove-lock' do
      stack = params[:stack]
      unlock_pushes(stack) if can_remove_stack_lock?
      redirect "/#{stack}"
    end

    # return a list of all deploys as JSON
    get '/deploys/?' do
      get_list_of_deploys.to_json
    end

    get '/static/css/style.css?:version' do
      send_file "#{File.dirname(__FILE__)}/static/css/style.css"
    end

    get '/static/css/diff_style.css' do
      send_file "#{File.dirname(__FILE__)}/static/css/diff_style.css"
    end

    get '/static/css/highlight.css' do
      send_file "#{File.dirname(__FILE__)}/static/css/highlight.css"
    end

    get '/js/flot/jquery.flot.min.js' do
      send_file "#{File.dirname(__FILE__)}/static/js/flot/jquery.flot.min.js"
    end

    get '/js/flot/jquery.flot.selection.js' do
      send_file "#{File.dirname(__FILE__)}/static/js/flot/jquery.flot.selection.js"
    end

    get '/js/jquery-1.8.3.min.js' do
      send_file "#{File.dirname(__FILE__)}/static/js/jquery-1.8.3.min.js"
    end

    get '/js/jquery-ui-1.8.24.min.js' do
      send_file "#{File.dirname(__FILE__)}/static/js/jquery-ui-1.8.24.min.js"
    end

    get '/js/jquery.timed_bar.js' do
      send_file "#{File.dirname(__FILE__)}/static/js/jquery.timed_bar.js"
    end

    get '/js/stats_load.js' do
      send_file "#{File.dirname(__FILE__)}/static/js/stats_load.js"
    end

    get '/deploys_status' do
        mustache Deployinator::Views::DeploysStatus
    end

    get '/log.txt' do
      content_type :text
      `tac #{Deployinator.log_path}#{ " | head -n #{params[:limit]}" if params[:limit]}`
    end

    get '/timing_log.txt' do
      content_type :text
      `tac #{Deployinator.timing_log_path}`
    end

    get '/ti/:stack/:env' do
      @stack = params[:stack]
      average_duration(params["env"], params["stack"]).to_s
    end

    # this is the API endpoint to asynchronously start a deploy that runs in
    # the background.
    post '/deploys/?' do
      params[:username] = @username
      params[:groups] = @groups
      params[:block] = Proc.new { |line| foo = line }
      deploy_running = is_deploy_active?(params[:stack], params[:stage])

      # if this deploy is already running, return 403
      if deploy_running
        return 403
      end

      pid = fork {
        Signal.trap("HUP") { exit }
        Deployinator.setup_logging
        $0 = get_deploy_process_title(params[:stack], params[:stage])
        controller = Deployinator.deploy_controller || Deployinator::Controller
        d = controller.new
        d.run(params)
      }
      Process.detach(pid)
      200
    end

    delete '/deploys/?' do
      return 400 if (params[:stack].nil? || params[:stage].nil?)
      res = stop_deploy(params[:stack], params[:stage])
      unless res
        return 404
      end

      200
    end

    get '/:thing' do
      @stack = params[:thing]

      unless Deployinator.get_stacks.include?(@stack)
        raise "No such stack #{@stack}"
      end

      @params = params
      register_plugins(@stack)
      begin
        mustache @stack
      rescue Errno::ENOENT
        pass
      end
    end
  end
end
