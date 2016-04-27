Rails.application.routes.draw do
  resources :racers
  root to: 'racers#index'
end
