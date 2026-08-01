Conduit.configure do |config|
  config.application = "clinical_exchange"

  config.source :ipm,
    username: Rails.application.credentials.dig(:conduit, :ipm, :username),
    password: Rails.application.credentials.dig(:conduit, :ipm, :password)
end

Conduit.on_query do |query|
  Rails.logger.info("[conduit] #{query.to_h}")
end
