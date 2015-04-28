require File.dirname(__FILE__) + '/test_helper'

class TestSite < TableauTest
  def test_site_finding
    site = @client.sites.find_by(name: ENV['TABLEAU_DEFAULT_SITE'])
    assert site[:name]
    assert site[:id]
  end

  def test_site_listing
    sites = @client.sites.all 
    assert sites[:sites].is_a? Array
  end
end
