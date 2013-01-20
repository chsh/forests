Forests::Application.routes.draw do

  devise_for :users, controllers: {
      sessions: 'users/sessions'
  }

  root :to => 'viewer#welcome'

  match 'dashboard' => 'user#dashboard', :as => 'dashboard'

  resource :account, :controller => "user" do
    collection do
      post 'register'
      get 'confirm'
      post 'activate'
    end
  end

  resources :one_tables do
    member do
      get 'template'
      get 'import'
      post 'import'
      put 'import'
      delete 'clear_all_records'
      get 'clear_last_error'
      get 'search'
      get 'download'
      post 'download'
      get 'permissions'
      get 'assign'
      post 'assign'
      get 'unassign'
      delete 'unassign'
      post 'duplicate'
      put 'duplicate'
    end
    resources :one_table_records do
      member do
        get 'assign'
        post 'assign'
        get 'unassign'
        delete 'unassign'
      end
    end
    resources :one_table_headers
    resources :blocks
    resources :one_table_templates do
      member do
        get 'download'
        post 'import'
        put 'import'
      end
    end
  end

  resources :search_word_lists do
    resources :search_words
  end

  resources :sites do
    member do
      get 'ref_tables'
      get 'assign'
      post 'assign'
      get 'unassign'
      delete 'unassign'
      get 'permissions'
      get 'search_export'
    end
    collection do
      post 'new2'
    end
    resources :site_attributes
    resources :site_files
    resources :pages do
      post 'regenerate', :on => :collection
    end
    resources :blocks
    resources :search_activities
    resources :logged_words
  end

  resources :fav_users

  resources :password_resets

  resource :admin, :controller => 'admin' do
    resources :users
  end

  match '/one_tables/:id/search' => 'one_tables#search'
  match '/my/:action' => 'my'
  match '/api/:action' => 'api'
  match '*path' => 'site_view#index'
end
