require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "should get blank" do
    get pages_blank_url
    assert_response :success
  end
end
