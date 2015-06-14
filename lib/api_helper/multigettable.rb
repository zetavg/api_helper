require 'active_support'

# = Multigettable
#
# A normal RESTful API can let clients get one specified resource at a time:
#
#   GET /posts/3
#
# If it's declared to be multigettable, then clients can get multiple
# specified resource like this:
#
#   GET /posts/3,4,8,9
#
# An API may also support applying operations on multiple resource sith a
# single request using this approach
#
#   PATCH /posts/3,4,8,9
#   DELETE /posts/3,4,8,9
#
# == Usage
#
# Include this +Concern+ in your Action Controller:
#
#   SamplesController < ApplicationController
#     include APIHelper::Multigettable
#   end
#
# or in your Grape API class:
#
#   class SampleAPI < Grape::API
#     helpers APIHelper::Multigettable
#   end
#
# then use the +multiget+ method like this:
#
#   @post = multiget(Post, find_by: :id, param: :id, max: 12)
#
# <em>The +multiget+ method returns an collection of or a single model, based
# directly from the requested URL.</em>
#
# There is also another helper method to determine whether the request is
# multigeting or not:
#
#   multiget?(param: id)  # => true of false
#
module APIHelper::Multigettable
  extend ActiveSupport::Concern

  # Get multiple resources from the request by specifing ids split by ','
  #
  # Params:
  #
  # +resource+::
  #   +ActiveRecord::Relation+ resource collection to find resources from
  #
  # +find_by+::
  #   +Symbol+ the attribute that is used to find resources, defaults to :id
  #
  # +param+::
  #   +Symbol+ the request parameter name used to find resources,
  #   defaults to :id
  #
  # +max+::
  #   +Integer+ maxium count of returning results
  #
  def multiget(resource, find_by: :id, param: :id, max: 10)
    ids = params[param].split(',')
    ids = ids[0..(max - 1)]

    if ids.count > 1
      resource.where(find_by => ids)
    else
      resource.find_by(find_by => ids[0])
    end
  end

  # Is the a multiget request?
  def multiget?(param: :id)
    params[param].present? && params[param].include?(',')
  end
end
