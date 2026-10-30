# frozen_string_literal: true

require "async/job/processor/redis"
require "async/redis"
require "async/redis/endpoint"

module Template
  module Jobs
    # The background-jobs example: open the row's attachment, record its byte
    # size and the moment it was processed. The copy-me shape — a job body is
    # a plain object whose #call receives the id carried in the job hash.
    class ProcessDocument
      include Template::Deps["repos.documents_repo"]

      def call(document_id)
        document = documents_repo.by_pk(document_id)
        unless document
          Console.warn(self, "ProcessDocument: document #{document_id} not found")
          return
        end

        attachment = document.attachment
        unless attachment
          Console.warn(self, "ProcessDocument: document #{document_id} has no attachment")
          return
        end

        # Reading the whole file is fine for the example; stream in chunks for
        # real payloads.
        byte_count = attachment.open { |io| io.read.bytesize }
        documents_repo.update(document_id, byte_count: byte_count, processed_at: Time.now)
      rescue => e
        # Log-and-return so async-job's retry-forever dequeue loop (server.rb
        # dequeue rescue → processing_list.retry) never fires for a permanent
        # failure; this example has no status machinery to persist instead.
        Console.error(self, "ProcessDocument failed for id=#{document_id}", exception: e)
      end

      # Build a Processor::Redis for this job type.
      # Used by bin/worker.rb and the queue integration test — same
      # construction in both.
      # parent: nil → Server uses Async::Idler (correct for the long-running
      # worker process); parent: task → Server tasks become children of task
      # (needed in tests for clean teardown).
      def self.build_redis_processor(endpoint: nil, prefix: "jobs", parent: nil)
        ep = endpoint || begin
          url = ENV["REDIS_URL"]
          url ? Async::Redis::Endpoint.parse(url) : Async::Redis.local_endpoint
        end
        opts = {endpoint: ep, prefix: prefix}
        opts[:parent] = parent if parent
        Async::Job::Processor::Redis.new(Delegate.new, **opts)
      end

      # Delegate wired into the async-job processor. Instantiated fresh per
      # processor; routes each job hash to a fresh job body.
      class Delegate
        def call(job)
          ProcessDocument.new.call(job["document_id"])
        end

        def start; end
        def stop; end
      end
    end
  end
end
