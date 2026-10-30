# frozen_string_literal: true

require "rom/factory"
require "faker"

Factory = ROM::Factory.configure do |c|
  c.rom = Space::Server::App["db.rom"]
end

Factory.define(:user) do |f|
  f.github_uid    { Faker::Internet.unique.uuid }
  f.username      { Faker::Internet.unique.username }
  f.name          { Faker::Name.name }
  f.email         { Faker::Internet.unique.email }
  f.avatar_url    { Faker::Internet.url }
  f.created_at    { Time.now }
  f.updated_at    { Time.now }
end

# The attachments example row: unattached and unprocessed by default; the
# uploader's JSON string rides the attachment_data text column.
Factory.define(:document) do |f|
  f.attachment_data { nil }
  f.byte_count      { nil }
  f.processed_at    { nil }
  f.created_at      { Time.now }
  f.updated_at      { Time.now }
end
