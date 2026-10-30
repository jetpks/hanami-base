# frozen_string_literal: true

module Space
  module Server
    module Actions
      module Documents
        # The attachments example's upload endpoint: persist the file through
        # the uploader, then enqueue the background job that processes it. In
        # test the queue is Inline, so the row comes back processed.
        class Create < Space::Server::Action
          include Space::Server::Deps[
            "repos.documents_repo",
            "job_queue"
          ]

          def handle(req, res)
            require_login(req, res)

            # Rack parses a multipart file part into a symbol-keyed Hash
            # ({filename:, type:, name:, tempfile:, head:}). Hanami::Action's
            # params object deep-symbolizes the top-level keys too
            # (hanami-action params.rb), so the part arrives at :file — anything
            # there that is not a Hash with a tempfile is not an upload.
            file_param = req.params[:file]
            unless file_param.is_a?(Hash) && file_param[:tempfile]
              halt_unprocessable(res, {file: ["must be a file upload"]})
            end

            data = AttachmentUploader.store(file_param[:tempfile])

            now = Time.now
            document = documents_repo.create(
              attachment_data: data,
              created_at: now,
              updated_at: now
            )

            job_queue.call({"document_id" => document.id})
            render_json(res, {ok: true, id: document.id}, status: 201)
          end
        end
      end
    end
  end
end
