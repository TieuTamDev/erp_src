require 'test_helper'

class TbhospitalsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get tbhospitals_index_url
    assert_response :success
  end

end
