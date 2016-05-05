Rails.application.routes.draw do
  scope "(:locale)", locale: /en|en-AU|zh-TW/ do
    
    resources :subscriptions
    # mount ActionCable.server => '/cable'


    #get 'stripe/index'
    resources :stripe, only: [:index, :destroy]

    devise_for :people, :controllers => { :invitations => 'people/invitations' }
      
    resources :unions, controller: :supergroups, type: 'Union' do
      resources :join_forms, except: [:show] do 
        resources :subscriptions
      end
      resource :key, only: [:show, :new, :edit, :update], controller: 'unions/key'
    end
    
    resources :people, except: [:new] do # people can only be invited
      member do 
        get 'compose_email'
        patch 'send_email'
      end
    end 

    resources :join_forms, except: [:show] 

    get '/public/:filename', to: 'files#get'
    
    get '/:union_id/:join_form_id/join', to: 'subscriptions#new' 
    post '/:union_id/:join_form_id/join', to: 'subscriptions#create' 
    get '/:union_id/:join_form_id/join/:id', to: 'subscriptions#edit'
    patch '/:union_id/:join_form_id/join/:id', to:  'subscriptions#update'
    get '/:union_id/:join_form_id/:id', to:  'subscriptions#show'

    root "join_forms#index"
  end

end
