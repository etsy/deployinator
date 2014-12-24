
require 'rake/testtask'
require 'rdoc/task'
require 'bundler/gem_tasks'

#
# Helpers
#

def command?(command)
  system("type #{command} &> /dev/null")
end

task :default => 'deploytest:unit'

#
# Tests
#

namespace :deploytest do

  desc 'Run deployinator unit tests'
  Rake::TestTask.new :unit do |t|
    t.libs << 'lib'
    t.pattern = 'test/unit/**/*_test.rb'
    t.verbose = false
  end

  desc 'Run deployinator functional tests'
  Rake::TestTask.new :functional do |t|
    t.libs << 'lib'
    t.pattern = 'test/functional/**/*_test.rb'
    t.verbose = false
  end

end
