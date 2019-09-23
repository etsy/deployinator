require 'test/unit'
require 'mocha/test_unit'
require 'open3'

require File.expand_path('../../lib/deployinator/helpers.rb',__dir__)

class DeployinatorHelpersTest < Test::Unit::TestCase

  def test_run_cmd_succeeds
    # arrange
    cmd = 'dummy_command_exits_with_success'

    deployinator_helper = Class.new.extend(Deployinator::Helpers)
    deployinator_helper.expects(:run_cmd)
      .returns({
        :exit_code => 0
      })
      .once

    # act
    actual = deployinator_helper.run_cmd(cmd)

    # assert
    assert_equal({:exit_code => 0}, actual)
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
