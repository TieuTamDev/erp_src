require 'test_helper'

class TmpcontractsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get tmpcontracts_index_url
    assert_response :success
  end

end
