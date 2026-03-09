require 'test_helper'

class SbenefitsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get sbenefits_index_url
    assert_response :success
  end

end
