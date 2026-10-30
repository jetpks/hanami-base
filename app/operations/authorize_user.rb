# frozen_string_literal: true

module Template
  module Operations
    # Sign-in authorization seam. The default allows any authenticated
    # identity: a template must round-trip auth out of the box, and
    # deny-by-default would ship a login that always bounces. A project
    # overrides #call — the OmniAuth auth hash carries the provider's own
    # claims (orgs, teams, email domain) — and sessions.create consults this
    # operation between authentication and session creation.
    class AuthorizeUser
      def call(_user, _auth_hash)
        true
      end
    end
  end
end
