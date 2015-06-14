require 'active_support'

# = Sortable
#
# A Sortable Resource API gives the flexibility to change how the returned data
# is sorted to the client. Clients can use the +sort+ URL parameter to control
# how the returned data is sorted, as this example:
#
#   GET /posts?sort=-created_at,title
#
# This means to sort the data by its created time descended and then the title
# ascended.
#
# == Usage
#
# Include this +Concern+ in your Action Controller:
#
#   SamplesController < ApplicationController
#     include APIHelper::Sortable
#   end
#
# or in your Grape API class:
#
#   class SampleAPI < Grape::API
#     helpers APIHelper::Sortable
#   end
#
# then use the +sortable+ method like this:
#
#   resources :posts do
#     get do
#       sortable default_order: { created_at: :desc }
#       @posts = Post.order(sortable_sort)
#
#       # ...
#     end
#   end
#
module APIHelper::Sortable
  extend ActiveSupport::Concern

  # Gets the +sort+ parameter with the format 'resourses?sort=-created_at,name',
  # verify and converts it into an safe Hash that can be passed into the .order
  # method.
  #
  # Params:
  #
  # +default_order+::
  #   +Hash+ the default value to return if the sort parameter is not provided
  #
  def sortable(default_order: {})
    # get the parameter
    sort_by = params[:sort] || params[:sort_by]

    if sort_by.is_a?(String)
      # split it
      sort_by_attrs = sort_by.gsub(/[^a-zA-Z0-9\-_,]/, '').split(',')

      # save it
      @sortable_sort = {}
      sort_by_attrs.each do |attrb|
        if attrb.match(/^-/)
          @sortable_sort[attrb.gsub(/^-/, '')] = :desc
        else
          @sortable_sort[attrb] = :asc
        end
      end
    else
      @sortable_sort = default_order
    end
  end

  # Helper to get the sort data
  def sortable_sort
    @sortable_sort
  end

  # Return the 'sort' param description
  def self.sort_param_desc(example: nil, default: nil)
    if default.present?
      desc = "Specify how the returning data should be sorted, defaults to '#{default}'."
    else
      desc = "Specify how the returning data should be sorted."
    end
    if example.present?
      "#{desc} Example value: '#{example}'"
    else
      desc
    end
  end
end
