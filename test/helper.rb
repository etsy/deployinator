# encoding: utf-8

ENV['RACK_ENV'] = 'test'

testdir = File.dirname(__FILE__)
$LOAD_PATH.unshift testdir unless $LOAD_PATH.include?(testdir)

maindir = File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift maindir unless $LOAD_PATH.include?(maindir)

require 'test/unit'

require 'deployinator/libraries'

def log_in_as(user)
  ENV['HTTP_X_USERNAME'] = user
  ENV['HTTP_X_GROUPS'] = 'foo'
end
