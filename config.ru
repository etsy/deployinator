# encoding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'deployinator/libraries'

if Deployinator.log_file?
  log = File.new(Deployinator.log_file, 'a')
  $stdout.reopen(log)
  $stderr.reopen(log)
  puts "Logging #{Deployinator.log_file}"
end

# Ignore the ssl cert on github:fi
ENV['GIT_SSL_NO_VERIFY'] = 'true'

use Rack::CommonLogger

use Deployinator::Stream
run Deployinator::App.new
