class Address

	attr_accessor :city, :state, :location

	def initialize(args = nil)
		if !args.nil?
			@city = args[:city]
			@state = args[:state]
			@location = Point.demongoize(args[:loc])
		end
	end

	def mongoize
		{city: @city, state: @state, loc: @location.mongoize}
	end

	def self.mongoize object
		case object
		when Address then object.mongoize
		when nil then nil
		when Hash then Address.new(object).mongoize
		else object
		end
	end

	def self.demongoize object
		case object
		when Hash then Address.new(object)
		when nil then nil
		else object
		end
	end

	def self.evolve object
		case object
    when Address then object.mongoize
    else object
    end
	end
end