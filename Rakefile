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

task :character => 'deployinator:test:character'

load 'deployinator/tasks/tests.rake'
