if Deployinator.log_file?
  log = File.new(Deployinator.log_file, "a")
  $stdout.reopen(log)
  $stderr.reopen(log)
  puts "Logging #{Deployinator.log_file}"
end
