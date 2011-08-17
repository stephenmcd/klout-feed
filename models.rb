require "datamapper"
require "date"
require "rest_client"

KLOUT_URL = "http://api.klout.com/1/klout.json"

#DataMapper::Logger.new(STDOUT, :debug)
DataMapper.setup(:default, ENV["DATABASE_URL"] || "sqlite3://#{Dir.pwd}/feed.db")

class User
  include DataMapper::Resource

  property :id, Serial
  property :name, String
  has n, :api_keys, :through => Resource
  has n, :scores

  def load_scores(api_key_value)
    api_key = ApiKey.first_or_create(:value => api_key_value)
    api_keys << api_key unless api_keys.include? api_key
    if scores.length == 0 or scores[0].created_at < DateTime.now - 4 / 24.0
      params = {:users => api_keys.users.all.join(","), :key => api_key_value}
      response = JSON.parse(RestClient.get KLOUT_URL, {:params => params})
      scores << Score.create(:value => response["users"][0]["kscore"])
      save
    end
  end

  def to_s
    name
  end
end

class ApiKey
  include DataMapper::Resource

  property :id, Serial
  property :value, String
  has n, :users, :through => Resource

  def to_s
    value
  end
end

class Score
  include DataMapper::Resource

  belongs_to :user
  property :id, Serial
  property :value, Float
  property :created_at, DateTime

  def self.latest
    all(:order => [:id.desc], :limit => 20)
  end

  def to_s
    date = created_at.strftime "%b %e"
    "#{user.name}'s Klout Score for #{date} is: #{value}"
  end
end

DataMapper.finalize
DataMapper.auto_upgrade!
