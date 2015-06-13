require 'spec_helper'

require 'rails'
require 'action_controller/railtie'
require 'rspec/rails'
require 'byebug'

module TestRailsApp
  class Application < Rails::Application
    config.secret_token = SecureRandom.hex
    config.secret_key_base = SecureRandom.hex
  end

  class ApplicationController < ActionController::Base
    extend RSpec::Rails::ControllerExampleGroup::BypassRescue
    include Rails.application.routes.url_helpers
  end
end
