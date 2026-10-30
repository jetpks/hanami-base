# frozen_string_literal: true

require_relative "action_test_helper"

# The attachments example end-to-end: multipart upload → storage → text column
# → queue → job body. In test the queue is the Inline processor, so the row is
# processed by the time the response is back. The Inline processor schedules
# through Async::Idler, which needs a running reactor — the upload POSTs run
# inside Sync (the same shape collect_sse_chunks uses for streaming bodies).
class DocumentsTest < Minitest::Test
  include ActionTestHelper

  CONTENT = "one\nuploaded through the chain\nthree\n"

  def setup
    setup_db
    Space::Server::App["db.gateway"].connection[:documents].delete
    OmniAuth.config.test_mode = true
  end

  def teardown
    OmniAuth.config.mock_auth[:github] = :csrf_detected
  end

  def mock_callback(uid: "11", username: "uploader")
    OmniAuth.config.mock_auth[:github] = OmniAuth::AuthHash.new(
      provider: "github",
      uid: uid,
      info: {nickname: username, name: username.capitalize, email: "#{username}@example.com", image: nil},
      credentials: nil
    )
    post("/auth/github/callback")
  end

  def documents_repo = Space::Server::Repos::DocumentsRepo.new

  def test_upload_creates_row_and_processes_it_inline
    _, headers, = mock_callback
    @session_cookie = headers["set-cookie"]&.split(";")&.first

    status, _, body = nil
    Sync do
      status, _, body = post_multipart("/documents", file: {filename: "notes.txt", content: CONTENT})
    end

    assert_equal 201, status
    payload = parse_json(body)
    assert_equal true, payload["ok"]

    document = documents_repo.by_pk(payload["id"])
    parsed = JSON.parse(document.attachment_data)
    assert parsed.key?("id")
    assert_equal "store", parsed["storage"]

    # The Inline queue ran the job body during the request
    refute_nil document.processed_at
    assert_equal CONTENT.bytesize, document.byte_count
  end

  def test_upload_without_a_file_part_is_unprocessable
    _, headers, = mock_callback
    @session_cookie = headers["set-cookie"]&.split(";")&.first

    status, _, body = Sync do
      post("/documents")
    end

    assert_equal 422, status
    assert_equal ["must be a file upload"], parse_json(body)["errors"]["file"]
    assert_equal 0, Space::Server::App["db.gateway"].connection[:documents].count
  end

  def test_anonymous_upload_redirects_without_creating_a_row
    status, headers, = post_multipart("/documents", file: {filename: "notes.txt", content: CONTENT})

    assert_equal 302, status
    assert_equal "/", headers["location"]
    assert_equal 0, Space::Server::App["db.gateway"].connection[:documents].count
  end
end
