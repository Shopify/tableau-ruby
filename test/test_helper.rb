require "minitest/autorun"
require 'pry'
require 'tableau_ruby'
require 'mocha/setup'
require 'vcr'
require 'byebug'

VCR.configure do |config|
  config.cassette_library_dir = "test/vcr_cassettes"
  config.hook_into :faraday
end

class TableauTest < Minitest::Test
  def setup
    VCR.use_cassette("tableau_setup", :erb => true) do
      @client = Tableau::Client.new(host: ENV['TABLEAU_URL'], admin_name: ENV['TABLEAU_ADMIN_USER'], admin_password: ENV['TABLEAU_ADMIN_PASSWORD'])
      @site = @client.sites.find_by(name: ENV['TABLEAU_DEFAULT_SITE'])
      @admin_user = @client.users.find_by(name: ENV['TABLEAU_ADMIN_USER'])
    end
  end
end
