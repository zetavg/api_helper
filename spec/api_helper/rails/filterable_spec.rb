require 'rails_helper'

describe APIHelper::Filterable do
  context "used in a Rails controller", :type => :controller do

    controller(TestRailsApp::ApplicationController) do
      include APIHelper::Filterable

      def index
        collection = filter(Model.all)
        render json: collection
      end
    end

    it "filters out resource with a matching attribute" do
      # GET /?filter[string]=yo
      get :index, filter: { string: 'yo' }
      json = JSON.parse(response.body)

      expect(json).not_to be_blank
      json.each do |resource|
        expect(resource['string']).to eq('yo')
      end

      # GET /?filter[boolean]=true
      get :index, filter: { boolean: 'true' }
      json = JSON.parse(response.body)

      expect(json).not_to be_blank
      json.each do |resource|
        expect(resource['boolean']).to be true
      end
    end

    it "filters out resource with multiple matching attribute" do
      # GET /?filter[integer]=1,2,5,7
      get :index, filter: { integer: '1,2,5,7' }
      json = JSON.parse(response.body)

      expect(json).not_to be_blank
      json.each do |resource|
        expect([1, 2, 5, 7]).to include(resource['integer'])
      end
    end

    it "filters out resource with the \"not()\" function" do
      # GET /?filter[string]=not(yo,hi,boom)
      get :index, filter: { string: 'not(yo,hi,boom)' }
      json = JSON.parse(response.body)

      expect(json).not_to be_blank
      json.each do |resource|
        expect(resource['string']).not_to eq('yo')
        expect(resource['string']).not_to eq('hi')
        expect(resource['string']).not_to eq('boom')
      end
    end

    it "filters out resource with the \"greater_then()\" function" do
      # GET /?filter[integer]=greater_then(3)
      get :index, filter: { integer: 'greater_then(3)' }
      json = JSON.parse(response.body)

      expect(json).not_to be_blank
      json.each do |resource|
        expect(resource['integer']).to be > 3
      end
    end

    it "filters out resource with the \"less_then()\" function" do
      # GET /?filter[integer]=less_then(3)
      get :index, filter: { integer: 'less_then(3)' }
      json = JSON.parse(response.body)

      expect(json).not_to be_blank
      json.each do |resource|
        expect(resource['integer']).to be < 3
      end
    end

    it "filters out resource with the \"greater_then_or_equal()\" function" do
      # GET /?filter[integer]=greater_then_or_equal(3)
      get :index, filter: { integer: 'greater_then_or_equal(3)' }
      json = JSON.parse(response.body)

      expect(json).not_to be_blank
      json.each do |resource|
        expect(resource['integer']).to be >= 3
      end
    end

    it "filters out resource with the \"less_then_or_equal()\" function" do
      # GET /?filter[integer]=less_then_or_equal(3)
      get :index, filter: { integer: 'less_then_or_equal(3)' }
      json = JSON.parse(response.body)

      expect(json).not_to be_blank
      json.each do |resource|
        expect(resource['integer']).to be <= 3
      end
    end

    it "filters out resource with the \"between()\" function" do
      # GET /?filter[integer]=between(2,4)
      get :index, filter: { integer: 'between(2,4)' }
      json = JSON.parse(response.body)

      expect(json).not_to be_blank
      json.each do |resource|
        expect(resource['integer']).to be >= 2
        expect(resource['integer']).to be <= 4
      end

      # GET /?filter[datetime]=between(1970-1-1,2199-1-1)
      get :index, filter: { datetime: 'between(1970-1-1,2199-1-1)' }
      json = JSON.parse(response.body)

      expect(json).not_to be_blank
      json.each do |resource|
        expect(Time.new(resource['datetime'])).to be >= Time.new(1970, 1, 1)
        expect(Time.new(resource['datetime'])).to be <= Time.new(2199, 1, 1)
      end
    end

    it "filters out resource with the \"contains()\" function" do
      # GET /?filter[string]=contains(o)
      get :index, filter: { string: 'contains(o)' }
      json = JSON.parse(response.body)

      expect(json).not_to be_blank
      json.each do |resource|
        expect(resource['string']).to include('o')
      end
    end

    it "filters out resource with the \"null()\" function" do
      # GET /?filter[string]=null()
      get :index, filter: { string: 'null()' }
      json = JSON.parse(response.body)

      expect(json).not_to be_blank
      json.each do |resource|
        expect(resource['string']).to eq(nil)
      end

      # GET /?filter[boolean]=null()
      get :index, filter: { boolean: 'null()' }
      json = JSON.parse(response.body)

      expect(json).not_to be_blank
      json.each do |resource|
        expect(resource['boolean']).to eq(nil)
      end
    end

    it "filters out resource with the \"blank()\" function" do
      # GET /?filter[string]=blank()
      get :index, filter: { string: 'blank()' }
      json = JSON.parse(response.body)

      expect(json).not_to be_blank
      json.each do |resource|
        expect(resource['string']).to be_blank
      end
    end

    it "filters out resource with multiple conditions" do
      # GET /?filter[integer]=between(2,4)&filter[string]=contains(o)
      get :index, filter: { integer: 'between(2,4)', string: 'contains(o)' }
      json = JSON.parse(response.body)

      expect(json).not_to be_blank
      json.each do |resource|
        expect(resource['integer']).to be_between(2, 4)
        expect(resource['string']).to include('o')
      end
    end

    it "ignores filtering with unknown fields" do
      # GET /?filter[string]=хорошо&unknown_field=val
      get :index, filter: { string: 'хорошо', unknown_field: 'val' }
      json = JSON.parse(response.body)

      expect(json).not_to be_blank
      json.each do |resource|
        expect(resource['string']).to eq('хорошо')
      end
    end

    context "with filterable fields specified" do

      controller(TestRailsApp::ApplicationController) do
        include APIHelper::Filterable

        def index
          collection =
            filter(Model.all, filterable_fields: [:integer, :boolean])
          render json: collection
        end
      end

      it "is only filterable with filterable fields" do
        # GET /?filter[string]=хорошо&integer=5
        get :index, filter: { string: 'хорошо', integer: '5' }
        json = JSON.parse(response.body)

        expect(json).not_to be_blank
        expect(json.count).to be > 1
      end
    end
  end
end if defined?(Rails)
