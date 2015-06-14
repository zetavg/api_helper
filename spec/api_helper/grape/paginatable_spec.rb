require 'grape_helper'

describe APIHelper::Paginatable do
  context "used in a Grape app" do
    include Rack::Test::Methods

    class PaginatableAPI < Grape::API
      helpers APIHelper::Paginatable

      resources :resources do
        get do
          pagination 1201, default_per_page: 20, maxium_per_page: 100
          return []
        end
      end
    end

    def app
      PaginatableAPI
    end

    it "sets the correct HTTP Link response header" do
      get 'resources.json'
      expect(last_response.header['Link']).to eq('<http://example.org/resources.json?page=2>; rel="next", <http://example.org/resources.json?page=61>; rel="last"')

      get 'resources.json?page=2'
      expect(last_response.header['Link']).to eq('<http://example.org/resources.json?page=1>; rel="first", <http://example.org/resources.json?page=1>; rel="prev", <http://example.org/resources.json?page=3>; rel="next", <http://example.org/resources.json?page=61>; rel="last"')

      get 'resources.json?page=3'
      expect(last_response.header['Link']).to eq('<http://example.org/resources.json?page=1>; rel="first", <http://example.org/resources.json?page=2>; rel="prev", <http://example.org/resources.json?page=4>; rel="next", <http://example.org/resources.json?page=61>; rel="last"')

      get 'resources.json?page=60'
      expect(last_response.header['Link']).to eq('<http://example.org/resources.json?page=1>; rel="first", <http://example.org/resources.json?page=59>; rel="prev", <http://example.org/resources.json?page=61>; rel="next", <http://example.org/resources.json?page=61>; rel="last"')

      get 'resources.json?page=61'
      expect(last_response.header['Link']).to eq('<http://example.org/resources.json?page=1>; rel="first", <http://example.org/resources.json?page=60>; rel="prev"')

      get 'resources.json?page=62'
      expect(last_response.header['Link']).to eq('<http://example.org/resources.json?page=1>; rel="first", <http://example.org/resources.json?page=60>; rel="prev"')

      get 'resources.json?page=0'
      expect(last_response.header['Link']).to eq('<http://example.org/resources.json?page=2>; rel="next", <http://example.org/resources.json?page=61>; rel="last"')

      get 'resources.json?per_page=5&page=3'
      expect(last_response.header['Link']).to eq('<http://example.org/resources.json?per_page=5&page=1>; rel="first", <http://example.org/resources.json?per_page=5&page=2>; rel="prev", <http://example.org/resources.json?per_page=5&page=4>; rel="next", <http://example.org/resources.json?per_page=5&page=241>; rel="last"')

      get 'resources.json?per_page=5000&page=3'
      expect(last_response.header['Link']).to eq('<http://example.org/resources.json?per_page=5000&page=1>; rel="first", <http://example.org/resources.json?per_page=5000&page=2>; rel="prev", <http://example.org/resources.json?per_page=5000&page=4>; rel="next", <http://example.org/resources.json?per_page=5000&page=13>; rel="last"')

      get 'resources.json?per_page=0&page=3'
      expect(last_response.header['Link']).to eq('<http://example.org/resources.json?per_page=0&page=1>; rel="first", <http://example.org/resources.json?per_page=0&page=2>; rel="prev", <http://example.org/resources.json?per_page=0&page=4>; rel="next", <http://example.org/resources.json?per_page=0&page=1201>; rel="last"')
    end

    it "sets the correct HTTP X-Items-Count response header" do
      get 'resources.json'
      expect(last_response.header['X-Items-Count']).to eq('1201')
    end

    it "sets the correct HTTP X-Pages-Count response header" do
      get 'resources.json'
      expect(last_response.header['X-Pages-Count']).to eq('61')

      get 'resources.json?per_page=5&page=3'
      expect(last_response.header['X-Pages-Count']).to eq('241')

      get 'resources.json?per_page=5000&page=3'
      expect(last_response.header['X-Pages-Count']).to eq('13')

      get 'resources.json?per_page=0&page=3'
      expect(last_response.header['X-Pages-Count']).to eq('1201')
    end
  end
end if defined?(Grape)
