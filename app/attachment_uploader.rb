# auto_register: false
# frozen_string_literal: true

require "shrine"
require "shrine/storage/file_system"
require "shrine/storage/memory"

# Storages are configured at class load (not via a provider) so Hanami.env? is
# the single switch: in-memory in test (no disk, no cleanup), file-system in
# dev/prod.
if Hanami.env?(:test)
  Shrine.storages = {
    cache: Shrine::Storage::Memory.new,
    store: Shrine::Storage::Memory.new
  }
else
  # Resolve from __dir__ so the path is cwd-invariant (mirrors config/providers/vite.rb).
  # __dir__ = <app root>/app → parent = <app root>
  root = Pathname(__dir__).parent
  Shrine.storages = {
    cache: Shrine::Storage::FileSystem.new(root.join("storage", "cache").to_s),
    store: Shrine::Storage::FileSystem.new(root.join("storage", "store").to_s)
  }
end

module Space
  module Server
    # The attachments skeleton. Store returns the JSON string a text column
    # carries; `uploaded_file` reconstitutes it (see Structs::Document#attachment).
    class AttachmentUploader < Shrine
      def self.store(io) = upload(io, :store).to_json
    end
  end
end
