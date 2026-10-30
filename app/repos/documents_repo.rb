# frozen_string_literal: true

module Space
  module Server
    module Repos
      class DocumentsRepo < Space::Server::DB::Repo
        def by_pk(id)
          documents.by_pk(id).one
        end

        def create(attrs)
          documents.command(:create).call(attrs)
        end

        def update(id, attrs)
          documents.by_pk(id).command(:update).call(attrs)
        end
      end
    end
  end
end
