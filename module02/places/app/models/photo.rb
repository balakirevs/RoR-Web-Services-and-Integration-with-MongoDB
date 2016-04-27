class Photo
  include Mongoid::Document
  include ActiveModel::Model

  Mongo::Logger.logger.level = ::Logger::INFO

  belongs_to :place

  attr_accessor :id, :location, :contents

  def self.mongo_client
    Mongoid::Clients.default
  end

  def contents
    Rails.logger.debug {"Getting GridFS Contents #{@id}"}
    f = mongo_client.database.fs.find_one(_id: BSON::ObjectId.from_string(@id))

    if f
      buffer = ""
      f.chunks.reduce([]) do |x, chunk|
        buffer << chunk.data.data
      end
      return buffer
    end
  end

  def initialize(params = {})
    if !params.nil?
      @id = params[:_id].nil? ? params[:id] : params[:_id].to_s
      @place = params[:metadata].nil? ? nil : params[:metadata][:place].to_s
      @location = Point.new(params[:metadata][:location]) if !params[:metadata].nil?
    else
      Photo.new
    end
  end

  def place
    if @place != ''
      return Place.find(@place.to_s)
    end
  end

  def place= p
    if p.class == String
      @place = BSON::ObjectId.from_string(p)
    else 
      if p.class == Place
        @place = BSON::ObjectId(p.id.to_s)
      else
        @place = p
      end
    end 
  end

  def persisted?
    !@id.nil?
  end

  def save
    if persisted?
      Rails.logger.debug {"Inside persisted"}
      updates = Hash.new()
      updates[:metadata] = {}
      updates[:metadata][:place] = @place
      updates[:metadata][:location] = @location.to_hash
      self.class.mongo_client.database.fs.find(_id: BSON::ObjectId(@id.to_s)).update_one(updates)
    else
      Rails.logger.debug {"saving gridfs file #{self.to_s}"}
      description = {}
      description[:filename] = @contents.to_s
      description[:content_type] = "image/jpeg"
      description[:metadata] = {}
      gps = EXIFR::JPEG.new(@contents).gps
      @contents.rewind
      @location = Point.new(lat: gps.latitude, lng: gps.longitude)
      description[:metadata][:location] = @location.to_hash 
      description[:metadata][:place] = BSON::ObjectId.from_string(@place.id.to_s) if !@place.nil?
      
      if @contents
        Rails.logger.debug {"contents = #{@contents}"}
        grid_file = Mongo::Grid::File.new(@contents.read,description)
        @id = self.class.mongo_client.database.fs.insert_one(grid_file).to_s
      end
    end
    return @id
  end

  def self.all(skip = 0, limit = nil)
    file = []
    result = mongo_client.database.fs.find.skip(skip)
    result = result.limit(limit) if !limit.nil?
    result.map {|doc| Photo.new(doc)}
  end

  def self.find id
    f = mongo_client.database.fs.find(_id: BSON::ObjectId.from_string(id.to_s)).first
    return f.nil? ? nil : Photo.new(f)
  end

  def destroy
    Rails.logger.debug {"Destroying file #{@id}"}
    mongo_client.database.fs.find(_id: BSON::ObjectId.from_string(@id)).delete_one
  end

  def find_nearest_place_id  max_meters
    places = Place.near(@location,max_meters).limit(1).projection(_id: 1).map {|doc| doc[:_id]}[0]
    return places.nil? ? nil : BSON::ObjectId.from_string(places)
  end

  def self.find_photos_for_place place_id
    place_id = BSON::ObjectId.from_string(place_id.to_s)
    result = self.mongo_client.database.fs.find(:"metadata.place" => place_id)
  end
end