# frozen_string_literal: true

require_relative "../test_helper"

# Relations load with schema inferred from the distilled users table.
class RelationsTest < Minitest::Test
  def rom
    @rom ||= Template::App["db.rom"]
  end

  def conn
    @conn ||= Template::App["db.gateway"].connection
  end

  def setup
    conn[:users].delete
  end

  def test_users_relation_queryable
    assert_kind_of Array, rom.relations[:users].to_a
  end

  def test_users_schema_includes_auth_columns
    attrs = rom.relations[:users].schema.map(&:name)
    assert_includes attrs, :github_uid
    assert_includes attrs, :username
    assert_includes attrs, :avatar_url
  end
end
