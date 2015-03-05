require 'deployinator/helpers/concurrency'

Celluloid.logger = nil
class ConcurrencyTest < Test::Unit::TestCase
  # Celluloid recommends doing this before each test
  # https://github.com/celluloid/celluloid/wiki/Gotchas#testing
  include Deployinator::Helpers::ConcurrencyHelpers
  def setup
    Celluloid.boot
    @@futures = {}
  end

  def teardown
    Celluloid.shutdown
  end

  def test_spawn_off_concurrent_thread
    run_parallel(:test) do 
      "Running inside thread"
    end
    assert_equal(get_value(:test), "Running inside thread")
  end

  def test_future_name_type
    assert_raise NoMethodError do
      run_parallel({:test => 'going crazy'}) do 
        "Running inside thread"
      end
    end
  end

  def test_fibers_with_same_reference
    run_parallel(:test) do 
      "Running inside thread"
    end
    assert_raise Deployinator::Helpers::ConcurrencyHelpers::DuplicateReferenceError do 
      run_parallel(:test) do 
        "Running inside thread"
      end
    end
  end

  def test_get_non_symbol_value
    run_parallel(:test) do 
      "Running inside thread"
    end
    assert_raise NoMethodError do
      get_value({:test => 'going crazy - jpaul'})
    end
  end

  def test_reference_taken
    assert_equal(reference_taken?(:test), false)
    @@futures[:test] = 'a value'
    assert_equal(reference_taken?(:test), true)
  end

  def test_multiple_futures_return
    run_parallel(:test1) do 
      "future1"
    end
    run_parallel(:test2) do 
      "future2"
    end
    assert_equal(get_values(:test1, :test2), {:test1 => "future1", :test2 => "future2"})
  end

end
