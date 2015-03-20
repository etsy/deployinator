require 'deployinator'
require 'deployinator/helpers'
require 'deployinator/helpers/git'

include Deployinator::Helpers::GitHelpers

class HelpersTest < Test::Unit::TestCase

  def test_git_url_https
    GitHelpers.expects(:which_github_host).returns("www.testmagic.com")
    GitHelpers.expects(:git_info_for_stack).returns({:stack => {:repository => 'drills', :user => 'construction'}})
    GitHelpers.expects(:git_info_for_stack).returns({:stack => {:repository => 'drills', :user => 'construction'}})
    assert_equal('https://www.testmagic.com/construction/drills.git', GitHelpers.git_url(:stack, 'https', false))
  end

  def test_git_url_default
    GitHelpers.expects(:which_github_host).returns("www.testmagic.com")
    GitHelpers.expects(:git_info_for_stack).returns({:stack => {:repository => 'drills', :user => 'construction'}})
    GitHelpers.expects(:git_info_for_stack).returns({:stack => {:repository => 'drills', :user => 'construction'}})
    assert_equal('git://www.testmagic.com/construction/drills', GitHelpers.git_url(:stack))
  end

  def test_git_url_read_write
    GitHelpers.expects(:which_github_host).returns("www.testmagic.com")
    GitHelpers.expects(:git_info_for_stack).returns({:stack => {:repository => 'drills', :user => 'construction'}})
    GitHelpers.expects(:git_info_for_stack).returns({:stack => {:repository => 'drills', :user => 'construction'}})
    assert_equal('git@www.testmagic.com:construction/drills', GitHelpers.git_url(:stack, "git", true))
  end
end
