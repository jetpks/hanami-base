# frozen_string_literal: true

module Template
  module Actions
    module Ticker
      # The SSE transport's neutral example: a public live feed off redis
      # stream "sse:ticker". Public by design — a minted project's first
      # demo must not require auth credentials; gating is the subclass's
      # job (see StreamAction).
      class Index < Template::StreamAction
        STREAM_KEY = "sse:ticker"

        def handle(req, res)
          render_stream(req, res, key: STREAM_KEY)
        end
      end
    end
  end
end
