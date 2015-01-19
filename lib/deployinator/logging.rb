if Deployinator.log_file?
  log = File.new(Deployinator.log_file, "a")
  $stdout.sync = true
  $stderr.sync = true
  puts "Logging #{Deployinator.log_file}"
end
