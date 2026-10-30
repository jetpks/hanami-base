# frozen_string_literal: true

require_relative "../test_helper"

# The job body and the provider seam: under test env the container's queue is
# the Inline processor, and a call runs the job body in-request.
class ProcessDocumentTest < Minitest::Test
  def conn
    @conn ||= Template::App["db.gateway"].connection
  end

  def setup
    Faker::Internet.unique.clear
    Faker::Number.unique.clear
    conn[:documents].delete
  end

  def documents_repo = Template::Repos::DocumentsRepo.new

  def test_provider_resolves_inline_and_runs_the_job_body
    queue = Template::App["job_queue"]
    assert_instance_of Async::Job::Processor::Inline, queue

    content = "count my bytes\n"
    data = Template::AttachmentUploader.store(StringIO.new(content))
    document = Factory[:document, attachment_data: data]

    # Inline schedules through Async::Idler, so the call needs a reactor
    Sync do
      queue.call({"document_id" => document.id})
    end

    reloaded = documents_repo.by_pk(document.id)
    assert_equal content.bytesize, reloaded.byte_count
    refute_nil reloaded.processed_at
  end

  # Unknown id: warn and return — nothing written, nothing raised
  def test_unknown_id_warns_and_returns
    Template::Jobs::ProcessDocument.new.call(999_999_999)
    assert_equal 0, conn[:documents].count
  end

  # Attachmentless row: warn and return — the row stays unprocessed
  def test_document_without_attachment_warns_and_returns
    document = Factory[:document]
    Template::Jobs::ProcessDocument.new.call(document.id)

    reloaded = documents_repo.by_pk(document.id)
    assert_nil reloaded.processed_at
    assert_nil reloaded.byte_count
  end
end
