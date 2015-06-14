require 'active_support'

# = Paginatable
#
# Paginating the requested items can avoid returning too much data in a single
# response. API clients can iterate over the results with pagination instead of
# rerteving all the data in one time, ruining the database connection or
# network.
#
# There are two available URL parameters: +per_page+ and +page+. The former is
# used for setting how many resources will be returned in each page, there will
# be a maxium limit and default value for each API:
#
#   GET /posts?per_page=10
#
# <em>The server will respond 10 resources in a request.</em>
#
# Use the +page+ parameter to specify which to page get:
#
#   GET /posts?page=5
#
# Pagination info will be provided in the HTTP Link header like this:
#
#   Link: <http://api-server.dev/movies?page=1>; rel="first",
#         <http://api-server.dev/movies?page=4>; rel="prev"
#         <http://api-server.dev/movies?page=6>; rel="next",
#         <http://api-server.dev/movies?page=238>; rel="last"
#
# <em>Line breaks are added for readability.</em>
#
# Which follows the proposed RFC 5988 standard.
#
# An aditional header, +X-Items-Count+, will also be set to the total pages
# count.
#
# == Usage
#
# Include this +Concern+ in your Action Controller:
#
#   SamplesController < ApplicationController
#     include APIHelper::Paginatable
#   end
#
# or in your Grape API class:
#
#   class SampleAPI < Grape::API
#     helpers APIHelper::Paginatable
#   end
#
# then set the options for pagination in the grape method, as the following as
# an example:
#
#   resources :posts do
#     get do
#       collection = current_user.posts
#       pagination collection.count, default_per_page: 25, maxium_per_page: 100
#
#       # ...
#     end
#   end
#
# Then use the helper methods like this:
#
#   # this example uses kaminari
#   User.page(page).per(per_page)
#
# HTTP Link header will be automatically set by the way.
module APIHelper::Paginatable
  extend ActiveSupport::Concern

  # Set pagination for the request
  #
  # Params:
  #
  # +items_count+::
  #   +Symbol+ name of resource to receive the inclusion
  #
  # +default_per_page+::
  #   +Integer+ default per_page
  #
  # +maxium_per_page+::
  #   +Integer+ maximum results do return on a single page
  #
  def pagination(items_count, default_per_page: 20,
                              maxium_per_page: 100,
                              set_header: true)
    items_count = items_count.count if items_count.respond_to? :count

    @pagination_per_page = (params[:per_page] || default_per_page).to_i
    @pagination_per_page = maxium_per_page if @pagination_per_page > maxium_per_page
    @pagination_per_page = 1 if @pagination_per_page < 1

    items_count = 0 if items_count < 0
    pages_count = (items_count.to_f / @pagination_per_page).ceil
    pages_count = 1 if pages_count < 1

    @pagination_page = (params[:page] || 1).to_i
    @pagination_page = pages_count if @pagination_page > pages_count
    @pagination_page = 1 if @pagination_page < 1

    if set_header
      link_headers ||= []

      if current_page > 1
        link_headers << "<#{add_or_replace_uri_param(request.url, :page, 1)}>; rel=\"first\""
        link_headers << "<#{add_or_replace_uri_param(request.url, :page, (current_page > pages_count ? pages_count : current_page - 1))}>; rel=\"prev\""
      end

      if current_page < pages_count
        link_headers << "<#{add_or_replace_uri_param(request.url, :page, current_page + 1)}>; rel=\"next\""
        link_headers << "<#{add_or_replace_uri_param(request.url, :page, pages_count)}>; rel=\"last\""
      end

      link_header = link_headers.join(', ')

      if self.respond_to?(:header)
        self.header('Link', link_header)
        self.header('X-Items-Count', items_count.to_s)
        self.header('X-Pages-Count', pages_count.to_s)
      end

      if defined?(response) && response.respond_to?(:headers)
        response.headers['Link'] = link_header
        response.headers['X-Items-Count'] = items_count.to_s
        response.headers['X-Pages-Count'] = pages_count.to_s
      end
    end
  end

  # Getter for the current page
  def pagination_page
    @pagination_page
  end

  alias_method :current_page, :pagination_page

  # Getter for per_page
  def pagination_per_page
    @pagination_per_page
  end

  alias_method :paginate_with, :pagination_per_page

  def add_or_replace_uri_param(url, param_name, param_value) # :nodoc:
    uri = URI(url)
    params = URI.decode_www_form(uri.query || '')
    params.delete_if { |param| param[0].to_s == param_name.to_s }
    params << [param_name, param_value]
    uri.query = URI.encode_www_form(params)
    uri.to_s
  end

  # Return the 'per_page' param description
  def self.per_page_param_desc
    "Specify how many items you want each page to return."
  end

  # Return the 'page' param description
  def self.page_param_desc
    "Specify which page you want to get."
  end
end
