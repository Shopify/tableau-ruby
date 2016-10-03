require_relative 'test_helper'

class TestUsers < TableauTest
  def test_user_listing
    VCR.use_cassette("tableau_user_list", :erb => true) do
      all_users = @client.users.all
      assert all_users[:users].is_a? Array
      assert all_users[:users].size() > 0
    end
  end

  def test_user_listing_with_page_size
    VCR.use_cassette("tableau_user_list", :erb => true) do
      all_users = @client.users.all(page_size: 10)
      assert all_users[:users].is_a? Array
      assert all_users[:users].size() > 0
    end
  end

  def test_user_listing_with_page_size_and_page_number
    VCR.use_cassette("tableau_user_list", :erb => true) do
      all_users = @client.users.all(page_size: 10, page_number: 2)
      assert all_users[:users].is_a? Array
      assert all_users[:users].size() > 0
    end
  end
  
  def test_user_generic_get
    VCR.use_cassette("tableau_user_list", :erb => true) do
      all_users = @client.users.get(page_size: 10, page_number: 2)
      assert all_users[:users].is_a? Array
      assert all_users[:users].size() > 0
    end
  end

  def test_user_find_by_id
    VCR.use_cassette("tableau_user_find", :erb => true) do
      admin_user = @client.users.find_by(id: @admin_user[:id])
      assert_equal @admin_user, admin_user
    end
  end

  def test_user_find_by_name
    VCR.use_cassette("tableau_user_find_name", :erb => true) do
      admin_user = @client.users.find_by(name: ENV['TABLEAU_ADMIN_USER'])
      assert_equal admin_user[:name], ENV['TABLEAU_ADMIN_USER']
      assert admin_user[:id]
    end
  end

  def test_user_create
    VCR.use_cassette("tableau_user_create", :erb => true) do
      user_id = @client.users.create(:name => "captain_lulz")
      assert_equal "93796309-005f-480b-9b30-fbfb717b35bd", user_id
    end
  end
  
  def test_user_delete
    VCR.use_cassette("tableau_user_delete", :erb => true) do
      status = @client.users.delete(:user_id => "93796309-005f-480b-9b30-fbfb717b35bd")
      assert_equal 204, status
    end
  end
end
