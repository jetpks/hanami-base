# frozen_string_literal: true

require_relative "../test_helper"
require "async"
require "async/job/processor/redis"
require "async/redis"
require "async/redis/endpoint"
require "securerandom"

# Queue integration: enqueue → redis → real round-trip → the job body's effect
# lands on the row. Uses the SAME Processor::Redis construction as bin/worker.rb
# via Jobs::ProcessDocument.build_redis_processor(prefix:). No skip branch: the
# suite-boot guard already hard-requires redis, so an unreachable server must
# fail loudly instead of faking the proof.
class JobQueueRedisIntegrationTest < Minitest::Test
  def conn = @conn ||= Template::App["db.gateway"].connection

  def documents_repo = Template::Repos::DocumentsRepo.new

  def setup
    Faker::Internet.unique.clear
    Faker::Number.unique.clear
    conn[:documents].delete
  end

  def test_redis_round_trip_processes_document
    content = "round trip\nsecond line\n"
    data = Template::AttachmentUploader.store(StringIO.new(content))
    document = Factory[:document, attachment_data: data]

    # Unique prefix per run: never collides with a live worker's queue keys
    prefix = "jobs-test-#{SecureRandom.hex(8)}"

    Sync do |task|
      # Build the server without parent: — @parent = Async::Idler, which
      # resolves Task.current at spawn time. Since server.start is called from
      # inside server_task below, ALL server sub-tasks (dequeue loop,
      # delayed-jobs bg, processing-list bg) become children of server_task's
      # inner fiber.
      server = Template::Jobs::ProcessDocument.build_redis_processor(prefix: prefix)

      # Enqueue before starting the server (a pure redis write — no tasks needed)
      server.call({"document_id" => document.id})

      # server_task owns all server sub-tasks. Stopping it tears down:
      #   - the delayed-jobs background loop (child of the inner task)
      #   - the processing-list heartbeat loop (child of the inner task)
      #   - the main dequeue loop (Idler resolves Task.current → inner task at spawn)
      server_task = task.async do
        server.start
        sleep(Float::INFINITY)  # keep alive; server_task.stop raises Async::Stop here
      end

      begin
        # 15-second backstop: TimeoutError aborts everything and the test fails
        # with a clear message if the job body never runs.
        task.with_timeout(15) do
          loop do
            sleep(0.1)
            break if documents_repo.by_pk(document.id)&.processed_at
          end
        end
      ensure
        # Stop server_task and all its children — guaranteed cleanup regardless
        # of whether the block completed normally or timed out.
        server_task.stop
      end
    end

    reloaded = documents_repo.by_pk(document.id)
    assert_equal content.bytesize, reloaded.byte_count,
      "expected the stored content's byte size after the redis round-trip"
    refute_nil reloaded.processed_at
  end
end
