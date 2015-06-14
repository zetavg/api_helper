require 'active_support'

# = Includable
#
# Inclusion lets your API returns not only the data of the primary resource,
# but also resources that have relation to it. Includable APIs will also
# support customising the resources included using the +include+ parameter.
#
# This design made references to the rules of <em>Inclusion of Related
# Resources</em> in <em>JSON API</em>:
# http://jsonapi.org/format/#fetching-includes
#
# For instance, articles can be requested with their comments along:
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
# instead of just the ids of each comment
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
# Multiple related resources can be stated in a comma-separated list,
# like this:
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
#     helpers APIHelper::Includable
#   end
#
# Then setup inclusion with +inclusion_for+ in the controller:
#
#   def index
#     inclusion_for :post, default: true
#     # ...
#   end
#
# or in the Grape method if you're using it:
#
#   resources :posts do
#     get do
#       inclusion_for :post, default: true
#       # ...
#     end
#   end
#
# This helper parses the +include+ and/or <tt>include[resource_name]</tt>
# parameters and saves the results into +@inclusion+ for further usage.
#
# +Includable+ integrates with +Fieldsettable+ if used together, by:
#
# * Sliceing the included fields that dosen't appears in the fieldset - since
#   the included resoure(s) are actually fields under the primary resorce,
#   fieldset will be in charged to determine the fields to show. Thus, fields
#   will be totally ignored if they aren't appeared in the fieldset, regardless
#   if they are included or not.
#
# So notice that +inclusion_for+ should be set after +fieldset_for+ if both are
# used!
#
# After that +inclusion_for ...+ line, you can use the +inclusion+ helper
# method to get the inclusion data of each request, and do something like this
# in your controller:
#
#   @posts = Post.includes(inclusion(:post))
#
# The +inclusion+ helper method will return data depending on the parameters
# passed in, as the following example:
#
#   inclusion  # => { 'post' => ['author'] }
#   inclusion(:post)  # => ['author']
#   inclusion(:post, :author)  # => true
#
# And don't forget to set your API views or serializers with the help of
# +inclusion+ to provide dynamic included resources!
#
# === API View with RABL
#
# If you're using RABL as the API view, it can be setup like this:
#
#   object @post
#
#   # set the includable and default inclusion fields of the view
#   set_inclusion :post, default_includes: [:author]
#
#   # set the details for all includable fields
#   set_inclusion_field :post, :author, :author_id
#   set_inclusion_field :post, :comments, :comment_ids
#
#   # extends the partial to show included fields
#   extends('extensions/includable_childs', locals: { self_resource: :post })
#
# --
# TODO: provide an example of includable_childs.rabl
# ++
#
module APIHelper::Includable
  extend ActiveSupport::Concern

  # Gets the include parameters, organize them into a +@inclusion+ hash
  #
  # Params:
  #
  # +resource+::
  #   +Symbol+ name of resource to receive the inclusion
  #
  # +default+::
  #   +Boolean+ should this resource take the parameter from +include+ while no
  #             resourse name is specified?
  #
  # +permitted_includes+::
  #   +Array+ of +Symbol+s list of includable fields, permitting all by default
  #
  # +default_includes+::
  #   +Array+ of +Symbol+s list of fields to be included by default
  #
  # +defaults_to_permitted_includes+::
  #   +Boolean+ if set to true, +@inclusion+ will be set to all
  #   permitted_includes when the current resource's included fields
  #   isn't specified
  #
  def inclusion_for(resource, default: false,
                              permitted_includes: [],
                              defaults_to_permitted_includes: false,
                              default_includes: [])
    @inclusion ||= ActiveSupport::HashWithIndifferentAccess.new
    @inclusion_specified ||= ActiveSupport::HashWithIndifferentAccess.new

    # put the fields in place
    if params[:include].is_a?(Hash)
      # get the specific resource inclusion fields from the "include" hash
      @inclusion[resource] = params[:include][resource]
      @inclusion_specified[resource] = true if params[:include][resource].present?
    elsif default
      # or get the "include" string directly if this resource is th default one
      @inclusion[resource] = params[:include]
      @inclusion_specified[resource] = true if params[:include].present?
    end

    # splits the string into array
    if @inclusion[resource].present?
      @inclusion[resource] = @inclusion[resource].split(',').map(&:to_s)
    elsif !@inclusion_specified[resource]
      @inclusion[resource] = default_includes.map(&:to_s)
    end

    if permitted_includes.present?
      permitted_includes = permitted_includes.map(&:to_s)

      # filter out unpermitted includes by intersecting them
      @inclusion[resource] &= permitted_includes if @inclusion[resource].present?

      # set default inclusion to permitted_includes if needed
      @inclusion[resource] = permitted_includes if @inclusion[resource].blank? &&
                                                   defaults_to_permitted_includes &&
                                                   !@inclusion_specified[resource]
    end

    if @fieldset.is_a?(Hash) && @fieldset[resource].present?
      @inclusion[resource] &= @fieldset[resource]
    end
  end

  # Getter for the inclusion data
  #
  # This method will act as a traditional getter of the inclusion data and
  # returns a hash containing fields for each resource if no parameter is
  # provided.
  #
  #   inclusion  # => { 'post' => ['author', 'comments'] }
  #
  # If one parameter - a specific resourse name is passed in, it will return an
  # array of relation names that should be included for that specific resourse.
  #
  #   inclusion(:post)  # => ['author', 'comments']
  #
  # And if one more parameter - a field name, is passed in, it will return a
  # boolen, determining if that relation should be included in the response.
  #
  #   inclusion(:post, :author)  # => true
  #
  def inclusion(resource = nil, field = nil)
    # act as a traditional getter if no parameters specified
    if resource.blank?
      @inclusion ||= ActiveSupport::HashWithIndifferentAccess.new

    # returns the inclusion array if an specific resource is passed in
    elsif field.blank?
      inclusion[resource] || []

    # determine if a field is inculded
    else
      field = field.to_s
      inclusion(resource).is_a?(Array) && inclusion(resource).include?(field)
    end
  end

  # View Helper to set the inclusion
  #
  # This is useful while using an resource view shared by multiple controllers,
  # this will ensure the +@inclusion+ instance variable presents, and can also
  # set the default included fields of a model for convenience, or the fields
  # that are permitted to be included for security.
  def set_inclusion(resource, default_includes: [], permitted_includes: [])
    @inclusion ||= ActiveSupport::HashWithIndifferentAccess.new
    @inclusion_field ||= ActiveSupport::HashWithIndifferentAccess.new
    @inclusion[resource] = default_includes.map(&:to_s) if @inclusion[resource].blank? &&
                                                           !@inclusion_specified[resource]
    @inclusion[resource] &= permitted_includes.map(&:to_s) if permitted_includes.present?
  end

  # View Helper to set the inclusion details
  #
  # Params:
  #
  # +resource+::
  #   +Symbol+ name of the resource to receive the inclusion field data
  #
  # +field+::
  #   +Symbol+ the field name of the relatiion that can be included
  #
  # +id_field+::
  #   +Symbol+ the field to use (normally suffixed with "_id") if the object
  #   isn't included
  #
  # +resource_name+::
  #   +Symbol+ the name of the child resource, can be used to determine which
  #   view template should be extended for rendering that child node and also
  #   can shown in the response metadata as well
  #
  # +resources_url+::
  #   +String+ the resources URL of the child resource, can be used to be shown
  #   in the metadata for the clients' convenience to learn ablou the API
  #
  def set_inclusion_field(resource, field, id_field, resource_name: nil,
                                                     resources_url: nil)
    @inclusion_field ||= ActiveSupport::HashWithIndifferentAccess.new
    @inclusion_field[resource] ||= ActiveSupport::HashWithIndifferentAccess.new
    @inclusion_field[resource][field] = {
      field: field,
      id_field: id_field,
      resource_name: resource_name,
      resources_url: resources_url
    }
  end

  # Returns the description of the 'include' URL parameter
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

  included do
    if defined? helper_method
      helper_method :inclusion, :set_inclusion, :set_inclusion_field
    end
  end
end
