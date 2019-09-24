require 'rake/testtask'
require 'rdoc/task'
require 'bundler/gem_tasks'

#
# Helpers
#

def command?(command)
  system("type #{command} &> /dev/null")
end

namespace :test do
  task :character => 'deployinator:test:character'
  task :unit => 'deployinator:test:unit'
end

load 'deployinator/tasks/tests.rake'
