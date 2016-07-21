require 'deployinator'
require 'deployinator/helpers'
require 'deployinator/helpers/git'

include Deployinator::Helpers::GitHelpers

class HelpersTest < Test::Unit::TestCase

  def test_git_url_https
    GitHelpers.expects(:which_github_host).returns("www.testmagic.com")
    GitHelpers.expects(:git_info_for_stack).returns({:stack => {:repository => 'drills', :user => 'construction'}}).at_least_once
    assert_equal('https://www.testmagic.com/construction/drills.git', GitHelpers.git_url(:stack, 'https', false))
  end

  def test_git_url_default
    GitHelpers.expects(:which_github_host).returns("www.testmagic.com")
    GitHelpers.expects(:git_info_for_stack).returns({:stack => {:repository => 'drills', :user => 'construction'}}).at_least_once
    assert_equal('git://www.testmagic.com/construction/drills', GitHelpers.git_url(:stack))
  end

  def test_git_url_read_write
    GitHelpers.expects(:which_github_host).returns("www.testmagic.com")
    GitHelpers.expects(:git_info_for_stack).returns({:stack => {:repository => 'drills', :user => 'construction'}}).at_least_once
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
    GitHelpers.expects(:git_freshen_clone).with(:stack, "extra-ssh", "/dev/null", "merge99", false)
    GitHelpers.git_freshen_or_clone(:stack, "extra-ssh", "/dev/null", "merge99", false, "https")
  end

  def test_git_freshen_or_clone_git_update_force
    GitHelpers.expects(:git_checkout_path).returns("/dev/null")
    GitHelpers.expects(:is_git_repo).with("/dev/null", "extra-ssh").returns(:true)
    GitHelpers.expects(:log_and_stream).returns(nil)
    GitHelpers.expects(:git_freshen_clone).with(:stack, "extra-ssh", "/dev/null", "merge99", true)
    GitHelpers.git_freshen_or_clone(:stack, "extra-ssh", "/dev/null", "merge99", false, "https", true)
  end
  def test_git_freshen_or_clone_git_bad_repo
    GitHelpers.expects(:git_checkout_path).returns("/dev/null")
    GitHelpers.expects(:is_git_repo).with("/dev/null", "extra-ssh").returns(:false)
    GitHelpers.expects(:log_and_stream).returns(nil)
    GitHelpers.git_freshen_or_clone(:stack, "extra-ssh", "/dev/null", "merge99", false, "https")
  end

  def test_git_head_rev_should_cache_results
    FileUtils.rm_f('/tmp/rev_head_cache_some_stack')

    head_rev_sha = 'ba83f60523008e48950f77bd0d3a773f9cb2805c'
    GitHelpers.expects(:get_git_head_rev).with('some_stack', 'master').returns(head_rev_sha).once
    assert_equal(head_rev_sha, GitHelpers.git_head_rev('some_stack'))
    # Calling it a second time should just use the cached result on disk
    assert_equal(head_rev_sha, GitHelpers.git_head_rev('some_stack'))
  end

  def test_git_get_head_rev_ls_output
    good_ls_output = <<-EOM
    724fe11d3d3afd1fe7e0bfa8cd9f34b90d038599        refs/heads/master
    EOM

    good_first_10_sha = '724fe11d3d'

    bad_ls_output = <<-EOM
    724fe11d3d3afd1fe7e0bfa8cd9f34b90d038599        refs/heads/master
    724fe11d3d3afd1fe7e0bfa8cd9f34b90d038599        refs/heads/origin/master
    EOM

    assert_equal(
      good_first_10_sha,
      GitHelpers.get_git_head_rev_from_ls_output(good_ls_output, 'master')
    )

    assert_raise(GitHelpers::AmbiguousRemoteBranchesError) do
      GitHelpers.get_git_head_rev_from_ls_output(bad_ls_output, 'master')
    end
  end
end
