SampleApp::Application.routes.draw do
  #devise_for :users

  ActiveAdmin.routes(self)

  devise_for :admin_users, ActiveAdmin::Devise.config
  
  resources :sessions, :only => [:new, :create, :destroy]
  resources :relationships, :only => [:create, :destroy]
  resources :events do
    member do
      post :attend
      post "/remove_attendee/:user_id" => "events#remove_attendee", :as=>:remove_attendee
      post "/edit" => "events#edit"
    end
  end
  resources :users do
    member do
      get :following, :followers
    end
  end
  
  match '/signup', :to => 'users#new'
  match '/create_event', :to => 'events#new'
  match '/my_events', :to => 'events#my_events'
  match '/signin', :to => 'sessions#new'
  match '/signout', :to => 'sessions#destroy'
  match '/contact', :to => 'pages#contact'
  match '/about', :to => 'pages#about'
  match '/help', :to => 'pages#help'
  
  root :to => 'pages#home'

end