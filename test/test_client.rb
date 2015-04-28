require File.dirname(__FILE__) + '/test_helper'

class TestClient < Minitest::Test
  def test_client_initializes_connection_things
    Tableau::Client.any_instance.expects(:setup_connection)
    Tableau::Client.any_instance.expects(:sign_in)
    Tableau::Client.any_instance.expects(:get_site_id)

    Tableau::Client.new(host: 'http://www.zombo.com', admin_name: 'bar', admin_password: 'waldo')
  end

  def test_client_POSTs_auth_blurb
    # lol
    Faraday::RackBuilder.any_instance.expects(:build_response).with do |*args|
      req = args[1]
      assert_equal req.method, :post
      assert_equal req.path, "/api/2.0/auth/signin"
      assert_equal req.headers["Content-Type"], "application/xml"
      assert_equal req.body, "<?xml version=\"1.0\"?>\n<tsRequest>\n  <credentials name=\"bar\" password=\"waldo\">\n    <site/>\n  </credentials>\n</tsRequest>\n"
    end.raises("dont care")

    err = assert_raises(RuntimeError) {
      Tableau::Client.new(host: 'http://www.zombo.com', admin_name: 'bar', admin_password: 'waldo')
    }
    assert_equal err.message, "dont care"
  end
end
