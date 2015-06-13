require 'active_support'
require 'active_support/core_ext/object/blank'

# = Filterable
#
# A filterable resource API supports requests to filter resources in collection
# by their fields, using the +filter+ query parameter.
#
# For example, the following is a request for all products that has a
# particular color:
#
#   GET /products?filter[color]=red
#
# With this approach, multiple filters can be applied to a single request:
#
#   GET /products?filter[color]=red&filter[status]=in-stock
#
# <em>Multiple filters are applied with the AND condition.</em>
#
# A list separated by commas (",") can be used to filter by field matching one
# of the values:
#
#   GET /products?filter[color]=red,blue,yellow
#
# A few functions: +not+, +greater_then+, +less_then+, +greater_then_or_equal+,
# +less_then_or_equal+, +between+, +like+, +contains+, +null+ and +blank+ can
# be used to filter the data, for example:
#
#   GET /products?filter[color]=not(red)
#   GET /products?filter[price]=greater_then(1000)
#   GET /products?filter[price]=less_then_or_equal(2000)
#   GET /products?filter[price]=between(1000,2000)
#   GET /products?filter[name]=like(%lovely%)
#   GET /products?filter[name]=contains(%lovely%)
#   GET /products?filter[provider]=null()
#   GET /products?filter[provider]=blank()
#
# == Usage
#
# Include this +Concern+ in your Action Controller:
#
#   SamplesController < ApplicationController
#     include APIHelpers::Filterable
#   end
#
# or in your Grape API class:
#
#   class SampleAPI < Grape::API
#     helpers APIHelper::Filterable
#   end
#
# then use the +filter+ method in the controller like this:
#
#   @products = filter(Post, filterable_fields: [:name, :price, :color])
#
# <em>The +filter+ method will return a scoped model collection, based
# directly from the requested URL parameters.</em>
#
module APIHelper::Filterable
  extend ActiveSupport::Concern

  # Filter resources of a collection from the request parameter
  #
  # Params:
  #
  # +resource+::
  #   +ActiveRecord::Relation+ resource collection
  #   to filter data from
  #
  # +filterable_fields+::
  #   +Array+ of +Symbol+s fields that are allowed to be filtered, defaults
  #   to all
  #
  def filter(resource, filterable_fields: [])
    # parse the request parameter
    if params[:filter].is_a?(Hash)
      @filter = params[:filter]
      filterable_fields = filterable_fields.map(&:to_s)

      # deal with each condition
      @filter.each_pair do |field, condition|
        # bypass fields that aren't be abled to filter with
        next if filterable_fields.present? && !filterable_fields.include?(field)

        # escape string to prevent SQL injection
        field = resource.connection.quote_string(field)

        next if resource.columns_hash[field].blank?
        field_type = resource.columns_hash[field].type

        # if a function is used
        if func = condition.match(/(?<function>[^\(\)]+)\((?<param>.*)\)/)
          case func[:function]
          when 'not'
            values = func[:param].split(',')
            values.map!(&:to_bool) if field_type == :boolean
            resource = resource.where.not(field => values)

          when 'greater_then'
            resource = resource
                       .where("\"#{resource.table_name}\".\"#{field}\" > ?",
                              func[:param])

          when 'less_then'
            resource = resource
                       .where("\"#{resource.table_name}\".\"#{field}\" < ?",
                              func[:param])

          when 'greater_then_or_equal'
            resource = resource
                       .where("\"#{resource.table_name}\".\"#{field}\" >= ?",
                              func[:param])

          when 'less_then_or_equal'
            resource = resource
                       .where("\"#{resource.table_name}\".\"#{field}\" <= ?",
                              func[:param])

          when 'between'
            param = func[:param].split(',')
            resource = resource
                       .where("\"#{resource.table_name}\".\"#{field}\" BETWEEN ? AND ?",
                              param.first, param.last)

          when 'like'
            resource = resource
                       .where("\"#{resource.table_name}\".\"#{field}\" LIKE ?",
                              func[:param])

          when 'contains'
            resource = resource
                       .where("\"#{resource.table_name}\".\"#{field}\" LIKE ?",
                              "%#{func[:param]}%")

          when 'null'
            resource = resource.where(field => nil)

          when 'blank'
            resource = resource.where(field => [nil, ''])
          end

        # if not function
        else
          values = condition.split(',')
          values.map!(&:to_bool) if field_type == :boolean
          resource = resource.where(field => values)
        end
      end
    end

    return resource
  end

  # Returns a description of the 'fields' URL parameter
  def self.filter_param_desc(for_field: nil)
    if for_field.present?
      "Filter data base on the '#{for_field}' field."
    else
      "Filter the data."
    end
  end
end

class String
  def to_bool
    self == 'true'
  end
end
