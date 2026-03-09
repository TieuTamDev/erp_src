require 'test_helper'

class PositionjobsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get positionjobs_index_url
    assert_response :success
  end

end
