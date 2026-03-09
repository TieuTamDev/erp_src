require 'test_helper'

class MrulesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get mrules_index_url
    assert_response :success
  end

end
