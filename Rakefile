require 'rake/testtask'
require 'rdoc/task'
require 'bundler/gem_tasks'

#
# Helpers
#

def command?(command)
  system("type #{command} &> /dev/null")
end

task :default => 'deployinator:test:unit'

load 'deployinator/tasks/tests.rake'
