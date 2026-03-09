require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Admincenter
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
	config.relative_url_root = "/mywork"
  config.time_zone = "Asia/Ho_Chi_Minh"
    config.middleware.insert_before 0, "Rack::Cors" do
      allow do
        origins '*'
        resource '*', :headers => :any, :methods => [:get, :post, :delete, :put, :patch, :options, :head]
      end
    end

    config.paths.add File.join('app','api'), glob: File.join('**','*.rb')
    config.autoload_paths += Dir[Rails.root.join('app','api','*')]

  end
end
