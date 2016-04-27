class RunResult < LegResult

  include Mongoid::Document

  field :mmile, as: :minute_mile, type: Float

  def calc
  	(secs/60)/event.miles
  end

  def calc_ave
  	if event && secs
			meters = event.meters
			self.minute_mile=meters.nil? ? nil : calc
		end
  end
end