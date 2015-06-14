require 'grape_helper'

describe APIHelper::Includable do
  context "used in a Grape app" do
    include Rack::Test::Methods

    class IncludableAPI < Grape::API
      helpers APIHelper::Includable

      resources :posts do
        get do
          inclusion_for :post, default: true, default_includes: [:author, :comments]
          inclusion_for :user, permitted_includes: [:posts, :followers]

          # returns the inclusion directly for examining
          return inclusion
        end
      end
    end

    def app
      IncludableAPI
    end

    it "parses the included fields for each resource" do
      get 'posts.json?include[post]=author,comments,stargazers&include[user]=followers'
      json = JSON.parse(last_response.body)

      expect(json).to eq('post' => ['author', 'comments', 'stargazers'],
                         'user' => ['followers'])
    end

    it "parses the currect fieldsets for the default resource" do
      get 'posts.json?include=author,comments,stargazers'
      json = JSON.parse(last_response.body)

      expect(json['post']).to eq(['author', 'comments', 'stargazers'])
    end

    it "uses the default fieldsets if not specified" do
      get 'posts.json'
      json = JSON.parse(last_response.body)

      expect(json['post']).to eq(['author', 'comments'])
    end

    it "ignores undeclared resource" do
      get 'posts.json?include[post]=author&include[ufo]=radius'
      json = JSON.parse(last_response.body)

      expect(json['post']).to eq(['author'])
      expect(json['ufo']).to be_blank
    end

    context "permitted includes is set" do
      it "ignores unpermitted fields" do
        get 'posts.json?include[post]=author&include[user]=followers,devices'
        json = JSON.parse(last_response.body)

        expect(json['post']).to eq(['author'])
        expect(json['user']).to eq(['followers'])
      end

      it "can be disabled while giving invalid parameters" do
        get 'posts.json?include[user]=none'
        json = JSON.parse(last_response.body)

        expect(json['user']).to be_blank
      end
    end

    context "integrated with fieldsettable" do

      class IncludableAPIv2 < Grape::API
        helpers APIHelper::Fieldsettable
        helpers APIHelper::Includable

        resources :posts do
          get do
            fieldset_for :post, default: true, default_fields: [:title, :author, :content]
            fieldset_for :user
            inclusion_for :post, default: true, default_includes: [:author, :comments]
            inclusion_for :user, permitted_includes: [:posts, :followers]

            # returns the inclusion directly for examining
            return inclusion
          end
        end
      end

      def app
        IncludableAPIv2
      end

      it "ignores fields not listed in fieldset" do
        get 'posts.json?include=author,comments'
        json = JSON.parse(last_response.body)

        expect(json['post']).to eq(['author'])

        get 'posts.json?fields=title,author,comments&include=author,comments'
        json = JSON.parse(last_response.body)

        expect(json['post']).to eq(['author', 'comments'])
      end

      it "includes fields by default" do
        get 'posts.json?fields=title,author,comments'
        json = JSON.parse(last_response.body)

        expect(json['post']).to eq(['author', 'comments'])
      end
    end
  end
end if defined?(Grape)
