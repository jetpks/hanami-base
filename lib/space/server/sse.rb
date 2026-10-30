# frozen_string_literal: true

module Space
  module Server
    # Shared primitives for the SSE transport: resume-cursor parsing, entry-id
    # ordering, and the wire frame format. Redis stream entries are
    # [entry_id, flat_fields] pairs; entry ids are "ms-seq" strings.
    module SSE
      module_function

      # A client's Last-Event-ID — "<anything>:<ms>-<seq>" or bare "<ms>-<seq>"
      # — as the EXCLUSIVE XRANGE start bound "(ms-seq". Absent/unparseable →
      # `default` ("-" replays from the top).
      def entry_bound(last_event_id, default = "-")
        entry_id = last_event_id.to_s.split(":").last
        return default unless entry_id&.match?(/\A\d+-\d+\z/)

        "(#{entry_id}"
      end

      # An entry id as a comparable [ms, seq] tuple, degrading to [0, 0]. The
      # numeric compare is required — a plain string compare is wrong at
      # same-ms seq >= 10 ("1776700000000-9" > "1776700000000-10" as strings,
      # so the string sort would drop -10 behind -9).
      def entry_key(entry_id)
        ms, seq = entry_id.to_s.split("-")
        [Integer(ms, 10), Integer(seq, 10)]
      rescue ArgumentError, TypeError
        [0, 0]
      end

      # One redis stream entry as an SSE event: the raw entry id on `id:` (so a
      # reconnect's Last-Event-ID resumes exactly), the first `data` field on
      # `data:` ("{}" when the entry carries none), blank-line terminated.
      def frame(entry_id, fields)
        data_idx = fields.index("data")
        data = data_idx ? fields[data_idx + 1] : "{}"
        "id: #{entry_id}\ndata: #{data}\n\n"
      end
    end
  end
end

# The acronym constant (SSE) can't ride the app's zeitwerk autoloader — its
# inflector camelizes "sse" to "Sse" — so consumers require this file by path
# (app/stream_action.rb anchors it; the loader's stale :Sse entry stays
# dormant). Fanout is part of the SSE surface, loaded with it.
require_relative "sse/fanout"
