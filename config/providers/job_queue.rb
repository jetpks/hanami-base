# frozen_string_literal: true

require "async/job/processor/inline"
require "async/job/processor/redis"
require "async/redis"
require "async/redis/endpoint"

# The queue the actions enqueue onto: Inline (runs the job body in-request) in
# test, the redis processor (a worker process dequeues) otherwise. Both share
# the same Delegate, so the job body is identical either way.
Hanami.app.register_provider(:job_queue) do
  start do
    delegate = Template::Jobs::ProcessDocument::Delegate.new

    processor = if Hanami.env?(:test)
      Async::Job::Processor::Inline.new(delegate)
    else
      Template::Jobs::ProcessDocument.build_redis_processor
    end

    register("job_queue", processor)
  end
end
