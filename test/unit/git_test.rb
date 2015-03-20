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

  def test_git_freshen_or_clone_https_passthrough
    GitHelpers.expects(:git_checkout_path).returns("/dev/null")
    GitHelpers.expects(:is_git_repo).with("/dev/null", "extra-ssh").returns(:missing)
    GitHelpers.expects(:log_and_stream).returns(nil)
    GitHelpers.expects(:git_url).with(:stack, "https", false).returns("https://www.testmagic.com/construction/drills.git")
    GitHelpers.expects(:git_clone).with(:stack, "https://www.testmagic.com/construction/drills.git", "extra-ssh", "/dev/null", "merge99")
    GitHelpers.git_freshen_or_clone(:stack, "extra-ssh", "/dev/null", "merge99", false, "https")
  end

  def test_git_freshen_or_clone_git_update
    GitHelpers.expects(:git_checkout_path).returns("/dev/null")
    GitHelpers.expects(:is_git_repo).with("/dev/null", "extra-ssh").returns(:true)
    GitHelpers.expects(:log_and_stream).returns(nil)
    GitHelpers.expects(:git_freshen_clone).with(:stack, "extra-ssh", "/dev/null", "merge99")
    GitHelpers.git_freshen_or_clone(:stack, "extra-ssh", "/dev/null", "merge99", false, "https")
  end

  def test_git_freshen_or_clone_git_bad_repo
    GitHelpers.expects(:git_checkout_path).returns("/dev/null")
    GitHelpers.expects(:is_git_repo).with("/dev/null", "extra-ssh").returns(:false)
    GitHelpers.expects(:log_and_stream).returns(nil)
    GitHelpers.git_freshen_or_clone(:stack, "extra-ssh", "/dev/null", "merge99", false, "https")
  end
end
