Rails.application.routes.draw do
  # mount ActionCable.server => '/cable'


  #get 'stripe/index'
  resources :stripe, only: [:index, :destroy]

  devise_for :people, :controllers => { :invitations => 'people/invitations' }
    
  resources :unions, controller: :supergroups, type: 'Union' do
    resources :join_forms, except: [:show]
  end
  
  resources :people, except: [:new] do # people can only be invited
    member do 
      get 'compose_email'
      patch 'send_email'
    end
  end 

  resources :join_forms, except: [:show] 

  post 'end_point', to: 'join_forms#receive'
    
  get '/public/:filename', to: 'files#get'
  
  root "join_forms#index"
  
end
