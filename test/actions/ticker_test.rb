# frozen_string_literal: true

require_relative "action_test_helper"

# The ticker page renders through the full inertia chassis — the page half of
# the SSE demo (the stream itself is TickerStreamTest). This test exists
# because the page was once unroutable: GET /ticker was the stream, nothing
# rendered the Ticker/Index component, and every suite stayed green because
# no test ever asked for the page.
class TickerTest < Minitest::Test
  include ActionTestHelper

  def setup
    setup_db
  end

  def test_ticker_renders_page_object
    status, headers, body = inertia_get("/ticker")
    assert_equal 200, status
    assert_equal "true", headers["x-inertia"]

    data = parse_json(body)
    assert_equal "Ticker/Index", data["component"]
    assert_equal "/ticker", data["url"]
    assert data.key?("version")
  end

  def test_ticker_page_carries_only_shared_props
    _, _, body = inertia_get("/ticker")
    props = parse_json(body)["props"]
    assert_nil props["current_user"]
    assert_equal({}, props["flash"])
  end
end
