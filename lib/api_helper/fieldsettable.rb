require 'active_support'

# = Helper To Make Resource APIs Fieldsettable
#
# By making an API fieldsettable, you let API callers to choose the fields they
# wanted to be returned with query parameters. This is really useful for making
# API calls more efficient and fast.
#
# This design made references to the rules of <em>Sparse Fieldsets</em> in
# <em>JSON API</em>:
# http://jsonapi.org/format/#fetching-sparse-fieldsets
#
# A client can request that an API endpoint return only specific fields in the
# response by including a +fields+ parameter, which is a comma-separated (",")
# list that refers to the name(s) of the fields to be returned.
#
#   GET /users?fields=id,name,avatar_url
#
# This functionality may also support requests specifying multiple fieldsets
# for several objects at a time (e.g. another object included in an field of
# another object) with <tt>fields[object_type]</tt> parameters.
#
#   GET /posts?fields[posts]=id,title,author&fields[user]=id,name,avatar_url
#
# Note: +author+ of a +post+ is a +user+.
#
# The +fields+ and <tt>fields[object_type]</tt> parameters can not be mixed.
# If the latter format is used, then it must be used for the main object as well.
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
#     include APIHelper::Fieldsettable
#   end
#
# then set the options for the fieldset in the grape method:
#
#   resources :posts do
#     get do
#       fieldset_for :post, root: true, default_fields: [:id, :title, :author]
#       fieldset_for :user, permitted_fields: [:id, :name, :posts, :avatar_url],
#                           show_all_permitted_fields_by_default: true
#       # ...
#     end
#   end
#
# This helper parses the +fields+ and <tt>fields[object_type]</tt> parameters to
# determine what the API caller wants, and save the results into instance
# variables for further usage.
#
# After this you can use the +fieldset+ helper method to get the fieldset data
# that the request specifies.
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
# You can make use of the information while dealing with requests, for example:
#
#   Post.select(fieldset(:post))...
#
# If you're using RABL as the API view, it can be also setup like this:
#
#   object @user
#
#   # this ensures the +fieldset+ instance variable is least setted with
#   # the default fields, and double check +permitted_fields+ at view layer -
#   # in case of things going wrong in the controller
#   set_fieldset :user, default_fields: [:id, :name, :avatar_url],
#                       permitted_fields: [:id, :name, :avatar_url, :posts]
#
#   # determine the fields to show on the fly
#   attributes(*fieldset[:user])
module APIHelper::Fieldsettable
  extend ActiveSupport::Concern

  # Gets the fields parameters, organize them into a +@fieldset+ hash for model to select certain
  # fields and/or templates to render specified fieldset. Following the URL rules of JSON API:
  # http://jsonapi.org/format/#fetching-sparse-fieldsets
  #
  # Params:
  #
  # +resource+::
  #   +Symbol+ name of resource to receive the fieldset
  #
  # +root+::
  #   +Boolean+ should this resource take the parameter from +fields+ while no type is specified
  #
  # +permitted_fields+::
  #   +Array+ of +Symbol+s list of accessible fields used to filter out unpermitted fields,
  #   defaults to permit all
  #
  # +default_fields+::
  #   +Array+ of +Symbol+s list of fields to show by default
  #
  # +show_all_permitted_fields_by_default+::
  #   +Boolean+ if set to true, @fieldset will be set to all permitted_fields when the current
  #   resource's fieldset isn't specified
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
  def fieldset_for(resource, root: false, permitted_fields: [], show_all_permitted_fields_by_default: false, default_fields: [])
    @fieldset ||= Hashie::Mash.new
    @meta ||= Hashie::Mash.new

    # put the fields in place
    if params[:fields].is_a? Hash
      @fieldset[resource] = params[:fields][resource] || params[:fields][resource]
    elsif root
      @fieldset[resource] = params[:fields]
    end

    # splits the string into array of symbles
    @fieldset[resource] = @fieldset[resource].present? ? @fieldset[resource].split(',').map(&:to_sym) : default_fields

    # filter out unpermitted fields by intersecting them
    @fieldset[resource] &= permitted_fields if @fieldset[resource].present? && permitted_fields.present?

    # set default fields to permitted_fields if needed
    @fieldset[resource] = permitted_fields if show_all_permitted_fields_by_default && @fieldset[resource].blank? && permitted_fields.present?
  end

  # View Helper to set the default and permitted fields
  def set_fieldset(resource, default_fields: [], permitted_fields: [])
    @fieldset ||= {}
    @fieldset[resource] = default_fields if @fieldset[resource].blank?
    @fieldset[resource] &= permitted_fields
  end

  # Getter for the fieldset data
  def fieldset(resource = nil, field = nil)
    if resource.blank?
      @fieldset ||= {}
    elsif field.blank?
      (@fieldset ||= {})[resource] ||= []
    else
      fieldset(resource).include?(field)
    end
  end

  # Return the 'fields' param description
  def self.fields_param_desc(example: nil)
    if example.present?
      "Choose the fields to be returned. Example value: '#{example}'"
    else
      "Choose the fields to be returned."
    end
  end
end
