Rails.application.routes.draw do
  devise_for :users
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :admin do
    root to: "dashboard#index"
    resources :users, only: %i[index new create edit update]
    resource :setting, only: [:edit, :update]
    resources :categories do
      member do
        patch :toggle_active
      end
    end
    resources :products do
      member do
        patch :toggle_active
      end
    end
    resources :customers do
      member do
        patch :toggle_active
      end
    end
    resources :sales, only: [:index, :show] do
      member do
        patch :void
        get   :ticket
        get   :receipt
      end
    end
    resources :cash_closings, only: [:index, :show]
    resources :credits, only: [:index, :show] do
      member do
        post :pay
      end
    end
  end

  namespace :pos do
    root to: "sales#new"

    resources :sales, only: [:new, :create] do
      member do
        get  :ticket
        get  :receipt
        post :resume
        delete :discard_suspended
      end
      collection do
        post :suspend
        get  :suspended, to: "sales#suspended_index"
      end
    end

    resources :closings, only: [:new, :create]

    get  "products/search",         to: "products#search"
    get  "products/lookup_barcode", to: "products#lookup_barcode"

    post   "cart/add",    to: "cart#add"
    delete "cart/remove", to: "cart#remove"
    delete "cart/clear",  to: "cart#clear"

    resources :credits, only: [:index, :show] do
      member do
        post :pay
      end
    end
  end

  root to: redirect("/admin")
end
