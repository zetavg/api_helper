require 'spec_helper'
require 'json'
require 'byebug'

begin
  require 'grape'
  require 'rack/test'
rescue LoadError
end
