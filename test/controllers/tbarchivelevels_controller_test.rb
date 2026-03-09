require 'test_helper'

class TbarchivelevelsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get tbarchivelevels_index_url
    assert_response :success
  end

end
