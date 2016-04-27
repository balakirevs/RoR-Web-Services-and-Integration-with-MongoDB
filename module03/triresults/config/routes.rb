Rails.application.routes.draw do
  resources :racers do
    post "entries" => "racers#create_entry"
  end
  resources :races
end
