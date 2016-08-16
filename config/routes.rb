
Rails.application.routes.draw do
  mount Bootsy::Engine => '/bootsy', as: 'bootsy'

  scope "(:locale)", locale: /en|en-AU|zh_tw|zh-TW/ do
    
    post '/records/receive_sms', to: 'records#receive_sms'
    post '/records/update_sms', to: 'records#update_sms'
    resources :subscriptions do 
      resources :records, except: [:edit]
    end

    # mount ActionCable.server => '/cable'
    
    resources :email_templates do 
      resource :preview, only: [:new, :create], controller: 'email_templates/preview' do
        member do
          get 'pdf', as: :pdf
          get 'download_pdf', as: :download_pdf
        end
      end
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
    
    post '/people/receive_sms', to: 'people#receive_sms'
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
    post '/:union_id/:join_form_id/renew', to: 'subscriptions#renew' 
    get '/:union_id/:join_form_id/join/:id', to: 'subscriptions#edit', as: :edit_join
    get '/:union_id/:join_form_id/renew/:id', to: 'subscriptions#edit', as: :renew_join
    patch '/:union_id/:join_form_id/join/:id', to:  'subscriptions#update'
    patch '/:union_id/:join_form_id/renew/:id', to:  'subscriptions#update'
    get '/:union_id/:join_form_id/:id', to:  'subscriptions#show', as: :join
    get '/:union_id/:join_form_id/:id/pdf', to:  'subscriptions#pdf', as: :pdf
    get '/temp_report', to: 'subscriptions#temp_report'

    root "join_forms#index"
  end

end
