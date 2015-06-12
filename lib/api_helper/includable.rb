require 'active_support'

# = Helper To Make Resource APIs Includable
#
# Inclusion of related resource lets your API return resources related to the
# primary data. This endpoint will support an +include+ request parameter to
# allow the client to customize which related resources should be returned.
#
# This design made references to the rules of <em>Inclusion of Related
# Resources</em> in <em>JSON API</em>:
# http://jsonapi.org/format/#fetching-includes
#
# For instance, comments could be requested with articles:
#
#   GET /articles?include=comments
#
# The server will respond
#
#   [
#     {
#       "id": 1,
#       "title": "First Post",
#       "content": "...",
#       "comments": [
#         {
#           "id": 1,
#           "content": "..."
#         },
#         {
#           "id": 3,
#           "content": "..."
#         },
#         {
#           "id": 6,
#           "content": "..."
#         }
#       ]
#     },
#     {
#       "id": 2,
#       "title": "Second Post",
#       "content": "...",
#       "comments": [
#         {
#           "id": 2,
#           "content": "..."
#         },
#         {
#           "id": 4,
#           "content": "..."
#         },
#         {
#           "id": 5,
#           "content": "..."
#         }
#       ]
#     }
#   ]
#
# instead of just:
#
#   [
#     {
#       "id": 1,
#       "title": "First Post",
#       "content": "...",
#       "comments": [1, 3, 6]
#     },
#     {
#       "id": 2,
#       "title": "Second Post",
#       "content": "...",
#       "comments": [2, 4, 5]
#     }
#   ]
#
# If requesting multiple related resources is needed, they can be stated in a
# comma-separated list:
#
#   GET /articles/12?include=author,comments
#
# == Usage
#
# Include this +Concern+ in your Action Controller:
#
#   SamplesController < ApplicationController
#     include APIHelper::Includable
#   end
#
# or in your Grape API class:
#
#   class SampleAPI < Grape::API
#     include APIHelper::Includable
#   end
#
# then set the options for the inclusion in the grape method:
#
#   resources :posts do
#     get do
#       inclusion_for :post, root: true
#       # ...
#     end
#   end
#
# This helper parses the +include+ and <tt>include[object_type]</tt> parameters to
# determine what the API caller wants, and save the results into instance
# variables for further usage.
#
# After this you can use the +inclusion+ helper method to get the inclusion data
# that the request specifies, and do something like this in your controller:
#
#   resource = resource.includes(:author) if inclusion(:post, :author)
#
# The +inclusion+ helper method returns data like this:
#
#   inclusion #=> { post: [:author] }
#   inclusion(:post) #=> [:author]
#   inclusion(:post, :author) #=> true
#
# === API View with RABL
#
# If you're using RABL as the API view, it can be setup like this:
#
#   # set the includable and default inclusion fields of the view
#   set_inclusion :post, default_includes: [:author]
#
#   # set the details for all includable fields
#   set_inclusion_field :post, :author, :author_id
#
#   # extends the partial to show included fields
#   extends('extensions/includable_childs', locals: { self_resource: :post })
module APIHelper::Includable
  extend ActiveSupport::Concern

  # Gets the include parameters, organize them into a +@inclusion+ hash for model to use
  # inner-join queries and/or templates to render relation attributes included.
  # Following the URL rules of JSON API:
  # http://jsonapi.org/format/#fetching-includes
  #
  # Params:
  #
  # +resource+::
  #   +Symbol+ name of resource to receive the inclusion
  def inclusion_for(resource, root: false, default_includes: [])
    @inclusion ||= ActiveSupport::HashWithIndifferentAccess.new
    @meta ||= ActiveSupport::HashWithIndifferentAccess.new

    # put the includes in place
    if params[:include].is_a? Hash
      @inclusion[resource] = params[:include][resource] || params[:include][resource]
    elsif root
      @inclusion[resource] = params[:include]
    end

    # splits the string into array of symbles
    @inclusion[resource] = @inclusion[resource] ? @inclusion[resource].split(',').map(&:to_sym) : default_includes
  end

  # View Helper to set the inclusion and default_inclusion.
  def set_inclusion(resource, default_includes: [])
    @inclusion ||= {}
    @inclusion_field ||= {}
    @inclusion[resource] = default_includes if @inclusion[resource].blank?
  end

  # View Helper to set the inclusion details.
  def set_inclusion_field(self_resource, field, id_field, class_name: nil, url: nil)
    return if (@fieldset.present? && @fieldset[self_resource].present? && !@fieldset[self_resource].include?(field))

    @inclusion_field ||= {}
    @inclusion_field[self_resource] ||= []
    field_data = {
      field: field,
      id_field: id_field,
      class_name: class_name,
      url: url
    }
    @inclusion_field[self_resource] << field_data
    @fieldset[self_resource].delete(field) if @fieldset[self_resource].present?
  end

  # Getter for the inclusion data.
  def inclusion(resource = nil, field = nil)
    if resource.blank?
      @inclusion ||= {}
    elsif field.blank?
      (@inclusion ||= {})[resource] ||= []
    else
      return false if (try(:fieldset, resource).present? && !fieldset(resource, field))
      inclusion(resource).include?(field)
    end
  end

  # Return the 'include' param description
  def self.include_param_desc(example: nil, default: nil)
    if default.present?
      desc = "Returning compound documents that include specific associated objects, defaults to '#{default}'."
    else
      desc = "Returning compound documents that include specific associated objects."
    end
    if example.present?
      "#{desc} Example value: '#{example}'"
    else
      desc
    end
  end
end
