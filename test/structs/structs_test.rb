# frozen_string_literal: true

require_relative "../test_helper"

# Structs: the users repo materializes rows as the DB::Struct base (the
# per-table struct subclasses died with their tables).
class StructsTest < Minitest::Test
  def conn
    @conn ||= Space::Server::App["db.gateway"].connection
  end

  def setup
    Faker::Internet.unique.clear
    Faker::Number.unique.clear
    conn[:users].delete
  end

  def users_repo = Space::Server::Repos::UsersRepo.new

  def test_user_struct_class
    user  = Factory[:user]
    found = users_repo.by_pk(user.id)
    # No authored struct subclass survives; ROM's auto-generated struct carries
    # the row (its class name still lands in the Structs namespace).
    assert_kind_of ROM::Struct, found
    assert_equal user.username, found.username
  end
end
