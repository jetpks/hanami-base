# frozen_string_literal: true

module Template
  module Relations
    class Users < Template::DB::Relation
      schema(:users, infer: true)
    end
  end
end
