# frozen_string_literal: true

require_relative "../test_helper"

# G2: CRUD round-trips and finders on the surviving repo.
class ReposTest < Minitest::Test
  def conn
    @conn ||= Space::Server::App["db.gateway"].connection
  end

  def setup
    Faker::Internet.unique.clear
    Faker::Number.unique.clear
    conn[:users].delete
  end

  def users_repo = Space::Server::Repos::UsersRepo.new

  def make_user(overrides = {})
    Factory[:user, **overrides]
  end

  # --- UsersRepo -----------------------------------------------------------

  def test_users_crud_round_trip
    user = make_user
    assert_kind_of Integer, user.id
    assert_equal user.username, users_repo.by_pk(user.id).username
    # update
    users_repo.update(user.id, name: "Updated Name")
    assert_equal "Updated Name", users_repo.by_pk(user.id).name
    # delete
    users_repo.delete(user.id)
    assert_nil users_repo.by_pk(user.id)
  end

  def test_users_by_github_uid
    user = make_user
    found = users_repo.by_github_uid(user.github_uid)
    refute_nil found
    assert_equal user.id, found.id
  end

  def test_users_by_github_uid_returns_nil_for_unknown
    assert_nil users_repo.by_github_uid("no-such-uid")
  end
end
