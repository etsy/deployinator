require 'deployinator'
require 'deployinator/helpers'
require 'deployinator/helpers/dsh'
require 'test/unit'
require 'mocha/setup'

include Deployinator
include Deployinator::Helpers
include Deployinator::Helpers::DshHelpers

#
# Set of tests for methods in our DshHelpers Module
#
class DshHelperTest < Test::Unit::TestCase

  def test_hosts_for_ignores_comments
    DshHelpers.expects(:`).returns("host1\n#host2\nhost3")
    assert_equal(["host1","host3"], DshHelpers.hosts_for("foo"))
  end

  def test_hosts_for_ignores_comments_whitespace_before
    DshHelpers.expects(:`).returns("host1\n   #host2\nhost3")
    assert_equal(["host1","host3"], DshHelpers.hosts_for("hoo"))
  end

  def test_hosts_for
    DshHelpers.expects(:`).returns("host1\nhost2\nhost3")
    assert_equal(["host1","host2","host3"], DshHelpers.hosts_for("bar"))
  end

  def test_host_for_raises_when_nil
    DshHelpers.expects(:`).returns("")
    # $? is the return value of the previous backtick command
    # we are mocking it
    $?.expects(:exitstatus).returns(1)
    assert_raises(RuntimeError) do
      DshHelpers.hosts_for("baz")
    end
  end
end
