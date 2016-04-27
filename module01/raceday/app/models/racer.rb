class Racer
	include ActiveModel::Model

	attr_accessor :id, :number, :first_name, :last_name, :gender, :group, :secs

	def self.mongo_client
		Mongoid::Clients.default
	end

	def self.collection
		self.mongo_client['racers']
	end

	def created_at
    nil
  end

  def updated_at
    nil
  end

	def persisted?
    !@id.nil? 
  end

	def self.all(prototype = {}, sort = {}, skip = 0, limit = nil) 
    result = collection.find(prototype).sort(sort).skip(skip)
    result = result.limit(limit) if !limit.nil?
    return result
  end

  def initialize(params = {})
    @id = params[:_id].nil? ? params[:id] : params[:_id].to_s
    @number = params[:number].to_i
    @first_name = params[:first_name]
    @last_name = params[:last_name]
    @gender = params[:gender]
    @group = params[:group]
    @secs = params[:secs].to_i
  end

  def self.find id
    id = BSON::ObjectId(id) if id.is_a?(String) 
    Rails.logger.debug {"getting racer #{id}"}
    result = collection.find(_id: id).first
    return result.nil? ? nil : Racer.new(result)
  end

  def save
    result = self.class.collection.insert_one(_id: @id, number: @number, first_name: @first_name, last_name: @last_name, 
    																					gender: @gender, group: @group, secs: @secs)
    @id = result.inserted_id.to_s
  end

  def update(params)
    @number = params[:number].to_i
    @first_name = params[:first_name]
    @last_name = params[:last_name]
    @gender = params[:gender]
    @group = params[:group]
    @secs = params[:secs].to_i

    @BSON_id = BSON::ObjectId(@id)

    params.slice!(:number, :first_name, :last_name, :gender, :group, :secs) if !params.nil?
    self.class.collection.find(_id: @BSON_id).update_one(:$set => {number: @number, first_name: @first_name, last_name: @last_name, 
    																															 gender: @gender, group: @group, secs: @secs})
  end

  def destroy
    self.class.collection.find(number: @number).delete_one
  end

  def self.paginate(params)
    Rails.logger.debug("paginate(#{params})")
    page = (params[:page] ||= 1).to_i
    limit = (params[:per_page] ||= 30).to_i
    offset = (page - 1) * limit
    sort = params[:sort] ||= {number: 1}

    racers = []
    all({}, sort, offset, limit).each do |doc|
      racers << Racer.new(doc)
    end

    total = all({}, sort, 0, 1).count
    
    WillPaginate::Collection.create(page, limit, total) do |pager|
      pager.replace(racers)
    end    
  end
end