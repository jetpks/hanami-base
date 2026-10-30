# auto_register: false
# frozen_string_literal: true

require "hanami/action"
require "dry/monads"
require "json"
require "inertia_hanami"

module Template
  class Action < Hanami::Action
    include Dry::Monads[:result]
    include InertiaHanami::Action
    include Template::Deps["repos.users_repo"]

    private

    JSON_CONTENT_TYPE = "application/json; charset=utf-8"

    # Session-only lookup. Takes req explicitly; safe when actions are singleton
    # objects (no per-request instance state).
    def current_user(req)
      return nil unless (uid = req.session[:user_id])
      users_repo.by_pk(uid)
    end

    def render_json(res, data, status: 200)
      res.status = status
      res.content_type = JSON_CONTENT_TYPE
      res.body = JSON.generate(data)
    end

    # Set JSON content-type before halting so it survives the throw/catch.
    # Hanami::Action#finish sets res.status+body from the halted tuple but
    # does NOT reset content_type, so this assignment persists.
    def halt_not_found(res)
      res.content_type = JSON_CONTENT_TYPE
      halt 404, JSON.generate(error: "Not found")
    end

    def halt_unprocessable(res, errors)
      res.content_type = JSON_CONTENT_TYPE
      halt 422, JSON.generate(errors: errors)
    end

    # Redirect with a flash message. res.redirect_to calls Halt.call (throw :halt),
    # aborting handle — no separate halt needed after this call.
    def redirect_with_flash(res, to, notice: nil, alert: nil)
      res.flash["notice"] = notice if notice
      res.flash["alert"] = alert if alert
      res.redirect_to(to)
    end

    # redirect_back with flash: uses Referer or fallback URL.
    def redirect_back_with_flash(req, res, fallback:, notice: nil, alert: nil)
      to = req.env["HTTP_REFERER"].to_s
      to = fallback if to.empty?
      redirect_with_flash(res, to, notice: notice, alert: alert)
    end

    # Returns the current user or redirects to / with flash if anonymous.
    def require_login(req, res)
      user = current_user(req)
      redirect_with_flash(res, "/", alert: "Please sign in to continue.") unless user
      user
    end
  end
end
