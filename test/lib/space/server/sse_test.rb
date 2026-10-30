# frozen_string_literal: true

require_relative "../../../test_helper"
# The acronym constant can't ride the app autoloader (see the require note in
# lib/space/server/sse.rb) — required by path like every other consumer.
require_relative "../../../../lib/space/server/sse"

class SseTest < Minitest::Test
  SSE = Space::Server::SSE

  # --- entry_bound -------------------------------------------------------------------

  def test_entry_bound_nil_returns_default
    assert_equal "-", SSE.entry_bound(nil)
  end

  def test_entry_bound_bare_id_is_exclusive_bound
    assert_equal "(1776700000000-9", SSE.entry_bound("1776700000000-9")
  end

  def test_entry_bound_prefixed_id_takes_the_tail_after_the_last_colon
    assert_equal "(1776700000000-10", SSE.entry_bound("anything:1776700000000-10")
  end

  def test_entry_bound_junk_returns_default_but_valid_tail_wins
    assert_equal "-", SSE.entry_bound("junk")
    assert_equal "-", SSE.entry_bound("not-an-id")
    assert_equal "(123-0", SSE.entry_bound("x:123-0")
  end

  # --- entry_key ---------------------------------------------------------------------

  def test_entry_key_orders_numerically_at_same_ms
    early = SSE.entry_key("1776700000000-9")
    late  = SSE.entry_key("1776700000000-10")
    assert_equal(-1, early <=> late)
    assert_equal(1, late <=> early)
    # The property the numeric rule exists for: at same-ms seq >= 10 the plain
    # string compare flips the order — the latent drop the tuple fixes.
    assert_operator "1776700000000-10", :<, "1776700000000-9"
  end

  def test_entry_key_orders_across_ms
    assert_equal(1, SSE.entry_key("1776700000001-0") <=> SSE.entry_key("1776700000000-99"))
  end

  def test_entry_key_junk_degrades_to_zero_tuple
    assert_equal [0, 0], SSE.entry_key("junk")
    assert_equal [0, 0], SSE.entry_key(nil)
  end

  # --- frame -------------------------------------------------------------------------

  def test_frame_is_id_data_and_blank_line
    frame = SSE.frame("1776700000000-0", ["type", "tick", "data", %({"type":"tick","n":1})])
    assert_equal "id: 1776700000000-0\ndata: {\"type\":\"tick\",\"n\":1}\n\n", frame
  end

  def test_frame_missing_data_field_defaults_to_empty_object
    assert_equal "id: 1776700000000-0\ndata: {}\n\n", SSE.frame("1776700000000-0", ["type", "tick"])
  end
end
