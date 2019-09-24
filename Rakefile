require 'rake/testtask'
require 'rdoc/task'
require 'bundler/gem_tasks'

#
# Helpers
#

def command?(command)
  system("type #{command} &> /dev/null")
end

task :default => 'test:unit'

namespace :test do
  task :default => 'deployinator:test:unit'
  task :character => 'deployinator:test:character'
  task :unit => 'deployinator:test:unit'
end

load 'deployinator/tasks/tests.rake'
