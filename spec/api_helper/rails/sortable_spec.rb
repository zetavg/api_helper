require 'rails_helper'

describe APIHelper::Sortable do
  context "used in a Rails controller", :type => :controller do

    controller(TestRailsApp::ApplicationController) do
      include APIHelper::Sortable

      def index
        sortable(default_order: { string: :desc })
        collection = Model.order(sortable_sort)
        render json: collection
      end
    end

    it "sorts the resource with the given order" do
      # GET /?sort=integer
      get :index, sort: 'integer'
      json = JSON.parse(response.body)

      expect(json[0]['integer']).to eq(nil)
      expect(json[1]['integer']).to eq(nil)
      expect(json[2]['integer']).to eq(nil)
      expect(json[3]['integer']).to eq(1)
      expect(json[4]['integer']).to eq(2)
      expect(json[5]['integer']).to eq(3)

      # GET /?sort=-integer
      get :index, sort: '-integer'
      json = JSON.parse(response.body)

      expect(json[0]['integer']).to eq(5)
      expect(json[1]['integer']).to eq(5)
      expect(json[2]['integer']).to eq(5)

      # GET /?sort=-integer,string
      get :index, sort: '-integer,string'
      json = JSON.parse(response.body)

      expect(json[0]['integer']).to eq(5)
      expect(json[0]['string']).to eq('')
      expect(json[1]['integer']).to eq(5)
      expect(json[1]['string']).to eq('хорошо')
      expect(json[2]['integer']).to eq(5)
      expect(json[2]['string']).to eq('好！')

      # GET /?sort=-integer,-string
      get :index, sort: '-integer,-string'
      json = JSON.parse(response.body)

      expect(json[0]['integer']).to eq(5)
      expect(json[0]['string']).to eq('好！')
      expect(json[1]['integer']).to eq(5)
      expect(json[1]['string']).to eq('хорошо')
      expect(json[2]['integer']).to eq(5)
      expect(json[2]['string']).to eq('')
    end

    it "sorts the resource with the default order" do
      # GET /
      get :index
      json = JSON.parse(response.body)

      expect(json[0]['string']).to eq('好！')
      expect(json[1]['string']).to eq('хорошо')
      expect(json[2]['string']).to eq('yo')
    end
  end
end if defined?(Rails)
