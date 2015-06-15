require 'simplecov'

SimpleCov.profiles.define :gem do
  add_filter '/test/'
  add_filter '/features/'
  add_filter '/spec/'
  add_filter '/autotest/'

  add_group 'Binaries', '/bin/'
  add_group 'Libraries', '/lib/'
  add_group 'Extensions', '/ext/'
  add_group 'Vendor Libraries', '/vendor/'
end

begin
  require 'rails'
rescue LoadError
else
  require 'coveralls'
  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
    SimpleCov::Formatter::HTMLFormatter,
    Coveralls::SimpleCov::Formatter
  ]
end

SimpleCov.start :gem

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'api_helper'

Dir[File.expand_path('../support/**/*.rb', __FILE__)].each { |f| require f }
Dir[File.expand_path('../shared_context/**/*.rb', __FILE__)].each { |f| require f }

require 'byebug'
