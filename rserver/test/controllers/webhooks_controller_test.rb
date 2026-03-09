require 'test_helper'

class WebhooksControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get webhooks_index_url
    assert_response :success
  end

end
