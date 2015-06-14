require 'grape_helper'

describe APIHelper::Multigettable do
  context "used in a Grape app" do
    include Rack::Test::Methods

    class MultigettableAPI < Grape::API
      helpers APIHelper::Multigettable

      resources :resources do
        get :':id' do
          collection = multiget(Model.all)
          return collection
        end
      end
    end

    def app
      MultigettableAPI
    end

    it "can get a specified resource" do
      get '/resources/1.json'
      json = JSON.parse(last_response.body)

      expect(json['id']).to eq(1)

      get '/resources/2.json'
      json = JSON.parse(last_response.body)

      expect(json['id']).to eq(2)
    end

    it "can get multiple specified resource" do
      get '/resources/1,4,2,5.json'
      json = JSON.parse(last_response.body)

      expect(json.count).to eq(4)
      json.each do |resource|
        expect([1, 4, 2, 5]).to include(resource['id'])
      end
    end
  end
end if defined?(Grape)
