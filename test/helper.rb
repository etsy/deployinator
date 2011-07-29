ENV['RACK_ENV'] = 'test'

testdir = File.dirname(__FILE__)
$LOAD_PATH.unshift testdir unless $LOAD_PATH.include?(testdir)

maindir = File.dirname(File.dirname(__FILE__))
$LOAD_PATH.unshift maindir unless $LOAD_PATH.include?(maindir)

require 'test/unit'

require 'libraries'

def log_in_as(user)
  ENV['HTTP_X_USERNAME'] = user
  ENV['HTTP_X_GROUPS'] = "foo"
end
