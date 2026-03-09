require 'test_helper'

class StasksControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get stasks_index_url
    assert_response :success
  end

end
