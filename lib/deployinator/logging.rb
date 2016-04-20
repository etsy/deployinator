module Deployinator
  def self.setup_logging
    if Deployinator.log_file?
      $deployinator_log_handle = File.new(Deployinator.log_file, "a")
      def $stdout.write(string)
        $deployinator_log_handle.write string
        super
      end
      $stdout.sync = true
      $stderr.reopen($deployinator_log_handle)
      puts "Logging #{Deployinator.log_file}"
    end

    if Deployinator.log_path?
      $deployinator_log_path = File.new(Deployinator.log_path, "a")
    end

    if Deployinator.timing_log_path?
      $deployinator_timing_log_path = File.new(Deployinator.timing_log_path, "a")
    end

  end
end

Deployinator.setup_logging
