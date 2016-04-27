class AddressComponent 
  attr_reader :long_name, :short_name, :types
  
  def initialize(args = {})
    @long_name  = args[:long_name]
    @short_name = args[:short_name]
    @types = args[:types]
  end
end