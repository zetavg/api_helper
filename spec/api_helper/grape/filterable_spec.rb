require 'grape_helper'

describe APIHelper::Filterable do
  context "used in a Grape app" do
    include Rack::Test::Methods

    class FilterableAPI < Grape::API
      helpers APIHelper::Filterable

      resources :resources do
        get do
          collection = filter(Model.all)
          return collection
        end
      end
    end

    def app
      FilterableAPI
    end

    it "filters out resource with a matching attribute" do
      get '/resources.json?filter[string]=yo'
      json = JSON.parse(last_response.body)

      expect(json).not_to be_blank
      json.each do |resource|
        expect(resource['string']).to eq('yo')
      end

      get '/resources.json?filter[boolean]=true'
      json = JSON.parse(last_response.body)

      expect(json).not_to be_blank
      json.each do |resource|
        expect(resource['boolean']).to be true
      end
    end

    it "filters out resource with multiple matching attribute" do
      get '/resources.json?filter[integer]=1,2,5,7'
      json = JSON.parse(last_response.body)

      expect(json).not_to be_blank
      json.each do |resource|
        expect([1, 2, 5, 7]).to include(resource['integer'])
      end
    end

    it "filters out resource with the \"not()\" function" do
      get '/resources.json?filter[string]=not(yo,hi,boom)'
      json = JSON.parse(last_response.body)

      expect(json).not_to be_blank
      json.each do |resource|
        expect(resource['string']).not_to eq('yo')
        expect(resource['string']).not_to eq('hi')
        expect(resource['string']).not_to eq('boom')
      end
    end

    it "filters out resource with the \"greater_then()\" function" do
      get '/resources.json?filter[integer]=greater_then(3)'
      json = JSON.parse(last_response.body)

      expect(json).not_to be_blank
      json.each do |resource|
        expect(resource['integer']).to be > 3
      end
    end

    it "filters out resource with the \"less_then()\" function" do
      get '/resources.json?filter[integer]=less_then(3)'
      json = JSON.parse(last_response.body)

      expect(json).not_to be_blank
      json.each do |resource|
        expect(resource['integer']).to be < 3
      end
    end

    it "filters out resource with the \"greater_then_or_equal()\" function" do
      get '/resources.json?filter[integer]=greater_then_or_equal(3)'
      json = JSON.parse(last_response.body)

      expect(json).not_to be_blank
      json.each do |resource|
        expect(resource['integer']).to be >= 3
      end
    end

    it "filters out resource with the \"less_then_or_equal()\" function" do
      get '/resources.json?filter[integer]=less_then_or_equal(3)'
      json = JSON.parse(last_response.body)

      expect(json).not_to be_blank
      json.each do |resource|
        expect(resource['integer']).to be <= 3
      end
    end

    it "filters out resource with the \"between()\" function" do
      get '/resources.json?filter[integer]=between(2,4)'
      json = JSON.parse(last_response.body)

      expect(json).not_to be_blank
      json.each do |resource|
        expect(resource['integer']).to be >= 2
        expect(resource['integer']).to be <= 4
      end

      get '/resources.json?filter[datetime]=between(1970-1-1,2199-1-1)'
      json = JSON.parse(last_response.body)

      expect(json).not_to be_blank
      json.each do |resource|
        expect(Time.new(resource['datetime'])).to be >= Time.new(1970, 1, 1)
        expect(Time.new(resource['datetime'])).to be <= Time.new(2199, 1, 1)
      end
    end

    it "filters out resource with the \"contains()\" function" do
      get '/resources.json?filter[string]=contains(o)'
      json = JSON.parse(last_response.body)

      expect(json).not_to be_blank
      json.each do |resource|
        expect(resource['string']).to include('o')
      end
    end

    it "filters out resource with the \"null()\" function" do
      get '/resources.json?filter[string]=null()'
      json = JSON.parse(last_response.body)

      expect(json).not_to be_blank
      json.each do |resource|
        expect(resource['string']).to eq(nil)
      end

      get '/resources.json?filter[boolean]=null()'
      json = JSON.parse(last_response.body)

      expect(json).not_to be_blank
      json.each do |resource|
        expect(resource['boolean']).to eq(nil)
      end
    end

    it "filters out resource with the \"blank()\" function" do
      get '/resources.json?filter[string]=blank()'
      json = JSON.parse(last_response.body)

      expect(json).not_to be_blank
      json.each do |resource|
        expect(resource['string']).to be_blank
      end
    end

    it "filters out resource with multiple conditions" do
      get '/resources.json?filter[integer]=between(2,4)&filter[string]=contains(o)'
      json = JSON.parse(last_response.body)

      expect(json).not_to be_blank
      json.each do |resource|
        expect(resource['integer']).to be_between(2, 4)
        expect(resource['string']).to include('o')
      end
    end

    it "ignores filtering with unknown fields" do
      get '/resources.json?filter[string]=%D1%85%D0%BE%D1%80%D0%BE%D1%88%D0%BE&unknown_field=val'
      json = JSON.parse(last_response.body)

      expect(json).not_to be_blank
      json.each do |resource|
        expect(resource['string']).to eq('хорошо')
      end
    end

    context "with filterable fields specified" do

      class FilterableAPIv2 < Grape::API
        helpers APIHelper::Filterable

        resources :resources do
          get do
            collection =
              filter(Model.all, filterable_fields: [:integer, :boolean])
            return collection
          end
        end
      end

      def app
        FilterableAPIv2
      end

      it "is only filterable with filterable fields" do
        get '/resources.json?filter[string]=%D1%85%D0%BE%D1%80%D0%BE%D1%88%D0%BE&integer=5'
        json = JSON.parse(last_response.body)

        expect(json).not_to be_blank
        expect(json.count).to be > 1
      end
    end
  end
end if defined?(Grape)
