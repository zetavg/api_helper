require 'rails_helper'

describe APIHelper::Multigettable do
  context "used in a Rails controller", :type => :controller do

    controller(TestRailsApp::ApplicationController) do
      include APIHelper::Multigettable

      def index
        collection = multiget(Model.all)
        render json: collection
      end
    end

    it "can get a specified resource" do
      # GET /1
      get :index, id: 1
      json = JSON.parse(response.body)

      expect(json['id']).to eq(1)

      # GET /2
      get :index, id: 2
      json = JSON.parse(response.body)

      expect(json['id']).to eq(2)

      expect(controller.multiget?).to be false
    end

    it "can get multiple specified resource" do
      # GET /1,4,2,5
      get :index, id: '1,4,2,5'
      json = JSON.parse(response.body)

      expect(json.count).to eq(4)
      json.each do |resource|
        expect([1, 4, 2, 5]).to include(resource['id'])
      end

      expect(controller.multiget?).to be true
    end

    context "with maximum resource count limitations" do

      controller(TestRailsApp::ApplicationController) do
        include APIHelper::Multigettable

        def index
          collection = multiget(Model.all, max: 3)
          render json: collection
        end
      end

      it "limits the maximum resources returned" do
        # GET /1,4,2,5
        get :index, id: '1,4,2,5'
        json = JSON.parse(response.body)

        expect(json.count).to eq(3)
      end
    end

    context "with custom ids" do

      controller(TestRailsApp::ApplicationController) do
        include APIHelper::Multigettable

        def index
          collection = multiget(Model.all, find_by: :string, param: :code)
          render json: collection
        end
      end

      it "can get a specified resource" do
        get :index, code: 'yo'
        json = JSON.parse(response.body)

        expect(json['string']).to eq('yo')

        expect(controller.multiget?).to be false
        expect(controller.multiget?(param: :code)).to be false
      end

      it "can get multiple specified resource" do
        get :index, code: 'hi,yo'
        json = JSON.parse(response.body)

        expect(json.count).to eq(2)
        json.each do |resource|
          expect(%w(hi yo)).to include(resource['string'])
        end

        expect(controller.multiget?).to be false
        expect(controller.multiget?(param: :code)).to be true
      end
    end
  end
end if defined?(Rails)
