
Rails.application.routes.draw do
  mount Bootsy::Engine => '/bootsy', as: 'bootsy'

  scope "(:locale)", locale: /en|en-AU|zh-TW/ do
    
    resources :subscriptions
    # mount ActionCable.server => '/cable'
    
    resources :email_templates do 
      resource :preview, only: [:new, :create], controller: 'email_templates/preview'
    end
  

    #get 'stripe/index'
    resources :stripe, only: [:index, :destroy]

    devise_for :people, :controllers => { :invitations => 'people/invitations' }
      
    resources :unions, controller: :supergroups, type: 'Union' do
      resources :join_forms do 
        resources :subscriptions
        resource :follow, only: [:update], controller: 'join_forms/follow'
      end
      resource :key, only: [:show, :new, :edit, :update], controller: 'unions/key'
    end
    
    resources :people, except: [:new] do # people can only be invited
      member do 
        get 'compose_email'
        patch 'send_email'
      end
    end 

    resources :join_forms

    get '/public/:filename', to: 'files#get'
    
    get '/:union_id/:join_form_id/join', to: 'subscriptions#new', as: :new_join
    post '/:union_id/:join_form_id/join', to: 'subscriptions#create' 
    get '/:union_id/:join_form_id/join/:id', to: 'subscriptions#edit', as: :edit_join
    patch '/:union_id/:join_form_id/join/:id', to:  'subscriptions#update'
    get '/:union_id/:join_form_id/:id', to:  'subscriptions#show', as: :join
    get '/:union_id/:join_form_id/:id/pdf', to:  'subscriptions#pdf', as: :pdf
    get '/temp_report', to: 'subscriptions#temp_report'

    root "join_forms#index"
  end

end
