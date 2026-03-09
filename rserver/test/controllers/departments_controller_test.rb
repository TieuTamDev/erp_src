require 'test_helper'

class DepartmentsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get departments_index_url
    assert_response :success
  end

end
