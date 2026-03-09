require 'test_helper'

class RegulationControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get regulation_index_url
    assert_response :success
  end

end
