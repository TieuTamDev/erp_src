require 'test_helper'

class HiresControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get hires_index_url
    assert_response :success
  end

end
