# encoding: utf-8

require 'deployinator'
require 'deployinator/helpers'
require 'deployinator/helpers/dsh'
require 'tempfile'

class HelpersTest < Test::Unit::TestCase
  include Deployinator::Helpers,
    Deployinator::Helpers::DshHelpers

  def setup
    @jurl = %Q{<a href='https://github.com/example/repo/issues/%s' target='_blank'>%s</a>}
    @issue1 = "ABC-123"
    @issue2 = "DEF-456"
    @issue1_linked = "#{@jurl % ([@issue1] * 2)}"
    @issue2_linked = "#{@jurl % ([@issue2] * 2)}"
    @utf8_canary = 'Iñtërnâtiônàlizætiøn'
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
      `sleep 2 && echo "foo"`
    end
    assert_equal "foo\n", res
  end

  def test_strip_to_nil
    assert_equal(nil, strip_ws_to_nil(nil))
    assert_equal(nil, strip_ws_to_nil(''))
    assert_equal(nil, strip_ws_to_nil(' '))
    assert_equal('host01', strip_ws_to_nil('host01 '))
    assert_equal('host01,host02', strip_ws_to_nil(' host01 , host02 '))
    assert_equal('host01', strip_ws_to_nil('host01'))
  end

  def test_get_from_cache
    Tempfile.open('cache_file', encoding: 'UTF-8') do |tf|
      tf.write(@utf8_canary)
      tf.flush

      cached_content = get_from_cache(tf.path)
      assert_equal(@utf8_canary, cached_content)
      assert_equal(Encoding.find('UTF-8'), cached_content.encoding)
    end
  end

  def test_get_from_cache_when_file_does_not_exist
    assert_equal(false, get_from_cache('/does/not/exist'))
    assert_equal(false, get_from_cache('/does/not/exist', -1))
    assert_equal(false, get_from_cache('/does/not/exist', 10))
  end

  def test_get_from_cache_when_file_is_old
    Tempfile.open('cache_file') do |tf|
      File.stubs(:mtime).with(tf.path).returns(Time.now - 10)

      assert_equal(false, get_from_cache(tf.path))
      assert_not_equal(false, get_from_cache(tf.path, 30))
      assert_not_equal(false, get_from_cache(tf.path, -1))
    end
  end

  def test_write_to_cache
    Tempfile.open('cache_file') do |tf|
      write_to_cache(tf.path, @utf8_canary)

      cached_content = get_from_cache(tf.path)
      assert_equal(@utf8_canary, cached_content)
      assert_equal(Encoding.find('UTF-8'), cached_content.encoding)
    end
  end

  def test_is_admin_groups_nil
    assert_false(is_admin?)
  end

  def test_is_admin_groups_true
    assert_true(is_admin?(["foo", "bar"], ["bar"]))
  end

  def test_is_admin_groups_false
    assert_false(is_admin?(["foo", "bar"], ["bla"]))
  end

  def test_is_admin_groups_true_with_fallback
    @groups = ["foo", "bar"]
    Deployinator.admin_groups = ["bar"]
    assert_true(is_admin?(["foo", "bar"], ["bar"]))
  end
end
