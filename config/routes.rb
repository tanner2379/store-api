Rails.application.routes.draw do
  resources :sessions, only: [:create]
  resources :registrations, only: [:create, :update, :destroy]
  resources :products, param: :slug
  resources :categories, param: :slug do
    get :just_category, to: "categories#just_category"
  end
  resources :cart_items, except: [:show, :edit]
  delete :logout, to: "sessions#logout"
  get :logged_in, to: "sessions#logged_in"
  
  root to: "static#home"
end
