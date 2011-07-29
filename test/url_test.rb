require File.expand_path('../helper', __FILE__)
require 'capybara'
require 'capybara/dsl'

class UrlTest < Test::Unit::TestCase
  include Capybara::DSL
  
  def setup
    Capybara.app = Deployinator::App.new
  end
  
  def test_get_homepage_logged_in
    log_in_as("foo")
    visit '/'
    assert page.has_content?('Welcome to'), page.body
  end
end