require 'grape_helper'

describe APIHelper::Fieldsettable do
  context "used in a Grape app" do
    include Rack::Test::Methods

    class FieldsettableAPI < Grape::API
      helpers APIHelper::Fieldsettable

      resources :posts do
        get do
          fieldset_for :post, default: true,
                              permitted_fields: [:title, :content, :author],
                              default_fields: [:title, :content]
          fieldset_for :user, permitted_fields: [:id, :avatar_url, :name],
                              defaults_to_permitted_fields: true

          # returns the fieldset directly for examining
          return fieldset
        end
      end
    end

    def app
      FieldsettableAPI
    end

    it "parses the currect fieldsets for each resource" do
      get '/posts.json?fields[post]=title,author&fields[user]=name'
      json = JSON.parse(last_response.body)

      expect(json).to eq('post' => ['title', 'author'], 'user' => ['name'])
    end

    it "uses the default fieldsets if not specified" do
      get '/posts.json'
      json = JSON.parse(last_response.body)

      expect(json).to eq('post' => ['title', 'content'], 'user' => ['id', 'avatar_url', 'name'])
    end

    it "ignores undeclared resource" do
      get '/posts.json?fields[post]=title,author&fields[ufo]=radius'
      json = JSON.parse(last_response.body)

      expect(json['post']).to eq(['title', 'author'])
      expect(json['ufo']).to be_blank
    end

    it "does not return unpermitted fields for an resource" do
      get '/posts.json?fields[post]=title,author,secret&fields[user]=name,password'
      json = JSON.parse(last_response.body)

      expect(json).to eq('post' => ['title', 'author'],
                                        'user' => ['name'])
      expect(json['user']).not_to include('password')
    end
  end
end if defined?(Grape)
