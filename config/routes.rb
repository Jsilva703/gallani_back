Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      match "*path", to: "cors#preflight", via: :options

      namespace :auth do
        post :login, to: "sessions#create"
        get :me, to: "sessions#show"
        delete :logout, to: "sessions#destroy"
      end

      namespace :admin do
        resource :dashboard, only: :show, controller: "dashboard"
        get :agenda, to: "agenda#index"

        resources :users, only: %i[index create update]
        resources :services, only: %i[index create update]

        resources :professionals, only: %i[index create update] do
          resource :availability, only: :show, controller: "availabilities" do
            post :copy
          end
        end

        resources :customers, only: %i[index create]
        resources :availability_slots, only: %i[create destroy]

        put "professionals/:professional_id/availability_exceptions/:date",
            to: "availability_exceptions#upsert"

        resources :availability_exceptions, only: :destroy

        resources :blocked_slots, only: %i[index destroy] do
          post :bulk, on: :collection, action: :bulk_create
        end

        resources :appointments, only: :create do
          patch :status, on: :member, action: :update_status
          patch :reschedule, on: :member
        end

        resources :financial_entries, only: :index
        resources :expenses, only: :create
      end

      scope :professional, module: :professional_portal, as: :professional do
        resource :profile, only: :show, controller: "profile"
        get :agenda, to: "agenda#index"
        resources :customers, only: %i[index create]
        resources :appointments, only: :create
      end

      namespace :integrations do
        namespace :nexa do
          resources :services, only: :index
          resources :professionals, only: :index
          resources :customers, only: %i[index create]
          resource :availability, only: :show, controller: "availability"

          resources :appointments, only: %i[index show create] do
            patch :cancel, on: :member
            patch :reschedule, on: :member
          end
        end
      end
    end
  end
end
