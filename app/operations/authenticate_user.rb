# frozen_string_literal: true

module Template
  module Operations
    # Find-or-create a User from an OmniAuth auth hash (the provider claims
    # arrive in auth.info; the uid is the stable key). Faithful port of
    # User.from_omniauth from the Rails oracle, minus the org-membership
    # sync — that was domain authz and died with the authorize_user seam.
    class AuthenticateUser
      include Template::Deps["repos.users_repo"]

      def call(auth)
        find_or_create(auth)
      end

      private

      def find_or_create(auth)
        uid  = auth.uid.to_s
        info = auth.info
        now  = Time.now
        attrs = {
          username:   info.nickname,
          name:       info.name,
          email:      info.email,
          avatar_url: info.image,
          updated_at: now
        }

        if (existing = users_repo.by_github_uid(uid))
          users_repo.update(existing.id, attrs)
          users_repo.by_pk(existing.id)
        else
          users_repo.create(attrs.merge(github_uid: uid, created_at: now))
        end
      end
    end
  end
end
