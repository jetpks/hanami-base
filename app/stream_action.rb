# auto_register: false
# frozen_string_literal: true

require_relative "../lib/template/sse"

module Template
  # Base class for live SSE actions. Subclasses gate in #handle (auth or
  # anything else) BEFORE calling #render_stream — halting first keeps the
  # error response ordinary JSON; once the SSE headers are set, an error can
  # only surface as a broken stream.
  class StreamAction < Action
    include Template::Deps["redis"]

    protected

    # Streams redis stream `key` as SSE: the transport headers, the backlog
    # (a reconnecting client's Last-Event-ID becomes the exclusive start
    # bound), then the live tail until the client disconnects.
    def render_stream(req, res, key:)
      res.status = 200
      res.headers["content-type"] = "text/event-stream"
      res.headers["cache-control"] = "no-cache"
      res.headers["x-accel-buffering"] = "no"

      start_bound = SSE.entry_bound(req.get_header("HTTP_LAST_EVENT_ID"))
      fanout = SSE::Fanout.for(key, redis)

      # The only streaming hatch in hanami-action 3.0.1: Response#body=
      # special-cases file iterators and otherwise write(str)s — stringifying
      # a Proc — while Rack returns @body verbatim and falcon natively drives
      # proc bodies (|stream| with << and close). Production-proven in the
      # discipline source this transport was distilled from.
      body = proc do |stream|
        # Subscribe FIRST, then xrange the backlog: anything the fanout
        # queues meanwhile is deduped below against the delivered cursor.
        queue = fanout.subscribe
        cursor = nil
        error = nil

        begin
          (redis.xrange(key, start_bound, "+") || []).each do |entry_id, fields|
            cursor = SSE.entry_key(entry_id)
            stream << SSE.frame(entry_id, fields)
          end

          # Live tail. HEARTBEAT_SECONDS is read at pop time (tests swap the
          # constant without redefining the action). The cursor compare is
          # the numeric tuple, never a string compare — see SSE.entry_key.
          loop do
            item = queue.pop(timeout: SSE::Fanout::HEARTBEAT_SECONDS)
            if item.nil?
              stream << ": ping\n\n"
              next
            end

            entry_id, fields = item
            entry = SSE.entry_key(entry_id)
            next if cursor && (entry <=> cursor) <= 0

            cursor = entry
            stream << SSE.frame(entry_id, fields)
          end
        rescue => error
        ensure
          fanout.unsubscribe(queue)
          stream.close(error)
        end
      end

      res.instance_variable_set(:@body, body)
    end
  end
end
