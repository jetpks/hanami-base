# frozen_string_literal: true

module Template
  module Actions
    module Home
      # The template's one example page: root route, rendered through the
      # full inertia + vite chain with no page-local props — the shared
      # props (current_user, flash) already exercise the interesting plumbing.
      class Index < Template::Action
        def handle(req, res)
          render_inertia(req, res, "Home/Index", props: {})
        end
      end
    end
  end
end
