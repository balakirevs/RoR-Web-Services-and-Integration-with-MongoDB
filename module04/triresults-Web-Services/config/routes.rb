Rails.application.routes.draw do
  resources :racers do
    post "entries" => "racers#create_entry"
  end
  resources :races

  namespace :api do
    resources :races do
      resources :results
    end
    resources :racers do
      resources :entries
    end
  end
end