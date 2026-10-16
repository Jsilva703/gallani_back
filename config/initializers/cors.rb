allowed_origins = ENV.fetch(
  "FRONTEND_ORIGIN",
  Rails.env.development? ? "http://localhost:5178" : ""
).split(",").map(&:strip).reject(&:empty?)

if allowed_origins.any?
  Rails.application.config.middleware.insert_before 0, Rack::Cors do
    allow do
      origins(*allowed_origins)

      resource "/api/*",
               headers: :any,
               methods: %i[get post put patch delete options head]
    end
  end
end