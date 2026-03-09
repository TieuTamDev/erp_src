require 'test_helper'

class OperatingsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get operatings_index_url
    assert_response :success
  end

end
