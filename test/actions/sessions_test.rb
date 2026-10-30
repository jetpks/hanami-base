# frozen_string_literal: true

require_relative "action_test_helper"
require "omniauth"
require "time"

class SessionsActionTest < Minitest::Test
  include ActionTestHelper

  def setup
    setup_db
    OmniAuth.config.test_mode = true
  end

  def teardown
    OmniAuth.config.mock_auth[:github] = :csrf_detected
  end

  def mock_callback
    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
      provider: "github",
      uid: "9",
      info: {nickname: "orgy", name: "Orgy", email: "orgy@example.com", image: nil},
      credentials: nil
    )
    post("/auth/github/callback")
  end

  # G1 — login creates user in DB via real repo, sets 302 → root, profile mapped
  def test_login_creates_user_and_sets_session
    status, headers, _ = mock_callback

    assert_equal 302, status
    assert_equal "/", headers["location"]

    users_repo = Space::Server::App["repos.users_repo"]
    user = users_repo.by_github_uid("9")
    refute_nil user
    assert_equal "orgy",             user.username
    assert_equal "Orgy",             user.name
    assert_equal "orgy@example.com", user.email
  end

  # G5 — sessions#create notice flash (oracle: "Signed in as #{user.username}.")
  def test_login_sets_signed_in_notice_flash
    _, headers, _ = mock_callback
    flash = flash_from_redirect(headers)
    assert_equal "Signed in as orgy.", flash["notice"]
  end

  # G2(a) — session fixation: post-login cookie differs from pre-login (rotated)
  def test_login_rotates_session_id
    _, pre_headers, _ = inertia_get("/")
    pre_cookie = pre_headers["set-cookie"]

    _, post_headers, _ = mock_callback
    post_cookie = post_headers["set-cookie"]

    refute_nil post_cookie, "Login must issue a session cookie"
    refute_equal pre_cookie, post_cookie
  end

  # G2(b) — sessions.create is OUT of Hanami Action CSRF
  def test_callback_post_succeeds_without_csrf_token
    status, _, _ = mock_callback
    assert_equal 302, status
  end

  # G4 — logout renews+clears session and redirects root
  def test_logout_clears_session_and_redirects
    mock_callback
    status, headers, _ = get("/logout")
    assert_equal 302, status
    assert_equal "/", headers["location"]
  end

  # G5 — sessions#destroy notice flash (oracle: "Signed out.")
  def test_logout_sets_signed_out_notice_flash
    mock_callback
    _, headers, _ = get("/logout")
    flash = flash_from_redirect(headers)
    assert_equal "Signed out.", flash["notice"]
  end

  # G4 — failure action (GET /auth/failure) redirects to root
  def test_failure_action_redirects_to_root
    status, headers, _ = get("/auth/failure?message=auth_failure")
    assert_equal 302, status
    assert_equal "/", headers["location"]
  end

  # G5 — sessions#failure alert flash (oracle: "Authentication failed: #{params[:message]}.")
  def test_failure_action_sets_alert_flash
    _, headers, _ = get("/auth/failure?message=auth_failure")
    flash = flash_from_redirect(headers)
    assert_equal "Authentication failed: auth_failure.", flash["alert"]
  end

  # G4 — on_failure wired: mock set to Symbol triggers OmniAuth failure handler
  def test_on_failure_handler_wired
    OmniAuth.config.mock_auth[:github] = :access_denied
    status, headers, _ = post("/auth/github/callback")
    assert_equal 302, status
    assert_match %r{\A/auth/failure}, headers["location"]
  end

  # Persistent session cookie (BRIEF §1 phone-first): the sign-in cookie must
  # carry a non-empty expires= attribute consistent with SESSION_EXPIRE_AFTER,
  # so iOS Safari keeps it across lock/tab-discard instead of bouncing hourly.
  def test_sign_in_issues_persistent_session_cookie
    _, headers, _ = mock_callback

    set_cookie = headers["set-cookie"]
    refute_nil set_cookie, "Login must issue a session cookie"
    entry = set_cookie.split("\n").find do |cookie|
      cookie.start_with?("_space_server_session=") && cookie.include?("expires=")
    end
    refute_nil entry, "Sign-in Set-Cookie must carry an expires= attribute: #{set_cookie.inspect}"

    expires = Time.httpdate(entry[/expires=([^;]+)/i, 1])
    assert_in_delta Time.now + Space::Server::SESSION_EXPIRE_AFTER, expires, 300
  end

  # Post-logout session authenticates as nobody: capture the renewed logout
  # cookie, replay it on the root page, and expect the shared props to carry
  # no current_user (the root is the template's public example page — the
  # probe is the shared-props render, not a gated-route bounce).
  def test_logout_cookie_authenticates_as_nobody
    _, login_headers, _ = mock_callback
    @session_cookie = login_headers["set-cookie"]&.split(";")&.first
    refute_nil @session_cookie, "Login must issue a session cookie"

    _, logout_headers, _ = get("/logout")
    @session_cookie = logout_headers["set-cookie"]&.split(";")&.first
    refute_nil @session_cookie, "Logout must issue a renewed session cookie"

    _, _, body = inertia_get("/")
    assert_nil parse_json(body)["props"]["current_user"]
  end

  # G5 — no dev_auth_user bypass in architect app/ sources
  def test_no_dev_auth_user_bypass
    architect_app_dir = File.expand_path("../../app", __dir__)
    hits = Dir.glob("#{architect_app_dir}/**/*.rb").select do |f|
      File.read(f).include?("dev_auth_user")
    end
    assert_empty hits, "dev_auth_user must not appear in architect app/ sources: #{hits}"
  end

  # G5 — current_user is nil with no session (tested via action without crashing)
  def test_get_root_without_session_does_not_crash
    status, _, _ = inertia_get("/")
    assert status < 500, "GET / with no session must not 500 (current_user must be nil-safe)"
  end
end
