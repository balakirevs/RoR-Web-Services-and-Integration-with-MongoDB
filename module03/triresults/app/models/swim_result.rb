class SwimResult < LegResult

  include Mongoid::Document

  field :pace_100, type: Float

  def calc
  	secs / (event.meters / 100)
  end
  
  def calc_ave
  	if event && secs
  		meters = event.meters
  		self.pace_100 = meters.nil? ? nil : calc
  	end
  end
end