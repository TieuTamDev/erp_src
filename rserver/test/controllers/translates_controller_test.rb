require 'test_helper'

class TranslatesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get translates_index_url
    assert_response :success
  end

  test "should get new" do
    get translates_new_url
    assert_response :success
  end

  test "should get edit" do
    get translates_edit_url
    assert_response :success
  end

  test "should get update" do
    get translates_update_url
    assert_response :success
  end

  test "should get delete" do
    get translates_delete_url
    assert_response :success
  end

end
