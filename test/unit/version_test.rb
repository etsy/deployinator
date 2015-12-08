require 'deployinator/helpers/version'
require 'test/unit'
require 'mocha/setup'

class VersionTest < Test::Unit::TestCase

  def test_get_build_from_valid_string
    res = Deployinator::Helpers::VersionHelpers.get_build('c5e3d40-20111227-195028-UTC')
    assert_equal('c5e3d40', res)
  end

  def test_get_build_from_longer_rev
    res = Deployinator::Helpers::VersionHelpers.get_build('c5e3d4066-20111227-195028-UTC')
    assert_equal('c5e3d4066', res)
  end

  def test_get_build_from_rev_too_short
    res = Deployinator::Helpers::VersionHelpers.get_build('c5e3d-20111227-195028-UTC')
    assert_equal(nil, res)
  end

  def test_get_build_from_invalid_string
    res = Deployinator::Helpers::VersionHelpers.get_build('<!DOCTYPE html>
                              <html xmlns="http://www.w3.org/1999/xhtml">
                              <head>')
    assert_equal(nil, res)
  end

  def test_get_build_from_nil
    res = Deployinator::Helpers::VersionHelpers.get_build nil
    assert_equal(nil, res)
  end

  # unit test get_version_by_url with mocked curl_get_url
  def test_get_version_by_url_with_real_version
    Deployinator::Helpers::VersionHelpers.expects(:curl_get_url)
           .with("https://testhost.etsy.com/version.txt")
           .returns("c5e3d40-20111227-195028-UTC")
    res = Deployinator::Helpers::VersionHelpers.get_version_by_url("https://testhost.etsy.com/version.txt")
    assert_equal("c5e3d40-20111227-195028-UTC", res)
  end

  def test_get_version_by_url_with_invalid_string
    Deployinator::Helpers::VersionHelpers.expects(:curl_get_url)
           .with("https://testhost.etsy.com/version.txt")
           .returns('<!DOCTYPE html>
                     <html xmlns="http://www.w3.org/1999/xhtml">
                     <head>')
    res = Deployinator::Helpers::VersionHelpers.get_version_by_url("https://testhost.etsy.com/version.txt")
    assert_equal(nil, res)
  end

  def test_get_version_by_url_with_too_short_format
    Deployinator::Helpers::VersionHelpers.expects(:curl_get_url)
           .with("https://testhost.etsy.com/version.txt")
           .returns("c5e3d40-201127-195028-UTC")
    res = Deployinator::Helpers::VersionHelpers.get_version_by_url("https://testhost.etsy.com/version.txt")
    assert_equal(nil, res)
  end

  def test_get_version_by_url_with_too_long_format
    Deployinator::Helpers::VersionHelpers.expects(:curl_get_url)
           .with("https://testhost.etsy.com/version.txt")
           .returns("c5e3d40-2011122700-195028-UTC")
    res = Deployinator::Helpers::VersionHelpers.get_version_by_url("https://testhost.etsy.com/version.txt")
    assert_equal(nil, res)
  end

  # integration testing the get_version method with get_version_by_url
  def test_get_version_with_real_version
    Deployinator::Helpers::VersionHelpers.expects(:curl_get_url)
           .with("https://testhost.etsy.com/version.txt")
           .returns("c5e3d40-20111227-195028-UTC")
    res = Deployinator::Helpers::VersionHelpers.get_version("testhost.etsy.com")
    assert_equal("c5e3d40-20111227-195028-UTC", res)
  end

  def test_get_version_with_invalid_string
    Deployinator::Helpers::VersionHelpers.expects(:curl_get_url)
           .with("https://testhost.etsy.com/version.txt")
           .returns('<!DOCTYPE html>
                     <html xmlns="http://www.w3.org/1999/xhtml">
                     <head>')
    res = Deployinator::Helpers::VersionHelpers.get_version("testhost.etsy.com")
    assert_equal(nil, res)
  end

  def test_get_version_with_too_short_format
    Deployinator::Helpers::VersionHelpers.expects(:curl_get_url)
           .with("https://testhost.etsy.com/version.txt")
           .returns("c5e3d40-201127-195028-UTC")
    res = Deployinator::Helpers::VersionHelpers.get_version("testhost.etsy.com")
    assert_equal(nil, res)
  end

  def test_get_version_with_too_long_format
    Deployinator::Helpers::VersionHelpers.expects(:curl_get_url)
           .with("https://testhost.etsy.com/version.txt")
           .returns("c5e3d40-2011122700-195028-UTC")
    res = Deployinator::Helpers::VersionHelpers.get_version("testhost.etsy.com")
    assert_equal(nil, res)
  end

end
