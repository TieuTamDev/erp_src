require 'test_helper'

class TbbenefitsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get tbbenefits_index_url
    assert_response :success
  end

end
