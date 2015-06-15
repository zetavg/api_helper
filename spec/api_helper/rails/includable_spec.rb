require 'rails_helper'

describe APIHelper::Includable do
  context "used in a Rails controller", :type => :controller do

    controller(TestRailsApp::ApplicationController) do
      include APIHelper::Includable

      def index
        inclusion_for :post, default: true, default_includes: [:author, :comments]
        inclusion_for :user, permitted_includes: [:posts, :followers]
        render json: []
      end
    end

    it "parses the included fields for each resource" do
      # GET /?include[post]=author,comments,stargazers&include[user]=followers
      get :index, include: { post: 'author,comments,stargazers', user: 'followers' }

      expect(controller.inclusion).to eq('post' => ['author', 'comments', 'stargazers'],
                                         'user' => ['followers'])
      expect(controller.inclusion[:post]).to eq(['author', 'comments', 'stargazers'])
      expect(controller.inclusion(:user)).to eq(['followers'])
      expect(controller.inclusion(:post, :author)).to be true
      expect(controller.inclusion(:post, 'author')).to be true
      expect(controller.inclusion('post', :author)).to be true
      expect(controller.inclusion('post', 'author')).to be true
      expect(controller.inclusion(:post, :board)).to be false

      expect(controller.inclusion(:nothing)).to eq([])
    end

    it "parses the currect fieldsets for the default resource" do
      # GET /?include=author,comments,stargazers
      get :index, include: 'author,comments,stargazers'

      expect(controller.inclusion[:post]).to eq(['author', 'comments', 'stargazers'])
      expect(controller.inclusion(:post)).to eq(['author', 'comments', 'stargazers'])
      expect(controller.inclusion(:post, :author)).to be true
      expect(controller.inclusion(:post, 'author')).to be true
      expect(controller.inclusion('post', :author)).to be true
      expect(controller.inclusion('post', 'author')).to be true
      expect(controller.inclusion(:post, :board)).to be false
    end

    it "uses the default fieldsets if not specified" do
      # GET /
      get :index

      expect(controller.inclusion[:post]).to eq(['author', 'comments'])
      expect(controller.inclusion(:post)).to eq(['author', 'comments'])
      expect(controller.inclusion(:post, :author)).to be true
      expect(controller.inclusion(:user)).to be_blank
    end

    it "ignores undeclared resource" do
      # GET /?include[post]=author&include[ufo]=radius
      get :index, include: { post: 'author', ufo: 'passengers' }

      expect(controller.inclusion(:post)).to eq(['author'])
      expect(controller.inclusion(:ufo)).to be_blank
    end

    context "permitted includes is set" do
      it "ignores unpermitted fields" do
        # GET /?include[post]=author&include[user]=followers,devices
        get :index, include: { post: 'author', user: 'followers,devices' }

        expect(controller.inclusion(:post)).to eq(['author'])
        expect(controller.inclusion(:user)).to eq(['followers'])
        expect(controller.inclusion(:user, :devices)).to be false
      end

      it "can be disabled while giving invalid parameters" do
        # GET /?include[user]=none
        get :index, include: { user: 'none' }

        expect(controller.inclusion(:user)).to be_blank
      end
    end

    context "integrated with fieldsettable" do

      controller(TestRailsApp::ApplicationController) do
        include APIHelper::Fieldsettable
        include APIHelper::Includable

        def index
          fieldset_for :post, default: true, default_fields: [:title, :author, :content]
          fieldset_for :user
          inclusion_for :post, default: true, default_includes: [:author, :comments]
          inclusion_for :user, permitted_includes: [:posts, :followers]
          render json: []
        end
      end

      it "ignores fields not listed in fieldset" do
        # GET /?include=author,comments
        get :index, include: 'author,comments'

        expect(controller.inclusion(:post)).to eq(['author'])
        expect(controller.inclusion(:post, :comments)).to be false

        # GET /?fields=title,author,comments&include=author,comments
        get :index, fields: 'title,author,comments',
                    include: 'author,comments'

        expect(controller.inclusion(:post)).to eq(['author', 'comments'])
        expect(controller.inclusion(:post, :comments)).to be true

        expect(controller.fieldset(:post)).to eq(['title', 'author', 'comments'])
      end

      it "ignores default inclusion fields not listed in fieldset" do
        # GET /?fields=title,author,comments
        get :index, fields: 'title,author'
        # This method is normally be called in the view
        controller.set_inclusion :post,
                                 default_includes: [:author, :comments]
        expect(controller.inclusion(:post, :author)).to be true
        expect(controller.inclusion(:post, :comments)).to be false
      end

      it "includes fields by default" do
        # GET /?fields=title,author,comments
        get :index, fields: 'title,author,comments'

        expect(controller.inclusion(:post)).to eq(['author', 'comments'])
        expect(controller.inclusion(:post, :comments)).to be true

        expect(controller.fieldset(:post)).to eq(['title', 'author', 'comments'])
      end
    end

    describe "view helpers" do
      describe "set_inclusion" do
        it "sets the properties of inclusion" do
          # GET /?include[post]=author,comments,board
          get :index, include: { post: 'author,comments,board' }

          # This method is normally be called in the view
          controller.set_inclusion :post, default_includes: [:author],
                                          permitted_includes: [:author, :comments]

          expect(controller.inclusion(:post)).to eq(['author', 'comments'])

          # GET /
          get :index

          # This method is normally be called in the view
          controller.set_inclusion :user, default_includes: [:post]

          expect(controller.inclusion(:user)).to eq(['post'])

          # GET /?include=false
          get :index

          # This method is normally be called in the view
          controller.set_inclusion :post, default_includes: [:author],
                                          permitted_includes: [:author, :comments]

          expect(controller.inclusion(:post)).to be_blank
        end
      end

      describe "set_inclusion_field" do
        it "sets the properties of includable fields" do
          # These methods are normally called in the view
          controller.set_inclusion_field :post, :comments, :comment_ids,
                                         resource_name: :comment,
                                         resources_url: '/comments'
          controller.set_inclusion_field :post, :author, :author_id,
                                         resource_name: :user,
                                         resources_url: '/users'

          expect(controller.instance_variable_get(:'@inclusion_field')).to \
            eq('post' => {
                 'comments' => {
                   'field' => :comments,
                   'id_field' => :comment_ids,
                   'resource_name' => :comment,
                   'resources_url' => '/comments'
                 },
                 'author' => {
                   'field' => :author,
                   'id_field' => :author_id,
                   'resource_name' => :user,
                   'resources_url' => '/users'
                 }
               })
        end
      end

      describe "inclusion_field" do
        it "get the properties of includable fields" do
          # These methods are normally called in the view
          controller.set_inclusion_field :post, :comments, :comment_ids,
                                         resource_name: :comment,
                                         resources_url: '/comments'
          controller.set_inclusion_field :post, :author, :author_id,
                                         resource_name: :user,
                                         resources_url: '/users'

          expect(controller.inclusion_field).to \
            eq('post' => {
                 'comments' => {
                   'field' => :comments,
                   'id_field' => :comment_ids,
                   'resource_name' => :comment,
                   'resources_url' => '/comments'
                 },
                 'author' => {
                   'field' => :author,
                   'id_field' => :author_id,
                   'resource_name' => :user,
                   'resources_url' => '/users'
                 }
               })

          expect(controller.inclusion_field(:post)).to \
            eq('comments' => {
                 'field' => :comments,
                 'id_field' => :comment_ids,
                 'resource_name' => :comment,
                 'resources_url' => '/comments'
               },
               'author' => {
                 'field' => :author,
                 'id_field' => :author_id,
                 'resource_name' => :user,
                 'resources_url' => '/users'
               })

          expect(controller.inclusion_field(:nothing)).to eq({})
        end
      end
    end
  end
end if defined?(Rails)
