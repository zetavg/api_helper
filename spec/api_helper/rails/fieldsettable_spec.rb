require 'rails_helper'

describe APIHelper::Fieldsettable do
  context "used in a Rails controller", :type => :controller do

    context "with specified fieldsets" do

      controller(TestRailsApp::ApplicationController) do
        include APIHelper::Fieldsettable

        def index
          fieldset_for :post, default: true, default_fields: [:title, :content]
          fieldset_for :user
          render json: []
        end
      end

      it "parses the fieldsets for each resource" do
        # GET /?fields[post]=title,author&fields[user]=name
        get :index, fields: { post: 'title,author', user: 'name' }

        expect(controller.fieldset).to eq('post' => ['title', 'author'],
                                          'user' => ['name'])
        expect(controller.fieldset[:post]).to eq(['title', 'author'])
        expect(controller.fieldset(:post)).to eq(['title', 'author'])
        expect(controller.fieldset(:post, :author)).to be true
        expect(controller.fieldset(:post, 'author')).to be true
        expect(controller.fieldset('post', :author)).to be true
        expect(controller.fieldset('post', 'author')).to be true
        expect(controller.fieldset(:post, :content)).to be false

        expect(controller.fieldset(:nothing)).to eq([])
      end

      it "parses the currect fieldsets for the default resource" do
        # GET /?fields=title,author
        get :index, fields: 'title,author'

        expect(controller.fieldset[:post]).to eq(['title', 'author'])
        expect(controller.fieldset(:post)).to eq(['title', 'author'])
        expect(controller.fieldset(:post, :author)).to be true
        expect(controller.fieldset(:post, 'author')).to be true
        expect(controller.fieldset('post', :author)).to be true
        expect(controller.fieldset('post', 'author')).to be true
        expect(controller.fieldset(:post, :content)).to be false
      end

      it "uses the default fieldsets if not specified" do
        # GET /
        get :index

        expect(controller.fieldset[:post]).to eq(['title', 'content'])
        expect(controller.fieldset(:post)).to eq(['title', 'content'])
        expect(controller.fieldset(:post, :content)).to be true
        expect(controller.fieldset(:user)).to be_blank
      end

      it "ignores undeclared resource" do
        # GET /?fields[post]=title,author&fields[ufo]=radius
        get :index, fields: { post: 'title,author', ufo: 'radius' }

        expect(controller.fieldset(:post)).to eq(['title', 'author'])
        expect(controller.fieldset(:ufo)).to be_blank
      end

      describe "view helpers" do
        describe "set_fieldset" do
          it "sets the properties of fieldset" do
            # GET /?fields[post]=title,author,secret
            get :index, fields: { post: 'title,author,secret' }

            # These methods are normally be called in the view
            controller.set_fieldset :post, permitted_fields: [:title, :content, :author]
            controller.set_fieldset :user, default_fields: [:avatar_url, :name]

            expect(controller.fieldset(:post)).to eq(['title', 'author'])
            expect(controller.fieldset(:user)).to eq(['avatar_url', 'name'])
          end
        end
      end
    end

    context "with specified permitted_fields fieldsets" do

      controller(TestRailsApp::ApplicationController) do
        include APIHelper::Fieldsettable

        def index
          fieldset_for :post, default: true,
                              permitted_fields: [:title, :content, :author],
                              default_fields: [:title, :content]
          fieldset_for :user, permitted_fields: [:id, :avatar_url, :name],
                              defaults_to_permitted_fields: true

          render json: []
        end
      end

      it "does not return unpermitted fields for an resource" do
        # GET /?fields[post]=title,author,secret&fields[user]=name,password
        get :index, fields: { post: 'title,author,secret', user: 'name,password' }

        expect(controller.fieldset).to eq('post' => ['title', 'author'],
                                          'user' => ['name'])
        expect(controller.fieldset(:user, :password)).to be false
      end

      it "uses the default fieldsets if not specified" do
        # GET /
        get :index

        expect(controller.fieldset(:user)).to eq(%w(id avatar_url name))
      end
    end
  end
end if defined?(Rails)
