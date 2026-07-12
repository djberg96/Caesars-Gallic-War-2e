require "test_helper"

class BoardControllerTest < ActionDispatch::IntegrationTest
  test "renders the playable board shell" do
    get root_url(host: "localhost")

    assert_response :success
    assert_select "h1", "Caesar's Gallic War"
    assert_select "script#game-data"
    assert_includes response.body, "CGW_Map"
    assert_match %r{Cards/allobroges-[a-f0-9]+\.svg}, response.body
    assert_includes response.body, "Legion X"
  end
end
