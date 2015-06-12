# APIHelper [![Gem Version](https://badge.fury.io/rb/api_helper.svg)](http://badge.fury.io/rb/api_helper) [![Build Status](https://travis-ci.org/Neson/api_helper.svg?branch=master)](https://travis-ci.org/Neson/api_helper)

Helpers for creating standard RESTful API for Rails or Grape with Active Record.


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'api_helper'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install api_helper


## API Standards

<dl>

  <dt><a href="http://www.rubydoc.info/github/Neson/api_helper/master/APIHelper/Fieldsettable" target="_blank">Fieldsettable</a></dt>
  <dd>Let clients choose the fields they wanted to be returned with the "fields" query parameter, making their API calls optimizable to gain efficiency and speed.</dd>

  <dt><a href="http://www.rubydoc.info/github/Neson/api_helper/master/APIHelper/Includable" target="_blank">Includable</a></dt>
  <dd>Clients can use the "include" query parameter to enable inclusion of related items - for instance, get the author's data along with a post.</dd>

  <dt><a href="http://www.rubydoc.info/github/Neson/api_helper/master/APIHelper/Paginatable" target="_blank">Paginatable</a></dt>
  <dd>Paginate the results of a resource collection, client can get a specific page with the "page" query parameter and set a custom page size with the "per_page" query parameter.</dd>

  <dt><a href="http://www.rubydoc.info/github/Neson/api_helper/master/APIHelper/Sortable" target="_blank">Sortable</a></dt>
  <dd>Client can set custom sorting with the "sort" query parameter while getting a resource collection.</dd>

  <dt><a href="http://www.rubydoc.info/github/Neson/api_helper/master/APIHelper/Filterable" target="_blank">Filterable</a></dt>
  <dd>Enables clients to filter through a resource collection with their fields.</dd>

  <dt><a href="http://www.rubydoc.info/github/Neson/api_helper/master/APIHelper/Multigettable" target="_blank">Multigettable</a></dt>
  <dd>Let Client execute operations on multiple resources with a single request.</dd>

</dl>


## Usage

### Ruby on Rails (Action Pack)

Include each helper concern you need in an `ActionController::Base`:

```ruby
PostsController < ApplicationController
  include APIHelpers::Filterable
  include APIHelpers::Paginatable
  include APIHelpers::Sortable

  # ...

end
```

Further usage of each helper can be found in the [docs](http://www.rubydoc.info/github/Neson/api_helper/master/APIHelper).

### Grape

Set the helpers you need in an `Grape::API`:

```ruby
class PostsAPI < Grape::API
  helpers APIHelpers::Filterable
  helpers APIHelpers::Paginatable
  helpers APIHelpers::Sortable

  # ...

end
```

Further usage of each helper can be found in the [docs](http://www.rubydoc.info/github/Neson/api_helper/master/APIHelper).


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).


## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Neson/api_helper.
