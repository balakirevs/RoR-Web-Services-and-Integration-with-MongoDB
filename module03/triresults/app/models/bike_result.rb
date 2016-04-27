class BikeResult < LegResult

  include Mongoid::Document

  field :mph, type: Float

  def calc
  	event.miles * 3600 / secs
  end

  def calc_ave
  	if event && secs
			meters = event.meters
			self.mph = meters.nil? ? nil : calc
		end
  end
end