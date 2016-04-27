class Point
  attr_accessor :longitude, :latitude

  def initialize(params = {})
    if !params.nil?
      if params[:type] 
        @longitude = params[:coordinates][0]
        @latitude  = params[:coordinates][1]
      else
        @latitude  = params[:lat]
        @longitude = params[:lng]
      end
    end 
  end
  
  def to_hash
    params = {}
    params[:type] = "Point"
    params[:coordinates] = [@longitude, @latitude]
    return params
  end
end