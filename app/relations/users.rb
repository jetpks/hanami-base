# frozen_string_literal: true

module Space
  module Server
    module Relations
      class Users < Space::Server::DB::Relation
        schema(:users, infer: true)
      end
    end
  end
end
