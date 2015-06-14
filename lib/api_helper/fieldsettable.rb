require 'active_support'
require 'active_support/core_ext/object/blank'

# = Fieldsettable
#
# By making an API fieldsettable, you enables the ability for API clients to
# choose the returned fields of resources with URL query parameters. This is
# really useful for optimizing requests, making API calls more efficient and
# fast.
#
# This design made references to the rules of <em>Sparse Fieldsets</em> in
# <em>JSON API</em>:
# http://jsonapi.org/format/#fetching-sparse-fieldsets
#
# A client can request to get only specific fields in the response by using
# the +fields+ parameter, which is expected to be a comma-separated (",") list
# that refers to the name(s) of the fields to be returned.
#
#   GET /users?fields=id,name,avatar_url
#
# This functionality may also support requests passing in multiple fieldsets
# for several resource at a time (e.g. an included related resource in an field
# of another resource) with <tt>fields[object_type]</tt> parameters.
#
#   GET /posts?fields[posts]=id,title,author&fields[user]=id,name,avatar_url
#
# Note: +author+ of a +post+ is a +user+.
#
# The +fields+ and <tt>fields[object_type]</tt> parameters can not be mixed.
# If the latter format is used, then it must be used for the main resource as
# well.
#
# == Usage
#
# Include this +Concern+ in your Action Controller:
#
#   SamplesController < ApplicationController
#     include APIHelper::Fieldsettable
#   end
#
# or in your Grape API class:
#
#   class SampleAPI < Grape::API
#     helpers APIHelper::Fieldsettable
#   end
#
# Then set fieldset with +fieldset_for+ for each resource in the controller:
#
#   def index
#     fieldset_for :post, default: true, default_fields: [:id, :title, :author]
#     fieldset_for :user, permitted_fields: [:id, :name, :posts, :avatar_url],
#                         defaults_to_permitted_fields: true
#     # ...
#   end
#
# or in the Grape method if you're using Grape:
#
#   resources :posts do
#     get do
#       fieldset_for :post, default: true, default_fields: [:id, :title, :author]
#       fieldset_for :user, permitted_fields: [:id, :name, :posts, :avatar_url],
#                           defaults_to_permitted_fields: true
#       # ...
#     end
#   end
#
# The +fieldset_for+ method used above parses the +fields+ and/or
# <tt>fields[resource_name]</tt> parameters, and save the results into
# +@fieldset+ instance variable for further usage.
#
# After that line, you can use the +fieldset+ helper method to get the fieldset
# information. Actual examples are:
#
# With <tt>GET /posts?fields=title,author</tt>:
#
#   fieldset #=> { post: [:title, :author], user: [:id, :name, :posts, :avatar_url] }
#
# With <tt>GET /posts?fields[post]=title,author&fields[user]=name</tt>:
#
#   fieldset #=> { post: [:title, :author], user: [:name] }
#   fieldset(:post) #=> [:title, :author]
#   fieldset(:post, :title) #=> true
#   fieldset(:user, :avatar_url) #=> false
#
# You can make use of these information while dealing with requests in the
# controller, for example:
#
#   Post.select(fieldset(:post)).find(params[:id])
#
# And return only specified fields in the view, for instance, Jbuilder:
#
#   json.(@post, *fieldset(:post))
#   json.author do
#     json.(@author, *fieldset(:user))
#   end
#
# or RABL:
#
#   # post.rabl
#
#   object @post
#   attributes(*fieldset[:post])
#   child :author do
#     extends 'user'
#   end
#
#   # user.rabl
#
#   object @user
#   attributes(*fieldset[:user])
#
# You can also set properties of fieldset with the +set_fieldset+ helper method
# in the views if you're using a same view across multiple controllers, for
# decreasing code duplication or increasing security. Below is an example with
# RABL:
#
#   object @user
#
#   # this ensures that the +fieldset+ instance variable is least setted with
#   # the default fields, and double filters +permitted_fields+ at view layer -
#   # in case of any things going wrong in the controller
#   set_fieldset :user, default_fields: [:id, :name, :avatar_url],
#                       permitted_fields: [:id, :name, :avatar_url, :posts]
#
#   # determine the fields to show on the fly
#   attributes(*fieldset[:user])
#
module APIHelper::Fieldsettable
  extend ActiveSupport::Concern

  # Gets the fields parameters, organize them into a +@fieldset+ hash for model to select certain.
  # fields and/or templates to render specified fieldset. Following the URL rules of JSON API:
  # http://jsonapi.org/format/#fetching-sparse-fieldsets
  #
  # Params:
  #
  # +resource+::
  #   +Symbol+ name of resource to receive the fieldset
  #
  # +default+::
  #   +Boolean+ should this resource take the parameter from +fields+ while no
  #             resourse name is specified?
  #
  # +permitted_fields+::
  #   +Array+ of +Symbol+s list of accessible fields used to filter out unpermitted fields,
  #   defaults to permit all
  #
  # +default_fields+::
  #   +Array+ of +Symbol+s list of fields to show by default
  #
  # +defaults_to_permitted_fields+::
  #   +Boolean+ if set to true, @fieldset will be set to all permitted_fields
  #   when the current resource's fieldset isn't specified
  #
  # Example Result:
  #
  #     fieldset_for :user, root: true
  #     fieldset_for :group
  #
  #     # @fieldset => {
  #     #                :user => [:id, :name, :email, :groups],
  #     #                :group => [:id, :name]
  #     #              }
  #
  def fieldset_for(resource, default: false,
                             permitted_fields: [],
                             defaults_to_permitted_fields: false,
                             default_fields: [])
    @fieldset ||= ActiveSupport::HashWithIndifferentAccess.new

    # put the fields in place
    if params[:fields].is_a?(Hash)
      # get the specific resource fields from fields hash
      @fieldset[resource] = params[:fields][resource] || params[:fields][resource]
    elsif default
      # or get the fields string directly if this resource is th default one
      @fieldset[resource] = params[:fields]
    end

    # splits the string into array
    if @fieldset[resource].present?
      @fieldset[resource] = @fieldset[resource].split(',').map(&:to_s)
    else
      @fieldset[resource] = default_fields.map(&:to_s)
    end

    if permitted_fields.present?
      permitted_fields = permitted_fields.map(&:to_s)

      # filter out unpermitted fields by intersecting them
      @fieldset[resource] &= permitted_fields if @fieldset[resource].present?

      # set default fields to permitted_fields if needed
      @fieldset[resource] = permitted_fields if @fieldset[resource].blank? &&
                                                defaults_to_permitted_fields
    end
  end

  # Getter for the fieldset data
  #
  # This method will act as a traditional getter of the fieldset data and
  # returns a hash containing fields for each resource if no parameter is
  # provided.
  #
  #   fieldset  # => { 'user' => ['name'], 'post' => ['title', 'author'] }
  #
  # If one parameter - a specific resourse name is passed in, it will return
  # a fields array of that specific resourse.
  #
  #   fieldset(:post)  # => ['title', 'author']
  #
  # And if one more parameter - a field name, is passed in, it will return a
  # boolen, determining if that field should exist in that resource.
  #
  #   fieldset(:post, :title)  # => true
  #
  def fieldset(resource = nil, field = nil)
    # act as a traditional getter if no parameters specified
    if resource.blank?
      @fieldset ||= ActiveSupport::HashWithIndifferentAccess.new

    # returns the fieldset array if an specific resource is passed in
    elsif field.blank?
      fieldset[resource] || []

    # determine if a field is inculded in a specific fieldset
    else
      field = field.to_s
      fieldset(resource).is_a?(Array) && fieldset(resource).include?(field)
    end
  end

  # View Helper to set the default and permitted fields
  #
  # This is useful while using an resource view shared by multiple controllers,
  # it will ensure the +@fieldset+ instance variable presents, and can also set
  # the default fields of a model for convenience, or the whitelisted permitted
  # fields for security.
  def set_fieldset(resource, default_fields: [], permitted_fields: [])
    @fieldset ||= ActiveSupport::HashWithIndifferentAccess.new
    @fieldset[resource] = default_fields.map(&:to_s) if @fieldset[resource].blank?
    @fieldset[resource] &= permitted_fields.map(&:to_s) if permitted_fields.present?
  end

  # Returns the description of the 'fields' URL parameter
  def self.fields_param_desc(example: nil)
    if example.present?
      "Choose the fields to be returned. Example value: '#{example}'"
    else
      "Choose the fields to be returned."
    end
  end

  included do
    if defined? helper_method
      helper_method :fieldset, :set_fieldset
    end
  end
end
