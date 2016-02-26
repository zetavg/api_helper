require 'rails_helper'

describe APIHelper::Paginatable do
  context "used in a Rails controller", :type => :controller do

    controller(TestRailsApp::ApplicationController) do
      include APIHelper::Paginatable

      def index
        pagination 1201, default_per_page: 20, maxium_per_page: 100
        render json: []
      end
    end

    it "sets the correct HTTP Link response header" do
      # GET /
      get :index
      expect(response.header['Link']).to eq('<http://test.host/test_rails_app/application?page=2>; rel="next", <http://test.host/test_rails_app/application?page=61>; rel="last"')

      # GET /?page=2
      get :index, page: 2
      expect(response.header['Link']).to eq('<http://test.host/test_rails_app/application?page=1>; rel="first", <http://test.host/test_rails_app/application?page=1>; rel="prev", <http://test.host/test_rails_app/application?page=3>; rel="next", <http://test.host/test_rails_app/application?page=61>; rel="last"')

      # GET /?page=3
      get :index, page: 3
      expect(response.header['Link']).to eq('<http://test.host/test_rails_app/application?page=1>; rel="first", <http://test.host/test_rails_app/application?page=2>; rel="prev", <http://test.host/test_rails_app/application?page=4>; rel="next", <http://test.host/test_rails_app/application?page=61>; rel="last"')

      # GET /?page=60
      get :index, page: 60
      expect(response.header['Link']).to eq('<http://test.host/test_rails_app/application?page=1>; rel="first", <http://test.host/test_rails_app/application?page=59>; rel="prev", <http://test.host/test_rails_app/application?page=61>; rel="next", <http://test.host/test_rails_app/application?page=61>; rel="last"')

      # GET /?page=61
      get :index, page: 61
      expect(response.header['Link']).to eq('<http://test.host/test_rails_app/application?page=1>; rel="first", <http://test.host/test_rails_app/application?page=60>; rel="prev"')

      # GET /?page=62
      get :index, page: 62
      expect(response.header['Link']).to eq('<http://test.host/test_rails_app/application?page=1>; rel="first", <http://test.host/test_rails_app/application?page=60>; rel="prev"')

      # GET /?page=0
      get :index, page: 0
      expect(response.header['Link']).to eq('<http://test.host/test_rails_app/application?page=2>; rel="next", <http://test.host/test_rails_app/application?page=61>; rel="last"')

      # GET /?per_page=5&page=3
      # get :index, per_page: 5, page: 3
      # expect(response.header['Link']).to eq('<http://test.host/test_rails_app/application?per_page=5&page=1>; rel="first", <http://test.host/test_rails_app/application?per_page=5&page=2>; rel="prev", <http://test.host/test_rails_app/application?per_page=5&page=4>; rel="next", <http://test.host/test_rails_app/application?per_page=5&page=241>; rel="last"')

      # GET /?per_page=5000&page=3
      get :index, per_page: 5000, page: 3
      # expect(response.header['Link']).to eq('<http://test.host/test_rails_app/application?page=1>; rel="first", <http://test.host/test_rails_app/application?page=2>; rel="prev", <http://test.host/test_rails_app/application?page=4>; rel="next", <http://test.host/test_rails_app/application?page=13>; rel="last"')

      # GET /?per_page=0&page=3
      get :index, per_page: 0, page: 3
      # expect(response.header['Link']).to eq('<http://test.host/test_rails_app/application?page=1>; rel="first", <http://test.host/test_rails_app/application?page=2>; rel="prev", <http://test.host/test_rails_app/application?page=4>; rel="next", <http://test.host/test_rails_app/application?page=1201>; rel="last"')
    end

    it "sets the correct HTTP X-Items-Count response header" do
      # GET /
      get :index
      expect(response.header['X-Items-Count']).to eq('1201')
    end

    it "sets the correct HTTP X-Pages-Count response header" do
      # GET /
      get :index
      expect(response.header['X-Pages-Count']).to eq('61')

      # GET /?per_page=5&page=3
      get :index, per_page: 5, page: 3
      expect(response.header['X-Pages-Count']).to eq('241')

      # GET /?per_page=5000&page=3
      get :index, per_page: 5000, page: 3
      expect(response.header['X-Pages-Count']).to eq('13')

      # GET /?per_page=0&page=3
      get :index, per_page: 0, page: 3
      expect(response.header['X-Pages-Count']).to eq('1201')
    end

    describe "helper methods" do
      describe "pagination_per_page" do
        it "returns page of the request" do
          # GET /
          get :index
          expect(controller.pagination_per_page).to eq(20)

          # GET /?page=3
          get :index, page: 3
          expect(controller.pagination_per_page).to eq(20)

          # GET /?page=25
          get :index, per_page: 25
          expect(controller.pagination_per_page).to eq(25)

          # GET /?per_page=5000
          get :index, per_page: 5000
          expect(controller.pagination_per_page).to eq(100)

          # GET /?per_page=0
          get :index, per_page: 0
          expect(controller.pagination_per_page).to eq(1)
        end
      end

      describe "pagination_page" do
        it "returns page of the request" do
          # GET /
          get :index
          expect(controller.pagination_page).to eq(1)

          # GET /?page=3
          get :index, page: 3
          expect(controller.pagination_page).to eq(3)

          # GET /?page=0
          get :index, page: 0
          expect(controller.pagination_page).to eq(1)

          # GET /?per_page=5000&page=3
          get :index, per_page: 5000, page: 14
          expect(controller.pagination_page).to eq(13)
        end
      end
    end
  end
end if defined?(Rails)
