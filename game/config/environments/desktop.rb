require_relative "production"

Rails.application.configure do
  # The desktop build is served only on the loopback interface, without a TLS
  # proxy in front of Puma.
  config.assume_ssl = false
  config.force_ssl = false
  config.public_file_server.enabled = true
  config.hosts = [ "localhost", "127.0.0.1", "::1" ]

  # Installed application files may be read-only. Runtime files live under the
  # per-user data directory selected by bin/desktop.
  if ENV["CGW_DESKTOP_LOG"].present?
    config.logger = ActiveSupport::TaggedLogging.logger(ENV.fetch("CGW_DESKTOP_LOG"))
  end

  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "warn")
end
