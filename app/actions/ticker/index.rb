# frozen_string_literal: true

module Template
  module Actions
    module Ticker
      # The SSE demo's page (the browser-facing half; the stream itself is
      # Stream — EventSource tails GET /ticker/stream). Split from the
      # transport so the Inertia page is actually routable: a single action
      # cannot be both the SSE body and the page, and for the page there is
      # nothing to gate — the feed is public by design.
      class Index < Template::Action
        def handle(req, res)
          render_inertia(req, res, "Ticker/Index", props: {})
        end
      end
    end
  end
end
