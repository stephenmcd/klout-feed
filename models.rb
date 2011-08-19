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

  # Given an API key, add it to the list of keys being used to
  # request this user's score. Every API key used for this user
  # is stored so that whenever this user's feed is requested,
  # we can piggyback the API request and get any other users
  # associated with this API key to try and keep their scores
  # as fresh as possible.
  def load_scores(api_key_value)
    api_key = ApiKey.first_or_create(:value => api_key_value)
    if not api_keys.include? api_key
        api_keys << api_key
        save
    end
    if load_new?
      params = {:users => api_keys.users.all.join(","), :key => api_key_value}
      begin
          response = JSON.parse(RestClient.get KLOUT_URL, {:params => params})
      rescue RestClient::Forbidden
          return "Invalid API Key"
      rescue RestClient::ResourceNotFound
          return "Invalid username"
      end
      # Convert the API response into a hash of usernames mapped to scores
      # so we can easily get a user's score as we iterate through the users.
      users = Hash[response["users"].map {|u| [u["twitter_screen_name"], u["kscore"]]}]
      return "Invalid username" unless users.has_key? name
      api_key.users.each do |u|
        if u.set_new?
            u.scores << Score.create(:value => users[u.name])
            u.save
        end
      end
    end
    ""
  end

  # Used to determine whether the API should be hit. Don't hit the API
  # if a score was loaded less than 4 hours ago. This frequency is
  # lower than a day since we don't know when the actual feed gets
  # requested or when the score actually ticks over for the day.
  def load_new?
    last = scores.latest.first
    last.nil? or last.created_at < DateTime.now - 4 / 24.0
  end

  # Used to determine whether a new score should be set. Don't set a
  # new score if the previous score falls on the same day.
  def set_new?
    last = scores.latest.first
    last.nil? or last.created_at.day != DateTime.now.day
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
    last = user.scores.all(:id.lt => id).latest.first
    delta = last.nil? ? 0 : value - last.value
    updown = delta < 0 ? "down" : "up"
    date = created_at.strftime "%b %e"
    "#{user.name}'s Klout Score for #{date} is: #{value}, #{updown} by #{delta}"
  end
end

DataMapper.finalize
DataMapper.auto_upgrade!
