module Api
  class RacersController < ApplicationController

    def index
      if !request.accept || request.accept == "*/*"
        render plain: "/api/racers"
      end
    end

    def show
      if !request.accept || request.accept == "*/*"
        render plain: "/api/racers/#{params[:id]}"
      end
    end
  end
end