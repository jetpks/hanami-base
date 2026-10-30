# frozen_string_literal: true

require_relative "action_test_helper"
require "async"
require "async/redis"
require "async/redis/endpoint"

class TickerPublishTest < Minitest::Test
  include ActionTestHelper

  STREAM_KEY = "sse:ticker"
  COUNTER_KEY = "sse:ticker:count"

  def redis_endpoint
    url = ENV["REDIS_URL"]
    url ? Async::Redis::Endpoint.parse(url) : Async::Redis.local_endpoint
  end

  # CSRF is auto-disabled under HANAMI_ENV=test (hanami-action skips the
  # session/CSRF stack entirely in the test env), so the plain post helper
  # needs no token — the browser path (X-XSRF-TOKEN header) is exercised by
  # the Ticker page and its component test.

  def test_publish_appends_one_stream_entry_and_returns_n
    Sync do
      redis_client = Async::Redis::Client.new(redis_endpoint)
      redis_client.del(STREAM_KEY, COUNTER_KEY)

      status, headers, body = post("/ticker/publish")
      assert_equal 200, status
      assert_match "application/json", headers["content-type"]
      payload = parse_json(body)
      assert_equal true, payload["ok"]
      n = payload["n"]
      assert_kind_of Integer, n

      entries = redis_client.xrange(STREAM_KEY, "-", "+") || []
      assert_equal 1, entries.length, "one publish appends exactly one entry"

      entry_id, fields = entries.first
      assert_match(/\A\d+-\d+\z/, entry_id)
      assert_equal "tick", fields[fields.index("type") + 1]
      assert_equal n, JSON.parse(fields[fields.index("data") + 1])["n"]
    ensure
      redis_client&.close
    end
  end

  def test_publish_increments_the_counter
    Sync do
      redis_client = Async::Redis::Client.new(redis_endpoint)
      redis_client.del(COUNTER_KEY)

      _, _, body1 = post("/ticker/publish")
      _, _, body2 = post("/ticker/publish")

      assert_equal parse_json(body1)["n"] + 1, parse_json(body2)["n"], "INCR round-trips"
    ensure
      redis_client&.close
    end
  end
end
