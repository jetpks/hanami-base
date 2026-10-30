# frozen_string_literal: true

module Template
  module Relations
    class Documents < Template::DB::Relation
      schema(:documents, infer: true)
    end
  end
end
