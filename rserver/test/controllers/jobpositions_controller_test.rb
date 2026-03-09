require 'test_helper'

class JobpositionsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get jobpositions_index_url
    assert_response :success
  end

end
