# frozen_string_literal: true

module Template
  module Actions
    module Sessions
      # OmniAuth provider callback. OmniAuth's request-phase (POST /auth/:provider)
      # already guards CSRF via the shared `_csrf_token` validation phase wired in
      # config/app.rb. This action must be OUT of Hanami Action CSRF because the
      # callback POST carries OmniAuth's own token, not Hanami's _csrf_token.
      class Create < Template::Action
        include Template::Deps["operations.authenticate_user", "operations.authorize_user"]

        def handle(req, res)
          auth = req.env["omniauth.auth"]

          unless auth
            res.redirect_to "/auth/failure?message=omniauth_error"
            return
          end

          user = authenticate_user.call(auth)

          # Authorization seam: the default (AuthorizeUser) allows any
          # authenticated identity; a project overrides that operation to plug
          # its own rule. A denial must NOT create a session.
          unless authorize_user.call(user, auth)
            res.flash["alert"] = "Not authorized."
            res.redirect_to "/"
            return
          end

          # Session fixation guard: :renew tells Rack::Session to delete the old
          # session and generate a new ID before committing.
          req.env["rack.session.options"][:renew] = true
          req.session.clear
          req.session[:user_id] = user.id

          res.flash["notice"] = "Signed in as #{user.username}."
          res.redirect_to "/"
        end

        private

        def verify_csrf_token?(*, **)
          false
        end
      end
    end
  end
end
