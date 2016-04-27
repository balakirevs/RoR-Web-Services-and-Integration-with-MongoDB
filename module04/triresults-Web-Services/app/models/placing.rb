class Placing

	attr_accessor :name, :place

	def initialize(args)
		@name = args[:name]
		@place = args[:place]
	end

	def mongoize
		{name: @name, place: @place}
	end

	def self.mongoize object
		case object
		when Hash then Placing.new(object).mongoize
		when Placing then object.mongoize
		when nil then nil
		else object
		end
	end

	def self.demongoize object
		case object
		when Hash then Placing.new(object)
		when nil then nil
		else object
		end
	end

	def self.evolve object
		case object
    when Placing then object.mongoize
    when Hash then Placing.new(object).mongoize
    else object
    end
	end
end