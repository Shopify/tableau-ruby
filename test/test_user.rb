require File.dirname(__FILE__) + '/test_helper'

class TestUsers < TableauTest
  def test_user_listing
    all_users = @client.users.all
    assert all_users[:users].is_a? Array
    assert all_users[:users].size() > 0
  end

  def test_user_find_by_name
    admin_user = @client.users.find_by(user_name: ENV['TABLEAU_ADMIN_USER'])
    assert_equal admin_user[:name], ENV['TABLEAU_ADMIN_USER']
    assert admin_user[:id]
  end
end
