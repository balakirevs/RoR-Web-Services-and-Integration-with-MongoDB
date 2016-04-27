class Place
  include ActiveModel::Model

  attr_accessor :id, :formatted_address, :location, :address_components

  def self.mongo_client
    Mongoid::Clients.default
  end

  def persisted?
    !@id.nil?
  end

  def self.collection
    self.mongo_client['places']
  end

  def self.load_all file
    input = {}
    input = JSON.parse(file.read)
    collection.insert_many(input)
  end

  def initialize(params = {})
    @id = params[:_id].nil? ? params[:id] : params[:_id].to_s
    @formatted_address = params[:formatted_address]
    @location = Point.new(params[:geometry][:geolocation]) if !params.nil?
    @address_components = params[:address_components].map {|a| AddressComponent.new(a)} if !params[:address_components].nil?
  end

  def self.find_by_short_name input
    collection.find({:'address_components.short_name' => input})
  end

  def self.to_places collection
    collection.map {|doc| Place.new(doc)}
  end

  def self.find id
    id = BSON::ObjectId.from_string(id)
    result = collection.find({_id: id}).first
    result = Place.new(result) if !result.nil?
  end

  def self.all(offset = 0, limit = 0)
    result = collection.find.skip(offset).limit(limit)
    places = []
    result.each do |r|
      places << Place.new(r)
    end
    return places
  end

  def destroy
    self.class.collection.find({_id: BSON::ObjectId(@id)}).delete_one 
  end

  def self.get_address_components(sort = {}, offset = 0, limit = nil)
    queries = [ {:$project => {_id: 1, address_components: 1, formatted_address: 1, :'geometry.geolocation' => 1}}, 
                              {:$unwind => '$address_components'}, {:$skip => offset}]  
    queries.insert(2, {:$sort => sort}) if sort != {}
    queries << {:$limit => limit} if !limit.nil?
    collection.find.aggregate(queries)
  end

  def self.get_country_names
    collection.find.aggregate([{:$unwind => "$address_components"},
                               {:$match => {:'address_components.types' => "country"}},
                               {:$group => {_id: "$address_components.long_name"}},
                               {:$project => {_id: 1}}]).to_a.map {|h| h[:_id]}
  end

  def self.find_ids_by_country_code country_code
    collection.find.aggregate([{:$unwind => "$address_components"},
                               {:$match => { :'address_components.short_name' => country_code}},
                               {:$project => {_id: 1}}]).to_a.map {|h| h[:_id].to_s}
  end

  def self.create_indexes
    collection.indexes.create_one({:'geometry.geolocation' => Mongo::Index::GEO2DSPHERE})
  end

  def self.remove_indexes
    collection.indexes.drop_all
  end

  def self.near(input, max_meters = nil)
    result = collection.find({:'geometry.geolocation' => {:$near => {:$geometry => input.to_hash, :$maxDistance => max_meters}}})
  end

  def near(max_meters = nil)
    max_meters = max_meters.nil? ? 1000 : max_meters.to_i
    result = Place.near(@location, max_meters)
    Place.to_places(result)
  end

  def photos(offset = 0, limit = nil)
    result = Photo.find_photos_for_place(@id).skip(offset)
    result = result.limit(limit) if !limit.nil?
    result = result.map {|r| Photo.new(r)}
  end
end