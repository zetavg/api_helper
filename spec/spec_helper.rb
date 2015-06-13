$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'api_helper'

Dir[File.expand_path('../support/**/*.rb', __FILE__)].each { |f| require f }
Dir[File.expand_path('../shared_context/**/*.rb', __FILE__)].each { |f| require f }

require 'byebug'
