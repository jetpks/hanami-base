# frozen_string_literal: true

module Space
  module Server
    module Relations
      class Documents < Space::Server::DB::Relation
        schema(:documents, infer: true)
      end
    end
  end
end
