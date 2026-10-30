# frozen_string_literal: true

module Space
  module Server
    module Structs
      class Document < Space::Server::DB::Struct
        # The attachment column is the uploader's JSON string; reconstitute it
        # into an UploadedFile (open/each_line/read) — nil when unattached.
        def attachment
          return nil unless attachment_data
          Space::Server::AttachmentUploader.uploaded_file(attachment_data)
        end
      end
    end
  end
end
