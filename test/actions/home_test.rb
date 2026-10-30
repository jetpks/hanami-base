# frozen_string_literal: true

require_relative "action_test_helper"

# The root renders the template's example page through the full inertia
# chassis: page object shape, component name, shared props.
class HomeTest < Minitest::Test
  include ActionTestHelper

  def setup
    setup_db
    OmniAuth.config.test_mode = true
  end

  def teardown
    OmniAuth.config.mock_auth[:github] = :csrf_detected
  end

  def test_root_renders_home_index_page_object
    status, headers, body = inertia_get("/")
    assert_equal 200, status
    assert_equal "true", headers["x-inertia"]
    assert_equal "application/json", headers["content-type"]

    data = parse_json(body)
    assert_equal "Home/Index", data["component"]
    assert_equal "/", data["url"]
    assert data.key?("version")
  end

  def test_root_carries_shared_props_for_anonymous
    _, _, body = inertia_get("/")
    props = parse_json(body)["props"]
    assert_nil props["current_user"]
    assert_equal({}, props["flash"])
  end

  def test_root_shared_props_carry_signed_in_user
    user = Factory[:user, username: "rooty"]
    sign_in(user)
    _, _, body = inertia_get("/")
    assert_equal "rooty", parse_json(body)["props"]["current_user"]["username"]
  end
end
