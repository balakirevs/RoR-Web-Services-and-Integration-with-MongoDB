module Api
  class RacesController < ApplicationController

  	rescue_from ActionView::MissingTemplate do |exception|
      Rails.logger.debug("Accept:#{request.accept}")
      render plain: "woops: we do not support that content-type[#{request.accept}]", status: :unsupported_media_type
    end

    rescue_from Mongoid::Errors::DocumentNotFound do |exception|
      @msg = "woops: cannot find race[#{params[:id]}]"
      if !request.accept || request.accept == "*/*"
        render plain: @msg, status: :not_found
      else
        case request.accept
        when "application/json" then render json: {"msg" => @msg}, status: :not_found, template: "api/error_msg"
        else
          render status: :not_found, template: "api/error_msg"
        end        
        Rails.logger.debug("Accept:#{request.accept}")
      end
    end

    def index
      if !request.accept || request.accept == "*/*"
        render plain: "#{api_races_path}, offset=[#{params[:offset]}], limit=[#{params[:limit]}]"
      end
    end

    def show
      if !request.accept || request.accept == "*/*"
        render plain: api_race_path(params[:id])
      else
        set_race
        render "show", status: :ok
      end
    end

    def create
      Rails.logger.debug("Accept:#{request.accept}")
      if !request.accept || request.accept == "*/*"
        if params && params[:race] && params[:race][:name]
          render plain: "#{params[:race][:name]}", status: :ok
        else        
          render plain: :nothing, status: :ok
        end
      elsif !request.accept || request.accept != "*/*"
        race = Race.new(race_params)
        if race.save
          render plain: "#{params[:race][:name]}", status: :created
        else
          render plain: "#{params[:race][:name]}", status: :error
        end
      else
        render plain: ""
      end
    end

    def update
      if !request.accept || request.accept == "*/*"
        render plain: :nothing, status: :ok
      else
        set_race
        Rails.logger.debug("method=#{request.method}")
        if @race.update(race_params)
          render json: @race, status: :ok
        else
          render json: @race, status: :error
        end
      end
    end

    def destroy
      set_race
      if @race.destroy
        render nothing: true, status: :no_content
      else
        render nothing: true, status: :error
      end
    end

    private

    def set_race
      @race = Race.find(params[:id])
    end

    def race_params
      params.require(:race).permit(:name, :date)
    end
  end
end