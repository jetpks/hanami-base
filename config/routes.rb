# frozen_string_literal: true

module Template
  class Routes < Hanami::Routes
    mount HanamiHealthcheck::Endpoint.new, at: "/up"

    # Auth — OmniAuth callback (GET for redirect, POST for form submission)
    get  "/auth/:provider/callback", to: "sessions.create"
    post "/auth/:provider/callback", to: "sessions.create"
    get  "/auth/failure",            to: "sessions.failure"

    # Logout — both GET (link) and DELETE (form)
    get    "/logout", to: "sessions.destroy"
    delete "/logout", to: "sessions.destroy"

    # The SSE transport's neutral example: a public live feed + its publisher
    get  "/ticker",          to: "ticker.index"
    post "/ticker/publish", to: "ticker.publish"

    # The attachments example: upload → persist → enqueue for processing
    post "/documents", to: "documents.create"

    # The template's one example page
    root to: "home.index"
  end
end
