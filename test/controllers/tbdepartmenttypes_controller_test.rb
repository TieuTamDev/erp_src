require 'test_helper'

class TbdepartmenttypesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get tbdepartmenttypes_index_url
    assert_response :success
  end

end
