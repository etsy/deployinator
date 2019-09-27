require 'test/unit'
require 'mocha/test_unit'
require 'open3'

require File.expand_path('../../lib/deployinator/helpers.rb',__dir__)

class DeployinatorHelpersTest < Test::Unit::TestCase

  def test_run_cmd_calls_popen3_once_with_expected_command
    # arrange
    cmd = 'fakecommand'
    deployinator_helper = Class.new.extend(Deployinator::Helpers)
    Open3.expects(:popen3).with(cmd).once

    # act & assert
    deployinator_helper.run_cmd(cmd)
  end

  def test_run_cmd_succeeds_while_log_errors_is_false
    # arrange
    cmd = 'echo -n epicsuccess && exit 0'
    deployinator_helper = Class.new.extend(Deployinator::Helpers)
    deployinator_helper.expects(:log_and_stream).times(4)
    log_errors = false

    expected = {
      :exit_code => 0,
      :stdout => 'epicsuccess'
    }

    # act
    actual = deployinator_helper.run_cmd(cmd, nil, log_errors)

    # assert
    assert_equal(expected, actual)
  end

  def test_run_cmd_succeeds_while_log_errors_is_true
    # arrange
    cmd = 'echo -n epicsuccess && exit 0'
    deployinator_helper = Class.new.extend(Deployinator::Helpers)
    deployinator_helper.expects(:log_and_stream).times(4)
    log_errors = true

    expected = {
      :exit_code => 0,
      :stdout => 'epicsuccess'
    }

    # act
    actual = deployinator_helper.run_cmd(cmd, nil, log_errors)

    # assert
    assert_equal(expected, actual)
  end

  def test_run_cmd_fails_while_log_errors_is_false
    # arrange
    cmd = 'echo -n epicfail && exit 1'
    deployinator_helper = Class.new.extend(Deployinator::Helpers)
    deployinator_helper.expects(:log_and_stream).times(5)
    log_errors = false

    expected = {
      :exit_code => 1,
      :stdout => 'epicfail'
    }

    # act
    actual = deployinator_helper.run_cmd(cmd, nil, log_errors)

    # assert
    assert_equal(expected, actual)
  end

  def test_run_cmd_fails_while_log_errors_is_true
    # arrange
    cmd = 'echo -n epicfail && exit 1'
    deployinator_helper = Class.new.extend(Deployinator::Helpers)
    deployinator_helper.expects(:log_and_stream).times(5)
    log_errors = true

    expected = {
      :exit_code => 1,
      :stdout => 'epicfail'
    }

    # act
    actual = deployinator_helper.run_cmd(cmd, nil, log_errors)

    # assert
    assert_equal(expected, actual)
  end

end
