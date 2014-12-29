require 'deployinator'
require 'deployinator/helpers'
require 'deployinator/helpers/dsh'

class HelpersTest < Test::Unit::TestCase
  include Deployinator::Helpers,
    Deployinator::Helpers::DshHelpers

  def setup
    @jurl = %Q{<a href='https://github.com/example/repo/issues/%s' target='_blank'>%s</a>}
    @issue1 = "ABC-123"
    @issue2 = "DEF-456"
    @issue1_linked = "#{@jurl % ([@issue1] * 2)}"
    @issue2_linked = "#{@jurl % ([@issue2] * 2)}"
    Deployinator.default_user = "testuser"
    Deployinator.deploy_host = "deploytest.vm.ny4dev.etsy.com"
    Deployinator.issue_tracker = proc do |issue|
      "https://github.com/example/repo/issues/#{issue}"
    end

    # mock out the run_cmd. this should move.
    Deployinator::Helpers.module_eval do
      define_method "run_cmd" do |cmd|
        return { :stdout => cmd, :exit_code => 0 }
      end
    end
  end

  def test_single_issue_linked
    assert_equal %Q{I #{@issue1_linked}}, hyperlink("I #{@issue1}")
  end

  def test_multiple_issue_linked
    assert_equal %Q{I #{@issue1_linked}, #{@issue2_linked}}, hyperlink("I #{@issue1}, #{@issue2}")
  end

  def test_no_issue_linked
    assert_equal %Q{I ABC -123, DEF -456}, hyperlink("I ABC -123, DEF -456")
  end

  def test_no_message
    assert_equal %Q{}, hyperlink(nil)
  end

  def test_run_dsh
    assert_equal %Q{ssh testuser@deploytest.vm.ny4dev.etsy.com dsh -g princess  -r ssh -F 30 "whoami"},
                   run_dsh("princess", "whoami")
  end

  def test_run_dsh_multiple
    assert_equal %Q{ssh testuser@deploytest.vm.ny4dev.etsy.com dsh -g princess -g p2  -r ssh -F 30 "whoami"},
                    run_dsh(["princess", "p2"], "whoami")
  end

  def test_with_timeout_failed
    res = with_timeout 1 do
      `sleep 2 && echo -n "foo"`
    end
    assert_equal "", res
  end

  def test_with_timeout_success
    res = with_timeout 3 do
      `sleep 2 && echo -n "foo"`
    end
    assert_equal "foo", res
  end

  def test_strip_to_nil
    assert_equal(nil, strip_ws_to_nil(nil))
    assert_equal(nil, strip_ws_to_nil(''))
    assert_equal(nil, strip_ws_to_nil(' '))
    assert_equal('host01', strip_ws_to_nil('host01 '))
    assert_equal('host01,host02', strip_ws_to_nil(' host01 , host02 '))
    assert_equal('host01', strip_ws_to_nil('host01'))
  end
end
