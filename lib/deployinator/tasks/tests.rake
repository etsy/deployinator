#
# Tests
#

namespace :deployinator do
  namespace :test do

    desc 'Run deployinator unit tests'
    Rake::TestTask.new :unit do |t|
      t.libs << 'lib'
      t.pattern = "#{File.dirname(__FILE__)}/../../../test/unit/**/*_test.rb"
      t.verbose = false
    end

    desc 'Run deployinator functional tests'
    Rake::TestTask.new :functional do |t|
      t.libs << 'lib'
      t.pattern = "#{File.dirname(__FILE__)}/../../../test/functional/**/*_test.rb"
      t.verbose = false
    end

    desc 'Run deployinator characterization tests'
    Rake::TestTask.new :character do |t|
      t.libs << 'lib'
      t.pattern = "#{File.dirname(__FILE__)}/../../../test/character/**/*_test.rb"
      t.verbose = false
    end
  end
end
