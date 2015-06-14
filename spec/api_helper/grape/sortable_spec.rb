require 'grape_helper'

describe APIHelper::Sortable do
  context "used in a Grape app" do
    include Rack::Test::Methods

    class SortableAPI < Grape::API
      helpers APIHelper::Sortable

      resources :resources do
        get do
          sortable(default_order: { string: :desc })
          collection = Model.order(sortable_sort)
          return collection
        end
      end
    end

    def app
      SortableAPI
    end

    it "sorts the resource with the given order" do
      get 'resources.json?sort=integer'
      json = JSON.parse(last_response.body)

      expect(json[0]['integer']).to eq(nil)
      expect(json[1]['integer']).to eq(nil)
      expect(json[2]['integer']).to eq(nil)
      expect(json[3]['integer']).to eq(1)
      expect(json[4]['integer']).to eq(2)
      expect(json[5]['integer']).to eq(3)

      get 'resources.json?sort=-integer'
      json = JSON.parse(last_response.body)

      expect(json[0]['integer']).to eq(5)
      expect(json[1]['integer']).to eq(5)
      expect(json[2]['integer']).to eq(5)

      get 'resources.json?sort=-integer,string'
      json = JSON.parse(last_response.body)

      expect(json[0]['integer']).to eq(5)
      expect(json[0]['string']).to eq('')
      expect(json[1]['integer']).to eq(5)
      expect(json[1]['string']).to eq('хорошо')
      expect(json[2]['integer']).to eq(5)
      expect(json[2]['string']).to eq('好！')

      get 'resources.json?sort=-integer,-string'
      json = JSON.parse(last_response.body)

      expect(json[0]['integer']).to eq(5)
      expect(json[0]['string']).to eq('好！')
      expect(json[1]['integer']).to eq(5)
      expect(json[1]['string']).to eq('хорошо')
      expect(json[2]['integer']).to eq(5)
      expect(json[2]['string']).to eq('')
    end

    it "sorts the resource with the default order" do
      get 'resources.json'
      json = JSON.parse(last_response.body)

      expect(json[0]['string']).to eq('好！')
      expect(json[1]['string']).to eq('хорошо')
      expect(json[2]['string']).to eq('yo')
    end
  end
end if defined?(Grape)
