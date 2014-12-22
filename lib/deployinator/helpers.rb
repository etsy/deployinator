require 'benchmark'
require 'timeout'
require 'deployinator/helpers/version'
require 'deployinator/helpers/plugin'

module Deployinator
  module Helpers
    include Deployinator::Helpers::VersionHelpers,
      Deployinator::Helpers::PluginHelpers

    RUN_LOG_PATH = "run_logs/"

    def dev_context?
      Deployinator.app_context['context'] == 'dev'
    end

    def not_dev?
      Deployinator.app_context['context'] != 'dev'
    end

    def run_log_path
      RUN_LOG_PATH
    end

    def init(env)
    end

    def write_file(str, file)
      File.open("#{RUN_LOG_PATH}#{file}", "a:UTF-8") do |f|
        f.print str.force_encoding("UTF-8")
      end
    end

    # Creates a current-stackname symlink for each deploy for easier tailing
    #
    # filename - String of the current run log filename
    # stack - String containing the stack for this deploy
    def link_stack_logfile(filename, stack)
      run_cmd %Q{ln -nfs #{Deployinator.app_context['install_path']}/#{run_log_path}#{filename} #{Deployinator.app_context['install_path']}/#{run_log_path}current-#{stack}}
    end

    # Moves current-stackname symlink so tailer won't accidentally pick up on last push
    # race condition
    #
    # stack - String containing the stack for this deploy
    def move_stack_logfile(stack)
      run_cmd %Q{mv #{Deployinator.app_context['install_path']}/#{run_log_path}current-#{stack} #{Deployinator.app_context['install_path']}/#{run_log_path}last-#{stack}}
    end

    # output to a file, and the streaming output handler
    # Public: helper function to write a message to the logfile and have it
    # streamed in the webfrontend also. The frontend is HTML markuped so you
    # can use HTML in the log message and it will be rendered with the given
    # CSS of the site. Some classes can be used per default in Deployinator to
    # show the output also in an error or info notification box. These are then
    # displayed in a box above the logging output.
    #
    # output - String to be logged and shown in the output
    #
    # Examples:
    #   log_and_stream(<div class="stderror"> ERROR! </div>)
    #   log_and_stream(<div class="info_msg"> INFO! </div>)
    #
    # Returns nothing
    def log_and_stream(output)
      write_file output, @filename if @filename
      return @block.call(output) unless @block.nil?
      ""
    end

    # Run external command with timing information
    # streams and logs the output of the command as well
    # If the command fails, it is retried some number of times
    # This defaults to 5, but can be specified with the num_retries parameter
    # If all the retries fail, an exception is thrown
    # Between retries it will sleep for a given period, defaulting to 2 seconds
    def run_cmd_with_retries(cmd, num_retries=5, sleep_seconds=2, timing_metric=nil)
      for i in 1..num_retries
        if i == num_retries then
          result = run_cmd(cmd, timing_metric)
        else
          result = run_cmd(cmd, timing_metric, false)
        end
        if result[:exit_code] == 0
          return result
        else
          retries_remaining = num_retries - i
          unless i == num_retries
            log_and_stream("`#{cmd}` failed, will retry #{retries_remaining} more times<br>")
            sleep sleep_seconds
          end
        end
      end

      raise "Unable to execute `#{cmd}` after retrying #{num_retries} times"
    end

    # Run external command with timing information
    # streams and logs the output of the command as well
    # does not (currently) check exit status codes
    def run_cmd(cmd, timing_metric=nil, log_errors=true)
      ret = ""
      exit_code = 0
      start = Time.now.to_i
      timestamp = Time.now.to_s
      plugin_state = {
        :cmd => cmd,
        :timing_metric => timing_metric,
        :start_time => start,
        :log_errors => log_errors
      }
      raise_event(:run_command_start, plugin_state)
      log_and_stream "<div class='command'><h4>#{timestamp}: Running #{cmd}</h4>\n<p class='output'>"
      time = Benchmark.measure do
        Open3.popen3(cmd) do |inn, out, err, wait_thr|
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
          error_message = nil
          log_and_stream(output) unless output.empty?

          error_message = err.read unless err.eof?
          if (log_errors) then
            log_and_stream("<span class='stderr'>STDERR: #{error_message}</span><br>") unless error_message.nil?
          else
            log_and_stream("STDERR:" + error_message + "<br>") unless error_message.nil?
          end

          unless error_message.nil? then
            plugin_state[:error_message] = error_message
            plugin_state[:log_errors] = error_message
            raise_event(:run_command_error, plugin_state)
          end

          # Log non-zero exits
          if wait_thr.value.exitstatus != 0 then
            log_and_stream("<span class='stderr'>DANGER! #{cmd} had an exit value of: #{wait_thr.value.exitstatus}</span><br>")
            exit_code = wait_thr.value.exitstatus
          end
        end
      end
      log_and_stream "</p>"
      log_and_stream "<h5>Time: #{time}</h5></div>"
      plugin_state[:exit_code] = exit_code
      plugin_state[:stdout] = ret
      plugin_state[:time] = time.real 
      raise_event(:run_command_end, plugin_state)
      return { :stdout => ret, :exit_code => exit_code }
    end

    def nicify_env(env)
      env = "production" if env == "PROD"
      env.downcase
    end

    def http_host
      @host
    end

    def stack
      @stack
    end

    %w[dev qa stage princess production].each do |env|
      define_method "#{env}_version" do
        version = self.send("#{stack}_#{env}_version")
        if @disabled_override == true
          @disabled = false
        else
          @disabled = !version || version.empty?
        end
        version
      end

      define_method "#{env}_build" do
        get_build(self.send("#{env}_version"))
      end
    end

    def diff(r1, r2, stack="web", time=null)
      if (!time)
        time = Time.now.to_i
      end
      redirect "/diff/#{stack}/#{r1}/#{r2}/github?time=#{time}"
      return
    end

    def send_email(options)
      Pony.mail(options)
    end

    def get_log
      log_entries.collect do |line|
        "[" + line.split("|").join("] [") + "]"
      end.join("<br>")
    end

    # Public: log a given message to the log_path file. The method calls
    # log_string_to_file for lower level logging functionality.
    #
    # env   - String which represents the environment the log was produced in
    # who   - String which represents the active user
    # msg   - String representing the actual log message
    # stack - String representing the current deploy stack
    #
    # Returns the return code of log_string_to_file
    def log(env, who, msg, stack)
      s = stack
      log_string_to_file("#{now}|#{env}|#{clean(who)}|#{clean(msg)}|#{s}|#{@filename}", Deployinator.log_path)
    end

    # Public: wrapper method around appending stdout to a logfile.
    #
    # string - String representing the log message
    # path   - String representing the path to the logfile
    #
    # Returns true if echo exited with 0, false for non-zero exit and nil if
    # the call fails
    def log_string_to_file(string, path)
      cmd = %Q{echo  "#{string}" >> #{path}}
      system(cmd)
    end

    def clean(msg)
      (msg || "").gsub("|", "/").gsub('"', "&quot;").gsub("'", "&apos;")
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

    def environments
      custom_env = "#{stack}_environments"
      envs = send(custom_env) if respond_to?(custom_env.to_sym)
      envs ||=
      [{
        :name            => "production",
        :title           => "Deploy #{stack} production",
        :method          => "production",
        :current_version => proc{send(:"#{stack}_production_version")},
        :current_build   => proc{get_build(send(:"#{stack}_production_version"))},
        :next_build      => proc{send(:head_build)}
      }]

      envs.each_with_index { |env, i| env[:number] = "%02d." % (i + 1); env[:not_last] = (i < envs.size - 1) }
    end


    # Public: fetch the run_logs in 'run_logs/' based on sevaral parameters
    #
    # Parameters:
    #   opts
    #           :offset
    #           :limit
    #           :filename - <stack>-<method>
    #
    # Returns an array of hashes with name and time keys
    def get_run_logs(opts={})
      offset = opts[:offset] || 0
      limit = opts[:limit] || -1
      filename = opts[:filename] || ""
      glob = Deployinator::Helpers::RUN_LOG_PATH + "*.html"
      files = Dir.glob(glob)

      # filter for config files
      files.select! {|file| file.match(/^((?!web[-_]config_diff.html).)*$/) && file.match(/html/)}

      # filter for princess or production run_logs
      files.select! {|file| file.match(/#{filename}/)}

      # map files to hash with name and time keys
      files.map! do |file|
        { :name => File.basename(file), :time => Time.at(file[/(\d{8,})/].to_i) }
      end

      # sort files chronologically,
      files.sort_by! {|file| file[:time]}.reverse!

      # select files within an index range
      files[offset...offset +limit]

    end

    # Public: strips all of the whitespace from a string. If the string only whitespace, return nil.
    #
    # s - the string to strip whitespace from
    #
    # Example
    #   if strip_ws_to_nil(hostname).nil?
    #     puts "blank hostname is not valid!"
    #   end
    #
    # Returns A whitespace-free string or nil.
    def strip_ws_to_nil(s)
      if s.nil?
        nil
      else
        s = s.gsub(/\s+/, "")
        if s == ''
          nil
        else
          s
        end
      end
    end

    # Public: gets the contes from a cache file if it hasn't expired
    #
    # Paramaters:
    #    cache_file: path to a cache file
    #    cache_ttl : how long in seconds the cached content is good for
    #    A negative number will indicate you don't care how old the cache
    #    file is.
    #
    # Returns: cached content or false if expired or cache file doesn't exist.
    def get_from_cache(cache_file, cache_ttl=5)
      if File.exists?(cache_file)
        now = Time.now
        file_mtime = File.mtime(cache_file)
        file_age = now - file_mtime
        if ((cache_ttl < 0) || (file_age <= cache_ttl))
          file = File.open(cache_file, "r:UTF-8")
          return file.read
        else
          # Return False if the cache is old
          return false
        end
      else
        # Return False if the cache file doesn't exist
        return false
      end
    end

    def lock_pushes(stack, who, method)
      log_and_stream("LOCKING #{stack}")
      if lock_info = push_lock_info(stack)
        return log_and_stream("Pushes locked by #{lock_info[:who]} - #{lock_info[:method]}")
      end

      dt = Time.now.strftime("%m/%d/%Y %H:%M")
      log_string_to_file("#{who}|#{method}|#{dt}", push_lock_path(stack))
    end

    def unlock_pushes(stack)
      system(%Q{rm #{push_lock_path(stack)}})
    end

    def push_lock_info(stack)
      d = `test -f #{push_lock_path(stack)} && cat #{push_lock_path(stack)}`.chomp
      d.empty? ? nil : Hash[*[:who, :method, :lock_time].zip(d.split("|")).flatten]
    end

    def pushes_locked?(stack)
        push_lock_info(stack)
    end

    def push_lock_path(stack)
      "#{Deployinator.app_context['data_path']}/#{stack}-push-lock"
    end

    # Public: Outputs stack data for use in templating
    # the stack selection box in the header.
    #
    # Returns an array of hashes with the fields "stack" and "current"
    # where "current" is true for the currently selected stack.
    def get_stack_select
      stacks = Deployinator.get_stacks
      output = Array.new
      stacks.each do |s|
        current = stack == s
        output << { "stack" => s, "current" => current }
      end
      output
    end

    # Public: Gets the value of app_context config flag 'pinned_stacks'
    #
    # Returns an array of stack names, an empty array, or nil if not set in config.
    def pinned_stacks
      Deployinator.app_context['pinned_stacks']
    end

    # Public: given a run logs filename, return a full URL to the runlg
    #
    # Params:
    #   filename - string of the filename
    #
    # Returns a string URL where that runlog can be viewed
    def run_log_url(filename)
      "http://#{Deployinator.hostname}/run_logs/view/#{filename}"
    end

    # Public: wrap a block into a timeout
    #
    # seconds     - timeout in seconds
    # description - optional description for logging (default:"")
    # &block      - block to call
    #
    # Example
    #   with_timeout(20){system("curl -s http://google.com")}
    #   with_timeout 30 do; system("curl -s http://google.com"); end
    #
    # Returns nothing
    def with_timeout(seconds, description=nil,  &block)
      begin
        Timeout.timeout(seconds) do
          yield
        end
      rescue Timeout::Error => e
        info = "#{Time.now}: Timeout: #{e}"
        info += " for #{description}" unless description.nil?
        # log and stream if log filename is not undefined
        if (/undefined/ =~ @filename).nil?
          log_and_stream "<div class=\"stderr\">#{info}</div>"
        end
        state = {
          :seconds => seconds,
          :info => info
        }
        raise_event(:timeout, state)
        ""
      end
    end

    def can_remove_stack_lock?
      unless @groups.nil? then
        Deployinator.admin_groups.each { |cg| return true if @groups.include?(cg) }
      end

      # get the lock info to see if the user is the locker
      info = push_lock_info(@stack) || {}
      return true if info.empty?
      if info[:who] == @username
        return true
      end

      return false
    end

    def announce(announcement, options = {})
      raise_event(:announce, {:announcement => announcement, :options => options})

      if options[:send_email] && options[:send_email] == true
        stack = options[:stack]

        send_email({
          :subject => "#{stack} deployed #{options[:env]} by #{@username}",
          :html_body => announcement
        })
      end
    end

    def diff_url(stack, old_build, new_build)
      raise_event(:diff, {:stack => stack, :old_build => old_build, :new_build => new_build})
    end

    def log_and_shout(options={})
      options[:stack] ||= @stack

      raise "Must have stack" unless options[:stack]

      options[:env] ||= "PROD"
      options[:nice_env] = nicify_env(options[:env])
      options[:user] ||= @username
      options[:start] = @start_time unless options[:start] || ! @start_time

      if (options[:start])
        options[:end] = Time.now unless options.key?(:end)
        options[:duration] = options[:end] - options[:start]

        log_and_stream "Ended at #{options[:end]}<br>Took: #{options[:duration]} seconds<br>"
        # TODO: fix this, move over timing log and add plugin raise for graphite
        # timing_log options[:duration], options[:nice_env], options[:stack]
      end

      if (options[:old_build] && options[:build])
        log_str = "#{options[:stack]} #{options[:nice_env]} deploy: old #{options[:old_build]}, new: #{options[:build]}"
        log options[:env], options[:user], log_str, options[:stack]
        d_url = diff_url(options[:stack], options[:old_build], options[:build])
      end

      if (options[:old_build] && options[:build] && (options[:irc_channels] || options[:send_email]))
        announcement = "#{options[:stack]} #{options[:env]} deployed by #{options[:user]}"
        announcement << " build: #{options[:build]} took: #{options[:duration]} seconds "
        announcement << "diff: #{d_url}" if d_url
        announce announcement, options
      end
    end

    def timing_log(duration, type, stack, timestamp=nil)
      if (timestamp == nil) then
        timestamp = Time.now.to_i
      end

      current = now()
      log_string_to_file("#{current}|#{type}|#{stack}|#{duration}", Deployinator.timing_log_path)
      raise_event(:timing_log, {:duration => duration, :current => current, :type => type, :timestamp => timestamp})
    end

    def average_duration(type, stack)
      log = `grep "#{type}|#{stack}" #{Deployinator.timing_log_path} | tac | head -5`
      timings = log.split("\n").collect { |line| line.split("|").last.to_f }
      avg_time = (timings.empty?) ? 30 : timings.inject(0) {|a,v| a+v} / timings.size
      puts "avg time for #{stack}/#{type}: #{avg_time}"
      avg_time
    end

    def log_entries(options = {})
      stacks = []
      stacks << "LOG MESSAGE" unless (options[:no_limit] || options[:no_global])

      stacks << options[:stack] if options[:stack]

      env = options[:env] ? "\\|#{options[:env].upcase}\\|" : ""
      limit = (options[:no_limit] && options[:no_limit] == true) ? nil : (options[:limit] || 40)

      # stack should be the last part of the log line from the last pipe to the end
      # modified this to take into account the run_log entry at the end
      unless stacks.empty? && env.empty?
        grep = "| egrep '#{env}.*\\|\(#{stacks.join("|")}\)(|(\\||$))?'"
      end

      # extra grep does another filter to the line, needed to get CONFIG PRODUCTION
      if defined? options[:extragrep]
        extragrep = "| egrep -i '#{options[:extragrep]}' "
      end

      if options[:page]
        num_per_page = 40
        limit = "| head -#{num_per_page * options[:page].to_i} | tail -#{num_per_page}"
      else
        limit = "| head -#{limit}" if limit
      end

      log = `tac #{Deployinator.log_path} #{grep} #{extragrep} #{limit}`
      log.split("\n")
    end
  end
end
