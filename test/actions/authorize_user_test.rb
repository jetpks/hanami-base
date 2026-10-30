# frozen_string_literal: true

require_relative "action_test_helper"

# The authz seam (BRIEF §4): the default allows any authenticated identity, so
# the template round-trips auth out of the box; a denial must NOT create
# a session — alert flash + redirect to / only.
class AuthorizeUserTest < Minitest::Test
  include ActionTestHelper

  def setup
    setup_db
    OmniAuth.config.test_mode = true
  end

  def teardown
    OmniAuth.config.mock_auth[:github] = :csrf_detected
  end

  def mock_callback(uid: "9", username: "authz")
    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
      provider: "github",
      uid: uid,
      info: {nickname: username, name: username.capitalize, email: "#{username}@example.com", image: nil},
      credentials: nil
    )
    post("/auth/github/callback")
  end

  def seam = Space::Server::App["operations.authorize_user"]

  # Container resolutions are fresh instances, so the deny rule is injected at
  # the class: every resolution constructs the denying seam for the block's
  # span — the shape a project gets by overriding AuthorizeUser#call.
  def with_denying_seam
    deny_seam = Object.new
    def deny_seam.call(_user, _auth_hash) = false
    Space::Server::Operations::AuthorizeUser.stub(:new, ->(*) { deny_seam }) do
      yield
    end
  end

  def test_default_decision_is_allow
    assert_equal true, seam.call(nil, nil)
  end

  def test_allow_round_trip_creates_session
    status, headers, _ = mock_callback
    assert_equal 302, status
    assert_equal "/", headers["location"]

    user = Space::Server::App["repos.users_repo"].by_github_uid("9")
    refute_nil user, "allowed sign-in must persist the user"

    @session_cookie = headers["set-cookie"]&.split(";")&.first
    _, _, body = inertia_get("/")
    assert_equal "authz", parse_json(body)["props"]["current_user"]["username"]
  end

  def test_deny_sets_alert_flash_and_redirects_without_session
    with_denying_seam do
      status, headers, _ = mock_callback
      assert_equal 302, status
      assert_equal "/", headers["location"]

      flash = flash_from_redirect(headers)
      assert_equal "Not authorized.", flash["alert"]
      assert_nil flash["notice"]
    end
  end

  def test_deny_leaves_the_replayed_cookie_unauthenticated
    with_denying_seam do
      _, headers, _ = mock_callback

      # The callback still sets a (renewed) cookie for the flash to ride —
      # replaying it on the root must surface NO current_user.
      @session_cookie = headers["set-cookie"]&.split(";")&.first
      refute_nil @session_cookie

      _, _, body = inertia_get("/")
      assert_nil parse_json(body)["props"]["current_user"],
                 "a denied sign-in must not authenticate the session"
    end
  end
end
