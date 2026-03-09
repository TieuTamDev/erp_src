require 'test_helper'

class PayslipsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get payslips_index_url
    assert_response :success
  end

end
