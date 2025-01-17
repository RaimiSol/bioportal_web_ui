require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module BioportalWebUi
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    config.exceptions_app = self.routes

    config.autoload_paths += %W[#{config.root}/app/lib/kgcl]


    config.settings = config_for :settings
    # Initialize configuration for KGCL change request functionality.
    config.change_request = config_for :change_request

    config.generators.template_engine = :haml
  end
end
