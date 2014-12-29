#
# Tests
#

namespace :depoyinator do
  namespace :test do

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
end
