# frozen_string_literal: true

module Template
  module Actions
    module Sessions
      class Destroy < Template::Action
        def handle(req, res)
          req.env["rack.session.options"][:renew] = true
          req.session.clear
          res.flash["notice"] = "Signed out."
          res.redirect_to "/"
        end
      end
    end
  end
end
