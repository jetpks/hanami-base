# frozen_string_literal: true

require_relative "test_helper"

# The settings-driven OAuth provider seam (BRIEF §4): settings.oauth_providers
# names the enabled providers; both the OmniAuth registration and the CSP
# form-action origins derive from that same list (config/app.rb). github is the
# compiled-in example strategy. (Bare OmniAuth.strategies can't prove the mount
# — merely requiring omniauth-github appends the class to that list — so the
# seam is asserted at its source.)
class OauthProvidersTest < Minitest::Test
  def settings = Space::Server::App["settings"]

  def test_default_settings_enable_github_only
    assert_equal %w[github], settings.oauth_providers
  end

  def test_every_enabled_provider_resolves_to_a_strategy_registration
    settings.oauth_providers.each do |name|
      assert_includes Space::Server::OAUTH_PROVIDERS, name
    end

    strategy, client_id, client_secret, options =
      Space::Server.oauth_provider_registration("github", settings)
    assert_equal :github, strategy
    # Credentials resolve through the mapped settings keys (nil in test env,
    # where none are configured — same values the seed captured at boot).
    entry = Space::Server::OAUTH_PROVIDERS.fetch("github")
    assert_equal :github_client_id,     entry[:client_id_setting]
    assert_equal :github_client_secret, entry[:client_secret_setting]
    assert_nil client_id
    assert_nil client_secret
    assert_equal({scope: "read:user,user:email,read:org"}, options)
  end

  def test_csp_form_action_includes_every_enabled_provider_origin
    origins = Space::Server.oauth_form_action_origins(settings.oauth_providers)
    assert_equal ["https://github.com"], origins

    # The live app CSP, as derived at boot from the same list.
    form_action = Space::Server::App.config.actions.content_security_policy[:form_action]
    assert_includes form_action, "'self'"
    origins.each { |origin| assert_includes form_action, origin }
  end

  def test_unknown_provider_name_raises
    assert_raises(KeyError) { Space::Server.oauth_provider_registration("gitlab", settings) }
    assert_raises(KeyError) { Space::Server.oauth_form_action_origins(["gitlab"]) }
  end
end
