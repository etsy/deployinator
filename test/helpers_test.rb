require File.expand_path('../helper', __FILE__)

class HelpersTest < Test::Unit::TestCase
  include Deployinator::Helpers

  def setup
    @jurl = %Q{<a href='https://github.com/example/repo/issues/%s' target='_blank'>%s</a>}
    @issue1 = "ABC-123"
    @issue2 = "DEF-456"
    @issue1_linked = "#{@jurl % ([@issue1] * 2)}"
    @issue2_linked = "#{@jurl % ([@issue2] * 2)}"
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
end
