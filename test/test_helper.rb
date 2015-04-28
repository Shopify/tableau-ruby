require "minitest/autorun"
require 'byebug'
require 'tableau_ruby'
require 'mocha/setup'

class TableauTest < Minitest::Test
  def setup
    @client = Tableau::Client.new(host: ENV['TABLEAU_URL'], admin_name: ENV['TABLEAU_ADMIN_USER'], admin_password: ENV['TABLEAU_ADMIN_PASSWORD'])
    @site = @client.sites.find_by(name: ENV['TABLEAU_DEFAULT_SITE'])
    @admin_user = @client.users.find_by(user_name: ENV['TABLEAU_ADMIN_USER'])
  end
end
