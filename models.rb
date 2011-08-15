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
  has n, :scores

  def load_scores(key)
    if scores.length == 0 or scores[0].created_at < DateTime.now - 4 / 24.0
      params = {:users => name, :key => key}
      response = JSON.parse(RestClient.get KLOUT_URL, {:params => params})
      scores << Score.create(:value => response["users"][0]["kscore"])
      save
    end
  end

  def to_s
    name
  end

end

class Score
  include DataMapper::Resource

  belongs_to :user
  property :id, Serial
  property :value, Float
  property :created_at, DateTime

  def to_s
    date = created_at.strftime "%b %e"
    "#{user.name}'s Klout Score for #{date} is: #{value}"
  end

end

User.auto_upgrade!
Score.auto_upgrade!
