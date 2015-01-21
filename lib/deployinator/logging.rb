module Deployinator
  def setup_logging
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
  end
end

Deployinator.setup_logging
