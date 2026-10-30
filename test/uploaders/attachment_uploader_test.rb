# frozen_string_literal: true

require_relative "../test_helper"

class AttachmentUploaderTest < Minitest::Test
  def conn
    @conn ||= Template::App["db.gateway"].connection
  end

  def setup
    Faker::Internet.unique.clear
    Faker::Number.unique.clear
    conn[:documents].delete
  end

  def documents_repo = Template::Repos::DocumentsRepo.new

  # Storages are configured at uploader load (not via a provider); test env = Memory
  def test_storages_configured_as_memory_in_test
    storages = Template::AttachmentUploader.storages
    assert storages.key?(:cache), "storages missing :cache"
    assert storages.key?(:store), "storages missing :store"
    assert_equal "Shrine::Storage::Memory", storages[:cache].class.name
    assert_equal "Shrine::Storage::Memory", storages[:store].class.name
  end

  # Round-trip: store → persist → reload struct → #attachment → open
  def test_round_trip_store_persist_reload_read
    content = "hello attachment\nline two\n"
    data = Template::AttachmentUploader.store(StringIO.new(content))

    assert_kind_of String, data
    parsed = JSON.parse(data)
    assert parsed.key?("id")
    assert_equal "store", parsed["storage"]

    document = Factory[:document, attachment_data: data]
    reloaded = documents_repo.by_pk(document.id)

    attachment = reloaded.attachment
    refute_nil attachment
    assert_instance_of Template::AttachmentUploader::UploadedFile, attachment

    read_bytes = attachment.open { |io| io.read }
    assert_equal content, read_bytes

    lines = attachment.open { |io| io.each_line.to_a }
    assert_equal ["hello attachment\n", "line two\n"], lines

    assert_equal content.bytesize, attachment.metadata["size"]
  end

  # #attachment is nil when the row carries no uploader JSON
  def test_attachment_nil_when_no_data
    document = Factory[:document]
    reloaded = documents_repo.by_pk(document.id)
    assert_nil reloaded.attachment
  end
end
