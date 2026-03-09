require 'test_helper'

class TbarchivetypesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get tbarchivetypes_index_url
    assert_response :success
  end

end
