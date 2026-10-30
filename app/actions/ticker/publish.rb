# frozen_string_literal: true

require "json"

module Template
  module Actions
    module Ticker
      # The feed's publisher: INCR the counter, XADD one capped entry onto
      # the stream. The MAXLEN ~ cap bounds demo memory (the capped-XADD
      # idiom this transport was distilled from); the state lives entirely
      # in redis — no schema of its own.
      class Publish < Template::Action
        include Template::Deps["redis"]

        COUNTER_KEY = "sse:ticker:count"
        MAX_ENTRIES = 1_000

        def handle(req, res)
          n = redis.incr(COUNTER_KEY)
          redis.xadd(Index::STREAM_KEY, "MAXLEN", "~", MAX_ENTRIES, "*",
            "type", "tick", "data", JSON.generate(type: "tick", n: n))
          render_json(res, {ok: true, n: n})
        end
      end
    end
  end
end
