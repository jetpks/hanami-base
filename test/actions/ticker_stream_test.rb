# frozen_string_literal: true

require_relative "action_test_helper"
require "async"
require "async/redis"
require "async/redis/endpoint"
require_relative "../../lib/space/server/sse"

class TickerStreamTest < Minitest::Test
  include ActionTestHelper

  STREAM_KEY = "sse:ticker"

  def teardown
    Space::Server::SSE::Fanout.stop(STREAM_KEY)
  end

  def redis_endpoint
    url = ENV["REDIS_URL"]
    url ? Async::Redis::Endpoint.parse(url) : Async::Redis.local_endpoint
  end

  # data payloads of the collected frames, in order (scan yields one array
  # per match — destructure the single capture group).
  def sse_ns(chunks)
    chunks.join.scan(/^data: (.+)$/).map { |(data)| JSON.parse(data)["n"] }
  end

  # --- headers (public endpoint by design) --------------------------------------------

  def test_ticker_anon_returns_sse_headers
    status, headers, = get_stream("/ticker")
    assert_equal 200, status
    assert_equal "text/event-stream", headers["content-type"]
    assert_equal "no-cache", headers["cache-control"]
    assert_equal "no", headers["x-accel-buffering"]
  end

  # --- backlog replay ------------------------------------------------------------------

  def test_ticker_backlog_replays_seeded_entries
    Sync do
      redis_client = Async::Redis::Client.new(redis_endpoint)
      redis_client.del(STREAM_KEY)
      first = redis_client.xadd(STREAM_KEY, "*", "type", "tick", "data", %({"type":"tick","n":1}))
      _     = redis_client.xadd(STREAM_KEY, "*", "type", "tick", "data", %({"type":"tick","n":2}))
      _     = redis_client.xadd(STREAM_KEY, "*", "type", "tick", "data", %({"type":"tick","n":3}))

      _, _, body = get_stream("/ticker")
      chunks = collect_sse_chunks(body, timeout: 5)

      text = chunks.join
      assert_equal [1, 2, 3], sse_ns(chunks)
      assert_match "id: #{first}", text, "each entry carries its redis id for resume"
    ensure
      redis_client&.close
    end
  end

  # --- live tail via the fanout ----------------------------------------------------------

  def test_ticker_live_tail_delivers_entries_via_fanout
    Sync do
      redis_client = Async::Redis::Client.new(redis_endpoint)
      redis_client.del(STREAM_KEY)

      _, _, body = get_stream("/ticker")
      chunks = []
      mock_stream = MockStream.new(chunks)

      body_task = Async do
        begin
          body.call(mock_stream)
        rescue
        end
      end

      # Sleep briefly to let XREAD BLOCK register in Redis before the XADD fires.
      sleep 0.05
      redis_client.xadd(STREAM_KEY, "*", "type", "tick", "data", %({"type":"tick","n":7}))

      # The live tail has no terminal event — collect for a moment, then stop.
      sleep 0.3
      body_task.stop
      body_task.wait rescue nil

      assert_equal [7], sse_ns(chunks)
    ensure
      redis_client&.close
    end
  end

  # --- Last-Event-ID resume ----------------------------------------------------------------

  def test_ticker_last_event_id_replays_only_post_cursor_entries
    Sync do
      redis_client = Async::Redis::Client.new(redis_endpoint)
      redis_client.del(STREAM_KEY)
      redis_client.xadd(STREAM_KEY, "*", "type", "tick", "data", %({"type":"tick","n":1}))
      second = redis_client.xadd(STREAM_KEY, "*", "type", "tick", "data", %({"type":"tick","n":2}))
      redis_client.xadd(STREAM_KEY, "*", "type", "tick", "data", %({"type":"tick","n":3}))

      _, _, body = get_stream("/ticker", extra_env: {"HTTP_LAST_EVENT_ID" => second})
      chunks = collect_sse_chunks(body, timeout: 5)

      assert_equal [3], sse_ns(chunks), "reconnect replays exactly the post-cursor entries"
    ensure
      redis_client&.close
    end
  end

  # --- heartbeat ------------------------------------------------------------------------------

  def test_ticker_heartbeat_pings_after_the_backlog
    # Heartbeat constant swapped short — the action reads it at queue-pop time,
    # so the production 15s posture is unchanged while the test cycles fast.
    fanout_class = Space::Server::SSE::Fanout
    original     = fanout_class::HEARTBEAT_SECONDS
    fanout_class.send(:remove_const, :HEARTBEAT_SECONDS)
    fanout_class.const_set(:HEARTBEAT_SECONDS, 0.1)
    begin
      Sync do
        redis_client = Async::Redis::Client.new(redis_endpoint)
        redis_client.del(STREAM_KEY)

        # One entry with nothing after it: the backlog emits, then the pop
        # timeout must fire the heartbeat comment between events.
        redis_client.xadd(STREAM_KEY, "*", "type", "tick", "data", %({"type":"tick","n":0}))

        _, _, body = get_stream("/ticker")
        chunks = []
        mock_stream = MockStream.new(chunks)

        body_task = Async do
          begin
            body.call(mock_stream)
          rescue
          end
        end

        # Wait for the backlog + a couple of heartbeat cycles.
        sleep 1
        body_task.stop
        body_task.wait rescue nil

        text = chunks.join
        assert_match %("n":0), text
        assert_match ": ping", text, "heartbeat comment must arrive between events"
      ensure
        redis_client&.close
      end
    ensure
      fanout_class.send(:remove_const, :HEARTBEAT_SECONDS)
      fanout_class.const_set(:HEARTBEAT_SECONDS, original)
    end
  end
end
