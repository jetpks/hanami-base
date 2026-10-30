# frozen_string_literal: true

module Template
  module Structs
    class Document < Template::DB::Struct
      # The attachment column is the uploader's JSON string; reconstitute it
      # into an UploadedFile (open/each_line/read) — nil when unattached.
      def attachment
        return nil unless attachment_data
        Template::AttachmentUploader.uploaded_file(attachment_data)
      end
    end
  end
end
