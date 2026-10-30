#!/usr/bin/env ruby
# frozen_string_literal: true

ENV["HANAMI_ENV"] ||= "test"

# In-process boot + route-resolve smoke.
# Usage: bundle exec ruby bin/http_smoke.rb
# Exit 0 = PASS; exit 1 = FAIL (error printed to stderr)
#
# The important invariant: no route returns 5xx.

require "hanami/boot"
require "rack/mock"

INERTIA_GET_PATHS = %w[/].freeze

def smoke_call(verb, path)
  env = Rack::MockRequest.env_for(path, "REQUEST_METHOD" => verb)
  if verb == "GET" && INERTIA_GET_PATHS.include?(path)
    env["HTTP_X_INERTIA"] = "true"
    env["HTTP_X_INERTIA_VERSION"] = Space::Server::App["vite"].digest
  end
  Space::Server::App.call(env)
end

failures = []

# Routes that must NOT 5xx
ANON_ROUTES = [
  ["GET",    "/up"],
  ["GET",    "/auth/github/callback"],
  ["POST",   "/auth/github/callback"],
  ["GET",    "/auth/failure"],
  ["GET",    "/logout"],
  ["DELETE", "/logout"],
  ["GET",    "/"],
].freeze

ANON_ROUTES.each do |verb, path|
  begin
    status, _, _ = smoke_call(verb, path)
    if status >= 500
      failures << "#{verb} #{path} → #{status} (server error)"
    end
  rescue => e
    failures << "#{verb} #{path} → #{e.class}: #{e.message}"
  end
end

# GET / must return 200 (the example page)
root_status, root_headers, root_body = smoke_call("GET", "/")
unless root_status == 200
  failures << "GET / → expected 200, got #{root_status}"
end

# GET /up must return 200
up_status, _, _ = smoke_call("GET", "/up")
unless up_status == 200
  failures << "GET /up → expected 200, got #{up_status}"
end

if failures.empty?
  puts "SMOKE OK — #{ANON_ROUTES.size} routes resolved, GET / → #{root_status}, GET /up → #{up_status}"
  exit 0
else
  $stderr.puts "SMOKE FAIL:"
  failures.each { |f| $stderr.puts "  - #{f}" }
  exit 1
end
