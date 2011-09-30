module Deployinator
  module Helpers
    RUN_LOG_PATH = "run_logs/"

    # list of URLs that don't require authorization (can take regular expressions)
    # this should be in a config
    AUTH_FREE_URLS = []
    AUTH_FREE_URLS << %w[/last_pushes /last_chef /favicon.ico /web/versions /api/versions]
    AUTH_FREE_URLS << %w[/log.txt /month_stats_lag /web/lb_status.json]
    AUTH_FREE_URLS << %w[/deploys/\w+/\w+/\d+/\d+]

    OK_PATH_REGEX = %r{^(#{AUTH_FREE_URLS.compact.join("|")})$}

    def run_log_path
      RUN_LOG_PATH
    end

    def set_block(&block)
      @block = block
    end

    def init(env)
      @username = (env["HTTP_X_USERNAME"] || ENV["HTTP_X_USERNAME"]) or raise "Must be logged in"
      @groups   = CGI.unescape(env["HTTP_X_GROUPS"] || ENV["HTTP_X_GROUPS"]).split("|")
      @host     = env["HTTP_HOST"]
      @local    = @host.match(/local|dev/)
      @ny4      = @host.match(/ny4/)
      if @username == "nobody" && ! request.path_info.match(OK_PATH_REGEX)
        raise "Must be logged in"
      end
      @stack = form_hash(env, "stack") unless @stack
      @filename = "#{Time.now.to_i}-#{@username}-#{dep_method(env)}.html"
    end

    def dep_method(env)
      return "undefined" unless form_hash(env, "method")
      "#{@stack}-#{form_hash(env, "method")}"
    end

    def form_hash(env, key)
      fh = env["rack.request.form_hash"]
      fh && fh.key?(key) && fh[key]
    end

    def write_file(str, file)
      File.open("#{RUN_LOG_PATH}#{file}", "a") do |f|
        # escape the script tags so we dont get redirects when looking at logs
        str = str.gsub(%r{(<script>.*?</script>)}) {|script| CGI.escapeHTML(script)}
        f.print str
      end
    end

    # output to a file, and the streaming output handler
    def log_and_stream(output)
      write_file output, @filename if @filename
      @block.call(output)
    end

    # Run external command with timing information
    # streams and logs the output of the command as well
    # does not (currently) check exit status codes
    def run_cmd(cmd)
      ret = ""
      start = Time.now.to_i
      log_and_stream "<div class='command'><h4>Running #{cmd}</h4><p class='output'>"
      time = Benchmark.measure do
        ret_code = Open4.popen4(cmd) do |pid, inn, out, err|
          output = ""
          until out.eof?
            # raise "Timeout" if output.empty? && Time.now.to_i - start > 300
            chr = out.read(1)
            output << chr
            ret << chr
            if chr == "\n" || chr == "\r"
              log_and_stream output + "<br>"
              output = ""
            end
          end
          log_and_stream(output) unless output.empty?
          log_and_stream("<span class='stderr'>STDERR: #{err.read}</span><br>") unless err.eof?
        end
        raise 'process_failed' unless ret_code == 0
      end
      log_and_stream "</p>"
      log_and_stream "<h5>Time: #{time}</h5></div>"
      return ret
    end

    def nicify_env(env)
      env = "production" if env == "PROD"
      env.downcase
    end

    def log_and_shout(options={})
      options[:stack] ||= @stack

      raise "Must have stack" unless options[:stack]

      # newlines in any of these will corrupt the logfile, so strip them out
      newoptions = {}
      options.each do |key, value|
        value.chomp! if value.respond_to?(:"chomp!")
        newoptions[key] = value
      end
      options = newoptions

      options[:env] ||= "PROD"
      options[:nice_env] = nicify_env(options[:env])
      options[:user] ||= @username
      options[:start] = @start_time unless options[:start] || ! @start_time

      if (options[:start])
        options[:end] = Time.now unless options.key?(:end)
        options[:duration] = options[:end] - options[:start]

        log_and_stream "Ended at #{options[:end]}<br>Took: #{options[:duration]} seconds<br>"
        timing_log options[:duration], options[:nice_env], options[:stack]
      end

      if (options[:old_build] && options[:build])
        log_str = "#{options[:stack]} #{options[:nice_env]} deploy: old #{options[:old_build]}, new: #{options[:build]}"
        log options[:env], options[:user], log_str, options[:stack]
        d_url = diff_url(options[:stack], options[:old_build], options[:build])
      end

      if (options[:old_build] && options[:build] && (options[:irc_channels] || options[:send_email]))
        announcement = "#{options[:stack]} #{options[:env]} deployed by #{options[:user]}"
        announcement << " build: #{options[:build]} took: #{options[:duration]} seconds diff: #{d_url}"
        announce announcement, options
      end
    end

    # Actual helper methods

    def diff_url(stack, old_build, new_build)
      "#{Deployinator.protocol}://#{Deployinator.hostname}/diff/#{stack}/#{old_build}/#{new_build}"
    end

    def stack
      @stack
    end

    def deploy_host_cmd
      "sh -c"
    end

    def stack_qa_version(stack, extra="htdocs/", has_x=true)
      stack = stack + "-x" if has_x
      %x{#{deploy_host_cmd} cat #{checkout_root}/#{stack}/#{extra}version.txt}.chomp
    end

    def stack_production_version(stack, extra="htdocs/", has_x=false)
      # has_x is totally unused, but putting it here to have the same signature as stack_qa_version
      puts %Q{#{deploy_host_cmd} cat #{stack}/#{extra}version.txt}
      %x{#{deploy_host_cmd} cat #{stack}/#{extra}version.txt}.chomp
    end

    %w[qa stage princess production].each do |env|
      define_method "#{env}_version" do
        version = self.send("#{stack}_#{env}_version")
        @disabled = !version || version.empty?
        version
      end

      define_method "#{env}_build" do
        Version.get_build(self.send("#{env}_version"))
      end
    end

    def head_build
      meth = "#{stack}_head_build"
      if self.respond_to?(meth)
        self.send(meth)
      else
        if github_info_for_stack.key?(stack)
          %x{git ls-remote #{git_url(stack)} HEAD | cut -c1-7}.chomp
        else
          SVN.version_of(Deployinator.svn_default_repo)
        end
      end
    end

    def use_github(stack, rev1, rev2)
      # Hackery
      return true if self.respond_to?(stack.to_s + "_git_repo_url")
      return false if [rev1, rev2].all? {|r| r.match(/^\d{5}$/)}
      return true if github_info_for_stack.key?(stack)
      return false
    end

    def diff(r1, r2, stack="web")
      if use_github(stack.to_sym, r1, r2)
        redirect "/diff/#{stack}/#{r1}/#{r2}/github"
        return
      end
      @r1 = r1
      @r2 = r2
      @paths = diff_paths_for_stack[stack.to_sym]
      @date1 = SVN.time_of_rev(r1) + 1
      @date2 = SVN.time_of_rev(r2)

      mustache :diff
    end

    def log_entries(options = {})
      stacks = []
      stacks << "GLOBAL" unless (options[:no_limit] || options[:no_global])
      stacks << options[:stack] if options[:stack]
      env = options[:env] ? "\\|#{options[:env].upcase}\\|" : ""
      limit = (options[:no_limit] && options[:no_limit] == true) ? nil : (options[:limit] || 40)

      unless stacks.empty? && env.empty?
        grep = "| egrep '#{env}.*\\|#{stacks.join("|")}'"
      end

      limit = "| head -#{limit}" if limit

      log = `#{log_host} "#{tac} #{log_path} #{grep} #{limit}"`
      log.split("\n")
    end

    def average_duration(type, stack)
      log = `#{log_host} 'grep "#{type}|#{stack}" #{timing_log_path} | #{tac} | head -5'`
      timings = log.split("\n").collect { |line| line.split("|").last.to_f }
      avg_time = (timings.empty?) ? 30 : timings.inject(0) {|a,v| a+v} / timings.size
      puts "avg time for #{stack}/#{type}: #{avg_time}"
      avg_time
    end

    def send_email(options)
      if Pony.options.keys.count == 0 
        log_and_stream "Pony not configuration; not sending mail."
      else 
        Pony.mail(options)
      end 
    end

    def announce(announcement, options = {})
      d_url = diff_url(options[:stack], options[:old_build], options[:build])

      irc_announce(announcement.dup, options[:irc_channels]) if options[:irc_channels]

      if options[:send_email] && options[:send_email] == true
        stack = options[:stack] || "web"

        diff_html = ""

        if (options[:old_build] && options[:build])
          # generate diff with compare.php - TBD
        end

        if diff_html && diff_html.match(/<!-- extra -->/)
          diff_html.gsub!(/<!-- extra -->/, "<pre margin='5px;'>#{announcement}</pre>")
        else
          diff_html = (diff_html || "") + announcement
        end

        send_email({
          :subject => "#{stack} deployed #{options[:env]} by #{@username}",
          :html_body => diff_html
        })
      end

      if Deployinator.new_relic_options
        opts = Deployinator.new_relic_options
        
        new_relic_url = "https://rpm.newrelic.com/deployments.xml"
        raise "Must have New Relic apikey and appid" unless opts[:apikey] && opts[:appid]

        cmd = %Q{curl -s --connect-timeout 10 -H "x-api-key:#{opts[:apikey]}" \
                      -d "deployment[application_id]=#{opts[:appid]}" \
                      -d "deployment[user]=#{@username}" \
                      -d "deployment[description]=#{d_url}" \
                      -d "deployment[revision]=#{options[:env]}: #{options[:build]}" \
                      #{new_relic_url} }
        run_cmd cmd
      end
    end

    def irc_announce(message, channels=[])
      channels = channels.split(",") if channels.is_a?(String)
      message = "message=#{CGI.escape(message)}&channels=#{CGI.escape(channels.join(","))}"
      devbot_url = Deployinator.devbot_url
      cmd = %Q{curl -s --connect-timeout 10 -d "#{message}" #{devbot_url}}
      `#{cmd}`
    end

    def get_log
      log_entries.collect do |line|
        "[" + line.split("|").join("] [") + "]"
      end.join("<br>")
    end

    def log(env, who, msg, stack)
      s = stack
      log_string_to_file("#{now}|#{env}|#{clean(who)}|#{clean(msg)}|#{s}", log_path)
    end

    def timing_log(duration, type, stack)
      log_string_to_file("#{now}|#{type}|#{stack}|#{duration}", timing_log_path)
      %x{echo "deploylong.#{stack}.#{type} #{duration} #{Time.now.to_i}" | nc #{Deployinator.graphite_host} #{Deployinator.graphite_port || 2003}}
    end

    def log_string_to_file(string, path)
      cmd = %Q{#{log_host} 'echo  "#{string}" >> #{path}'}
      system(cmd)
    end

    def clean(msg)
      (msg || "").gsub("|", "/").gsub('"', "&quot;").gsub("'", "&apos;")
    end

    def before_stream(args)
      @start_time = Time.now
      unless args["method"].match(/unlock/)
        # lock_pushes(@username, args["method"])
      end
    end

    def after_stream(args, extra={})
      # for some day... web hooks post deploy
      # urls = SVN.export(SVN::URL + "/devtools/trunk/deploy_hooks.txt")
      # args.merge!(extra)
      # urls.split("\n").each { |url| Net::HTTP.post_form(URI.parse(url), args)

      # unlock_pushes

      if (args["stack"] && args["method"])
        if args["method"].match(/config_push/)
          args["stack"] = "config"
          env = args["method"].match(/prod/) ? "production" : "princess"
        else
          env = args["method"][/(qa|production|princess|prod|webs|stage|config)/i, 1] || "other"
          env = "production" if env.match(/prod|webs/)
        end

        # ping graphite!
        time = args["time"] || Time.now
        %x{echo "deploys.#{args["stack"]}.#{env} 1 #{time.to_i}" | nc #{Deployinator.graphite_host} #{Deployinator.graphite_port || 2003}}
      end
    end

    def nice_time
      "%Y-%m-%d %H:%M:%S"
    end

    def now
      Time.now.gmtime.strftime(nice_time)
    end

    def hyperlink(msg)
      (msg || "").gsub(/([A-Z]{2,10}-[0-9]{2,})/) do |issue|
        issue_url = Deployinator.issue_tracker.call(issue)
        "<a href='#{issue_url}' target='_blank'>#{issue}</a>"
      end
    end

    def mac_os_x?
      `uname -s`.chomp == "Darwin"
    end

    def tac
      mac_os_x? ? "tail -r" : "tac"
    end

    def log_to_hash(opts={})
      times = {}
      last_time = 0
      l = log_entries(opts).map do |ll|
        fields = ll.split("|")
        times[fields[1]] ||= []
        times[fields[1]] << fields[0]
        utc_time = Time.parse(fields[0] + "UTC")
        {
          :timestamp => fields[0],
          :time      => utc_time,
          :time_secs => utc_time.to_i,
          :env       => fields[1],
          :who       => fields[2],
          :msg       => hyperlink(fields[3]),
          :old       => fields[3] && fields[3][/old[\s:]*(\w+)/, 1],
          :new       => fields[3] && fields[3][/new[\s:]*(\w+)/, 1],
          :stack     => fields[4]
        }
      end
      times.each { |e,t| t.shift }
      l.map do |le|
        le[:last_time] = times[le[:env]].shift || 0
        le
      end
    end

    def environments
      custom_env = "#{stack}_environments"
      envs = send(custom_env) if respond_to?(custom_env.to_sym)
      envs ||=
      [{
        :name            => "production",
        :title           => "Deploy #{stack} production",
        :method          => "#{stack}_production",
        :current_version => proc{send(:"#{stack}_production_version")},
        :current_build   => proc{Version.get_build(send(:"#{stack}_production_version"))},
        :next_build      => proc{send(:head_build)}
      }]

      envs.each_with_index { |env, i| env[:number] = "%02d." % (i + 1); env[:not_last] = (i < envs.size - 1) }
    end
  end
end
