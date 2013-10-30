module Deployinator
  # = Sinatra application
  class App < Sinatra::Base
    register Mustache::Sinatra
    helpers Deployinator::Helpers

    set :mustache, {
      :views     => 'views/',
      :templates => 'templates/',
      :namespace => Deployinator
    }

    set :public_folder, "public/"
    set :static, true

    before do
      init(env)
    end

    get '/' do
      if Deployinator.default_stack 
        @stack = Deployinator::default_stack
      else 
        @stack = "demo"
      end
      mustache @stack
    end

    get '/log.txt' do
      content_type :text
      `#{log_host} "#{tac} #{log_path}#{ " | head -n #{params[:limit]}" if params[:limit]}"`
    end

    get '/timing_log.txt' do
      content_type :text
      `#{log_host} "#{tac} #{timing_log_path}"`
    end

    get '/run_logs/view/:log' do
      template = open(settings.mustache[:templates] + "stream.mustache").read
      template.gsub!("{{ yield }}", "{{{yield}}}")
      Mustache.render(template, :yield => open("run_logs/" + params[:log]).read)
    end

    get '/run_logs/?' do
      mustache :run_logs
    end

    get %r{/(\w+)/(versions|builds)} do |stack, type|
      type = type.gsub(/s$/, '')
      @stack = stack
      content_type :json
      inst = mustache_class(@stack, settings.mustache).new

      if (@stack == 'translations')
        return
      end

      meth = "#{@stack}_%s_#{type}"
      inst.push_order.collect {|env| [env, inst.send(meth % env)]}.to_json
    end

    get '/last_pushes' do
      @stack = params[:stack] || "web"
      @dep_env = params[:env] || "production"
      @limit = (params[:limit] || 2).to_i
      mustache :last_pushes, :layout => false
    end

    post '/message' do
      log('GLOBAL', @username, params[:message], 'GLOBAL')
      announce "#{@username} says: #{params[:message]}", {:irc_channels => "#push"}
      redirect '/'
    end

    get '/log/?' do
      @stack = "log"
      @params = params
      mustache :log_table
    end

    get '/config/?' do
      redirect '/config/web'
    end

    get '/config/web/?' do
      @stack = "web"
      headers['Cache-Control'] = 'nocache, no-store'
      mustache :file_config
    end

    get '/config/web/commit' do
      @stack = "web"
      headers['Cache-Control'] = 'nocache, no-store'
      mustache :file_config_commit
    end

    get '/translate/?' do
      redirect '/translate/translations'
    end

    get '/translate/translations' do
      @stack ="translations"
      headers['Cache-Control'] = 'nocache, no-store'
      mustache :file_translate
    end

    post '/dispatch' do
      env['method'] = params[:method]
      env['arguments'] = params.merge(:username => @username)
      ""
    end

    get '/ti/:stack/:env' do
      @stack = params[:stack]
      average_duration(params["env"], params["stack"]).to_s
    end

    def version_for_and_before(stack, env)
      inst = mustache_class(stack, settings.mustache).new
      current = inst.send(env == "production" ? "build" : env + "_build")
      order = inst.push_order
      if (pos = order.index(env)) > 0
        last_one = inst.send(order[pos-1] + "_build")
      else
        last_one = inst.head_build
      end
      [current.to_i, last_one, stack]
    end

    get '/diff/:stack/:env' do
      @stack = params[:stack]
      diff(*version_for_and_before(params["stack"], params["env"]))
    end

    get '/diff/:r1/:r2' do
      diff(params["r1"], params["r2"])
    end

    get '/diff/:stack/:r1/:r2/?' do
      @stack = params[:stack]
      diff(params["r1"], params["r2"], params["stack"])
    end

    get '/diff/:stack/:r1/:r2/compare/?' do
      r1 = [params["r1"].to_i, params["r2"].to_i].min + 1
      r2 = [params["r1"].to_i, params["r2"].to_i].max
      stack = params[:stack].to_sym
      @diff = %x{#{deploy_host_cmd} deploy/compare.php #{r1} #{r2} #{diff_paths_for_stack[stack]}}

      mustache :compare
    end

    get '/diff/:stack/:r1/:r2/github/?' do
      stack = params[:stack].to_sym
      if Deployinator::Helpers.respond_to?(stack.to_s + "_git_repo_url")
        repo_url = Deployinator::Helpers.send(stack.to_s + "_git_repo_url")
        if repo_url =~ /^https:\/\//
          parts = repo_url.split("/")
          user = parts[3]
          repo = parts[4].gsub(/\.git$/, "")
        elsif repo_url =~ /git@github/
          parts = repo_url.split("/")
          user_actual = parts[0].split(":")
          user = user_actual[1] 
          repo = parts[1].gsub(/\.git$/, "")
        end

        redirect "#{github_url}#{user}/#{repo}/compare/#{params[:r1]}...#{params[:r2]}"
      else
        gh_info = github_info_for_stack[stack]
        redirect "#{github_url}#{gh_info[:user]}/#{gh_info[:repository]}/compare/#{params[:r1]}...#{params[:r2]}"
      end
    end

    get '/deploys/:stack/:env/:start/:end' do
      deploys = log_to_hash({
        :no_global => true, :env => params[:env],
        :stack => params[:stack], :no_limit => true
      })
      start = params[:start].to_i
      d_end = params[:end].to_i
      ds = deploys.find_all do |d|
        # puts "Start: #{start} / End: #{d_end} / #{d[:time].to_i}"
        d[:time].to_i >= start && d[:time].to_i < d_end
      end
      ds.map! do |d|
        {:who => d[:who], :ver => d[:new], :time => d[:time].to_i, :when => d[:timestamp]}
      end
      ret = ds.to_json
      ret = "#{params[:callback]}(#{ret});" if params[:callback]
      content_type "application/javascript"
      ret
    end

    get '/month_stats_lag' do
      @active_month = params[:month]
      mustache "month_stats_lag", :layout => false
    end

    get '/:thing' do
      @stack = params[:thing]
      begin
        mustache @stack 
      rescue Errno::ENOENT
        pass
      end
    end
  end
end
